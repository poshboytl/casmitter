#!/bin/bash

# Script to fix permissions for Docker volumes
# This ensures the host directories have the correct permissions for the Rails user (UID 1000)

echo "Fixing permissions for Docker volumes..."

# Create directories if they don't exist
mkdir -p ./storage ./log ./tmp

# Set ownership to UID 1000 (Rails user in container)
sudo chown -R 1000:1000 ./storage ./log ./tmp

# Set appropriate permissions
sudo chmod -R 755 ./storage ./log ./tmp

echo "Permissions fixed! You can now run:"
echo "docker-compose -f docker-compose.production.yml up --build"
