#!/usr/bin/env bash
# Validates template seed import and smoke-tests the Supabase health webhook template.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() { echo -e "${GREEN}✅ $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; exit 1; }

info() { echo "ℹ️  $1"; }

if [ -f .env ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
      export "$line"
    fi
  done < .env
else
  fail ".env not found — run: cp .env.example .env"
fi

OLLAMA_ID="bKhNvmpDfT4mclXo"
HEALTH_ID="c9a1b2c3d4e5f6789012345678ab"
BUILDER_ID="d4e5f6a7b8c9012345678901234abcd"

info "Checking n8n-import completed successfully..."
if ! docker compose ps -a --format '{{.Name}} {{.State}}' 2>/dev/null | grep -q 'n8n-import.*exited'; then
  fail "n8n-import container not found — is the stack up?"
fi
IMPORT_EXIT="$(docker inspect n8n-import --format '{{.State.ExitCode}}' 2>/dev/null || echo 1)"
if [ "$IMPORT_EXIT" != "0" ]; then
  docker compose logs n8n-import --no-color 2>/dev/null | tail -40 || true
  fail "n8n-import exited with code $IMPORT_EXIT"
fi
pass "n8n-import exited 0"

info "Checking template seed marker..."
if ! docker exec n8n test -f /home/node/.n8n/.template-seed-complete 2>/dev/null; then
  fail "Missing .template-seed-complete in n8n volume — seed did not run"
fi
pass "Template seed marker present"

info "Checking workflows via n8n CLI..."
WORKFLOW_LIST="$(docker exec n8n n8n list:workflow 2>/dev/null || true)"
echo "$WORKFLOW_LIST" | grep -q "$OLLAMA_ID" || fail "Ollama template workflow not found"
echo "$WORKFLOW_LIST" | grep -q "$HEALTH_ID" || fail "Supabase health template workflow not found"
echo "$WORKFLOW_LIST" | grep -q "$BUILDER_ID" || fail "NodeBot Builder template workflow not found"

info "Checking workflows are active in database..."
for wf_id in "$OLLAMA_ID" "$HEALTH_ID" "$BUILDER_ID"; do
  ACTIVE="$(docker exec supabase-db psql -U postgres -t -A -c \
    "SELECT active FROM n8n.workflow_entity WHERE id = '${wf_id}';" 2>/dev/null | tr -d '[:space:]')"
  [ "$ACTIVE" = "t" ] || fail "Workflow $wf_id is not active (got: $ACTIVE)"
done
pass "Template workflows present and active"

info "Checking NodeBot Builder workflow-agent shape..."
BUILDER_SHAPE="$(docker exec supabase-db psql -U postgres -t -A -c \
  "SELECT
     EXISTS (SELECT 1 FROM jsonb_array_elements(nodes::jsonb) n WHERE n->>'type' = '@n8n/n8n-nodes-langchain.chatTrigger' AND COALESCE((n->'parameters'->>'availableInChat')::boolean, false)),
     EXISTS (SELECT 1 FROM jsonb_array_elements(nodes::jsonb) n WHERE n->>'type' = '@n8n/n8n-nodes-langchain.agent' AND (n->>'typeVersion')::numeric >= 2.2),
     EXISTS (SELECT 1 FROM jsonb_array_elements(nodes::jsonb) n WHERE n->>'type' = '@n8n/n8n-nodes-langchain.mcpClientTool'),
     (SELECT count(*) FROM jsonb_array_elements(nodes::jsonb) n WHERE n->>'type' = '@n8n/n8n-nodes-langchain.toolWorkflow') = 4,
     COALESCE((settings::jsonb->>'availableInMCP')::boolean, false)
   FROM n8n.workflow_entity WHERE id = '${BUILDER_ID}';" 2>/dev/null | tr -d '[:space:]')"
[ "$BUILDER_SHAPE" = "t|t|t|t|t" ] || fail "NodeBot Builder is not configured as a Chat Hub + MCP workflow agent with 4 sub-workflow tools (got: $BUILDER_SHAPE)"
pass "NodeBot Builder workflow agent is configured (chat + MCP + 4 helpers)"

for HELPER_ID in \
  e6f7a8b9c0d1e2f3a4b5c6d7e8f90123 \
  a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6 \
  b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7 \
  c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8; do
  HELPER_READY="$(docker exec supabase-db psql -U postgres -t -A -c \
    "SELECT EXISTS (SELECT 1 FROM n8n.workflow_entity WHERE id = '${HELPER_ID}' AND active);" 2>/dev/null | tr -d '[:space:]')"
  [ "$HELPER_READY" = "t" ] || fail "Builder helper sub-workflow ${HELPER_ID} must be imported and active (got: $HELPER_READY)"
done
pass "All four NodeBot Builder helper sub-workflows are present and active"

MCP_ENABLED="$(docker exec supabase-db psql -U postgres -t -A -c \
  "SELECT value::text FROM n8n.settings WHERE key = 'mcp.access.enabled';" 2>/dev/null | tr -d '[:space:]')"
[ "$MCP_ENABLED" = "true" ] || fail "n8n instance-level MCP is not enabled (got: $MCP_ENABLED)"
pass "Instance-level MCP is enabled"

info "Checking n8n-bootstrap completed (shared workflows/credentials, chat agent, trigger)..."
BOOTSTRAP_EXIT="$(docker inspect n8n-bootstrap --format '{{.State.ExitCode}}' 2>/dev/null || echo 1)"
if [ "$BOOTSTRAP_EXIT" != "0" ]; then
  docker compose logs n8n-bootstrap --no-color 2>/dev/null | tail -40 || true
  fail "n8n-bootstrap exited with code $BOOTSTRAP_EXIT"
fi
pass "n8n-bootstrap exited 0"

PROJECTS="$(docker exec supabase-db psql -U postgres -t -A -c \
  "SELECT count(*) FROM n8n.project WHERE type = 'personal';" 2>/dev/null | tr -d '[:space:]')"
if [ "${PROJECTS:-0}" -gt 0 ]; then
  info "n8n has ${PROJECTS} personal project(s) — checking sharing + chat agent..."
  for wf_id in "$OLLAMA_ID" "$HEALTH_ID" "$BUILDER_ID"; do
    COUNT="$(docker exec supabase-db psql -U postgres -t -A -c \
      "SELECT count(*) FROM n8n.shared_workflow WHERE \"workflowId\" = '${wf_id}';" 2>/dev/null | tr -d '[:space:]')"
    [ "${COUNT:-0}" -gt 0 ] || fail "Workflow ${wf_id} is not shared with any project"
  done
  pass "Workflows shared with personal project(s)"
  CRED_SHARED="$(docker exec supabase-db psql -U postgres -t -A -c \
    "SELECT count(*) FROM n8n.shared_credentials WHERE \"credentialsId\" = 'VmhEukzPe8au9PTB';" 2>/dev/null | tr -d '[:space:]')"
  [ "${CRED_SHARED:-0}" -gt 0 ] || fail "Ollama credential is not shared with any project"
  pass "Ollama credential shared with personal project(s)"
  MCP_CRED_SHARED="$(docker exec supabase-db psql -U postgres -t -A -c \
    "SELECT count(*) FROM n8n.shared_credentials WHERE \"credentialsId\" = 'N8NMcpBearer001';" 2>/dev/null | tr -d '[:space:]')"
  [ "${MCP_CRED_SHARED:-0}" -gt 0 ] || fail "MCP bearer credential is not shared with any project"
  pass "MCP bearer credential shared with personal project(s)"
  AGENTS="$(docker exec supabase-db psql -U postgres -t -A -c \
    "SELECT count(*) FROM n8n.chat_hub_agents WHERE provider = 'ollama' AND \"credentialId\" = 'VmhEukzPe8au9PTB' AND json_typeof(\"suggestedPrompts\") = 'array' AND json_typeof(\"suggestedPrompts\"->0) = 'object' AND (\"suggestedPrompts\"->0)::jsonb ? 'text';" 2>/dev/null | tr -d '[:space:]')"
  [ "${AGENTS:-0}" -gt 0 ] || fail "No Ollama chat_hub_agent was created"
  pass "Native n8n Chat is pre-configured with an Ollama personal agent"
