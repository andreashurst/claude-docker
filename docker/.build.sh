#!/bin/bash
set -e

# Go to project root if in docker/
[[ "$PWD" == */docker ]] && cd ..

[[ ! -f docker/Dockerfile.dev ]] && echo "Error: Run from project root or docker/" && exit 1

docker build -f docker/Dockerfile.dev -t andreashurst/claude-docker:latest-dev .
docker build -f docker/Dockerfile.flow -t andreashurst/claude-docker:latest-flow .