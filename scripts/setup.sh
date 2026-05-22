#!/usr/bin/env bash
# Interactive setup wizard for Supabase AI Starter Kit.
# Goal: a non-dev can run `npm run setup` and end up with everything working.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BOLD=$'\e[1m'; DIM=$'\e[2m'
RED=$'\e[31m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'; BLUE=$'\e[34m'; CYAN=$'\e[36m'; NC=$'\e[0m'

OLLAMA_MODEL="${OLLAMA_MODEL:-llama3.2:3b}"
OLLAMA_BUILDER_MODEL="${OLLAMA_BUILDER_MODEL:-llama3.2:3b}"
HOST_OLLAMA_URL="http://localhost:11434"
SKIP_VALIDATE="${SKIP_VALIDATE:-0}"
AUTO_YES="${SETUP_YES:-0}"
OPEN_BROWSER="${SETUP_OPEN_BROWSER:-1}"

print_header() {
  echo
  echo "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo "${BOLD}${CYAN}║       Supabase AI Starter Kit — interactive setup wizard       ║${NC}"
  echo "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
  echo "${DIM}Checks Docker + Ollama, configures .env, pulls models, starts stack, validates.${NC}"
  echo
}

step() { echo; echo "${BOLD}${BLUE}==>${NC} ${BOLD}$1${NC}"; }
ok() { echo "  ${GREEN}✓${NC} $1"; }
warn() { echo "  ${YELLOW}!${NC} $1"; }
fail() { echo "  ${RED}✗${NC} $1"; exit 1; }
info() { echo "  ${DIM}$1${NC}"; }

confirm() {
  local prompt="$1" default="${2:-y}" reply
  if [ "$AUTO_YES" = "1" ]; then return 0; fi
  read -r -p "  ${BOLD}?${NC} ${prompt} [${default}] " reply
  reply="${reply:-$default}"
  [[ "$reply" =~ ^[Yy]$ ]]
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1. $2"
}

# ---------- 1. Prereqs ----------
print_header
step "Checking required commands"
require_cmd docker "Install Docker Desktop (https://docs.docker.com/desktop/)."
require_cmd curl "Install curl (preinstalled on macOS/Linux)."
require_cmd openssl "Install openssl (preinstalled on macOS/Linux)."
ok "docker $(docker --version | awk '{print $3}' | tr -d ',')"
ok "curl $(curl --version | head -1 | awk '{print $2}')"
ok "openssl present"

if ! docker info >/dev/null 2>&1; then
  fail "Docker daemon is not running. Start Docker Desktop and re-run: npm run setup"
fi
ok "docker daemon running"

# ---------- 2. .env ----------
step "Configuring .env"
if [ ! -f .env ]; then
  cp .env.example .env
  ok "Created .env from .env.example (defaults are safe for local dev)"
else
  ok ".env already exists (leaving as-is)"
fi

# Load .env for downstream steps
set -a
while IFS= read -r line || [ -n "$line" ]; do
  [[ "$line" =~ ^[[:space:]]*$ ]] && continue
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] && export "$line"
done < .env
set +a

ENCRYPTION_KEY="${N8N_ENCRYPTION_KEY:-super-secret-key}"

# ---------- 3. Ollama detection ----------
step "Detecting Ollama"
USE_CONTAINER_OLLAMA=0
OLLAMA_REACHABLE=0
if curl -sS --max-time 3 "${HOST_OLLAMA_URL}/api/tags" >/dev/null 2>&1; then
  OLLAMA_REACHABLE=1
  ok "Host Ollama reachable at ${HOST_OLLAMA_URL}"
fi

if [ "$OLLAMA_REACHABLE" = "1" ]; then
  ok "Using host Ollama (fastest, especially on Apple Silicon)"
else
  warn "Host Ollama not reachable."
  if command -v ollama >/dev/null 2>&1; then
    warn "Ollama is installed but not running. Start the Ollama app/daemon, or proceed with containerized Ollama."
  else
    info "You can either:"
    info "  • install host Ollama (https://ollama.com/download) and re-run setup, or"
    info "  • use containerized Ollama (this script can start it for you)"
  fi
  if confirm "Use containerized Ollama (CPU profile) instead?" y; then
    USE_CONTAINER_OLLAMA=1
    ok "Will use containerized Ollama (--profile cpu)"
  else
    fail "Aborting. Install/start Ollama, then re-run: npm run setup"
  fi
fi

# ---------- 4. Configure n8n Ollama credential URL ----------
step "Configuring n8n → Ollama URL"
CRED_FILE="n8n/demo-data/credentials/VmhEukzPe8au9PTB.json"
if [ "$USE_CONTAINER_OLLAMA" = "1" ]; then
  OLLAMA_NODE_URL="http://ollama:11434"
