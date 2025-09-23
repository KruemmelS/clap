#!/bin/bash

# CLAP Production Update Script
# This script pulls the latest Docker images from GitHub Container Registry and restarts the services

set -e

echo "🚀 Starting CLAP Production Update..."

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Login to GitHub Container Registry (optional, for private repos)
# echo "🔐 Logging in to GitHub Container Registry..."
# echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USERNAME --password-stdin

echo "📥 Pulling latest Docker images..."
docker-compose -f docker-compose.prod.yml pull

echo "🔄 Restarting services..."
docker-compose -f docker-compose.prod.yml up -d

echo "🧹 Cleaning up old images..."
docker image prune -f

echo "✅ Update complete!"
echo "📊 Checking service status..."
docker-compose -f docker-compose.prod.yml ps