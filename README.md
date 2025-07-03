![Supabase AI Starter Kit](./assets/supabase-ai-starter-kit-banner.png)

# Supabase AI Starter Kit

> **Production-ready AI infrastructure. Ship in hours, not weeks.**

An open-source, Infrastructure-as-Code template that gets you from AI concept to working application in minutes. Built for developers, AI engineers, and teams who need to move fast without sacrificing production quality.

![Supabase](https://img.shields.io/badge/supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Kong](https://img.shields.io/badge/kong-003459?style=for-the-badge&logo=kong&logoColor=white)
![n8n](https://img.shields.io/badge/n8n-EA4B71?style=for-the-badge&logo=n8n&logoColor=white)
![Docker](https://img.shields.io/badge/docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/postgresql-336791?style=for-the-badge&logo=postgresql&logoColor=white)

**Infrastructure-as-Code. No Supabase Studio required. Everything in Docker.**

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
- **Vector Search** - Semantic search and RAG (Retrieval Augmented Generation)
- **AI Model Connectors** - Pre-configured for OpenAI, Anthropic, Ollama, and more
- **Batch Processing** - Background jobs for training and large-scale operations
- **Real-time AI** - Streaming responses and live AI interactions

### 🛠️ **Developer Experience**

- **Complete Testing Suite** - Postman collections, Node.js scripts, health checks
- **Development Email** - Inbucket for testing auth flows without external SMTP
- **Infrastructure-as-Code** - Everything configured via Docker and environment files
- **Zero External Dependencies** - No Supabase Studio or cloud services required

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

## 🚀 Quick Start (60 seconds)

### **1. Clone & Configure**

```bash
git clone https://github.com/fletchertyler914/supabase-ai-starter-kit.git
cd supabase-ai-starter-kit

# Copy environment template and configure
cp .env.example .env
# Edit .env with your API keys and settings
```

### **2. Start Everything**

```bash
# Recommended: Use npm scripts
npm run dev                      # Start with development features
npm run health                   # Validate everything works

# Or use Docker directly
docker-compose up -d
docker-compose -f docker-compose.yml -f docker/docker-compose.dev.yml up -d
```

### **3. Validate Setup**

```bash
# Test everything (recommended)
npm test

# Or run individual tests
npm run health                   # System health check
npm run test:auth                # Authentication flow
npm run test:db                  # Database integration

# Access services
npm run kong:open                # Kong API Gateway
npm run n8n:open                 # n8n Workflows
npm run email:open               # Email Testing (dev mode)
```

**That's it!** You now have a production-ready AI infrastructure stack running locally.

> 💡 **Pro Tip:** Use `npm run` to see all available commands, or check [package.json](./package.json) for the complete list of convenience scripts.

## 🌐 Service Architecture

| Service              | URL                                     | Purpose                                 |
| -------------------- | --------------------------------------- | --------------------------------------- |
| **Kong API Gateway** | [localhost:8000](http://localhost:8000) | Main API entry point, routing, security |
| **n8n Workflows**    | [localhost:5678](http://localhost:5678) | Visual AI workflow automation           |
| **Email Testing**    | [localhost:9000](http://localhost:9000) | Development email server (dev mode)     |
| **Supabase Auth**    | localhost:8000/auth/v1/\*               | Authentication endpoints via Kong       |
| **PostgREST API**    | localhost:8000/rest/v1/\*               | Database REST API via Kong              |
| **Realtime**         | localhost:8000/realtime/v1/\*           | WebSocket connections via Kong          |

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

### **Complete Test Suite**

- **Postman Collections** - All API endpoints with environment variables
- **Authentication Tests** - Full signup/signin/confirmation flow
- **Health Checks** - Service monitoring and connectivity validation
- **Integration Tests** - End-to-end workflow validation

### **Test Authentication Flow**

```bash
# Test complete auth flow with email confirmation
node scripts/test-auth-complete.js

# Test direct auth service (bypass Kong)
node scripts/test-auth-direct.js

# Basic auth functionality
node scripts/test-auth.js
```

### **API Testing with Postman**

```bash
# Import collections (pre-configured)
# 1. Open Postman
# 2. Import: postman/Supabase-AI-Starter-Kit.postman_collection.json
# 3. Import: postman/Supabase-AI-Starter-Kit.postman_environment.json
# 4. Configure environment variables with your keys

# Or setup keys automatically
cd postman && ./setup-keys.sh
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

### **n8n AI Workflows**

- **Pre-configured integrations** for OpenAI, Anthropic, Hugging Face
- **Vector database nodes** for embeddings and similarity search
- **Webhook endpoints** for real-time AI processing
- **Background jobs** for batch AI operations
- **Template workflows** for common AI patterns

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
# Development with email testing
docker-compose -f docker-compose.yml -f docker/docker-compose.dev.yml up -d

# Production-like setup
docker-compose up -d

# View logs
docker-compose logs -f [service-name]

# Reset and clean restart
./scripts/reset.sh
```

### **NPM Scripts (Recommended)** 🚀

For an even better developer experience, use the included npm scripts:

```bash
# Quick start commands
npm run start                    # Intelligent startup
npm run dev                      # Development mode with email
npm run dev:full                 # Full development stack (email + S3)
npm stop                         # Stop all services
npm run reset                    # Clean reset

# Testing commands
npm test                         # Run all tests
npm run health                   # Health check
npm run test:auth                # Test authentication
npm run test:db                  # Test database

# Utility commands
npm run logs                     # View all logs
npm run db:connect               # Connect to database
npm run email:open               # Open email interface
npm run n8n:open                 # Open n8n workflows
npm run kong:open                # Open Kong gateway
```

## 🔧 Configuration & Customization

### **Environment Variables**

Key settings in `.env`:

```bash
# Database
POSTGRES_PASSWORD=your-super-secret-jwt-token-with-at-least-32-characters-long

# Authentication
ENABLE_EMAIL_SIGNUP=true
ENABLE_EMAIL_AUTOCONFIRM=false  # Set true for development
DISABLE_SIGNUP=false

# SMTP (for production)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# AI Service Keys (add as needed)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
PERPLEXITY_API_KEY=pplx-...
```

### **AI Model Configuration**

Configure your AI integrations by setting environment variables in your `.env` file:

```bash
# AI Provider Keys
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
# Simple upgrade process
./scripts/reset.sh              # Clean state
docker-compose pull     # Latest images
docker-compose up -d    # Restart with updates
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

### **Getting Started Guides**

- [**Authentication Setup**](./postman/README.md) - Complete auth flow setup
- [**API Testing**](./scripts/README.md) - Testing and validation
- [**n8n Workflows**](./n8n/README.md) - AI automation patterns
- [**Database Schema**](./volumes/db/) - PostgreSQL setup and extensions
- [**Docker Configurations**](./docker/) - Development and deployment compose files

### **Advanced Topics**

- [**Production Deployment**](./DEPLOYMENT.md) - Production setup and configuration
- [**Security Best Practices**](./SECURITY.md) - Security hardening and compliance
- [**Performance Tuning**](./PERFORMANCE.md) - Optimization and scaling
- [**Troubleshooting Guide**](./TROUBLESHOOTING.md) - Common issues and solutions

## 🛟 Troubleshooting

### **Common Issues**

**Services not starting?**

```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs -f

# Reset and restart
./scripts/reset.sh && docker-compose up -d
```

**Authentication failing?**

```bash
# Test auth flow
node scripts/test-auth-complete.js

# Check email service (dev mode)
open http://localhost:9000

# Verify Kong routing
curl http://localhost:8000/auth/v1/health
```

**n8n workflows not working?**

```bash
# Restart n8n service
docker-compose restart n8n

# Check n8n logs
docker-compose logs -f n8n

# Access n8n interface
open http://localhost:5678
```

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

We welcome contributions! Whether you're:

- **Fixing bugs** or improving documentation
- **Adding new AI workflow templates**
- **Sharing use case examples**
- **Improving performance or security**

Check out our [Contributing Guidelines](./CONTRIBUTING.md) to get started.

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
