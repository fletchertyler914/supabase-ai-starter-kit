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

-- Create a simple example documents table (commented out - enable if needed)
-- CREATE TABLE IF NOT EXISTS documents (
--   id SERIAL PRIMARY KEY,
--   content TEXT NOT NULL,
--   embedding extensions.vector(1536), -- OpenAI embedding dimension
--   metadata JSONB DEFAULT '{}',
--   created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
--   updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
-- );

-- Create indexes for the example table (commented out - enable if needed)
-- CREATE INDEX CONCURRENTLY IF NOT EXISTS documents_embedding_cosine_idx 
--   ON documents USING ivfflat (embedding extensions.vector_cosine_ops) WITH (lists = 100);
-- CREATE INDEX CONCURRENTLY IF NOT EXISTS documents_metadata_gin_idx 
--   ON documents USING gin (metadata);

-- Enable RLS on documents table (commented out - enable if needed)
-- ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (commented out - enable if needed)
-- CREATE POLICY "Users can insert their own documents" ON documents
--   FOR INSERT WITH CHECK (auth.uid()::text = (metadata->>'user_id'));
-- CREATE POLICY "Users can view their own documents" ON documents
--   FOR SELECT USING (auth.uid()::text = (metadata->>'user_id'));
-- CREATE POLICY "Users can update their own documents" ON documents
--   FOR UPDATE USING (auth.uid()::text = (metadata->>'user_id'));
-- CREATE POLICY "Users can delete their own documents" ON documents
--   FOR DELETE USING (auth.uid()::text = (metadata->>'user_id')); 
