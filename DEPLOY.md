# Deploying the starter kit

This kit was built for local development. Putting it on the public internet is doable, but it's important to understand the trade-offs first.

## Resource shape

The full stack runs ~15 containers and needs **roughly 3–4 GB of RAM** to be comfortable. Postgres, n8n, Kong, GoTrue, PostgREST, Realtime, Storage, Studio, Analytics, Vector, and the supporting workers all need to be up at the same time. Local LLM inference (Ollama) adds more.

That immediately rules out every truly-free cloud tier I'm aware of as of 2026. Be skeptical of any guide that claims otherwise — most are out of date.

## Honest options, ranked by total cost

### 1. **Your own machine + Cloudflare Tunnel** — $0/mo, recommended for personal/AI agent use

Run the stack on a Mac mini, an old laptop, a NAS, or a home server. Expose it to the internet through Cloudflare Tunnel without opening any router ports.

Pros:
- Genuinely free
- You keep all your data
- Performance is excellent (especially on Apple Silicon for Ollama)
- Cloudflare handles TLS + DDoS

Cons:
- Your machine has to stay on
- Not for "production" customer workloads

Run the bundled tunnel script:

```bash
./scripts/tunnel.sh
```

The script will install `cloudflared` if missing, walk you through `cloudflared login`, and start a named tunnel that proxies a public HTTPS URL to your local stack. See [`scripts/tunnel.sh`](./scripts/tunnel.sh) for details.

### 2. **Coolify (or Dokploy) on a cheap VPS** — ~$4–10/mo, recommended for small production

