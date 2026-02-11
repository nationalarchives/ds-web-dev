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
        -subj '/CN=*.localhost' -extensions EXT -config <( \
        printf "[dn]\nCN=*.localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost,DNS:nginx\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
    echo
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
    # elif [[ ! -f "services/$service/.env" ]]
    # then
    #     echo "Creating blank .env for $service..."
    #     touch "services/$service/.env"
    #     echo
    fi
done

# Clone the website tests
if [[ ! -d "tests" ]]
then
    echo "Cloning tests..."
    git clone git@github.com:nationalarchives/ds-tna-website-tests.git tests
    # cp "tests/.example.env" "tests/.env"
    echo
fi

# Start the services
for service in "${services[@]}"
do
    echo "Starting $service..."
    docker compose --file "services/$service/docker-compose.yml" up --detach --wait --wait-timeout 120 && echo "✅ Started $service" || echo "❌ Failed to start $service"
    echo
done

# Set up the frontend dependencies for development
echo "Set up the frontend dependencies..."
docker compose --file services/ds-frontend/docker-compose.yml exec app cp -r /app/node_modules/@nationalarchives/frontend/nationalarchives/assets /app/app/static
docker compose --file services/ds-frontend-enrichment/docker-compose.yml exec app cp -r /app/node_modules/@nationalarchives/frontend/nationalarchives/assets /app/app/static
docker compose --file services/ds-catalogue/docker-compose.yml exec app cp -r /app/node_modules/@nationalarchives/frontend/nationalarchives/assets /app/app/static
docker compose --file services/ds-sitemap-search/docker-compose.yml exec app cp -r /app/node_modules/@nationalarchives/frontend/nationalarchives/assets /app/app/static
docker compose --file services/ds-request-service-record/docker-compose.yml exec app cp -r /app/node_modules/@nationalarchives/frontend/nationalarchives/assets /app/app/static
docker compose --file services/wa-frontend/docker-compose.yml exec app cp -r /app/node_modules/@nationalarchives/frontend/nationalarchives/assets /app/app/static

# Start the nginx service
echo "Starting nginx..."
docker compose up --build --detach --wait --wait-timeout 120 nginx && echo "✅ Started nginx" || echo "❌ Failed to start nginx"
echo

if [[ -f wagtail-init.sql ]]
then
    # Import the wagtail-init.sql file into the Wagtail database
    echo "Importing wagtail-init.sql into the Wagtail database..."
    cp wagtail-init.sql services/ds-wagtail/dumps/wagtail-init.sql
    cd services/ds-wagtail
    ./dev/local-db-restore wagtail-init.sql
    cd ../..
    echo
else
    # Pull a copy of the development database
    echo "Pulling a copy of the development database..."
    cd services/ds-wagtail
    ./dev/pull-data
    cd ../..
    echo
fi

# Create an API token for the Wagtail admin user and update ds-frontend and wa-frontend .env files
echo "Creating Wagtail API token and updating frontend .env files..."
API_TOKEN=$(docker compose --file services/ds-wagtail/docker-compose.yml exec app poetry run python manage.py manage_api_token localhost --refresh --quiet)
sed -i .bak -r -e 's/WAGTAIL_API_KEY=[^\n]*/WAGTAIL_API_KEY='"$API_TOKEN"'/' services/ds-frontend/.env
rm -f services/ds-frontend/.env.bak
docker compose --file "services/ds-frontend/docker-compose.yml" up --detach --wait --wait-timeout 120 app
sed -i .bak -r -e 's/WAGTAIL_API_KEY=[^\n]*/WAGTAIL_API_KEY='"$API_TOKEN"'/' services/wa-frontend/.env
rm -f services/wa-frontend/.env.bak
docker compose --file "services/wa-frontend/docker-compose.yml" up --detach --wait --wait-timeout 120 app
rm -f .env

# Update the root .env file with the Wagtail API token for use by the documentation site
echo "WAGTAIL_API_KEY=$API_TOKEN" >> .env
docker compose up --detach --wait --wait-timeout 120 wagtail-docs

# Populate the sitemap search database in the background
echo "Populating the sitemap search database..."
docker compose --file services/ds-sitemap-search/docker-compose.yml exec --detach app poetry run python populate.py

# Open the browser
open https://localhost || start https://localhost || explorer.exe https://localhost
