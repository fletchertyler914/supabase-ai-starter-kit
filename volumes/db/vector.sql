-- Create a dedicated schema for extensions to avoid security issues
CREATE SCHEMA IF NOT EXISTS extensions;

-- Enable pgvector extension in the extensions schema
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA extensions;

-- Enable other useful extensions in the extensions schema
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS btree_gin WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA extensions;

-- Grant necessary permissions for vector operations
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT USAGE ON SCHEMA extensions TO anon, authenticated, service_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

-- Set up a basic vector similarity function with proper search_path
CREATE OR REPLACE FUNCTION public.cosine_similarity(a extensions.vector, b extensions.vector)
RETURNS float
LANGUAGE sql
IMMUTABLE STRICT PARALLEL SAFE
SET search_path = public, extensions
AS $$
  SELECT 1 - (a <=> b);
$$;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.cosine_similarity(extensions.vector, extensions.vector) TO anon, authenticated, service_role;

-- RAG documents table (768-dim for Ollama nomic-embed-text)
CREATE TABLE IF NOT EXISTS public.documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content TEXT NOT NULL,
  embedding extensions.vector(768),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS documents_embedding_cosine_idx
  ON public.documents USING ivfflat (embedding extensions.vector_cosine_ops)
  WITH (lists = 100);

CREATE INDEX IF NOT EXISTS documents_metadata_gin_idx
  ON public.documents USING gin (metadata);

ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

-- Local-dev permissive policies (tighten before exposing publicly)
DROP POLICY IF EXISTS "documents_anon_select" ON public.documents;
DROP POLICY IF EXISTS "documents_anon_insert" ON public.documents;
DROP POLICY IF EXISTS "documents_service_all" ON public.documents;

CREATE POLICY "documents_anon_select" ON public.documents
  FOR SELECT TO anon, authenticated USING (true);

CREATE POLICY "documents_anon_insert" ON public.documents
  FOR INSERT TO anon, authenticated WITH CHECK (true);

CREATE POLICY "documents_service_all" ON public.documents
  FOR ALL TO service_role USING (true) WITH CHECK (true);
