#!/bin/bash

# Parse command line arguments
DEV_EMAIL=false
DETACHED=false
PROFILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --dev-email)
            DEV_EMAIL=true
            shift
            ;;
        -d|--detach)
            DETACHED=true
            shift
            ;;
        --cpu)
            PROFILE="cpu"
            shift
            ;;
        --gpu-nvidia)
            PROFILE="gpu-nvidia"
            shift
            ;;
        --gpu-amd)
            PROFILE="gpu-amd"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Start the Supabase AI Starter Kit services."
            echo ""
            echo "Options:"
            echo "  --dev-email       Include the development email server (inbucket)"
            echo "  --cpu             Start containerized CPU-only Ollama"
            echo "  --gpu-nvidia      Start containerized NVIDIA GPU Ollama"
            echo "  --gpu-amd         Start containerized AMD GPU Ollama"
            echo "  -d, --detach      Run in detached mode (background)"
            echo "  -h, --help        Show this help message"
            echo ""
            echo "Note: Without GPU/CPU flags, expects Ollama running on host machine"
            echo ""
            echo "Examples:"
            echo "  # Ollama modes"
            echo "  $0                                    # Host machine Ollama (fastest for Mac/Apple Silicon)"
            echo "  $0 --cpu                              # Containerized CPU Ollama"
            echo "  $0 --gpu-nvidia                       # Containerized NVIDIA GPU Ollama"
            echo "  $0 --gpu-amd                          # Containerized AMD GPU Ollama"
            echo ""
            echo "  # With email server"
            echo "  $0 --dev-email                        # Host Ollama + email server"
            echo "  $0 --cpu --dev-email                  # CPU Ollama + email server"
            echo "  $0 --gpu-nvidia --dev-email           # NVIDIA GPU Ollama + email server"
            echo "  $0 --gpu-amd --dev-email              # AMD GPU Ollama + email server"
            echo ""
            echo "  # Background mode"
            echo "  $0 --detach                           # Host Ollama and run everything in background"
            echo "  $0 --gpu-nvidia --detach              # NVIDIA GPU Ollama in background"
            echo ""
            echo "  # Full combinations"
            echo "  $0 --gpu-nvidia --dev-email --detach  # NVIDIA + email + background"
            echo "  $0 --cpu --dev-email -d               # CPU + email + background (short flag)"
            echo ""
            echo "Access points:"
            echo "  • Supabase Studio: http://localhost:3000"
            echo "  • API Gateway: http://localhost:8000"
            if [ "$DEV_EMAIL" = true ]; then
                echo "  • Email Web UI: http://localhost:9000"
            fi
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Check for .env file and copy from .env.example if it doesn't exist
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        echo "📄 .env file not found, copying from .env.example..."
        if cp .env.example .env 2>/dev/null; then
            echo "✅ Environment file created from .env.example"
            echo "⚠️  Please review and update the .env file with your actual values before proceeding"
        else
            echo "❌ Failed to copy .env.example to .env"
            exit 1
        fi
    else
        echo "❌ .env.example file not found! Cannot create .env file."
        echo "   Please create a .env file with the required environment variables."
        exit 1
    fi
fi

# No default profile - if none specified, run without Ollama containers
# This expects Ollama to be running externally on the host

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}🚀 Starting Supabase AI Starter Kit...${NC}"

# Build compose file arguments
COMPOSE_FILES="-f docker-compose.yml"
if [ "$DEV_EMAIL" = true ]; then
    COMPOSE_FILES="$COMPOSE_FILES -f docker-compose.email.yml"
    echo -e "${BLUE}📧 Email server enabled${NC}"
fi

# Add profile selection if specified
if [ -n "$PROFILE" ]; then
    PROFILE_FLAG="--profile $PROFILE"
    case $PROFILE in
        cpu)
            echo -e "${BLUE}🖥️  Containerized CPU Ollama${NC}"
            ;;
        gpu-nvidia)
            echo -e "${GREEN}🚀 Containerized NVIDIA GPU Ollama${NC}"
            ;;
        gpu-amd)
            echo -e "${GREEN}🚀 Containerized AMD GPU Ollama${NC}"
            ;;
    esac
else
    PROFILE_FLAG=""
    echo -e "${YELLOW}📡 Using host machine Ollama (expects Ollama running on host)${NC}"
fi

# Build docker compose command
COMPOSE_CMD="docker compose $COMPOSE_FILES $PROFILE_FLAG up"
if [ "$DETACHED" = true ]; then
    COMPOSE_CMD="$COMPOSE_CMD -d"
fi

echo -e "${BLUE}Starting services...${NC}"
exec $COMPOSE_CMD 
