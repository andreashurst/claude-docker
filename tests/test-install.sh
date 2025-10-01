#!/bin/bash
#
# Automated Tests for Claude Docker Installation
# Tests the install.sh script without actually installing
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "════════════════════════════════════════════════════════"
echo "  🧪 Claude Docker Installation Tests"
echo "════════════════════════════════════════════════════════"
echo ""

PASS=0
FAIL=0

# Test function
test_check() {
    local name=$1
    local result=$2

    if [ $result -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $name"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} $name"
        ((FAIL++))
    fi
}

# Test 1: Docker is available
echo "Testing prerequisites..."
docker info &>/dev/null
test_check "Docker daemon is running" $?

# Test 2: Required files exist
echo ""
echo "Testing file structure..."

[ -f "$PROJECT_ROOT/install.sh" ]
test_check "install.sh exists" $?

[ -f "$PROJECT_ROOT/bin/claude-dev" ]
test_check "bin/claude-dev exists" $?

[ -f "$PROJECT_ROOT/bin/claude-flow" ]
test_check "bin/claude-flow exists" $?

[ -f "$PROJECT_ROOT/bin/claude-health" ]
test_check "bin/claude-health exists" $?

[ -f "$PROJECT_ROOT/bin/git-commit-ai" ]
test_check "bin/git-commit-ai exists" $?

[ -f "$PROJECT_ROOT/bin/mcp-status" ]
test_check "bin/mcp-status exists" $?

[ -f "$PROJECT_ROOT/bin/claude-docker.lib.sh" ]
test_check "bin/claude-docker.lib.sh exists" $?

# Test 3: Dockerfiles exist
[ -f "$PROJECT_ROOT/docker/Dockerfile.dev" ]
test_check "docker/Dockerfile.dev exists" $?

[ -f "$PROJECT_ROOT/docker/Dockerfile.flow" ]
test_check "docker/Dockerfile.flow exists" $?

# Test 4: MCP structure
echo ""
echo "Testing MCP structure..."

[ -d "$PROJECT_ROOT/mcp/servers" ]
test_check "mcp/servers directory exists" $?

[ -d "$PROJECT_ROOT/mcp/context" ]
test_check "mcp/context directory exists" $?

[ -d "$PROJECT_ROOT/mcp/cache" ]
test_check "mcp/cache directory exists" $?

[ -f "$PROJECT_ROOT/mcp/config.json" ]
test_check "mcp/config.json exists" $?

# Test 5: MCP servers exist
SERVER_COUNT=$(find "$PROJECT_ROOT/mcp/servers" -name "*.js" -type f | wc -l)
[ $SERVER_COUNT -ge 7 ]
test_check "At least 7 MCP servers present ($SERVER_COUNT found)" $?

# Test 6: Context files exist
CONTEXT_COUNT=$(find "$PROJECT_ROOT/mcp/context" -name "*.json" -type f -o -name "*.html" -type f | wc -l)
[ $CONTEXT_COUNT -ge 10 ]
test_check "Context files present ($CONTEXT_COUNT found)" $?

# Test 7: Scripts are executable
echo ""
echo "Testing file permissions..."

[ -x "$PROJECT_ROOT/bin/claude-dev" ]
test_check "claude-dev is executable" $?

[ -x "$PROJECT_ROOT/bin/claude-flow" ]
test_check "claude-flow is executable" $?

[ -x "$PROJECT_ROOT/bin/claude-health" ]
test_check "claude-health is executable" $?

[ -x "$PROJECT_ROOT/bin/git-commit-ai" ]
test_check "git-commit-ai is executable" $?

[ -x "$PROJECT_ROOT/bin/mcp-status" ]
test_check "mcp-status is executable" $?

# Test 8: JSON files are valid
echo ""
echo "Testing JSON validity..."

jq empty "$PROJECT_ROOT/mcp/config.json" 2>/dev/null
test_check "mcp/config.json is valid JSON" $?

jq empty "$PROJECT_ROOT/mcp/cache/claude-project-settings-template.json" 2>/dev/null
test_check "claude-project-settings-template.json is valid JSON" $?

# Test 9: Check bash syntax
echo ""
echo "Testing bash syntax..."

bash -n "$PROJECT_ROOT/install.sh" 2>/dev/null
test_check "install.sh has valid bash syntax" $?

bash -n "$PROJECT_ROOT/bin/claude-dev" 2>/dev/null
test_check "claude-dev has valid bash syntax" $?

bash -n "$PROJECT_ROOT/bin/claude-flow" 2>/dev/null
test_check "claude-flow has valid bash syntax" $?

bash -n "$PROJECT_ROOT/bin/git-commit-ai" 2>/dev/null
test_check "git-commit-ai has valid bash syntax" $?

# Test 10: Docker images can be pulled (if available)
echo ""
echo "Testing Docker images..."

if docker manifest inspect andreashurst/claude-docker:latest-dev &>/dev/null; then
    test_check "claude-docker:latest-dev manifest exists" 0
else
    echo -e "${YELLOW}⊘${NC} claude-docker:latest-dev not yet published (OK for dev)"
fi

if docker manifest inspect andreashurst/claude-docker:latest-flow &>/dev/null; then
    test_check "claude-docker:latest-flow manifest exists" 0
else
    echo -e "${YELLOW}⊘${NC} claude-docker:latest-flow not yet published (OK for dev)"
fi

# Summary
echo ""
echo "════════════════════════════════════════════════════════"
echo "  Test Results"
echo "════════════════════════════════════════════════════════"
echo ""
echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${RED}Failed: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi
