#!/bin/bash

set -e

# Get the versions
APPLICATION_DIRECTORY=$1
DEPENDENCY_NAME=$2
DEPENDENCY_VERSION=$3

# Error if no application directory was passed
if [[ -z "$APPLICATION_DIRECTORY" ]]
then
  echo -e "Error: application directory not passed\n";
  echo "PARAMETERS"
  echo "  application          the directory of the application to upgrade"
  echo "  tna-frontend         the version of TNA Frontend to use"
  echo "  [tna-frontend-jinja] the version of TNA Frontend Jinja to use (optional)"
  echo "                       Example: upgrade_npm_dependency.sh services/ds-frontend @nationalarchives/frontend 0.30.2";
  exit 1
fi

# Check if the application directory contains a docker-compose.yml file
if [[ ! -f "$APPLICATION_DIRECTORY/docker-compose.yml" ]]
then
  echo -e "Error: application directory '$APPLICATION_DIRECTORY' does not contain a docker-compose.yml file";
  exit 1
fi

# Update the specified dependency in package.json
if [[ -f "$APPLICATION_DIRECTORY/package.json" ]]
then
    if jq "has(.dependencies.\"$DEPENDENCY_NAME\")" "$APPLICATION_DIRECTORY/package.json" > /dev/null;
    then
        echo "Updating $DEPENDENCY_NAME to version $DEPENDENCY_VERSION"
        docker compose --file "$APPLICATION_DIRECTORY/docker-compose.yml" exec app bash -c ". tna-nvm && npm install --save-exact $DEPENDENCY_NAME@$DEPENDENCY_VERSION"
    else
        echo "$DEPENDENCY_NAME not found in package.json, skipping..."
    fi
fi