else
  OLLAMA_NODE_URL="http://host.docker.internal:11434"
fi
ENC_DATA=$(printf '%s' "{\"baseUrl\":\"${OLLAMA_NODE_URL}\"}" \
  | openssl enc -aes-256-cbc -md md5 -salt -pass pass:"${ENCRYPTION_KEY}" -base64 -A 2>/dev/null)
cat > "$CRED_FILE" <<EOF
{
  "createdAt": "2026-05-21T12:00:00.000Z",
  "updatedAt": "2026-05-21T12:00:00.000Z",
  "id": "VmhEukzPe8au9PTB",
  "name": "Self Hosted Ollama",
  "data": "${ENC_DATA}",
  "type": "ollamaApi",
  "isManaged": false
}
EOF
ok "n8n credential points to ${OLLAMA_NODE_URL}"

BUILDER_WORKFLOW_FILE="$(find "${ROOT}/n8n/demo-data/workflows" -name 'd4e5f6a7b8c9012345678901234abcd.json' 2>/dev/null | head -1)"
if [ -f "$BUILDER_WORKFLOW_FILE" ]; then
  python3 - "$BUILDER_WORKFLOW_FILE" "$OLLAMA_BUILDER_MODEL" <<'PY'
from pathlib import Path
import json
import sys

path = Path(sys.argv[1])
model = sys.argv[2]
workflow = json.loads(path.read_text())
for node in workflow.get("nodes", []):
    if node.get("type") == "@n8n/n8n-nodes-langchain.lmChatOllama" and node.get("name") == "Builder Ollama Model":
        node.setdefault("parameters", {})["model"] = model
path.write_text(json.dumps(workflow, indent=2) + "\n")
PY
  ok "NodeBot Builder model set to ${OLLAMA_BUILDER_MODEL}"
fi

# ---------- 5. Pull models ----------
step "Ensuring Ollama models are available"
if [ "$USE_CONTAINER_OLLAMA" = "1" ]; then
  info "Will pull models after starting the containerized Ollama"
else
  for model in "${OLLAMA_MODEL}" "${OLLAMA_BUILDER_MODEL}"; do
    if curl -sS "${HOST_OLLAMA_URL}/api/tags" | grep -q "\"${model}\""; then
      ok "Model ${model} already present"
    else
      info "Pulling ${model}..."
      if command -v ollama >/dev/null 2>&1; then
        ollama pull "${model}"
      else
        curl -sS -X POST "${HOST_OLLAMA_URL}/api/pull" \
          -H 'Content-Type: application/json' \
          -d "{\"name\":\"${model}\",\"stream\":false}" \
          --max-time 900 >/dev/null
      fi
      ok "Model ${model} pulled"
    fi
  done
fi

# ---------- 6. Start the stack ----------
step "Starting the stack"
mkdir -p volumes/n8n volumes/db/data volumes/storage
chmod -R 777 volumes/n8n volumes/db/data volumes/storage 2>/dev/null || true

if [ "$USE_CONTAINER_OLLAMA" = "1" ]; then
  ./scripts/start.sh --cpu --detach
else
  npm run dev:full
fi

