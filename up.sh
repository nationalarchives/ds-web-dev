#!/bin/bash

set -e

# Get the list of services
source services.sh

# Compose can now delegate builds to bake for better performance
COMPOSE_BAKE=true

# Start the services
for service in "${services[@]}"
do
    echo "Starting $service..."
    docker compose --file "services/$service/docker-compose.yml" up --detach --wait --wait-timeout 120 && echo "✅ Started $service" || echo "❌ Failed to start $service"
    echo
done

# Start the nginx service
echo "Restarting nginx..."
docker compose up --build --detach --wait --wait-timeout 120 nginx && echo "✅ Started nginx" || echo "❌ Failed to start nginx"
