#!/bin/bash

set -e

# Get the versions
APPLICATION_DIRECTORY=$1
TNA_FRONTEND_VERSION=$2
TNA_FRONTEND_JINJA_VERSION=$3

# Error if no application directory was passed
if [[ -z "$APPLICATION_DIRECTORY" ]]
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
if [[ -z "$TNA_FRONTEND_VERSION" ]]
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
if [[ -z "$TNA_FRONTEND_JINJA_VERSION" ]]
then
  TNA_FRONTEND_JINJA_VERSION=$TNA_FRONTEND_VERSION
fi

echo "Updating TNA Frontend in $APPLICATION_DIRECTORY..."

# Start the application to ensure dependencies can be updated
docker compose --file "$APPLICATION_DIRECTORY/docker-compose.yml" up --remove-orphans --detach --wait --wait-timeout 120

# Update TNA Frontend
"$(dirname "$0")/upgrade_npm_dependency.sh" "$APPLICATION_DIRECTORY" "@nationalarchives/frontend" "$TNA_FRONTEND_VERSION" --no-min-release-age

# Restart the application to ensure the new version of TNA Frontend is used
docker compose --file "$APPLICATION_DIRECTORY/docker-compose.yml" restart app

# Update TNA Frontend Jinja
"$(dirname "$0")/upgrade_poetry_dependency.sh" "$APPLICATION_DIRECTORY" "tna-frontend-jinja" "$TNA_FRONTEND_JINJA_VERSION"

# Restart the application to ensure the new version of TNA Frontend Jinja is used
docker compose --file "$APPLICATION_DIRECTORY/docker-compose.yml" restart app
