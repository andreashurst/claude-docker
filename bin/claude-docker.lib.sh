#!/bin/bash

# Claude Docker Common Library
# Shared functions for claude-dev and claude-flow
# Version: 1.0.0

# Check Docker is running
claude_docker_check() {
    if ! docker info >/dev/null 2>&1; then
        echo "❌ Error: Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Detect webserver type
claude_docker_detect_webserver() {
    if [ -f "docker-compose.yml" ] && grep -q "webserver:" docker-compose.yml; then
        echo "webserver"
    elif [ -f ".ddev/config.yaml" ]; then
        echo "ddev"
    else
        echo "none"
    fi
}

# Detect project type
claude_docker_detect_project() {
    local project_type="generic"

    # Node/JavaScript projects
    if [ -f "package.json" ]; then
        if [ -f "next.config.js" ] || [ -f "next.config.mjs" ]; then
            project_type="nextjs"
        elif [ -f "vite.config.js" ] || [ -f "vite.config.ts" ]; then
            project_type="vite"
        elif [ -f "webpack.config.js" ]; then
            project_type="webpack"
        else
            project_type="node"
        fi
    # PHP projects
    elif [ -f "composer.json" ]; then
        if [ -f "artisan" ]; then
            project_type="laravel"
        elif [ -d "wp-content" ]; then
            project_type="wordpress"
        else
            project_type="php"
        fi
    # Python projects
    elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "Pipfile" ]; then
        if [ -f "manage.py" ]; then
            project_type="django"
        else
            project_type="python"
        fi
    # Ruby projects
    elif [ -f "Gemfile" ]; then
        if [ -f "config.ru" ]; then
            project_type="rails"
        else
            project_type="ruby"
        fi
    # Go projects
    elif [ -f "go.mod" ]; then
        project_type="go"
    # Rust projects
    elif [ -f "Cargo.toml" ]; then
        project_type="rust"
    fi

    echo "$project_type"
}

# Copy credentials to container
claude_docker_copy_credentials_to() {
    local container_name="$1"
    local HOST_CLAUDE_DOCKER="$HOME/.claude.docker.json"

    if [ -f "$HOST_CLAUDE_DOCKER" ]; then
        echo "📥 Copying Claude Docker credentials to container..."
        docker compose cp "$HOST_CLAUDE_DOCKER" "$container_name:/home/claude/.claude.json" 2>/dev/null || true
        docker compose exec -T "$container_name" chown claude:claude /home/claude/.claude.json 2>/dev/null || true
        echo "✅ Credentials copied from $HOST_CLAUDE_DOCKER"
    else
        echo "ℹ️  No Claude Docker credentials found"
        echo "🔐 Starting automatic login..."
    fi
}

# Copy credentials from container
claude_docker_copy_credentials_from() {
    local container_name="$1"
    local HOST_CLAUDE_DOCKER="$HOME/.claude.docker.json"

    echo "📤 Saving Claude Docker credentials..."
    docker compose cp "$container_name:/home/claude/.claude.json" "$HOST_CLAUDE_DOCKER" 2>/dev/null && \
        echo "✅ Credentials saved to $HOST_CLAUDE_DOCKER" || \
        echo "⚠️  No credentials to save (not logged in?)"
}

# Find a free port
claude_docker_find_free_port() {
    local port=8080
    while lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; do
        ((port++))
    done
    echo $port
}

# Create base docker-compose.yml if needed
claude_docker_create_base_compose() {
    # Only create a minimal docker-compose.yml if it doesn't exist
    # This is just for docker compose to work, not for webserver
    if [ ! -f "docker-compose.yml" ]; then
        cat > "docker-compose.yml" << EOF
# Minimal docker-compose.yml for claude-docker
# The actual service is defined in docker-compose.override.yml
version: '3.8'
EOF
        echo "✅ Created minimal docker-compose.yml"
    fi
}


# Ask to replace override file
claude_docker_ask_replace_override() {
    if [ -f "docker-compose.override.yml" ]; then
        read -p "Replace existing docker-compose.override.yml? (y/N): " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && return 1
    fi
    return 0
}

# Create localhost mapping script (shared part)
claude_docker_create_localhost_mapping() {
    cat << 'EOF'
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
EOF
}

# Create base environment setup
claude_docker_create_base_environment() {
    cat << 'EOF'
# Set environment
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export TERM=xterm-256color
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
EOF
}


