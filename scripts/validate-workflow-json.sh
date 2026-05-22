#!/usr/bin/env bash
# Validate n8n seed workflow exports: JSON shape, filename id match, tags, active vs activate list.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

WF_DIR="$ROOT/n8n/demo-data/workflows"
TEMPLATES_DIR="$WF_DIR/templates"
HELPERS_DIR="$WF_DIR/builder-helpers"
ACTIVATE="$ROOT/n8n/demo-data/workflow-ids.activate"

for d in "$WF_DIR" "$TEMPLATES_DIR" "$HELPERS_DIR"; do
  if [ ! -d "$d" ]; then
    echo "❌ Missing directory $d" >&2
    exit 1
  fi
done
if [ ! -f "$ACTIVATE" ]; then
  echo "❌ Missing $ACTIVATE" >&2
  exit 1
fi

ROOT_JSON_COUNT="$(find "$WF_DIR" -maxdepth 1 -name '*.json' -print | wc -l | tr -d ' ')"
if [ "${ROOT_JSON_COUNT:-0}" != "0" ]; then
  echo "❌ Workflow JSON files must live under workflows/templates/ or workflows/builder-helpers/, not workflows/ root" >&2
  ls -la "$WF_DIR"/*.json 2>/dev/null || true
  exit 1
fi

export VALIDATE_ACTIVATE="$ACTIVATE"
export VALIDATE_WF_DIR="$WF_DIR"
python3 <<'PY'
import json
import os
import re
import sys
from pathlib import Path

activate_path = Path(os.environ["VALIDATE_ACTIVATE"]).resolve()
wf_dir = Path(os.environ["VALIDATE_WF_DIR"]).resolve()
templates_dir = wf_dir / "templates"
helpers_dir = wf_dir / "builder-helpers"

activate_lines = activate_path.read_text().splitlines()
activate_ids = {ln.strip() for ln in activate_lines if ln.strip() and not ln.strip().startswith('#')}

wf_files = sorted(templates_dir.glob('*.json')) + sorted(helpers_dir.glob('*.json'))
seen = {}
for path in wf_files:
    dup = seen.setdefault(path.name, [])
    dup.append(path)
conflicts = {n: paths for n, paths in seen.items() if len(paths) > 1}
if conflicts:
    for name, paths in sorted(conflicts.items()):
        locs = ", ".join(str(p.relative_to(wf_dir)) for p in paths)
        print(f"❌ Duplicate workflow JSON name {name}: {locs}", file=sys.stderr)
    sys.exit(1)

file_stems = {p.stem for p in wf_files}

if activate_ids != file_stems:
    missing_from_dir = sorted(activate_ids - file_stems)
    stray_files = sorted(file_stems - activate_ids)
    msg = []
    if missing_from_dir:
        msg.append(f"workflow-ids.activate lists ids with no JSON file: {missing_from_dir}")
    if stray_files:
        msg.append(f"Extra workflow JSON files not listed in workflow-ids.activate: {stray_files}")
    print("❌ " + " | ".join(msg), file=sys.stderr)
    sys.exit(1)


def hexish_id(ident: str) -> bool:
    if len(ident) == 32:
        return bool(re.fullmatch(r'[0-9a-f]{32}', ident))
    # Short historical n8n ids (still validate filename/key consistency)
    return bool(re.fullmatch(r'[0-9A-Za-z_-]{16,36}', ident)) and len(ident) >= 16

errors = []

for path in wf_files:
    stem = path.stem
    try:
        data = json.loads(path.read_text())
    except json.JSONDecodeError as e:
        errors.append(f"{path.name}: invalid JSON ({e})")
        continue
    wf_id = data.get('id')
    if wf_id != stem:
        errors.append(f"{path.name}: top-level id {wf_id!r} must match filename stem {stem!r}")
    tags = data.get('tags')
    if tags != []:
        errors.append(f"{path.name}: tags must be [], got {tags!r}")
    want_active = stem in activate_ids
    if data.get('active') != want_active:
        errors.append(f"{path.name}: active={data.get('active')!r} but workflow-ids.activate expects {want_active}")

    ident = wf_id if isinstance(wf_id, str) else ''
    if not hexish_id(ident):
        errors.append(f"{path.name}: id failed hex/shape validation: {ident!r}")

    # n8n 2.x requires versionId to be a proper UUID string. Free-form labels
    # (e.g. "ver-foo-001") cause the workflow to import but lack activeVersionId,
    # which breaks webhook activation.
    version_id = data.get('versionId')
    if not isinstance(version_id, str) or not re.fullmatch(
        r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
        version_id,
    ):
        errors.append(f"{path.name}: versionId must be a UUID (got {version_id!r})")

if errors:
    print("❌ Workflow validation errors:", file=sys.stderr)
    for e in errors:
        print(f"  - {e}", file=sys.stderr)
    sys.exit(1)

print(f"✅ {len(wf_files)} workflow JSON files OK (workflow-ids.activate + rules)")
PY
