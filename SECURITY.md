# Security Policy

## Supported Versions

Security fixes target the latest `main` branch and the latest tagged release.

## Reporting a Vulnerability

Please do not open a public issue for suspected vulnerabilities.

Report security issues through GitHub's private vulnerability reporting feature if it is enabled for this repository. If it is not enabled, open a minimal public issue asking for a private disclosure channel without including exploit details.

Include as much detail as possible:

- Affected component or file path.
- Steps to reproduce.
- Impact and exploitability.
- Any logs, requests, or workflow JSON needed to verify the issue.

## Secrets and Local Data

This project generates local credentials for Supabase, n8n, and seeded n8n credentials. Do not commit:

- `.env`
- exported n8n credentials with real tokens
- database dumps
- `volumes/**` runtime data
- private model keys or SaaS API keys

The sample `.env.example` file contains development defaults only. Replace all credentials before exposing the stack beyond localhost.

## Deployment Warning

The default setup is optimized for local development. Before public exposure, review `DEPLOY.md`, rotate all secrets, enable TLS at the edge, lock down n8n, and review Supabase/Kong authentication settings.

