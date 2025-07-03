#!/bin/bash

# Supabase AI Starter Kit - Taskmaster Setup Script
# Automatically sets up AI-powered project planning for your use case

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in a valid project directory
check_project_directory() {
    if [[ ! -f "docker-compose.yml" ]] || [[ ! -d "volumes" ]]; then
        log_error "This doesn't appear to be a Supabase AI Starter Kit directory"
        log_info "Please run this script from the root of your cloned starter kit"
        exit 1
    fi
}

# Check if Taskmaster is available
check_taskmaster() {
    if ! command -v task-master &> /dev/null && ! command -v npx &> /dev/null; then
        log_error "Neither 'task-master' nor 'npx' is available"
        log_info "Please install Node.js and npm first: https://nodejs.org/"
        exit 1
    fi
    
    # Prefer global task-master, fall back to npx
    if command -v task-master &> /dev/null; then
        TASKMASTER_CMD="task-master"
        log_info "Using global task-master installation"
    else
        TASKMASTER_CMD="npx task-master-ai"
        log_info "Using npx to run task-master-ai"
    fi
}

# Initialize Taskmaster if not already done
init_taskmaster() {
    if [[ -d ".taskmaster" ]] && [[ -f ".taskmaster/tasks/tasks.json" ]]; then
        log_info "Taskmaster already initialized"
        return 0
    fi
    
    log_info "Initializing Taskmaster for AI-powered project planning..."
    
    # Initialize with cursor rules for AI assistance
    $TASKMASTER_CMD init \
        --rules cursor \
        --name "AI Application" \
        --description "AI application built on Supabase AI Starter Kit" \
        --version "0.1.0" \
        --yes
    
    log_success "Taskmaster initialized successfully!"
}

# Look for existing PRD files
find_prd_files() {
    local prd_files=()
    
    # Common PRD file locations and names
    local search_patterns=(
        "prd.txt"
        "prd.md"
        "requirements.txt"
        "requirements.md"
        "product-requirements.txt"
        "product-requirements.md"
        ".taskmaster/docs/prd.txt"
        ".taskmaster/docs/prd.md"
        "docs/prd.txt"
        "docs/prd.md"
        "docs/requirements.txt"
        "docs/requirements.md"
    )
    
    for pattern in "${search_patterns[@]}"; do
        if [[ -f "$pattern" ]]; then
            prd_files+=("$pattern")
        fi
    done
    
    echo "${prd_files[@]}"
}