# Create command blocker scripts and helper commands
claude_docker_create_command_scripts() {
    # Create git blocker
    cat > /usr/local/bin/git << 'BLOCKER'
#!/bin/sh
echo "⚠️  Run git from your host system!"
exit 1
BLOCKER
    chmod +x /usr/local/bin/git

    # Create npm blocker
    cat > /usr/local/bin/npm << 'BLOCKER'
#!/bin/sh
echo "⚠️  Run npm on your host system!"
exit 1
BLOCKER
    chmod +x /usr/local/bin/npm

    # Create yarn blocker
    cat > /usr/local/bin/yarn << 'BLOCKER'
#!/bin/sh
echo "⚠️  Run yarn on your host system!"
exit 1
BLOCKER
    chmod +x /usr/local/bin/yarn

    # Create pnpm blocker
    cat > /usr/local/bin/pnpm << 'BLOCKER'
#!/bin/sh
echo "⚠️  Run pnpm on your host system!"
exit 1
BLOCKER
    chmod +x /usr/local/bin/pnpm

    # Create apk blocker
    cat > /usr/local/bin/apk << 'BLOCKER'
#!/bin/sh
echo "⚠️  Use the host system for package management!"
exit 1
BLOCKER
    chmod +x /usr/local/bin/apk

    # Create ctest helper
    cat > /usr/local/bin/ctest << 'HELPER'
#!/bin/sh
curl -s localhost > /dev/null && echo "✅ localhost working!" || echo "❌ localhost not working"
HELPER
    chmod +x /usr/local/bin/ctest

    # Create ll helper
    cat > /usr/local/bin/ll << 'HELPER'
#!/bin/sh
ls -la "$@"
HELPER
    chmod +x /usr/local/bin/ll
}

# Create command blockers (for backwards compatibility - returns aliases)
claude_docker_create_command_blockers() {
    cat << 'EOF'
# Smart Command Blockers (as aliases for .bashrc)
alias apk='echo "⚠️  Use the host system for package management!" && false'
alias pnpm='echo "⚠️  Run pnpm on your host system!" && false'
alias npm='echo "⚠️  Run npm on your host system!" && false'
alias yarn='echo "⚠️  Run yarn on your host system!" && false'
alias git='echo "⚠️  Run git from your host system!" && false'
EOF
}

# Create common aliases
claude_docker_create_common_aliases() {
    cat << 'EOF'
# Basic aliases (only ones that can't be scripts)
alias ..='cd ..'
# Note: ll and ctest are now available as scripts in /usr/local/bin
EOF
}

# Update gitignore
claude_docker_update_gitignore() {
    grep -q "^docker-compose\.override\.yml$" .gitignore 2>/dev/null || echo "docker-compose.override.yml" >> .gitignore
}

# Create docker-compose.override.yml
claude_docker_create_override() {
    local ENV_TYPE="$1"  # "dev" or "flow"
    local ENTRYPOINT_FILE="$2"
    local CURRENT_DIR="$3"
    
    local CONTAINER_NAME="claude-$ENV_TYPE"
    local IMAGE_TAG="latest-$ENV_TYPE"
    
    # Set resource limits based on environment type
    if [ "$ENV_TYPE" = "flow" ]; then
        local MEMORY_LIMIT="12G"
        local CPU_LIMIT="6.0"
        local MEMORY_RESERVE="4G"
        local CPU_RESERVE="2.0"
        local EXTRA_ENV="      - FLOW_MODE=true
      - PLAYWRIGHT_BROWSERS_PATH=/home/claude/.cache/ms-playwright"
    else
        local MEMORY_LIMIT="8G"
        local CPU_LIMIT="4.0"
        local MEMORY_RESERVE="2G"
        local CPU_RESERVE="1.0"
        local EXTRA_ENV=""
    fi
    
    cat > "docker-compose.override.yml" << EOF
services:
  $CONTAINER_NAME:
    image: andreashurst/claude-docker:$IMAGE_TAG
    working_dir: /var/www/html
    user: "0:0"

    volumes:
      - .:/var/www/html
      - $ENTRYPOINT_FILE:/usr/local/bin/custom-entrypoint.sh

    environment:
      - NODE_ENV=development
      - PROJECT_PATH=$CURRENT_DIR
      - PROJECT_TYPE=$(claude_docker_detect_project)
$EXTRA_ENV

    stdin_open: true
    tty: true
    restart: "no"

    deploy:
      resources:
        limits:
          memory: $MEMORY_LIMIT
          cpus: '$CPU_LIMIT'
        reservations:
          memory: $MEMORY_RESERVE
          cpus: '$CPU_RESERVE'

    entrypoint: ["/usr/local/bin/custom-entrypoint.sh"]
EOF
    
    echo "Created $CONTAINER_NAME configuration"
}

