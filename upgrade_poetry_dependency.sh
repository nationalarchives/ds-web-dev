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
  echo "                       Example: upgrade_poetry_dependency.sh services/ds-frontend tna-frontend-jinja 0.30.0";
  exit 1
fi

# Check if the application directory contains a docker-compose.yml file
if [[ ! -f "$APPLICATION_DIRECTORY/docker-compose.yml" ]]
then
  echo -e "Error: application directory '$APPLICATION_DIRECTORY' does not contain a docker-compose.yml file";
  exit 1
fi

# Update the specified dependency in pyproject.toml
if [[ -f "$APPLICATION_DIRECTORY/pyproject.toml" ]]
then
    if docker compose --file "$APPLICATION_DIRECTORY/docker-compose.yml" exec app poetry show "$DEPENDENCY_NAME" > /dev/null 2>&1;
    then
        echo "Updating $DEPENDENCY_NAME to version $DEPENDENCY_VERSION"
        docker compose --file "$APPLICATION_DIRECTORY/docker-compose.yml" exec app poetry add "$DEPENDENCY_NAME"="$DEPENDENCY_VERSION" --no-cache
    else
        echo "$DEPENDENCY_NAME not found in pyproject.toml, skipping..."
    fi
fi
