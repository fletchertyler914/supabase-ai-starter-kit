#!/bin/bash

# Health check script for Supabase + n8n Docker stack
# Tests all major services and their connectivity with proper authentication

echo "🔍 Docker Stack Health Check"
echo "=============================="

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
    echo "✅ Loaded environment variables"
else
    echo "❌ .env file not found"
    exit 1
fi

# Check if Docker Compose is running
echo ""
echo "📦 Checking Docker services..."
RUNNING_SERVICES=$(docker compose ps --services --filter "status=running" | wc -l)
TOTAL_SERVICES=$(docker compose ps --services | wc -l)
echo "Services running: $RUNNING_SERVICES/$TOTAL_SERVICES"

# Check specific service health
echo ""
echo "🏥 Service Health Status:"
docker compose ps --format "table {{.Service}}\t{{.Status}}" | grep -E "(healthy|running|Up)"

# Test main endpoints
echo ""
echo "🌐 Endpoint Connectivity Tests:"

# Supabase API Gateway
KONG_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health)
echo "Kong API Gateway (8000): $KONG_STATUS (401 expected - auth required)"

# n8n Web Interface  
N8N_WEB=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5678)
echo "n8n Web Interface (5678): $N8N_WEB"

# Analytics Service
ANALYTICS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:4000/health)  
echo "Analytics Service (4000): $ANALYTICS_STATUS"

# Enhanced Authentication Tests
echo ""
echo "🔐 Authentication & API Tests:"

# Auth health endpoint with anonymous key
AUTH_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "apikey: $ANON_KEY" \
  http://localhost:8000/auth/v1/health)
echo "Auth Health (anon): $AUTH_HEALTH"

# Get auth user (should return 403 if no user session)
AUTH_USER=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "apikey: $ANON_KEY" \
  http://localhost:8000/auth/v1/user)
echo "Auth User Endpoint (anon): $AUTH_USER (403 expected - no active session)"

# Test REST API with anonymous key
REST_ANON=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "apikey: $ANON_KEY" \
  http://localhost:8000/rest/v1/)
echo "REST API (anon): $REST_ANON"

# Test REST API with service role key (should have full access)
REST_SERVICE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "apikey: $SERVICE_ROLE_KEY" \
  http://localhost:8000/rest/v1/)
echo "REST API (service_role): $REST_SERVICE"

# Test specific REST endpoint - list tables with service role
TABLES_TEST=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "apikey: $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  http://localhost:8000/rest/v1/)
echo "REST Tables Access (service_role): $TABLES_TEST"

# Test Realtime service via container health (HTTP endpoint not externally accessible)
REALTIME_CONTAINER_STATUS=$(docker inspect realtime-dev.supabase-realtime --format '{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
echo "Realtime Service: $REALTIME_CONTAINER_STATUS"

# Test Storage API
STORAGE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "apikey: $ANON_KEY" \
  http://localhost:8000/storage/v1/bucket)
echo "Storage API (list buckets): $STORAGE_STATUS"

# Test Edge Functions
FUNCTIONS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "apikey: $ANON_KEY" \
  http://localhost:8000/functions/v1/hello)
echo "Edge Functions (hello): $FUNCTIONS_STATUS"

# Database connectivity test
echo ""
echo "🗄️  Database Connectivity:"
DB_VERSION=$(docker exec supabase-db psql -U postgres -t -c "SELECT version();" 2>/dev/null | head -1 | xargs)
if [ $? -eq 0 ]; then
    echo "✅ Database: Connected ($DB_VERSION)"
else
    echo "❌ Database: Connection failed"
fi

# Test database via REST API with a working RPC function
echo ""
echo "🗄️  Database API Tests:"
DB_VIA_API=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $SERVICE_ROLE_KEY" \
  -H "apikey: $SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -X POST \
  http://localhost:8000/rest/v1/rpc/show_limit)
echo "Database RPC via API: $DB_VIA_API"

# Check n8n database schema
echo ""
echo "🔧 n8n Database Setup:"
N8N_TABLES=$(docker exec supabase-db psql -U postgres -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'n8n';" 2>/dev/null | xargs)
if [ "$N8N_TABLES" -gt 0 ]; then
    echo "✅ n8n schema: $N8N_TABLES tables found"
else
    echo "❌ n8n schema: No tables found"
fi

# Test n8n Web Interface Accessibility
echo ""
echo "🤖 n8n Service Tests:"
N8N_WEB=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5678)
echo "n8n Web Interface (5678): $N8N_WEB"

# Check if n8n is ready (may take a moment to fully initialize)
if [ $N8N_WEB -eq 200 ]; then
    echo "✅ n8n is ready and accessible"
else
    echo "⏳ n8n may still be initializing (this is normal on first startup)"
fi

# Overall health summary
echo ""
echo "📊 Health Summary:"
HEALTHY_COUNT=$(docker compose ps | grep -c "healthy")
echo "Healthy services: $HEALTHY_COUNT"

# Check startup time by looking at container creation time
OLDEST_CONTAINER=$(docker ps --format "{{.CreatedAt}}" | sort | head -1)
echo "Stack started: $OLDEST_CONTAINER"

echo ""
echo "🔍 Authentication Test Results Summary:"
echo "- Auth Health: $AUTH_HEALTH (200 expected)"
echo "- REST API (anon): $REST_ANON (200 expected)"  
echo "- REST API (service): $REST_SERVICE (200 expected)"
echo "- Realtime: $REALTIME_CONTAINER_STATUS (expected healthy)"
echo "- Storage: $STORAGE_STATUS (200 expected)"

# Enhanced success criteria
if [ $N8N_WEB -eq 200 ] && [ $ANALYTICS_STATUS -eq 200 ] && [ $AUTH_HEALTH -eq 200 ] && [ $REST_ANON -eq 200 ] && [ $REST_SERVICE -eq 200 ] && [ $REALTIME_CONTAINER_STATUS == "healthy" ] && [ $STORAGE_STATUS -eq 200 ] && [ $DB_VIA_API -eq 200 ]; then
    echo ""
    echo "🎉 All services are healthy and authentication is working correctly!"
    exit 0
else
    echo ""
    echo "⚠️  Some services may have issues. Check the status above."
    echo "Expected: n8n_web=200, analytics=200, auth_health=200, rest_anon=200, rest_service=200, realtime=healthy, storage=200, db_rpc=200"
    exit 1
fi 
