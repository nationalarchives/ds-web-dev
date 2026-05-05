#!/bin/bash

set -e

# Get the versions
TNA_PYTHON_UTILITIES_VERSION=$1

# Error if no version was passed
if [[ -z "$TNA_PYTHON_UTILITIES_VERSION" ]]
then
  echo -e "Error: version of TNA Python Utilities not specified\n";
  echo "PARAMETERS"
  echo "  tna-python-utilities the version of TNA Python Utilities to use"
  echo "                       Example: tna_python_utilities_upgrade_all.sh services/ds-frontend 0.30.2";
  exit 1
fi

# Get the list of services
source services.sh

read -p "This will stash all changes, check out the main branch and update TNA Frontend for each service. Are you sure you want to continue? (y/N)" -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  for service in "${services[@]}"
  do
    # Stash any changes, check out the main branch and pull the latest changes
    cd "services/$service"

    # Get the current branch name
    BRANCH="$(git rev-parse --abbrev-ref HEAD)"

    # Start the service to ensure it is working before making any changes
    docker compose up --remove-orphans --detach --wait --wait-timeout 120 && echo "✅ Started $service" || echo "❌ Failed to start $service"

    # If branch is not main, stash changes, check out main and pull the latest changes
    if [[ "$BRANCH" != "main" ]]
    then
      git stash
      git checkout main
    fi

    # Pull the latest changes
    git pull

    # Create a new branch for the upgrade
    git checkout -b "chore/tna-python-utilities-$TNA_PYTHON_UTILITIES_VERSION" || git checkout "chore/tna-python-utilities-$TNA_PYTHON_UTILITIES_VERSION"
    git pull origin main

    # Upgrade TNA Python Utilities for each service
    $(dirname $0)/tna_python_utilities_upgrade_service.sh . "$TNA_PYTHON_UTILITIES_VERSION"

    # Commit and push the changes
    git add package.json package-lock.json pyproject.toml poetry.lock
    
    COMMIT_MESSAGE="Upgrade TNA Python Utilities to version $TNA_PYTHON_UTILITIES_VERSION"

    PR_URL="https://github.com/nationalarchives/$service/compare/chore/tna-python-utilities-$TNA_PYTHON_UTILITIES_VERSION?expand=1"
    (git commit -m "$COMMIT_MESSAGE" && git push && (open "$PR_URL" || start "$PR_URL" || explorer.exe "$PR_URL")) || echo "No changes to commit for $service"

    # If the original branch was not main, check it out again
    git checkout "$BRANCH"

    cd "../.."
  done
fi
