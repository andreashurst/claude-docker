#!/bin/bash

# Claude Flow Container Entrypoint
# This script initializes the container environment and Docker tools
# Runs as root initially, then switches to claude user

# Set PATH to include Deno and local binaries
export PATH="/home/claude/.deno/bin:/usr/local/bin:$PATH"

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
# ROOT OPERATIONS (system-level setup)
# ═══════════════════════════════════════════════════════════

echo "🔧 Setting up Docker development tools..."

# Create convenient symlinks for the wrappers if they don't exist
if [ ! -L "/usr/local/bin/curl-wrapped" ] && [ -f "/usr/local/bin/curl-docker" ]; then
    ln -sf /usr/local/bin/curl-docker /usr/local/bin/curl-wrapped
    echo "  ✓ Curl wrapper linked"
fi

if [ ! -L "/usr/local/bin/playwright-wrapped" ] && [ -f "/usr/local/bin/playwright-docker" ]; then
    ln -sf /usr/local/bin/playwright-docker /usr/local/bin/playwright-wrapped
    echo "  ✓ Playwright wrapper linked"
fi

# Ensure scripts are executable (we're running as root)
chmod +x /usr/local/bin/curl-docker 2>/dev/null && echo "  ✓ curl-docker executable" || echo "  ⚠ Could not make curl-docker executable"
chmod +x /usr/local/bin/playwright-docker 2>/dev/null && echo "  ✓ playwright-docker executable" || echo "  ⚠ Could not make playwright-docker executable"
chmod +x /usr/local/bin/vite-proxy 2>/dev/null && echo "  ✓ vite-proxy executable" || echo "  ⚠ Could not make vite-proxy executable"
chmod +x /usr/local/bin/detect-environment 2>/dev/null && echo "  ✓ detect-environment executable" || echo "  ⚠ Could not make detect-environment executable"
chmod +x /usr/local/share/claude/vite-hmr-proxy.cjs 2>/dev/null && echo "  ✓ vite-hmr-proxy.cjs executable" || echo "  ⚠ Could not make vite-hmr-proxy.cjs executable"

# Test if tools are working
if /usr/local/bin/curl-docker --version >/dev/null 2>&1; then
    echo "  ✓ Curl wrapper operational"
else
    echo "  ⚠ Curl wrapper test failed (non-critical)"
fi

if /usr/local/bin/playwright-docker --version >/dev/null 2>&1; then
    PLAYWRIGHT_VERSION=$(/usr/local/bin/playwright-docker --version 2>/dev/null | head -n1)
    echo "  ✓ Playwright wrapper operational ($PLAYWRIGHT_VERSION)"
else
    echo "  ⚠ Playwright wrapper test failed (non-critical)"
fi

# ═══════════════════════════════════════════════════════════
# PROJECT DETECTION AND CONFIGURATION
# ═══════════════════════════════════════════════════════════

# Detect project type and set intelligent default
if [ -d "$ROOT/.ddev" ]; then
    # Extract project details from .ddev/config.yaml
    if [ -f "$ROOT/.ddev/config.yaml" ]; then
        PROJECT_NAME=$(grep "^name:" $ROOT/.ddev/config.yaml | cut -d' ' -f2 | tr -d '"' | head -n1)

        # Try to get URLs in priority order
        ADDITIONAL_FQDNS=$(grep "^additional_fqdns:" $ROOT/.ddev/config.yaml | cut -d':' -f2- | tr -d '[]"' | sed 's/,.*//g' | tr -d ' ')
        ADDITIONAL_HOSTNAMES=$(grep "^additional_hostnames:" $ROOT/.ddev/config.yaml | cut -d':' -f2- | tr -d '[]"' | sed 's/,.*//g' | tr -d ' ')
        PROJECT_TLD=$(grep "^project_tld:" $ROOT/.ddev/config.yaml | cut -d' ' -f2 | tr -d '"' | head -n1)

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

# Interactive frontend URL input (only on container start)
echo ""
echo "🎯 $PROJECT_TYPE project detected"
echo ""
read -p "Frontend URL (default: $DEFAULT_URL): " FRONTEND_INPUT
export FRONTEND_URL=${FRONTEND_INPUT:-$DEFAULT_URL}

# Save the frontend URL for future sessions (in claude's home)
echo "export FRONTEND_URL='$FRONTEND_URL'" > /home/claude/.claude_env
chown claude:claude /home/claude/.claude_env

