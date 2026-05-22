#!/usr/bin/env bash
# Local smoke test for n8n instance-level MCP and the NodeBot Builder workflow agent.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}✅ $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; exit 1; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
info() { echo "ℹ️  $1"; }

if [ -f .env ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
      export "$line"
    fi
  done < .env
fi

MCP_TOKEN="${N8N_MCP_ACCESS_TOKEN:-}"
if [ -z "$MCP_TOKEN" ]; then
  MCP_TOKEN="$(docker exec supabase-db psql -U postgres -d postgres -t -A -c \
    "SELECT \"apiKey\" FROM n8n.user_api_keys WHERE audience = 'mcp-server-api' ORDER BY \"updatedAt\" DESC LIMIT 1;" 2>/dev/null | tr -d '[:space:]' || true)"
fi

if [ -z "$MCP_TOKEN" ]; then
  warn "No MCP token found. Create the first n8n owner account, then run npm run setup."
  exit 0
fi

info "Listing n8n MCP tools..."
BODY="$(mktemp)"
HTTP_CODE="$(curl -sS -o "$BODY" -w '%{http_code}' \
  -X POST http://localhost:5678/mcp-server/http \
  -H "Authorization: Bearer ${MCP_TOKEN}" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' || echo 000)"

if [ "$HTTP_CODE" != "200" ]; then
  cat "$BODY" 2>/dev/null || true
  rm -f "$BODY"
  fail "MCP tools/list returned HTTP $HTTP_CODE"
fi

if ! grep -q '"create_workflow_from_code"' "$BODY"; then
  cat "$BODY" 2>/dev/null || true
  rm -f "$BODY"
  fail "MCP tools/list did not include create_workflow_from_code"
fi
rm -f "$BODY"
pass "MCP exposes workflow-builder tools"

BUILDER_READY="$(docker exec supabase-db psql -U postgres -d postgres -t -A -c \
  "SELECT
     EXISTS (SELECT 1 FROM n8n.workflow_entity WHERE id = 'd4e5f6a7b8c9012345678901234abcd' AND active),
     EXISTS (SELECT 1 FROM n8n.credentials_entity WHERE id = 'N8NMcpBearer001'),
     EXISTS (SELECT 1 FROM n8n.shared_credentials WHERE \"credentialsId\" = 'N8NMcpBearer001')
   ;" 2>/dev/null | tr -d '[:space:]')"
[ "$BUILDER_READY" = "t|t|t" ] || fail "NodeBot Builder workflow/credential is not ready (got: $BUILDER_READY)"
pass "NodeBot Builder workflow and MCP credential are ready"

echo ""
pass "n8n MCP builder-agent checks passed"
