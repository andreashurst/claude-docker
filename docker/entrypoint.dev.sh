#!/bin/bash

# Claude Dev Container Entrypoint - KISS Edition
# Auto-maps localhost, sets up environment, always runs as claude user

ROOT="/var/www/html"

# ═══════════════════════════════════════════════════════════
# LOCALHOST MAPPING (as root)
# ═══════════════════════════════════════════════════════════

if getent hosts webserver >/dev/null 2>&1; then
    WEBSERVER_IP=$(getent hosts webserver | cut -d' ' -f1)
    sed -i '/[[:space:]]localhost[[:space:]]*$/d' /etc/hosts
    echo "$WEBSERVER_IP localhost" >> /etc/hosts
    echo "Mapped localhost to webserver ($WEBSERVER_IP)"
fi

# ═══════════════════════════════════════════════════════════
# SETUP CLAUDE ENVIRONMENT
# ═══════════════════════════════════════════════════════════

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
alias ll='ls -la'
alias ..='cd ..'
alias test-connectivity='/home/claude/.claude/scripts/test-connectivity.sh'
PS1='\[\033[01;32m\]claude@dev\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

echo ""
echo "Claude Dev Container Ready"
echo "  Working Directory: $(pwd)"
echo "  Help: cat ~/.claude/docs/README.md"
echo "  Test Network: test-connectivity"
echo ""
EOF

# Switch to claude user and start shell
exec su - claude -c "cd /var/www/html && exec bash"