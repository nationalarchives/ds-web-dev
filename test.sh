#!/bin/bash

set -e

# Run the tests in a Docker container
echo "Booting tests container..."
docker compose up nginx -d && docker compose up --build tests
