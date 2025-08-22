#!/bin/bash

# NPM uses temp directories - no setup needed

# Detect project type
if [ -d "/var/www/html/.ddev" ]; then
    PROJECT_TYPE="DDEV"
else
    PROJECT_TYPE="Standard"
fi

# Display project detection
echo "🎯 $PROJECT_TYPE project detected"

echo ""
echo 'Claude Dev Environment Starting...'
echo '================================='
echo 'Node.js version:' && node --version
echo 'NPM version:' && npm --version
echo 'Claude Code version:' && claude --version
echo ''

echo 'Network Configuration:'
echo '====================='
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

echo '✓ Claude Dev Environment ready!'
echo ''

echo '📖 Quick Start Guide:'
echo '===================='
echo '• claude "your prompt"           - Ask Claude anything'
echo '• claude --help                  - Show all Claude options'
echo '• claude auth login              - Login to Claude (if needed)'
echo '• ls                             - List files in your project'
echo '• git status                     - Check git status'
echo '• exit                           - Leave container'
echo ''
echo '💡 Your project is mounted at /var/www/html'
echo '💡 Changes persist on your host system'
echo ''

# Start interactive shell
exec /bin/bash