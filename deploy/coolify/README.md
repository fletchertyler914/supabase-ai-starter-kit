# Coolify deployment recipe

[Coolify](https://coolify.io) is an open-source self-hosted PaaS. With a $4–6/mo VPS you can run this whole starter kit with TLS, restarts, env management, and a UI — no `docker` commands needed after install.

## Why Coolify

- One-click Docker Compose deploys
- Built-in TLS via Caddy/Traefik
- Env var editor + secret management
- Push-to-deploy from GitHub if you fork the repo

## Prereqs

1. A VPS with **≥ 4 GB RAM, ≥ 2 vCPU, ≥ 40 GB disk**. Tested guidance:
   - Hetzner CX22 (~$4/mo, 4 GB RAM) — works
   - DigitalOcean Premium 2 vCPU / 4 GB (~$24/mo) — comfortable
   - AWS Lightsail 2 vCPU / 4 GB ($24/mo) — works
2. A domain you control on Cloudflare (or any DNS).
3. Coolify installed on the VPS:
   ```bash
   curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
   ```
   Then open `https://<VPS_IP>:8000` and complete setup.

## Deploy

1. In Coolify → **Resources** → **+ New** → **Docker Compose Empty**.
2. Connect your fork of this repo (or paste the repo URL).
3. **Build pack**: Docker Compose.
4. **Docker Compose Location**: `docker-compose.yml`.
5. **Environment Variables**: paste the contents of your `.env` (Coolify will store them). At minimum, change every default password before deploying.
6. **Domains**:
   - Kong (Supabase API): map your `api.example.com` to port `8000`.
   - n8n: map `n8n.example.com` to port `5678`.
   - Studio: map `studio.example.com` to port `8000` (different subdomain; Kong routes Studio by path).
7. Deploy. Coolify will pull images, run compose, and wire TLS via its proxy.

## After deploy

```bash
# From your local machine, sanity check:
curl -I https://api.example.com/auth/v1/health   # expect 200
curl -I https://n8n.example.com/                 # expect 401 (basic auth)
```

Then log into n8n at `https://n8n.example.com` with the credentials from your env. Templates should already be imported.

## Things to change vs local

- Disable the dev overlays. Coolify deploys only `docker-compose.yml` by default — keep it that way.
- Remove all bind-mounted dev-only volumes if any (the base file doesn't include them).
- Set `SITE_URL`, `API_EXTERNAL_URL`, `SUPABASE_PUBLIC_URL` to your real domain in env.
- Set `N8N_HOST`, `N8N_PROTOCOL=https`, `N8N_PORT=443` in env.
- Rotate all secrets (see [`../../DEPLOY.md`](../../DEPLOY.md) production checklist).

## Updating

In Coolify → Resource → **Redeploy**. Or enable auto-deploy from your fork's `main` branch.

## What we do NOT ship here

- A bespoke `coolify.json` — Coolify doesn't need one for Compose-based apps.
- An override file for prod. The base `docker-compose.yml` already runs fine; overlays in `docker/` are dev-only.

If something looks like it would benefit from a Coolify override file, open an issue and we'll add it here.
