#!/bin/bash

set -e

# Get the versions
TNA_FRONTEND_VERSION=$1
TNA_FRONTEND_JINJA_VERSION=$2

# Error if no version was passed
if [[ -z "$TNA_FRONTEND_VERSION" ]]
then
  echo -e "Error: versions of TNA Frontend not specified\n";
  echo "PARAMETERS"
  echo "  tna-frontend         the version of TNA Frontend to use"
  echo "  [tna-frontend-jinja] the version of TNA Frontend Jinja to use (optional)"
  echo "                       Example: tna_frontend_upgrade_all.sh services/ds-frontend 0.30.2 0.30.0";
  exit 1
fi

# If no TNA Frontend Jinja version is passed, use the same as TNA Frontend
if [[ -z "$TNA_FRONTEND_JINJA_VERSION" ]]
then
  TNA_FRONTEND_JINJA_VERSION=$TNA_FRONTEND_VERSION
fi

# Get the list of services
source services.sh

# Upgrade TNA Frontend for each service
for service in "${services[@]}"
do
    ./tna_frontend_upgrade_service.sh "services/$service" "$TNA_FRONTEND_VERSION" "$TNA_FRONTEND_JINJA_VERSION"
done
