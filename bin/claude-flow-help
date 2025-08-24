#!/bin/bash

# Extended help documentation for Claude Flow containers

echo ""
echo '╔══════════════════════════════════════════════════╗'
echo '║   Claude Flow Development Environment - Help     ║'
echo '╚══════════════════════════════════════════════════╝'
echo ""

echo '🌊 CLAUDE FLOW OVERVIEW:'
echo '========================'
echo 'Claude Flow provides an enhanced development environment with:'
echo '• Claude Code AI assistant'
echo '• Claude Flow interface for interactive development'
echo '• Playwright for browser automation and testing'
echo '• Deno for TypeScript execution'
echo '• Python 3 for scripting'
echo '• MCP servers for enhanced capabilities'
echo ""

echo '📚 CLAUDE CODE COMMANDS:'
echo '========================'
echo 'claude "prompt"           - Execute a prompt'
echo 'claude --help            - Show Claude Code help'
echo 'claude auth login        - Authenticate with Claude'
echo 'claude auth logout       - Log out from Claude'
echo 'claude auth status       - Check authentication status'
echo 'claude mcp add <server>  - Add an MCP server'
echo 'claude mcp list          - List configured MCP servers'
echo ""

echo '🌊 CLAUDE FLOW COMMANDS:'
echo '========================'
echo 'claude-flow              - Start Claude Flow interface'
echo 'claude-flow --help       - Show Flow help'
echo 'claude-flow --version    - Show Flow version'
echo ""

echo '🎭 PLAYWRIGHT COMMANDS:'
echo '======================='
echo 'playwright codegen       - Generate test code interactively'
echo 'playwright test          - Run all tests'
echo 'playwright test <file>   - Run specific test file'
echo 'playwright show-report   - Show HTML test report'
echo 'playwright --help        - Show all Playwright options'
echo ''
echo 'Browser Management:'
echo 'npx playwright install              - Install all browsers'
echo 'npx playwright install chromium     - Install Chromium only'
echo 'npx playwright install --with-deps  - Install with dependencies'
echo ""

echo '🦕 DENO COMMANDS:'
echo '================='
echo 'deno run script.ts       - Run TypeScript file'
echo 'deno run --allow-all script.ts  - Run with all permissions'
echo 'deno test               - Run Deno tests'
echo 'deno fmt                - Format code'
echo 'deno lint               - Lint code'
echo 'deno compile script.ts  - Compile to executable'
echo 'deno repl               - Start REPL'
echo ""

echo '🐍 PYTHON COMMANDS:'
echo '==================='
echo 'python3 script.py       - Run Python script'
echo 'python3 -m pip install  - Install Python packages'
echo 'python3 -c "code"       - Execute Python code'
echo 'python3                 - Start Python REPL'
echo ""

echo '🔌 MCP SERVER MANAGEMENT:'
echo '========================='
echo 'Available MCP Servers:'
echo '• @playwright/mcp - Browser automation capabilities'
echo '• @modelcontextprotocol/server-filesystem - File system operations'
echo '• mcp-server-git - Git repository operations'
echo ''
echo 'Adding MCP servers to Claude:'
echo 'claude mcp add playwright npx @playwright/mcp'
echo 'claude mcp add filesystem npx @modelcontextprotocol/server-filesystem /path'
echo 'claude mcp add git python3 -m mcp_server_git --repo /path/to/repo'
echo ""

echo '🔧 NETWORK TESTING:'
echo '==================='
echo 'ping host.docker.internal          - Test host connectivity'
echo 'test-port <port>                   - Test specific port'
echo 'test-host-connectivity              - Full connectivity test'
echo 'curl -I http://host.docker.internal:3000  - Test HTTP endpoint'
echo ''
echo 'Common host services:'
echo '• host.docker.internal:3000  - Next.js/React dev server'
echo '• host.docker.internal:5173  - Vite dev server'
echo '• host.docker.internal:4200  - Angular dev server'
echo '• host.docker.internal:8000  - Backend API server'
echo '• host.docker.internal:5432  - PostgreSQL database'
echo '• host.docker.internal:3306  - MySQL database'
echo ""

echo '📁 FILE OPERATIONS:'
echo '==================='
echo 'ls -la                  - List all files with details'
echo 'cd <directory>          - Change directory'
echo 'pwd                     - Show current directory'
echo 'cat <file>              - Display file contents'
echo 'nano <file>             - Edit file (if installed)'
echo 'vi <file>               - Edit file with vi'
echo 'mkdir -p <path>         - Create directory structure'
echo 'rm -rf <path>           - Remove files/directories'
echo 'cp -r <src> <dst>       - Copy files/directories'
echo 'mv <src> <dst>          - Move/rename files'
echo ""

echo '🔀 GIT COMMANDS:'
echo '================'
echo 'git status              - Show repository status'
echo 'git log --oneline -10   - Show recent commits'
echo 'git diff                - Show unstaged changes'
echo 'git diff --staged       - Show staged changes'
echo 'git add .               - Stage all changes'
echo 'git commit -m "msg"     - Commit changes'
echo 'git push                - Push to remote'
echo 'git pull                - Pull from remote'
echo 'git branch              - List branches'
echo 'git checkout <branch>   - Switch branches'
echo ""

echo '🐳 CONTAINER INFO:'
echo '=================='
echo 'env | grep FRONTEND     - Show frontend URL config'
echo 'env | grep PATH         - Show PATH configuration'
echo 'which <command>         - Find command location'
echo 'ps aux                  - Show running processes'
echo 'df -h                   - Show disk usage'
echo 'free -h                 - Show memory usage'
echo 'id                      - Show user info'
echo ""

echo '📍 IMPORTANT PATHS:'
echo '==================='
echo '/var/www/html                     - Your project directory'
echo '/home/claude                      - Claude user home'
echo '/home/claude/.cache/ms-playwright - Playwright browsers'
echo '/home/claude/.deno                - Deno installation'
echo '/home/claude/.claude              - Claude configuration'
echo '/usr/local/bin                    - Global executables'
echo ""

echo '💡 TIPS & TRICKS:'
echo '================='
echo '• Use Tab for command/path completion'
echo '• Use Ctrl+R to search command history'
echo '• Use Ctrl+C to cancel running commands'
echo '• Use Ctrl+D or "exit" to leave the container'
echo '• Your project files persist on the host system'
echo '• Changes in /var/www/html are reflected on host'
echo '• Use host.docker.internal to access host services'
echo '• The container runs as user "claude" for security'
echo ""

echo '🔍 TROUBLESHOOTING:'
echo '==================='
echo 'If Playwright tests fail:'
echo '  npx playwright install --with-deps'
echo ''
echo 'If host connection fails:'
echo '  test-host-connectivity'
echo '  docker network ls'
echo ''
echo 'If permissions are denied:'
echo '  Check file ownership: ls -la'
echo '  Container user: id'
echo ""

if [ -n "$FRONTEND_URL" ]; then
    echo "📌 Your configured frontend URL: $FRONTEND_URL"
    echo ""
fi

echo 'For more information, visit:'
echo '• Claude Documentation: https://claude.ai/docs'
echo '• Playwright Docs: https://playwright.dev'
echo '• Deno Manual: https://deno.land/manual'
echo ""