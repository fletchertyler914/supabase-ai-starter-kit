#!/bin/bash

# Health check script for Supabase + n8n Docker stack
# Tests all major services and their connectivity with proper authentication

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_status() {
    case $1 in
        "error") echo -e "${RED}❌ $2${NC}" ;;
        "success") echo -e "${GREEN}✅ $2${NC}" ;;
        "warning") echo -e "${YELLOW}⚠️ $2${NC}" ;;
        "info") echo -e "${BLUE}ℹ️ $2${NC}" ;;
        *) echo "$2" ;;
    esac
}

echo "🔍 Docker Stack Health Check"
echo "=============================="
echo "🕐 $(date)"
echo

# Load environment variables
if [ -f .env ]; then
    # Load environment variables while avoiding issues with comments
    while IFS= read -r line; do
        # Skip empty lines and comments
        if [[ "$line" =~ ^[[:space:]]*$ ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        # Export valid variable assignments
        if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
            export "$line"
        fi
    done < .env
    print_status "success" "Environment variables loaded"
else
    print_status "error" ".env file not found"
    exit 1
fi
echo

# Check if Docker Compose is running
print_status "info" "Checking Docker services..."
RUNNING_SERVICES=$(docker compose ps --services --filter "status=running" | wc -l)
TOTAL_SERVICES=$(docker compose ps --services | wc -l)

if [ "$RUNNING_SERVICES" -eq "$TOTAL_SERVICES" ]; then
    print_status "success" "All services running ($RUNNING_SERVICES/$TOTAL_SERVICES)"
else
    print_status "warning" "Some services not running ($RUNNING_SERVICES/$TOTAL_SERVICES)"
fi
echo

# Check specific service health
print_status "info" "Service Health Status:"
echo
# Get the service status and format it properly - handle variable spacing
docker compose ps --format "{{.Service}}|{{.Status}}" | while IFS='|' read -r service status; do
    if [[ "$status" == *"healthy"* ]]; then
        print_status "success" "$service: $status"
    elif [[ "$status" == *"Up"* ]] && [[ "$status" != *"healthy"* ]]; then
        print_status "info" "$service: $status"
    elif [[ "$status" == *"running"* ]]; then
        print_status "info" "$service: $status"
    else
        print_status "warning" "$service: $status"
    fi
done
echo

# Test main endpoints
print_status "info" "Testing Endpoint Connectivity..."
echo

# Supabase API Gateway
KONG_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health)
if [ "$KONG_STATUS" = "401" ]; then
    print_status "success" "Kong API Gateway (8000): $KONG_STATUS (auth required - expected)"
else
    print_status "warning" "Kong API Gateway (8000): $KONG_STATUS (expected 401)"
fi

# n8n Web Interface  
N8N_WEB=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5678)
if [ "$N8N_WEB" = "200" ]; then
    print_status "success" "n8n Web Interface (5678): $N8N_WEB"
else
    print_status "error" "n8n Web Interface (5678): $N8N_WEB (expected 200)"
fi

# Analytics Service
ANALYTICS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4000/health)  
if [ "$ANALYTICS_STATUS" = "200" ]; then
    print_status "success" "Analytics Service (4000): $ANALYTICS_STATUS"
else
    print_status "error" "Analytics Service (4000): $ANALYTICS_STATUS (expected 200)"
fi
echo

# Enhanced Authentication Tests
print_status "info" "Testing Authentication & API Access..."
echo

# Auth health endpoint with anonymous key
AUTH_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "apikey: $ANON_KEY" \
  http://localhost:8000/auth/v1/health)
if [ "$AUTH_HEALTH" = "200" ]; then
    print_status "success" "Auth Health (anon): $AUTH_HEALTH"
else
    print_status "error" "Auth Health (anon): $AUTH_HEALTH (expected 200)"
fi

# Get auth user (should return 403 if no user session)
AUTH_USER=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "apikey: $ANON_KEY" \
  http://localhost:8000/auth/v1/user)
if [ "$AUTH_USER" = "403" ]; then
    print_status "success" "Auth User Endpoint (anon): $AUTH_USER (no active session - expected)"
else
    print_status "warning" "Auth User Endpoint (anon): $AUTH_USER (expected 403)"
fi

# Test REST API with anonymous key
REST_ANON=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "apikey: $ANON_KEY" \
  http://localhost:8000/rest/v1/)
if [ "$REST_ANON" = "200" ]; then
    print_status "success" "REST API (anon): $REST_ANON"
else
    print_status "error" "REST API (anon): $REST_ANON (expected 200)"
fi

# Test REST API with service role key (should have full access)
REST_SERVICE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "apikey: $SERVICE_ROLE_KEY" \
  http://localhost:8000/rest/v1/)
if [ "$REST_SERVICE" = "200" ]; then
    print_status "success" "REST API (service_role): $REST_SERVICE"
else
    print_status "error" "REST API (service_role): $REST_SERVICE (expected 200)"
fi

# Test specific REST endpoint - list tables with service role
TABLES_TEST=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "apikey: $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  http://localhost:8000/rest/v1/)
if [ "$TABLES_TEST" = "200" ]; then
    print_status "success" "REST Tables Access (service_role): $TABLES_TEST"
else
    print_status "error" "REST Tables Access (service_role): $TABLES_TEST (expected 200)"
fi

