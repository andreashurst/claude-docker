#!/bin/bash

# Claude Flow Container Entrypoint
# This script initializes the container environment and Docker tools
# Runs as root initially, then switches to claude user

# Set PATH to include Deno and local binaries
export PATH="/home/claude/.deno/bin:/usr/local/bin:$PATH"
# Set NODE_PATH for global modules
export NODE_PATH="/usr/local/lib/node_modules:$NODE_PATH"

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
# ROOT OPERATIONS (system-level setup)
# ═══════════════════════════════════════════════════════════

echo "🔧 Setting up Flow environment..."

# Install command blockers (ONLY works in Docker, safe for host)
if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
    # Block APT package manager to prevent container modifications
    cat > /usr/local/bin/apt << 'BLOCKER'
#!/bin/sh
echo "⚠️  Use the host system for APT package management!"
echo "   This is blocked to prevent accidental container modifications."
exit 1
BLOCKER
    chmod +x /usr/local/bin/apt

    cat > /usr/local/bin/apt-get << 'BLOCKER'
#!/bin/sh
echo "⚠️  Use the host system for APT package management!"
echo "   This is blocked to prevent accidental container modifications."
exit 1
BLOCKER
    chmod +x /usr/local/bin/apt-get
    echo "✅ APT blockers installed (container safety)"
fi

# Test if Playwright is working (installed via npm in Dockerfile)
if command -v playwright >/dev/null 2>&1; then
    PLAYWRIGHT_VERSION=$(playwright --version 2>/dev/null | head -n1)
    echo "  ✓ Playwright operational ($PLAYWRIGHT_VERSION)"
    echo "  ✓ Browsers: Chromium, Firefox, WebKit installed"
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

# IMPORTANT: Playwright Test Directory Structure
# The following directories are used for Playwright testing:
# - playwright-tests/: All test files (*.spec.js, *.test.js) go here
# - playwright-results/: Test execution results and screenshots are saved here
# - playwright-report/: HTML test reports are generated here
# Always save Playwright tests and scripts in these directories!
mkdir -p "$ROOT/playwright-tests" "$ROOT/playwright-results" "$ROOT/playwright-report"
chown -R claude:claude $ROOT/playwright-* 2>/dev/null || true

# Playwright is globally installed and can be used with:
# const { chromium } = require('/usr/local/lib/node_modules/playwright');
# or: const { chromium } = require('playwright'); (with NODE_PATH set)

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
export NODE_PATH="/usr/local/lib/node_modules:$NODE_PATH"

# Playwright has all browsers installed and ready
# Curl uses the standard Debian curl

# Package managers are now available in the container
# Only block system package manager to prevent container modifications
alias apt='echo "⚠️  Use the host system for APT package management!" && false'
alias apt-get='echo "⚠️  Use the host system for APT package management!" && false'

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
    echo "  • playwright test                   → run tests from playwright-tests/"
    echo "  • playwright codegen                → generate test code"
    echo "  • curl http://localhost:3000        → access localhost services"
    echo "  • Frontend URL: $FRONTEND_URL"
    echo ""
    echo "📁 Playwright directories:"
    echo "  • playwright-tests/                 → place test files here"
    echo "  • playwright-results/               → screenshots & artifacts"
    echo "  • playwright-report/                → HTML test reports"
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