# Copy Claude settings if available (check both possible locations)
if [ ! -f "$ROOT/.claude/settings.local.json" ]; then
    # Try to find settings in the container
    if [ -f "/home/claude/.claude/settings.local.json" ]; then
        mkdir -p $ROOT/.claude
        cp /home/claude/.claude/settings.local.json $ROOT/.claude/settings.local.json
        chown -R claude:claude $ROOT/.claude
        echo "  ✓ Copied Claude settings to project directory"
    else
        echo "  ⚠ No Claude settings found (this is normal for first run)"
    fi
else
    echo "  ✓ Claude settings already exist in project"
fi

# Copy examples from container to mounted volume if they don't exist
mkdir -p "$ROOT/playwright/examples"
cp /usr/local/share/playwright/* $ROOT/playwright/
mkdir -p $ROOT/docs
cp /usr/local/share/docs/* $ROOT/docs/

# Set proper ownership of copied files
chown -R claude:claude $ROOT/playwright 2>/dev/null || true
chown -R claude:claude $ROOT/docs 2>/dev/null || true

# ═══════════════════════════════════════════════════════════
# USER ENVIRONMENT SETUP
# ═══════════════════════════════════════════════════════════

# Set up bash profile for claude user with Docker tools aliases
cat > /home/claude/.bashrc << 'EOF'
# Claude Flow Environment Bash Configuration

# Source environment variables
[ -f ~/.claude_env ] && source ~/.claude_env

# Set PATH
export PATH="/home/claude/.deno/bin:/usr/local/bin:$PATH"
export PLAYWRIGHT_BROWSERS_PATH=/home/claude/.cache/ms-playwright

# Docker Tools Aliases
alias curl='/usr/local/bin/curl-docker'
alias playwright='/usr/local/bin/playwright-docker'
alias vite-proxy='node /usr/local/share/claude/vite-hmr-proxy.cjs'

# Command blockers to prevent accidental project modifications
alias apk='echo "⚠️  Use the host system for package management!" && false'
alias pnpm='echo "⚠️  Run pnpm on your host system!" && false'
alias npm='echo "⚠️  Run npm on your host system!" && false'
alias yarn='echo "⚠️  Run yarn on your host system!" && false'
alias git='echo "⚠️  Run git from your host system!" && false'

# Standard aliases
alias ll='ls -la'
alias ..='cd ..'
alias ...='cd ../..'

# Quick test commands
alias test-curl='curl http://localhost:3000 -s -o /dev/null -w "Status: %{http_code} from %{url_effective}\n" 2>/dev/null || echo "Curl test failed"'
alias test-playwright='playwright --version 2>/dev/null || echo "Playwright not available"'
alias test-connectivity='ping -c 3 host.docker.internal 2>/dev/null || echo "Cannot reach host.docker.internal"'
alias test-tools='echo "Testing tools..."; test-curl; test-playwright; test-connectivity'

# Custom prompt
PS1='\[\033[01;35m\]claude@flow\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

if [ -t 1 ]; then
    PROJECT_TYPE="${PROJECT_TYPE:-unknown}"
    echo ""
    echo "Claude Flow Environment"
    echo "  Working Directory: $(pwd)"
    echo "  Project Type: $PROJECT_TYPE"
    echo ""

    # Show Docker tools info
    echo "🐳 Docker Development Tools Ready:"
    echo "  • curl http://localhost:3000        → auto-rewrites to host.docker.internal"
    echo "  • playwright screenshot URL out.png → auto-rewrites URLs"
    echo "  • vite-proxy 3000                   → start HMR proxy for Vite"
    echo "  • Frontend URL: $FRONTEND_URL"
    echo ""

    # Auto-start claude based on credentials
    export PATH="/usr/local/bin:$PATH"
    claude
fi
EOF

# Set ownership of bashrc
chown claude:claude /home/claude/.bashrc

# Also set root prompt in case someone execs as root
echo 'PS1="\[\033[01;31m\]root@flow\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]# "' >> /root/.bashrc

echo ""
echo "✅ Claude Flow container initialized successfully!"
echo "✅ Docker tools installed and configured!"
echo ""
echo "📝 Type 'cat ~/README.md' for tool usage"
echo ""

# Switch to claude user and start interactive shell
cd /var/www/html
exec su - claude -c "cd /var/www/html && exec bash"
