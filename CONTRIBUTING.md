# Contributing

Thanks for helping improve Supabase AI Starter Kit. This project aims to stay easy to run locally, honest about deployment trade-offs, and useful as a public reference for self-hosted AI infrastructure.

## Quick Start

```bash
git clone https://github.com/fletchertyler914/supabase-ai-starter-kit.git
cd supabase-ai-starter-kit
npm run setup
```

Before opening a pull request, run the checks that match your change:

```bash
npm run validate:workflows
npm run test:templates
npm run test:db
npm run test:rag
npm run test:builder
```

Use `npm test` when your change touches Docker, Supabase, n8n, workflow imports, auth, RAG, or Ollama wiring.

## What Makes a Good PR

- Keep changes focused. Docs-only updates, workflow-template changes, and stack upgrades should usually be separate PRs.
- Preserve the one-command setup path. A fresh clone should still work with `npm run setup`.
- Update the relevant docs when behavior changes: `README.md`, `QUICKSTART.md`, `EXTENDING.md`, `UPGRADING.md`, `templates/README.md`, or `n8n/README.md`.
- Never commit local secrets, generated credential exports, `.env`, database dumps, or runtime volume data.
- For n8n workflow JSON, run `npm run validate:workflows` before pushing.

## Workflow Template Rules

Seeded workflows live in `n8n/demo-data/workflows/templates/` or `n8n/demo-data/workflows/builder-helpers/`.

When adding or changing a workflow:

1. Use a stable 24-32 character hex workflow `id`.
2. Use a real UUID for `versionId`; n8n 2.x requires it for activation.
3. Add active shipped workflows to `n8n/demo-data/workflow-ids.activate`.
4. Update `n8n/demo-data/manifest.json`.
5. Document user-facing templates in `templates/README.md`.
6. Run `npm run validate:workflows` and `npm run test:templates`.

## Stack Upgrade Rules

When bumping Docker images:

- Update `docker-compose.yml` and any overlay files under `docker/`.
- Update the pinned version table and caveats in `UPGRADING.md`.
- Run `npm run upgrade:check`, `docker compose config --quiet`, and the relevant integration tests.
- Call out major-version risks in the PR description.

## Code Style

This repo is intentionally script-heavy and Docker-native. Prefer small shell scripts with clear output, explicit environment variables, and checks that fail with actionable messages.

For documentation, optimize for someone arriving from GitHub with no context. Keep the README concise and push deep details into focused docs.

