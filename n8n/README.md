# n8n template seed

This directory holds the **template library v0** workflows and optional credentials imported by the `n8n-import` one-shot container in [`docker-compose.yml`](../docker-compose.yml).

## First run vs later starts

1. **`n8n-import`** runs `import-templates.sh` once per `volumes/n8n` volume:
   - Imports credentials (if present) and workflows from `demo-data/`.
   - Activates only workflow IDs listed in `workflow-ids.activate` (see `manifest.json`).
   - Writes marker `.template-seed-complete` so later stack starts **skip** re-import.
2. **`n8n`** starts after import completes successfully (`service_completed_successfully`).

Import failures **abort startup** (no silent `|| echo warn` fallbacks).

## Template library

| Workflow ID | Name | Trigger | Notes |
| ----------- | ---- | ------- | ----- |
| `bKhNvmpDfT4mclXo` | Template - Local Ollama Chat | LangChain chat (non-public) | Needs Ollama + `llama3.2:1b` (or change model in UI). |
| `c9a1b2c3d4e5f6789012345678ab` | Template - Supabase API Health Check | Webhook `POST /webhook/template-supabase-health` | Calls `http://kong:8000/auth/v1/health` on the Docker network. |

Full setup, env vars, and smoke-test commands: [`templates/README.md`](../templates/README.md).

## Credential policy

- **Do not commit** real Supabase service-role keys, Stripe secrets, or third-party API tokens.
- Shipped Ollama credential is a local-dev placeholder encrypted with `N8N_ENCRYPTION_KEY`.
- See [`demo-data/credentials/README.md`](demo-data/credentials/README.md).

## Security defaults

- n8n UI basic auth is enabled by default (`N8N_BASIC_AUTH_*` in `.env.example`).
- Template chat trigger is **not** public; enable public access only if you understand the exposure.
- PostgREST does **not** expose the `n8n` schema (`PGRST_DB_SCHEMAS` excludes it).

## Exporting changes back into the repo

```bash
docker compose exec n8n n8n export:workflow --all --output=/demo-data/workflows --separate
docker compose exec n8n n8n export:credentials --all --output=/demo-data/credentials --separate
```

Both write into `/demo-data`, bind-mounted to `./n8n/demo-data` on the host. Update `manifest.json` and `workflow-ids.activate` when adding templates.

## Resetting n8n (re-seed templates)

```bash
./scripts/reset.sh
# or manually:
docker compose down
rm -rf volumes/n8n
docker compose up -d
```

This clears the bind-mounted n8n data directory and removes the seed marker so the next start re-imports templates. The Postgres `n8n` schema is recreated on a full DB reset via [`volumes/db/n8n.sql`](../volumes/db/n8n.sql).
