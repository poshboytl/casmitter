#!/bin/bash

# Multi-Environment Deployment Script for Casmitter
# Usage: ./deploy.sh [start|stop|restart|logs|ssl|auto-ssl] [options]
# Options:
#   -b, --branch <branch>    Git branch to pull before deployment (e.g., -b staging)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
# Auto-detect environment from .env file
if [ -f ".env" ]; then
    ENV_FILE=".env"
    ENVIRONMENT=$(grep ENVIRONMENT .env | cut -d '=' -f2 2>/dev/null || echo "staging")
else
    # Fallback to staging if no .env file
    ENV_FILE="staging.env"
    ENVIRONMENT="staging"
fi

# Set compose file based on environment
case "$ENVIRONMENT" in
    "production")
        COMPOSE_FILE="docker-compose.production.yml"
        ;;
    "staging"|*)
        COMPOSE_FILE="docker-compose.staging.yml"
        ;;
esac

DOMAIN_NAME=$(grep DOMAIN_NAME $ENV_FILE | cut -d '=' -f2)

# Log environment information
echo -e "${GREEN}[INFO]${NC} Using environment: $ENVIRONMENT"
echo -e "${GREEN}[INFO]${NC} Using compose file: $COMPOSE_FILE"
echo -e "${GREEN}[INFO]${NC} Using env file: $ENV_FILE"
if [ -n "$GIT_BRANCH" ]; then
    echo -e "${GREEN}[INFO]${NC} Git branch to pull: $GIT_BRANCH"
fi

# Parse command line arguments
GIT_BRANCH=""
ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -b|--branch)
            GIT_BRANCH="$2"
            shift 2
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

# Restore arguments for later processing
set -- "${ARGS[@]}"

# Determine docker compose command
if command -v docker &> /dev/null && docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE=""
fi

# Load environment variables for script use
if [ -f "$ENV_FILE" ]; then
    # Source the file instead of export to handle spaces in values
    set -a
    source "$ENV_FILE"
    set +a
    
    # Validate required environment variables
    if [ -z "$DOMAIN_NAME" ]; then
        echo -e "${RED}Error: DOMAIN_NAME not found in $ENV_FILE${NC}"
        exit 1
    fi
    
    if [ -z "$CERTBOT_EMAIL" ]; then
        echo -e "${RED}Error: CERTBOT_EMAIL not found in $ENV_FILE${NC}"
        exit 1
    fi
else
    echo -e "${RED}Error: $ENV_FILE not found${NC}"
    exit 1
fi

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

pull_git_branch() {
    local branch="$1"
    
    if [ -z "$branch" ]; then
        return 0
    fi
    
    log_info "Pulling latest code from branch: $branch"
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository"
        return 1
    fi
    
    # Check if the branch exists remotely
    if ! git ls-remote --heads origin "$branch" > /dev/null 2>&1; then
        log_error "Branch '$branch' does not exist on remote origin"
        return 1
    fi
    
    # Stash any local changes
    if ! git diff-index --quiet HEAD --; then
        log_warn "Local changes detected, stashing them..."
        git stash push -m "Auto-stash before pulling $branch"
    fi
    
    # Fetch latest changes
    log_info "Fetching latest changes from remote..."
    if ! git fetch origin; then
        log_error "Failed to fetch from remote"
        return 1
    fi
    
    # Checkout the specified branch
    log_info "Checking out branch: $branch"
    if ! git checkout "$branch"; then
        log_error "Failed to checkout branch: $branch"
        return 1
    fi
    
    # Pull latest changes
    log_info "Pulling latest changes from branch: $branch"
    if ! git pull origin "$branch"; then
        log_error "Failed to pull from branch: $branch"
        return 1
    fi
    
    # Show current status
    local current_branch=$(git branch --show-current)
    local latest_commit=$(git rev-parse --short HEAD)
    local commit_message=$(git log -1 --pretty=format:"%s")
    
    log_info "Successfully pulled branch: $current_branch"
    log_info "Latest commit: $latest_commit - $commit_message"
    
    return 0
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    if [ -z "$DOCKER_COMPOSE" ]; then
        log_error "Neither 'docker compose' nor 'docker-compose' is available"
        log_error "Please install Docker Compose or ensure Docker Desktop is up to date"
        exit 1
    fi
    
    # Check for libpq-dev package (PostgreSQL client library)
    if ! dpkg -l | grep -q "libpq-dev"; then
        log_warn "libpq-dev package is not installed"
        log_warn "This package is required for PostgreSQL gem compilation"
        log_warn "Please install it using: sudo apt install libpq-dev"
        log_warn "Or on other systems: sudo yum install postgresql-devel (RHEL/CentOS)"
        log_warn "Continuing deployment, but gem installation may fail..."
        echo ""
        read -p "Do you want to continue anyway? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled. Please install libpq-dev and try again."
            exit 1
        fi
    else
        log_info "libpq-dev package is installed"
    fi
    
    log_info "Using: $DOCKER_COMPOSE"
    log_info "Dependencies check passed"
}

