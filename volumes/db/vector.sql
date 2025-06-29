-- Enable pgvector extension for vector similarity search
CREATE EXTENSION IF NOT EXISTS vector;

-- Enable other useful extensions that work well with vector search
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- Grant necessary permissions for vector operations
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

-- Set up a basic vector similarity function for convenience
CREATE OR REPLACE FUNCTION cosine_similarity(a vector, b vector)
RETURNS float
LANGUAGE sql
IMMUTABLE STRICT PARALLEL SAFE
AS $$
  SELECT 1 - (a <=> b);
$$;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION cosine_similarity(vector, vector) TO anon, authenticated, service_role;

-- Create a simple example documents table (commented out - enable if needed)
-- CREATE TABLE IF NOT EXISTS documents (
--   id SERIAL PRIMARY KEY,
--   content TEXT NOT NULL,
--   embedding VECTOR(1536), -- OpenAI embedding dimension
--   metadata JSONB DEFAULT '{}',
--   created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
--   updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
-- );

-- Create indexes for the example table (commented out - enable if needed)
-- CREATE INDEX CONCURRENTLY IF NOT EXISTS documents_embedding_cosine_idx 
--   ON documents USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
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
