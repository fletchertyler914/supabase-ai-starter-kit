# Quickstart (5 minutes)

This kit gives you a local AI playground: a full Supabase backend + n8n for visual workflows + Ollama for local LLMs, all running on your machine. You can build AI agents and integrations without writing infrastructure code.

You don't need to be a developer to use this. The setup wizard does everything.

## What you need

| Required | Why | How to get it |
| --- | --- | --- |
| **Docker Desktop** | Runs the stack | https://www.docker.com/products/docker-desktop |
| **Git** | Clone the repo | https://git-scm.com/downloads (preinstalled on macOS) |
| **Node.js 18+** | Runs the `npm` commands | https://nodejs.org/ |
| **Ollama** (optional but recommended) | Local LLMs | https://ollama.com/download |

If you skip Ollama, the wizard will offer to run it inside Docker instead. Slower, but no extra install.

## Run the wizard

```bash
git clone https://github.com/fletchertyler914/supabase-ai-starter-kit.git
cd supabase-ai-starter-kit
npm install            # installs nothing of substance, just sets up scripts
npm run setup
```

The wizard will:

1. Check Docker is running
2. Create `.env` from sane defaults
3. Detect Ollama (host or container)
4. Pull the local chat model (`llama3.2:3b`, ~2 GB) and a tool-capable builder model (`llama3.2:3b` by default)
5. Start the stack
6. Configure n8n's local MCP token for workflow building (after your first n8n owner account exists)
7. Run the full validation suite (auth, database, templates, real LLM)
8. Print the URLs and credentials

When it finishes, n8n opens in your browser.

## What you get

| Service | URL | Login |
| --- | --- | --- |
| **n8n workflows** | http://localhost:5678 | `admin` / `changeme` |
| **Supabase Studio** | http://localhost:8000 | `supabase` / `this_password_is_insecure_and_should_be_updated` |
| **Email inbox (dev)** | http://localhost:9000 | none |
| **MinIO (S3 console)** | http://localhost:9101 | `supa-storage-admin` / `super-secret-jwt-token-with-at-least-32-characters-long` |

> Defaults are safe for local-only use. Change every password in `.env` before exposing this on the public internet.

## What's preconfigured

When you log in to n8n the first time, you already have:

- **Personal agent** (Chat Hub → Personal agents → *Local Ollama Agent*) — drop-in chat with your local LLM.
- **Workflow agents** in Chat Hub:
  - **AI Starter Console** — guided tour of the stack, status checks, template pointers.
  - **NodeBot Builder** — describe a workflow in chat, watch n8n create it.
- **Six user-facing templates** auto-imported and **activated**:
  - Local Ollama Chat (chat trigger)
  - Supabase API Health Check (webhook)
  - Document Ingest + Query (RAG webhooks)
  - NodeBot Builder (chat trigger + MCP tools)
  - AI Starter Console (Chat Hub workflow agent)
  - Starter Kit Index (JSON catalog webhook)
- **Eleven builder helper sub-workflows** (called by NodeBot Builder / Console under the hood).
- **Instance-level MCP** turned on; `npm run setup` creates the first n8n owner and issues the MCP token automatically.

### Start with the AI Starter Console

Click **Chat** (top-left) → **Workflow agents** → **AI Starter Console**. Ask:

```text
What's running in my starter kit and what should I try first?
```

Or fetch the read-only JSON catalog without opening chat:

```bash
curl -s http://localhost:5678/webhook/template-kit-index | jq .
```

### Try RAG (document search)

```bash
curl -s -X POST http://localhost:5678/webhook/template-rag-ingest \
  -H 'Content-Type: application/json' \
  -d '{"content":"pgvector stores embeddings for semantic search.","metadata":{"topic":"pgvector"}}'

curl -s -X POST http://localhost:5678/webhook/template-rag-query \
  -H 'Content-Type: application/json' \
  -d '{"question":"How does pgvector help with search?"}'
```

Or run `npm run test:rag` after the stack is up.

### Talk to the Personal Agent

Click the **Chat** icon (top-left in n8n) → **Personal agents** → **Local Ollama Agent**. Ask anything:

```text
What can I build with this starter kit?
```

That's a real LLM running on your machine.

### Build workflows by chatting (NodeBot Builder)

Same Chat Hub, **Workflow agents** tab → **NodeBot Builder**. The four suggested prompts are the four guaranteed-to-work fast paths:

| Prompt | What it does |
| --- | --- |
| *"Create a workflow with a Manual Trigger and a Set node that returns hello from NodeBot."* | Greeting demo |
| *"Create a webhook workflow at path lead-capture that accepts JSON and returns a normalized response."* | POST webhook |
| *"Create a scheduled workflow that runs every morning at 9am and logs a heartbeat message."* | Cron job |
| *"List the workflows in this n8n instance."* | Read-only listing |

Each one finishes in a few seconds and gives you a real URL like `http://localhost:5678/workflow/<id>` you can click to inspect and activate.

For anything outside those four shapes the agent falls back to n8n's instance-level MCP builder tools (search nodes, validate SDK code, create workflows). It also has helpers for **RAG**, **update/activate/delete**, and **Postgres row triggers**. If you ask for something complex and the small default model struggles, bump the builder model (see [docs/models.md](./docs/models.md)):

```bash
echo 'OLLAMA_BUILDER_MODEL=qwen2.5:7b-instruct' >> .env
ollama pull qwen2.5:7b-instruct
npm run setup
```

### Call a template from the terminal

```bash
# Streaming chat through the Local Ollama Chat template
curl -s -X POST \
  http://localhost:5678/webhook/ba65d0a2-7d1d-4efe-9e7a-c41b1031e3bb/chat \
  -H 'Content-Type: application/json' \
  -d '{"action":"sendMessage","sessionId":"my-test","chatInput":"Hello"}'

# Supabase health probe template
curl -s -X POST http://localhost:5678/webhook/template-supabase-health | jq .
```

> MCP credentials are configured automatically by `npm run setup` — no manual re-run needed on fresh installs.

## Build your own

You have two ways to extend the kit:

1. **Visually in n8n** — drag nodes, connect them, click activate. See [`EXTENDING.md`](./EXTENDING.md) for patterns: "AI agent with tools", "process new database rows", "respond to emails".
2. **With an AI agent (Cursor/Claude)** — point your AI coding agent at this repo and ask it to "add a workflow that does X" or "add a new edge function for Y". The repo layout and conventions in [`EXTENDING.md`](./EXTENDING.md) are written so an AI can follow them autonomously.

## Stop, restart, reset

```bash
npm stop               # stop everything, keep data
npm run dev:full       # start again (keeps data)
npm run reset          # wipe everything (asks for confirmation)
```

## Deploying somewhere

When you want to put this on the internet, read [`DEPLOY.md`](./DEPLOY.md). It compares free, cheap, and managed options honestly.

## Something's wrong?

```bash
npm run health         # quick health check
npm run logs           # tail all container logs
docker compose ps      # see container state
```

If anything important looks broken, open an issue with the output of `npm run health`.
