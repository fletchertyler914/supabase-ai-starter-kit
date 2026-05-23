# Demo assets

## Banner

[`supabase-ai-starter-kit-banner.png`](./supabase-ai-starter-kit-banner.png) — repo banner image.

## Demo recording (recommended for launch)

Add a short screen recording for the README and social posts:

| File | Format | Suggested length |
| --- | --- | --- |
| `demo.gif` | Animated GIF | 15–30 seconds |
| `demo.mp4` | Video | 15–30 seconds |

### What to show

1. `npm run setup` completing successfully (or stack already up).
2. Browser opens [n8n](http://localhost:5678).
3. **Chat → Workflow agents → AI Starter Console** — ask what is available.
4. **NodeBot Builder** — prompt such as: `Create a webhook workflow at path lead-capture that accepts JSON and returns a normalized response.`
5. Click the workflow URL returned in chat and show the workflow in n8n.

### After recording

Embed near the top of the root [`README.md`](../README.md), for example:

```markdown
![Demo](./assets/demo.gif)
```

Re-run a quick `npm test` before recording so the validation output in the terminal matches a healthy stack.
