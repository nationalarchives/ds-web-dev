#!/bin/bash

set -e

# Get the list of services
source services.sh

# Compose can now delegate builds to bake for better performance
# shellcheck disable=SC2034
COMPOSE_BAKE=true

# Stop nginx
docker compose down

# Pull the latest base Python Docker images
docker pull ghcr.io/nationalarchives/tna-python-dev:preview
docker pull ghcr.io/nationalarchives/tna-python-dev:latest

# Rebuild the services
for service in "${services[@]}"
do
    echo "Rebuilding $service..."
    docker compose --file "services/$service/docker-compose.yml" build --no-cache && echo "✅ Rebuilt $service" || echo "❌ Failed to rebuild $service"
    echo
done

# Refresh the Wagtail API keys
./refresh_wagtail_api_keys.sh

# Start the services
./up.sh
