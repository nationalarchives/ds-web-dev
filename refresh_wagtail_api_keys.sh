#!/bin/bash

set -e

echo "Creating Wagtail API token and updating frontend .env files..."

# Create an API token for the Wagtail localhost account
API_TOKEN=$(docker compose --file services/ds-wagtail/docker-compose.yml exec app poetry run python manage.py manage_api_token localhost --refresh --quiet)

# Update the WAGTAIL_API_KEY value in ds-frontend and restart the service
sed -i .bak -r -e 's/WAGTAIL_API_KEY=[^\n]*/WAGTAIL_API_KEY='"$API_TOKEN"'/' services/ds-frontend/.env
rm -f services/ds-frontend/.env.bak
docker compose --file "services/ds-frontend/docker-compose.yml" up --detach --wait --wait-timeout 120 app

# Update the WAGTAIL_API_KEY value in wa-frontend and restart the service
sed -i .bak -r -e 's/WAGTAIL_API_KEY=[^\n]*/WAGTAIL_API_KEY='"$API_TOKEN"'/' services/wa-frontend/.env
rm -f services/wa-frontend/.env.bak
docker compose --file "services/wa-frontend/docker-compose.yml" up --detach --wait --wait-timeout 120 app

# Update the WAGTAIL_API_KEY value for wagtail-docs and restart the service
sed -i .bak -r -e 's/WAGTAIL_API_KEY=[^\n]*/WAGTAIL_API_KEY='"$API_TOKEN"'/' .env
rm -f .env.bak
docker compose up --detach --wait --wait-timeout 120 wagtail-docs
