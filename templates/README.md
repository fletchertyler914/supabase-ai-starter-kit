# Template library

The kit ships with two layers of preconfigured AI in n8n:

1. **Chat Hub agents** — a Personal agent + a Workflow agent, both backed by your local Ollama.
2. **n8n workflows** — three user-facing templates plus four internal "builder helper" sub-workflows that NodeBot Builder uses to turn natural-language requests into real workflows reliably.

Everything is imported and activated automatically on the **first** stack start (or after `volumes/n8n` is cleared / `./scripts/reset.sh` is run).

## Prerequisites

- Stack running: `npm run setup` (recommended) or `npm run dev:full`.
- `.env` copied from `.env.example` with a stable `N8N_ENCRYPTION_KEY` (required to decrypt the shipped credentials).
- For Ollama-backed templates: Ollama reachable from n8n (`http://ollama:11434` in Docker, or host Ollama via profile flags). `npm run setup` pulls both:
  - `OLLAMA_MODEL` / `OLLAMA_DEFAULT_MODELS` — chat model (default `llama3.2:3b`)
  - `OLLAMA_BUILDER_MODEL` — NodeBot Builder model (default `llama3.2:3b`; bump to `qwen2.5:7b-instruct` etc. if the small model can't drive complex MCP workflows)
- For NodeBot Builder: instance-level MCP enabled (`N8N_MCP_ACCESS_ENABLED=true` in `.env`, on by default) and an MCP access token. `npm run setup` generates the token after your first n8n owner account exists.

## Chat Hub agents

Open n8n → top-left **Chat** icon.

### Personal agent — Local Ollama Agent

| | |
| --- | --- |
| Surface | Chat Hub → **Personal agents** |
| Provider | `ollama` |
| Model | `OLLAMA_MODEL` (default `llama3.2:3b`) |
| Suggested prompts | 4 (Supabase, n8n, vector search, environment) |
| Where it's defined | `n8n/demo-data/bootstrap.sql` (`n8n.chat_hub_agents`), upserted on every startup |

The system prompt is intentionally directive — small local models otherwise tend to leak system instructions or pseudo-XML tags into chat. If you change the prompt or model, edit `bootstrap.sql` and re-run `docker compose run --rm n8n-bootstrap` (or `npm run setup`).

### Workflow agent — NodeBot Builder

| | |
| --- | --- |
| Surface | Chat Hub → **Workflow agents** |
| Workflow ID | `d4e5f6a7b8c9012345678901234abcd` |
| File | `n8n/demo-data/workflows/d4e5f6a7b8c9012345678901234abcd.json` |
| Trigger | Chat Trigger v1.4 (`availableInChat`) |
| Agent | AI Agent v3.1 (Tools Agent, streaming, `maxIterations: 12`) |
| Model | `lmChatOllama` with `OLLAMA_BUILDER_MODEL` |
| Memory | Buffer window (8 turns), session from chat input |
| Tools | 4 sub-workflow helpers + `mcpClientTool` (10 MCP tools) |

The agent's system prompt routes requests to one of two paths:

1. **Fast helpers** (recommended) — four `toolWorkflow` nodes wired to dedicated sub-workflows. The agent only has to pick the right helper and pass 1-3 short strings via `$fromAI`. The helper itself builds valid n8n Workflow SDK code, calls MCP `validate_workflow` → `create_workflow_from_code`, and returns the real workflow URL.
2. **MCP Client Tool** — falls back here only when no helper fits. Goes through the full `get_sdk_reference → search_nodes → get_node_types → validate_workflow → create_workflow_from_code` loop.

The Chat Trigger ships with four suggested prompts that map 1:1 onto the four helpers. Tested working end-to-end with `llama3.2:3b`.

## User-facing workflow templates

### 1. Template — Local Ollama Chat

| | |
| --- | --- |
| Workflow ID | `bKhNvmpDfT4mclXo` |
| File | `n8n/demo-data/workflows/bKhNvmpDfT4mclXo.json` |
| Trigger | LangChain chat (public webhook for local use) |
| Credentials | `ollamaApi` — `VmhEukzPe8au9PTB.json` (seeded) |
| Webhook ID | `ba65d0a2-7d1d-4efe-9e7a-c41b1031e3bb` |

Open in n8n and use the chat panel, or call it from a terminal:

```bash
curl -s -X POST \
  http://localhost:5678/webhook/ba65d0a2-7d1d-4efe-9e7a-c41b1031e3bb/chat \
  -H 'Content-Type: application/json' \
  -d '{"action":"sendMessage","sessionId":"my-test","chatInput":"Hello"}'
```

### 2. Template — Supabase API Health Check

| | |
| --- | --- |
| Workflow ID | `c9a1b2c3d4e5f6789012345678ab` |
| File | `n8n/demo-data/workflows/c9a1b2c3d4e5f6789012345678ab.json` |
| Trigger | Webhook `POST /webhook/template-supabase-health` |
| Credentials | None (HTTP request to internal Kong using `.env` anon JWT) |

```bash
curl -s -X POST http://localhost:5678/webhook/template-supabase-health | jq .
```

Expected: JSON with `"ok": true` and `authHealthStatus: 200` when Auth is healthy.

### 3. Template — NodeBot Builder

See [Workflow agent — NodeBot Builder](#workflow-agent--nodebot-builder) above. The workflow is exposed both as a Chat Hub workflow agent and as `availableInMCP` so other agents can also drive it.

## Builder helper sub-workflows

These are the "engine room" for NodeBot Builder. The user never invokes them directly; the agent picks one and parameterizes it. Each helper takes 1-3 string inputs, builds valid n8n Workflow SDK TypeScript, calls MCP `validate_workflow`, then `create_workflow_from_code`, and returns the real workflow URL.

| Helper workflow | ID | Tool name on agent | Inputs |
| --- | --- | --- | --- |
| **SK - Create Greeting Workflow** | `e6f7a8b9c0d1e2f3a4b5c6d7e8f90123` | `Create_Greeting_Workflow` | `workflowName`, `message` |
| **SK - Create Webhook Workflow** | `a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6` | `Create_Webhook_Workflow` | `workflowName`, `webhookPath`, `description` |
| **SK - Create Scheduled Workflow** | `b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7` | `Create_Scheduled_Workflow` | `workflowName`, `cronExpression`, `message` |
| **SK - List Workflows** | `c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8` | `List_Workflows` | `query` (optional) |

All four:

- Must stay **active** (they're listed in `workflow-ids.activate`). n8n refuses to run an inactive sub-workflow.
- Use the seeded `httpBearerAuth` credential `N8NMcpBearer001` to call the local MCP endpoint at `http://127.0.0.1:5678/mcp-server/http`.
- Return a `response` field with a human-readable summary the agent paraphrases in chat.

Why bother with helpers instead of pure MCP? Small local models (`llama3.2:3b`) often emit "fake" tool-call JSON in chat content instead of issuing real tool calls. Helpers turn a multi-step MCP loop into a single 1-3-argument tool call the model can drive reliably. See [`EXTENDING.md`](../EXTENDING.md) for adding more helpers.

## Credentials

Seeded encrypted credentials live in `n8n/demo-data/credentials/`:

| File | Type | Purpose |
| --- | --- | --- |
| `VmhEukzPe8au9PTB.json` | `ollamaApi` | Points at `http://ollama:11434` (or host Ollama via profile) |
| `N8NMcpBearer001.json` | `httpBearerAuth` | MCP access token for the in-stack MCP endpoint |

Both are **local-dev only**, encrypted with `N8N_ENCRYPTION_KEY` from `.env`. `scripts/setup.sh` rewrites `N8NMcpBearer001` from the first n8n owner's freshly-issued MCP token. If no owner exists yet, the credential is a placeholder; create the first account in n8n, then re-run `npm run setup`.

## Validation commands

```bash
# Stack-wide health + n8n basic auth
npm run test:health

# Workflow import shape, activation, MCP enablement, helper presence, webhook smoke
npm run test:templates

# MCP endpoint reachable + workflow-builder tools exposed
npm run test:builder

# Real Ollama -> Chat template end-to-end through the webhook
npm run test:ollama

# Everything
npm test
```

## Reset and re-import

```bash
./scripts/reset.sh           # interactive teardown (preserves Ollama models by default)
npm run dev:full             # or npm run setup
npm run test:templates
```

To force re-import without wiping the DB:

```bash
docker exec n8n rm -f /home/node/.n8n/.template-seed-complete
docker compose run --rm n8n-import
docker compose restart n8n
```

## Adding more templates or builder helpers

1. Build the workflow in n8n and export to `n8n/demo-data/workflows/`.
2. Add an entry to `n8n/demo-data/manifest.json`.
3. Append the workflow ID to `n8n/demo-data/workflow-ids.activate` if it should auto-activate.
4. If it's a builder helper, also:
   - Add a `@n8n/n8n-nodes-langchain.toolWorkflow` node to `n8n/demo-data/workflows/d4e5f6a7b8c9012345678901234abcd.json` with a clear description and `$fromAI` inputs.
   - Update the system prompt's "FAST HELPERS" section to mention the new tool.
   - Add a check to `scripts/test-n8n-templates.sh`.
5. Document it in this file.
6. Re-import: `docker exec n8n rm -f /home/node/.n8n/.template-seed-complete && docker compose run --rm n8n-import && docker compose restart n8n`.

Detailed walkthrough with code examples lives in [`EXTENDING.md`](../EXTENDING.md).
