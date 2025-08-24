#!/bin/bash

# Extended help documentation for Claude containers

echo ""
echo '╔══════════════════════════════════════════════════╗'
echo '║      Claude Development Environment - Help       ║'
echo '╚══════════════════════════════════════════════════╝'
echo ""

echo '📚 CLAUDE CODE COMMANDS:'
echo '========================'
echo 'claude "prompt"           - Execute a prompt'
echo 'claude --help            - Show Claude Code help'
echo 'claude auth login        - Authenticate with Claude'
echo 'claude auth logout       - Log out from Claude'
echo 'claude auth status       - Check authentication status'
echo ""

if [ -f "/.claude-flow-env" ]; then
    echo '🌊 CLAUDE FLOW COMMANDS:'
    echo '========================'
    echo 'claude-flow              - Start Claude Flow interface'
    echo 'claude-flow --help       - Show Flow help'
    echo ""
    
    echo '🎭 PLAYWRIGHT COMMANDS:'
    echo '======================='
    echo 'playwright codegen       - Generate test code interactively'
    echo 'playwright test          - Run tests'
    echo 'playwright show-report   - Show HTML test report'
    echo 'npx playwright install   - Install/update browsers'
    echo ""
    
    echo '🦕 DENO COMMANDS:'
    echo '================='
    echo 'deno run script.ts       - Run TypeScript file'
    echo 'deno test               - Run Deno tests'
    echo 'deno fmt                - Format code'
    echo 'deno lint               - Lint code'
    echo ""
fi

echo '🔧 NETWORK TESTING:'
echo '==================='
echo 'ping host.docker.internal          - Test host connectivity'
echo 'test-port <port>                   - Test specific port'
echo 'test-host-connectivity              - Full connectivity test'
echo 'curl -I http://host.docker.internal:3000  - Test HTTP endpoint'
echo ""

echo '📁 FILE OPERATIONS:'
echo '==================='
echo 'ls                       - List files'
echo 'cd <directory>          - Change directory'
echo 'pwd                     - Show current directory'
echo 'cat <file>              - Display file contents'
echo 'nano <file>             - Edit file (if installed)'
echo 'vi <file>               - Edit file with vi'
echo ""

echo '🔀 GIT COMMANDS:'
echo '================'
echo 'git status              - Show repository status'
echo 'git log --oneline      - Show commit history'
echo 'git diff               - Show changes'
echo 'git add .              - Stage all changes'
echo 'git commit -m "msg"    - Commit changes'
echo ""

echo '🐳 CONTAINER INFO:'
echo '=================='
echo 'env                     - Show all environment variables'
echo 'which <command>        - Find command location'
echo 'ps aux                 - Show running processes'
echo 'df -h                  - Show disk usage'
echo 'free -h                - Show memory usage'
echo ""

echo '📍 IMPORTANT PATHS:'
echo '==================='
echo '/var/www/html          - Your project directory'
echo '/home/claude           - Claude user home'

if [ -f "/.claude-flow-env" ]; then
    echo '/home/claude/.cache/ms-playwright - Playwright browsers'
    echo '/home/claude/.deno     - Deno installation'
fi

echo ""
echo '💡 TIPS:'
echo '========'
echo '• Your project files are mounted from your host system'
echo '• Changes made in the container persist on your host'
echo '• Use host.docker.internal to access host services'
echo '• The container runs as user "claude" for security'
echo ""

if [ -n "$FRONTEND_URL" ]; then
    echo "📌 Your configured frontend URL: $FRONTEND_URL"
    echo ""
fi

echo 'For more information, visit the Claude documentation'
echo ""