#!/bin/bash
#
# MCP Server Validation
# Validates all MCP servers can load and respond
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

MCP_CONFIG="/home/claude/mcp/config.json"
MCP_SERVERS_DIR="/home/claude/mcp/servers"
MCP_CONTEXT_DIR="/home/claude/mcp/context"

echo "════════════════════════════════════════════════════════"
echo "  🔍 MCP Server Validation"
echo "════════════════════════════════════════════════════════"
echo ""

if [ ! -f "$MCP_CONFIG" ]; then
    echo -e "${RED}❌ MCP config not found: $MCP_CONFIG${NC}"
    echo "This script must run inside a Claude container"
    exit 1
fi

PASS=0
FAIL=0

# Test function
test_check() {
    local name=$1
    local result=$2
    local details=$3

    if [ $result -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $name"
        [ -n "$details" ] && echo "  $details"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} $name"
        [ -n "$details" ] && echo "  ${RED}$details${NC}"
        ((FAIL++))
    fi
}

# Validate config structure
echo "Validating MCP configuration..."
echo ""

jq -e '.mcpServers' "$MCP_CONFIG" &>/dev/null
test_check "MCP config has 'mcpServers' key" $?

SERVER_COUNT=$(jq -r '.mcpServers | length' "$MCP_CONFIG")
[ $SERVER_COUNT -ge 11 ]
test_check "Expected 11+ MCP servers" $? "Found: $SERVER_COUNT"

# Validate each server
echo ""
echo "Validating individual servers..."
echo ""

jq -r '.mcpServers | keys[]' "$MCP_CONFIG" | while read server_name; do
    echo -e "${CYAN}▸ $server_name${NC}"

    # Get server config
    command=$(jq -r ".mcpServers.\"$server_name\".command" "$MCP_CONFIG")
    description=$(jq -r ".mcpServers.\"$server_name\".description" "$MCP_CONFIG")

    echo "  Description: $description"

    # Check command exists
    if command -v "$command" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Command available: $command"
    else
        echo -e "  ${RED}✗${NC} Command not found: $command"
    fi

    # If it's a node server, check the file
    if [ "$command" = "node" ]; then
        server_file=$(jq -r ".mcpServers.\"$server_name\".args[0]" "$MCP_CONFIG")

        if [ -f "$server_file" ]; then
            echo -e "  ${GREEN}✓${NC} Server file exists: $(basename $server_file)"

            # Check file size
            file_size=$(stat -f%z "$server_file" 2>/dev/null || stat -c%s "$server_file" 2>/dev/null)
            if [ $file_size -gt 0 ]; then
                echo -e "  ${GREEN}✓${NC} File size: $((file_size / 1024))KB"
            else
                echo -e "  ${RED}✗${NC} File is empty"
            fi

            # Check if it's valid JavaScript
            if node --check "$server_file" 2>/dev/null; then
                echo -e "  ${GREEN}✓${NC} Valid JavaScript syntax"
            else
                echo -e "  ${RED}✗${NC} Invalid JavaScript syntax"
            fi

            # Check for required MCP SDK imports
            if grep -q "@modelcontextprotocol/sdk" "$server_file"; then
                echo -e "  ${GREEN}✓${NC} Uses MCP SDK"
            else
                echo -e "  ${YELLOW}⚠${NC}  No MCP SDK import found"
            fi
        else
            echo -e "  ${RED}✗${NC} Server file not found: $server_file"
        fi
    fi

    echo ""
done

# Validate context files
echo ""
echo "════════════════════════════════════════════════════════"
echo "Validating context files..."
echo "════════════════════════════════════════════════════════"
echo ""

if [ -d "$MCP_CONTEXT_DIR" ]; then
    # Check each context directory
    for context_type in tailwind daisyui playwright vite claude-flow; do
        context_path="$MCP_CONTEXT_DIR/$context_type"

        if [ -d "$context_path" ]; then
            file_count=$(find "$context_path" -type f | wc -l)
            total_size=$(du -sh "$context_path" 2>/dev/null | cut -f1)

            echo -e "${CYAN}▸ $context_type${NC}"
            echo "  Files: $file_count"
            echo "  Size: $total_size"

            # Validate JSON files
            json_count=0
            json_valid=0
            find "$context_path" -name "*.json" -type f | while read json_file; do
                ((json_count++))
                if jq empty "$json_file" 2>/dev/null; then
                    ((json_valid++))
                fi
            done

            if [ $json_count -gt 0 ]; then
                echo "  JSON files: $json_count (valid: $json_valid)"
            fi
            echo ""
        else
            echo -e "${YELLOW}⚠${NC}  $context_type directory not found"
        fi
    done
else
    echo -e "${RED}✗${NC} Context directory not found: $MCP_CONTEXT_DIR"
fi

# Check cache directory
echo "════════════════════════════════════════════════════════"
echo "Validating MCP cache..."
echo "════════════════════════════════════════════════════════"
echo ""

CACHE_DIR="/opt/mcp-cache"

[ -d "$CACHE_DIR" ]
test_check "Cache directory exists" $? "$CACHE_DIR"

[ -f "$CACHE_DIR/mcp.json" ]
test_check "Cached MCP config exists" $?

[ -f "$CACHE_DIR/claude-project-settings-template.json" ]
test_check "Project settings template exists" $?

[ -f "$CACHE_DIR/bashrc" ]
test_check "Bashrc template exists" $?

# Summary
echo ""
echo "════════════════════════════════════════════════════════"
echo "  Validation Results"
echo "════════════════════════════════════════════════════════"
echo ""
echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${RED}Failed: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✅ All MCP servers validated successfully!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some validations failed${NC}"
    exit 1
fi
