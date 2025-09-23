#!/bin/bash

# CLAP Auto-Update Webhook Script
# This script is triggered by GitHub webhook to automatically deploy new versions

set -e

LOG_FILE="/var/log/clap-auto-update.log"
WORK_DIR="/opt/clap"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "🔔 Webhook triggered - Starting auto-update..."

cd "$WORK_DIR"

# Pull latest changes (for docker-compose updates)
log "📥 Pulling latest repository changes..."
git pull origin master >> "$LOG_FILE" 2>&1 || log "⚠️  Git pull failed (this is ok if no repo changes)"

# Pull latest Docker images
log "📦 Pulling latest Docker images from ghcr.io/kruemmels..."
docker-compose -f docker-compose.prod.yml pull >> "$LOG_FILE" 2>&1

# Check if images were updated
IMAGES_UPDATED=$?
if [ $IMAGES_UPDATED -eq 0 ]; then
    log "🔄 Restarting services with new images..."
    docker-compose -f docker-compose.prod.yml up -d >> "$LOG_FILE" 2>&1

    log "🧹 Cleaning up old images..."
    docker image prune -f >> "$LOG_FILE" 2>&1

    log "✅ Auto-update completed successfully!"
    log "📊 Service status:"
    docker-compose -f docker-compose.prod.yml ps >> "$LOG_FILE" 2>&1
else
    log "❌ Failed to pull images"
    exit 1
fi