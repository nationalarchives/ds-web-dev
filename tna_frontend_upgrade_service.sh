#!/bin/bash

set -e

# Get the versions
APPLICATION_DIRECTORY=$1
TNA_FRONTEND_VERSION=$2
TNA_FRONTEND_JINJA_VERSION=$3

# Error if no application directory was passed
if [ -z "$APPLICATION_DIRECTORY" ]
then
  echo -e "Error: application directory not passed\n";
  echo "PARAMETERS"
  echo "  application          the directory of the application to upgrade"
  echo "  tna-frontend         the version of TNA Frontend to use"
  echo "  [tna-frontend-jinja] the version of TNA Frontend Jinja to use (optional)"
  echo "                       Example: tna_frontend_upgrade_service.sh services/ds-frontend 0.30.2 0.30.0";
  exit 1
fi

# Check if the application directory contains a docker-compose.yml file
if [[ ! -f "$APPLICATION_DIRECTORY/docker-compose.yml" ]]
then
  echo -e "Error: application directory '$APPLICATION_DIRECTORY' does not contain a docker-compose.yml file";
  exit 1
fi

# Error if no version was passed
if [ -z "$TNA_FRONTEND_VERSION" ]
then
  echo -e "Error: versions of TNA Frontend not specified\n";
  echo "PARAMETERS"
  echo "  application          the directory of the application to upgrade"
  echo "  tna-frontend         the version of TNA Frontend to use"
  echo "  [tna-frontend-jinja] the version of TNA Frontend Jinja to use (optional)"
  echo "                       Example: tna_frontend_upgrade_service.sh services/ds-frontend 0.30.2 0.30.0";
  exit 1
fi

# If no TNA Frontend Jinja version is passed, use the same as TNA Frontend
if [ -z "$TNA_FRONTEND_JINJA_VERSION" ]
then
  TNA_FRONTEND_JINJA_VERSION=$TNA_FRONTEND_VERSION
fi

echo "Updating TNA Frontend in $APPLICATION_DIRECTORY..."

# Start the application to ensure dependencies can be updated
docker compose --file "$APPLICATION_DIRECTORY/docker-compose.yml" up --remove-orphans --detach --wait --wait-timeout 120

# Update TNA Frontend in package.json
if [[ -f "$APPLICATION_DIRECTORY/package.json" ]]
then
    if jq 'has(.dependencies."@nationalarchives/frontend")' "$APPLICATION_DIRECTORY/package.json" > /dev/null;
    then
        echo "Updating @nationalarchives/frontend to version $TNA_FRONTEND_VERSION"
        docker compose --file "$APPLICATION_DIRECTORY/docker-compose.yml" exec app bash -c ". tna-nvm && npm install --save-exact @nationalarchives/frontend@$TNA_FRONTEND_VERSION"
    else
        echo "@nationalarchives/frontend not found in package.json, skipping..."
    fi
fi

# Update TNA Frontend Jinja in pyproject.toml
if [[ -f "$APPLICATION_DIRECTORY/pyproject.toml" ]]
then
    if docker compose --file "$APPLICATION_DIRECTORY/docker-compose.yml" exec app poetry show tna-frontend-jinja > /dev/null 2>&1;
    then
        echo "Updating tna-frontend-jinja to version $TNA_FRONTEND_JINJA_VERSION"
        docker compose --file "$APPLICATION_DIRECTORY/docker-compose.yml" exec app poetry add tna-frontend-jinja="$TNA_FRONTEND_JINJA_VERSION"
    else
        echo "tna-frontend-jinja not found in pyproject.toml, skipping..."
    fi
fi

# docker compose --file "$APPLICATION_DIRECTORY/docker-compose.yml" build --no-cache
docker compose --file "$APPLICATION_DIRECTORY/docker-compose.yml" restart app
