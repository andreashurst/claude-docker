#!/bin/bash
# Installation script for Docker development tools
# Part of claude-docker: https://github.com/andreashurst/claude-docker

echo "═══════════════════════════════════════════════════════════"
echo "       INSTALLING DOCKER DEVELOPMENT TOOLS"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if running in Docker
if [ ! -f /.dockerenv ] && [ -z "$DOCKER_CONTAINER" ]; then
    echo -e "${YELLOW}Warning: Not running in Docker container${NC}"
    echo "These tools are designed for Docker environments"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "Step 1: Creating convenient aliases..."
echo ""

# Function to add alias if it doesn't exist
add_alias() {
    local alias_name="$1"
    local alias_command="$2"
    local bashrc="${HOME}/.bashrc"
    
    if ! grep -q "alias $alias_name=" "$bashrc" 2>/dev/null; then
        echo "alias $alias_name='$alias_command'" >> "$bashrc"
        echo -e "${GREEN}✓${NC} Added alias: $alias_name"
    else
        echo -e "${YELLOW}•${NC} Alias already exists: $alias_name"
    fi
}

# Add aliases
add_alias "curl" "/usr/local/bin/curl-docker"
add_alias "playwright" "/usr/local/bin/playwright-docker"
add_alias "vite-proxy" "/usr/local/bin/node /usr/local/bin/vite-hmr-proxy.cjs"

echo ""
echo "Step 2: Verifying installations..."
echo ""

# Check curl wrapper
if [ -x "/usr/local/bin/curl-docker" ]; then
    echo -e "${GREEN}✓${NC} Curl wrapper installed"
else
    echo -e "${RED}✗${NC} Curl wrapper not found"
fi

# Check playwright wrapper
if [ -x "/usr/local/bin/playwright-docker" ]; then
    echo -e "${GREEN}✓${NC} Playwright wrapper installed"
else
    echo -e "${RED}✗${NC} Playwright wrapper not found"
fi

# Check vite proxy
if [ -f "/usr/local/bin/vite-hmr-proxy.cjs" ]; then
    echo -e "${GREEN}✓${NC} Vite HMR proxy installed"
else
    echo -e "${RED}✗${NC} Vite HMR proxy not found"
fi

# Check Node.js
if command -v node >/dev/null 2>&1 || [ -x "/usr/local/bin/node" ]; then
    echo -e "${GREEN}✓${NC} Node.js available"
else
    echo -e "${RED}✗${NC} Node.js not found"
fi

# Check Playwright CLI
if [ -f "/usr/local/lib/node_modules/playwright/cli.js" ]; then
    echo -e "${GREEN}✓${NC} Playwright CLI found"
else
    echo -e "${RED}✗${NC} Playwright CLI not found"
fi

echo ""
echo "Step 3: Testing basic functionality..."
echo ""

# Test curl wrapper
if /usr/local/bin/curl-docker --version >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Curl wrapper works"
else
    echo -e "${RED}✗${NC} Curl wrapper test failed"
fi

# Test playwright wrapper
if /usr/local/bin/playwright-docker --version >/dev/null 2>&1; then
    VERSION=$(/usr/local/bin/playwright-docker --version 2>/dev/null)
    echo -e "${GREEN}✓${NC} Playwright wrapper works (${VERSION})"
else
    echo -e "${RED}✗${NC} Playwright wrapper test failed"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo -e "${GREEN}                 INSTALLATION COMPLETE${NC}"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Usage:"
echo "  curl http://localhost:3000          # Auto-rewrites to host.docker.internal"
echo "  playwright screenshot URL output.png # Auto-rewrites URLs"
echo "  vite-proxy 3000                     # Start HMR proxy for full support"
echo ""
echo "Note: Reload your shell or run: source ~/.bashrc"
echo ""