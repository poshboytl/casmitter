#!/bin/bash

# Auto-renew SSL certificates script
# This script should be run via cron job (e.g., daily at 2 AM)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.staging.yml"
ENV_FILE="$PROJECT_DIR/staging.env"
LOG_FILE="$PROJECT_DIR/log/ssl-renewal.log"

# Load environment variables
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo "Error: $ENV_FILE not found" >&2
    exit 1
fi

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
    echo "$(date): [INFO] $1" >> "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "$(date): [WARN] $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date): [ERROR] $1" >> "$LOG_FILE"
}

# Check if certificates need renewal
check_certificate_expiry() {
    local cert_file="$PROJECT_DIR/nginx/ssl/live/${DOMAIN_NAME}/fullchain.pem"
    
    if [ ! -f "$cert_file" ]; then
        log_warn "SSL certificate not found"
        return 1
    fi
    
    # Check if certificate expires within 30 days
    local expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" 2>/dev/null | cut -d= -f2)
    if [ -z "$expiry_date" ]; then
        log_warn "Could not determine certificate expiry date"
        return 1
    fi
    
    local expiry_timestamp=$(date -d "$expiry_date" +%s 2>/dev/null)
    local current_timestamp=$(date +%s)
    local days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))
    
    if [ $days_until_expiry -le 30 ]; then
        log_info "Certificate expires in $days_until_expiry days, renewal needed"
        return 0
    else
        log_info "Certificate expires in $days_until_expiry days, no renewal needed"
        return 1
    fi
}

# Renew SSL certificates
renew_certificates() {
    log_info "Starting SSL certificate renewal..."
    
    cd "$PROJECT_DIR"
    
    # Stop nginx temporarily
    docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" stop nginx
    
    # Run certbot renewal
    if docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" run --rm certbot renew --force-renewal; then
        log_info "SSL certificates renewed successfully"
        
        # Set proper permissions
        chmod -R 644 nginx/ssl/live
        chmod -R 600 nginx/ssl/live/*/privkey.pem
        
        # Start nginx again
        docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d nginx
        
        log_info "SSL renewal completed successfully"
        return 0
    else
        log_error "Failed to renew SSL certificates"
        
        # Start nginx in HTTP-only mode
        docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d nginx
        
        return 1
    fi
}

# Main execution
main() {
    log_info "SSL certificate auto-renewal check started"
    
    # Create log directory if it doesn't exist
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Check if renewal is needed
    if check_certificate_expiry; then
        log_info "Certificate renewal is needed"
        if renew_certificates; then
            log_info "Certificate renewal completed successfully"
        else
            log_error "Certificate renewal failed"
            exit 1
        fi
    else
        log_info "No certificate renewal needed"
    fi
    
    log_info "SSL certificate auto-renewal check completed"
}

# Run main function
main "$@"
