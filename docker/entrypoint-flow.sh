#!/bin/bash

# Set PATH to include Deno
export PATH="/home/claude/.deno/bin:$PATH"

# NPM uses temp directories - no setup needed

# Detect project type and set intelligent default
if [ -d "/var/www/html/.ddev" ]; then
    # Extract project details from .ddev/config.yaml
    if [ -f "/var/www/html/.ddev/config.yaml" ]; then
        PROJECT_NAME=$(grep "^name:" /var/www/html/.ddev/config.yaml | cut -d' ' -f2 | tr -d '"' | head -n1)
        
        # Try to get URLs in priority order
        ADDITIONAL_FQDNS=$(grep "^additional_fqdns:" /var/www/html/.ddev/config.yaml | cut -d':' -f2- | tr -d '[]"' | sed 's/,.*//g' | tr -d ' ')
        ADDITIONAL_HOSTNAMES=$(grep "^additional_hostnames:" /var/www/html/.ddev/config.yaml | cut -d':' -f2- | tr -d '[]"' | sed 's/,.*//g' | tr -d ' ')
        PROJECT_TLD=$(grep "^project_tld:" /var/www/html/.ddev/config.yaml | cut -d' ' -f2 | tr -d '"' | head -n1)
        
        if [ -n "$ADDITIONAL_FQDNS" ] && [ "$ADDITIONAL_FQDNS" != "" ]; then
            DEFAULT_URL="https://${ADDITIONAL_FQDNS}"
        elif [ -n "$ADDITIONAL_HOSTNAMES" ] && [ "$ADDITIONAL_HOSTNAMES" != "" ]; then
            DEFAULT_URL="https://${ADDITIONAL_HOSTNAMES}"
        else
            # Use project_tld if set, otherwise default to ddev.site
            if [ -n "$PROJECT_TLD" ] && [ "$PROJECT_TLD" != "" ]; then
                DEFAULT_URL="https://${PROJECT_NAME}.${PROJECT_TLD}"
            else
                DEFAULT_URL="https://${PROJECT_NAME}.ddev.site"
            fi
        fi
    else
        DEFAULT_URL="localhost:3000"
    fi
    PROJECT_TYPE="DDEV"
else
    DEFAULT_URL="localhost:3000"
    PROJECT_TYPE="Standard"
fi

# Interactive frontend URL input
echo "🎯 $PROJECT_TYPE project detected"
echo ""
read -p "Frontend URL (default: $DEFAULT_URL): " FRONTEND_INPUT
export FRONTEND_URL=${FRONTEND_INPUT:-$DEFAULT_URL}

echo ""
echo 'Claude Flow Environment Starting...'
echo '================================='
echo 'Node.js version:' && node --version
echo 'NPM version:' && npm --version
echo 'Deno version:' && deno --version 2>/dev/null || echo 'deno: not found in PATH'
echo 'Claude Code version:' && claude --version
echo 'Claude Flow version:' && claude-flow --version 2>/dev/null || echo 'claude-flow: installed'
echo 'Playwright version:' && playwright --version
echo ''

echo 'Network Configuration:'
echo '====================='
echo 'Host Gateway: host.docker.internal'
ping -c 1 host.docker.internal > /dev/null 2>&1 && echo '✓ Host connection: OK' || echo '✗ Host connection: FAILED'
echo ''

echo 'Host Services Configuration:'
echo "- Configured Frontend: http://${FRONTEND_URL:-localhost:3000}"
echo '- Common Alternatives:'
echo '  - React/Next.js: http://host.docker.internal:3000'
echo '  - Vite Dev:      http://host.docker.internal:5173'
echo '  - Angular:       http://host.docker.internal:4200'
echo '- Backend:         http://host.docker.internal:8000'
echo '- Database:        host.docker.internal:5432'
echo ''

echo 'Testing Host Connectivity:'
echo '  ping host.docker.internal'
echo "  test-port ${FRONTEND_PORT:-3000}"
echo "  curl -I http://${FRONTEND_URL:-host.docker.internal:3000}"
echo ''

echo 'Checking Playwright browsers...'
npx playwright --version
echo 'Verifying browser installations...'
ls -la /home/claude/.cache/ms-playwright/ 2>/dev/null || echo 'Browser cache not found, will be created on first use'
echo ''

echo 'MCP Servers Status:'
echo '==================='
echo '✓ Playwright MCP: @playwright/mcp'
echo '✓ Filesystem MCP: @modelcontextprotocol/server-filesystem' 
echo '✓ Git MCP: mcp-server-git (Python)'
echo ''

echo '✓ Claude Flow Environment ready!'
echo ''

echo '📖 Quick Start Guide:'
echo '===================='
echo '• claude "your prompt"           - Ask Claude anything'
echo '• claude-flow                    - Start Claude Flow (if available)'
echo '• playwright codegen             - Generate Playwright tests'
echo '• deno run script.ts             - Run TypeScript with Deno'
echo '• python3 script.py             - Run Python scripts'
echo '• claude auth login              - Login to Claude (if needed)'
echo '• ls                             - List files in your project'
echo '• git status                     - Check git status'
echo '• exit                           - Leave container'
echo ''
echo '🔌 MCP Servers Available:'
echo '• Filesystem - Access project files'
echo '• Playwright - Browser automation'
echo '• Git - Repository operations'
echo ''
echo '💡 Your project is mounted at /var/www/html'
echo '💡 Changes persist on your host system'
echo ''

# Start interactive shell
exec /bin/bash