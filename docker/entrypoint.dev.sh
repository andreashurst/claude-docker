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
    # Backup original /etc/hosts
    cp /etc/hosts /etc/hosts.bak

    # Start with localhost mapping in first line
    echo "$HOST_IP localhost" > /etc/hosts

    # Append the original content
    cat /etc/hosts.bak >> /etc/hosts

    # Check for DDEV configuration
    if [ -f "/var/www/html/.ddev/config.yaml" ]; then
        echo "🔧 Detected DDEV project, adding domain mappings..."

        # Extract project name
        PROJECT_NAME=$(grep "^name:" /var/www/html/.ddev/config.yaml | cut -d' ' -f2 | tr -d '"' | head -n1)

        # Extract TLD (default is ddev.site if not specified)
        PROJECT_TLD=$(grep "^project_tld:" /var/www/html/.ddev/config.yaml 2>/dev/null | cut -d' ' -f2 | tr -d '"' | head -n1)
        if [ -z "$PROJECT_TLD" ]; then
            PROJECT_TLD="ddev.site"
        fi

        # Primary domain with correct TLD
        if [ -n "$PROJECT_NAME" ]; then
            echo "$HOST_IP ${PROJECT_NAME}.${PROJECT_TLD}" >> /etc/hosts
            echo "   ✓ Added ${PROJECT_NAME}.${PROJECT_TLD}"
        fi

        # Additional FQDNs
        ADDITIONAL_FQDNS=$(grep "^additional_fqdns:" /var/www/html/.ddev/config.yaml 2>/dev/null | cut -d':' -f2- | tr -d '[]"' | tr ',' '\n')
        if [ -n "$ADDITIONAL_FQDNS" ]; then
            for domain in $ADDITIONAL_FQDNS; do
                domain=$(echo $domain | tr -d ' ')
                if [ -n "$domain" ]; then
                    echo "$HOST_IP $domain" >> /etc/hosts
                    echo "   ✓ Added $domain"
                fi
            done
        fi

        # Additional hostnames (these also use the project_tld)
        ADDITIONAL_HOSTNAMES=$(grep "^additional_hostnames:" /var/www/html/.ddev/config.yaml 2>/dev/null | cut -d':' -f2- | tr -d '[]"' | tr ',' '\n')
        if [ -n "$ADDITIONAL_HOSTNAMES" ]; then
            for hostname in $ADDITIONAL_HOSTNAMES; do
                hostname=$(echo $hostname | tr -d ' ')
                if [ -n "$hostname" ]; then
                    # Additional hostnames get the TLD appended
                    echo "$HOST_IP ${hostname}.${PROJECT_TLD}" >> /etc/hosts
                    echo "   ✓ Added ${hostname}.${PROJECT_TLD}"
                fi
            done
        fi
    fi

    # Check for .claude-domains file for custom domain mappings
    if [ -f "/var/www/html/.claude-domains" ]; then
        echo "🔧 Found .claude-domains file, adding custom domains..."
        while IFS= read -r domain || [ -n "$domain" ]; do
            # Skip empty lines and comments
            if [ -n "$domain" ] && [[ ! "$domain" =~ ^# ]]; then
                domain=$(echo $domain | tr -d '\r' | tr -d ' ')
                echo "$HOST_IP $domain" >> /etc/hosts
                echo "   ✓ Added $domain"
            fi
        done < "/var/www/html/.claude-domains"
    fi

    echo "✅ Host mapping complete!"
    echo "   localhost and all configured domains now reach your host machine"
else
    echo "❌ Could not determine Docker host IP!"
fi

# ═══════════════════════════════════════════════════════════
# SETUP MCP CONFIGURATION
# ═══════════════════════════════════════════════════════════

echo "🔧 Setting up MCP configuration..."

# Ensure /etc/claude directory exists
mkdir -p /etc/claude

# Copy MCP config from project to system location if needed
if [ -f /var/www/html/docker/mcp.json ]; then
    cp /var/www/html/docker/mcp.json /etc/claude/mcp.json
    chmod 644 /etc/claude/mcp.json
    echo "✅ MCP configuration installed at /etc/claude/mcp.json"
fi

# Copy context files to home directory
if [ -d /var/www/html/claude/context ]; then
    mkdir -p /home/claude/.claude/context
    cp -r /var/www/html/claude/context/*.json /home/claude/.claude/context/ 2>/dev/null || true
    chown -R claude:claude /home/claude/.claude/context
    echo "✅ MCP context files copied to /home/claude/.claude/context/"
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
export PATH="/home/claude/.npm-global/bin:/usr/local/bin:$PATH"
export NPM_CONFIG_PREFIX="/home/claude/.npm-global"
export NODE_PATH="/usr/local/lib/node_modules:$NODE_PATH"
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
    export PATH="/home/claude/.npm-global/bin:/usr/local/bin:$PATH"
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
