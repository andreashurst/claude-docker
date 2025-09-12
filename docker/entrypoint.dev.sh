#!/bin/bash

# Claude Dev Container Entrypoint
# This script initializes the container environment
# Runs as root initially, then switches to claude user for interactive work

ROOT="/var/www/html"

# ═══════════════════════════════════════════════════════════
# PROJECT DETECTION AND CONFIGURATION
# ═══════════════════════════════════════════════════════════

# Detect project type and set intelligent default
if [ -d "$ROOT.ddev" ]; then
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

# Save the frontend URL for future sessions (both root and claude user)
echo "export FRONTEND_URL='$FRONTEND_URL'" > /root/.claude_env
echo "export FRONTEND_URL='$FRONTEND_URL'" > /home/claude/.claude_env
chown claude:claude /home/claude/.claude_env

# ═══════════════════════════════════════════════════════════
# FILE OPERATIONS AND SETUP (as root)
# ═══════════════════════════════════════════════════════════

# Copy Claude settings if available
if [ ! -f "$ROOT/.claude/settings.local.json" ]; then
    if [ -f "/home/claude/.claude/settings.local.json" ]; then
        mkdir -p $ROOT/.claude
        cp /home/claude/.claude/settings.local.json $ROOT/.claude/settings.local.json
        chown -R claude:claude $ROOT/.claude
        echo "  ✓ Claude settings copied to project directory"
    else
        echo "  ⚠ No Claude settings found (this is normal for first run)"
    fi
else
    echo "  ✓ Claude settings already exist in project"
fi


if [ -f "$ROOT/claude/.credentials.json" ] && [ ! -f "~.claude/.credentials.json" ]; then
    cp ~.$ROOT/credentials.jsonr ~.claude/.credentials.json
elif [ ! -f "~.$ROOT/.claude-docker/.credentials.json" ] && [ -f "~.claude/.credentials.json" ]; then
    cp ~.$ROOT/.credentials.json ~.claude/.credentials.json
fi


# Create documentation directory
mkdir -p $ROOT/docs

# Copy documentation to mounted volume if they don't exist
# Check multiple possible source locations
NETWORKING_COPIED=false

# Try different possible locations for the networking documentation
if [ ! -f "$ROOT/docs/NETWORKING.md" ]; && [ -f "/usr/local/share/docs/NETWORKING.md" ]; then
    cp /usr/local/share/docs/NETWORKING.md $ROOT/docs/NETWORKING.md
fi

# Set proper ownership for all project files
chown -R claude:claude $ROOT/docs 2>/dev/null || true

# ═══════════════════════════════════════════════════════════
# USER ENVIRONMENT SETUP
# ═══════════════════════════════════════════════════════════

# Set up bash profile for claude user (preferred for development)
cat > /home/claude/.bashrc << 'EOF'
[ -f ~/.claude_env ] && source ~/.claude_env
if [ -f /usr/local/bin/claude-info ]; then
    /usr/local/bin/claude-info
elif [ -f /usr/local/bin/claude-help ]; then
    /usr/local/bin/claude-help
fi
alias ll='ls -la'
alias ..='cd ..'
alias ...='cd ../..'
PS1='\[\033[01;32m\]claude@dev\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
echo ""
echo "🐳 Claude Dev Container Ready"
echo "  Project: $PROJECT_TYPE"
echo "  Frontend URL: $FRONTEND_URL"
EOF

# Switch to claude user and start interactive shell
exec su - claude
