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

info "Checking workflows are active in database..."
for wf_id in "$OLLAMA_ID" "$HEALTH_ID"; do
  ACTIVE="$(docker exec supabase-db psql -U postgres -t -A -c \
    "SELECT active FROM n8n.workflow_entity WHERE id = '${wf_id}';" 2>/dev/null | tr -d '[:space:]')"
  [ "$ACTIVE" = "t" ] || fail "Workflow $wf_id is not active (got: $ACTIVE)"
done
pass "Both template workflows present and active"

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
