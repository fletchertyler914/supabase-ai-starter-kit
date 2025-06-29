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

```bash
export OLLAMA_HOST=host.docker.internal:11434
docker compose --profile cpu up
```

**Open [localhost:5678](http://localhost:5678) → Select a chatbot workflow → Start chatting.**

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

Two pre-loaded workflows that work immediately:

- **"Local Ollama Chat (Macbook)"**
- **"Self Hosted Ollama Chat"**

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

## Community & Support

Built with ❤️ by developers, for developers.

- **Issues & Questions**: [GitHub Issues](https://github.com/fletchertyler914/supabase-ai-starter-kit/issues)
- **Supabase Community**: [Discord](https://discord.supabase.com/)
- **n8n Community**: [Forum](https://community.n8n.io/)

## License

Apache License 2.0 - Build something awesome.

---

**Happy building!** 🛠️ _From all of us who believe that the best way to predict the future is to build it._
