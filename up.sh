#!/bin/bash

set -e

# Get the list of services
source services.sh

# Start the services
for service in "${services[@]}"
do
    echo "Starting $service..."
    docker compose --file "services/$service/docker-compose.yml" up --detach --wait --wait-timeout 60 && echo "✅ Started $service" || echo "❌ Failed to start $service"
    echo
done

# Start the nginx service
echo "Starting nginx..."
docker compose up --build --detach --wait --wait-timeout 60 && echo "✅ Started nginx" || echo "❌ Failed to start nginx"
