#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "${PURPLE}"
    echo "╔════════════════════════════════════════════════════════════════════════════════╗"
    echo "║                            🚨 SUPABASE PROJECT RESET 🚨                       ║"
    echo "╚════════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_warning() {
    echo -e "${RED}⚠️  WARNING: This will remove all containers, volumes, and data!${NC}"
    echo -e "${RED}   • All Docker containers will be stopped and removed${NC}"
    echo -e "${RED}   • All volumes including Ollama models will be deleted${NC}"
    echo -e "${RED}   • All bind-mounted data directories will be cleared${NC}"
    echo -e "${RED}   • The .env file will be reset to defaults${NC}"
    echo ""
    echo -e "${YELLOW}   This action CANNOT be undone!${NC}"
    echo ""
}

print_section() {
    echo -e "${CYAN}┌──────────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│ $1${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────────────────┘${NC}"
}

print_step() {
    echo -e "${BLUE}  🔸 $1${NC}"
}

print_success() {
    echo -e "${GREEN}  ✅ $1${NC}"
}

print_skip() {
    echo -e "${GRAY}  ⏭️  $1${NC}"
}

print_error() {
    echo -e "${RED}  ❌ $1${NC}"
}

# Main script
clear
print_header
print_warning

# Confirmation prompt
echo -e "${YELLOW}Are you sure you want to proceed? ${WHITE}(y/N)${NC} "
read -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${GREEN}✨ Operation cancelled. Your data is safe!${NC}"
    echo ""
    exit 0
fi

echo ""
echo -e "${WHITE}🚀 Starting cleanup process...${NC}"
echo ""

# Step 1: Container cleanup
print_section "🐳 CONTAINER CLEANUP"
print_step "Stopping and removing Docker Compose services..."
if docker compose -f docker-compose.yml -f ./dev/docker-compose.dev.yml down -v --remove-orphans >/dev/null 2>&1; then
    print_success "Docker Compose services removed"
else
    print_error "Failed to remove some Docker Compose services"
fi

print_step "Cleaning up remaining Ollama containers..."
if docker stop $(docker ps -aq --filter "name=ollama") >/dev/null 2>&1; then
    print_success "Ollama containers stopped"
else
    print_skip "No Ollama containers to stop"
fi

if docker rm $(docker ps -aq --filter "name=ollama") >/dev/null 2>&1; then
    print_success "Ollama containers removed"
else
    print_skip "No Ollama containers to remove"
fi

print_step "Pruning stopped containers..."
if docker container prune -f >/dev/null 2>&1; then
    print_success "Stopped containers pruned"
else
    print_skip "No stopped containers to prune"
fi

echo ""

# Step 2: Volume cleanup
print_section "💾 VOLUME CLEANUP"
print_step "Removing Ollama models and data volumes..."
OLLAMA_VOLUMES=$(docker volume ls -q | grep ollama 2>/dev/null || true)
if [ -n "$OLLAMA_VOLUMES" ]; then
    if echo "$OLLAMA_VOLUMES" | xargs docker volume rm >/dev/null 2>&1; then
        print_success "Ollama volumes removed: $(echo $OLLAMA_VOLUMES | tr '\n' ' ')"
    else
        print_error "Failed to remove some Ollama volumes"
    fi
else
    print_skip "No Ollama volumes found"
fi

echo ""

# Step 3: Directory cleanup
print_section "📁 DIRECTORY CLEANUP"
BIND_MOUNTS=(
    "./volumes/db/data"
)

for DIR in "${BIND_MOUNTS[@]}"; do
    if [ -d "$DIR" ]; then
        print_step "Removing bind-mounted directory: $DIR"
        if rm -rf "$DIR" 2>/dev/null; then
            print_success "Directory removed: $DIR"
        else
            print_error "Failed to remove directory: $DIR"
        fi
    else
        print_skip "Directory not found: $DIR"
    fi
done

echo ""

# Step 4: Environment reset
print_section "⚙️  ENVIRONMENT RESET"
if [ -f ".env" ]; then
    print_step "Removing existing .env file..."
    if rm -f .env 2>/dev/null; then
        print_success "Existing .env file removed"
    else
        print_error "Failed to remove .env file"
    fi
else
    print_skip "No existing .env file found"
fi

if [ -f ".env.example" ]; then
    print_step "Copying .env.example to .env..."
    if cp .env.example .env 2>/dev/null; then
        print_success "Environment reset from .env.example"
    else
        print_error "Failed to copy .env.example"
    fi
else
    print_error ".env.example file not found!"
fi

echo ""

# Completion
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════════════════════════╗"
echo "║                              🎉 CLEANUP COMPLETE! 🎉                           ║"
echo "╠════════════════════════════════════════════════════════════════════════════════╣"
echo "║  Your Supabase project has been completely reset to a clean state.            ║"
echo "║                                                                                ║"
echo "║  Next steps:                                                                   ║"
echo "║  • Run: docker compose --profile cpu up                                       ║"
echo "║  • Your environment will start fresh with default settings                    ║"
echo "║  • New Ollama models will be downloaded based on your .env configuration      ║"
echo "╚════════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
