# n8n Demo Data

This directory holds the seed workflow and credentials that are imported into
n8n the first time the stack starts. The `n8n-import` container in
[`docker-compose.yml`](../docker-compose.yml) runs once, calls
`n8n import:credentials` and `n8n import:workflow`, then exits before the main
`n8n` service comes online.

## What's seeded

| File | Purpose |
| ---- | ------- |
| `demo-data/workflows/bKhNvmpDfT4mclXo.json` | "Self Hosted Ollama Chat" — a chat trigger wired to a Langchain LLM chain backed by the Ollama node (`llama3.2:1b`). |
| `demo-data/credentials/*.json` | Encrypted credential entries referenced by the workflow. Decryption requires `N8N_ENCRYPTION_KEY` (set in `.env`). |

The workflow is published to `http://localhost:5678` and the chat trigger
exposes a public webhook (`/webhook-test/<webhookId>`).

## Replacing or updating the seed data

The runtime n8n data lives in the named bind mount `./volumes/n8n`. To export
the current state back into the seed bundle (so a fresh clone reproduces what
you have):

```bash
# Export all workflows and credentials from the running stack
docker compose exec n8n n8n export:workflow --all --output=/demo-data/workflows --separate
docker compose exec n8n n8n export:credentials --all --output=/demo-data/credentials --separate
```

Both commands write into `/demo-data` inside the container, which is bind-mounted
to `./n8n/demo-data` on the host.

> **Credential secrets** are encrypted with `N8N_ENCRYPTION_KEY`. If you rotate
> that key without re-exporting, the seeded credentials will become unusable on
> the next clean start.

## Resetting n8n

```bash
# Wipe n8n DB rows + binary data + volume, then re-seed on next start
docker compose down
rm -rf volumes/n8n
docker compose up -d
```

The `n8n.sql` init script and the Postgres schema (`n8n` schema in the main
`postgres` database) are what make this work — they're created during the first
DB bootstrap by [`volumes/db/n8n.sql`](../volumes/db/n8n.sql).
