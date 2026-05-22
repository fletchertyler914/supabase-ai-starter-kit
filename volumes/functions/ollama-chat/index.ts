const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

const defaultModel = "llama3.2:3b"

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  })
}

function parseResponse(raw: string) {
  try {
    return JSON.parse(raw)
  } catch {
    return { raw }
  }
}

function getString(value: unknown) {
  return typeof value === "string" && value.trim() !== "" ? value.trim() : undefined
}

async function proxyOllama(base: string, body: Record<string, unknown>, messages: unknown[], model: string) {
  const chatUrl = `${base}/api/chat`
  const ollamaRes = await fetch(chatUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ ...body, messages, model }),
  })

  const raw = await ollamaRes.text()
  const data = parseResponse(raw)

  return {
    response: new Response(JSON.stringify(data), {
      status: ollamaRes.status,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    }),
    status: ollamaRes.status,
    target: chatUrl,
  }
}

async function proxyOpenAI(body: Record<string, unknown>, messages: unknown[]) {
  const apiKey = Deno.env.get("OPENAI_API_KEY")
  if (!apiKey) {
    return undefined
  }

  const base = Deno.env.get("OPENAI_API_BASE_URL")?.replace(/\/$/, "") ?? "https://api.openai.com/v1"
  const model = getString(body.openaiModel) ?? Deno.env.get("OPENAI_CHAT_MODEL") ?? "gpt-4o-mini"
  const openaiRes = await fetch(`${base}/chat/completions`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model,
      messages,
      temperature: typeof body.temperature === "number" ? body.temperature : undefined,
      stream: false,
    }),
  })

  const raw = await openaiRes.text()
  const data = parseResponse(raw) as Record<string, unknown>
  const choice = Array.isArray(data.choices) ? data.choices[0] as Record<string, unknown> | undefined : undefined
  const message = choice && typeof choice.message === "object" && choice.message !== null
    ? choice.message
    : undefined

  return json({
    provider: "openai",
    model,
    message,
    done: openaiRes.ok,
    raw: data,
  }, openaiRes.status)
}

async function tryOpenAIFallback(body: Record<string, unknown>, messages: unknown[]) {
  try {
    return await proxyOpenAI(body, messages)
  } catch (e) {
    console.error("openai fallback proxy:", e)
    return undefined
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders })
  }
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed", detail: "Use POST with JSON body" }, 405)
  }

  const base = Deno.env.get("OLLAMA_BASE_URL")?.replace(/\/$/, "") ?? "http://host.docker.internal:11434"
  const fallbackProvider = Deno.env.get("OLLAMA_CHAT_FALLBACK_PROVIDER")?.toLowerCase()

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return json({ error: "invalid_json" }, 400)
  }

  const messages = body.messages
  if (!Array.isArray(messages)) {
    return json({ error: "validation_error", detail: "`messages` must be an array of chat messages" }, 400)
  }

  const model = typeof body.model === "string" && body.model.trim() !== ""
    ? body.model.trim()
    : defaultModel

  try {
    const ollama = await proxyOllama(base, body, messages, model)
    if (ollama.status < 500 || fallbackProvider !== "openai") {
      return ollama.response
    }

    const fallback = await tryOpenAIFallback(body, messages)
    return fallback ?? ollama.response
  } catch (e) {
    if (fallbackProvider === "openai") {
      const fallback = await tryOpenAIFallback(body, messages)
      if (fallback) {
        return fallback
      }
    }

    console.error("ollama-chat proxy:", e)
    return json({
      error: "ollama_unreachable",
      detail: String(e),
      target: `${base}/api/chat`,
    }, 502)
  }
})
