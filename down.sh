#!/bin/bash

set -e

# Get the list of services
source services.sh

# Stop nginx
docker compose stop

# Stop the services
for service in "${services[@]}"
do
    echo "Stopping $service..."
    docker compose --file "services/$service/docker-compose.yml" stop && echo "✅ Stopped $service" || echo "❌ Failed to stop $service"
    echo
done
