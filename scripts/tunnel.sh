#!/usr/bin/env bash
# Spin up a Cloudflare Tunnel to expose the local stack to the internet.
# Free, no router config, automatic TLS, run from your laptop or a home server.
#
# Usage:
#   ./scripts/tunnel.sh                 # quick tunnel (random trycloudflare.com URL)
#   ./scripts/tunnel.sh --named NAME    # named tunnel using your Cloudflare account
#   ./scripts/tunnel.sh --service URL   # tunnel a different local URL (default: http://localhost:8000)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MODE="quick"
NAME=""
SERVICE_URL="http://localhost:8000"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --named) MODE="named"; NAME="${2:?--named requires a tunnel name}"; shift 2 ;;
    --service) SERVICE_URL="${2:?--service requires a URL}"; shift 2 ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0 ;;
    *) echo "Unknown flag: $1" >&2; exit 2 ;;
  esac
done

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "cloudflared is not installed."
  if command -v brew >/dev/null 2>&1; then
    echo "Installing via Homebrew..."
    brew install cloudflared
  else
    cat <<EOM
Install cloudflared, then re-run:
  macOS:  brew install cloudflared
  Linux:  see https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/
EOM
    exit 1
  fi
fi

if ! docker compose ps --format '{{.Names}}' 2>/dev/null | grep -q '^supabase-kong$'; then
  echo "Stack is not running. Start it first:"
  echo "  npm run setup     (interactive)"
  echo "  npm run dev:full  (already configured)"
  exit 1
fi

case "$MODE" in
  quick)
    echo "Starting quick tunnel to ${SERVICE_URL}..."
    echo "Watch for the 'https://*.trycloudflare.com' URL below. Ctrl-C to stop."
    echo
    exec cloudflared tunnel --url "${SERVICE_URL}"
    ;;
  named)
    if [ ! -f "${HOME}/.cloudflared/cert.pem" ]; then
      echo "You need to log in to Cloudflare first. Opening the login flow..."
      cloudflared tunnel login
    fi
    if ! cloudflared tunnel list 2>/dev/null | awk 'NR>1 {print $2}' | grep -qx "${NAME}"; then
      echo "Creating named tunnel: ${NAME}"
      cloudflared tunnel create "${NAME}"
      cat <<EOM

Named tunnel '${NAME}' created. To finish setup:

  1. Pick a hostname under a domain you control on Cloudflare (e.g. ai.example.com).
  2. Route it to this tunnel:
       cloudflared tunnel route dns ${NAME} ai.example.com
  3. Re-run this command and it will start the tunnel.

EOM
      exit 0
    fi
    echo "Starting named tunnel ${NAME} -> ${SERVICE_URL}"
    exec cloudflared tunnel run --url "${SERVICE_URL}" "${NAME}"
    ;;
esac