# Create flow-specific environment variables
claude_docker_create_flow_environment() {
    cat << 'EOF'
# Playwright specific settings
export PLAYWRIGHT_BROWSERS_PATH=/home/claude/.cache/ms-playwright
export FLOW_MODE=true
export PLAYWRIGHT_SCREENSHOTS_DIR="/var/www/html/playwright-results"
export PLAYWRIGHT_TEST_OUTPUT_DIR="/var/www/html/playwright-results"
export PLAYWRIGHT_HTML_REPORT="/var/www/html/playwright-report"

# Claude-flow directories in home (not in project!)
export CLAUDE_FLOW_HOME="/home/claude/.claude-flow"
export HIVE_MIND_HOME="/home/claude/.hive-mind"
export SWARM_HOME="/home/claude/.swarm"
export MEMORY_HOME="/home/claude/.memory"

# Create claude-flow directories in home
mkdir -p /home/claude/.claude-flow /home/claude/.hive-mind /home/claude/.swarm /home/claude/.memory
chown -R claude:claude /home/claude/.claude-flow /home/claude/.hive-mind /home/claude/.swarm /home/claude/.memory
EOF
}

# Create MCP configuration for Claude
claude_docker_create_mcp_config() {
    cat << 'EOF'
# Create MCP configuration
mkdir -p /home/claude/.config/claude
cat > "/home/claude/.config/claude/claude_desktop_config.json" << 'MCPCONFIG'
{
  "mcpServers": {
    "filesystem": {
      "command": "mcp-server-filesystem",
      "args": ["/var/www/html"]
    },
    "memory": {
      "command": "mcp-server-memory",
      "args": []
    },
    "git": {
      "command": "mcp-server-git", 
      "args": ["--repository", "/var/www/html"]
    },
    "sqlite": {
      "command": "mcp-server-sqlite",
      "args": ["--data-dir", "/home/claude/.claude/databases"]
    }
  }
}
MCPCONFIG
chown -R claude:claude /home/claude/.config
EOF
}

# Create flow-specific scripts and tools
claude_docker_create_flow_scripts() {
    cat << 'EOF'
# Create Flow-specific documentation
cat > "/home/claude/.claude/docs/FLOW.md" << 'EOF2'
# Claude Flow Environment

## Testing Tools
- `playwright test` - Run Playwright tests
- `playwright` - Direct Playwright access

## Browser Automation
- Chromium, Firefox, WebKit installed
- Headless and headed modes supported
- Screenshots and videos available

## Hive-Mine
- Data mining and analysis tools
- MCP server integration

## Commands
- `playwright test` - Run tests
EOF2

# Create testing scripts
cat > "/home/claude/.claude/scripts/test-browsers.sh" << 'EOF2'
#!/bin/bash
echo "🎭 Testing browser installations..."
playwright --version
echo "Chromium: $(chromium --version 2>/dev/null || echo 'not found')"
echo "Firefox: $(firefox --version 2>/dev/null || echo 'not found')"
EOF2

chmod +x /home/claude/.claude/scripts/test-browsers.sh
chown -R claude:claude /home/claude/.claude

# Playwright is already installed globally in the container
# No need for wrapper - it's available as direct command
EOF
}