create_directories() {
    log_info "Creating necessary directories..."
    
    mkdir -p nginx/ssl
    mkdir -p nginx/webroot
    mkdir -p nginx/logs
    mkdir -p init-scripts
    mkdir -p storage
    mkdir -p log
    mkdir -p tmp
    
    log_info "Directories created"
}

check_ssl_certificates() {
    log_info "Checking SSL certificates..."
    
    local cert_file="nginx/ssl/live/${DOMAIN_NAME}/fullchain.pem"
    local key_file="nginx/ssl/live/${DOMAIN_NAME}/privkey.pem"
    
    if [ -f "$cert_file" ] && [ -f "$key_file" ]; then
        # Check if certificates are valid and not expired
        local cert_expiry=$(openssl x509 -enddate -noout -in "$cert_file" 2>/dev/null | cut -d= -f2)
        if [ -n "$cert_expiry" ]; then
            local expiry_date=$(date -d "$cert_expiry" +%s 2>/dev/null)
            local current_date=$(date +%s)
            local days_until_expiry=$(( (expiry_date - current_date) / 86400 ))
            
            # Check if it's a self-signed certificate
            local issuer=$(openssl x509 -issuer -noout -in "$cert_file" 2>/dev/null | grep -o "CN=.*" | cut -d= -f2)
            local subject=$(openssl x509 -subject -noout -in "$cert_file" 2>/dev/null | grep -o "CN=.*" | cut -d= -f2)
            
            if [ "$issuer" = "$subject" ]; then
                log_warn "Self-signed SSL certificate found (valid until $cert_expiry)"
                log_warn "Self-signed certificates are not recommended for production use"
                log_info "Attempting to obtain Let's Encrypt certificate instead..."
                return 1
            else
                # Let's Encrypt or other CA certificate
                if [ $days_until_expiry -gt 30 ]; then
                    log_info "SSL certificates from CA are valid and will expire in $days_until_expiry days"
                    return 0
                else
                    log_warn "SSL certificates will expire in $days_until_expiry days"
                    return 1
                fi
            fi
        else
            log_warn "Could not determine certificate expiry date"
            return 1
        fi
    else
        log_info "SSL certificates not found"
        return 1
    fi
}

