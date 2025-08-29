#!/bin/bash

# Staging Deployment Script for Casmitter
# Usage: ./deploy-staging.sh [start|stop|restart|logs|ssl]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.staging.yml"
ENV_FILE="staging.env"
DOMAIN_NAME=$(grep DOMAIN_NAME $ENV_FILE | cut -d '=' -f2)

# Load environment variables
if [ -f "$ENV_FILE" ]; then
    # Source the file instead of export to handle spaces in values
    set -a
    source "$ENV_FILE"
    set +a
else
    echo -e "${RED}Error: $ENV_FILE not found${NC}"
    exit 1
fi

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
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
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    
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

setup_ssl() {
    log_info "Setting up SSL certificates..."
    
    # Stop nginx temporarily to free up port 80
    docker-compose -f $COMPOSE_FILE stop nginx
    
    # Run certbot to obtain certificates
    docker-compose -f $COMPOSE_FILE run --rm certbot
    
    # Start nginx again
    docker-compose -f $COMPOSE_FILE up -d nginx
    
    log_info "SSL setup completed"
}

start_services() {
    log_info "Starting staging services..."
    
    # Create directories first
    create_directories
    
    # Start all services
    docker-compose -f $COMPOSE_FILE up -d
    
    log_info "Services started successfully"
    log_info "Application will be available at: https://$DOMAIN_NAME"
}

stop_services() {
    log_info "Stopping staging services..."
    
    docker-compose -f $COMPOSE_FILE down
    
    log_info "Services stopped"
}

restart_services() {
    log_info "Restarting staging services..."
    
    docker-compose -f $COMPOSE_FILE restart
    
    log_info "Services restarted"
}

show_logs() {
    log_info "Showing logs for all services..."
    
    docker-compose -f $COMPOSE_FILE logs -f
}

show_status() {
    log_info "Service status:"
    
    docker-compose -f $COMPOSE_FILE ps
}

setup_database() {
    log_info "Setting up database..."
    
    # Wait for database to be ready
    log_info "Waiting for database to be ready..."
    docker-compose -f $COMPOSE_FILE exec -T postgres pg_isready -U casmitter
    
    # Run database migrations
    log_info "Running database migrations..."
    docker-compose -f $COMPOSE_FILE exec -T app bundle exec rails db:migrate
    
    # Seed database if needed
    if [ -f "db/seeds.rb" ]; then
        log_info "Seeding database..."
        docker-compose -f $COMPOSE_FILE exec -T app bundle exec rails db:seed
    fi
    
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
        setup_ssl
        ;;
    setup-db)
        setup_database
        ;;
    generate-secret)
        generate_secret_key
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs|status|ssl|setup-db|generate-secret}"
        echo ""
        echo "Commands:"
        echo "  start           - Start all staging services"
        echo "  stop            - Stop all staging services"
        echo "  restart         - Restart all staging services"
        echo "  logs            - Show logs for all services"
        echo "  status          - Show service status"
        echo "  ssl             - Setup SSL certificates"
        echo "  setup-db        - Setup database (migrations, seeds)"
        echo "  generate-secret - Generate new SECRET_KEY_BASE"
        exit 1
        ;;
esac
