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
        docker compose exec -T "$container_name" su - claude -c "claude auth login" || {
            echo "⚠️  Auto-login failed. Please run 'claude auth login' manually in container"
        }
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
    # Remove existing 127.0.0.1 localhost entry
    sed -i '/^127\.0\.0\.1[[:space:]]*localhost/d' /etc/hosts
    
    # Map localhost to Docker host
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

# Create command blockers
claude_docker_create_command_blockers() {
    cat << 'EOF'
# Smart Command Blockers
alias apk='echo "⚠️  Use the host system for package management!" && false'
alias pnpm='echo "⚠️  Run pnpm on your host system!" && false'
alias npm='echo "⚠️  Run npm on your host system!" && false'
alias yarn='echo "⚠️  Run yarn on your host system!" && false'
alias "git push"='echo "⚠️  Run git push from your host system!" && false'
EOF
}

# Create smart claude wrapper
claude_docker_create_claude_wrapper() {
    cat << 'EOF'
# Smart Claude wrapper - auto-login if needed
claude() {
    if [ ! -f ~/.claude.json ] || ! grep -q "oauthAccount" ~/.claude.json 2>/dev/null; then
        echo "🔐 Not logged in, running claude auth login..."
        command claude auth login
    else
        command claude "$@"
    fi
}
EOF
}

# Create common aliases
claude_docker_create_common_aliases() {
    cat << 'EOF'
# Basic aliases
alias ll='ls -la'
alias ..='cd ..'
alias ctest='curl -s localhost > /dev/null && echo "✅ localhost working!" || echo "❌ localhost not working"'
EOF
}

# Update gitignore
claude_docker_update_gitignore() {
    grep -q "^docker-compose\.override\.yml$" .gitignore 2>/dev/null || echo "docker-compose.override.yml" >> .gitignore
}

# Start container with connection
claude_docker_start_and_connect() {
    local container_name="$1"
    
    echo "Starting containers..."
    docker compose down 2>/dev/null || true
    docker compose up -d
    
    sleep 3
    
    if docker compose ps "$container_name" 2>/dev/null | grep -q "Up"; then
        echo "✅ Container started successfully!"
        
        claude_docker_copy_credentials_to "$container_name"
        
        echo "🔗 Connecting to $container_name container..."
        docker compose exec "$container_name" bash
        
        claude_docker_copy_credentials_from "$container_name"
        echo "✅ Session ended, credentials saved"
    else
        echo "Failed to start. Check logs:"
        docker compose logs "$container_name"
        exit 1
    fi
}