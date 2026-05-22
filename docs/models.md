# Tested Ollama Models (Starter Kit)

These models were exercised locally with Dockerized or host-run Ollama for chat, embeddings (`nomic-embed-text`), and the **Template - NodeBot Builder** agent (**builder tool-calling** = MCP + workflow tools behaving reliably).

| model | size | RAM | Chat OK | builder tool-calling | notes |
| --- | --- | --- | --- | --- | --- |
| `llama3.2:3b` | ~2.0 GiB | ≥ ~4 GiB | Yes | Yes | Default pulls in compose; smallest stable option for MCP-style loops. |
| `qwen2.5:7b-instruct` | ~4.7 GiB | ≥ ~8 GiB | Yes | Mostly | Strong instruction following; heavier than 3B; occasional tool-arg retries. |
| `llama3.1:8b` | ~4.9 GiB | ≥ ~8 GiB | Yes | Mostly | Solid chat; MCP tool calls work but latency and footprint beat 3B. |

\*RAM/VRAM targets assume reasonable CPU throughput or a single modest GPU workload; quantized pull weights vary slightly by revision.

For embeddings-only workloads, **`nomic-embed-text`** (768‑dim, see `match_documents`) is validated alongside the pgvector/`documents` RAG templates.