else
  info "No personal projects exist yet — sharing/chat agent will be created via trigger on first signup."
fi

TRIGGER_PRESENT="$(docker exec supabase-db psql -U postgres -t -A -c \
  "SELECT count(*) FROM pg_trigger WHERE tgname = 'starter_kit_bootstrap_trigger';" 2>/dev/null | tr -d '[:space:]')"
[ "${TRIGGER_PRESENT:-0}" -gt 0 ] || fail "Bootstrap trigger not installed"
pass "Bootstrap trigger installed for future signups"

info "Smoke test: Supabase API Health Check webhook..."
BODY_FILE="$(mktemp)"
HTTP_CODE="$(curl -sS -o "$BODY_FILE" -w "%{http_code}" -X POST \
  "http://localhost:5678/webhook/template-supabase-health" || echo 000)"
if [ "$HTTP_CODE" != "200" ]; then
  cat "$BODY_FILE" 2>/dev/null || true
  rm -f "$BODY_FILE"
  fail "Webhook returned HTTP $HTTP_CODE (expected 200)"
fi
if command -v jq >/dev/null 2>&1; then
  jq -e '.ok == true' "$BODY_FILE" >/dev/null || fail "Webhook body missing ok:true"
else
  grep -q '"ok"[[:space:]]*:[[:space:]]*true' "$BODY_FILE" || fail "Webhook body missing ok:true"
fi
rm -f "$BODY_FILE"
pass "Webhook smoke test passed"

echo ""
pass "n8n template library checks passed"
