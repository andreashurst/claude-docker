#!/bin/bash
# Test script for Docker development tools
# Part of claude-docker: https://github.com/andreashurst/claude-docker

echo "═══════════════════════════════════════════════════════════"
echo "      TESTING DOCKER DEVELOPMENT TOOLS"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TOTAL=0
PASSED=0
FAILED=0

# Test function
run_test() {
    local test_name="$1"
    local command="$2"
    local expected="${3:-pass}"
    
    TOTAL=$((TOTAL + 1))
    echo -n "Testing: $test_name... "
    
    if timeout 5 bash -c "$command" >/dev/null 2>&1; then
        if [ "$expected" = "pass" ]; then
            echo -e "${GREEN}✓ PASSED${NC}"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}✗ FAILED (expected failure)${NC}"
            FAILED=$((FAILED + 1))
        fi
    else
        if [ "$expected" = "fail" ]; then
            echo -e "${GREEN}✓ PASSED (expected failure)${NC}"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}✗ FAILED${NC}"
            FAILED=$((FAILED + 1))
        fi
    fi
}

echo "1. ENVIRONMENT DETECTION"
echo "────────────────────────────────────────"

if [ -f /.dockerenv ]; then
    echo -e "Environment: ${GREEN}Docker Container${NC}"
elif [ -n "$DOCKER_CONTAINER" ]; then
    echo -e "Environment: ${GREEN}Docker (env var)${NC}"
else
    echo -e "Environment: ${YELLOW}Not Docker${NC}"
fi

echo ""
echo "2. CURL WRAPPER TESTS"
echo "────────────────────────────────────────"

run_test "Curl wrapper exists" "test -x /usr/local/bin/curl-docker"
run_test "Curl version" "/usr/local/bin/curl-docker --version"
run_test "External HTTPS" "/usr/local/bin/curl-docker -s https://www.google.com"

# Test URL rewriting
echo -n "URL rewriting test: "
if [ -f /.dockerenv ] || [ -n "$DOCKER_CONTAINER" ]; then
    echo -e "${GREEN}localhost → host.docker.internal${NC}"
else
    echo -e "${YELLOW}No rewriting (not in Docker)${NC}"
fi

echo ""
echo "3. PLAYWRIGHT WRAPPER TESTS"
echo "────────────────────────────────────────"

run_test "Playwright wrapper exists" "test -x /usr/local/bin/playwright-docker"
run_test "Node.js available" "test -x /usr/local/bin/node"
run_test "Playwright CLI exists" "test -f /usr/local/lib/node_modules/playwright/cli.js"

if [ -x "/usr/local/bin/playwright-docker" ]; then
    run_test "Playwright version" "/usr/local/bin/playwright-docker --version"
fi

echo ""
echo "4. VITE HMR PROXY TESTS"
echo "────────────────────────────────────────"

run_test "HMR proxy exists" "test -f /usr/local/bin/vite-hmr-proxy.cjs"
run_test "Proxy is executable" "test -x /usr/local/bin/vite-hmr-proxy.cjs"

echo ""
echo "5. BROWSER INSTALLATION"
echo "────────────────────────────────────────"

if [ -d "/home/claude/.cache/ms-playwright" ]; then
    BROWSERS=$(ls /home/claude/.cache/ms-playwright 2>/dev/null | wc -l)
    if [ "$BROWSERS" -gt 0 ]; then
        echo -e "Playwright browsers: ${GREEN}Installed ($BROWSERS found)${NC}"
    else
        echo -e "Playwright browsers: ${YELLOW}Directory exists but empty${NC}"
    fi
else
    echo -e "Playwright browsers: ${RED}Not installed${NC}"
    echo "  Run: npx playwright install chromium"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "                    TEST SUMMARY"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Total Tests: $TOTAL"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ All tests passed successfully!${NC}"
    exit 0
else
    echo ""
    echo -e "${YELLOW}⚠ Some tests failed${NC}"
    exit 1
fi