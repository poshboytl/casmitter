#!/bin/bash

# Multi-Environment Deployment Script for Casmitter
# Usage: ./deploy.sh [start|stop|restart|logs|status|cert-only|debug-cert] [options]
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
    
    # First try to find certificates in live directory (standard location)
    local cert_file=$(find nginx/ssl/live -name "fullchain.pem" -path "*/${DOMAIN_NAME}*" 2>/dev/null | head -1)
    local key_file=$(find nginx/ssl/live -name "privkey.pem" -path "*/${DOMAIN_NAME}*" 2>/dev/null | head -1)
    
    # If not found in live, check archive directory
    if [ -z "$cert_file" ] || [ -z "$key_file" ]; then
        log_info "Certificates not found in live directory, checking archive..."
        cert_file=$(find nginx/ssl/archive -name "fullchain*.pem" -path "*/${DOMAIN_NAME}*" 2>/dev/null | head -1)
        key_file=$(find nginx/ssl/archive -name "privkey*.pem" -path "*/${DOMAIN_NAME}*" 2>/dev/null | head -1)
    fi
    
    if [ -n "$cert_file" ] && [ -n "$key_file" ] && [ -f "$cert_file" ] && [ -f "$key_file" ]; then
        # Check if certificates are valid and not expired
        local cert_expiry=$(openssl x509 -enddate -noout -in "$cert_file" 2>/dev/null | cut -d= -f2)
        if [ -n "$cert_expiry" ]; then
            local expiry_date=$(date -d "$cert_expiry" +%s 2>/dev/null)
            local current_date=$(date +%s)
            local days_until_expiry=$(( (expiry_date - current_date) / 86400 ))
            
            # Check if it's a self-signed certificate using more reliable method
            local issuer_full=$(openssl x509 -issuer -noout -in "$cert_file" 2>/dev/null)
            local subject_full=$(openssl x509 -subject -noout -in "$cert_file" 2>/dev/null)
            
            # Check if it's Let's Encrypt certificate
            if echo "$issuer_full" | grep -q "Let's Encrypt\|Let's Encrypt Authority\|Let's Encrypt Authority X3\|Let's Encrypt Authority X4"; then
                log_info "Let's Encrypt certificate detected - valid CA certificate"
                if [ $days_until_expiry -gt 30 ]; then
                    log_info "SSL certificates from Let's Encrypt are valid and will expire in $days_until_expiry days"
                    return 0
                else
                    log_warn "Let's Encrypt certificates will expire in $days_until_expiry days"
                    return 1
                fi
            # Check if it's other CA certificate
            elif echo "$issuer_full" | grep -q "CN=" && echo "$subject_full" | grep -q "CN="; then
                local issuer_cn=$(echo "$issuer_full" | grep -o "CN=[^,]*" | cut -d= -f2)
                local subject_cn=$(echo "$subject_full" | grep -o "CN=[^,]*" | cut -d= -f2)
                
                if [ "$issuer_cn" = "$subject_cn" ] && [ "$issuer_cn" != "staging.teahour.dev" ]; then
                    log_warn "Self-signed SSL certificate detected in live directory"
                    log_info "Removing live directory (contains symlinks to self-signed certs)..."
                    # Remove only the live directory (contains symlinks)
                    rm -rf nginx/ssl/live
                    return 1
                else
                    log_info "CA certificate detected - valid certificate"
                    if [ $days_until_expiry -gt 30 ]; then
                        log_info "SSL certificates from CA are valid and will expire in $days_until_expiry days"
                        return 0
                    else
                        log_warn "SSL certificates will expire in $days_until_expiry days"
                        return 1
                    fi
                fi
            else
                log_warn "Could not determine certificate type"
                return 1
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

handle_certificates() {
    log_info "Handling SSL certificates..."
    
    # Check if we have valid certificates in archive that can be restored
    if [ -d "nginx/ssl/archive" ]; then
        log_info "Found SSL archive directory, checking for existing certificates..."
        
        # Look for valid certificates in archive
        local archive_cert=$(find nginx/ssl/archive -name "fullchain*.pem" -path "*/${DOMAIN_NAME}*" 2>/dev/null | head -1)
        local archive_key=$(find nginx/ssl/archive -name "privkey*.pem" -path "*/${DOMAIN_NAME}*" 2>/dev/null | head -1)
        
        if [ -n "$archive_cert" ] && [ -n "$archive_key" ] && [ -f "$archive_cert" ] && [ -f "$archive_key" ]; then
            log_info "Found existing certificates in archive, attempting to restore structure..."
            
            # Check if certificate is valid and not expired
            local cert_expiry=$(openssl x509 -enddate -noout -in "$archive_cert" 2>/dev/null | cut -d= -f2)
            if [ -n "$cert_expiry" ]; then
                local expiry_date=$(date -d "$cert_expiry" +%s 2>/dev/null)
                local current_date=$(date +%s)
                local days_until_expiry=$(( (expiry_date - current_date) / 86400 ))
                
                if [ $days_until_expiry -gt 0 ]; then
                    log_info "Certificate is valid and expires in $days_until_expiry days"
                    
                    # Check if it's a Let's Encrypt certificate
                    local issuer=$(openssl x509 -issuer -noout -in "$archive_cert" 2>/dev/null)
                    if echo "$issuer" | grep -q "Let's Encrypt\|Let's Encrypt Authority\|Let's Encrypt Authority X3\|Let's Encrypt Authority X4"; then
                        log_info "Let's Encrypt certificate detected, restoring directory structure..."
                        
                        # Create live directory structure
                        mkdir -p "nginx/ssl/live/${DOMAIN_NAME}"
                        mkdir -p "nginx/ssl/live/current"
                        
                        # Find the latest certificate files
                        local cert_file=$(find "nginx/ssl/archive/${DOMAIN_NAME}" -name "fullchain*.pem" | sort -V | tail -1)
                        local key_file=$(find "nginx/ssl/archive/${DOMAIN_NAME}" -name "privkey*.pem" | sort -V | tail -1)
                        local chain_file=$(find "nginx/ssl/archive/${DOMAIN_NAME}" -name "chain*.pem" | sort -V | tail -1)
                        
                        # Create symlinks for domain-specific directory
                        ln -sf "../../archive/${DOMAIN_NAME}/$(basename $cert_file)" "nginx/ssl/live/${DOMAIN_NAME}/fullchain.pem"
                        ln -sf "../../archive/${DOMAIN_NAME}/$(basename $key_file)" "nginx/ssl/live/${DOMAIN_NAME}/privkey.pem"
                        
                        if [ -n "$chain_file" ]; then
                            ln -sf "../../archive/${DOMAIN_NAME}/$(basename $chain_file)" "nginx/ssl/live/${DOMAIN_NAME}/chain.pem"
                        fi
                        
                        # Create symlinks for nginx configuration (current)
                        ln -sf "../../archive/${DOMAIN_NAME}/$(basename $cert_file)" "nginx/ssl/live/current/fullchain.pem"
                        ln -sf "../../archive/${DOMAIN_NAME}/$(basename $key_file)" "nginx/ssl/live/current/privkey.pem"
                        
                        if [ -n "$chain_file" ]; then
                            ln -sf "../../archive/${DOMAIN_NAME}/$(basename $chain_file)" "nginx/ssl/live/current/chain.pem"
                        fi
                        
                        # Set proper permissions
                        chmod 644 "nginx/ssl/live/${DOMAIN_NAME}/fullchain.pem" 2>/dev/null || true
                        chmod 644 "nginx/ssl/live/${DOMAIN_NAME}/chain.pem" 2>/dev/null || true
                        chmod 600 "nginx/ssl/live/${DOMAIN_NAME}/privkey.pem" 2>/dev/null || true
                        chmod 644 "nginx/ssl/live/current/fullchain.pem" 2>/dev/null || true
                        chmod 644 "nginx/ssl/live/current/chain.pem" 2>/dev/null || true
                        chmod 600 "nginx/ssl/live/current/privkey.pem" 2>/dev/null || true
                        
                        log_info "Directory structure restored successfully!"
                        log_info "Certificate will expire in $days_until_expiry days"
                        return 0
                    else
                        log_warn "Certificate is not from Let's Encrypt, will request new certificate"
                    fi
                else
                    log_warn "Certificate has expired, will request new certificate"
                fi
            else
                log_warn "Could not determine certificate expiry, will request new certificate"
            fi
        fi
    fi
    
    # If we reach here, we need to get new certificates
    log_info "No valid certificates found, requesting new Let's Encrypt certificates..."
    setup_ssl_certificates
}

setup_ssl_certificates() {
    log_info "Setting up SSL certificates..."
    
    # Always clean up any existing certificates before requesting new ones
    if [ -d "nginx/ssl/live" ]; then
        log_info "Cleaning up existing certificates..."
        rm -rf nginx/ssl/live
    fi
    
    # Also clean up any other SSL-related files
    if [ -d "nginx/ssl/archive" ]; then
        log_info "Cleaning up SSL archive..."
        rm -rf nginx/ssl/archive
    fi
    
    if [ -d "nginx/ssl/renewal" ]; then
        log_info "Cleaning up SSL renewal configs..."
        rm -rf nginx/ssl/renewal
    fi
    
    log_info "Attempting to obtain Let's Encrypt SSL certificates..."
    
    # Create a simple nginx container just for ACME challenges
    log_info "Creating a simple nginx container for ACME challenges..."
    
    # Stop any existing nginx containers
    docker stop nginx-certbot 2>/dev/null || true
    docker rm nginx-certbot 2>/dev/null || true
    
    # Create webroot directory
    mkdir -p nginx/webroot/.well-known/acme-challenge
    
    # Create a simple nginx container for ACME challenges
    docker run -d \
        --name nginx-certbot \
        -p 80:80 \
        -v "$(pwd)/nginx/webroot:/var/www/html" \
        -v "$(pwd)/nginx/conf.d/certbot.conf:/etc/nginx/conf.d/default.conf" \
        nginx:alpine
    
    # Wait for nginx to be ready
    log_info "Waiting for nginx to be ready..."
    sleep 5
    
    # Verify nginx is accessible on port 80
    log_info "Verifying nginx is accessible on port 80..."
    if ! curl -f http://localhost/up > /dev/null 2>&1; then
        log_error "Nginx is not accessible on port 80. Cannot proceed with SSL setup."
        docker stop nginx-certbot 2>/dev/null || true
        docker rm nginx-certbot 2>/dev/null || true
        return 1
    fi
    
    # Run certbot to obtain certificates
    log_info "Running certbot to obtain certificates..."
    
    # Create certbot container
    if docker run --rm \
        --network host \
        -v "$(pwd)/nginx/ssl:/etc/letsencrypt" \
        -v "$(pwd)/nginx/webroot:/var/www/html" \
        certbot/certbot \
        certonly \
        --webroot \
        --webroot-path=/var/www/html \
        --email "$CERTBOT_EMAIL" \
        --agree-tos \
        --no-eff-email \
        --domains "$DOMAIN_NAME"; then
        
        log_info "SSL certificates generated successfully"
        
        # Set proper permissions
        chmod -R 644 nginx/ssl/live 2>/dev/null || true
        chmod -R 600 nginx/ssl/live/*/privkey.pem 2>/dev/null || true
        
        # Create current symlinks for nginx configuration
        if [ -d "nginx/ssl/live" ]; then
            local domain_dirs=$(find nginx/ssl/live -maxdepth 1 -type d -name "*" | grep -v "^nginx/ssl/live$" | grep -v "^nginx/ssl/live/current$")
            if [ -n "$domain_dirs" ]; then
                local first_domain=$(echo "$domain_dirs" | head -1 | sed 's|.*/||')
                log_info "Creating current symlinks for nginx configuration..."
                
                mkdir -p "nginx/ssl/live/current"
                ln -sf "../$first_domain/fullchain.pem" "nginx/ssl/live/current/fullchain.pem"
                ln -sf "../$first_domain/privkey.pem" "nginx/ssl/live/current/privkey.pem"
                ln -sf "../$first_domain/chain.pem" "nginx/ssl/live/current/chain.pem" 2>/dev/null || true
                
                chmod 644 "nginx/ssl/live/current/fullchain.pem" 2>/dev/null || true
                chmod 644 "nginx/ssl/live/current/chain.pem" 2>/dev/null || true
                chmod 600 "nginx/ssl/live/current/privkey.pem" 2>/dev/null || true
            fi
        fi
        
        # Display certificate and log file information
        log_info "Certificate files created:"
        if [ -d "nginx/ssl/live" ]; then
            find nginx/ssl/live -name "*.pem" -type f 2>/dev/null | while read file; do
                local file_size=$(du -h "$file" 2>/dev/null | cut -f1)
                local file_perms=$(ls -la "$file" 2>/dev/null | awk '{print $1}')
                log_info "  $file ($file_size, $file_perms)"
            done
        fi
        
        # Display log file information
        log_info "Log files created:"
        if [ -d "nginx/ssl/logs" ]; then
            find nginx/ssl/logs -name "*.log" -type f 2>/dev/null | while read logfile; do
                local log_size=$(du -h "$logfile" 2>/dev/null | cut -f1)
                local log_perms=$(ls -la "$logfile" 2>/dev/null | awk '{print $1}')
                log_info "  $logfile ($log_size, $log_perms)"
            done
        fi
        
        # Also check for certbot logs in the ssl directory
        if [ -d "nginx/ssl" ]; then
            find nginx/ssl -name "*.log" -type f 2>/dev/null | while read logfile; do
                local log_size=$(du -h "$logfile" 2>/dev/null | cut -f1)
                local log_perms=$(ls -la "$logfile" 2>/dev/null | awk '{print $1}')
                log_info "  $logfile ($log_size, $log_perms)"
            done
        fi
        
        # Stop the temporary nginx container
        log_info "Stopping temporary nginx container..."
        docker stop nginx-certbot 2>/dev/null || true
        docker rm nginx-certbot 2>/dev/null || true
        
        log_info "SSL setup completed successfully"
        return 0
    else
        log_error "Failed to generate SSL certificates"
        
        # Stop the temporary nginx container
        docker stop nginx-certbot 2>/dev/null || true
        docker rm nginx-certbot 2>/dev/null || true
        
        log_warn "You can manually retry SSL setup with: ./deploy.sh ssl"
        return 1
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
    
    # Start nginx (will use existing SSL certificates if available)
    log_info "Starting nginx..."
    $DOCKER_COMPOSE -f $COMPOSE_FILE --env-file $ENV_FILE up -d nginx
    
    # Wait for nginx to be ready
    log_info "Waiting for nginx to be ready..."
    sleep 10
    
    # Verify nginx is accessible
    if curl -f http://localhost/up > /dev/null 2>&1; then
        log_info "Nginx is accessible on port 80"
    else
        log_warn "Nginx may not be fully ready yet, continuing..."
    fi
    
    log_info "Services started successfully"
    
    # Check SSL status
    if check_ssl_certificates; then
        log_info "Application will be available at: https://$DOMAIN_NAME"
    else
        log_warn "SSL certificates not found, application will be available at: http://$DOMAIN_NAME"
        log_info "You can setup SSL certificates with: ./deploy.sh cert-only"
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
        echo -e "${GREEN}✓ SSL certificates from CA are valid${NC}"
        # Show certificate details
        local cert_file=$(find nginx/ssl/live -name "fullchain.pem" -path "*/${DOMAIN_NAME}*" 2>/dev/null | head -1)
        if [ -z "$cert_file" ]; then
            cert_file=$(find nginx/ssl/archive -name "fullchain*.pem" -path "*/${DOMAIN_NAME}*" 2>/dev/null | head -1)
        fi
        if [ -n "$cert_file" ] && [ -f "$cert_file" ]; then
            local issuer=$(openssl x509 -issuer -noout -in "$cert_file" 2>/dev/null | grep -o "CN=.*" | cut -d= -f2)
            local expiry=$(openssl x509 -enddate -noout -in "$cert_file" 2>/dev/null | cut -d= -f2)
            echo -e "${GREEN}  Issuer: $issuer${NC}"
            echo -e "${GREEN}  Expires: $expiry${NC}"
        fi
        
        # Show log file information
        echo ""
        log_info "SSL Log Files:"
        if [ -d "nginx/ssl" ]; then
            local log_count=0
            find nginx/ssl -name "*.log" -type f 2>/dev/null | while read logfile; do
                local log_size=$(du -h "$logfile" 2>/dev/null | cut -f1)
                local log_perms=$(ls -la "$logfile" 2>/dev/null | awk '{print $1}')
                echo -e "${GREEN}  $logfile${NC} ($log_size, $log_perms)"
                log_count=$((log_count + 1))
            done
            if [ $log_count -eq 0 ]; then
                echo -e "${YELLOW}  No log files found${NC}"
            fi
        else
            echo -e "${YELLOW}  SSL directory not found${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ SSL certificates need attention${NC}"
        echo -e "${YELLOW}  Run './deploy.sh cert-only' to obtain Let's Encrypt certificates${NC}"
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
        
        # For backward compatibility, start now calls full-deploy
        log_info "Starting full deployment..."
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
    cert-only)
        log_info "Running certificate only deployment..."
        check_dependencies
        handle_certificates
        log_info "Certificate only deployment completed."
        ;;
    debug-cert)
        log_info "Debugging SSL certificate information..."
        if [ -d "nginx/ssl" ]; then
            log_info "SSL directory structure:"
            find nginx/ssl -type f -name "*.pem" 2>/dev/null | while read certfile; do
                log_info "Certificate file: $certfile"
                log_info "  Issuer: $(openssl x509 -issuer -noout -in "$certfile" 2>/dev/null || echo 'Error reading issuer')"
                log_info "  Subject: $(openssl x509 -subject -noout -in "$certfile" 2>/dev/null || echo 'Error reading subject')"
                log_info "  Expires: $(openssl x509 -enddate -noout -in "$certfile" 2>/dev/null || echo 'Error reading expiry')"
                log_info "  ---"
            done
        else
            log_info "No SSL directory found"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs|status|cert-only|debug-cert} [options]"
        echo ""
        echo "Environment: $ENVIRONMENT (configured in $ENV_FILE)"
        echo ""
        echo "Commands:"
        echo "  start           - Start all $ENVIRONMENT services with automatic SSL setup"
        echo "  stop            - Stop all $ENVIRONMENT services"
        echo "  restart         - Restart all $ENVIRONMENT services"
        echo "  logs            - Show logs for all services"
        echo "  status          - Show service status and SSL certificate status"
        echo "  cert-only       - Only setup SSL certificates (for testing Let's Encrypt)"
        echo "  debug-cert      - Debug SSL certificate information and structure"
        echo ""
        echo "Options:"
        echo "  -b, --branch <branch>  - Pull latest code from specified Git branch before deployment"
        echo ""
        echo "Examples:"
        echo "  $0 start                    - Start services with current code"
        echo "  $0 start -b staging         - Pull staging branch and start services"
        echo "  $0 start --branch main      - Pull main branch and start services"
        echo "  $0 cert-only                - Only setup SSL certificates (for testing Let's Encrypt)"
        echo "  $0 debug-cert               - Debug SSL certificate information"
        exit 1
        ;;
esac
