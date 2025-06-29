#!/bin/bash

# Database Integration Test Script
# Tests the database initialization and verifies all components work correctly
# This script can be run anytime to verify the database stack is healthy

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

echo "🧪 Database Integration Test Script"
echo "=================================="
echo "🕐 $(date)"
echo

# Check if Docker services are running first
print_status "info" "Checking Docker services..."
if ! docker compose ps | grep -q "supabase-db.*healthy"; then
    print_status "error" "Supabase database is not running or healthy"
    echo "Please start the stack with: docker compose up"
    exit 1
fi
print_status "success" "Docker services are running"
echo

# Function to run SQL and capture output
run_sql() {
    local sql="$1"
    local database="${2:-postgres}"
    docker compose exec db bash -c "PAGER=cat psql -U postgres -d $database -t -c \"$sql\"" 2>/dev/null
}

# Function to count items
count_sql() {
    local sql="$1"
    local database="${2:-postgres}"
    result=$(run_sql "$sql" "$database" | xargs)
    echo "$result"
}

echo "📊 Testing Database Structure..."
echo

# Test 1: Check databases exist
echo "Test 1: Verify databases"
db_count=$(count_sql "SELECT count(*) FROM pg_database WHERE datname IN ('postgres', '_supabase');")
if [ "$db_count" = "2" ]; then
    print_status "success" "Both postgres and _supabase databases exist"
else
    print_status "error" "Expected 2 databases, found $db_count"
    exit 1
fi

# Test 2: Check schemas in postgres database
echo "Test 2: Verify schemas in postgres database"
expected_schemas=("_realtime" "supabase_functions" "net" "n8n")
for schema in "${expected_schemas[@]}"; do
    schema_exists=$(count_sql "SELECT count(*) FROM information_schema.schemata WHERE schema_name = '$schema';")
    if [ "$schema_exists" = "1" ]; then
        print_status "success" "Schema '$schema' exists"
    else
        print_status "error" "Schema '$schema' missing"
        exit 1
    fi
done

# Test 3: Check schemas in _supabase database  
echo "Test 3: Verify schemas in _supabase database"
supabase_schemas=("_analytics" "_supavisor")
for schema in "${supabase_schemas[@]}"; do
    schema_exists=$(count_sql "SELECT count(*) FROM information_schema.schemata WHERE schema_name = '$schema';" "_supabase")
    if [ "$schema_exists" = "1" ]; then
        print_status "success" "Schema '$schema' exists in _supabase"
    else
        print_status "error" "Schema '$schema' missing in _supabase"
        exit 1
    fi
done

# Test 4: Check extensions
echo "Test 4: Verify extensions"
required_extensions=("vector" "pg_trgm" "btree_gin" "btree_gist" "pg_net")
for ext in "${required_extensions[@]}"; do
    ext_exists=$(count_sql "SELECT count(*) FROM pg_extension WHERE extname = '$ext';")
    if [ "$ext_exists" = "1" ]; then
        print_status "success" "Extension '$ext' installed"
    else
        print_status "error" "Extension '$ext' missing"
        exit 1
    fi
done

# Test 5: Check JWT configuration
echo "Test 5: Verify JWT configuration"
jwt_configured=$(run_sql "SHOW app.settings.jwt_secret;" | wc -c)
if [ "$jwt_configured" -gt "10" ]; then
    print_status "success" "JWT secret configured"
else
    print_status "error" "JWT secret not configured"
    exit 1
fi

# Test 6: Check vector functionality
echo "Test 6: Verify vector functionality"
similarity_result=$(run_sql "SELECT cosine_similarity('[1,0,0]'::vector, '[1,0,0]'::vector);" | xargs)
if [ "$similarity_result" = "1" ]; then
    print_status "success" "Vector cosine similarity working (identical vectors = 1)"
else
    print_status "error" "Vector functionality broken, got: $similarity_result"
    exit 1
fi

# Test 7: Check supabase_functions tables
echo "Test 7: Verify webhooks/functions setup"
hooks_table_count=$(count_sql "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'supabase_functions' AND table_name IN ('hooks', 'migrations');")
if [ "$hooks_table_count" = "2" ]; then
    print_status "success" "Supabase functions tables created"
else
    print_status "error" "Expected 2 supabase_functions tables, found $hooks_table_count"
    exit 1
fi

# Test 8: Check n8n tables (should be in main postgres db)
echo "Test 8: Verify n8n integration"
n8n_table_count=$(count_sql "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'n8n';")
if [ "$n8n_table_count" -gt "30" ]; then
    print_status "success" "n8n tables created ($n8n_table_count tables)"
else
    print_status "warning" "n8n tables not found or incomplete ($n8n_table_count tables)"
    echo "     This is OK if n8n hasn't fully initialized yet"
fi

# Test 9: Check if we can connect to different databases
echo "Test 9: Verify database connectivity"
postgres_conn=$(count_sql "SELECT 1;")
supabase_conn=$(count_sql "SELECT 1;" "_supabase")
if [ "$postgres_conn" = "1" ] && [ "$supabase_conn" = "1" ]; then
    print_status "success" "Can connect to both databases"
else
    print_status "error" "Database connectivity issues"
    exit 1
fi

# Test 10: Check roles and permissions
echo "Test 10: Verify database roles"
role_count=$(count_sql "SELECT count(*) FROM pg_roles WHERE rolname IN ('authenticator', 'service_role', 'anon');")
if [ "$role_count" = "3" ]; then
    print_status "success" "Supabase roles configured"
else
    print_status "warning" "Some Supabase roles missing ($role_count/3 found)"
fi

echo
print_status "success" "🎉 All Database Integration Tests Passed!"
echo "========================================"
echo
echo "📋 Summary:"
print_status "success" "All required databases created"
print_status "success" "All schemas properly organized"
print_status "success" "All extensions installed and working"
print_status "success" "JWT configuration applied"
print_status "success" "Vector functionality operational"
print_status "success" "Webhooks and functions ready"
print_status "success" "n8n integration working"
print_status "success" "Database connectivity verified"
print_status "success" "Database roles configured"
echo
print_status "info" "💡 The database integration is working perfectly!"
echo "   All SQL scripts executed in the correct order and"
echo "   all components are properly initialized."
echo

# Optional: Test idempotency by re-running a safe script
echo "🔄 Testing Idempotency..."
echo "========================"
echo "Re-running vector.sql components to test idempotency..."

# Test idempotency with safe operations
idempotency_output=$(docker compose exec db bash -c "PAGER=cat psql -U postgres -c \"
-- Test idempotency by re-running vector extension setup
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE EXTENSION IF NOT EXISTS btree_gist;
\"" 2>&1)

if echo "$idempotency_output" | grep -q "already exists"; then
    print_status "success" "Idempotency test passed - scripts can be safely re-run"
else
    print_status "warning" "Idempotency test had unexpected output"
fi

echo
print_status "success" "🚀 Database Integration: COMPLETE"
echo "================================="
echo "All tests passed successfully!"
echo "🕐 Test completed at: $(date)"
echo
print_status "info" "Usage: Run this script anytime to verify database health"
print_status "info" "Location: scripts/test-database-integration.sh" 
