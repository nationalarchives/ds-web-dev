#!/bin/bash

set -e

# Get the list of services
source services.sh

# Show the current git status of each service
for service in "${services[@]}"
do
    echo "Git status for $service"
    cd "services/$service"
    git status
    cd "../.."
    echo
done
