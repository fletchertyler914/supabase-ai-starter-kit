# Upgrading

This file is the operator-facing checklist for upgrading the kit. The stack is
fully pinned to specific image tags in [`docker-compose.yml`](./docker-compose.yml)
so upgrades are deliberate, not silent.

## Currently pinned versions

| Component | Image / Tag | Source of truth |
| --- | --- | --- |
| Supabase Studio | `supabase/studio:2025.06.02-sha-8f2993d` | `docker-compose.yml` `studio.image` |
| GoTrue (Auth) | `supabase/gotrue:v2.174.0` | `auth.image` |
| Kong API Gateway | `kong:2.8.1` | `kong.image` |
| PostgREST | `postgrest/postgrest:v12.2.12` | `rest.image` |
| Realtime | `supabase/realtime:v2.34.47` | `realtime.image` |
| Storage API | `supabase/storage-api:v1.23.0` | `storage.image` |
| imgproxy | `darthsim/imgproxy:v3.8.0` | `imgproxy.image` |
| postgres-meta | `supabase/postgres-meta:v0.89.3` | `meta.image` |
| Edge Runtime (Functions) | `supabase/edge-runtime:v1.67.4` | `functions.image` |
| Logflare (Analytics) | `supabase/logflare:1.14.2` | `analytics.image` |
| Postgres + pgvector | `supabase/postgres:15.8.1.060` | `db.image` |
| Vector (logs) | `timberio/vector:0.28.1-alpine` | `vector.image` |
| Supavisor (pooler) | `supabase/supavisor:2.5.1` | `supavisor.image` |
| MinIO (dev:s3) | `minio/minio:latest` | `docker/docker-compose.s3.yml` |
| n8n | `n8nio/n8n:latest` | `x-n8n` anchor in `docker-compose.yml` |
| Inbucket (dev:email) | `inbucket/inbucket:3.0.3` | `docker/docker-compose.email.yml` |
| Ollama | `ollama/ollama:latest` (rocm for AMD) | `x-ollama` / `x-init-ollama` anchors |

> The `latest` tags on n8n, Ollama, and MinIO are deliberate (they release
> often and back-compat is good). Consider pinning them in a fork if you want
> truly reproducible builds.

## Upgrade workflow

### 1. In-place upgrade (preserves data)

```bash
docker compose pull
docker compose up -d
npm run health
npm run test:db
```

This works for patch-level bumps and for upgrading the `:latest`-tagged
services (n8n, Ollama, MinIO) without touching the database.

### 2. Bumping a pinned tag

1. Update the tag in `docker-compose.yml` (or the relevant overlay).
2. Read the upstream changelog for breaking changes — especially Postgres,
   GoTrue, Realtime, and Storage API often have migration notes.
3. Back up the database before running:
   ```bash
   docker exec supabase-db pg_dumpall -U postgres > backup-$(date +%Y%m%d-%H%M%S).sql
   ```
4. Pull, restart, and validate:
   ```bash
   docker compose pull
   docker compose up -d
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

- [ ] `docker compose config --quiet` for base + every overlay (`scripts/start.sh` + npm scripts)
- [ ] `npm run health`
- [ ] `npm run test:db`
- [ ] `npm run test:auth`
- [ ] Confirm `volumes/logs/vector.yml` container-name matches still align with
      `docker-compose.yml` (`supabase-kong`, `supabase-auth`, `supabase-rest`,
      `realtime-dev.supabase-realtime`, `supabase-storage`,
      `supabase-edge-functions`, `supabase-db`).
- [ ] Confirm `volumes/api/kong.yml` upstream hostnames (`auth`, `rest`,
      `realtime-dev.supabase-realtime`, `storage`, `functions`, `meta`,
      `analytics`, `studio`) still match service names in `docker-compose.yml`.
- [ ] Re-run the n8n demo workflow ("Self Hosted Ollama Chat") to confirm
      LangChain node compatibility hasn't regressed.

## Known caveats

- **Studio port**: Studio is not directly exposed; it's served behind Kong at
  `http://localhost:8000` (basic auth via `DASHBOARD_USERNAME`/`DASHBOARD_PASSWORD`).
- **MinIO host ports**: Remapped to `9100`/`9101` so `dev:full` doesn't conflict
  with Inbucket on `9000`. Internal DNS (`http://minio:9000`) is unchanged.
- **Ollama host vs. container**: Without `--cpu`/`--gpu-*`, `OLLAMA_HOST`
  defaults to `ollama:11434`. If you don't start an Ollama container, set
  `OLLAMA_HOST=host.docker.internal:11434` in `.env` and ensure Ollama runs on
  the host.
- **Default secrets are placeholders**: Every key in `.env.example` (JWT, API
  keys, dashboard password, vault key) must be rotated before any non-local use.