# Create entrypoint script for dev or flow environment
claude_docker_create_entrypoint() {
    local ENV_TYPE="$1"  # "dev" or "flow"
    local OUTPUT_FILE="$2"
    
    cat > "$OUTPUT_FILE" << EOF
#!/bin/bash

# Claude $ENV_TYPE Container Entrypoint
ROOT="/var/www/html"

# Localhost mapping
$(claude_docker_create_localhost_mapping)

# Environment setup
$(claude_docker_create_base_environment)

# PHP fix for Alpine
[ -f /usr/bin/php83 ] && ln -sf /usr/bin/php83 /usr/bin/php 2>/dev/null || true
EOF
    
    # Add flow-specific environment if needed
    if [ "$ENV_TYPE" = "flow" ]; then
        cat >> "$OUTPUT_FILE" << EOF
# Flow-specific environment
$(claude_docker_create_flow_environment)
EOF
    fi
    
    cat >> "$OUTPUT_FILE" << EOF
# Setup claude environment
mkdir -p /home/claude/.claude/{docs,scripts,config}

# Handle credentials - if mounted or copied, ensure claude owns them
if [ -f /home/claude/.claude.json ]; then
    chown claude:claude /home/claude/.claude.json
    echo "✅ Claude credentials found and owned by claude user"
fi

chown -R claude:claude /home/claude/.claude

# Create command scripts (blockers and helpers)
$(claude_docker_create_command_scripts)

# Setup MCP configuration for Claude
$(claude_docker_create_mcp_config)
EOF
    
    # Add flow-specific scripts if needed
    if [ "$ENV_TYPE" = "flow" ]; then
        cat >> "$OUTPUT_FILE" << EOF
# Flow-specific scripts and tools
$(claude_docker_create_flow_scripts)
EOF
    fi
    
    cat >> "$OUTPUT_FILE" << EOF

# Create .bashrc for claude user
cat > /home/claude/.bashrc << 'EOF2'
# Ensure PATH includes npm global bin
export PATH="/usr/local/bin:\$PATH"
# Claude $ENV_TYPE Environment
$(claude_docker_create_common_aliases)

# Command blockers to prevent accidental project modifications
$(claude_docker_create_command_blockers)

# Project detection
cd /var/www/html 2>/dev/null || true
EOF

    # Add environment-specific prompt and content
    if [ "$ENV_TYPE" = "flow" ]; then
        cat >> "$OUTPUT_FILE" << 'EOF'
# Set prompt - shows claude@flow
PS1='\[\033[01;35m\]claude@flow\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

if [ -t 1 ]; then
    PROJECT_TYPE="${PROJECT_TYPE:-unknown}"
    echo ""
    echo "Claude Flow Environment"
    echo "  Working Directory: $(pwd)"
    echo "  Project Type: $PROJECT_TYPE"
    echo ""

    # Auto-start claude based on credentials
    export PATH="/usr/local/bin:$PATH"
    if [ -f /home/claude/.claude.json ] && grep -q "oauthAccount" /home/claude/.claude.json 2>/dev/null; then
        echo "🚀 Starting Claude..."
        exec claude
    else
        echo "🔐 No credentials found - starting authentication..."
        exec claude
    fi
fi
EOF2

chown -R claude:claude /home/claude

# Also set root prompt in case someone execs as root
echo 'PS1="\[\033[01;31m\]root@flow\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]# "' >> /root/.bashrc
EOF
    else
        cat >> "$OUTPUT_FILE" << 'EOF'
# Set prompt - shows claude@dev
PS1='\[\033[01;32m\]claude@dev\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

if [ -t 1 ]; then
    PROJECT_TYPE="${PROJECT_TYPE:-unknown}"
    echo ""
    echo "Claude Development Environment"
    echo "  Working Directory: $(pwd)"
    echo "  Project Type: $PROJECT_TYPE"
    echo ""

    # Auto-start claude based on credentials
    export PATH="/usr/local/bin:$PATH"
    if [ -f /home/claude/.claude.json ] && grep -q "oauthAccount" /home/claude/.claude.json 2>/dev/null; then
        echo "🚀 Starting Claude..."
        exec claude
    else
        echo "🔐 No credentials found - starting authentication..."
        exec claude
    fi
fi
EOF2

chown -R claude:claude /home/claude

# Also set root prompt in case someone execs as root
echo 'PS1="\[\033[01;31m\]root@dev\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]# "' >> /root/.bashrc
EOF
    fi
    
    cat >> "$OUTPUT_FILE" << 'EOF'

cd /var/www/html
exec su - claude -c "cd /var/www/html && exec bash"
EOF
    
    chmod +x "$OUTPUT_FILE"
}

# Check if container is already running
claude_docker_is_running() {
    local container_name="$1"
    docker compose ps "$container_name" 2>/dev/null | grep -q "Up"
}

# Just connect to existing container
claude_docker_just_connect() {
    local container_name="$1"
    echo "🔗 Connecting to existing $container_name container..."
    docker compose exec -u claude "$container_name" bash
    claude_docker_copy_credentials_from "$container_name"
    echo "✅ Session ended"
}

# Start container with connection
claude_docker_start_and_connect() {
    local container_name="$1"

    # Check if container is already running
    if claude_docker_is_running "$container_name"; then
        echo "✅ Container already running!"
        claude_docker_just_connect "$container_name"
    else
        echo "Starting containers..."
        docker compose down 2>/dev/null || true
        docker compose up -d

        sleep 3

        if docker compose ps "$container_name" 2>/dev/null | grep -q "Up"; then
            echo "✅ Container started successfully!"

            claude_docker_copy_credentials_to "$container_name"

            echo "🔗 Connecting to $container_name container as claude user..."
            docker compose exec -u claude "$container_name" bash

            claude_docker_copy_credentials_from "$container_name"
            echo "✅ Session ended, credentials saved"
        else
            echo "Failed to start. Check logs:"
            docker compose logs "$container_name"
            exit 1
        fi
    fi
}
