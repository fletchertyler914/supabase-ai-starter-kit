# Template library (MVP)

Two production-oriented n8n workflows ship with this starter kit. They import automatically on the **first** stack start (or after `volumes/n8n` is cleared).

## Prerequisites

- Stack running: `npm run dev:full` (or `./scripts/start.sh` with your GPU/CPU profile).
- `.env` copied from `.env.example` with stable `N8N_ENCRYPTION_KEY` (required for credential decryption).
- For **Local Ollama Chat**: Ollama reachable from n8n (`http://ollama:11434` in Docker, or host Ollama via profile flags) and model `llama3.2:1b` pulled (default in `.env.example`).

## Template index

### 1. Template - Local Ollama Chat

| | |
| --- | --- |
| **Workflow ID** | `bKhNvmpDfT4mclXo` |
| **File** | `n8n/demo-data/workflows/bKhNvmpDfT4mclXo.json` |
| **Trigger** | LangChain chat (non-public) |
| **Credentials** | `ollamaApi` — `VmhEukzPe8au9PTB.json` (imported) |
| **Env** | `OLLAMA_HOST`, `OLLAMA_DEFAULT_MODELS`, `N8N_ENCRYPTION_KEY` |
| **UI** | http://localhost:5678 (basic auth: `admin` / `changeme` by default) |

Open the workflow in n8n, use the chat panel, and send a test message after Ollama is healthy.

### 2. Template - Supabase API Health Check

| | |
| --- | --- |
| **Workflow ID** | `c9a1b2c3d4e5f6789012345678ab` |
| **File** | `n8n/demo-data/workflows/c9a1b2c3d4e5f6789012345678ab.json` |
| **Trigger** | Webhook `POST /webhook/template-supabase-health` |
| **Credentials** | None (HTTP Request to internal Kong) |
| **Env** | Supabase stack up; Kong on `kong:8000` inside Docker network. Uses the dev `ANON_KEY` from `.env.example` in request headers (public anon JWT, not a service-role secret). |

Smoke test from the host:

```bash
curl -s -X POST http://localhost:5678/webhook/template-supabase-health | jq .
```

Expected: JSON with `"ok": true` and `authHealthStatus` 200 when Auth is healthy.

## Validation commands

```bash
# Full stack health (includes n8n with basic auth)
npm run test:health

# Template import + webhook smoke tests
npm run test:templates

# Health + auth + DB + templates
npm test
```

## Reset and re-import

```bash
./scripts/reset.sh
npm run dev:full
npm run test:templates
```

## Adding more templates

1. Build the workflow in n8n and export to `n8n/demo-data/workflows/`.
2. Add an entry to `n8n/demo-data/manifest.json`.
3. Append the workflow ID to `n8n/demo-data/workflow-ids.activate` if it should auto-activate.
4. Document it in this file and extend `scripts/test-n8n-templates.sh`.
