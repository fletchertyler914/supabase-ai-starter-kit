#!/bin/sh
# Runs inside the n8n-import container. Idempotent and self-healing:
# - If the marker exists AND every expected workflow ID is present in the n8n DB, skip.
# - Otherwise, (re-)import credentials + workflows and (re-)activate the listed IDs.
set -eu

MARKER="/home/node/.n8n/.template-seed-complete"
DEMO="/demo-data"
ACTIVATE_FILE="$DEMO/workflow-ids.activate"

list_workflows() { n8n list:workflow 2>/dev/null || true; }

needs_import() {
  if [ ! -f "$MARKER" ]; then
    echo "No template seed marker — will import."
    return 0
  fi
  if [ ! -f "$ACTIVATE_FILE" ]; then
    return 1
  fi
  EXISTING="$(list_workflows)"
  while IFS= read -r wf_id || [ -n "$wf_id" ]; do
    [ -z "$wf_id" ] && continue
    if ! printf '%s\n' "$EXISTING" | grep -q "^${wf_id}|"; then
      echo "Marker present but expected workflow $wf_id missing — re-importing."
      return 0
    fi
  done < "$ACTIVATE_FILE"
  return 1
}

if ! needs_import; then
  echo "Template seed already applied and all workflows present ($(cat "$MARKER" 2>/dev/null || echo "?")). Skipping import."
  exit 0
fi

CRED_COUNT=0
if [ -d "$DEMO/credentials" ]; then
  for f in "$DEMO/credentials"/*.json; do
    [ -f "$f" ] || continue
    CRED_COUNT=$((CRED_COUNT + 1))
  done
fi
if [ "$CRED_COUNT" -gt 0 ]; then
  echo "Importing template credentials..."
  n8n import:credentials --separate --input="$DEMO/credentials"
else
  echo "No credential files to import (configure credentials in n8n UI per manifest)."
fi

echo "Importing template workflows..."
n8n import:workflow --separate --input="$DEMO/workflows"

if [ -f "$ACTIVATE_FILE" ]; then
  echo "Activating template workflows from manifest..."
  while IFS= read -r wf_id || [ -n "$wf_id" ]; do
    [ -z "$wf_id" ] && continue
    echo "  -> activate $wf_id"
    n8n update:workflow --id="$wf_id" --active=true
  done < "$ACTIVATE_FILE"
else
  echo "ERROR: missing $ACTIVATE_FILE"
  exit 1
fi

date -u +%Y-%m-%dT%H:%M:%SZ > "$MARKER"
echo "Template seed completed at $(cat "$MARKER")"