[Coolify](https://coolify.io/) is a self-hostable Vercel/Heroku alternative. On a Hetzner CX22 (~$4/mo, 4 GB RAM) or DigitalOcean $6 droplet you can:

1. Install Coolify with their one-liner.
2. Add this repo as a "Docker Compose" resource.
3. Point Coolify at the `docker-compose.yml` + dev/email/s3 overlays you want.
4. Coolify handles TLS, reverse proxy, restarts, backups.

Pros:
- Cheap and predictable
- Coolify gives you a UI for env vars, logs, restarts
- Real domain with TLS out of the box

Cons:
- You're now an admin (security updates, backups)
- Free-tier Hetzner / DO may be slow for Ollama; consider GPU droplets only if you actually need them

### 3. **Hybrid: Supabase Cloud + n8n Cloud** — free tier exists, but you give up "self-hosted"

If you only want the workflow + AI-agent experience and don't need a self-hosted Supabase, use the managed equivalents:

- Supabase Cloud free tier: 500 MB DB, 1 GB storage, 50K MAU
- n8n Cloud free trial → community self-host
- Ollama on your machine (or any LLM API)

The starter-kit n8n templates can be imported into n8n Cloud / self-hosted as-is. The Supabase health-check workflow needs the URL changed from `http://kong:8000` to your Supabase Cloud project URL.

Pros:
- Easiest "real internet" deployment
- Free for small projects

Cons:
- Two vendor accounts
- Less control, no edge functions parity, less obvious local/prod parity

### 4. **Fly.io** — ~$10–20/mo if you really want it

Fly removed the always-free allowance in late 2024. Realistic monthly bill: $10–20 for shared CPU + 4 GB RAM + a small Postgres + persistent volumes. It works, but no longer wins on price.

If you go this route, plan to split the stack: Fly Postgres (managed) + a single Machine running the docker-compose for the other services, OR several smaller Machines. There is no committed `fly.toml` in this repo because Fly's pricing/positioning keeps changing — assemble your own from their current docs.

### 5. **Railway, Render, AWS Lightsail, Azure Container Apps** — variable

All workable, all in the $5–20/mo range for small instances. Render's free tier is too restrictive for a 15-container stack. Railway and Lightsail are reasonable choices. We don't ship platform-specific manifests for these; the existing `docker-compose.yml` is portable to anything that runs Compose.

## Production checklist (regardless of where you deploy)

Before exposing this on the public internet, change every line in this checklist:

- [ ] `.env`: rotate `POSTGRES_PASSWORD`, `JWT_SECRET`, `ANON_KEY`, `SERVICE_ROLE_KEY` (regenerate JWTs against the new secret), `N8N_ENCRYPTION_KEY`, `N8N_USER_MANAGEMENT_JWT_SECRET`, `N8N_BASIC_AUTH_PASSWORD`, `DASHBOARD_USERNAME`/`PASSWORD`, `LOGFLARE_*` keys, `MINIO_ROOT_PASSWORD`, `N8N_MCP_ACCESS_TOKEN`.
- [ ] Rotating `N8N_ENCRYPTION_KEY` invalidates seeded credentials. Either re-import them with the new key, or recreate them in the n8n UI.
- [ ] Rotating `JWT_SECRET` requires regenerating `ANON_KEY` and `SERVICE_ROLE_KEY` with a Supabase JWT generator (any JWT-signing tool with HS256 works).
- [ ] Decide whether to keep n8n's instance-level MCP enabled (`N8N_MCP_ACCESS_ENABLED`). It's on by default for local DX. In production, either disable it entirely or rotate `N8N_MCP_ACCESS_TOKEN` and restrict which workflows have `availableInMCP: true` — anything flagged is callable by any holder of the token.
- [ ] Put **everything** behind TLS. Cloudflare Tunnel and Coolify both handle this automatically.
- [ ] Restrict n8n webhooks. Either use n8n's "Header Auth" credentials on each webhook or front the whole stack with an auth layer. The seeded Local Ollama Chat template uses `public: true` — disable that before exposing.
- [ ] Lock down direct ports. `docker-compose.yml` binds 5678 (n8n), 5432/6543 (Postgres pool), 9000 (Inbucket), 9101 (MinIO), 11434 (host Ollama). On a server, drop the `ports:` entries you don't need exposed and rely on the reverse proxy.
- [ ] Disable Inbucket (`docker/docker-compose.email.yml`) and MinIO (`docker/docker-compose.s3.yml`) overlays in production unless you actually use them.
- [ ] Pin image tags. `latest` is fine locally; in prod pin to specific image digests.
- [ ] Back up `volumes/db/data` and the n8n schema. A nightly `pg_dump` to S3 is sufficient for most users.

## Backup and restore

With the stack running (Postgres up), snapshot the logical database dump plus bundled app volumes:

```bash
npm run backup
```

This writes under `backups/<timestamp>/` as `pg_dumpall.sql` and `volumes.tgz` (`volumes/n8n` + `volumes/storage`).

To restore onto a **stopped or idle** workspace you are willing to overwrite:

```bash
RESTORE_I_KNOW_THIS_IS_DESTRUCTIVE=1 npm run restore -- backups/<timestamp>
```

Then restart Compose so n8n/Storage reconnect cleanly. Inspect `scripts/backup.sh` and `scripts/restore.sh` before using in production — `pg_dumpall` restores are cluster-wide operations.

## What the kit doesn't include

By design:

- No "deploy to X" button. We picked honest docs over vendor lock-in.
- No managed scaling. This is a single-node compose stack; if you need HA, lift the parts you care about into managed services.
- No first-class secret manager. Use your platform's (Coolify env, Fly secrets, SOPS, Doppler, 1Password, Bitwarden — pick one).

## Going further

- Want a guided VPS install? See [Coolify's Hetzner guide](https://coolify.io/docs/installation) and point it at this repo's `docker-compose.yml`.
- Want a one-click public URL right now? Run `./scripts/tunnel.sh`.
- Want the AI agent + workflow story without self-hosting? Use Supabase Cloud + n8n Cloud and import the workflows from `n8n/demo-data/workflows/templates/` and `n8n/demo-data/workflows/builder-helpers/`.
