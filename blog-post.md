# From Zero to AI in 60 Seconds: Why I Built the Supabase AI Starter Kit

_How one Docker command eliminates the "configuration tax" that kills weekend AI projects_

---

## The Weekend Warrior's Dilemma

Picture this: It's Friday night. You've got a brilliant AI idea brewing, and you're ready to build. But 6 hours later, you're still wrestling with Docker configs, environment variables, and dependency hell instead of writing the code that matters.

Sound familiar?

Every developer who's tried to build an AI-powered app has been there. You want to focus on creating, not configuring. That's exactly why I created the **Supabase AI Starter Kit** – a zero-configuration Docker Compose template that gets you from idea to working AI app in literally one command.

## The Magic: One Command, Full Stack

```bash
docker compose --profile cpu up
```

That's it. No YAML editing. No credential juggling. No "works on my machine" surprises.

### What's included

✅ **[Supabase](https://supabase.com/)** - PostgreSQL + Auth + Realtime + Edge Functions + pgvector  
✅ **[n8n](https://n8n.io/)** - Visual workflow automation with 400+ integrations  
✅ **[Ollama](https://ollama.com/)** - Local LLMs that actually work in production  
✅ **Pre-built AI chatbots** - Ready to use, zero configuration required

### What you can build

⭐️ **AI-powered customer support** with your company docs  
⭐️ **Smart document processing** workflows that never leak data  
⭐️ **Local RAG systems** with vector search and semantic retrieval  
⭐️ **Automated content generation** pipelines for marketing teams

## What Makes This Different?

### 🤖 **Instant AI Chatbots (Zero Setup Required)**

Most AI starter kits give you the ingredients but make you cook the meal. Not here. The moment your containers boot up, you have two working chatbots:

- **"NodeBot"** - A technical AI assistant pre-trained on Supabase, n8n, and Ollama workflows
- **"Local Ollama Chat"** - A general-purpose chatbot for Mac users with local Ollama

The workflows auto-activate and persist changes automatically. No manual configuration needed.

### ⚡ **Vector Search Without the Hassle**

PostgreSQL with pgvector comes pre-configured and ready for semantic search:

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

No extensions to install, no vector database drama. Just semantic search that works.

### 🔧 **Smart Environment Handling**

The kit automatically detects your setup:

- **Mac with local Ollama?** Set `OLLAMA_HOST=host.docker.internal:11434` and go
- **Want GPU acceleration?** Use `--profile gpu-nvidia` or `--profile gpu-amd`
- **Need email testing?** Add the dev profile for a local email server

### 🔄 **The Reset Script That Respects Your Time**

Here's a detail that shows the thoughtfulness behind this project: the reset script. It gives you nuclear reset capability while being smart about what you actually want to preserve:

```bash
# Reset everything but keep downloaded Ollama models (saves re-download time)
./reset.sh

# Reset everything including models (completely fresh start)
./reset.sh --clear-ollama
```

Most developers want to reset their database and configs but not re-download gigabytes of LLM models. This script gets it.

## The Architecture That Makes Sense

The Docker Compose setup uses smart service profiles and dependency management:

```yaml
# CPU-only setup (default)
docker compose --profile cpu up

# GPU acceleration for NVIDIA
docker compose --profile gpu-nvidia up

# Development with email testing
docker compose -f docker-compose.yml -f dev/docker-compose.dev.yml up
```

Each profile includes exactly what you need, nothing more. The services communicate through a shared network with health checks and proper dependency ordering.

## Real-World Developer Experience

### The Good Parts

- **Instant gratification**: Working chatbots in under a minute
- **No dependency hell**: Everything containerized and isolated
- **Flexible**: Works equally well for prototypes and production
- **Local-first**: Your data stays on your machine
- **Extensible**: Built on standard tools you can customize

### What You Get Out of the Box

| Service         | URL                 | Purpose                             |
| --------------- | ------------------- | ----------------------------------- |
| Supabase Studio | `localhost:8000`    | Database admin & project management |
| n8n Workflows   | `localhost:5678`    | Visual automation builder           |
| AI Chatbots     | Direct webhook URLs | Ready-to-use conversational AI      |
| Email Testing   | `localhost:9000`    | Local email server for auth flows   |

## The Technical Innovation

### Pre-loaded Workflows

The n8n instance comes with pre-built, activated workflows. No importing JSON files or manual setup. The "NodeBot" chatbot is specifically trained to help with the exact stack you're using:

_"I'm NodeBot, your local AI co-pilot for Supabase, n8n, and Ollama. Need help wiring up a workflow, setting up Supabase rules, or running local AI models?"_

### Smart Model Management

Ollama models are configurable but sensible:

```bash
# Default models that actually fit in memory and work well
OLLAMA_DEFAULT_MODELS=llama3.2:1b,nomic-embed-text

# Want more? Add them easily
OLLAMA_DEFAULT_MODELS=llama3.2:1b,nomic-embed-text,llama3.2:3b,codellama:7b
```

### GPU Support Done Right

GPU acceleration just works, with separate profiles for NVIDIA and AMD setups. No driver wrestling or CUDA complexity.

## Why This Matters for the AI Ecosystem

The barrier to AI experimentation shouldn't be infrastructure setup. Too many good ideas die in Docker hell before they ever get built.

While [n8n's self-hosted AI starter kit](https://github.com/n8n-io/self-hosted-ai-starter-kit) provides excellent n8n + Ollama + Qdrant integration, this Supabase variant recognizes that most developers need more than just workflow automation. You need auth, real-time features, edge functions, and a complete backend - not just vector storage.

### Key Differentiators

| Feature                | n8n Starter Kit | Supabase AI Starter Kit                |
| ---------------------- | --------------- | -------------------------------------- |
| **Vector Storage**     | Qdrant          | PostgreSQL + pgvector                  |
| **Authentication**     | ❌              | ✅ Built-in auth with social providers |
| **Real-time Features** | ❌              | ✅ WebSocket subscriptions             |
| **Edge Functions**     | ❌              | ✅ Serverless TypeScript functions     |
| **Database Admin**     | ❌              | ✅ Supabase Studio interface           |
| **Email Testing**      | ❌              | ✅ Local email server for dev          |
| **Pre-built Chatbots** | ❌              | ✅ Two working chatbots out of the box |

This kit combines the best of both worlds: n8n's powerful workflow automation with Supabase's complete backend-as-a-service platform. It's opinionated where it matters (smart defaults, proven integrations) and flexible where you need it (GPU options, model choices, extensible workflows).

## Try It Yourself

The core of the Supabase AI Starter Kit is a Docker Compose file, pre-configured with network and storage settings, minimizing the need for additional installations. Ready to skip the configuration tax and start building?

### Quick Start

```bash
git clone https://github.com/fletchertyler914/supabase-ai-starter-kit.git
cd supabase-ai-starter-kit
docker compose --profile cpu up
```

**That's it.** Now follow these steps:

1. **Open [http://localhost:5678/](http://localhost:5678/)** in your browser to set up n8n. You'll only have to do this once.
2. **Navigate to the included workflows** - they're automatically imported and activated
3. **Click the direct chat links** to start using the AI chatbots immediately:
   - **NodeBot**: [http://localhost:5678/webhook/ba65d0a2-7d1d-4efe-9e7a-c41b1031e3bb/chat](http://localhost:5678/webhook/ba65d0a2-7d1d-4efe-9e7a-c41b1031e3bb/chat)
   - **Local Ollama**: [http://localhost:5678/webhook/d1433448-02fc-44cd-9512-63941e7c4973/chat](http://localhost:5678/webhook/d1433448-02fc-44cd-9512-63941e7c4973/chat)
4. **If this is your first time**, you may need to wait while Ollama downloads the `llama3.2:1b` model. You can inspect the Docker console logs to check progress.

### Platform-Specific Setup

**Mac users with local Ollama:**

```bash
# First, start Ollama locally and pull models
ollama serve
ollama pull llama3.2:1b
ollama pull nomic-embed-text

# Then run the stack
export OLLAMA_HOST=host.docker.internal:11434
docker compose up
```

**GPU acceleration:**

```bash
# NVIDIA users
docker compose --profile gpu-nvidia up

# AMD users (Linux)
docker compose --profile gpu-amd up
```

With your n8n instance running, you'll have access to over 400 integrations and a suite of AI nodes including AI Agent, Text Classifier, and Information Extractor. To keep everything local, the workflows use Ollama for language models and PostgreSQL with pgvector for embeddings.

### Quick Troubleshooting

**Workflows appear inactive?** The included workflows should auto-activate, but if they don't:

```bash
# Manually activate all workflows
docker exec n8n n8n update:workflow --all --active=true
docker compose restart n8n
```

**Need a clean slate?** Use the intelligent reset script:

```bash
# Reset everything but preserve Ollama models (recommended)
./reset.sh

# Nuclear option - reset everything including models
./reset.sh --clear-ollama
```

**Chat links not working?** Make sure you've completed the initial n8n setup at [http://localhost:5678/](http://localhost:5678/) first.

> **Note**: This starter kit is designed to help you get started with self-hosted AI workflows. While it's not fully optimized for production environments, it combines robust, battle-tested components that work well together for proof-of-concept projects and rapid prototyping. You can customize it to meet your specific needs.

## What's Next?

This starter kit represents where I think AI development tooling should go: **less configuration, more creation**. The goal isn't to be the most feature-complete solution – it's to be the fastest path from idea to working prototype.

Future improvements I'm considering:

- More pre-built workflow templates (RAG, document processing, API integrations)
- One-click deployment to common hosting providers
- Better observability and debugging tools
- Integration with popular frontend frameworks

---

**The bottom line**: Your weekend projects deserve better than getting stuck in setup hell. Sometimes the best innovation isn't adding more features – it's removing friction.

What would you build if setup took 60 seconds instead of 6 hours?

---

_Found this useful? Star the [repo](https://github.com/fletchertyler914/supabase-ai-starter-kit) and let me know what you build with it. I'm always curious to see what happens when developers can focus on creating instead of configuring._
