# Upgrading

This file is the operator-facing checklist for upgrading the kit. Critical images use
explicit tags in [`docker-compose.yml`](./docker-compose.yml); run
[`scripts/upgrade-check.sh`](./scripts/upgrade-check.sh) (`npm run upgrade:check`) occasionally
to compare pinned tags against Docker Hub digest metadata.

## Currently pinned versions

Last bumped: 2026-05-22 (mirrors the Supabase `master` docker-compose matrix + the latest stable n8n 2.x and Ollama 0.24).

| Component | Image / Tag | Source of truth |
| --- | --- | --- |
| Supabase Studio | `supabase/studio:2026.04.27-sha-5f60601` | `docker-compose.yml` `studio.image` |
| GoTrue (Auth) | `supabase/gotrue:v2.186.0` | `auth.image` |
| Kong API Gateway | `kong/kong:3.9.1` | `kong.image` |
| PostgREST | `postgrest/postgrest:v14.8` | `rest.image` |
| Realtime | `supabase/realtime:v2.76.5` | `realtime.image` |
| Storage API | `supabase/storage-api:v1.48.26` | `storage.image` |
| imgproxy | `darthsim/imgproxy:v3.30.1` | `imgproxy.image` |
| postgres-meta | `supabase/postgres-meta:v0.96.3` | `meta.image` |
| Edge Runtime (Functions) | `supabase/edge-runtime:v1.71.2` | `functions.image` |
| Logflare (Analytics) | `supabase/logflare:1.36.1` | `analytics.image` |
| Postgres + pgvector | `supabase/postgres:15.8.1.085` | `db.image` |
| Vector (logs) | `timberio/vector:0.53.0-alpine` | `vector.image` |
| Supavisor (pooler) | `supabase/supavisor:2.7.4` | `supavisor.image` |
| MinIO (dev:s3) | `minio/minio:latest` | `docker/docker-compose.s3.yml` |
| **n8n** | **`n8nio/n8n:2.21.7`** | `x-n8n` anchor |
| Inbucket (dev:email) | `inbucket/inbucket:3.0.3` | `docker/docker-compose.email.yml` |
| **Ollama** | **`ollama/ollama:0.24.0`** | `x-ollama` / `x-init-ollama` |
| **Ollama (AMD ROCm)** | **`ollama/ollama:0.24.0-rocm`** | `ollama-gpu-amd` overrides |

MinIO remains on `:latest` in the optional S3 dev overlay because it tracks frequent patch releases.

> **Heads up — major bumps from 2026-05-22:** Kong jumped from `2.8.1` to `3.9.1`
> (new declarative-config path `/usr/local/kong/kong.yml`, new `kong-entrypoint.sh`,
> expanded plugin list, and the optional `SUPABASE_PUBLISHABLE_KEY` / `SUPABASE_SECRET_KEY`
> opaque-key pathway introduced upstream). PostgREST jumped two majors from `v12.2.12`
> to `v14.8`. n8n jumped a full major from `1.117.0` to `2.21.7`. **Re-run
> `npm test` end-to-end after pulling these images** and re-check `volumes/api/kong.yml`
> against your custom routes if you have any.

## Workflow seed checks

Before or after upgrading n8n specifically, validate shipped workflow exports stay consistent:

```bash
npm run validate:workflows
```

This runs `./scripts/validate-workflow-json.sh`, which asserts every ID in `workflow-ids.activate`
exists under `workflows/templates/` + `workflows/builder-helpers/` and matches the exported JSON rules.

## Upgrade workflow

### 1. In-place upgrade (preserves data)

```bash
docker compose pull
docker compose up -d
npm run health
npm run test:db
npm run verify
```

Works for patch-level bumps on pinned tags plus pulling newer MinIO `:latest`.

### 2. Bumping a pinned tag

1. Update the tag in `docker-compose.yml` (or the relevant overlay).
2. Read the upstream changelog for breaking changes — especially Postgres, GoTrue,
   Realtime, Storage API, **n8n MCP / LangChain nodes**, and Ollama often have surprises.
3. Optionally capture new digests and refresh the table above / comment next to `image:` lines.
4. Run `./scripts/upgrade-check.sh` to sanity-check Compose plus Hub metadata.
5. Back up the database before running:
   ```bash
   docker exec supabase-db pg_dumpall -U postgres > backup-$(date +%Y%m%d-%H%M%S).sql
   ```
6. Pull, restart, and validate:
   ```bash
   docker compose pull
   docker compose up -d
   npm run validate:workflows
   npm test
   ```

### 3. Clean-slate upgrade

When you want a fully fresh stack on the new image versions:

```bash
./scripts/reset.sh              # interactive; preserves Ollama models
docker compose pull
npm start
npm test
```

`./scripts/reset.sh --clear-ollama` also wipes Ollama model volumes.

## What survives `docker compose down`

Persistent bind mounts (kept until explicitly deleted):

- `volumes/db/data` — Postgres data directory
- `volumes/storage` — Storage API filesystem backend (also MinIO data in `dev:s3`)
- `volumes/n8n` — n8n encrypted credentials and working data

