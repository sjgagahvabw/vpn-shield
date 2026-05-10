#!/bin/bash

# Update VPN Shield

echo "🔄 Updating VPN Shield..."

cd "$(dirname "$0")/.."

# Pull latest changes
git pull

# Pull latest Docker images
docker-compose pull

# Rebuild and restart
docker-compose up -d --build

# Clean up old images
docker image prune -f

echo "✅ VPN Shield updated successfully"
