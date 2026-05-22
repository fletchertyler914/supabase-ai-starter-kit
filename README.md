# Supabase AI Starter Kit

> **Self-hosted Supabase + Kong + n8n + pgvector + Ollama, all in one Docker stack.**

An open-source, Infrastructure-as-Code template that gives you a complete self-hosted Supabase backend plus n8n workflow automation, ready for AI/RAG/LLM workloads on day one.

![Supabase](https://img.shields.io/badge/supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Kong](https://img.shields.io/badge/kong-003459?style=for-the-badge&logo=kong&logoColor=white)
![n8n](https://img.shields.io/badge/n8n-EA4B71?style=for-the-badge&logo=n8n&logoColor=white)
![Docker](https://img.shields.io/badge/docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/postgresql-336791?style=for-the-badge&logo=postgresql&logoColor=white)

**Infrastructure-as-Code. Everything in Docker. No external dependencies.**

## 🚀 What You Get

### ⚡ **Complete AI-Ready Backend**

- **PostgreSQL + pgvector** - Vector database for embeddings and semantic search
- **Supabase Auth** - Email/password authentication with email confirmation
- **Kong API Gateway** - Professional API management and routing
- **Real-time Features** - WebSocket subscriptions for live AI interactions
- **Edge Functions** - Serverless TypeScript functions for AI processing
- **File Storage** - Supabase Storage for AI training data and media

### 🧠 **AI Integration Platform**

- **n8n Workflows** - Visual automation for AI pipelines and integrations
- **Preconfigured Chat Hub agents** - Personal "Local Ollama Agent" + Workflow agents "AI Starter Console" and "NodeBot Builder"
- **NodeBot Builder** - Describe a workflow in chat, it gets built. Uses 9 fast-helper sub-workflows + n8n's instance-level MCP under the hood
- **RAG template** - Document ingest + semantic query webhooks backed by pgvector (`nomic-embed-text` embeddings)
- **Vector Search** - Semantic search and RAG (Retrieval Augmented Generation)
- **AI Model Connectors** - Pre-configured for OpenAI, Anthropic, Ollama, and more
- **Batch Processing** - Background jobs for training and large-scale operations
- **Real-time AI** - Streaming responses and live AI interactions

### 🛠️ **Developer Experience**

- **Built-in Test Suite** - Node.js auth flow tests + shell health/db integration tests
- **Development Email** - Inbucket for testing auth flows without external SMTP
- **Optional Local LLMs** - Run Ollama on CPU/NVIDIA/AMD via Docker profiles
- **Infrastructure-as-Code** - Everything configured via Docker and environment files

## 🎯 What You Can Build

### 🤖 **AI Chatbots & Assistants**

- Customer support bots with company knowledge
- Technical documentation assistants
- Multi-user chat applications with context
- Real-time conversational AI with memory

### 📊 **AI Analytics & Insights**

- Intelligent data processing pipelines
- Semantic search across documents and data
- Real-time AI-powered dashboards
- Automated report generation and insights

### 🎨 **AI Content Generation**

- Text, image, and media generation workflows
- Content approval and review systems
- Template-based generation with customization
- Multi-step creative pipelines

### 🔍 **AI-Powered Search & Discovery**

- Vector search across any content type
- Personalized recommendation engines
- Intelligent content categorization
- Semantic similarity and clustering

## 🚀 Quick Start (one command)

```bash
git clone https://github.com/fletchertyler914/supabase-ai-starter-kit.git
cd supabase-ai-starter-kit
npm run setup
```

That runs an interactive wizard which checks Docker, detects Ollama (host or containerized), generates `.env`, pulls the chat model (`llama3.2:3b`, ~2 GB) and the NodeBot Builder model (`OLLAMA_BUILDER_MODEL`, `llama3.2:3b` by default), starts the full stack, seeds the Chat Hub agents + 17 n8n workflows (6 user-facing templates + 11 builder helpers), issues an MCP access token from the first n8n owner, runs the full validation suite, and opens n8n in your browser.

See [QUICKSTART.md](./QUICKSTART.md) for the non-dev walkthrough, [EXTENDING.md](./EXTENDING.md) for adding workflows/integrations (designed to be followed by AI agents like Cursor/Claude too), and [DEPLOY.md](./DEPLOY.md) for honest deployment options (Cloudflare Tunnel, Coolify on a VPS, Fly.io, hybrid Cloud).

### Manual start (if you prefer)

```bash
cp .env.example .env
npm run dev:full           # base + dev + email + S3 (MinIO)
# or: npm start            # base stack only (host Ollama expected)
```

> **Tip:** Without a `--cpu`/`--gpu-*` flag, the kit expects Ollama to already
> be running on the host (`http://host.docker.internal:11434`). To run Ollama
> in Docker instead, use `./scripts/start.sh --cpu` / `--gpu-nvidia` / `--gpu-amd`.

### **3. Validate Setup**

```bash
# Test everything (recommended)
npm test

# Or run individual tests
npm run health                   # System health check
npm run test:auth                # Authentication flow
npm run test:db                  # Database integration
npm run test:builder             # n8n MCP workflow-builder smoke test

# Access services
npm run kong:open                # Kong API Gateway
npm run n8n:open                 # n8n Workflows
npm run email:open               # Email Testing (dev mode)
```

**That's it!** You now have a production-ready AI infrastructure stack running locally.

> 💡 **Pro Tip:** Use `npm run` to see all available commands, or check [package.json](./package.json) for the complete list of convenience scripts.

## 🌐 Service Architecture

| Service              | URL                                     | Purpose                                       |
| -------------------- | --------------------------------------- | --------------------------------------------- |
| **Kong API Gateway** | [localhost:8000](http://localhost:8000) | Main API entry point, routing, security       |
| **Supabase Studio**  | [localhost:8000](http://localhost:8000) | DB/auth/storage UI (basic-auth via Kong)      |
| **n8n Workflows**    | [localhost:5678](http://localhost:5678) | Visual AI workflow automation                 |
| **Analytics**        | [localhost:4000](http://localhost:4000) | Logflare logs UI                              |
| **Email (dev)**      | [localhost:9000](http://localhost:9000) | Inbucket web UI (`npm run dev:email`)         |
| **MinIO console**    | [localhost:9101](http://localhost:9101) | S3-compatible storage console (`dev:s3`)      |
| **Postgres pooler**  | localhost:5432                          | Supavisor session pool                        |
| **Postgres txn**     | localhost:6543                          | Supavisor transaction pool                    |
| **Supabase Auth**    | localhost:8000/auth/v1/\*               | Authentication endpoints via Kong             |
| **PostgREST API**    | localhost:8000/rest/v1/\*               | Database REST API via Kong                    |
| **Realtime**         | localhost:8000/realtime/v1/\*           | WebSocket connections via Kong                |
| **Storage**          | localhost:8000/storage/v1/\*            | File storage API via Kong                     |
| **Edge Functions**   | localhost:8000/functions/v1/\*          | Deno serverless functions                     |

### 🏗️ Core Infrastructure

```
┌─ Kong API Gateway (8000) ────────────────────────────┐
│                                                      │
├─ Auth Service (/auth/v1/*)                          │
├─ REST API (/rest/v1/*)                              │
├─ Realtime (/realtime/v1/*)                          │
├─ Storage (/storage/v1/*)                            │
└─ Functions (/functions/v1/*)                        │

┌─ AI & Automation ───────────────────────────────────┐
│                                                      │
├─ n8n Workflows (5678)                               │
├─ PostgreSQL + pgvector                              │
├─ Background Processing                               │
└─ AI Model Integrations                              │

┌─ Development Tools ─────────────────────────────────┐
│                                                      │
├─ Inbucket Email (9000)                              │
├─ Postman Collections                                │
├─ Health Check Scripts                               │
└─ Authentication Tests                               │
```

## 🧪 Built-in Testing & Validation

### **Test Suite**

- **Authentication Tests** - Full signup/signin/confirmation flow against Kong
- **Health Checks** - Service monitoring and connectivity validation
- **Database Integration** - Schemas, extensions, JWT, pgvector, roles

### **Test Authentication Flow**

```bash
# Full auth flow with email confirmation
node scripts/test-auth-complete.js

# Auth service direct (bypass Kong)
node scripts/test-auth-direct.js

# Basic auth functionality
node scripts/test-auth.js
```

## 🧠 AI Development Patterns

### **Vector Search & RAG**

```sql
-- PostgreSQL with pgvector is ready for AI embeddings
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content TEXT,
  embedding VECTOR(1536),
  metadata JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Semantic search example
SELECT content, 1 - (embedding <=> '[0.1,0.2,...]'::vector) as similarity
FROM documents
ORDER BY embedding <=> '[0.1,0.2,...]'::vector
LIMIT 5;
```

### **Pre-configured AI in n8n**

Out of the box you get:

- **Personal agent** (n8n Chat Hub → Personal agents → *Local Ollama Agent*) — plain chat with your local Ollama model. Pre-wired with `llama3.2:3b`, suggested prompts, and a directive system prompt so small models stop leaking instructions.
- **Workflow agents** in Chat Hub:
  - **NodeBot Builder** — describe a workflow in chat, watch it appear in n8n. Uses 4 fast-helper sub-workflows (greeting / webhook / scheduled / list) plus n8n's instance-level MCP for anything custom.
- **Webhook templates** — auto-imported, auto-activated, ready to curl.
- **Instance-level MCP** is enabled with a bearer token auto-issued by `npm run setup` after your first n8n owner account exists.

User-facing templates ([`templates/README.md`](./templates/README.md)):

| Template | Trigger | What it does |
| -------- | ------- | ------------ |
| **Local Ollama Chat** | LangChain chat (public webhook) | Streaming chat with your local Ollama model |
| **Supabase API Health Check** | `POST /webhook/template-supabase-health` | Verifies Kong/Auth health from inside Docker |
| **NodeBot Builder** | Chat Hub workflow agent | Conversationally builds, lists, and manages n8n workflows |
| **Document Ingest + Query** | Webhooks `template-rag-ingest` / `template-rag-query` | RAG with pgvector + Ollama embeddings |
| **AI Starter Console** | Chat Hub workflow agent | Guided tour, status, template launcher |
| **Starter Kit Index** | Webhook `GET /webhook/template-kit-index` | JSON catalog of templates, helpers, and URLs |

Builder helper sub-workflows (called internally by NodeBot Builder, not for direct use):

| Helper | Pattern |
| --- | --- |
| `SK - Create Greeting Workflow` | Manual Trigger + Set greeting |
| `SK - Create Webhook Workflow` | POST webhook + normalized JSON response |
| `SK - Create Scheduled Workflow` | Schedule Trigger (cron) + Set log |
| `SK - Create RAG Workflow` | RAG ingest + query webhooks |
| `SK - List / Update / Activate / Delete Workflow` | Workflow management |
| `SK - Create Supabase Row Trigger Workflow` | Postgres row-change trigger |
| `SK - Starter Kit Status` | Read-only stack readiness summary |
| `SK - Record AI Call` | Observability insert into `ai_calls` |

```bash
npm run test:templates          # import + workflow shape checks + webhook smoke test
npm run test:rag                # RAG ingest + query end-to-end
npm run test:builder            # MCP + NodeBot Builder readiness
npm run test:ollama             # end-to-end LLM chat through the n8n webhook
npm run validate:workflows      # JSON seed validation (also runs in CI)
npm run backup                  # pg_dump + n8n/storage tarball
curl -s -X POST http://localhost:5678/webhook/template-supabase-health
```

n8n UI defaults to basic auth (`admin` / `changeme` — change in `.env` before exposing publicly). See [`n8n/README.md`](./n8n/README.md).

### **Real-time AI Features**

```javascript
// WebSocket connection for streaming AI responses
import { createClient } from '@supabase/supabase-js';

const supabase = createClient('http://localhost:8000', 'your-anon-key');

// Subscribe to real-time AI updates
supabase
  .channel('ai-responses')
  .on(
    'postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'ai_responses' },
    (payload) => console.log('New AI response:', payload.new)
  )
  .subscribe();
```

## 🛠️ Development Workflow

```bash
# Base stack (no dev overlays)
docker compose up -d

# Base + dev overlay (anonymous DB volume, seed data)
docker compose -f docker-compose.yml -f docker/docker-compose.dev.yml up -d

# View logs for a specific service
docker compose logs -f [service-name]

# Reset and clean restart (drops project volumes)
./scripts/reset.sh
```

### **NPM Scripts (Recommended)**

```bash
# Setup / lifecycle
npm run setup                    # ./scripts/setup.sh (interactive wizard)
npm run tunnel                   # ./scripts/tunnel.sh (Cloudflare Tunnel public URL)
npm start                        # ./scripts/start.sh (smart starter with flags)
npm stop                         # docker compose down
npm run restart                  # docker compose restart
npm run reset                    # ./scripts/reset.sh (interactive)

# Compose modes
npm run dev                      # base + docker/docker-compose.dev.yml
npm run dev:email                # base + Inbucket (dev SMTP / web UI)
npm run dev:s3                   # base + MinIO (S3-compatible storage)
npm run dev:full                 # base + dev + email + S3

# Testing
npm test                         # health + auth + db + templates + ollama
npm run test:templates           # template import + builder shape + webhook smoke test
npm run test:builder             # n8n MCP + NodeBot Builder readiness
npm run test:ollama              # n8n -> Ollama chat webhook end-to-end
npm run health                   # ./scripts/health-check.sh
npm run test:auth                # node scripts/test-auth-complete.js
npm run test:db                  # ./scripts/test-database-integration.sh
npm run verify                   # CI-like local verification pipeline

# Utilities
npm run logs                     # docker compose logs -f
npm run db:logs                  # docker compose logs -f db
npm run db:connect               # psql shell inside supabase-db
npm run kong:open                # http://localhost:8000 (Kong / Studio)
npm run studio:open              # http://localhost:8000 (Studio via Kong)
npm run n8n:open                 # http://localhost:5678
npm run email:open               # http://localhost:9000 (Inbucket)
npm run minio:open               # http://localhost:9101 (MinIO console)
```

### **Ollama (LLM runtime)**

The kit talks to Ollama at `http://ollama:11434` from inside Docker. Choose
one of the following depending on your host:

```bash
# Use Ollama installed on the host machine (default; fastest on Mac)
./scripts/start.sh

# Run Ollama inside Docker on CPU only
./scripts/start.sh --cpu

# NVIDIA / AMD GPU profiles
./scripts/start.sh --gpu-nvidia
./scripts/start.sh --gpu-amd
```

## 🔧 Configuration & Customization

### **Environment Variables**

Key settings in `.env` (see [`.env.example`](./.env.example) for the full list):

```bash
# Secrets — MUST regenerate before any non-local use
POSTGRES_PASSWORD=your-super-secret-and-long-postgres-password
JWT_SECRET=your-super-secret-jwt-token-with-at-least-32-characters-long
ANON_KEY=...                          # Generate via Supabase JWT helper
SERVICE_ROLE_KEY=...                  # Generate via Supabase JWT helper
DASHBOARD_USERNAME=supabase
DASHBOARD_PASSWORD=change-me          # Basic auth in front of Supabase Studio
SECRET_KEY_BASE=...                   # Realtime / Supavisor
VAULT_ENC_KEY=...                     # 32-char min

# Authentication
ENABLE_EMAIL_SIGNUP=true
ENABLE_EMAIL_AUTOCONFIRM=false        # Set true for fully local dev without email
DISABLE_SIGNUP=false

# SMTP — set these in production; for local dev use docker-compose.email.yml
SMTP_HOST=supabase-mail               # = Inbucket when dev:email overlay is on
SMTP_PORT=2500
SMTP_USER=fake_mail_user
SMTP_PASS=fake_mail_password

# n8n
N8N_ENCRYPTION_KEY=super-secret-key
N8N_USER_MANAGEMENT_JWT_SECRET=even-more-secret
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=changeme

# Ollama (local AI)
OLLAMA_HOST=0.0.0.0
OLLAMA_BASE_URL=http://ollama:11434
OLLAMA_DEFAULT_MODELS=llama3.2:3b,nomic-embed-text
OLLAMA_BUILDER_MODEL=llama3.2:3b      # Bump to qwen2.5:7b-instruct etc. for stronger MCP tool calling

# n8n instance-level MCP (auto-managed by npm run setup)
N8N_MCP_MANAGED_BY_ENV=true
N8N_MCP_ACCESS_ENABLED=true
N8N_MCP_ACCESS_TOKEN=                 # Filled by scripts/setup.sh after first n8n owner exists
```

> Generate strong JWT keys with the [Supabase self-hosting guide](https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys).

### **AI Model Configuration**

Add provider keys to `.env` (no defaults are required — they're only used by the
edge functions and n8n nodes you wire up):

```bash
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
PERPLEXITY_API_KEY=pplx-...
GOOGLE_API_KEY=AIza...
```

## 🔐 Security & Production Features

### **Built-in Security**

- **JWT Authentication** - Secure token-based auth with proper expiration
- **Row Level Security** - Database-level authorization for multi-tenancy
- **API Gateway** - Kong providing rate limiting and access control
- **Environment Isolation** - Secure configuration management
- **Network Security** - Proper Docker networking and service isolation

### **Production Ready**

- **Connection Pooling** - PgBouncer for database performance
- **Health Monitoring** - Comprehensive service health checks
- **Logging Infrastructure** - Audit trails and error tracking
- **Data Persistence** - Proper volume management for production data
- **Backup Strategy** - Database persistence and recovery patterns

## 🎯 AI Use Case Examples

### **Chatbot with Memory**

1. **User authentication** via Kong gateway
2. **Conversation storage** in PostgreSQL
3. **Vector search** for context retrieval
4. **n8n workflow** for AI processing
5. **Real-time responses** via WebSocket

### **Document Analysis Pipeline**

1. **File upload** to Supabase Storage
2. **Background processing** via n8n workflows
3. **Vector embeddings** generated and stored
4. **Search API** for semantic queries
5. **Real-time results** via subscriptions

### **Content Generation System**

1. **Template management** in database
2. **Generation workflows** in n8n
3. **Approval processes** with user roles
4. **Version control** with audit trails
5. **API endpoints** for integration

## 📊 Performance & Scaling

### **Optimized for AI Workloads**

- **pgvector** configured for efficient similarity search
- **Connection pooling** via PgBouncer for high concurrency
- **Background processing** for expensive AI operations
- **Caching strategies** built into Kong gateway
- **Resource isolation** via Docker containers

### **Horizontal Scaling Ready**

- **Stateless services** for easy horizontal scaling
- **Database connection pooling** for multiple instances
- **Load balancing** via Kong gateway
- **Microservices architecture** with clear service boundaries

## 🚀 Deployment Options

### **Development**

- **Local Docker** - Full stack on your machine
- **Development email** - Inbucket for testing auth flows
- **Hot reloading** - Live development with instant feedback

### **Production**

- **Docker Compose** - Single-server deployment
- **Environment management** - Production-ready configuration
- **Health monitoring** - Built-in service monitoring
- **SSL/TLS ready** - HTTPS configuration templates

## 🔄 Migration & Upgrades

### **Easy Updates**

```bash
# Pull latest images and restart in place (preserves data volumes)
docker compose pull
docker compose up -d

# Clean-slate upgrade (drops DB / storage / n8n volumes)
./scripts/reset.sh              # Removes containers + project volumes
docker compose pull
npm start
```

### **Data Migration**

- **PostgreSQL dumps** for data backup/restore
- **Volume persistence** maintains data across updates
- **Schema migrations** via SQL scripts
- **n8n workflows** exported/imported automatically

## 🤝 AI Integration

### **Built for AI Applications**

- **Multiple AI Providers** - OpenAI, Anthropic, Google, and more
- **Clear extension points** - Add AI capabilities without breaking existing code
- **Modular architecture** - Mix and match components as needed
- **Vector database ready** - pgvector for semantic search and RAG

### **Development Patterns**

- **Infrastructure-as-Code** - No manual setup or configuration
- **Testing automation** - Comprehensive validation for CI/CD
- **Documentation as code** - Self-documenting APIs and services
- **Extension templates** - Clear patterns for adding new AI features

## 📚 Documentation & Resources

### **In-repo Reference**

- [**Scripts README**](./scripts/README.md) - Setup, tunnel, testing, health, reset utilities
- [**Database Bootstrap**](./volumes/db/) - PostgreSQL init scripts, roles, JWT, pgvector
- [**Kong Routing**](./volumes/api/kong.yml) - Declarative API gateway routes
- [**Edge Functions**](./volumes/functions/) - Deno serverless function runtime
- [**Template library**](./templates/README.md) - User-facing templates + builder sub-workflows + test commands
- [**n8n seed data**](./n8n/demo-data/) - Workflow exports, import manifest, MCP credential, bootstrap SQL
- [**Docker Overlays**](./docker/) - Dev, email (Inbucket), and S3 (MinIO) variants
- [**Extending guide**](./EXTENDING.md) - Add workflows, agents, edge functions; readable by AI coding agents

### **Upstream Documentation**

- [Self-hosting Supabase](https://supabase.com/docs/guides/self-hosting/docker)
- [n8n self-hosted](https://docs.n8n.io/hosting/)
- [Kong declarative config](https://docs.konghq.com/gateway/latest/production/deployment-topologies/db-less-and-declarative-config/)
- [pgvector](https://github.com/pgvector/pgvector)

## 🛟 Troubleshooting

### **Common Issues**

**Services not starting?**

```bash
# Check service status
docker compose ps

# View logs
docker compose logs -f

# Reset and restart
./scripts/reset.sh && docker compose up -d
```

**Authentication failing?**

```bash
# Test auth flow
node scripts/test-auth-complete.js

# Check email service (dev mode)
open http://localhost:9000

# Verify Kong routing
curl -H "apikey: $ANON_KEY" http://localhost:8000/auth/v1/health
```

**n8n workflows not working?**

```bash
# Restart n8n
docker compose restart n8n

# Check n8n logs
docker compose logs -f n8n

# Access n8n interface
open http://localhost:5678
```

**Port conflicts when running `dev:full`?**

The S3 overlay remaps MinIO to host ports `9100` (API) and `9101` (console)
so it can coexist with the Inbucket email overlay on port `9000`. Inside the
docker network MinIO is still reachable at `http://minio:9000`.

### **Reset Options**

```bash
./scripts/reset.sh                    # Standard reset
./scripts/reset.sh --help             # See all options
```

## 📈 What's Next?

### **Extend Your AI App**

1. **Add your AI models** - Configure OpenAI, Anthropic, or local models
2. **Build custom workflows** - Use n8n for complex AI pipelines
3. **Create your database schema** - Add domain-specific tables
4. **Deploy to production** - Use provided Docker Compose setup
5. **Scale horizontally** - Add more service instances as needed

### **Community Features**

- **Workflow templates** - Share n8n AI automation patterns
- **Schema patterns** - Database designs for common AI use cases
- **Integration guides** - Step-by-step guides for popular AI services
- **Performance benchmarks** - Reference implementations and metrics

## 🤝 Contributing

Pull requests and issues are welcome. Please open an issue first to discuss
substantial changes (new services, breaking config changes, image bumps).

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🌟 Why This Exists

AI development shouldn't start with weeks of infrastructure setup. This starter kit eliminates the typical 2-4 weeks of backend work so you can focus on building intelligent features, not configuring services.

**Start building AI applications in hours, not weeks.**

---

**Built with ❤️ for the AI development community**

- **Issues & Support**: [GitHub Issues](https://github.com/fletchertyler914/supabase-ai-starter-kit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/fletchertyler914/supabase-ai-starter-kit/discussions)
- **Community**: [Supabase Discord](https://discord.supabase.com/) | [n8n Community](https://community.n8n.io/)
