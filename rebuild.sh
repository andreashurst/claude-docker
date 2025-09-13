#!/bin/bash
# Force complete rebuild without any cache

echo "🔄 Force Complete Rebuild"
echo "========================="

# 1. Clean local Docker
echo "Step 1: Cleaning local Docker..."
docker rmi andreashurst/claude-docker:latest-flow 2>/dev/null || true
docker rmi andreashurst/claude-docker:latest-dev 2>/dev/null || true
docker system prune -a -f
#docker builder prune -a -f
docker volume prune -f

# 2. Build with absolutely no cache
echo ""
echo "Step 2: Building with --no-cache and --pull..."
docker buildx build \
  --no-cache \
  --pull \
  --force-rm \
  -f "docker/Dockerfile.flow" \
  --platform "linux/amd64,linux/arm64" \
  -t "andreashurst/claude-docker:latest-flow" \
  .

docker buildx build \
  --no-cache \
  --pull \
  --force-rm \
  -f "docker/Dockerfile.dev" \
  --platform "linux/amd64,linux/arm64" \
  -t "andreashurst/claude-docker:latest-dev" \
  .

# 3. Login and push
echo ""
echo "Step 3: Push to Docker Hub..."
echo "Run: docker login"
docker login

docker push andreashurst/claude-docker:latest-flow
docker push andreashurst/claude-docker:latest-dev

echo ""
echo "✅ Complete! New images pushed without any cache."
echo ""
echo "Users must now run:"
echo "  docker pull andreashurst/claude-docker:latest-flow"
echo "  docker pull andreashurst/claude-docker:latest-dev"