# ---------- 7. Wait for ready ----------
step "Waiting for services"
N8N_AUTH_USER="${N8N_BASIC_AUTH_USER:-admin}"
N8N_AUTH_PASS="${N8N_BASIC_AUTH_PASSWORD:-changeme}"
for i in $(seq 1 60); do
  KONG=$(curl --connect-timeout 2 --max-time 3 -sS -o /dev/null -w '%{http_code}' http://localhost:8000/health 2>/dev/null || true)
  N8N=$(curl --connect-timeout 2 --max-time 3 -sS -o /dev/null -w '%{http_code}' -u "${N8N_AUTH_USER}:${N8N_AUTH_PASS}" http://localhost:5678 2>/dev/null || true)
  echo "  attempt $i: kong=${KONG:-?} n8n=${N8N:-?}"
  if [ "$KONG" = "401" ] && [ "$N8N" = "200" ]; then
    ok "Core endpoints ready"
    break
  fi
  if [ "$i" = "60" ]; then fail "Timed out waiting for services. Check: docker compose logs"; fi
  sleep 5
done

# ---------- 8. Ensure n8n owner account (REST bootstrap when DB has no users) ----------
step "Ensuring n8n owner account"
N8N_OWNER_EMAIL="${N8N_OWNER_EMAIL:-admin@starter-kit.local}"
N8N_OWNER_PASSWORD="${N8N_OWNER_PASSWORD:-changeme-n8n-owner}"
N8N_OWNER_FIRST_NAME="${N8N_OWNER_FIRST_NAME:-Starter}"
N8N_OWNER_LAST_NAME="${N8N_OWNER_LAST_NAME:-Admin}"

if docker compose ps --format '{{.Service}} {{.State}}' | grep -q '^db running'; then
  OWNER_COUNT="$(docker exec supabase-db psql -U postgres -d postgres -t -A -c \
    'SELECT COUNT(*)::text FROM n8n."user";' 2>/dev/null | tr -d '[:space:]' || true)"
else
  OWNER_COUNT=""
fi

if [ -n "${OWNER_COUNT:-}" ] && [ "${OWNER_COUNT}" != "0" ]; then
  ok "n8n owner already present (${OWNER_COUNT} user(s))"
else
  OWNER_JSON="$(OWNER_EMAIL="$N8N_OWNER_EMAIL" OWNER_PASSWORD="$N8N_OWNER_PASSWORD" OWNER_FN="$N8N_OWNER_FIRST_NAME" OWNER_LN="$N8N_OWNER_LAST_NAME" python3 - <<'PY'
import json, os

print(
    json.dumps(
        {
            "email": os.environ["OWNER_EMAIL"],
            "firstName": os.environ["OWNER_FN"],
            "lastName": os.environ["OWNER_LN"],
            "password": os.environ["OWNER_PASSWORD"],
        }
    )
)
PY
)"
  OWNER_OK=0
  for attempt in $(seq 1 12); do
    BODY_FILE="$(mktemp)"
    HTTP_CODE="$(curl -sS -o "$BODY_FILE" --connect-timeout 2 --max-time 30 \
      -w '%{http_code}' \
      -u "${N8N_AUTH_USER}:${N8N_AUTH_PASS}" \
      -H 'Content-Type: application/json' \
      -d "$OWNER_JSON" \
      -X POST 'http://localhost:5678/rest/owner/setup' 2>/dev/null || echo 000)"
    rm -f "$BODY_FILE"
    if [ "$HTTP_CODE" = "200" ]; then
      OWNER_OK=1
      ok "Registered n8n owner (${N8N_OWNER_EMAIL}) via /rest/owner/setup"
      break
    fi
    info "n8n owner setup attempt ${attempt}/12 HTTP ${HTTP_CODE} — retrying…"
    if [ "$attempt" = "12" ]; then
      warn "Could not bootstrap n8n owner via REST. Create owner in UI or retry setup."
      break
    fi
    sleep 5
  done
  if [ "$OWNER_OK" = "1" ] && docker compose ps --format '{{.Service}} {{.State}}' | grep -q '^db running'; then
    if [ "$(docker exec supabase-db psql -U postgres -d postgres -t -A -c \
      'SELECT COUNT(*)::text FROM n8n."user";' 2>/dev/null | tr -d '[:space:]')" = "0" ]; then
      warn "Owner setup returned 200 but n8n.user is still empty — check n8n logs."
    fi
  fi
fi

# ---------- 9. Configure n8n MCP token and credential ----------
step "Configuring n8n MCP access"
if docker compose ps --format '{{.Service}} {{.State}}' | grep -q '^db running'; then
  N8N_OWNER_ID="$(docker exec supabase-db psql -U postgres -d postgres -t -A -c \
    "SELECT id FROM n8n.\"user\" ORDER BY \"createdAt\" LIMIT 1;" 2>/dev/null | tr -d '[:space:]' || true)"
else
  N8N_OWNER_ID=""
fi

if [ -n "$N8N_OWNER_ID" ]; then
  MCP_TOKEN="$(N8N_OWNER_ID="$N8N_OWNER_ID" N8N_JWT_SECRET="${N8N_USER_MANAGEMENT_JWT_SECRET:-even-more-secret}" python3 - <<'PY'
import base64, hashlib, hmac, json, os, time, uuid

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()

header = {"alg": "HS256", "typ": "JWT"}
payload = {
    "sub": os.environ["N8N_OWNER_ID"],
    "iss": "n8n",
    "aud": "mcp-server-api",
    "jti": str(uuid.uuid4()),
    "iat": int(time.time()),
}
secret = os.environ["N8N_JWT_SECRET"].encode()
signing_input = f"{b64url(json.dumps(header, separators=(',', ':')).encode())}.{b64url(json.dumps(payload, separators=(',', ':')).encode())}"
signature = hmac.new(secret, signing_input.encode(), hashlib.sha256).digest()
print(f"{signing_input}.{b64url(signature)}")
PY
)"
  docker exec -i supabase-db psql -U postgres -d postgres >/dev/null <<SQL
INSERT INTO n8n.user_api_keys (id, "userId", label, "apiKey", scopes, audience, "createdAt", "updatedAt")
VALUES (gen_random_uuid()::text, '${N8N_OWNER_ID}', 'MCP Server API Key', '${MCP_TOKEN}', '[]'::json, 'mcp-server-api', NOW(), NOW())
ON CONFLICT ("userId", label) DO UPDATE
SET "apiKey" = EXCLUDED."apiKey",
    scopes = EXCLUDED.scopes,
    audience = EXCLUDED.audience,
    "updatedAt" = NOW();
