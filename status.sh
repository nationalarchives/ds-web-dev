#!/bin/bash

set -e

docker container ls --all --filter "name=app" --format "table {{.Image}}\t{{.State}}\t{{.RunningFor}}\t{{.Ports}}"
