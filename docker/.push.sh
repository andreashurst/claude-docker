#!/bin/bash
set -e

# Go to project root if in docker/
[[ "$PWD" == */docker ]] && cd ..

[[ ! -f docker/Dockerfile.dev ]] && echo "Error: Run from project root or docker/" && exit 1

# Build unless --skip-build
if [ "$1" != "--skip-build" ]; then
    if [ "$1" == "--no-cache" ]; then
        docker rmi andreashurst/claude-docker:latest-flow 2>/dev/null || true
        docker rmi andreashurst/claude-docker:latest-dev 2>/dev/null || true
        docker system prune -f

        docker buildx build --no-cache --pull --force-rm \
            -f docker/Dockerfile.dev \
            --platform "linux/amd64,linux/arm64" \
            -t "andreashurst/claude-docker:latest-dev" .

        docker buildx build --no-cache --pull --force-rm \
            -f docker/Dockerfile.flow \
            --platform "linux/amd64,linux/arm64" \
            -t "andreashurst/claude-docker:latest-flow" .
    else
        ./docker/.build.sh
    fi
fi

docker login
docker push andreashurst/claude-docker:latest-dev
docker push andreashurst/claude-docker:latest-flow
