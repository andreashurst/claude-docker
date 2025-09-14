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
# ROOT OPERATIONS (system-level setup)
# ═══════════════════════════════════════════════════════════

echo "🔧 Setting up Flow environment..."

# Install command blockers (ONLY works in Docker, safe for host)
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

# Test if Playwright is working (installed via npm in Dockerfile)
if command -v playwright >/dev/null 2>&1; then
    PLAYWRIGHT_VERSION=$(playwright --version 2>/dev/null | head -n1)
    echo "  ✓ Playwright operational ($PLAYWRIGHT_VERSION)"
else
    echo "  ⚠ Playwright not found - you may need to run: npm install -g playwright"
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

# Create playwright directories if needed
mkdir -p "$ROOT/playwright-tests" "$ROOT/playwright-results" "$ROOT/playwright-report"
chown -R claude:claude $ROOT/playwright-* 2>/dev/null || true

# ═══════════════════════════════════════════════════════════
# USER ENVIRONMENT SETUP
# ═══════════════════════════════════════════════════════════

# Set up bash profile for claude user with Docker tools aliases
cat > /home/claude/.bashrc << 'EOF'
# Claude Flow Environment Bash Configuration

# Source environment variables
[ -f ~/.claude_env ] && source ~/.claude_env

# Set PATH
export PATH="/home/claude/.deno/bin:/home/claude/.npm-global/bin:/usr/local/bin:$PATH"
export NPM_CONFIG_PREFIX="/home/claude/.npm-global"
export PLAYWRIGHT_BROWSERS_PATH=/home/claude/.cache/ms-playwright

# Playwright is available directly (no wrapper needed)
# Curl uses the standard Alpine curl

# Package managers are now available in the container
# Only block system package manager to prevent container modifications
alias apk='echo "⚠️  Use the host system for APK package management!" && false'

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
    echo "🎭 Flow Testing Tools Ready:"
    echo "  • playwright test                   → run Playwright tests"
    echo "  • playwright codegen                → generate test code"
    echo "  • curl http://localhost:3000        → access localhost services"
    echo "  • Frontend URL: $FRONTEND_URL"
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
