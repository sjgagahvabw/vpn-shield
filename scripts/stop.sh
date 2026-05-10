#!/bin/bash

# Stop VPN Shield

echo "🛑 Stopping VPN Shield..."

cd "$(dirname "$0")/.."

docker-compose down

echo "✅ VPN Shield stopped"
