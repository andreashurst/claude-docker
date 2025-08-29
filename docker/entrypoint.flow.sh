#!/bin/bash

# Claude Flow Container Entrypoint
# This script initializes the container environment

# Set PATH to include Deno
export PATH="/home/claude/.deno/bin:$PATH"

# Mark this as a Flow environment
touch /.claude-flow-env

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

# Save the frontend URL for future sessions
echo "export FRONTEND_URL='$FRONTEND_URL'" > /home/claude/.claude_env

# Copy Claude settings if available
if [ ! -f "/var/www/html/.claude/settings.local.json" ] && [ -f "/home/claude/.claude/settings.local.json" ]; then
    mkdir -p /var/www/html/.claude
    cp /home/claude/.claude/settings.local.json /var/www/html/.claude/settings.local.json /var/www/html
    chown -R claude:claude /var/www/html/.claude
fi

# Copy examples from container to mounted volume if they don't exist
mkdir -p /var/www/html/playwright/examples
mkdir -p /var/www/html/docs

# Copy Playwright config example to mounted volume if it doesn't exist
if [ ! -f "/var/www/html/playwright/examples/playwright.config.js" ] && [ -f "/usr/local/share/claude/examples/playwright.config.js" ]; then
    cp /usr/local/share/claude/examples/playwright.config.js /var/www/html/playwright/examples/playwright.config.js
fi

# Copy example test to mounted volume if it doesn't exist
if [ ! -f "/var/www/html/playwright/examples/example-test.spec.js" ] && [ -f "/usr/local/share/claude/examples/example-test.spec.js" ]; then
    cp /usr/local/share/claude/examples/example-test.spec.js /var/www/html/playwright/examples/example-test.spec.js
fi

# Copy documentation to mounted volume if they don't exist
if [ ! -f "/var/www/html/docs/PLAYWRIGHT.md" ] && [ -f "/usr/local/share/docs/PLAYWRIGHT.md" ]; then
    cp /usr/local/share/docs/PLAYWRIGHT.md /var/www/html/docs/PLAYWRIGHT.md
fi

if [ ! -f "/var/www/html/docs/NETWORKING.md" ] && [ -f "/usr/local/share/docs/NETWORKING.md" ]; then
    cp /usr/local/share/docs/NETWORKING.md /var/www/html/docs/NETWORKING.md
fi

# Set up bash profile for claude user
cat > /home/claude/.bashrc << 'EOF'
# Claude Flow Environment Bash Configuration

# Source environment variables
[ -f ~/.claude_env ] && source ~/.claude_env

# Set PATH
export PATH="/home/claude/.deno/bin:$PATH"
export PLAYWRIGHT_BROWSERS_PATH=/home/claude/.cache/ms-playwright

# Show info on login
if [ -f /usr/local/bin/claude-info ]; then
    /usr/local/bin/claude-info
fi

# Aliases
alias ll='ls -la'
alias ..='cd ..'
alias ...='cd ../..'

# Custom prompt
PS1='\[\033[01;32m\]claude@flow\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF

# Ensure proper ownership
chown claude:claude /home/claude/.bashrc
chown claude:claude /home/claude/.claude_env 2>/dev/null || true

echo ""
echo "✅ Claude Flow container initialized successfully!"
echo ""

# Start interactive shell
exec su - claude
