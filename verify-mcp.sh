#!/bin/bash

echo "🔍 Verifying MCP Configuration in Docker Images"
echo "================================================"
echo ""

# Check if claude command exists
if command -v claude >/dev/null 2>&1; then
    echo "✅ Claude CLI is installed"

    # Check MCP servers
    echo ""
    echo "📋 Checking MCP servers:"
    claude mcp list

    # Check if .claude.json exists
    if [ -f ~/.claude.json ]; then
        echo ""
        echo "✅ Claude configuration file exists"
        echo "   Path: ~/.claude.json"

        # Count configured MCP servers
        SERVER_COUNT=$(grep -c '"type": "stdio"' ~/.claude.json 2>/dev/null || echo "0")
        echo "   Configured MCP servers: $SERVER_COUNT"
    else
        echo ""
        echo "⚠️  No .claude.json found - MCP servers will be auto-configured on first run"
    fi

    # Check pre-cached template
    if [ -f ~/.claude-template.json ]; then
        echo ""
        echo "✅ Pre-cached MCP template found"
        echo "   Path: ~/.claude-template.json"
    fi

    # Check MCP server binaries
    echo ""
    echo "📦 Checking MCP server binaries:"

    # Node-based servers
    if [ -f /usr/local/lib/node_modules/@modelcontextprotocol/server-filesystem/dist/index.js ]; then
        echo "   ✅ filesystem server installed"
    else
        echo "   ❌ filesystem server missing"
    fi

    if [ -f /usr/local/lib/node_modules/@modelcontextprotocol/server-memory/dist/index.js ]; then
        echo "   ✅ memory server installed"
    else
        echo "   ❌ memory server missing"
    fi

    # Python servers
    if command -v mcp-server-git >/dev/null 2>&1; then
        echo "   ✅ git server installed"
    else
        echo "   ❌ git server missing"
    fi

    if command -v mcp-server-sqlite >/dev/null 2>&1 || [ -f ~/.local/bin/mcp-server-sqlite ]; then
        echo "   ✅ sqlite server installed"
    else
        echo "   ❌ sqlite server missing"
    fi

    # Custom servers
    if [ -f /var/www/html/mcp/servers/webserver-env.js ]; then
        echo "   ✅ webserver-env server available"
    else
        echo "   ⚠️  webserver-env server not found (project-specific)"
    fi

    echo ""
    echo "🎯 MCP Configuration Status:"
    if [ "$SERVER_COUNT" -ge "4" ]; then
        echo "   ✅ All MCP servers are configured and ready!"
    elif [ -f ~/.claude-template.json ]; then
        echo "   ✅ MCP servers will be auto-configured from cache on first run"
    else
        echo "   ⚠️  MCP servers need configuration - run 'claude mcp add' to configure"
    fi

else
    echo "❌ Claude CLI not found!"
    echo "   Please ensure the Docker image was built correctly"
fi

echo ""
echo "================================================"
echo "📝 To manually configure MCP servers, run:"
echo "   claude mcp add filesystem node /usr/local/lib/node_modules/@modelcontextprotocol/server-filesystem/dist/index.js /var/www/html"
echo "   claude mcp add memory node /usr/local/lib/node_modules/@modelcontextprotocol/server-memory/dist/index.js"
echo "   claude mcp add git mcp-server-git -- --repository /var/www/html"
echo "   claude mcp add sqlite mcp-server-sqlite -- --db-path ~/.claude/databases/main.db"