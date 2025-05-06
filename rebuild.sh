#!/bin/bash

set -e

# Get the list of services
source services.sh

# Compose can now delegate builds to bake for better performance
COMPOSE_BAKE=true

# Stop nginx
docker compose down

# Rebuild the services
for service in "${services[@]}"
do
    echo "Rebuilding $service..."
    docker compose --file "services/$service/docker-compose.yml" build --no-cache && echo "✅ Rebuilt $service" || echo "❌ Failed to rebuild $service"
    echo
done

# Start the services
./init.sh
