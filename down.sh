#!/bin/bash

set -e

# Get the list of services
source services.sh

# Stop nginx
docker compose down

# Start the services
for service in "${services[@]}"
do
    echo "Starting $service..."
    docker compose --file "services/$service/docker-compose.yml" down && echo "✅ Stopped $service" || echo "❌ Failed to stop $service"
    echo
done
