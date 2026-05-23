#!/usr/bin/env bash
# End-to-end Ollama integration test:
#   1. Verifies Ollama reachable from host
#   2. Verifies required model present
#   3. Direct Ollama /api/chat call returns a non-empty response (real model)
#   4. Verifies n8n container can reach Ollama at host.docker.internal:11434
#   5. Drives the n8n "Local Ollama Chat" template via chat trigger webhook end-to-end
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
pass() { echo -e "${GREEN}✅ $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; exit 1; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
info() { echo "ℹ️  $1"; }

OLLAMA_HOST_URL="${OLLAMA_HOST_URL:-http://localhost:11434}"
OLLAMA_MODEL="${OLLAMA_MODEL:-llama3.2:3b}"
N8N_BASE_URL="${N8N_BASE_URL:-http://localhost:5678}"
OLLAMA_CHAT_WEBHOOK_ID="ba65d0a2-7d1d-4efe-9e7a-c41b1031e3bb"
TIMEOUT_SECONDS="${OLLAMA_TIMEOUT_SECONDS:-120}"

# 1. Ollama reachable
info "Checking Ollama reachable at ${OLLAMA_HOST_URL}..."
if ! curl -sS --max-time 5 "${OLLAMA_HOST_URL}/api/tags" >/dev/null 2>&1; then
  warn "Ollama not reachable at ${OLLAMA_HOST_URL} — skipping end-to-end Ollama test."
  warn "Start Ollama (host install, or 'docker compose --profile cpu up -d ollama-cpu') to exercise this path."
  exit 0
fi
pass "Ollama reachable"

# 2. Model present
info "Checking model ${OLLAMA_MODEL} present..."
if ! curl -sS "${OLLAMA_HOST_URL}/api/tags" | grep -q "\"${OLLAMA_MODEL}\""; then
  warn "Model ${OLLAMA_MODEL} not present — attempting pull (may take several minutes)..."
  if command -v ollama >/dev/null 2>&1; then
    ollama pull "${OLLAMA_MODEL}" || fail "ollama pull ${OLLAMA_MODEL} failed"
  else
    curl -sS -X POST "${OLLAMA_HOST_URL}/api/pull" \
      -H 'Content-Type: application/json' \
      -d "{\"name\":\"${OLLAMA_MODEL}\",\"stream\":false}" \
      --max-time 600 >/dev/null \
      || fail "Failed to pull ${OLLAMA_MODEL} via Ollama API"
  fi
fi
pass "Model ${OLLAMA_MODEL} available"

# 3. Direct Ollama API smoke test (real model invocation)
info "Direct Ollama /api/chat smoke test (real model run)..."
DIRECT_BODY="$(mktemp)"
trap 'rm -f "$DIRECT_BODY"' EXIT
HTTP_CODE="$(curl -sS -o "$DIRECT_BODY" -w '%{http_code}' \
  --max-time "${TIMEOUT_SECONDS}" \
  -X POST "${OLLAMA_HOST_URL}/api/chat" \
  -H 'Content-Type: application/json' \
  -d "{
    \"model\": \"${OLLAMA_MODEL}\",
    \"stream\": false,
    \"messages\": [
      {\"role\": \"system\", \"content\": \"You answer concisely.\"},
      {\"role\": \"user\", \"content\": \"Reply with exactly one short sentence saying hello.\"}
    ],
    \"options\": { \"num_predict\": 64 }
  }" || echo 000)"
if [ "$HTTP_CODE" != "200" ]; then
  cat "$DIRECT_BODY" 2>/dev/null || true
  fail "Direct /api/chat returned HTTP $HTTP_CODE"
fi
if command -v jq >/dev/null 2>&1; then
  CONTENT="$(jq -r '.message.content // empty' "$DIRECT_BODY")"
else
  CONTENT="$(python3 -c "import json,sys; print(json.load(open('${DIRECT_BODY}'))['message']['content'])" 2>/dev/null || echo "")"
fi
if [ -z "$CONTENT" ]; then
  cat "$DIRECT_BODY" 2>/dev/null || true
  fail "Direct /api/chat returned empty content"
fi
pass "Direct Ollama response: ${CONTENT:0:120}"

# 4. n8n container can reach Ollama
info "Checking n8n container can reach host Ollama..."
if ! docker ps --format '{{.Names}}' | grep -q '^n8n$'; then
  fail "n8n container is not running"
fi
if ! docker exec n8n sh -c 'wget -qO- --timeout=5 http://host.docker.internal:11434/api/tags' >/dev/null 2>&1; then
  fail "n8n container cannot reach Ollama at host.docker.internal:11434"
fi
pass "n8n container can reach host Ollama"

# 5. Drive n8n Ollama chat template via webhook
info "Driving n8n chat trigger webhook..."
WF_BODY="$(mktemp)"
SESSION_ID="ollama-test-$$"
HTTP_CODE="$(curl -sS -o "$WF_BODY" -w '%{http_code}' \
  --max-time "${TIMEOUT_SECONDS}" \
  -X POST "${N8N_BASE_URL}/webhook/${OLLAMA_CHAT_WEBHOOK_ID}/chat" \
  -H 'Content-Type: application/json' \
  -d "{
    \"action\": \"sendMessage\",
    \"sessionId\": \"${SESSION_ID}\",
    \"chatInput\": \"Reply with exactly one short sentence saying hello.\"
  }" || echo 000)"
if [ "$HTTP_CODE" != "200" ]; then
  echo "--- response body ---"
  cat "$WF_BODY" 2>/dev/null || true
  echo "--- n8n logs (last 60 lines) ---"
  docker compose logs n8n --no-color 2>&1 | tail -60 || true
  rm -f "$WF_BODY"
  fail "n8n chat webhook returned HTTP $HTTP_CODE"
fi

if command -v jq >/dev/null 2>&1; then
  N8N_OUTPUT="$(jq -r '.output // .text // .response // .message // empty' "$WF_BODY")"
else
  N8N_OUTPUT="$(python3 -c "
import json,sys
d=json.load(open('${WF_BODY}'))
for k in ('output','text','response','message'):
    v=d.get(k)
    if isinstance(v,str) and v:
        print(v); break
" 2>/dev/null || echo "")"
fi
if [ -z "$N8N_OUTPUT" ]; then
  echo "--- response body ---"
  cat "$WF_BODY" 2>/dev/null || true
  rm -f "$WF_BODY"
  fail "n8n chat webhook returned no LLM output"
fi
rm -f "$WF_BODY"
pass "n8n -> Ollama response: ${N8N_OUTPUT:0:160}"

echo ""
pass "Ollama end-to-end integration checks passed"
