# Project Utility Scripts

This directory contains utility scripts for managing and testing the Supabase AI Starter Kit stack.

| Script | npm wrapper | Purpose |
| --- | --- | --- |
| `setup.sh` | `npm run setup` | Interactive bootstrap: env, Docker, Ollama (host or container), model pulls, MCP token issuance, full test pass |
| `start.sh` | `npm start` | Smart start; flags: `--cpu`, `--gpu-nvidia`, `--gpu-amd`, `--dev-email` |
| `reset.sh` | `npm run reset` | Interactive teardown; `--clear-ollama` wipes models |
| `tunnel.sh` | `npm run tunnel` | Install + run `cloudflared`, expose stack via Cloudflare Tunnel |
| `health-check.sh` | `npm run health` / `test:health` | Container + endpoint health |
| `verify-local.sh` | `npm run verify` | CI-like local verification pipeline |
| `test-auth-complete.js` | `npm run test:auth` | Full signup/signin/confirm/logout flow through Kong |
| `test-auth-direct.js` | `npm run test:auth:direct` | Same, bypassing Kong (debugging) |
| `test-auth.js` | `npm run test:auth:basic` | Minimal auth check |
| `test-database-integration.sh` | `npm run test:db` | DB structure, extensions, JWT, pgvector, roles, n8n schema |
| `test-n8n-templates.sh` | `npm run test:templates` | Workflow import shape, activation, MCP enabled, helper presence, webhook smoke |
| `test-n8n-builder-agent.sh` | `npm run test:builder` | MCP endpoint reachable + NodeBot Builder helper/MCP wiring intact |
| `test-ollama-integration.sh` | `npm run test:ollama` | Real Ollama chat round-trip through the seeded Local Ollama Chat webhook |

## Available Scripts

### 🚀 `setup.sh` — interactive bootstrap (start here)

**Purpose:** One-command onboarding for new users.

- Verifies Docker Desktop is running.
- Detects Ollama (host vs containerized) and offers to start the containerized profile if needed.
- Creates `.env` from `.env.example` when missing.
- Pulls `OLLAMA_MODEL` / `OLLAMA_DEFAULT_MODELS` (chat) and `OLLAMA_BUILDER_MODEL` (NodeBot Builder).
- Starts the full stack via `./scripts/start.sh`.
- Once the first n8n owner account exists, issues an MCP access token, writes it to `.env` (`N8N_MCP_ACCESS_TOKEN`), re-encrypts the seeded `N8NMcpBearer001` credential with the new token, and restarts n8n so the credential is picked up.
- Runs the full `npm test` suite end-to-end.
- Opens n8n in your browser.

**Usage:**

```bash
npm run setup
```

Re-run any time after creating the first n8n owner account, after changing `OLLAMA_BUILDER_MODEL`, or after rotating `N8N_MCP_ACCESS_TOKEN`.

### 🌐 `tunnel.sh` — public URL via Cloudflare

**Purpose:** Get an HTTPS public URL for the local stack without opening router ports.

- Installs `cloudflared` if missing (Homebrew on macOS, apt/curl elsewhere).
- Walks you through `cloudflared login`.
- Starts a named tunnel that proxies `https://<your-subdomain>.<your-domain>` to `http://localhost:8000` (Kong) and `http://localhost:5678` (n8n).

**Usage:**

```bash
npm run tunnel
```

See [`DEPLOY.md`](../DEPLOY.md) for the full deployment matrix.

### 🔐 Authentication Test Scripts

#### `test-auth-complete.js`

**Purpose:** Comprehensive end-to-end authentication flow testing

- Tests complete signup, signin, and user profile workflows
- Validates email confirmation flow
- Tests protected API access with authentication
- Verifies Kong API gateway routing for auth endpoints
- Includes session management and logout testing

#### `test-auth-direct.js`

**Purpose:** Direct authentication service testing (bypassing Kong)

- Tests auth service directly on internal port
- Useful for debugging authentication issues
- Bypasses API gateway for isolated auth testing
- Validates core auth functionality without routing complexity

