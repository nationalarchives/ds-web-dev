#!/bin/bash

set -e

# Get the versions
APPLICATION_DIRECTORY=$1
TNA_PYTHON_UTILITIES_VERSION=$2

# Error if no application directory was passed
if [[ -z "$APPLICATION_DIRECTORY" ]]
then
  echo -e "Error: application directory not passed\n";
  echo "PARAMETERS"
  echo "  application          the directory of the application to upgrade"
  echo "  tna-python-utilities the version of TNA Python Utilities to use"
  echo "                       Example: tna_python_utilities_upgrade_service.sh services/ds-frontend 0.30.2";
  exit 1
fi

# Check if the application directory contains a docker-compose.yml file
if [[ ! -f "$APPLICATION_DIRECTORY/docker-compose.yml" ]]
then
  echo -e "Error: application directory '$APPLICATION_DIRECTORY' does not contain a docker-compose.yml file";
  exit 1
fi

# Error if no version was passed
if [[ -z "$TNA_PYTHON_UTILITIES_VERSION" ]]
then
  echo -e "Error: version of TNA Python Utilities not specified\n";
  echo "PARAMETERS"
  echo "  application          the directory of the application to upgrade"
  echo "  tna-python-utilities the version of TNA Python Utilities to use"
  echo "                       Example: tna_python_utilities_upgrade_service.sh services/ds-frontend 0.30.2";
  exit 1
fi

echo "Updating TNA Python Utilities in $APPLICATION_DIRECTORY..."

# Start the application to ensure dependencies can be updated
docker compose --file "$APPLICATION_DIRECTORY/docker-compose.yml" up --remove-orphans --detach --wait --wait-timeout 120

# Update TNA Python Utilities
if docker compose --file "$APPLICATION_DIRECTORY/docker-compose.yml" exec app poetry show flask > /dev/null 2>&1;
    then
      ./upgrade_poetry_dependency.sh "$APPLICATION_DIRECTORY" "tna-utilities[flask]" "$TNA_PYTHON_UTILITIES_VERSION"
    else
      ./upgrade_poetry_dependency.sh "$APPLICATION_DIRECTORY" "tna-utilities" "$TNA_PYTHON_UTILITIES_VERSION"
    fi

# Restart the application to ensure the new version of TNA Python Utilities is used
docker compose --file "$APPLICATION_DIRECTORY/docker-compose.yml" restart app
