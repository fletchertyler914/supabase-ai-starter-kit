# Template credentials

Committed credential exports are **encrypted with `N8N_ENCRYPTION_KEY`** from `.env`. They must not contain production API keys, service-role tokens, or webhook signing secrets.

## Shipped credentials

| File | Type | Purpose |
| ---- | ---- | ------- |
| `VmhEukzPe8au9PTB.json` | `ollamaApi` | Points at the in-stack Ollama service (`http://ollama:11434`). Used by **Template - Local Ollama Chat**. |

## Adding credentials for your own workflows

1. Create credentials in the n8n UI (or via CLI inside the `n8n` container).
2. Export with `n8n export:credentials --separate --output=/demo-data/credentials`.
3. Re-export only after scrubbing secrets — prefer env-based configuration in nodes where possible.

If you rotate `N8N_ENCRYPTION_KEY`, re-export credentials or recreate them in the UI.
