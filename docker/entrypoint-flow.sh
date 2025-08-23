#!/bin/bash

# Set PATH to include Deno
export PATH="/home/claude/.deno/bin:$PATH"

# Create aliases for Claude - secure by default
echo 'alias claude-insecure="/usr/bin/claude"' >> ~/.bashrc
echo 'alias claude="/usr/bin/claude --settings /home/claude/.claude/settings.local.json"' >> ~/.bashrc

echo '=============================================================================='
echo 'Claude Dev Environment Starting...'
echo '=============================================================================='
echo ''
# NPM uses temp directories - no setup needed

# Create Claude working directories based on settings.local.json
echo "📁 Setting up Claude working directories..."
mkdir -p /var/www/html/.claude/TMP
mkdir -p /var/www/html/.claude/PLAYWRIGHT
mkdir -p /var/www/html/.claude/PLAYWRIGHT/test-results
mkdir -p /var/www/html/.claude/PLAYWRIGHT/screenshots
mkdir -p /var/www/html/.claude/PLAYWRIGHT/tests
echo "✓ Claude directories created"

# Create Playwright aliases for convenience
echo 'alias screenshot="node /usr/local/bin/screenshot"' >> ~/.bashrc
echo 'alias playwright-test="cd /var/www/html/.claude/PLAYWRIGHT && playwright test"' >> ~/.bashrc
echo 'alias playwright-ui="cd /var/www/html/.claude/PLAYWRIGHT && playwright test --ui"' >> ~/.bashrc

# Detect project type
if [ -d "/var/www/html/.ddev" ]; then
    PROJECT_TYPE="DDEV"
else
    PROJECT_TYPE="Standard"
fi

# Display project detection
echo "🎯 $PROJECT_TYPE project detected"

echo ""
echo 'Node.js version:' && node --version
echo 'NPM version:' && npm --version
echo 'Deno version:' && deno --version 2>/dev/null || echo 'deno: not found in PATH'
echo 'Claude Code version:' && claude --version
echo 'Claude Flow version:' && claude-flow --version 2>/dev/null || echo 'claude-flow: v2.0.0-alpha.91 (AI orchestration)'
echo 'Playwright version:' && playwright --version
echo ''

echo '=============================================================================='
echo 'Network Configuration:'
echo '=============================================================================='
echo 'Host Gateway: host.docker.internal'
ping -c 1 host.docker.internal > /dev/null 2>&1 && echo '✓ Host connection: OK' || echo '✗ Host connection: FAILED'
echo ''

echo 'Services Configuration:'
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
echo ''

echo 'Checking Playwright browsers...'
npx playwright --version
echo 'Verifying browser installations...'
ls -la /home/claude/.cache/ms-playwright/ 2>/dev/null || echo 'Browser cache not found, will be created on first use'
echo ''

echo '=============================================================================='
echo 'MCP Servers Status:'
echo '=============================================================================='
echo '✓ Playwright MCP: @playwright/mcp'
echo '✓ Filesystem MCP: @modelcontextprotocol/server-filesystem'
echo '✓ Git MCP: mcp-server-git (Python)'
echo ''

echo '=============================================================================='
echo 'Playwright & Vite Integration:'
echo '=============================================================================='
echo '✓ Universal screenshot: screenshot <url> <output>'
echo '✓ Auto-detects: DDEV, Docker, or Local environment'
echo '✓ Test directory: /var/www/html/.claude/PLAYWRIGHT'
echo ''
echo '📸 Screenshot Usage:'
echo '  screenshot http://localhost screenshot.png'
echo '  → DDEV: Uses *.ddev.site domains'
echo '  → Docker: Uses host.docker.internal'
echo '  → Local: Direct localhost access'
echo ''
echo '🔗 Environment Detection:'
echo '  - DDEV: Automatically uses *.ddev.site domains'
echo '  - Docker: Rewrites to host.docker.internal'
echo '  - Local: Direct access (no rewriting needed)'
echo ''

echo '=============================================================================='
echo 'Claude Security Settings (DEFAULT):'
echo '=============================================================================='
echo '✓ Config file: /home/claude/.claude/settings.local.json'
echo '✓ Mode: SECURE by default (use claude-insecure for unrestricted)'
echo '✓ Blocked: git, sudo, rm -rf, system packages, chmod 777'
echo '✓ Allowed: npm, node, playwright, safe file operations'
echo '✓ Playwright test directory: /var/www/html/.claude/PLAYWRIGHT'
echo '✓ Temporary files: /var/www/html/.claude/TMP'
echo ''

echo '✓ Claude Flow Environment ready!'
echo ''

echo '=============================================================================='
echo '📖 Quick Start Guide:'
echo '=============================================================================='
echo '• claude                         - Claude CLI for chat (SECURE by default)'
echo '• claude-insecure                - Claude CLI (unrestricted mode)'
echo '• claude "your prompt"           - Ask Claude anything (secure mode)'
echo '• claude-flow init                - Initialize AI orchestration project'
echo '• claude-flow --help             - Show claude-flow commands'
echo '• screenshot <url> <file>        - Universal screenshot (auto-detect env)'
echo '• playwright codegen             - Generate Playwright tests'
echo '• playwright-test                - Run tests in .claude/PLAYWRIGHT'
echo '• playwright-ui                  - Run tests with UI mode'
echo '• deno run script.ts             - Run TypeScript with Deno'
echo '• python3 script.py             - Run Python scripts'
echo '• test-port 3000                 - Test host port connectivity'
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
