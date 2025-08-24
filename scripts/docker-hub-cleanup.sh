#!/bin/bash
# Script to delete Docker Hub images and force rebuild

echo "🧹 Docker Hub Cleanup Script"
echo "============================"

# Local Docker cleanup
echo "1. Cleaning local Docker cache..."
docker system prune -a -f
docker builder prune -a -f

echo ""
echo "2. To delete images from Docker Hub:"
echo "   - Go to: https://hub.docker.com/r/andreashurst/claude-docker"
echo "   - Click on 'Tags' tab"
echo "   - Delete 'latest-flow' and 'latest-dev' tags"
echo "   - Or delete the entire repository and recreate it"

echo ""
echo "3. After Docker Hub cleanup, rebuild and push:"
echo ""
echo "# Build with no cache"
docker build --no-cache -f Dockerfile.flow -t andreashurst/claude-docker:latest-flow .
docker build --no-cache -f Dockerfile.dev -t andreashurst/claude-docker:latest-dev .

echo ""
echo "# Push new images"
docker push andreashurst/claude-docker:latest-flow
docker push andreashurst/claude-docker:latest-dev

echo ""
echo "4. Force users to pull new images:"
echo "docker pull andreashurst/claude-docker:latest-flow"
echo "docker pull andreashurst/claude-docker:latest-dev"