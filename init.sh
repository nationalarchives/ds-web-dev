#!/bin/bash

set -e

# Get the list of services
source services.sh

# Stop nginx if it is running
docker compose down

# Generate a self-signed SSL certificate for localhost
mkdir -p ssl
if [[ ! -f ssl/localhost.crt || ! -f ssl/localhost.key ]];
then
    echo "Generating self-signed SSL certificate for localhost..."
    openssl req -x509 -out ssl/localhost.crt -keyout ssl/localhost.key \
        -newkey rsa:2048 -nodes -sha256 \
        -subj '/CN=localhost' -extensions EXT -config <( \
        printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
fi

# Make a directory for the services
mkdir -p services

# Clone the services if they don't exist and start them
for service in "${services[@]}"
do
    if [ ! -d "services/$service" ]
    then
        echo "Cloning $service..."
        git clone "git@github.com:nationalarchives/$service.git" "services/$service"
    fi
    echo "Starting $service..."
    docker compose --file "services/$service/docker-compose.yml" up --detach && echo "✅ Started $service" || echo "❌ Failed to start $service"
    echo
done

# Set up the frontend dependencies for development
echo "Set up the frontend dependencies..."
docker compose --file services/ds-frontend/docker-compose.yml exec app cp -r /app/node_modules/@nationalarchives/frontend/nationalarchives/assets /app/app/static
docker compose --file services/ds-frontend-enrichment/docker-compose.yml exec app cp -r /app/node_modules/@nationalarchives/frontend/nationalarchives/assets /app/app/static
docker compose --file services/ds-search/docker-compose.yml exec app cp -r /app/node_modules/@nationalarchives/frontend/nationalarchives/assets /app/app/static
docker compose --file services/ds-sitemap-search/docker-compose.yml exec app cp -r /app/node_modules/@nationalarchives/frontend/nationalarchives/assets /app/app/static

# Start the nginx service
echo "Starting nginx..."
docker compose up --build --detach && echo "✅ Started nginx" || echo "❌ Failed to start nginx"

# Pull a copy of the development database
echo "Pulling a copy of the development database..."
docker compose --file services/ds-wagtail/docker-compose.yml exec dev pull

# Populate the sitemap search database in the background
echo "Populating the sitemap search database..."
docker compose --file services/ds-sitemap-search/docker-compose.yml exec --detach app poetry run python populate.py

# Open the browser
xdg-open https://localhost || open https://localhost || start https://localhost
