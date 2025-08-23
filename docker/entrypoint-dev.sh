#!/bin/bash

# NPM uses temp directories - no setup needed

# Create aliases for Claude - secure by default
echo 'alias claude-insecure="/usr/bin/claude"' >> ~/.bashrc
echo 'alias claude="/usr/bin/claude --settings /home/claude/.claude/settings.local.json"' >> ~/.bashrc

echo '=============================================================================='
echo 'Claude Dev Environment Starting...'
echo '=============================================================================='
echo ''
# Detect project type
if [ -d "/var/www/html/.ddev" ]; then
    PROJECT_TYPE="DDEV"
else
    PROJECT_TYPE="Standard"
fi

echo 'Node.js version:' && node --version
echo 'NPM version:' && npm --version
echo 'Claude Code version:' && claude --version
echo ''

echo '=============================================================================='
echo 'Network Configuration:'
echo '=============================================================================='
echo 'Host Gateway: host.docker.internal'
ping -c 1 host.docker.internal > /dev/null 2>&1 && echo '✓ Host connection: OK' || echo '✗ Host connection: FAILED'
echo ''

echo 'Host Services Configuration:'
echo '- Frontend Services:'
echo '  - React/Next.js: http://host.docker.internal:3000'
echo '  - Vite Dev:      http://host.docker.internal:5173'
echo '  - Angular:       http://host.docker.internal:4200'
echo '- Backend:         http://host.docker.internal:8000'
echo '- Database:        host.docker.internal:5432'
echo ''

echo 'Testing Host Connectivity:'
echo '  ping host.docker.internal'
echo '  test-port 3000'
echo '  curl -I http://host.docker.internal:3000'
echo ''

echo '=============================================================================='
echo 'Claude Security Settings (DEV MODE):'
echo '=============================================================================='
echo '✓ Config file: /home/claude/.claude/settings.local.json'
echo '✓ Mode: SECURE by default (use claude-insecure for unrestricted)'
echo '✓ Blocked: sudo, rm -rf /*, chmod 777 /*, systemctl'
echo '✓ Allowed: git, npm, node, all safe file operations'
echo ''

echo '✓ Claude Dev Environment ready!'
echo ''

echo '=============================================================================='
echo '📖 Quick Start Guide:'
echo '=============================================================================='
echo '• claude                         - Claude shell (SECURE by default)'
echo '• claude-insecure                - Claude shell (unrestricted mode)'
echo '• claude "your prompt"           - Ask Claude anything (secure mode)'
echo '• claude --help                  - Show all Claude options'
echo '• claude auth login              - Login to Claude (if needed)'
echo '• ls                             - List files in your project'
echo '• git status                     - Check git status'
echo '• exit                           - Leave container'
echo ''
echo '🔒 Security Mode: Lighter restrictions than claude-flow'
echo '   ✓ Git commands allowed'
echo '   ✗ Sudo and dangerous rm commands blocked'
echo ''
echo '💡 Your project is mounted at /var/www/html'
echo '💡 Changes persist on your host system'
echo ''

# Start interactive shell
exec /bin/bash
