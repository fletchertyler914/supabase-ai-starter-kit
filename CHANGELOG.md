# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [0.1.0] - 2026-05-23

First public launch of the Supabase AI Starter Kit as a local-first, self-hosted AI application stack.

### Added

- One-command setup (`npm run setup`) with Docker, Ollama detection, model pulls, workflow seeding, MCP token issuance, and validation.
- Self-hosted Supabase stack: Auth, Postgres, pgvector, Realtime, Storage, Edge Functions, Kong gateway, Supavisor pooler.
- n8n with 17 seeded workflows: 6 user-facing templates (including NodeBot Builder, AI Starter Console, RAG ingest/query) and 11 builder helpers.
- Ollama integration for local chat and embeddings (`llama3.2:3b`, `nomic-embed-text`).
- RAG schema (`public.documents`, `match_documents()`) and AI call telemetry (`ai_calls`, daily stats view).
- Test suite: health, auth, database integration, templates, RAG, Ollama (skips when Ollama unreachable), builder readiness, workflow JSON validation.
- GitHub Actions CI: full Docker stack startup and `npm test`.
- Documentation: README launch positioning, QUICKSTART, EXTENDING, DEPLOY, UPGRADING, CONTRIBUTING, SECURITY, devcontainer/Codespaces.
- Scripts: backup/restore, upgrade-check, Cloudflare Tunnel, verify-local pipeline.
- Deployment notes: Cloudflare Tunnel, Coolify/VPS, hybrid cloud paths in DEPLOY.md.

### Changed

- README rewritten for clearer audience, wow moment, and non-goals.
- DB migration mount order fixed for lexicographic init (`99-vector.sql` before `99-vector_match_documents.sql`).

### Fixed

- CI failures from Postgres init ordering (`extensions.vector` before `match_documents`).
- Ollama-dependent tests skip cleanly when Ollama is not running (CI and local runs without Ollama).

[0.1.0]: https://github.com/fletchertyler914/supabase-ai-starter-kit/releases/tag/v0.1.0

## Unreleased

### Added

- Community and contributor documentation for public collaboration.
- GitHub issue and pull request templates.
- Devcontainer configuration for Codespaces and local container-based development.