setup_ssl_certificates() {
    log_info "Setting up SSL certificates..."
    
    # Always attempt to obtain Let's Encrypt certificates
    # Remove any existing self-signed certificates
    if [ -d "nginx/ssl/live" ]; then
        log_info "Cleaning up existing certificates..."
        rm -rf nginx/ssl/live
    fi
    
    log_info "Attempting to obtain Let's Encrypt SSL certificates..."
    
    # Stop nginx temporarily to free up port 80
    $DOCKER_COMPOSE -f $COMPOSE_FILE --env-file $ENV_FILE stop nginx
    
    # Clean up old certificates if they exist
    if [ -d "nginx/ssl/live" ]; then
        log_info "Cleaning up old certificates..."
        rm -rf nginx/ssl/live
    fi
    
    # Run certbot to obtain certificates
    log_info "Running certbot to obtain certificates..."
    if $DOCKER_COMPOSE -f $COMPOSE_FILE --env-file $ENV_FILE run --rm certbot; then
        log_info "SSL certificates generated successfully"
        
        # Set proper permissions
        chmod -R 644 nginx/ssl/live
        chmod -R 600 nginx/ssl/live/*/privkey.pem
        
        # Start nginx again
        $DOCKER_COMPOSE -f $COMPOSE_FILE --env-file $ENV_FILE up -d nginx
        
        log_info "SSL setup completed successfully"
        return 0
    else
        log_error "Failed to generate SSL certificates"
        
        # Start nginx in HTTP-only mode
        log_info "Starting nginx in HTTP-only mode..."
        $DOCKER_COMPOSE -f $COMPOSE_FILE --env-file $ENV_FILE up -d nginx
        
        return 1
    fi
}

auto_ssl_setup() {
    log_info "Setting up automatic SSL certificate management..."
    
    # Check if certificates exist and are valid
    if check_ssl_certificates; then
        log_info "SSL certificates from CA are valid"
        
        # Check if renewal is needed (within 30 days)
        local cert_file="nginx/ssl/live/${DOMAIN_NAME}/fullchain.pem"
        local expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" 2>/dev/null | cut -d= -f2)
        local days_until_expiry=$(( ($(date -d "$expiry_date" +%s) - $(date +%s)) / 86400 ))
        
        if [ $days_until_expiry -le 30 ]; then
            log_info "Certificates will expire soon, attempting renewal..."
            setup_ssl_certificates
        fi
    else
        log_info "No valid CA certificates found, attempting to obtain Let's Encrypt certificates..."
        setup_ssl_certificates
    fi
}

start_services() {
    log_info "Starting $ENVIRONMENT services..."
    
    # Create directories first
    create_directories
    
    # Start core services (without nginx first)
    log_info "Starting core services..."
    $DOCKER_COMPOSE -f $COMPOSE_FILE --env-file $ENV_FILE up -d postgres redis app
    
    # Wait for app to be ready
    log_info "Waiting for application to be ready..."
    sleep 30
    
    # Setup SSL certificates
    auto_ssl_setup
    
    # Start nginx (will be started by SSL setup if successful)
    if ! $DOCKER_COMPOSE -f $COMPOSE_FILE --env-file $ENV_FILE ps nginx | grep -q "Up"; then
        log_info "Starting nginx..."
        $DOCKER_COMPOSE -f $COMPOSE_FILE --env-file $ENV_FILE up -d nginx
    fi
    
    log_info "Services started successfully"
    
    # Check final status
    if check_ssl_certificates; then
        log_info "Application will be available at: https://$DOMAIN_NAME"
    else
        log_warn "SSL setup failed, application will be available at: http://$DOMAIN_NAME"
        log_info "You can manually run './deploy-staging.sh ssl' to retry SSL setup"
    fi
}

stop_services() {
    log_info "Stopping $ENVIRONMENT services..."
    
    $DOCKER_COMPOSE -f $COMPOSE_FILE --env-file $ENV_FILE down
    
    log_info "Services stopped"
}

restart_services() {
    log_info "Restarting $ENVIRONMENT services..."
    
    $DOCKER_COMPOSE -f $COMPOSE_FILE --env-file $ENV_FILE restart
    
    log_info "Services restarted"
}

show_logs() {
    log_info "Showing logs for all services..."
    
    $DOCKER_COMPOSE -f $COMPOSE_FILE --env-file $ENV_FILE logs -f
}

show_status() {
    log_info "Service status:"
    
    $DOCKER_COMPOSE -f $COMPOSE_FILE --env-file $ENV_FILE ps
    
    echo ""
    log_info "SSL Certificate Status:"
    if check_ssl_certificates; then
        local cert_file="nginx/ssl/live/${DOMAIN_NAME}/fullchain.pem"
        if [ -f "$cert_file" ]; then
            local issuer=$(openssl x509 -issuer -noout -in "$cert_file" 2>/dev/null | grep -o "CN=.*" | cut -d= -f2)
            local subject=$(openssl x509 -subject -noout -in "$cert_file" 2>/dev/null | grep -o "CN=.*" | cut -d= -f2)
            
            if [ "$issuer" = "$subject" ]; then
                echo -e "${YELLOW}⚠ Self-signed SSL certificate found (not recommended)${NC}"
                echo -e "${YELLOW}⚠ Attempting to obtain Let's Encrypt certificate...${NC}"
            else
                echo -e "${GREEN}✓ SSL certificates from CA are valid${NC}"
            fi
        else
            echo -e "${GREEN}✓ SSL certificates are valid${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ SSL certificates need attention${NC}"
    fi
}

setup_database() {
    log_info "Setting up database..."
    
    # Wait for database to be ready
    log_info "Waiting for database to be ready..."
    $DOCKER_COMPOSE -f $COMPOSE_FILE --env-file $ENV_FILE exec -T postgres pg_isready -U casmitter
    
    # Run database migrations
    log_info "Running database migrations..."
    $DOCKER_COMPOSE -f $COMPOSE_FILE --env-file $ENV_FILE exec -T app bundle exec rails db:migrate
    
    log_info "Database setup completed"
}

generate_secret_key() {
    log_info "Generating new SECRET_KEY_BASE..."
    
    # Generate a new secret key
    NEW_SECRET=$(ruby -e "require 'securerandom'; puts SecureRandom.hex(64)")
    
    if [ $? -eq 0 ]; then
        log_info "New SECRET_KEY_BASE generated successfully!"
        echo ""
        echo "Add this to your staging.env file:"
        echo "SECRET_KEY_BASE=$NEW_SECRET"
        echo ""
        echo "Or update the existing line in staging.env"
    else
        log_error "Failed to generate SECRET_KEY_BASE"
        log_info "You can manually generate one using:"
        log_info "ruby -e \"require 'securerandom'; puts SecureRandom.hex(64)\""
    fi
}

# Main script logic
case "${1:-start}" in
    start)
        check_dependencies
        
        # Pull Git branch if specified
        if [ -n "$GIT_BRANCH" ]; then
            if ! pull_git_branch "$GIT_BRANCH"; then
                log_error "Failed to pull Git branch: $GIT_BRANCH"
                exit 1
            fi
        fi
        
        start_services
        log_info "Waiting for services to be ready..."
        sleep 30
        setup_database
        log_info "Deployment completed successfully!"
        show_status
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    logs)
        show_logs
        ;;
    status)
        show_status
        ;;
    ssl)
        setup_ssl_certificates
        ;;
    auto-ssl)
        auto_ssl_setup
        ;;
    force-ssl)
        log_info "Forcing Let's Encrypt SSL certificate setup..."
        if [ -f "./force-letsencrypt.sh" ]; then
            ./force-letsencrypt.sh
        else
            log_error "Force Let's Encrypt script not found"
            exit 1
        fi
        ;;
    setup-db)
        setup_database
        ;;
    generate-secret)
        generate_secret_key
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs|status|ssl|auto-ssl|force-ssl|setup-db|generate-secret} [options]"
        echo ""
        echo "Environment: $ENVIRONMENT (configured in $ENV_FILE)"
        echo ""
        echo "Commands:"
        echo "  start           - Start all $ENVIRONMENT services with automatic SSL setup"
        echo "  stop            - Stop all $ENVIRONMENT services"
        echo "  restart         - Restart all $ENVIRONMENT services"
        echo "  logs            - Show logs for all services"
        echo "  status          - Show service status and SSL certificate status"
        echo "  ssl             - Manually setup SSL certificates (requires public domain)"
        echo "  auto-ssl        - Automatically manage SSL certificates"
        echo "  force-ssl       - Force Let's Encrypt SSL certificate setup (removes existing certs)"
        echo "  setup-db        - Setup database (migrations, seeds)"
        echo "  generate-secret - Generate new SECRET_KEY_BASE"
        echo ""
        echo "Options:"
        echo "  -b, --branch <branch>  - Pull latest code from specified Git branch before deployment"
        echo ""
        echo "Examples:"
        echo "  $0 start                    - Start services with current code"
        echo "  $0 start -b staging         - Pull staging branch and start services"
        echo "  $0 start --branch main      - Pull main branch and start services"
        exit 1
        ;;
esac