Named volumes (kept until `docker compose down -v`):

- `db-config` — Postgres custom config (pgsodium decryption key)
- `ollama_storage` — downloaded LLM weights

## Pre-flight checklist for any release

- [ ] `npm run validate:workflows`
- [ ] `docker compose config --quiet` for base + every overlay (`scripts/start.sh` + npm scripts)
- [ ] `./scripts/upgrade-check.sh` if you touched `n8nio/*` or `ollama/*`
- [ ] `npm run health`
- [ ] `npm run test:db`
- [ ] `npm run test:auth`
- [ ] `npm run test:templates` — workflow shape, activation, MCP enablement, helper presence
- [ ] `npm run test:builder` — MCP endpoint and NodeBot Builder readiness
- [ ] `npm run test:ollama` — end-to-end LLM round-trip through the seeded webhook
- [ ] Confirm `volumes/logs/vector.yml` container-name matches still align with
      `docker-compose.yml` (`supabase-kong`, `supabase-auth`, `supabase-rest`,
      `realtime-dev.supabase-realtime`, `supabase-storage`,
      `supabase-edge-functions`, `supabase-db`).
- [ ] Confirm `volumes/api/kong.yml` upstream hostnames (`auth`, `rest`,
      `realtime-dev.supabase-realtime`, `storage`, `functions`, `meta`,
      `analytics`, `studio`) still match service names in `docker-compose.yml`.
- [ ] Re-run NodeBot Builder helper prompts to confirm Chat Hub workflow agents + MCP + sub-workflows are intact.
- [ ] Re-run the seeded Local Ollama Chat template to confirm LangChain node compatibility hasn't regressed.

## Known caveats

- **Studio port**: Studio is not directly exposed; it's served behind Kong at
  `http://localhost:8000` (basic auth via `DASHBOARD_USERNAME`/`DASHBOARD_PASSWORD`).
- **MinIO host ports**: Remapped to `9100`/`9101` so `dev:full` doesn't conflict
  with Inbucket on `9000`. Internal DNS (`http://minio:9000`) is unchanged.
- **Ollama host vs. container**: Without `--cpu`/`--gpu-*`, `OLLAMA_HOST`
  defaults to `ollama:11434`. If you don't start an Ollama container, set
  `OLLAMA_HOST=host.docker.internal:11434` in `.env` and ensure Ollama runs on
  the host.
- **n8n MCP token**: `N8N_MCP_ACCESS_TOKEN` is populated by `scripts/setup.sh`
  after the first n8n owner account exists. Until then, NodeBot Builder will
  report MCP auth errors. Re-run `npm run setup` after creating the owner.
- **NodeBot Builder model**: `OLLAMA_BUILDER_MODEL` defaults to `llama3.2:3b`,
  which is sufficient for the starter suggested prompts. For freeform workflow
  building via raw MCP, bump to `qwen2.5:7b-instruct` or larger.
- **Default secrets are placeholders**: Every key in `.env.example` (JWT, API
  keys, dashboard password, vault key) must be rotated before any non-local use.
- **Opaque API keys are opt-in**: `SUPABASE_PUBLISHABLE_KEY` / `SUPABASE_SECRET_KEY`
  / `ANON_KEY_ASYMMETRIC` / `SERVICE_ROLE_KEY_ASYMMETRIC` are accepted by the new
  Kong entrypoint script but default to empty, which keeps the kit on the legacy
  HS256 (`ANON_KEY` / `SERVICE_ROLE_KEY`) path that all seeded n8n workflows and
  Edge Functions already use. See [Self-hosted auth keys](https://supabase.com/docs/guides/self-hosting/self-hosted-auth-keys)
  before flipping the switch — you'll also need to update Kong's `volumes/api/kong.yml`
  to wire up the `LUA_AUTH_EXPR` request-transformer headers.
- **n8n 2.x major bump**: Workflows seeded by the kit (`workflows/templates/` +
  `workflows/builder-helpers/`) were re-validated under `n8nio/n8n:2.21.7`. If you
  imported custom workflows under 1.x and they use deprecated node `typeVersion`s,
  re-export them from the 2.x UI once they're activated.
- **n8n 2.x `versionId` must be a UUID**: n8n 2.x introduced an `activeVersionId`
  column on `workflow_entity` and a `publish:workflow` CLI verb. Any workflow JSON
  whose `versionId` is not a real UUID (e.g. `"foo-ver-001"`) will import but
  fail with `"Active version not found for workflow with id ..."` on the first
  webhook hit. `scripts/validate-workflow-json.sh` now rejects non-UUID
  `versionId` values for shipped workflows; copy `uuidgen` output into the field
  before re-exporting.
- **n8n 2.x activation requires restart**: `n8n update:workflow --active=true`
  is deprecated in favor of `n8n publish:workflow --id=<id>`. Either command
  prints `Changes will not take effect if n8n is running. Please restart n8n`.
  The kit's `n8n-import` sidecar finishes before `n8n` starts, so a clean
  bootstrap is fine. When you re-import workflows against a running stack, run
  `docker compose restart n8n` afterwards or activation won't be picked up.
