# Public Launch Checklist

Use this checklist before promoting the repo publicly.

## GitHub Repository Settings

- Enable **Template repository** so visitors get the "Use this template" button.
- Enable **Discussions** for questions, ideas, and show-and-tell.
- Enable **Private vulnerability reporting** under Security settings.
- Add repository topics: `supabase`, `n8n`, `ollama`, `pgvector`, `rag`, `self-hosted`, `ai-starter-kit`, `docker`, `postgres`, `local-first`.
- Add a concise repository description: `Local-first Supabase AI starter kit with n8n, pgvector RAG, Ollama, Kong, and one-command setup.`
- Add the website field if you publish docs or a demo page later.

## Demo Assets

- Record a 15-30 second GIF or MP4 showing:
  1. `npm run setup` completing successfully.
  2. n8n opening at `http://localhost:5678`.
  3. Chat Hub -> Workflow agents -> AI Starter Console.
  4. NodeBot Builder creating a simple webhook workflow.
  5. The generated workflow URL opening in n8n.
- Save the final asset as `assets/demo.gif` or `assets/demo.mp4`.
- Add the demo asset near the top of `README.md` under the badges.

## Release Hygiene

- Create an initial GitHub release after the next clean `main` CI run.
- Keep `CHANGELOG.md` updated for user-facing changes.
- Tag releases when Docker image versions or workflow seed contracts change.

## High-Impact Follow-Ups

- Add a tiny optional app under `apps/web/` that demonstrates login, chat, and RAG query against the seeded stack.
- Add a visual observability dashboard on top of `ai_calls` and `ai_call_daily_stats` so users can see local model usage and workflow latency from the UI.
- Add a model fallback path for `volumes/functions/ollama-chat/index.ts`: local Ollama first, optional hosted providers second.
- Add one real-world integration template such as Slack or Discord RAG Q&A.
- Add a builder eval harness that prompts NodeBot Builder with known requests and verifies the expected helper/tool path.

