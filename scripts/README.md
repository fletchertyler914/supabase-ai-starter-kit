# Scripts

Utility scripts for bootstrapping, operating, and validating the Supabase AI Starter Kit stack. Most are wired through `npm run` in [`package.json`](../package.json).

## Quick reference

| Script | npm command | Purpose |
| --- | --- | --- |
| `setup.sh` | `npm run setup` | Interactive bootstrap: `.env`, Docker, Ollama, model pulls, MCP token, full test pass |
| `start.sh` | `npm start` | Start stack; flags: `--cpu`, `--gpu-nvidia`, `--gpu-amd`, `--dev-email` |
| `reset.sh` | `npm run reset` | Interactive teardown; `--clear-ollama` removes Ollama model volumes |
| `tunnel.sh` | `npm run tunnel` | Cloudflare Tunnel for a public demo URL |
| `health-check.sh` | `npm run health` | Container and endpoint health |
| `verify-local.sh` | `npm run verify` | CI-like local verification pipeline |
| `backup.sh` | `npm run backup` | `pg_dump` plus n8n/storage tarball under `backups/` |
| `restore.sh` | `npm run restore` | Restore from a backup created by `backup.sh` |
| `upgrade-check.sh` | `npm run upgrade:check` | Compare pinned image tags against upstream |
| `validate-workflow-json.sh` | `npm run validate:workflows` | Validate seeded n8n workflow JSON (also runs in CI) |
| `test-auth-complete.js` | `npm run test:auth` | Full signup/signin/confirm flow through Kong |
| `test-auth-direct.js` | `npm run test:auth:direct` | Auth flow bypassing Kong (debugging) |
| `test-auth.js` | `npm run test:auth:basic` | Minimal auth smoke test |
| `test-database-integration.sh` | `npm run test:db` | DB schemas, extensions, JWT, pgvector, RAG helpers, n8n schema |
| `test-n8n-templates.sh` | `npm run test:templates` | Workflow import, activation, MCP, builder/console shape, webhook smoke |
| `test-n8n-builder-agent.sh` | `npm run test:builder` | MCP endpoint and NodeBot Builder wiring |
| `test-n8n-builder-e2e.sh` | `npm run test:builder:e2e` | Builder workflow end-to-end smoke test |
| `test-rag-flow.sh` | `npm run test:rag` | RAG ingest + query through n8n webhooks |
| `test-ollama-integration.sh` | `npm run test:ollama` | Ollama chat round-trip through seeded webhook |
| `test-edge-functions.sh` | `npm run test:edge` | Edge function smoke tests |

## Start here

```bash
npm run setup
```

`setup.sh` checks Docker, configures `.env`, detects or starts Ollama, pulls chat and builder models, starts the stack, seeds workflows, issues an n8n MCP token after the first owner account exists, runs `npm test`, and opens n8n.

Re-run after creating your first n8n owner, after changing `OLLAMA_BUILDER_MODEL`, or after rotating `N8N_MCP_ACCESS_TOKEN`.

## Lifecycle

```bash
npm start              # ./scripts/start.sh
npm stop               # docker compose down
npm run restart
npm run reset          # interactive; preserves Ollama models unless --clear-ollama
npm run logs
npm run tunnel         # public HTTPS demo via Cloudflare
```

Compose overlays (see [`docker/`](../docker/)):

```bash
npm run dev            # base + dev overlay
npm run dev:email      # base + Inbucket
npm run dev:s3         # base + MinIO
npm run dev:full       # base + dev + email + S3
```

## Validation

Default suite (`npm test`):

```bash
npm run test:health
npm run test:auth
npm run test:db
npm run test:templates
npm run test:rag
npm run test:ollama
```

Individual checks:

```bash
npm run validate:workflows
npm run test:builder
npm run test:builder:e2e
npm run test:edge
npm run verify           # broader CI-like pipeline
npm run upgrade:check
```

**Ollama-dependent tests:** `test:rag` and `test:ollama` exit successfully with a warning when Ollama is not reachable at `http://localhost:11434`. That keeps CI and Ollama-less local runs green while still exercising the full path when Ollama is running (host install or `docker compose --profile cpu up -d ollama-cpu`).

## Backup and restore

Workflow and credential data live in Postgres (`n8n` schema) and on disk under `volumes/`. Use backups before major upgrades or destructive resets.

```bash
npm run backup         # writes timestamped artifacts under backups/
npm run restore        # interactive restore from a prior backup
```

## Auth tests

```bash
npm run test:auth          # recommended end-to-end flow
npm run test:auth:direct   # auth service only
npm run test:auth:basic    # minimal check
```

Requires the stack running and `.env` configured. `test:auth` expects the dev email overlay (`npm run dev:email` or `npm run dev:full`) for confirmation links.

## n8n and workflow tests

- **`test-n8n-templates.sh`** — Confirms 17 seeded workflows import and activate, NodeBot Builder and AI Starter Console agent shapes, MCP enabled, bootstrap sharing, and health/index webhook smoke tests.
- **`test-n8n-builder-agent.sh`** — MCP `tools/list` and NodeBot Builder readiness; warns (does not fail) if no MCP token yet.
- **`test-n8n-builder-e2e.sh`** — Drives builder paths against a running stack.
- **`validate-workflow-json.sh`** — Static JSON validation for seed files under `n8n/demo-data/workflows/`.

See [`n8n/README.md`](../n8n/README.md) and [`templates/README.md`](../templates/README.md) for workflow IDs and template behavior.

## When to run what

| Situation | Command |
| --- | --- |
| First clone | `npm run setup` |
| After stack start | `npm run health` |
| After DB or migration changes | `npm run test:db` |
| After workflow JSON edits | `npm run validate:workflows` && `npm run test:templates` |
| Before opening a PR | `npm test` (or `npm run verify` for broader coverage) |
| Before upgrade | `npm run upgrade:check` && `npm run backup` |

## Prerequisites

- Docker Desktop (or Docker Engine) running
- Node.js 18+ (for npm scripts and auth tests only; no npm dependencies to install)
- Ollama on the host or via Compose profile for full RAG/Ollama test coverage

## Exit codes

- **0** — success (including intentional Ollama skips)
- **1** — failure; scripts print actionable errors before exiting
