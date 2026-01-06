#!/bin/bash

set -e

# Get the list of services
source services.sh

# Prune all old branches for each service
for service in "${services[@]}"
do
    echo "Pruning old branches and clearing git stashes for $service..."
    cd "services/$service"
    git fetch -p
    for branch in $(git branch -vv | grep ': gone]' | awk '{print $1}')
    do
        git branch -D $branch
    done
    git stash clear
    cd "../.."
    echo
done
