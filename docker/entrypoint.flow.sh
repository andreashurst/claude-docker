#!/bin/bash

# Claude Flow Container Entrypoint
# This script initializes the container environment and Docker tools
# Runs as root initially, then switches to claude user

# Set PATH to include Deno and local binaries
export PATH="/home/claude/.deno/bin:/usr/local/bin:$PATH"

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
if [ ! -f "/var/www/html/.claude/settings.local.json" ]; then
    # Try to find settings in the container
    if [ -f "/home/claude/.claude/settings.local.json" ]; then
        mkdir -p /var/www/html/.claude
        cp /home/claude/.claude/settings.local.json /var/www/html/.claude/settings.local.json
        chown -R claude:claude /var/www/html/.claude
        echo "  ✓ Copied Claude settings to project directory"
    else
        echo "  ⚠ No Claude settings found (this is normal for first run)"
    fi
else
    echo "  ✓ Claude settings already exist in project"
fi

# Copy examples from container to mounted volume if they don't exist
mkdir -p /var/www/html/playwright/examples
mkdir -p /var/www/html/docs

# Copy Playwright config example to mounted volume if it doesn't exist
if [ ! -f "/var/www/html/playwright/examples/playwright.config.js" ] && [ -f "/usr/local/share/claude/examples/playwright.config.js" ]; then
    cp /usr/local/share/claude/examples/playwright.config.js /var/www/html/playwright/examples/playwright.config.js
    echo "  ✓ Copied Playwright config example"
fi

# Copy example test to mounted volume if it doesn't exist
if [ ! -f "/var/www/html/playwright/examples/example-test.spec.js" ] && [ -f "/usr/local/share/claude/examples/example-test.spec.js" ]; then
    cp /usr/local/share/claude/examples/example-test.spec.js /var/www/html/playwright/examples/example-test.spec.js
    echo "  ✓ Copied example test"
fi

# Copy documentation to mounted volume if they don't exist
if [ ! -f "/var/www/html/docs/PLAYWRIGHT.md" ] && [ -f "/usr/local/share/docs/PLAYWRIGHT.md" ]; then
    cp /usr/local/share/docs/PLAYWRIGHT.md /var/www/html/docs/PLAYWRIGHT.md
    echo "  ✓ Copied PLAYWRIGHT.md"
fi

if [ ! -f "/var/www/html/docs/NETWORKING.md" ] && [ -f "/usr/local/share/docs/NETWORKING.md" ]; then
    cp /usr/local/share/docs/NETWORKING.md /var/www/html/docs/NETWORKING.md
    echo "  ✓ Copied NETWORKING.md"
fi

# Set proper ownership of copied files
chown -R claude:claude /var/www/html/playwright 2>/dev/null || true
chown -R claude:claude /var/www/html/docs 2>/dev/null || true

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

# Show Docker tools info on login
echo ""
echo "🐳 Docker Development Tools Ready:"
echo "  • curl http://localhost:3000        → auto-rewrites to host.docker.internal"
echo "  • playwright screenshot URL out.png → auto-rewrites URLs"
echo "  • vite-proxy 3000                   → start HMR proxy for Vite"
echo "  • Frontend URL: $FRONTEND_URL"
echo ""

# Show info on login (only if the script exists)
if [ -f /usr/local/bin/claude-info ]; then
    /usr/local/bin/claude-info
fi

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
PS1='\[\033[01;32m\]claude@flow\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF

# Set ownership of bashrc
chown claude:claude /home/claude/.bashrc

# Create quick reference card
cat > /home/claude/README.md << 'EOF'
═══════════════════════════════════════════════════════════════════
                    DOCKER DEVELOPMENT TOOLS
═══════════════════════════════════════════════════════════════════

QUICK START:
  curl http://localhost:3000              # Auto-rewrites URLs
  playwright screenshot URL output.png    # Takes screenshots
  vite-proxy 3000                         # Start HMR proxy

URL REWRITING:
  localhost:3000 → host.docker.internal:3000 (automatic)

TEST COMMANDS:
  test-curl            # Test curl wrapper
  test-playwright      # Test playwright wrapper
  test-connectivity    # Test host connection
  test-tools          # Test all tools

TROUBLESHOOTING:
  If "command not found", use full paths:
    /usr/local/bin/curl-docker
    /usr/local/bin/playwright-docker

FILES:
  ~/README.md    # This help
  ~/.claude_env              # Your environment variables
  /var/www/html/docs/        # Documentation

═══════════════════════════════════════════════════════════════════
EOF

chown claude:claude /home/claude/README.md

echo ""
echo "✅ Claude Flow container initialized successfully!"
echo "✅ Docker tools installed and configured!"
echo ""
echo "📝 Type 'cat ~/README.md' for tool usage"
echo ""

# Switch to claude user and start interactive shell
#exec su - claude
