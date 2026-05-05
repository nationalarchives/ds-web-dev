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
    git checkout -b "chore/tna-frontend-$TNA_FRONTEND_VERSION" || git checkout "chore/tna-frontend-$TNA_FRONTEND_VERSION"
    git pull origin main

    # Upgrade TNA Frontend for each service
    "$(dirname "$0")/tna_frontend_upgrade_service.sh" . "$TNA_FRONTEND_VERSION" "$TNA_FRONTEND_JINJA_VERSION"

    # Commit and push the changes
    git add package.json package-lock.json pyproject.toml poetry.lock
    
    if [[ "$TNA_FRONTEND_VERSION" == "$TNA_FRONTEND_JINJA_VERSION" ]]
    then
      COMMIT_MESSAGE="Upgrade TNA Frontend and TNA Frontend Jinja to version $TNA_FRONTEND_VERSION"
    else
      COMMIT_MESSAGE="Upgrade TNA Frontend to version $TNA_FRONTEND_VERSION and TNA Frontend Jinja to version $TNA_FRONTEND_JINJA_VERSION"
    fi
    PR_URL="https://github.com/nationalarchives/$service/compare/chore/tna-frontend-$TNA_FRONTEND_VERSION?expand=1"
    (git commit -m "$COMMIT_MESSAGE" && git push && (open "$PR_URL" || start "$PR_URL" || explorer.exe "$PR_URL")) || echo "No changes to commit for $service"

    # If the original branch was not main, check it out again
    git checkout "$BRANCH"

    cd "../.."
  done
fi
