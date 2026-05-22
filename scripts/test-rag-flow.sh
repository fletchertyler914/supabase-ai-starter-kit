#!/usr/bin/env bash
# Smoke test for Template - Document Ingest + Query (RAG).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
pass() { echo -e "${GREEN}✅ $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; exit 1; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
info() { echo "ℹ️  $1"; }

N8N_BASE="${N8N_BASE_URL:-http://localhost:5678}"
OLLAMA_URL="${OLLAMA_HOST_URL:-http://localhost:11434}"
TIMEOUT="${RAG_TEST_TIMEOUT:-180}"

if [ -f .env ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then export "$line"; fi
  done < .env
fi

info "Checking Ollama + nomic-embed-text..."
if ! curl -sS --max-time 5 "${OLLAMA_URL}/api/tags" | grep -q 'nomic-embed-text'; then
  if command -v ollama >/dev/null 2>&1; then
    ollama pull nomic-embed-text || fail "Could not pull nomic-embed-text"
  else
    curl -sS -X POST "${OLLAMA_URL}/api/pull" \
      -H 'Content-Type: application/json' \
      -d '{"name":"nomic-embed-text","stream":false}' \
      --max-time 600 >/dev/null || fail "Could not pull nomic-embed-text via API"
  fi
fi
pass "nomic-embed-text available"

info "Ensuring documents table exists (apply migration on running DB if needed)..."
docker exec -i supabase-db psql -U postgres -d postgres >/dev/null 2>&1 <<'SQL' || true
\i /docker-entrypoint-initdb.d/migrations/99-vector.sql
\i /docker-entrypoint-initdb.d/migrations/99-match-documents.sql
SQL

WF_ACTIVE="$(docker exec supabase-db psql -U postgres -d postgres -t -A -c \
  "SELECT active FROM n8n.workflow_entity WHERE id = 'f1e2d3c4b5a6978890abcdef12345678';" 2>/dev/null | tr -d '[:space:]' || true)"
[ "$WF_ACTIVE" = "t" ] || fail "RAG template workflow f1e2d3c4b5a6978890abcdef12345678 is not active"

SESSION="rag-test-$(date +%s)"

ingest() {
  local content="$1"
  local meta="$2"
  curl -sS --max-time "$TIMEOUT" -X POST \
    "${N8N_BASE}/webhook/template-rag-ingest" \
    -H 'Content-Type: application/json' \
    -d "{\"content\":$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$content"),\"metadata\":${meta}}" \
    | tee /tmp/rag-ingest.json
  echo
  grep -q '"ok":true' /tmp/rag-ingest.json || fail "Ingest failed for: $content"
}

info "Ingesting sample documents..."
ingest "PostgreSQL pgvector stores embeddings for semantic search in this starter kit." '{"topic":"pgvector"}'
ingest "n8n workflows can call Ollama for local LLM chat and embeddings." '{"topic":"n8n"}'
ingest "Supabase Auth provides JWT-based authentication through Kong." '{"topic":"auth"}'
pass "Three documents ingested"

info "Querying RAG pipeline..."
QUERY_BODY="$(curl -sS --max-time "$TIMEOUT" -X POST \
  "${N8N_BASE}/webhook/template-rag-query" \
  -H 'Content-Type: application/json' \
  -d "{\"question\":\"How does pgvector help with semantic search?\",\"sessionId\":\"${SESSION}\"}")"

echo "$QUERY_BODY" | tee /tmp/rag-query.json
echo "$QUERY_BODY" | grep -qi 'pgvector\|embedding\|semantic' \
  || fail "RAG query did not return context about pgvector (got: ${QUERY_BODY:0:300})"
pass "RAG query returned relevant answer"

echo ""
pass "RAG flow smoke test passed"
