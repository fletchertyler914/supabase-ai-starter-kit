#!/usr/bin/env bash
# Compare pinned Compose image references with Docker Hub "latest" digests where applicable.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Pinned image lines in Compose (n8n / Ollama / MinIO):"

{
  grep -h -E '^[[:space:]]+image:.*(n8nio/n8n|ollama/ollama|minio/minio|minio/mc)' \
    "${ROOT}/docker-compose.yml" \
    "${ROOT}/docker/docker-compose.s3.yml" 2>/dev/null || true
} | sort -u

echo ""
python3 <<'PY'
import json
import urllib.request

SERVICES = [
    ("Docker Hub — n8n", "https://hub.docker.com/v2/repositories/n8nio/n8n/tags/latest"),
    ("Docker Hub — ollama", "https://hub.docker.com/v2/repositories/ollama/ollama/tags/latest"),
    ("Docker Hub — minio", "https://hub.docker.com/v2/repositories/minio/minio/tags/latest"),
]

for title, url in SERVICES:
    try:
        with urllib.request.urlopen(url, timeout=15) as r:
            j = json.load(r)
    except Exception as e:
        print(f"{title}: (could not fetch: {e})")
        continue
    digest = j.get("digest")
    imgs = [x for x in (j.get("images") or []) if x.get("digest")]
    arch = imgs[0] if imgs else {}
    size_mb = ""
    if arch.get("size"):
        size_mb = f" (~{arch['size'] / (1024*1024):.0f} MB compressed)"
    if digest:
        print(f"{title} latest digest: {digest}{size_mb}")
    else:
        print(f"{title}: (response had no digest)")

PY

echo ""
echo "Local images matching Compose pins (after docker compose pull):"

first_image_matching() {
  local pattern="$1"
  grep -h -E "^[[:space:]]+image:[[:space:]].*${pattern}" \
    "${ROOT}/docker-compose.yml" \
    "${ROOT}/docker/docker-compose.s3.yml" 2>/dev/null \
    | head -1 \
    | sed -E 's/^[[:space:]]+image:[[:space:]]*//' \
    | tr -d '\r' \
    | sed -e 's/^"\(.*\)"$/\1/' \
    | sed -e "s/^'\\(.*\\)'$/\\1/"
}

show_local() {
  local name="$1"
  local img="$2"
  img="$(echo "$img" | sed 's/^["'\'']//; s/["'\'']$//')"
  if [ -z "$img" ]; then
    echo "${name}: (no Compose image reference found)"
    return
  fi
  if docker image inspect "$img" >/dev/null 2>&1; then
    docker image inspect "$img" --format "${name}: ${img} → {{.Id}} (created {{.Created}})" 2>/dev/null
  else
    echo "${name}: ${img} not present locally — run: docker pull ${img}"
  fi
}

N8N_REF="$(first_image_matching 'n8nio/n8n')"
OLLAMA_REF="$(first_image_matching 'ollama/ollama')"
MINIO_REF="$(first_image_matching 'minio/minio')"
show_local n8n "$N8N_REF"
show_local ollama "$OLLAMA_REF"
show_local minio "$MINIO_REF"
