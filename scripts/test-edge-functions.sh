#!/usr/bin/env bash
# Curl Supabase Functions through Kong using ANON_KEY from .env (hello function).
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
info() { echo "ℹ️  $1"; }

if [ -f .env ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then export "$line"; fi
  done < .env
fi

KONG_PORT="${KONG_HTTP_PORT:-8000}"
HELLO_URL="http://localhost:${KONG_PORT}/functions/v1/hello"
ANON="${ANON_KEY:-}"

if [ -z "$ANON" ]; then
  fail "ANON_KEY not set (.env)"
fi

info "GET ${HELLO_URL}"
BODY="$(mktemp)"
HTTP_CODE="$(curl -sS -o "$BODY" -w '%{http_code}' --max-time 30 \
  "$HELLO_URL" \
  -H "Authorization: Bearer ${ANON}" \
  -H 'apikey: '"${ANON}" || echo 000)"

if [ "$HTTP_CODE" != "200" ]; then
  cat "$BODY" 2>/dev/null || true
  rm -f "$BODY"
  fail "Edge function returned HTTP $HTTP_CODE (expected 200). Is kong + functions containers up?"
fi

grep -qi 'hello' "$BODY" || {
  cat "$BODY"
  rm -f "$BODY"
  fail "Response did not mention hello"
}
rm -f "$BODY"
pass "functions/v1/hello reachable through Kong"
