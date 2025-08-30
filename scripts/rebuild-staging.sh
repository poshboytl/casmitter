#!/bin/bash

# Rebuild and restart staging environment
# This script will rebuild the Docker image and restart all services

set -e

echo "🚀 Rebuilding staging environment..."

# Stop existing services
echo "📦 Stopping existing services..."
docker-compose -f docker-compose.staging.yml down

# Remove old images to force rebuild
echo "🧹 Cleaning up old images..."
docker-compose -f docker-compose.staging.yml build --no-cache

# Start services
echo "🚀 Starting services..."
docker-compose -f docker-compose.staging.yml up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
sleep 30

# Check service status
echo "📊 Checking service status..."
docker-compose -f docker-compose.staging.yml ps

# Check logs for any errors
echo "📋 Recent logs from app service:"
docker-compose -f docker-compose.staging.yml logs --tail=20 app

echo "✅ Staging environment rebuild complete!"
echo "🌐 Your app should be available at: http://localhost"
echo "🔍 Check logs with: docker-compose -f docker-compose.staging.yml logs -f app"
