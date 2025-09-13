#!/bin/bash
# Build claude-docker images

#set -e

echo "🔨 Building Claude Docker Images"
echo "================================="

# Build dev image
echo ""
echo "📦 Building claude-dev..."
docker build -f docker/Dockerfile.dev -t andreashurst/claude-docker:latest-dev .

# Build flow image  
echo ""
echo "📦 Building claude-flow..."
docker build -f docker/Dockerfile.flow -t andreashurst/claude-docker:latest-flow .

echo ""
echo "✅ Build complete!"
echo ""
echo "To push to Docker Hub:"
echo "  docker push andreashurst/claude-docker:latest-dev"
echo "  docker push andreashurst/claude-docker:latest-flow"
echo ""
echo "To use locally:"
echo "  claude-dev"
echo "  claude-flow"