#!/usr/bin/env bash
# Snapshot Postgres (pg_dumpall) plus n8n and storage volumes into backups/<timestamp>.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TS="$(date +%Y%m%d-%H%M%S)"
OUT="${BACKUP_DIR_OVERRIDE:-${ROOT}/backups/${TS}}"
mkdir -p "$OUT"

if ! docker compose ps --format '{{.Service}} {{.State}}' 2>/dev/null | grep -q '^db running'; then
  echo "❌ Postgres container (db service) must be running. Start the stack then retry." >&2
  exit 1
fi

echo "Writing ${OUT}/pg_dumpall.sql ..."
docker exec supabase-db pg_dumpall -U postgres --clean --if-exists >"${OUT}/pg_dumpall.sql"

echo "Archiving volumes/n8n and volumes/storage → ${OUT}/volumes.tgz ..."
mkdir -p "${ROOT}/volumes/n8n" "${ROOT}/volumes/storage"
tar -czf "${OUT}/volumes.tgz" -C "$ROOT/volumes" n8n storage

echo ""
echo "✅ Backup complete: ${OUT}"
