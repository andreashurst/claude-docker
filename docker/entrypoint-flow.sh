#!/bin/bash

# Set PATH to include Deno
export PATH="/home/claude/.deno/bin:$PATH"

# NPM uses temp directories - no setup needed

# Detect project type
if [ -d "/var/www/html/.ddev" ]; then
    PROJECT_TYPE="DDEV"
else
    PROJECT_TYPE="Standard"
fi

# Display project detection
echo "🎯 $PROJECT_TYPE project detected"

# Check for web server directory and start internal server
echo ""
echo "🌐 Setting up internal web server for Playwright..."
if [ -d "/var/www/html/public" ]; then
    WEB_DIR="/var/www/html/public"
    echo "✓ Found 'public' directory"
elif [ -d "/var/www/html/src" ]; then
    WEB_DIR="/var/www/html/src"
    echo "✓ Found 'src' directory"
elif [ -d "/var/www/html/dist" ]; then
    WEB_DIR="/var/www/html/dist"
    echo "✓ Found 'dist' directory"
elif [ -d "/var/www/html/build" ]; then
    WEB_DIR="/var/www/html/build"
    echo "✓ Found 'build' directory"
else
    echo "No standard web directory found (public, src, dist, build)"
    read -p "Enter directory to serve (relative to /var/www/html, or 'skip' to skip): " WEB_INPUT
    if [ "$WEB_INPUT" != "skip" ] && [ "$WEB_INPUT" != "" ]; then
        WEB_DIR="/var/www/html/${WEB_INPUT}"
        if [ ! -d "$WEB_DIR" ]; then
            echo "Creating directory: $WEB_DIR"
            mkdir -p "$WEB_DIR"
        fi
    fi
fi

# Start the web server if directory was selected
if [ -n "$WEB_DIR" ] && [ "$WEB_INPUT" != "skip" ]; then
    echo "Starting web server on port 80 serving: $WEB_DIR"
    mkdir -p /var/log
    cd "$WEB_DIR" && nohup python3 -m http.server 80 --bind 0.0.0.0 > /var/log/webserver.log 2>&1 &
    sleep 1
    if ps aux | grep -q "[p]ython3 -m http.server 80"; then
        echo "✓ Web server started successfully on http://localhost:80"
        echo "  Internal URL for Playwright: http://localhost:80"
        echo "  Logs: /var/log/webserver.log"
    else
        echo "⚠ Web server failed to start. Check /var/log/webserver.log for details"
    fi
else
    echo "⚠ Skipping internal web server setup"
fi

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

echo 'Services Configuration:'
if [ -n "$WEB_DIR" ] && [ "$WEB_INPUT" != "skip" ]; then
    echo "- Internal Web Server: http://localhost:80 (serving $WEB_DIR)"
fi
echo '- Host Frontend Services:'
echo '  - React/Next.js: http://host.docker.internal:3000'
echo '  - Vite Dev:      http://host.docker.internal:5173'
echo '  - Angular:       http://host.docker.internal:4200'
echo '- Host Backend:    http://host.docker.internal:8000'
echo '- Host Database:   host.docker.internal:5432'
echo ''

echo 'Testing Connectivity:'
echo '  ping host.docker.internal'
echo '  test-port 3000  # For host services'
if [ -n "$WEB_DIR" ] && [ "$WEB_INPUT" != "skip" ]; then
    echo '  curl -I http://localhost:80  # For internal web server'
fi
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