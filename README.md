# Supabase AI Starter Kit

> **Build AI that scales. Ship in a weekend, iterate forever.**

An open-source Docker Compose template that gets you from idea to AI-powered app in minutes, not months. Built for the builders, hackers, and 100x developers who move fast and ship things.

![Supabase](https://img.shields.io/badge/supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![n8n](https://img.shields.io/badge/n8n-EA4B71?style=for-the-badge&logo=n8n&logoColor=white)
![Ollama](https://img.shields.io/badge/ollama-000000?style=for-the-badge&logoColor=white)

## What's Inside 🚀

- **[Supabase](https://supabase.com/)** - PostgreSQL + Auth + Realtime + Edge Functions + pgvector
- **[n8n](https://n8n.io/)** - Visual workflow automation with 400+ integrations
- **[Ollama](https://ollama.com/)** - Local LLMs that actually work
- **Pre-built AI chatbots** - Ready to use, zero configuration required

## Quick Start

### 1. Get the code:

```bash
git clone https://github.com/fletchertyler914/supabase-ai-starter-kit.git
cd supabase-ai-starter-kit
```

### 2. Run it:

**Default setup (CPU-only):**

```bash
docker compose --profile cpu up
```

**Mac users with local Ollama:**

First, start Ollama locally and pull the models:

```bash
# Start Ollama (if not already running)
ollama serve

# Pull the default models
ollama pull llama3.2:1b
ollama pull nomic-embed-text
```

Then run the stack (no profile needed):

```bash
export OLLAMA_HOST=host.docker.internal:11434
docker compose up
```

**Open [localhost:5678](http://localhost:5678) → Complete the quick setup → Select a chatbot workflow → Start chatting.**

That's it. No yaml editing, no credential juggling. **It just works.**

## GPU Support (Optional)

**NVIDIA:**

```bash
docker compose --profile gpu-nvidia up
```

**AMD (Linux):**

```bash
docker compose --profile gpu-amd up
```

## What You Get Out of the Box

### 🤖 **Instant AI Chatbots**

One unified workflow that works with both local and Docker Ollama setups:

- **"Ollama Chat"** - Automatically detects and works with your Ollama configuration

**Direct Chat Link** (available after running the stack):

- **Chat Interface**: [http://localhost:5678/webhook/ba65d0a2-7d1d-4efe-9e7a-c41b1031e3bb/chat](http://localhost:5678/webhook/ba65d0a2-7d1d-4efe-9e7a-c41b1031e3bb/chat)

> ✨ **Workflow is automatically activated!** The chat link works immediately after startup.

> ✨ **Workflow changes auto-save!** Modify the workflow in the n8n UI and it persists automatically.

### ⚡ **Vector Search Ready**

PostgreSQL with pgvector extension pre-configured. No setup, no fuss:

```sql
-- Create your table
CREATE TABLE documents (
  id SERIAL PRIMARY KEY,
  content TEXT,
  embedding VECTOR(1536),
  metadata JSONB DEFAULT '{}'
);

-- Search semantically
SELECT content, cosine_similarity(embedding, '[...]'::vector) as similarity
FROM documents
ORDER BY embedding <=> '[...]'::vector
LIMIT 5;
```

### 🔐 **Auth & Realtime Built-in**

User management, real-time subscriptions, and APIs auto-generated. Because life's too short to build auth from scratch.

## For the Tinkerers

### Local Email Testing

```bash
docker compose -f docker-compose.yml -f dev/docker-compose.dev.yml up
```

Includes local email server at [localhost:9000](http://localhost:9000) for testing OTP flows.

### Environment Magic

```bash
# Use local Ollama (Mac)
OLLAMA_HOST=host.docker.internal:11434

# Use Docker Ollama (default)
# No env var needed
```

### Adding More Ollama Models

**Before starting containers** (add to `.env` file):

```bash
# Comma-separated list of models to pull automatically
# Default: llama3.2:1b,nomic-embed-text
OLLAMA_DEFAULT_MODELS=llama3.2:1b,nomic-embed-text,llama3.2:3b,codellama:7b
```

**After containers are running:**

```bash
# Pull additional models manually
docker exec ollama-cpu ollama pull llama3.2:3b
docker exec ollama-cpu ollama pull codellama:7b

# Or for GPU containers
docker exec ollama-gpu ollama pull llama3.2:3b

# List available models
docker exec ollama-cpu ollama list
```

### First-Time Setup

When you first access n8n at [localhost:5678](http://localhost:5678), you'll need to create an owner account. This is a one-time setup - just provide an email and password to get started.

### Troubleshooting

**Workflows appear inactive?** If imported workflows don't activate automatically:

```bash
# Manually activate all workflows
docker exec n8n n8n update:workflow --all --active=true

# Then restart the container
docker compose restart n8n
```

**Need a clean slate?** Reset the entire project while preserving or clearing Ollama models:

```bash
# Reset everything but keep downloaded Ollama models (default)
./reset.sh

# Reset everything including Ollama models
./reset.sh --clear-ollama

# See all available options
./reset.sh --help
```

**Note**: The reset script preserves Ollama models by default to save re-download time. Use `--clear-ollama` if you want to start completely fresh.

## Services

| Service             | URL                                     | Purpose          |
| ------------------- | --------------------------------------- | ---------------- |
| **Supabase Studio** | [localhost:8000](http://localhost:8000) | Database admin   |
| **n8n**             | [localhost:5678](http://localhost:5678) | Workflow builder |
| **Email Testing**   | [localhost:9000](http://localhost:9000) | Dev emails       |

## Why This Exists

Every weekend warrior and side-project hero has been there: you have a brilliant AI idea, but you spend 6 hours wrestling with Docker configs instead of building. This starter kit is for the builders who want to spend their time creating, not configuring.

**Inspired by the [n8n AI starter kit](https://github.com/n8n-io/self-hosted-ai-starter-kit)**, but supercharged with Supabase's unified platform. Because why manage separate services when you can have it all in one beautiful, scalable stack?

## The Supabase Difference

Unlike traditional setups with PostgreSQL + Qdrant + separate auth services:

- **One database** for everything (structured data + vectors)
- **Built-in auth** with social providers, magic links, OTP
- **Real-time subscriptions** out of the box
- **Edge functions** for custom logic
- **Auto-generated APIs** (REST + GraphQL)
- **Row Level Security** for multi-tenant apps

## Contributing

**We'd love your help making this even better!** 🙌

- **Found a bug?** [Open an issue](https://github.com/fletchertyler914/supabase-ai-starter-kit/issues)
- **Have an idea?** [Start a discussion](https://github.com/fletchertyler914/supabase-ai-starter-kit/discussions) or submit a PR
- **Built something cool?** Share your workflows and demos
- **Improved the docs?** Documentation PRs are always welcome

Whether you're fixing typos, adding features, or sharing workflows - every contribution makes this better for the community.

## Community & Support

Built with ❤️ by developers, for developers.

- **Issues & Questions**: [GitHub Issues](https://github.com/fletchertyler914/supabase-ai-starter-kit/issues)
- **Supabase Community**: [Discord](https://discord.supabase.com/)
- **n8n Community**: [Forum](https://community.n8n.io/)

## License

Apache License 2.0 - Build something awesome.

---

**Happy building!** 🛠️ _From all of us who believe that the best way to predict the future is to build it._
