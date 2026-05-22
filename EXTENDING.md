# Extending the starter kit

This guide is written for two audiences at once:

- **Humans** who want to add their own workflows, integrations, or AI agents to the kit.
- **AI coding agents** (Cursor, Claude, Copilot CLI, etc.) that have been pointed at this repo and asked to "add a feature". Every section names the exact files and conventions to follow.

The kit is built so that extensions live in well-known directories, follow predictable patterns, and are exercisable from the same `npm test` suite.

## TL;DR for AI agents

If you are an AI agent reading this, follow these rules:

1. **n8n workflows**: ship curated templates under `n8n/demo-data/workflows/templates/<id>.json` and NodeBot Builder helpers under `n8n/demo-data/workflows/builder-helpers/<id>.json` (`workflows/examples/` is reserved for optional samples). After adding one, append its workflow ID to `n8n/demo-data/workflow-ids.activate` (one ID per line), run `npm run validate:workflows`, and document it in `templates/README.md`.
2. **n8n credentials** go in `n8n/demo-data/credentials/<id>.json`. The `data` field is **AES-256-CBC** encrypted with the OpenSSL "Salted__" format using `N8N_ENCRYPTION_KEY` from `.env`. See [`Encrypting credentials`](#encrypting-credentials).
3. **Chat Hub workflow agents** should use a new Chat Trigger with `availableInChat: true`, an `@n8n/n8n-nodes-langchain.agent` node with streaming enabled, and explicit tool connections. For workflow creation, prefer **dedicated `toolWorkflow` helper sub-workflows** that wrap the MCP authoring loop. Only fall back to a raw MCP Client Tool for cases that don't fit a helper. See [`Add a Chat Hub workflow agent`](#add-a-chat-hub-workflow-agent).
4. **Chat Hub personal agents** are stored in the `n8n.chat_hub_agents` table, not as exported workflow JSON. Configure them via idempotent `INSERT ... ON CONFLICT` in `n8n/demo-data/bootstrap.sql`. See [`Add a Chat Hub personal agent`](#add-a-chat-hub-personal-agent).
5. **Edge functions** go in `volumes/functions/<name>/index.ts` (Deno runtime). They are served at `http://localhost:8000/functions/v1/<name>`.
6. **Database changes** go in `volumes/db/*.sql`. They run once on a fresh DB. For migrations on a running DB, use `docker exec supabase-db psql -U postgres -f /path/to/sql`.
7. **Tests** for anything you add should be exercisable via `npm test`. Add a smoke test to an existing script in `scripts/` or create a new `scripts/test-<feature>.sh` and wire it into `package.json`.
8. **Never commit real secrets.** Use `.env.example` for placeholders, `.env` for local values (gitignored), and explicit setup steps in the relevant README.
9. **Default to local-first.** If something needs an external API key, make it optional and document it in `.env.example` with a comment explaining what unlocks if set.

## Repo layout

```
.
├─ docker-compose.yml          # base stack (Supabase + n8n)
├─ docker/
│  ├─ docker-compose.dev.yml   # dev overlay (seed data, anonymous DB volume)
│  ├─ docker-compose.email.yml # Inbucket dev SMTP
│  └─ docker-compose.s3.yml    # MinIO S3-compatible storage
├─ .env.example                # safe defaults, copy to .env
├─ n8n/
│  ├─ README.md                # n8n seed behavior
│  └─ demo-data/
│     ├─ manifest.json         # human-readable index of seeded workflows
│     ├─ workflow-ids.activate # one workflow ID per line to auto-activate
│     ├─ workflows/templates/<id>.json   # shipped “Template - …” exports
│     ├─ workflows/builder-helpers/<id>.json # SK helpers + tooling sub-workflows
│     ├─ workflows/examples/          # placeholder for optional samples (.gitkeep)
│     ├─ credentials/<id>.json # AES-256-CBC encrypted with N8N_ENCRYPTION_KEY
│     ├─ bootstrap.sql         # idempotent SQL: chat_hub_agents, sharing, MCP enablement
│     └─ import-templates.sh   # runs once in n8n-import container
├─ volumes/
│  ├─ db/                      # init SQL (runs once on a fresh DB)
│  ├─ functions/<name>/        # Edge Functions (Deno)
│  └─ ...
├─ scripts/
│  ├─ setup.sh                 # interactive wizard
│  ├─ start.sh                 # smart start with profile flags
│  ├─ reset.sh                 # interactive teardown
│  ├─ health-check.sh
│  ├─ test-auth-complete.js
│  ├─ test-database-integration.sh
│  ├─ test-n8n-templates.sh
│  ├─ test-ollama-integration.sh
│  └─ verify-local.sh
├─ templates/README.md         # user-facing template library index
├─ QUICKSTART.md
├─ EXTENDING.md                # you are here
└─ DEPLOY.md
```

## Add a new n8n workflow

The "1-minute" path (in the n8n UI):

1. Open http://localhost:5678 → New workflow → build it.
2. Export it: ⋯ menu → Download → save the JSON.
3. Save the JSON to `n8n/demo-data/workflows/templates/<id>.json` (user-facing templates) **or** `n8n/demo-data/workflows/builder-helpers/<id>.json` (builder tooling) where `<id>` is the workflow's ID from the JSON `"id"` field.
4. If it should auto-activate on first start: append the ID on its own line in `n8n/demo-data/workflow-ids.activate`.
5. Add a row to `templates/README.md` so users can find it.

The "AI agent" path (no UI):

1. Author the JSON directly. The minimum viable webhook workflow:

```json
{
  "id": "<24-32 hex chars, e.g. f1e2d3c4b5a6978899aabbccddeeff00>",
  "name": "Template - Example Webhook",
  "active": false,
  "nodes": [
    { "id": "trigger", "name": "Webhook", "type": "n8n-nodes-base.webhook",
      "typeVersion": 2, "position": [400, 300],
      "webhookId": "<same-as-id-or-any-unique-string>",
      "parameters": { "httpMethod": "POST", "path": "example-webhook", "responseMode": "lastNode" } },
    { "id": "respond", "name": "Respond", "type": "n8n-nodes-base.respondToWebhook",
      "typeVersion": 1.1, "position": [620, 300],
      "parameters": { "respondWith": "json", "responseBody": "={{ { ok: true, echo: $json } }}" } }
  ],
  "connections": { "Webhook": { "main": [[{ "node": "Respond", "type": "main", "index": 0 }]] } },
  "settings": { "executionOrder": "v1" }, "staticData": null, "pinData": {},
  "meta": { "templateCredsSetupCompleted": true },
  "versionId": "<id>-v1", "triggerCount": 0, "tags": []
}
```

## Add a Chat Hub workflow agent

Use this pattern when you want a conversational agent inside n8n's **Chat → Workflow agents** surface:

1. Add a new Chat Trigger node (`@n8n/n8n-nodes-langchain.chatTrigger`) at the newest available version and set `availableInChat: true`, `agentName`, and `agentDescription`.
2. Connect it to an AI Agent node (`@n8n/n8n-nodes-langchain.agent`) version `2.2` or newer. Keep streaming enabled.
3. Attach a chat model, usually the seeded Ollama credential `VmhEukzPe8au9PTB`.
4. Attach tools explicitly. For agents that create or manage n8n workflows, use MCP Client Tool pointed at `http://127.0.0.1:5678/mcp-server/http` with the seeded `N8NMcpBearer001` bearer credential.
5. Keep tool access narrow. The starter NodeBot Builder agent exposes **two layers**:

   **Layer 1 — fast helper sub-workflows** (preferred). Each is a `@n8n/n8n-nodes-langchain.toolWorkflow` node bound to a sub-workflow that already knows how to build SDK code, validate it via MCP, and create the workflow. The agent only has to pick the right helper and supply 1-3 short strings.

   | Tool name on agent | Sub-workflow | Workflow ID | Pattern |
   | --- | --- | --- | --- |
   | `Create_Greeting_Workflow` | `SK - Create Greeting Workflow` | `e6f7a8b9c0d1e2f3a4b5c6d7e8f90123` | Manual Trigger + Set greeting |
   | `Create_Webhook_Workflow` | `SK - Create Webhook Workflow` | `a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6` | POST webhook + normalized JSON response |
   | `Create_Scheduled_Workflow` | `SK - Create Scheduled Workflow` | `b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7` | Schedule Trigger (cron) + Set log |
   | `List_Workflows` | `SK - List Workflows` | `c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8` | MCP `search_workflows` wrapper, formatted |

   See `n8n/demo-data/manifest.json` and `workflows/builder-helpers/*.json` for the full set of SK helpers (create/update/publish/delete workflows, Supabase row triggers, RAG authoring, status, analytics logging, etc.).

   **Layer 2 — `mcpClientTool`** wired to `http://127.0.0.1:5678/mcp-server/http` with the seeded `N8NMcpBearer001` bearer credential. Exposes `get_sdk_reference`, `search_nodes`, `get_node_types`, `validate_workflow`, `create_workflow_from_code`, `update_workflow`, `publish_workflow`, `search_workflows`, `get_workflow_details`, `execute_workflow`. Only used when no helper fits.

   Each helper:
   - Must stay **active** (listed in `workflow-ids.activate`) or n8n refuses to run it as a sub-workflow.
   - Uses an `executeWorkflowTrigger` with `inputSource: "workflowInputs"` so `toolWorkflow` `$fromAI` mappings line up with named arguments.
   - Internally builds valid n8n Workflow SDK TypeScript in a `Code` node, posts it to MCP `validate_workflow` via `httpRequest`, then `create_workflow_from_code` if validation passes.
   - Returns a `response` field with a human-readable summary plus the real workflow URL.

#### Adding a new fast helper

1. Copy an existing helper, e.g. `n8n/demo-data/workflows/builder-helpers/a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6.json` (the webhook helper), to a new file. Generate a fresh 32-char hex ID for both the file name and the `id` field.
2. Update `workflowInputs` on the `executeWorkflowTrigger` node:
   ```json
   "workflowInputs": {
     "values": [
       { "name": "workflowName", "type": "string" },
       { "name": "yourCustomInput", "type": "string" }
     ]
   }
   ```
3. Rewrite the `Build SDK Payload` Code node's `jsCode` to emit the SDK code your pattern needs. Use one of the existing helpers as a template — they all follow the same `defineWorkflow → manualTrigger/webhook/schedule → set` shape.
4. Leave `MCP Validate`, `Parse Validate`, `MCP Create`, and `Format Result` nodes unchanged — they're generic.
5. Append the new ID to `n8n/demo-data/workflow-ids.activate` and add a row to `n8n/demo-data/manifest.json`.
6. Open `n8n/demo-data/workflows/templates/d4e5f6a7b8c9012345678901234abcd.json` (NodeBot Builder) and:
   - Add a new `@n8n/n8n-nodes-langchain.toolWorkflow` node with a `description` that mirrors the helper's purpose and `workflowInputs` that map `$fromAI` placeholders to the helper's named inputs.
   - Wire it into `connections."NodeBot Builder Agent"."ai_tool"`.
   - Add the helper to the "FAST HELPERS" list in the system prompt and add a matching `suggestedPrompts` entry to the Chat Trigger.
7. Update `EXPECTED_TOTAL_HELPERS`, the NodeBot `toolWorkflow` count assertion, and helper coverage in `scripts/test-n8n-templates.sh`.
8. Update `templates/README.md`.
9. Re-import: `docker exec n8n rm -f /home/node/.n8n/.template-seed-complete && docker compose run --rm n8n-import && docker compose restart n8n`.

If the small default model still falls back to text-mode tool calls for everything, bump `OLLAMA_BUILDER_MODEL` in `.env` to a stronger native tool-caller (e.g. `qwen2.5:7b-instruct` or `llama3.1:8b-instruct`), `ollama pull` it, then run `docker compose restart n8n`.

The MCP credential is local-dev only. `scripts/setup.sh` refreshes it after an n8n owner account exists. If a new user reports missing MCP auth, ask them to create/sign into the first n8n owner account and re-run `npm run setup`.

> Do not put tag names in `tags`. The import will fail with `null value in column "tagId"` on a fresh DB. Always ship workflows with `"tags": []`.

After authoring any workflow:
1. Wire the ID into `workflow-ids.activate`.
2. Update `templates/README.md` and `n8n/demo-data/manifest.json`.
3. Either reset the n8n volume so the seed marker rebuilds, or force re-import in place:
   ```bash
   # Full reset
   docker compose down
   rm -rf volumes/n8n
   docker compose up -d

   # In-place re-import (faster)
   docker exec n8n rm -f /home/node/.n8n/.template-seed-complete
   docker compose run --rm n8n-import
   docker compose restart n8n
   ```
4. Add a smoke test in `scripts/test-n8n-templates.sh` or a new test script that:
   - Checks the workflow exists (`docker exec n8n n8n list:workflow | grep <id>`)
   - Checks it's active in DB (`SELECT active FROM n8n.workflow_entity WHERE id = '<id>'`)
   - Hits the webhook (or asserts the helper returns a URL) and validates the response

## Add a Chat Hub personal agent

Personal agents live in the `n8n.chat_hub_agents` table, **not** as exported workflows. To add one:

1. Build and tune it in n8n's UI (Chat → New personal agent → pick provider/model/prompt).
2. Inspect the row:
   ```bash
   docker exec supabase-db psql -U postgres -c \
     "SELECT id, name, provider, \"modelName\", \"systemPrompt\", \"suggestedPrompts\"
      FROM n8n.chat_hub_agents WHERE name = '<your agent>';"
   ```
3. Add a corresponding idempotent `INSERT ... ON CONFLICT (name) DO UPDATE` block to `n8n/demo-data/bootstrap.sql`. The shipped *Local Ollama Agent* is the canonical template — copy its shape and edit the fields.
4. Apply on a running stack:
   ```bash
   docker compose run --rm n8n-bootstrap
   ```
5. Hard-refresh the n8n Chat Hub UI to see it.

## Encrypting credentials

n8n stores credential `data` as base64-encoded AES-256-CBC ciphertext in OpenSSL "Salted__" format, keyed by `N8N_ENCRYPTION_KEY`.

Encrypt a payload:

```bash
printf '%s' '{"baseUrl":"http://ollama:11434"}' \
  | openssl enc -aes-256-cbc -md md5 -salt -base64 -A \
      -pass pass:"$(grep '^N8N_ENCRYPTION_KEY=' .env | cut -d= -f2-)"
```

Paste the result into the `data` field of a credential JSON file. Example skeleton:

```json
{
  "id": "myCustomCredId",
  "name": "My API",
  "type": "httpHeaderAuth",
  "isManaged": false,
  "data": "U2FsdGVkX1...=",
  "createdAt": "2026-05-21T12:00:00.000Z",
  "updatedAt": "2026-05-21T12:00:00.000Z"
}
```

Reference the credential from a workflow node:

```json
"credentials": {
  "httpHeaderAuth": { "id": "myCustomCredId", "name": "My API" }
}
```

> Decrypt the same way with `openssl enc -d -aes-256-cbc -md md5 -base64 -A -pass pass:<key>`.

## Add an edge function (Supabase Functions, Deno)

1. Create `volumes/functions/<name>/index.ts`:

```ts
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

Deno.serve(async (req) => {
  const { name = "world" } = await req.json().catch(() => ({}));
  return new Response(
    JSON.stringify({ hello: name, ts: new Date().toISOString() }),
    { headers: { "Content-Type": "application/json" } }
  );
});
```

2. Restart edge functions:
   ```bash
   docker compose restart functions
   ```
3. Hit it (the kit gates functions with anon JWT by default):
   ```bash
   ANON=$(grep '^ANON_KEY=' .env | cut -d= -f2-)
   curl -s -H "Authorization: Bearer $ANON" \
        -H "apikey: $ANON" \
        http://localhost:8000/functions/v1/<name>
   ```

## Add a database table / migration

For changes that should land on a fresh clone, add a `.sql` file to `volumes/db/`. It runs once when the DB initializes. To re-apply to an existing DB:

```bash
docker exec -i supabase-db psql -U postgres < volumes/db/your-file.sql
```

For ad-hoc changes on a running DB, use Supabase Studio (http://localhost:8000 → SQL editor) or `npm run db:connect`.

## Adding an AI agent workflow (canonical pattern)

A typical n8n "AI agent with tools" workflow has 4 ingredients:

1. **Trigger** — Webhook, Chat trigger, Cron, or a DB-row trigger (via Postgres LISTEN/NOTIFY).
2. **Memory** — Postgres-backed chat memory works out of the box because n8n is already on the local Supabase Postgres. Use the `Postgres Chat Memory` node, schema `n8n`.
3. **Tools** — HTTP Request nodes, Supabase nodes (PostgREST against `http://kong:8000/rest/v1/...`), and any third-party APIs you wire up.
4. **LLM** — `lmChatOllama` for local, `lmChatOpenAi` if you wire an OpenAI key in `.env`.

Make the workflow self-contained: it should run after `npm run setup` with no manual steps. If your workflow needs an API key, ship it gated behind an env var with a clear "skip if not set" branch.

## Add tests

Every new feature should be exercisable from `npm test`. Pick the right spot:

- **Auth / users** → extend `scripts/test-auth-complete.js`
- **DB / extensions / schema** → extend `scripts/test-database-integration.sh`
- **n8n templates** → extend `scripts/test-n8n-templates.sh`
- **Ollama / LLMs** → extend `scripts/test-ollama-integration.sh`
- **Something new** → create `scripts/test-<feature>.sh`, make it executable, and add `"test:<feature>": "./scripts/test-<feature>.sh"` to `package.json`. Chain it into the top-level `"test"` script.

Tests should:

- exit non-zero on failure
- print a clear human-readable line on success/failure
- finish in under 2 minutes (cap any LLM call with `num_predict` or a timeout)

## Anti-patterns to avoid

- **Hardcoding secrets in committed workflow/credential JSON.** Always go via `N8N_ENCRYPTION_KEY` + `.env`.
- **Bind-mounting host paths in workflows.** Workflows must work from a fresh clone.
- **Workflows that depend on external SaaS APIs without docs.** If you require a key, document it in `templates/README.md` and gate the workflow.
- **Tags on seeded workflows.** Always ship `"tags": []` — see workflow section above.
- **Forgetting `workflow-ids.activate`.** A workflow that isn't in that list will import but stay inactive, and the webhook won't respond.

## Helpful invariants for AI agents

When making changes, you can rely on these:

- `docker exec supabase-db psql -U postgres ...` always works against the live local DB.
- `docker exec n8n n8n list:workflow` lists all workflows by `id|name`.
- `docker exec n8n n8n update:workflow --id=<id> --active=true` activates a workflow without a restart cycle (n8n then needs a restart to start the trigger).
- The n8n `n8n` Postgres schema lives in the same `postgres` database as Supabase. You can `SELECT ... FROM n8n.workflow_entity` and `SELECT ... FROM n8n.chat_hub_agents` directly.
- The MCP HTTP endpoint at `http://localhost:5678/mcp-server/http` (inside Docker: `http://127.0.0.1:5678/mcp-server/http`) accepts JSON-RPC 2.0 over HTTP with bearer auth. `N8NMcpBearer001` is the canonical credential.
- All Kong-routed Supabase endpoints accept the anon JWT in `ANON_KEY` from `.env`.
- The seed marker `/home/node/.n8n/.template-seed-complete` inside the `n8n` container is the single source of truth for "templates have been imported". Delete it to force re-import without wiping the DB.

If any of these break, treat it as a regression and fix it.