#### `test-auth.js`

**Purpose:** Basic authentication functionality testing

- Simple signup and signin flow testing
- Quick verification of core auth endpoints
- Lightweight testing for basic auth validation

**Usage:**

```bash
# Test complete authentication flow (recommended)
node scripts/test-auth-complete.js

# Test auth service directly (debugging)
node scripts/test-auth-direct.js

# Basic auth testing
node scripts/test-auth.js
```

**Prerequisites:**

- Docker stack must be running
- Email service must be configured (for test-auth-complete.js)
- .env file with proper auth configuration

### 🧪 `test-database-integration.sh`

**Purpose:** Comprehensive database integration testing

- Tests database structure and schema organization
- Verifies all extensions are installed and working
- Checks JWT configuration and authentication setup
- Tests vector functionality (pgvector)
- Validates n8n integration
- Tests database connectivity and roles
- Includes idempotency testing

**Usage:**

```bash
./scripts/test-database-integration.sh
```

**Prerequisites:**

- Docker stack must be running (`docker compose up`)
- Database service must be healthy

### 🏥 `health-check.sh`

**Purpose:** System health monitoring and service verification

- Checks all Docker services are running and healthy
- Tests service endpoints and connectivity
- Verifies database connections
- Monitors service health status with color-coded results
- Tests API gateway routing and authentication
- Validates n8n web interface accessibility

**Usage:**

```bash
./scripts/health-check.sh
```

**Prerequisites:**

- Docker stack must be running (`docker compose up`)
- .env file must be present with required API keys

### 🚀 `start.sh`

**Purpose:** Intelligent stack startup with development options

- Detects and starts appropriate Docker Compose configuration
- Handles development vs production startup automatically
- Manages network connectivity for services
- Provides startup validation and health checks
- Supports both basic and advanced development modes

**Usage:**

```bash
./scripts/start.sh
```

### 🔄 `reset.sh`

**Purpose:** Complete stack reset and cleanup

- Stops all running containers
- Cleans up Docker volumes and networks
- Resets database to initial state
- Clears persistent storage and logs (`volumes/db/data`, `volumes/storage`, `volumes/n8n`)
- Provides fresh startup environment
- Includes safety prompts and confirmation
- `--clear-ollama` also removes the Ollama models volume (otherwise Ollama models are preserved)

**Usage:**

```bash
./scripts/reset.sh [options]
./scripts/reset.sh --clear-ollama   # nuke Ollama models too
```

### 🧪 n8n template, builder, and Ollama tests

#### `test-n8n-templates.sh`

**Purpose:** End-to-end import + shape check for seeded n8n workflows.

- Confirms `n8n-import` wrote the seed marker.
- Asserts all 7 workflows are present in the n8n DB (3 user-facing templates + 4 builder helpers).
- Verifies the workflows listed in `workflow-ids.activate` are active.
- Asserts the NodeBot Builder agent JSON has exactly 4 `toolWorkflow` nodes wired to the helper IDs.
- Hits `POST /webhook/template-supabase-health` and asserts the response shape.
- Runs as part of `npm test`.

#### `test-n8n-builder-agent.sh`

**Purpose:** Confirm NodeBot Builder is ready to chat.

- Reads `N8N_MCP_ACCESS_TOKEN` from `.env`; if missing, falls back to `n8n.user_api_keys` in Postgres.
- Posts `tools/list` to `http://localhost:5678/mcp-server/http` with that token and asserts a 200 response that includes `create_workflow_from_code`.
- Asserts the NodeBot Builder workflow (`d4e5f6a7b8c9012345678901234abcd`) is active in `n8n.workflow_entity`.
- Asserts the `N8NMcpBearer001` credential exists in `n8n.credentials_entity` and is shared.
- Exits 0 with a warning (not failure) if no MCP token exists yet — run `npm run setup` after creating the first n8n owner.

#### `test-ollama-integration.sh`

