#!/bin/bash

echo "🔨 Rebuilding Docker Images for Claude Dev Environment"
echo "======================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to build an image
build_image() {
    local dockerfile=$1
    local tag=$2
    local name=$3
    
    echo -e "${YELLOW}Building $name...${NC}"
    
    if docker build -f "$dockerfile" -t "$tag" --no-cache .; then
        echo -e "${GREEN}✓ $name built successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to build $name${NC}"
        return 1
    fi
}

# Stop and remove old containers if running
echo "Cleaning up old containers..."
docker stop claude-dev 2>/dev/null || true
docker stop claude-flow 2>/dev/null || true
docker rm claude-dev 2>/dev/null || true
docker rm claude-flow 2>/dev/null || true

echo ""
echo "Building images..."
echo ""

# Build Dev image
build_image "Dockerfile.dev" "claude-dev:latest" "Claude Dev Image"
echo ""

# Build Flow image
build_image "Dockerfile.flow" "claude-flow:latest" "Claude Flow Image"
echo ""

echo "======================================================="
echo ""

# Check if builds were successful
if docker images | grep -q "claude-dev.*latest" && docker images | grep -q "claude-flow.*latest"; then
    echo -e "${GREEN}✓ All images built successfully!${NC}"
    echo ""
    echo "You can now run the containers with:"
    echo "  ./bin/claude-dev    # For Claude Dev environment"
    echo "  ./bin/claude-flow   # For Claude Flow environment"
else
    echo -e "${RED}✗ Some images failed to build. Please check the errors above.${NC}"
    exit 1
fi