# Project Utility Scripts

This directory contains utility scripts for managing and testing the Supabase project stack.

## Available Scripts

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

## When to Run These Scripts

### During Development

- **After starting the stack:** Run `health-check.sh` to verify everything is up
- **After database changes:** Run `test-database-integration.sh` to verify DB integrity
- **Before committing changes:** Run both scripts to ensure no regressions

### Troubleshooting

- **Services not responding:** Use `health-check.sh` to identify which services are failing
- **Database issues:** Use `test-database-integration.sh` to pinpoint DB problems
- **After stack restart:** Run both scripts to verify full functionality

### Production/Staging

- **After deployment:** Run both scripts to verify successful deployment
- **Regular monitoring:** Schedule `health-check.sh` to run periodically
- **Before maintenance:** Run scripts to establish baseline health

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
