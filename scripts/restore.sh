#!/usr/bin/env bash
# Restore pg_dumpall from backup dir and extract volumes tarball.
# ⚠️  Destroys current DB definitions and replaces volume dirs — stop workloads first or take another backup.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

usage() {
  echo "Usage: $0 /path/to/backup/dir" >&2
  echo "Expects pg_dumpall.sql and volumes.tgz in that directory." >&2
}

if [ "${1:-}" = "" ]; then usage; exit 1; fi
BK="$1"
SQL="${BK%/}/pg_dumpall.sql"
TGZ="${BK%/}/volumes.tgz"

[ -f "$SQL" ] || { echo "❌ Missing $SQL" >&2; exit 1; }
[ -f "$TGZ" ] || { echo "❌ Missing $TGZ" >&2; exit 1; }

if ! docker compose ps --format '{{.Service}} {{.State}}' 2>/dev/null | grep -q '^db running'; then
  echo "❌ Postgres container (db service) must be running." >&2
  exit 1
fi

if [ "${RESTORE_I_KNOW_THIS_IS_DESTRUCTIVE:-}" != "1" ]; then
  cat <<EOF >&2

This will REPLACE the Postgres cluster data from pg_dumpall and overwrite volumes/n8n + volumes/storage.

Re-run with: RESTORE_I_KNOW_THIS_IS_DESTRUCTIVE=1 $0 "$BK"

EOF
  exit 1
fi

echo "Restoring database from pg_dumpall (this may disconnect clients) ..."
docker exec -i supabase-db psql -U postgres -v ON_ERROR_STOP=1 <"$SQL"

echo "Extracting volume archive into ${ROOT}/volumes ..."
mkdir -p "${ROOT}/volumes"
tar -xzf "$TGZ" -C "${ROOT}/volumes"

echo "✅ Restore steps finished — restart compose if services were running (npm restart or docker compose restart)."
