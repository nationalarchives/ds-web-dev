#!/bin/bash

set -e

# Get the list of services
source services.sh

# For each service, if the git branch is up-to-date, check out the main branch
for service in "${services[@]}"
do
    echo "Checking out main branch for $service..."
    cd "services/$service"
    git fetch origin main
    if git diff-index --quiet HEAD --; then
        git checkout main && git pull origin main && echo "✅ Checked out main for $service" || echo "❌ Failed to check out main for $service"
    else
        echo "❌ $service has uncommitted changes, skipping"
    fi
    cd "../.."
done
