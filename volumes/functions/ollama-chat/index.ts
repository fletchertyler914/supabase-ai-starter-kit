const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  })
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders })
  }
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed", detail: "Use POST with JSON body" }, 405)
  }

  const base = Deno.env.get("OLLAMA_BASE_URL")?.replace(/\/$/, "") ?? "http://host.docker.internal:11434"

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
    : "llama3.2:3b"

  const chatUrl = `${base}/api/chat`
  try {
    const payload = {
      ...body,
      messages,
      model,
    }

    const ollamaRes = await fetch(chatUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    })

    const raw = await ollamaRes.text()
    let data: unknown
    try {
      data = JSON.parse(raw)
    } catch {
      data = { raw }
    }

    return new Response(typeof data === "string" ? JSON.stringify(data) : JSON.stringify(data), {
      status: ollamaRes.status,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    })
  } catch (e) {
    console.error("ollama-chat proxy:", e)
    return json({
      error: "ollama_unreachable",
      detail: String(e),
      target: chatUrl,
    }, 502)
  }
})
