#!/bin/bash

set -e

# Pull this repository
git pull && echo "✅ Pulled latest changes for ds-web-dev"
echo

# Get the list of services
source services.sh

# Pull the latest changes for each service if the main branch is checked out
for service in "${services[@]}"
do
    repo_dir="services/$service"
    echo "Pulling latest changes for $service..."

    # Auto-clone new repos that aren't present locally
    if [[ ! -d "$repo_dir/.git" ]]; then
        echo "📦 $service is missing locally. Cloning..."
        if ! git clone "git@github.com:nationalarchives/$service.git" "$repo_dir"; then
            echo "⚠️ Could not clone $service (missing repo or no access). Skipping."
            echo
            continue
        fi
    fi

    cd "$repo_dir"
    BRANCH="$(git rev-parse --abbrev-ref HEAD)"
    if [[ "$BRANCH" == "main" ]]; then
        git pull origin main && echo "✅ Pulled latest changes for $service" || echo "❌ Failed to pull latest changes for $service"
    else
        echo "⚠️ You are on the $BRANCH branch. Please switch to the main branch to pull the latest changes."
    fi
    cd "../.."
    echo
done

echo "Pulling latest changes for tests..."
cd tests
if [[ "$BRANCH" == "main" ]]; then
    git pull origin main && echo "✅ Pulled latest changes for $service" || echo "❌ Failed to pull latest changes for $service"
else
    echo "⚠️ You are on the $BRANCH branch. Please switch to the main branch to pull the latest changes."
fi
echo
cd ".."

# Restart any services that might be running
./up.sh
