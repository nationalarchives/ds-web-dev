#!/bin/bash

set -e

# Get the list of services
source services.sh

# Compose can now delegate builds to bake for better performance
COMPOSE_BAKE=true

# Stop nginx if it is running
docker compose down

# Generate a self-signed SSL certificate for localhost
mkdir -p ssl
if [[ ! -f ssl/localhost.crt || ! -f ssl/localhost.key ]];
then
    echo "Generating self-signed SSL certificate for localhost/nginx..."
    openssl req -x509 -out ssl/localhost.crt -keyout ssl/localhost.key \
        -newkey rsa:2048 -nodes -sha256 \
        -subj '/CN=localhost' -extensions EXT -config <( \
        printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost,DNS:nginx\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
fi

# Make a directory for the services
mkdir -p services

# Clone the services if they don't exist
for service in "${services[@]}"
do
    if [[ ! -d "services/$service" ]]
    then
        echo "Cloning $service..."
        git clone "git@github.com:nationalarchives/$service.git" "services/$service"
        echo
    fi

    if [[ -f "services/$service/.example.env" ]]
    then
        echo "Copying example .env for $service..."
        cp "services/$service/.example.env" "services/$service/.env"
        echo
    elif [[ ! -f "services/$service/.env" ]]
    then
        echo "Creating blank .env for $service..."
        touch "services/$service/.env"
    fi
done

# Clone the website tests
if [[ ! -d "tests" ]]
then
    echo "Cloning tests..."
    git clone git@github.com:nationalarchives/ds-tna-website-tests.git tests
    cp "tests/.example.env" "tests/.env"
fi

# Set up node_modules directories for frontend services
echo "Setting up node_modules directories for frontend services..."
mkdir -p services/ds-frontend/node_modules services/ds-frontend-enrichment/node_modules services/ds-search/node_modules services/ds-sitemap-search/node_modules

# Start the services
for service in "${services[@]}"
do
    echo "Starting $service..."
    if [[ -d "services/$service/node_modules" ]]
    then
        docker compose --file "services/$service/docker-compose.yml" up --detach --wait --wait-timeout 60 || echo "Failed to start $service"
        echo "Changing ownership of node_modules directory for $service..."
        sudo chown -R "$USER:$USER" "services/$service/node_modules"
    fi
    docker compose --file "services/$service/docker-compose.yml" up --detach --wait --wait-timeout 60 && echo "✅ Started $service" || echo "❌ Failed to start $service"
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
docker compose up --build --detach --wait --wait-timeout 60 nginx && echo "✅ Started nginx" || echo "❌ Failed to start nginx"

# Pull a copy of the development database
echo "Pulling a copy of the development database..."
docker compose --file services/ds-wagtail/docker-compose.yml exec dev pull

# Populate the sitemap search database in the background
echo "Populating the sitemap search database..."
docker compose --file services/ds-sitemap-search/docker-compose.yml exec --detach app poetry run python populate.py

# Open the browser
xdg-open https://localhost || open https://localhost || start https://localhost