**Purpose:** Real LLM round-trip.

1. Checks Ollama is reachable at `OLLAMA_HOST_URL` (defaults to `http://localhost:11434`).
2. Ensures `OLLAMA_MODEL` is present locally (pulls if missing).
3. Calls Ollama `/api/chat` directly with a real prompt and asserts a non-empty response.
4. Verifies the `n8n` container can reach Ollama from inside Docker.
5. Drives the seeded Local Ollama Chat template via its public webhook and asserts the streamed output is non-empty.

Fails fast if Ollama isn't reachable — start Ollama first, or use the `--cpu` / `--gpu-*` profiles.

## When to Run These Scripts

### During Development

- **After starting the stack:** Run `health-check.sh` to verify everything is up
- **After database changes:** Run `test-database-integration.sh` to verify DB integrity
- **Before committing changes:** Run both scripts to ensure no regressions
- **n8n workflows:** All data persists automatically in Supabase database ✨

### Troubleshooting

- **Services not responding:** Use `health-check.sh` to identify which services are failing
- **Database issues:** Use `test-database-integration.sh` to pinpoint DB problems
- **After stack restart:** Run both scripts to verify full functionality

### Production/Staging

- **After deployment:** Run both scripts to verify successful deployment
- **Regular monitoring:** Schedule `health-check.sh` to run periodically
- **Before maintenance:** Run scripts to establish baseline health

### n8n Workflow Management

- **All workflows and credentials persist in Supabase database** - No backups needed! ✨
- **Initial setup:** Uses `n8n/demo-data/` for seeding workflows on first run
- **Reset to defaults:** Use `./reset.sh` to restore initial demo-data state
- **After git pull/merge:** If demo-data changed, restart stack to import new workflows

## Script Features

Both scripts include:

- ✅ **Beautiful colored output** for easy reading and quick status identification
- 🎯 **Smart status detection** - different colors for success, warnings, errors, and info
- ⚡ **Fast execution** with efficient testing
- 🛑 **Fail-fast behavior** - stops on first critical error
- 📊 **Detailed reporting** of test results with clear explanations
- 🔄 **Idempotency testing** where applicable
- 🕐 **Timestamps** for tracking when tests were run

### Color Coding System

- **🟢 Green (✅):** Successful tests, healthy services, expected results
- **🔵 Blue (ℹ️):** Informational messages, running services without health checks
- **🟡 Yellow (⚠️):** Warnings, services that may be initializing, non-critical issues
- **🔴 Red (❌):** Errors, failed tests, critical issues requiring attention

## Extending the Scripts

To add new tests:

1. Follow the existing pattern of numbered tests
2. Use the `print_status` function for consistent colored output:
   - `print_status "success" "Message"` for green checkmarks
   - `print_status "error" "Message"` for red X marks
   - `print_status "warning" "Message"` for yellow warnings
   - `print_status "info" "Message"` for blue information
3. Include both success and failure cases
4. Add meaningful error messages with expected vs actual results
5. Update this README with new functionality

## Exit Codes

- **0:** All tests passed successfully
- **1:** Critical failure (service down, database issue, etc.)

## Example Output

```bash
🔍 Docker Stack Health Check
==============================
🕐 Sun Jun 29 09:44:45 CDT 2025

✅ Environment variables loaded

ℹ️ Checking Docker services...
✅ All services running (14/14)

ℹ️ Service Health Status:

✅ realtime: Up 16 minutes (healthy)
✅ analytics: Up 16 minutes (healthy)
ℹ️ n8n: Up 16 minutes
✅ auth: Up 16 minutes (healthy)

ℹ️ Testing Endpoint Connectivity...

✅ Kong API Gateway (8000): 401 (auth required - expected)
✅ n8n Web Interface (5678): 200
✅ Analytics Service (4000): 200

# ... more tests ...

✅ 🎉 All services are healthy and authentication is working correctly!
🕐 Health check completed at: Sun Jun 29 09:44:45 CDT 2025
```
