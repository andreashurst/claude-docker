#!/bin/bash

# Claude Flow Container Information Display
# This script shows useful information when logging into the Flow container

echo ""
echo '╔══════════════════════════════════════════════════╗'
echo '║         Claude Flow Development Environment      ║'
echo '╚══════════════════════════════════════════════════╝'
echo ""

echo "🚀 Environment: Claude Flow"
echo ""

echo '📦 Installed Tools:'
echo '==================='
echo -n '• Node.js: ' && node --version 2>/dev/null || echo 'not installed'
echo -n '• NPM: ' && npm --version 2>/dev/null || echo 'not installed'
echo -n '• Claude Code: ' && claude --version 2>/dev/null || echo 'not installed'
echo -n '• Claude Flow: ' && claude-flow --version 2>/dev/null || echo 'installed'
echo -n '• Deno: ' && deno --version 2>/dev/null | head -n1 || echo 'not installed'
echo -n '• Playwright: ' && playwright --version 2>/dev/null || echo 'not installed'
echo -n '• Python3: ' && python3 --version 2>/dev/null || echo 'not installed'

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
echo "• User: $(whoami) (uid=$(id -u))"

# Check for DDEV project
if [ -d "/var/www/html/.ddev" ] && [ -f "/var/www/html/.ddev/config.yaml" ]; then
    PROJECT_NAME=$(grep "^name:" /var/www/html/.ddev/config.yaml | cut -d' ' -f2 | tr -d '"' | head -n1)
    echo "• DDEV Project: $PROJECT_NAME"
fi

echo ""
echo '🎭 Playwright Browsers:'
echo '======================'
if [ -d "/home/claude/.cache/ms-playwright" ]; then
    echo "✓ Browsers installed at: ~/.cache/ms-playwright"
    ls -1 /home/claude/.cache/ms-playwright/ 2>/dev/null | grep -E "chromium|firefox|webkit" | while read browser; do
        echo "  • $browser"
    done
else
    echo "⚠ Browsers not installed. Run: npx playwright install"
fi

echo ""
echo '💡 Quick Commands:'
echo '=================='
echo '• claude "your prompt"     - Ask Claude anything'
echo '• claude-flow             - Start Claude Flow interface'
echo '• playwright codegen      - Generate Playwright tests'
echo '• playwright test         - Run Playwright tests'
echo '• deno run script.ts      - Run TypeScript with Deno'
echo '• python3 script.py       - Run Python scripts'
echo '• test-port <port>        - Test host port connectivity'
echo '• git status              - Check git status'
echo '• exit                    - Leave container'

echo ""
echo '🔌 MCP Servers Available:'
echo '========================='
echo '• @playwright/mcp                             - Browser automation'
echo '• @modelcontextprotocol/server-filesystem     - File system access'
echo '• mcp-server-git                              - Git operations'

echo ""
echo '💡 Type "claude-help" for detailed documentation'
echo ""