# Interactive PRD selection
select_prd_file() {
    local prd_files=($1)
    
    if [[ ${#prd_files[@]} -eq 0 ]]; then
        return 1
    elif [[ ${#prd_files[@]} -eq 1 ]]; then
        echo "${prd_files[0]}"
        return 0
    else
        log_info "Multiple PRD files found:"
        for i in "${!prd_files[@]}"; do
            echo "  $((i + 1)). ${prd_files[i]}"
        done
        
        while true; do
            read -p "Select a PRD file (1-${#prd_files[@]}): " choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#prd_files[@]} ]]; then
                echo "${prd_files[$((choice - 1))]}"
                return 0
            fi
            log_warning "Invalid selection. Please choose 1-${#prd_files[@]}"
        done
    fi
}

# Parse existing PRD
parse_existing_prd() {
    local prd_file="$1"
    
    log_info "Parsing PRD: $prd_file"
    log_info "This may take up to a minute as AI analyzes your requirements..."
    
    # Use research flag for better task generation
    $TASKMASTER_CMD parse-prd "$prd_file" --research --force
    
    log_success "PRD parsed successfully! Tasks generated."
    log_info "Run 'task-master list' to see your project tasks"
    log_info "Run 'task-master next' to see what to work on first"
}

# Create PRD template with AI starter kit context
create_prd_template() {
    local prd_file=".taskmaster/docs/prd.txt"
    
    # Ensure directory exists
    mkdir -p ".taskmaster/docs"
    
    cat > "$prd_file" << 'EOF'
# AI Application - Product Requirements Document

## Project Vision
[Describe your AI application idea in 2-3 sentences]

## Target Users
[Who will use this AI application?]

## Core AI Features
[What AI capabilities will your application provide?]
- [ ] Chatbot/Conversational AI
- [ ] Document/Text Analysis  
- [ ] Content Generation
- [ ] Data Processing/Analytics
- [ ] Image/Media Processing
- [ ] Search/Recommendation Engine
- [ ] Other: [specify]

## Technical Requirements

### AI Models/Services
- [ ] OpenAI GPT (ChatGPT API)
- [ ] Anthropic Claude
- [ ] Local LLMs (Ollama)
- [ ] Vector Embeddings for Search
- [ ] Custom ML Models
- [ ] Other: [specify]

### Data & Storage
- [ ] User-generated content
- [ ] Document storage and processing
- [ ] Vector database for embeddings
- [ ] Real-time data streams
- [ ] File uploads (images, documents)
- [ ] Other: [specify]

### User Interface
- [ ] Web application (React/Next.js)
- [ ] Mobile app
- [ ] API-only service
- [ ] Admin dashboard
- [ ] Chatbot interface
- [ ] Other: [specify]

### Integration Requirements
- [ ] Third-party APIs
- [ ] Webhook integrations
- [ ] Email notifications
- [ ] Payment processing
- [ ] Social media integration
- [ ] Other: [specify]

## Success Criteria
[How will you measure success?]

## Timeline
[What's your target timeline?]

## Additional Notes
[Any other important details, constraints, or requirements]

---

## Getting Started

1. Fill out this PRD with your specific requirements
2. Save the file
3. Run: `./setup-taskmaster.sh` again to generate your project tasks
4. Start building with: `task-master next`

The Supabase AI Starter Kit provides:
- PostgreSQL database with vector extensions
- Authentication and user management
- Real-time features for live AI interactions
- API gateway for secure access
- n8n for AI workflow automation
- Complete development and testing infrastructure
EOF

    echo "$prd_file"
}

# Interactive PRD creation
create_interactive_prd() {
    log_info "Let's create a Product Requirements Document for your AI application"
    echo
    
    # Create template
    local prd_file=$(create_prd_template)
    
    log_success "PRD template created: $prd_file"
    echo
    log_info "Next steps:"
    echo "  1. Edit $prd_file with your specific requirements"
    echo "  2. Run './setup-taskmaster.sh' again to generate tasks"
    echo "  3. Start building with 'task-master next'"
    echo
    log_info "Or continue with the example PRD for a demo experience"
    
    read -p "Continue with example PRD now? (y/N): " continue_demo
    if [[ "$continue_demo" =~ ^[Yy]$ ]]; then
        # Fill in a demo example
        create_demo_prd "$prd_file"
        parse_existing_prd "$prd_file"
    fi
}

# Create a demo PRD for immediate testing
create_demo_prd() {
    local prd_file="$1"
    
    cat > "$prd_file" << 'EOF'
# AI-Powered Knowledge Assistant - Product Requirements Document

## Project Vision
Build an AI-powered knowledge assistant that helps users find information, answer questions, and automate common tasks using conversational AI with access to uploaded documents and real-time web search.

## Target Users
- Small business owners who need quick answers about their operations
- Content creators looking for research assistance
- Teams that want to query their internal documentation

## Core AI Features
- Conversational AI chatbot with memory of previous interactions
- Document upload and analysis (PDF, text files)
- Vector-based semantic search across uploaded content
- Real-time web search integration for up-to-date information
- Automated content summarization
- Query suggestion and follow-up questions

## Technical Requirements

### AI Models/Services
- OpenAI GPT-4 for conversational AI and content generation
- OpenAI text-embedding-ada-002 for vector embeddings
- Vector database for semantic search capabilities
- Real-time search integration for current information

### Data & Storage
- User authentication and profile management
- Document storage with metadata (title, upload date, tags)
- Vector embeddings storage for semantic search
- Conversation history and user preferences
- File upload system for PDFs and text documents

### User Interface
- Modern web application with React/Next.js
- Real-time chat interface with typing indicators
- Document management dashboard
- Search interface with filtering options
- Admin panel for user and content management

### Integration Requirements
- Real-time search API integration
- Email notifications for important updates
- Webhook support for third-party integrations
- Export functionality for conversations and insights

## Success Criteria
- Users can upload documents and get relevant answers within 30 seconds
- Chat responses are contextually relevant to user's document library
- System handles at least 100 concurrent users
- 95% uptime and sub-2-second response times

## Timeline
- MVP in 4-6 weeks
- Beta release in 8-10 weeks
- Production launch in 12-14 weeks

## Additional Notes
- Focus on data privacy and secure document handling
- Ensure scalable architecture for future AI model upgrades
- Build with mobile-responsive design for cross-device usage
- Include comprehensive analytics for user engagement tracking
EOF

    log_info "Demo PRD created with example AI knowledge assistant project"
}

# Main execution
main() {
    echo "🚀 Supabase AI Starter Kit - Taskmaster Setup"
    echo "============================================="
    echo
    
    # Pre-flight checks
    check_project_directory
    check_taskmaster
    
    # Initialize Taskmaster
    init_taskmaster
    
    # Look for existing PRD files
    log_info "Looking for Product Requirements Document (PRD)..."
    prd_files=$(find_prd_files)
    
    if [[ -n "$prd_files" ]]; then
        log_success "Found PRD file(s)!"
        selected_prd=$(select_prd_file "$prd_files")
        if [[ -n "$selected_prd" ]]; then
            parse_existing_prd "$selected_prd"
        fi
    else
        log_info "No PRD files found"
        echo
        log_info "A Product Requirements Document helps the AI generate relevant tasks for your project"
        read -p "Would you like to create one? (Y/n): " create_prd
        
        if [[ ! "$create_prd" =~ ^[Nn]$ ]]; then
            create_interactive_prd
        else
            log_info "Skipping PRD creation"
            log_info "You can create one later and run: task-master parse-prd your-prd.txt"
        fi
    fi
    
    echo
    log_success "Setup complete! 🎉"
    echo
    log_info "Next steps:"
    echo "  • View tasks: task-master list"
    echo "  • Get next task: task-master next"
    echo "  • Task details: task-master show <id>"
    echo "  • Update progress: task-master update-subtask --id=X.Y --prompt='...'"
    echo
    log_info "Happy building with AI-powered project planning! 🤖"
}

# Run main function
main "$@" 
