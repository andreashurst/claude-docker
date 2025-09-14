#!/bin/bash

# Claude Dev Container Entrypoint - KISS Edition
# Auto-maps localhost, sets up environment, always runs as claude user

ROOT="/var/www/html"

# ═══════════════════════════════════════════════════════════
# LOCALHOST MAPPING (as root)
# ═══════════════════════════════════════════════════════════

echo "🔧 Setting up localhost mapping..."

# Get the Docker host IP from default gateway
HOST_IP=$(ip route | grep default | awk '{print $3}')

if [ -n "$HOST_IP" ]; then
    # Remove ALL existing localhost entries (both 127.0.0.1 and any others)
    sed -i '/[[:space:]]localhost/d' /etc/hosts
    sed -i '/^localhost[[:space:]]/d' /etc/hosts

    # Map localhost to Docker host (single entry)
    echo "$HOST_IP localhost" >> /etc/hosts
    echo "✅ Mapped localhost to Docker host ($HOST_IP)"
    echo "   Now 'curl localhost:PORT' reaches your host machine"
    echo "   Use the port defined in your docker-compose.yml"
else
    echo "❌ Could not determine Docker host IP!"
fi

# ═══════════════════════════════════════════════════════════
# SETUP CLAUDE ENVIRONMENT
# ═══════════════════════════════════════════════════════════

# Install command blockers (ONLY works in Docker, safe for host)
# This creates /usr/local/bin/apk blocker to prevent container modifications
if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
    # Only block APK, not npm/yarn/pnpm/git
    cat > /usr/local/bin/apk << 'BLOCKER'
#!/bin/sh
echo "⚠️  Use the host system for APK package management!"
echo "   This is blocked to prevent accidental container modifications."
exit 1
BLOCKER
    chmod +x /usr/local/bin/apk
    echo "✅ APK blocker installed (container safety)"
fi

# Create .claude directory structure
mkdir -p $ROOT/.claude/{docs,scripts,config}
chown -R claude:claude $ROOT/.claude

# Copy helpful documentation to .claude/docs/
cat > "$ROOT/.claude/docs/README.md" << 'EOF'
# Claude Development Environment

## Quick Start
- `curl localhost` - Access webserver
- `curl webserver` - Direct webserver access
- `claude auth login` - Login to Claude (first time)

## Project Structure
- `.claude/docs/` - Documentation
- `.claude/scripts/` - Helper scripts
- `.claude/config/` - Local configs

## Networking
- localhost → webserver container
- webserver → direct service access
- host-gateway → Docker host system

## Credentials
- Auto-synced to ~/.claude-docker/
- Shared across projects
EOF

cat > "$ROOT/.claude/docs/NETWORKING.md" << 'EOF'
# Container Networking Guide

## Available Hostnames
- `localhost` - Webserver container (auto-mapped)
- `webserver` - Direct webserver service
- `host-gateway` - Docker host system
- `host.docker.internal` - Docker host (macOS/Windows)

## Port Access
- Port 80: `curl localhost` or `curl webserver`
- Host ports: `curl host-gateway:3000`
- Database: `curl db:3306` (if exists)

## Troubleshooting
- Check mapping: `cat /etc/hosts`
- Test services: `ping webserver`
- View containers: `docker compose ps`
EOF

# Create useful scripts
cat > "$ROOT/.claude/scripts/test-connectivity.sh" << 'EOF'
#!/bin/bash
echo "Testing container connectivity..."
echo "localhost: $(curl -s -o /dev/null -w "%{http_code}" localhost || echo "failed")"
echo "webserver: $(curl -s -o /dev/null -w "%{http_code}" webserver || echo "failed")"
echo "host-gateway: $(ping -c1 host-gateway >/dev/null 2>&1 && echo "ok" || echo "failed")"
EOF

chmod +x $ROOT/.claude/scripts/test-connectivity.sh

# Set ownership
chown -R claude:claude $ROOT/.claude

# ═══════════════════════════════════════════════════════════
# CLAUDE USER SETUP
# ═══════════════════════════════════════════════════════════

# Simple .bashrc for claude user
cat > /home/claude/.bashrc << 'EOF'
# Claude Dev Environment
export PATH="/usr/local/bin:/usr/local/lib/node_modules/.bin:$PATH"
export NPM_CONFIG_PREFIX="/usr/local"
alias ll='ls -la'
alias ..='cd ..'
alias test-connectivity='/home/claude/.claude/scripts/test-connectivity.sh'

# Package managers are now available in the container
# Only block system package manager to prevent container modifications
alias apk='echo "⚠️  Use the host system for APK package management!" && false'

PS1='\[\033[01;32m\]claude@dev\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

if [ -t 1 ]; then
    PROJECT_TYPE="${PROJECT_TYPE:-unknown}"
    echo ""
    echo "Claude Development Environment"
    echo "  Working Directory: $(pwd)"
    echo "  Project Type: $PROJECT_TYPE"
    echo ""

    # Auto-start claude based on credentials
    export PATH="/usr/local/bin:/usr/local/lib/node_modules/.bin:$PATH"
    # Check if claude command exists and run it
    if command -v claude >/dev/null 2>&1; then
        claude
    else
        echo "⚠️  Claude CLI not found. You may need to run: claude auth login"
        echo "   If claude command is still not working, try: /usr/local/bin/claude"
    fi
fi
EOF

chown -R claude:claude /home/claude

# Also set root prompt in case someone execs as root
echo 'PS1="\[\033[01;31m\]root@dev\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]# "' >> /root/.bashrc

# Switch to claude user and start shell
cd /var/www/html
exec su - claude -c "cd /var/www/html && exec bash"
