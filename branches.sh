#!/bin/bash

set -e

# Get the list of services
source services.sh

LONGEST_SERVICE_NAME_LENGTH=0
for service in "${services[@]}"
do
    # Get the length of the service name
    SERVICE_NAME_LENGTH=${#service}
    # Update the longest service name length if necessary
    if [ $SERVICE_NAME_LENGTH -gt $LONGEST_SERVICE_NAME_LENGTH ]; then
        LONGEST_SERVICE_NAME_LENGTH=$SERVICE_NAME_LENGTH
    fi
done

# Pull the latest changes for each service if the main branch is checked out
for service in "${services[@]}"
do
    cd "services/$service"
    BRANCH="$(git rev-parse --abbrev-ref HEAD)"
    echo "$service$(printf -- ' '%.s $(seq -s ' ' $(($LONGEST_SERVICE_NAME_LENGTH-${#service}+3))))$BRANCH"
    cd "../.."
done
