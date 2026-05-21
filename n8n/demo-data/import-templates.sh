#!/bin/sh
# Runs inside the n8n-import container. Seeds workflows/credentials once per volume.
set -eu

MARKER="/home/node/.n8n/.template-seed-complete"
DEMO="/demo-data"

if [ -f "$MARKER" ]; then
  echo "Template seed already applied ($(cat "$MARKER")). Skipping import."
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

if [ -f "$DEMO/workflow-ids.activate" ]; then
  echo "Activating template workflows from manifest..."
  while IFS= read -r wf_id || [ -n "$wf_id" ]; do
    [ -z "$wf_id" ] && continue
    echo "  -> activate $wf_id"
    n8n update:workflow --id="$wf_id" --active=true
  done < "$DEMO/workflow-ids.activate"
else
  echo "ERROR: missing $DEMO/workflow-ids.activate"
  exit 1
fi

date -u +%Y-%m-%dT%H:%M:%SZ > "$MARKER"
echo "Template seed completed at $(cat "$MARKER")"
