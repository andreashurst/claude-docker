#!/bin/bash

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