SQL

  python3 - "$MCP_TOKEN" <<'PY'
from pathlib import Path
import sys

path = Path(".env")
token = sys.argv[1]
lines = path.read_text().splitlines()
for i, line in enumerate(lines):
    if line.startswith("N8N_MCP_ACCESS_TOKEN="):
        lines[i] = f"N8N_MCP_ACCESS_TOKEN={token}"
        break
else:
    lines.append(f"N8N_MCP_ACCESS_TOKEN={token}")
path.write_text("\n".join(lines) + "\n")
PY

  ENC_MCP_DATA=$(printf '%s' "{\"token\":\"${MCP_TOKEN}\"}" \
    | openssl enc -aes-256-cbc -md md5 -salt -pass pass:"${ENCRYPTION_KEY}" -base64 -A 2>/dev/null)
  MCP_CRED_FILE="n8n/demo-data/credentials/N8NMcpBearer001.json"
  cat > "$MCP_CRED_FILE" <<EOF
{
  "createdAt": "2026-05-21T12:00:00.000Z",
  "updatedAt": "2026-05-21T12:00:00.000Z",
  "id": "N8NMcpBearer001",
  "name": "n8n MCP Access Token",
  "data": "${ENC_MCP_DATA}",
  "type": "httpBearerAuth",
  "isManaged": false
}
EOF
  docker exec -i supabase-db psql -U postgres -d postgres >/dev/null <<SQL
INSERT INTO n8n.credentials_entity (id, name, data, type, "isManaged", "createdAt", "updatedAt")
VALUES ('N8NMcpBearer001', 'n8n MCP Access Token', '${ENC_MCP_DATA}', 'httpBearerAuth', false, NOW(), NOW())
ON CONFLICT (id) DO UPDATE
SET data = EXCLUDED.data,
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    "updatedAt" = NOW();
SQL
  docker compose up n8n-bootstrap --no-deps >/dev/null || true
  ok "n8n MCP token and credential configured for the first owner"
else
  warn "No n8n owner account exists yet. Create your first n8n account, then re-run npm run setup to auto-wire MCP credentials."
fi

# ---------- 10. Pull model into container Ollama (if applicable) ----------
if [ "$USE_CONTAINER_OLLAMA" = "1" ]; then
  step "Pulling Ollama models into containerized Ollama"
  for model in "${OLLAMA_MODEL}" "${OLLAMA_BUILDER_MODEL}"; do
    if docker exec ollama ollama pull "${model}"; then
      ok "Model ${model} pulled into container"
    else
      warn "Failed to pull ${model} into container — related workflows will not respond until you pull it manually:"
      info "  docker exec ollama ollama pull ${model}"
    fi
  done
fi

# ---------- 10. Validate ----------
if [ "$SKIP_VALIDATE" = "0" ]; then
  step "Running validation suite (this exercises real auth, DB, templates, Ollama)"
  if npm test; then
    ok "All validation tests passed"
  else
    warn "Some validation tests failed — see output above. Stack is still running."
  fi
fi

# ---------- 12. Summary ----------
step "Ready"
cat <<EOF

  ${BOLD}${GREEN}Everything is up.${NC}

  ${BOLD}Open these:${NC}
    • n8n (workflows):        http://localhost:5678   (user: ${N8N_AUTH_USER} / pass: ${N8N_AUTH_PASS})
    • Supabase Studio:        http://localhost:8000   (basic auth via DASHBOARD_USERNAME/PASSWORD)
    • Inbucket (dev email):   http://localhost:9000
    • MinIO (S3 console):     http://localhost:9101

  ${BOLD}Try the templates:${NC}
    • Supabase health:
        curl -s -X POST http://localhost:5678/webhook/template-supabase-health
    • Ollama chat (real LLM):
        curl -s -X POST http://localhost:5678/webhook/ba65d0a2-7d1d-4efe-9e7a-c41b1031e3bb/chat \\
          -H 'Content-Type: application/json' \\
          -d '{"action":"sendMessage","sessionId":"hello","chatInput":"Say hi"}'

  ${BOLD}Useful commands:${NC}
    npm test            # re-run the full validation
    npm run logs        # tail logs
    npm stop            # stop the stack (keeps data)
    npm run reset       # wipe and start clean

  ${BOLD}Next:${NC} read ${BOLD}EXTENDING.md${NC} for how to add your own workflows / integrations.

EOF

if [ "$OPEN_BROWSER" = "1" ]; then
  if command -v open >/dev/null 2>&1; then
    open http://localhost:5678 >/dev/null 2>&1 || true
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open http://localhost:5678 >/dev/null 2>&1 || true
  fi
fi
