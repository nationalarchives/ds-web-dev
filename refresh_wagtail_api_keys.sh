#!/bin/bash

set -e

# Get the list of services
source services.sh

echo "Creating Wagtail API token and updating frontend .env files..."

# Create an API token for the Wagtail localhost account
API_TOKEN=$(docker compose --file services/ds-wagtail/docker-compose.yml exec app poetry run python manage.py manage_api_token localhost --refresh --quiet)

# Loop through the list of services and update the WAGTAIL_API_KEY variable in their .env files, then restart the service
for service in "${wagtail_dependant_services[@]}"; do
    if [ -f "${service}/.env" ]; then
        echo "Updating WAGTAIL_API_KEY in ${service}/.env"
        sed -i .bak -r -e 's/WAGTAIL_API_KEY=[^\n]*/WAGTAIL_API_KEY='"$API_TOKEN"'/' "${service}/.env"
        rm -f "${service}/.env.bak"
    else
        echo "No .env file found for ${service}, creating one..."
        touch "${service}/.env"
        echo "WAGTAIL_API_KEY=${API_TOKEN}" >> "${service}/.env"
    fi
    echo "Restarting ${service} service"
    docker compose --file "${service}/docker-compose.yml" up --detach --wait --wait-timeout 120 app
done
