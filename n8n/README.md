# n8n seed data

This directory holds everything that gets imported into n8n on first start:

- Workflow JSON files (`demo-data/workflows/templates/`, `demo-data/workflows/builder-helpers/`, optional `examples/`)
- Encrypted credential JSON files (`demo-data/credentials/`)
- The activation list (`demo-data/workflow-ids.activate`)
- The human-readable index (`demo-data/manifest.json`)
- The Chat Hub agent SQL bootstrap (`demo-data/bootstrap.sql`)
- The one-shot importer script (`demo-data/import-templates.sh`)

For end-user documentation of what each workflow does, see [`templates/README.md`](../templates/README.md).

## First run vs later starts

`docker-compose.yml` defines two short-lived containers that run before the main `n8n` service starts:

1. **`n8n-import`** runs `demo-data/import-templates.sh` once per `volumes/n8n` volume:
   - Imports every credential under `demo-data/credentials/` (if any).
   - Imports every workflow under `demo-data/workflows/templates/` and `demo-data/workflows/builder-helpers/`.
   - Activates the workflow IDs listed in `workflow-ids.activate`.
   - Writes the marker file `.template-seed-complete` so the next start **skips** re-import.
2. **`n8n-bootstrap`** runs `demo-data/bootstrap.sql` against the Postgres `n8n` schema on **every** start:
   - Idempotently configures the Personal agent (Chat Hub → Personal agents → *Local Ollama Agent*) in `n8n.chat_hub_agents`.
   - Idempotently shares all seeded workflows with the first owner project so they show up in the UI.
   - Idempotently shares the seeded credentials.
3. **`n8n`** starts after both complete successfully (`service_completed_successfully`).

Import failures **abort startup** (no silent `|| echo warn` fallbacks). If `n8n-import` is the only thing failing, the marker file is intentionally not written — fix the cause, then either re-run `npm run setup` or `docker compose run --rm n8n-import`.

## Template inventory

User-facing (full docs in [`templates/README.md`](../templates/README.md)):

| Workflow ID | Name | Trigger | Notes |
| --- | --- | --- | --- |
| `bKhNvmpDfT4mclXo` | Template - Local Ollama Chat | LangChain chat (public webhook) | Needs Ollama + `OLLAMA_MODEL` |
| `c9a1b2c3d4e5f6789012345678ab` | Template - Supabase API Health Check | Webhook `POST /webhook/template-supabase-health` | Calls Kong on the Docker network |
| `d4e5f6a7b8c9012345678901234abcd` | Template - NodeBot Builder | Chat Hub workflow agent | Uses Ollama + 9 `toolWorkflow` helpers + MCP Client Tool |

Shipped templates also include **`f1e2…` — Document ingest + query (RAG)**, **`f8e9…` — AI Starter Console**, and **`fa0b…` — Starter Kit Index** (JSON catalog webhook) — see [`templates/README.md`](../templates/README.md) and [`demo-data/manifest.json`](demo-data/manifest.json).

Builder helper sub-workflows (called by NodeBot Builder live under `demo-data/workflows/builder-helpers/`):

| Workflow ID | Name |
| --- | --- |
| `e6f7a8b9c0d1e2f3a4b5c6d7e8f90123` | SK - Create Greeting Workflow |
| `a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6` | SK - Create Webhook Workflow |
| `b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7` | SK - Create Scheduled Workflow |
| `c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8` | SK - List Workflows |
| `f2e3d4c5b6a7988991bcdef23456789a` | SK - Create RAG Workflow |
| `f3e4d5c6b7a8999002cdef345678901b` | SK - Update Workflow |
| `f4e5d6c7b8a9000113def456789012c` | SK - Activate Deactivate Workflow |
| `f5e6d7c8b9a0111224ef567890123d` | SK - Delete Workflow |
| `f6e7d8c9b0a1222335f6789012345ef` | SK - Create Supabase Row Trigger Workflow |
| `f7e8d9c0b1a2333446a7890123456af` | SK - Starter Kit Status |
| `f9a0b1c2d3e4567890abcdef1234567a` | SK - Record AI Call |

All helpers are listed in `workflow-ids.activate` and **must stay active** so the builder can call them as sub-workflows.

## Chat Hub agents

Personal agents and Workflow agents in Chat Hub are stored in the `n8n.chat_hub_agents` table. We don't ship them as exported workflow JSON — they're upserted by `demo-data/bootstrap.sql`. To add a new Personal agent:

1. Build it in the n8n UI (Chat → New personal agent) and verify it works.
2. Inspect the row: `SELECT * FROM n8n.chat_hub_agents WHERE name = '<your agent>';`
3. Add a matching idempotent `INSERT ... ON CONFLICT` to `bootstrap.sql`.
4. Re-run `docker compose run --rm n8n-bootstrap`.

## Credential policy

- **Do not commit** real Supabase service-role keys, Stripe secrets, or third-party API tokens.
- The shipped `ollamaApi` credential is a local-dev placeholder encrypted with `N8N_ENCRYPTION_KEY`.
- The shipped MCP bearer credential is a local-dev placeholder. `scripts/setup.sh` rotates it from the first n8n owner's MCP access token; until then it's a stub.
- See [`demo-data/credentials/README.md`](demo-data/credentials/README.md) for the encryption format.

## Security defaults

- n8n UI basic auth is enabled by default (`N8N_BASIC_AUTH_*` in `.env.example` — change before exposing publicly).
- **Instance-level MCP is enabled** (`N8N_MCP_ACCESS_ENABLED=true`). It's reachable at `http://localhost:5678/mcp-server/http` and is guarded by the bearer token in `N8N_MCP_ACCESS_TOKEN`. Only expose this stack publicly after rotating that token and reviewing which workflows have `availableInMCP: true`.
- The Local Ollama Chat template's chat trigger uses `public: true` so it accepts webhook POSTs for automated tests. n8n webhooks are **not** protected by `N8N_BASIC_AUTH_*` by design — disable public mode on triggers or unbind port 5678 before exposing publicly.
- PostgREST does **not** expose the `n8n` schema (`PGRST_DB_SCHEMAS` excludes it).

## Exporting changes back into the repo

```bash
docker compose exec n8n n8n export:workflow --all --output=/demo-data/workflows --separate
# Move exports from workflows/ into workflows/templates/ vs workflows/builder-helpers/, then run npm run validate:workflows.
docker compose exec n8n n8n export:credentials --all --output=/demo-data/credentials --separate
```

Both write into `/demo-data`, which is bind-mounted to `./n8n/demo-data` on the host. When adding templates, also update `manifest.json` and `workflow-ids.activate`.

## Resetting n8n (re-seed templates)

```bash
./scripts/reset.sh
# or manually:
docker compose down
rm -rf volumes/n8n
docker compose up -d
```

This clears the bind-mounted n8n data directory and the seed marker, so the next start re-imports templates and re-runs the SQL bootstrap. The Postgres `n8n` schema is recreated on a full DB reset via [`volumes/db/n8n.sql`](../volumes/db/n8n.sql).

To force re-import **without** wiping data:

```bash
docker exec n8n rm -f /home/node/.n8n/.template-seed-complete
docker compose run --rm n8n-import
docker compose restart n8n
```
