#!/bin/bash

# Parse command line arguments
CLEAR_OLLAMA=false
DEV_EMAIL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --clear-ollama)
            CLEAR_OLLAMA=true
            shift
            ;;
        --dev-email)
            DEV_EMAIL=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Reset the Supabase AI Starter Kit to a clean state."
            echo ""
            echo "Options:"
            echo "  --clear-ollama    Also remove Ollama models and volumes (default: preserve)"
            echo "  --dev-email       Include email server containers in cleanup"
            echo "  -h, --help        Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                              # Standard reset (keep Ollama models)"
            echo "  $0 --clear-ollama               # Nuclear option (remove everything)"
            echo "  $0 --dev-email                  # Include email server cleanup"
            echo "  $0 --clear-ollama --dev-email   # Full cleanup including email server"
            echo ""
            echo "Note: This will stop and remove ALL containers from the project,"
            echo "      regardless of which GPU/CPU profile was used to start them."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

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
    echo "║                            🚨 SUPABASE AI STARTER KIT RESET 🚨                       ║"
    echo "╚════════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_warning() {
    echo -e "${RED}⚠️  WARNING: This will remove containers, volumes, and data!${NC}"
    echo -e "${RED}   • All Docker containers will be stopped and removed${NC}"
    if [ "$CLEAR_OLLAMA" = true ]; then
        echo -e "${RED}   • All volumes INCLUDING Ollama models will be deleted${NC}"
    else
        echo -e "${YELLOW}   • Database volumes will be deleted (Ollama models preserved)${NC}"
    fi
    echo -e "${RED}   • All bind-mounted data directories will be cleared${NC}"
    echo -e "${RED}   • The .env file will be reset to defaults${NC}"
    echo ""
    if [ "$CLEAR_OLLAMA" = true ]; then
        echo -e "${YELLOW}   This action CANNOT be undone!${NC}"
    else
        echo -e "${YELLOW}   Note: Ollama models will be preserved (use --clear-ollama to remove)${NC}"
    fi
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

# Build compose file arguments
COMPOSE_FILES="-f docker-compose.yml -f docker/docker-compose.dev.yml"
if [ "$DEV_EMAIL" = true ]; then
    COMPOSE_FILES="$COMPOSE_FILES -f docker/docker-compose.email.yml"
fi

print_step "Stopping and removing Docker Compose services..."
if [ "$CLEAR_OLLAMA" = true ]; then
    # Remove all volumes including Ollama
    if docker compose $COMPOSE_FILES down -v --remove-orphans >/dev/null 2>&1; then
        print_success "Docker Compose services and all volumes removed"
    else
        print_error "Failed to remove some Docker Compose services"
    fi
else
    # Remove containers but preserve volumes (we'll selectively remove non-Ollama volumes later)
    if docker compose $COMPOSE_FILES down --remove-orphans >/dev/null 2>&1; then
        print_success "Docker Compose services removed (volumes preserved)"
    else
        print_error "Failed to remove some Docker Compose services"
    fi
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

if [ "$CLEAR_OLLAMA" = true ]; then
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
else
    print_step "Preserving Ollama volumes, removing other project volumes..."
    # Get all project volumes but exclude Ollama ones
    PROJECT_VOLUMES=$(docker volume ls -q | grep -E "(supabase|postgres|n8n)" | grep -v ollama 2>/dev/null || true)
    if [ -n "$PROJECT_VOLUMES" ]; then
        if echo "$PROJECT_VOLUMES" | xargs docker volume rm >/dev/null 2>&1; then
            print_success "Project volumes removed (Ollama preserved): $(echo $PROJECT_VOLUMES | tr '\n' ' ')"
        else
            print_error "Failed to remove some project volumes"
        fi
    else
        print_skip "No project volumes found to remove"
    fi
    
    OLLAMA_VOLUMES=$(docker volume ls -q | grep ollama 2>/dev/null || true)
    if [ -n "$OLLAMA_VOLUMES" ]; then
        print_success "Ollama volumes preserved: $(echo $OLLAMA_VOLUMES | tr '\n' ' ')"
    else
        print_skip "No Ollama volumes found"
    fi
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
echo "║  Your Supabase AI Starter Kit has been reset to a clean state.                       ║"
echo "║                                                                                ║"
echo "║  Next steps:                                                                   ║"
echo "║  • Run: docker compose --profile cpu up                                       ║"
echo "║  • Your environment will start fresh with default settings                    ║"
if [ "$CLEAR_OLLAMA" = true ]; then
echo "║  • New Ollama models will be downloaded based on your .env configuration      ║"
else
echo "║  • Existing Ollama models are preserved and ready to use                      ║"
fi
echo "╚════════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
