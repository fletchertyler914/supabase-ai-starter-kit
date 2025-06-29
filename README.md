# Supabase AI Starter Kit

**Supabase AI Starter Kit** is an open-source Docker Compose template designed to swiftly initialize a comprehensive local AI and low-code development environment using Supabase as the backbone.

Inspired by the [n8n self-hosted AI starter kit](https://github.com/n8n-io/self-hosted-ai-starter-kit), this project combines the power of self-hosted Supabase with n8n automation platform and local AI capabilities for building sophisticated AI workflows with enterprise-grade data management.

### What's included

✅ **[Supabase](https://supabase.com/)** - Open-source Firebase alternative with PostgreSQL, Auth, instant APIs, Edge Functions, Realtime subscriptions, and Storage
✅ **[n8n](https://n8n.io/)** - Low-code platform with over 400 integrations and advanced AI components  
✅ **[Ollama](https://ollama.com/)** - Cross-platform LLM platform to install and run the latest local LLMs
✅ **[PostgreSQL with pgvector](https://github.com/pgvector/pgvector)** - Supabase's PostgreSQL with vector similarity search capabilities
✅ **Kong API Gateway** - API gateway for routing and security
✅ **Realtime Server** - For real-time subscriptions and live updates

### What you can build

⭐️ **AI-powered applications** with built-in authentication and real-time capabilities  
⭐️ **Document analysis workflows** with vector search and semantic similarity  
⭐️ **Intelligent chatbots** backed by your own data stored securely in Supabase  
⭐️ **Automated data processing pipelines** with n8n workflows and Supabase functions  
⭐️ **Private AI assistants** with conversation history and user management

## Installation

### Prerequisites

- Docker and Docker Compose installed
- At least 8GB of RAM recommended
- For GPU acceleration: NVIDIA Docker runtime (optional)

### Cloning the Repository

```bash
git clone <your-repo-url>
cd supabase-project
```

### Running using Docker Compose

#### For Nvidia GPU users

```bash
docker compose --profile gpu-nvidia up
```

> [!NOTE]
> If you have not used your Nvidia GPU with Docker before, please follow the
> [Ollama Docker instructions](https://github.com/ollama/ollama/blob/main/docs/docker.md).

#### For AMD GPU users on Linux

```bash
docker compose --profile gpu-amd up
```

#### For Mac / Apple Silicon users

If you're using a Mac with an M1 or newer processor, you can't expose your GPU to the Docker instance, unfortunately. There are two options in this case:

1. Run the starter kit fully on CPU, like in the section "For everyone else" below
2. Run Ollama on your Mac for faster inference, and connect to that from the n8n instance

If you want to run Ollama on your mac, check the [Ollama homepage](https://ollama.com/) for installation instructions, and run the starter kit as follows:

```bash
docker compose up
```

##### For Mac users running OLLAMA locally

If you're running OLLAMA locally on your Mac (not in Docker), you need to modify the OLLAMA_HOST environment variable in the n8n service configuration. Update the x-n8n section in your Docker Compose file as follows:

```yaml
x-n8n: &service-n8n # ... other configurations ...
  environment:
    # ... other environment variables ...
    - OLLAMA_HOST=host.docker.internal:11434
```

Additionally, after you see "Editor is now accessible via:":

1. Head to http://localhost:5678
2. Click on "Local Ollama service"
3. Change the base URL to "http://host.docker.internal:11434/"

#### For everyone else

```bash
docker compose --profile cpu up
```

## ⚡️ Quick start and usage

The core of the Supabase AI Starter Kit is a Docker Compose file, pre-configured with network and storage settings, minimizing the need for additional installations. After completing the installation steps above, simply follow the steps below to get started.

1. Open [http://localhost:5678](http://localhost:5678) in your browser to set up n8n. You'll only have to do this once.
2. Select the **pre-loaded chatbot workflow** that matches your setup:
   - **"Local Ollama Chat (Macbook)"** if running Ollama locally on Mac
   - **"Self Hosted Ollama Chat"** if using Docker-based Ollama
3. Click the **Chat** button at the bottom of the canvas to start chatting immediately!
4. If this is the first time you're running the workflow, you may need to wait until Ollama finishes downloading Llama3.2. You can inspect the docker console logs to check on the progress.

To open n8n at any time, visit [http://localhost:5678](http://localhost:5678) in your browser. With your n8n instance, you'll have access to over 400 integrations and a suite of basic and advanced AI nodes such as [AI Agent](https://docs.n8n.io/integrations/builtin/cluster-nodes/root-nodes/n8n-nodes-langchain.agent/), [Text classifier](https://docs.n8n.io/integrations/builtin/cluster-nodes/root-nodes/n8n-nodes-langchain.text-classifier/), and [Information Extractor](https://docs.n8n.io/integrations/builtin/cluster-nodes/root-nodes/n8n-nodes-langchain.information-extractor/) nodes. To keep everything local, just remember to use the Ollama node for your language model and Supabase with pgvector for your vector store.

> [!NOTE]
> This starter kit is designed to help you get started with self-hosted AI
> workflows. While it's not fully optimized for production environments, it
> combines robust components that work well together for proof-of-concept
> projects. You can customize it to meet your specific needs

### 1. Access Supabase Dashboard

- Open [http://localhost:8000](http://localhost:8000) to access the Supabase Studio
- Default credentials are typically found in your `.env` file or docker-compose configuration

### 2. Access n8n and Start Chatting

- Open [http://localhost:5678](http://localhost:5678) to set up n8n (first-time setup required)
- **Demo workflows are automatically loaded!** No imports needed.

### 3. Ready-to-Use Chatbot Workflows

The starter kit includes **pre-loaded demo workflows** that work immediately out of the box:

1. **"Local Ollama Chat (Macbook)"** - Works with Ollama running locally on your Mac
2. **"Self Hosted Ollama Chat"** - Works with Ollama running in Docker containers

**Everything is pre-configured!** Just select the workflow that matches your setup and start chatting immediately - no configuration required!

### 4. Set up your own AI workflow

1. In n8n, create a new workflow or customize one of the demo workflows
2. Configure the Supabase node with your local instance credentials:
   - URL: `http://supabase-kong:8000`
   - Service Role Key: (found in your Supabase project settings)
3. Configure Ollama connection:
   - Base URL: `http://host.docker.internal:11434` (for Mac) or `http://ollama:11434` (for Docker-based Ollama)

### 5. Database and Vector Search Setup

Your Supabase instance comes pre-configured with:

- PostgreSQL with pgvector extension **automatically enabled**
- Authentication and user management
- Real-time subscriptions
- Edge Functions runtime
- Custom `cosine_similarity()` function for convenience

**Vector search is ready to use immediately!** No manual setup required.

Example usage:

```sql
-- Create a table with vector column
CREATE TABLE documents (
  id SERIAL PRIMARY KEY,
  content TEXT,
  embedding VECTOR(1536), -- Adjust dimension based on your model
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create an index for faster vector searches
CREATE INDEX ON documents USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- Insert a document with embedding
INSERT INTO documents (content, embedding) VALUES
  ('Sample text', '[0.1, 0.2, 0.3, ...]'::vector);

-- Similarity search using cosine distance
SELECT content, cosine_similarity(embedding, '[0.1, 0.2, 0.3, ...]'::vector) as similarity
FROM documents
ORDER BY embedding <=> '[0.1, 0.2, 0.3, ...]'::vector
LIMIT 5;
```

**Test vector functionality**: Run the `test-vector-db.sql` script in Supabase Studio to verify everything is working.

## Key Differences from the Original n8n AI Starter Kit

This setup replaces the separate PostgreSQL + Qdrant stack with Supabase, providing:

### Advantages of Supabase Integration:

- **Unified Data Platform**: Single database for both structured data and vector search
- **Built-in Authentication**: User management and security out of the box
- **Real-time Capabilities**: Live updates and subscriptions
- **Edge Functions**: Serverless functions for custom logic
- **Admin Dashboard**: Web interface for database management
- **Auto-generated APIs**: Instant REST and GraphQL APIs

### Architecture Changes:

- **PostgreSQL with pgvector** replaces separate PostgreSQL + Qdrant
- **Supabase Studio** provides database administration
- **Kong Gateway** handles API routing and authentication
- **Realtime server** enables live data synchronization

## Configuration

### Environment Variables

Key configuration options (typically in `.env` or docker-compose files):

```env
# Supabase Configuration
POSTGRES_PASSWORD=your-secure-password
JWT_SECRET=your-jwt-secret
ANON_KEY=your-anon-key
SERVICE_ROLE_KEY=your-service-role-key

# n8n Configuration
N8N_HOST=localhost
N8N_PORT=5678

# Ollama Configuration (for Mac users)
OLLAMA_HOST=host.docker.internal:11434
```

### Accessing Local Files

The setup creates a shared folder mounted to `/data/shared` within containers, allowing n8n to access files on your local system.

**Nodes that interact with the local filesystem:**

- [Read/Write Files from Disk](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.filesreadwrite/)
- [Local File Trigger](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.localfiletrigger/)
- [Execute Command](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.executecommand/)

## Upgrading

### For Nvidia GPU setups:

```bash
docker compose --profile gpu-nvidia pull
docker compose create && docker compose --profile gpu-nvidia up
```

### For AMD GPU setups:

```bash
docker compose --profile gpu-amd pull
docker compose create && docker compose --profile gpu-amd up
```

### For Mac / Apple Silicon users

```bash
docker compose pull
docker compose create && docker compose up
```

### For Non-GPU setups:

```bash
docker compose --profile cpu pull
docker compose create && docker compose --profile cpu up
```

## 👓 Recommended Reading

### Supabase Resources:

- [Supabase Documentation](https://supabase.com/docs)
- [pgvector and Vector Search](https://supabase.com/docs/guides/database/extensions/pgvector)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [Real-time with Supabase](https://supabase.com/docs/guides/realtime)

### n8n AI Resources:

- [AI agents for developers: from theory to practice with n8n](https://blog.n8n.io/ai-agents/)
- [Tutorial: Build an AI workflow in n8n](https://docs.n8n.io/advanced-ai/intro-tutorial/)
- [Langchain Concepts in n8n](https://docs.n8n.io/advanced-ai/langchain/langchain-n8n/)
- [What are vector databases?](https://docs.n8n.io/advanced-ai/examples/understand-vector-databases/)

## 🛍️ Example Workflows

Here are some AI workflow ideas particularly well-suited for the Supabase + n8n combination:

- **User-specific AI Chat**: Leverage Supabase auth to create personalized AI experiences
- **Document Processing Pipeline**: Upload files, extract text, generate embeddings, store in Supabase
- **Real-time AI Notifications**: Use Supabase real-time to trigger AI workflows
- **Multi-tenant AI Applications**: Use Supabase RLS (Row Level Security) for data isolation

Visit the [official n8n AI template gallery](https://n8n.io/workflows/categories/ai/) for more workflow inspiration.

## Troubleshooting

### Common Issues:

**Ollama Connection Issues (Mac)**:

- Ensure Ollama is running locally: `ollama serve`
- Verify n8n can reach `host.docker.internal:11434`
- Check firewall settings

**Supabase Connection Issues**:

- Verify all containers are running: `docker compose ps`
- Check logs: `docker compose logs supabase-db`
- Ensure ports 8000 and 5432 are not in use by other services

**Performance Issues**:

- Allocate more memory to Docker (8GB+ recommended)
- For large datasets, consider optimizing vector indexes
- Monitor resource usage: `docker stats`

## 📜 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 💬 Support

For support and community discussion:

- **Supabase**: [Supabase Discord](https://discord.supabase.com/) and [GitHub Discussions](https://github.com/supabase/supabase/discussions)
- **n8n**: [n8n Community Forum](https://community.n8n.io/)
- **General Issues**: Open an issue in this repository

## Acknowledgments

This project is inspired by and builds upon:

- [n8n Self-hosted AI Starter Kit](https://github.com/n8n-io/self-hosted-ai-starter-kit)
- [Supabase Self-hosting Guide](https://supabase.com/docs/guides/hosting/docker)
- The amazing open-source communities behind Supabase, n8n, and Ollama
