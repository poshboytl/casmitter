#!/bin/bash

# Generate Self-Signed SSL Certificates for Local Development
# Usage: ./generate-self-signed-ssl.sh [domain]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default domain
DOMAIN=${1:-staging.teahour.dev}

# SSL directory
SSL_DIR="nginx/ssl/live/${DOMAIN}"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create SSL directories
log_info "Creating SSL directories..."
mkdir -p "$SSL_DIR"

# Generate private key
log_info "Generating private key..."
openssl genrsa -out "$SSL_DIR/privkey.pem" 2048

# Generate certificate signing request
log_info "Generating certificate signing request..."
openssl req -new -key "$SSL_DIR/privkey.pem" -out "$SSL_DIR/cert.csr" -subj "/C=US/ST=State/L=City/O=Organization/CN=${DOMAIN}"

# Generate self-signed certificate
log_info "Generating self-signed certificate..."
openssl x509 -req -days 365 -in "$SSL_DIR/cert.csr" -signkey "$SSL_DIR/privkey.pem" -out "$SSL_DIR/fullchain.pem"

# Create chain.pem (same as fullchain.pem for self-signed)
log_info "Creating certificate chain..."
cp "$SSL_DIR/fullchain.pem" "$SSL_DIR/chain.pem"

# Set proper permissions
log_info "Setting permissions..."
chmod 644 "$SSL_DIR/fullchain.pem"
chmod 644 "$SSL_DIR/chain.pem"
chmod 600 "$SSL_DIR/privkey.pem"

# Clean up CSR
rm "$SSL_DIR/cert.csr"

log_info "Self-signed SSL certificates generated successfully!"
log_info "Certificate location: $SSL_DIR"
log_warn "Note: Self-signed certificates will show browser warnings"
log_warn "These are suitable for local development and testing only"
log_info "You can now run: ./deploy-staging.sh start"
