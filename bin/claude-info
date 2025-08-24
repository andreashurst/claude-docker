#!/bin/bash

# Claude Container Information Display
# This script shows useful information when logging into the container

echo ""
echo '╔══════════════════════════════════════════════════╗'
echo '║         Claude Development Environment           ║'
echo '╚══════════════════════════════════════════════════╝'
echo ""

# Show environment type
if [ -f "/.claude-flow-env" ]; then
    ENV_TYPE="Claude Flow"
    echo "🚀 Environment: $ENV_TYPE"
elif [ -f "/.claude-dev-env" ]; then
    ENV_TYPE="Claude Dev"
    echo "🚀 Environment: $ENV_TYPE"
else
    echo "🚀 Environment: Claude Container"
fi

echo ""
echo '📦 Installed Tools:'
echo '==================='
echo -n '• Node.js: ' && node --version 2>/dev/null || echo 'not installed'
echo -n '• NPM: ' && npm --version 2>/dev/null || echo 'not installed'
echo -n '• Claude Code: ' && claude --version 2>/dev/null || echo 'not installed'

# Check for Flow-specific tools
if [ -f "/.claude-flow-env" ]; then
    echo -n '• Claude Flow: ' && claude-flow --version 2>/dev/null || echo 'installed'
    echo -n '• Deno: ' && deno --version 2>/dev/null | head -n1 || echo 'not installed'
    echo -n '• Playwright: ' && playwright --version 2>/dev/null || echo 'not installed'
    echo -n '• Python3: ' && python3 --version 2>/dev/null || echo 'not installed'
fi

echo ""
echo '🌐 Network Status:'
echo '=================='
ping -c 1 host.docker.internal > /dev/null 2>&1 && echo '✓ Host connection: OK' || echo '✗ Host connection: FAILED'

# Show configured frontend URL if available
if [ -n "$FRONTEND_URL" ]; then
    echo "✓ Frontend URL: $FRONTEND_URL"
fi

echo ""
echo '📂 Project Location:'
echo '===================='
echo "• Working directory: $(pwd)"
echo "• Project mounted at: /var/www/html"

# Check for DDEV project
if [ -d "/var/www/html/.ddev" ] && [ -f "/var/www/html/.ddev/config.yaml" ]; then
    PROJECT_NAME=$(grep "^name:" /var/www/html/.ddev/config.yaml | cut -d' ' -f2 | tr -d '"' | head -n1)
    echo "• DDEV Project: $PROJECT_NAME"
fi

echo ""
echo '💡 Quick Commands:'
echo '=================='
echo '• claude "your prompt"     - Ask Claude anything'
echo '• claude --help           - Show all Claude options'

if [ -f "/.claude-flow-env" ]; then
    echo '• claude-flow             - Start Claude Flow'
    echo '• playwright codegen      - Generate Playwright tests'
    echo '• deno run script.ts      - Run TypeScript with Deno'
    echo '• python3 script.py       - Run Python scripts'
fi

echo '• test-port <port>        - Test host port connectivity'
echo '• git status              - Check git status'
echo '• exit                    - Leave container'

# Show MCP servers if Flow environment
if [ -f "/.claude-flow-env" ]; then
    echo ""
    echo '🔌 MCP Servers:'
    echo '==============='
    echo '• Filesystem - Access project files'
    echo '• Playwright - Browser automation'
    echo '• Git - Repository operations'
fi

echo ""
echo '💡 Type "claude-help" for detailed documentation'
echo ""