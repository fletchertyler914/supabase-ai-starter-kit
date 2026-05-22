#!/usr/bin/env bash
# Optional NodeBot Builder chat webhook E2E: uses Ollama + LLM routing.
# Strict mode: OLLAMA_BUILDER_MODEL_E2E=1 → failures exit non‑zero (CI).
# Soft mode (default): missing stack / webhook / Ollama → warn and exit 0.
#
# Also verifies n8n MCP exposes create_workflow_from_code (workflow-builder plumbing).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

fail() {
  echo -e "${RED}❌ $1${NC}" >&2
  exit 1
}
pass() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
info() { echo "ℹ️  $1"; }

SOFT_ABORT() {
  if [ "${OLLAMA_BUILDER_MODEL_E2E:-0}" = "1" ]; then
    fail "$1"
  fi
  warn "$1 — skipping chat E2E (set OLLAMA_BUILDER_MODEL_E2E=1 to enforce)"
  exit 0
}

if [ -f .env ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then export "$line"; fi
  done < .env
fi

N8N_BASE="${N8N_BASE_URL:-http://localhost:5678}"
# Chat trigger webhookId from Template - NodeBot Builder (hosted chat)
NODEBOT_CHAT_WEBHOOK_ID="${NODEBOT_CHAT_WEBHOOK_ID:-56fa6ad4-5b89-46be-8d8d-8ec528b11a36}"
OLLAMA_HOST_URL="${OLLAMA_HOST_URL:-http://localhost:11434}"
OLLAMA_MODEL="${OLLAMA_BUILDER_MODEL:-${OLLAMA_MODEL:-llama3.2:3b}}"
TIMEOUT="${BUILDER_E2E_TIMEOUT_SECONDS:-240}"

BUILDER_JSON="$(find "${ROOT}/n8n/demo-data/workflows" -name 'd4e5f6a7b8c9012345678901234abcd.json' 2>/dev/null | head -1)"
if [ ! -f "$BUILDER_JSON" ]; then
  SOFT_ABORT "Missing NodeBot Builder workflow export"
fi

grep -q '"webhookId": "56fa6ad4-5b89-46be-8d8d-8ec528b11a36"' "$BUILDER_JSON" 2>/dev/null \
  || warn "Exported NodeBot webhookId differs from NODEBOT_CHAT_WEBHOOK_ID — check NODEBOT_CHAT_WEBHOOK_ID env"

info "Checking MCP exposes create_workflow_from_code (workflow-builder surface)..."
MCP_TOKEN="${N8N_MCP_ACCESS_TOKEN:-}"
if [ -z "$MCP_TOKEN" ]; then
  MCP_TOKEN="$(docker exec supabase-db psql -U postgres -d postgres -t -A -c \
    "SELECT \"apiKey\" FROM n8n.user_api_keys WHERE audience = 'mcp-server-api' ORDER BY \"updatedAt\" DESC LIMIT 1;" 2>/dev/null | tr -d '[:space:]' || true)"
fi
if [ -z "$MCP_TOKEN" ]; then
  SOFT_ABORT "No N8N_MCP_ACCESS_TOKEN — run npm run setup after n8n owner exists"
fi

BODY_TOOLS="$(mktemp)"
trap 'rm -f "$BODY_TOOLS" "$WF_BODY"' EXIT
HTTP_MCP="$(curl -sS -o "$BODY_TOOLS" -w '%{http_code}' \
  -X POST "${N8N_BASE}/mcp-server/http" \
  -H "Authorization: Bearer ${MCP_TOKEN}" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' 2>/dev/null || echo 000)"
if [ "$HTTP_MCP" != "200" ] || ! grep -q '"create_workflow_from_code"' "$BODY_TOOLS"; then
  cat "$BODY_TOOLS" 2>/dev/null | head -40 || true
  SOFT_ABORT "MCP tools/list missing create_workflow_from_code (HTTP $HTTP_MCP)"
fi
pass "MCP exposes create_workflow_from_code"

if ! curl -sS --max-time 5 "${OLLAMA_HOST_URL}/api/tags" | grep -q "\"${OLLAMA_MODEL}\""; then
  SOFT_ABORT "Ollama not reachable or model ${OLLAMA_MODEL} missing at ${OLLAMA_HOST_URL}"
fi

CHAT_URL="${N8N_BASE}/webhook/${NODEBOT_CHAT_WEBHOOK_ID}/chat"
WF_BODY="$(mktemp)"
SESSION_ID="nodebot-e2e-$$"

info "POST ${CHAT_URL} (greeting helper path — manual trigger hello workflow)..."
HTTP_CODE="$(curl -sS -o "$WF_BODY" -w '%{http_code}' --max-time "$TIMEOUT" \
  -X POST "$CHAT_URL" \
  -H 'Content-Type: application/json' \
  -d "{
    \"action\": \"sendMessage\",
    \"sessionId\": \"${SESSION_ID}\",
    \"chatInput\": \"Create a workflow with a Manual Trigger and a Set node that returns hello from NodeBot. Name it e2e-hello-builder.\"
  }" 2>/dev/null || echo 000)"

if [ "$HTTP_CODE" != "200" ]; then
  cat "$WF_BODY" 2>/dev/null | head -50 || true
  SOFT_ABORT "Chat webhook HTTP $HTTP_CODE"
fi

# Accept common agent response shapes; NodeBot hides tool JSON so we look for human summary + clues
RESP_OK=0
if WF_PATH="$WF_BODY" python3 - <<'PY' 2>/dev/null
import json
import os
import sys

path = os.environ.get("WF_PATH", "")
try:
    d = json.loads(open(path, encoding='utf-8').read())
except Exception:
    sys.exit(1)
text = ""
for key in ("output", "text", "response", "message"):
    val = d.get(key)
    if isinstance(val, str) and val.strip():
        text = val
        break
    if isinstance(val, dict):
        nested = val.get('text') or val.get('output') or val.get('message')
        if isinstance(nested, str) and nested.strip():
            text = nested
            break

low = text.lower().strip()
if len(low) < 8:
    sys.exit(1)
if ("workflow" in low) and ("hello" in low or "manual" in low or "5678/workflow/" in low or "created" in low or "/workflow/" in low):
    sys.exit(0)
sys.exit(1)
PY
then
  RESP_OK=1
fi

if [ "$RESP_OK" = "1" ]; then
  pass "NodeBot returned a plausible workflow-builder reply"
else
  head -80 "$WF_BODY" || true
  SOFT_ABORT "NodeBot reply did not look successful (inspect body above)"
fi

echo ""
pass "NodeBot builder E2E (chat + MCP tool surface) passed"
