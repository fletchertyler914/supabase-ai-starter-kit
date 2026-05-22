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

  const ollamaBase = Deno.env.get("OLLAMA_BASE_URL")?.replace(/\/$/, "") ?? "http://host.docker.internal:11434"
  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.replace(/\/$/, "")
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")

  if (!supabaseUrl || !serviceKey) {
    return json({ error: "server_misconfigured", detail: "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY" }, 500)
  }

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return json({ error: "invalid_json" }, 400)
  }

  const question = typeof body.question === "string" ? body.question.trim() : ""
  if (!question) {
    return json({ error: "validation_error", detail: "`question` must be a non-empty string" }, 400)
  }

  const match_count = typeof body.match_count === "number" && Number.isFinite(body.match_count)
    ? Math.max(1, Math.floor(body.match_count))
    : 5

  const match_threshold = typeof body.match_threshold === "number" && Number.isFinite(body.match_threshold)
    ? body.match_threshold
    : 0.5

  const embedModel = typeof body.embed_model === "string" && body.embed_model.trim() !== ""
    ? body.embed_model.trim()
    : "nomic-embed-text"

  let embedding: number[] = []

  try {
    const embedRes = await fetch(`${ollamaBase}/api/embeddings`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ model: embedModel, prompt: question }),
    })

    const embedPayload = await embedRes.json()

    if (!embedRes.ok) {
      return json({
        error: "embed_failed",
        status: embedRes.status,
        ollama: embedPayload,
      }, 502)
    }

    const emb = (embedPayload as { embedding?: number[] }).embedding
    embedding = Array.isArray(emb) ? emb : []
    if (embedding.length === 0) {
      return json({ error: "empty_embedding", ollama: embedPayload }, 502)
    }
  } catch (e) {
    console.error("embed-and-query ollama:", e)
    return json({
      error: "ollama_unreachable",
      detail: String(e),
      target: `${ollamaBase}/api/embeddings`,
    }, 502)
  }

  try {
    const rpcUrl = `${supabaseUrl}/rest/v1/rpc/match_documents`
    const rpcRes = await fetch(rpcUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${serviceKey}`,
        apikey: serviceKey,
        Prefer: "return=representation",
      },
      body: JSON.stringify({
        query_embedding: embedding,
        match_count,
        match_threshold,
      }),
    })

    const rawText = await rpcRes.text()
    let matches: unknown
    try {
      matches = rawText ? JSON.parse(rawText) : []
    } catch {
      matches = { raw: rawText }
    }

    if (!rpcRes.ok) {
      return json({
        error: "rpc_failed",
        status: rpcRes.status,
        question,
        supabase_response: matches,
      }, rpcRes.status === 401 || rpcRes.status === 403 ? rpcRes.status : 502)
    }

    return json({
      question,
      embed_model: embedModel,
      match_count,
      match_threshold,
      matches,
    })
  } catch (e) {
    console.error("embed-and-query supabase:", e)
    return json({ error: "supabase_request_failed", detail: String(e) }, 502)
  }
})