# Test Realtime service via container health (HTTP endpoint not externally accessible)
REALTIME_CONTAINER_STATUS=$(docker inspect realtime-dev.supabase-realtime --format '{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
if [ "$REALTIME_CONTAINER_STATUS" = "healthy" ]; then
    print_status "success" "Realtime Service: $REALTIME_CONTAINER_STATUS"
else
    print_status "error" "Realtime Service: $REALTIME_CONTAINER_STATUS (expected healthy)"
fi

# Test Storage API
STORAGE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "apikey: $ANON_KEY" \
  http://localhost:8000/storage/v1/bucket)
if [ "$STORAGE_STATUS" = "200" ]; then
    print_status "success" "Storage API (list buckets): $STORAGE_STATUS"
else
    print_status "error" "Storage API (list buckets): $STORAGE_STATUS (expected 200)"
fi

# Test Edge Functions
FUNCTIONS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "apikey: $ANON_KEY" \
  http://localhost:8000/functions/v1/hello)
if [ "$FUNCTIONS_STATUS" = "200" ] || [ "$FUNCTIONS_STATUS" = "404" ]; then
    print_status "success" "Edge Functions (hello): $FUNCTIONS_STATUS (functions accessible)"
else
    print_status "warning" "Edge Functions (hello): $FUNCTIONS_STATUS"
fi
echo

# Database connectivity test
print_status "info" "Testing Database Connectivity..."
echo
DB_VERSION=$(docker exec supabase-db psql -U postgres -t -c "SELECT version();" 2>/dev/null | head -1 | xargs)
if [ $? -eq 0 ]; then
    print_status "success" "Database: Connected"
    print_status "info" "   Version: $DB_VERSION"
else
    print_status "error" "Database: Connection failed"
fi

# Test database via REST API with a working RPC function
DB_VIA_API=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "apikey: $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -X POST \
  http://localhost:8000/rest/v1/rpc/show_limit)
if [ "$DB_VIA_API" = "200" ] || [ "$DB_VIA_API" = "404" ]; then
    print_status "success" "Database RPC via API: $DB_VIA_API (database accessible)"
else
    print_status "warning" "Database RPC via API: $DB_VIA_API"
fi

# Check n8n database schema
N8N_TABLES=$(docker exec supabase-db psql -U postgres -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'n8n';" 2>/dev/null | xargs)
if [ "$N8N_TABLES" -gt 0 ]; then
    print_status "success" "n8n schema: $N8N_TABLES tables found"
else
    print_status "warning" "n8n schema: No tables found (may still be initializing)"
fi
echo

# Test n8n Web Interface Accessibility
print_status "info" "Testing n8n Service..."
echo
if [ $N8N_WEB -eq 200 ]; then
    print_status "success" "n8n is ready and accessible"
else
    print_status "warning" "n8n may still be initializing (this is normal on first startup)"
fi

# Overall health summary
print_status "info" "System Health Summary..."
echo
HEALTHY_COUNT=$(docker compose ps | grep -c "healthy")
print_status "info" "Healthy services: $HEALTHY_COUNT"

# Check startup time by looking at container creation time
OLDEST_CONTAINER=$(docker ps --format "{{.CreatedAt}}" | sort | head -1)
print_status "info" "Stack started: $OLDEST_CONTAINER"
echo

# Authentication Test Results Summary
echo "📋 Authentication Test Results:"
echo "================================"
if [ "$AUTH_HEALTH" = "200" ]; then
    print_status "success" "Auth Health: $AUTH_HEALTH"
else
    print_status "error" "Auth Health: $AUTH_HEALTH (expected 200)"
fi

if [ "$REST_ANON" = "200" ]; then
    print_status "success" "REST API (anon): $REST_ANON"
else
    print_status "error" "REST API (anon): $REST_ANON (expected 200)"
fi

if [ "$REST_SERVICE" = "200" ]; then
    print_status "success" "REST API (service): $REST_SERVICE"
else
    print_status "error" "REST API (service): $REST_SERVICE (expected 200)"
fi

if [ "$REALTIME_CONTAINER_STATUS" = "healthy" ]; then
    print_status "success" "Realtime: $REALTIME_CONTAINER_STATUS"
else
    print_status "error" "Realtime: $REALTIME_CONTAINER_STATUS (expected healthy)"
fi

if [ "$STORAGE_STATUS" = "200" ]; then
    print_status "success" "Storage: $STORAGE_STATUS"
else
    print_status "error" "Storage: $STORAGE_STATUS (expected 200)"
fi
echo

# Enhanced success criteria
if [ $N8N_WEB -eq 200 ] && [ $ANALYTICS_STATUS -eq 200 ] && [ $AUTH_HEALTH -eq 200 ] && [ $REST_ANON -eq 200 ] && [ $REST_SERVICE -eq 200 ] && [ $REALTIME_CONTAINER_STATUS == "healthy" ] && [ $STORAGE_STATUS -eq 200 ]; then
    print_status "success" "🎉 All services are healthy and authentication is working correctly!"
    echo "🕐 Health check completed at: $(date)"
    exit 0
else
    print_status "error" "⚠️ Some services may have issues. Check the status above."
    print_status "info" "Expected: n8n_web=200, analytics=200, auth_health=200, rest_anon=200, rest_service=200, realtime=healthy, storage=200"
    echo "🕐 Health check completed at: $(date)"
    exit 1
fi 
