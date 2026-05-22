-- Observability helpers: record AI completions from n8n or other clients via PostgREST.

CREATE TABLE IF NOT EXISTS public.ai_calls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider TEXT NOT NULL,
  model TEXT NOT NULL,
  latency_ms INTEGER,
  prompt_tokens INTEGER,
  completion_tokens INTEGER,
  cost_usd NUMERIC(14, 6),
  user_id UUID,
  workflow_id TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ai_calls_created_at_idx
  ON public.ai_calls (created_at DESC);

CREATE INDEX IF NOT EXISTS ai_calls_workflow_idx
  ON public.ai_calls (workflow_id)
  WHERE workflow_id IS NOT NULL;

COMMENT ON TABLE public.ai_calls IS 'Starter kit telemetry; tighten RLS before public exposure.';

ALTER TABLE public.ai_calls ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ai_calls_anon_select" ON public.ai_calls;
DROP POLICY IF EXISTS "ai_calls_anon_insert" ON public.ai_calls;
DROP POLICY IF EXISTS "ai_calls_service_all" ON public.ai_calls;

-- Local-dev permissive policies (mirror documents table guidance in vector.sql)
CREATE POLICY "ai_calls_anon_select" ON public.ai_calls
  FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "ai_calls_anon_insert" ON public.ai_calls
  FOR INSERT TO anon, authenticated WITH CHECK (true);

CREATE POLICY "ai_calls_service_all" ON public.ai_calls
  FOR ALL TO service_role USING (true) WITH CHECK (true);

GRANT SELECT, INSERT ON public.ai_calls TO anon, authenticated, service_role;

CREATE OR REPLACE VIEW public.ai_call_daily_stats AS
SELECT
  date_trunc('day', created_at)::date AS day,
  provider,
  model,
  count(*)::integer AS calls,
  round(avg(latency_ms))::integer AS avg_latency_ms,
  sum(coalesce(prompt_tokens, 0))::integer AS prompt_tokens,
  sum(coalesce(completion_tokens, 0))::integer AS completion_tokens,
  sum(coalesce(cost_usd, 0))::numeric(14, 6) AS cost_usd
FROM public.ai_calls
GROUP BY 1, 2, 3
ORDER BY day DESC, calls DESC;

COMMENT ON VIEW public.ai_call_daily_stats IS 'Daily rollup for local AI usage dashboards.';

GRANT SELECT ON public.ai_call_daily_stats TO anon, authenticated, service_role;
