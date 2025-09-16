#!/bin/bash

# MCP Initialization Script for Claude Docker
# This script sets up MCP configuration files in the proper locations

echo "🔧 Initializing MCP configuration..."

# Create necessary directories
mkdir -p /home/claude/.claude/plugins
mkdir -p /home/claude/.claude/context
mkdir -p /home/claude/.claude/databases
mkdir -p /etc/claude
mkdir -p /opt/mcp-cache

# Copy main MCP configuration
if [ -f /var/www/html/docker/mcp.json ]; then
    echo "📋 Installing MCP configuration..."

    # Copy to all required locations
    cp /var/www/html/docker/mcp.json /etc/claude/mcp.json
    cp /var/www/html/docker/mcp.json /opt/mcp-cache/mcp.json
    cp /var/www/html/docker/mcp.json /home/claude/.claude/plugins/mcp.json

    # Set proper permissions
    chmod 644 /etc/claude/mcp.json
    chmod 644 /opt/mcp-cache/mcp.json
    chmod 644 /home/claude/.claude/plugins/mcp.json

    echo "✅ MCP configuration installed"
else
    echo "⚠️  No mcp.json found in /var/www/html/docker/"
fi

# Setup context files
if [ -d /var/www/html/claude/context ]; then
    echo "📋 Installing context files..."

    for context_file in /var/www/html/claude/context/*.json; do
        if [ -f "$context_file" ]; then
            filename=$(basename "$context_file")
            cp "$context_file" "/home/claude/.claude/context/$filename"
            echo "   ✓ Installed $filename"
        fi
    done
fi

# Setup custom MCP servers
if [ -d /var/www/html/claude/mcp-servers ]; then
    echo "📋 Setting up custom MCP servers..."
    chmod +x /var/www/html/claude/mcp-servers/*.js 2>/dev/null || true
    echo "✅ Custom MCP servers ready"
fi

# Ensure proper ownership
chown -R claude:claude /home/claude/.claude

# Create a config.json for Claude plugins if it doesn't exist
if [ ! -f /home/claude/.claude/plugins/config.json ]; then
    echo '{"mcpEnabled": true}' > /home/claude/.claude/plugins/config.json
    chown claude:claude /home/claude/.claude/plugins/config.json
fi

echo "✅ MCP initialization complete!"
echo ""
echo "📝 MCP configuration locations:"
echo "   - /home/claude/.claude/plugins/mcp.json (primary)"
echo "   - /etc/claude/mcp.json (system backup)"
echo "   - /opt/mcp-cache/mcp.json (cache)"
echo ""
echo "🔍 To verify MCP servers, run: claude mcp"