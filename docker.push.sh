#!/bin/bash
# Build and push Docker images to Docker Hub

# set -e

echo "🚀 Docker Build & Push"
echo "====================="

# Option to skip build
SKIP_BUILD=${1:-""}


if [ "$SKIP_BUILD" != "--skip-build" ]; then
    echo ""
    echo "Step 1: Building images..."
    echo "--------------------------"

    # Check if we should force rebuild
    if [ "$1" == "--no-cache" ]; then
        echo "⚠️  Force rebuild without cache..."

        # Clean Docker cache
        docker rmi andreashurst/claude-docker:latest-flow 2>/dev/null || true
        docker rmi andreashurst/claude-docker:latest-dev 2>/dev/null || true
        docker system prune -f

        # Build with no cache for multi-platform
        docker buildx build \
            --no-cache \
            --pull \
            --force-rm \
            -f "docker/Dockerfile.dev" \
            --platform "linux/amd64,linux/arm64" \
            -t "andreashurst/claude-docker:latest-dev" \
            .

        docker buildx build \
            --no-cache \
            --pull \
            --force-rm \
            -f "docker/Dockerfile.flow" \
            --platform "linux/amd64,linux/arm64" \
            -t "andreashurst/claude-docker:latest-flow" \
            .
    else
        # Use the regular build script
        ./docker.build.sh
    fi
else
    echo ""
    echo "⏭️  Skipping build (using existing images)"
fi

# Login to Docker Hub
echo ""
echo "Step 2: Login to Docker Hub..."
echo "-------------------------------"
docker login

# Push images
echo ""
echo "Step 3: Pushing images..."
echo "-------------------------"
docker push andreashurst/claude-docker:latest-dev
docker push andreashurst/claude-docker:latest-flow

echo ""
echo "✅ Push complete!"
echo ""
echo "Images available at:"
echo "  docker pull andreashurst/claude-docker:latest-dev"
echo "  docker pull andreashurst/claude-docker:latest-flow"
echo ""
echo "Usage options:"
echo "  ./docker.push.sh              # Build and push"
echo "  ./docker.push.sh --no-cache   # Force rebuild and push"
echo "  ./docker.push.sh --skip-build # Push only (no build)"