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
        echo "XXXXXXXX"
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
claude_docker_create_command_blocker() {
    cat << 'EOF'
echo "✅ Install Bin Blocker"
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
EOF
}

# Create command blockers (for backwards compatibility - returns aliases)
claude_docker_create_command_blockers() {
    cat << 'EOF'
echo "✅ Install Blocker Aliases"
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

# Update gitignore with all necessary entries
claude_docker_update_gitignore() {
    # Create .gitignore if it doesn't exist
    [ ! -f .gitignore ] && touch .gitignore

    # Array of patterns to add to gitignore
    local patterns=(
        "docker-compose.override.yml"
        ".mcp.json"
        ".claude*"
        ".hive-mind"
        "playwright*"
        "*.sqlite"
        "*.sqlite3"
        "*.tmp"
        ".DS_Store"
        "Thumbs.db"
        ".backup"
    )

    # Add each pattern if it doesn't already exist
    for pattern in "${patterns[@]}"; do
        # Escape special characters for grep
        escaped_pattern=$(echo "$pattern" | sed 's/[[\.*^$()+?{|]/\\&/g')
        grep -q "^${escaped_pattern}$" .gitignore 2>/dev/null || {
            echo "$pattern" >> .gitignore
            echo "  ✓ Added $pattern to .gitignore"
        }
    done

    echo "✅ Updated .gitignore with all necessary patterns"
}

# Create docker-compose.override.yml
claude_docker_create_override() {
    local ENV_TYPE="$1"  # "dev" or "flow"
    local ENTRYPOINT_FILE="$2"
    local CURRENT_DIR="$3"

    local CONTAINER_NAME="claude-$ENV_TYPE"
    local IMAGE_TAG="latest-$ENV_TYPE"
    local VOLUME_NAME="claude-${ENV_TYPE}-data"

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
      - $VOLUME_NAME:/home/claude
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

    entrypoint: ["/docker/entrypoint.$ENV_TYPE.sh"]

volumes:
  $VOLUME_NAME:
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

# Create MCP configuration for Claude Code (simplified)
claude_docker_create_mcp_config() {
    cat << 'EOF'
# MCP config should be in project root as .mcp.json (per official docs)
# Copy default MCP config to project if not exists
if [ ! -f /var/www/html/.mcp.json ]; then
    cp /etc/claude/mcp.json /var/www/html/.mcp.json
    echo "✅ MCP configuration (.mcp.json) created in project root"
fi
# Ensure claude user can read it
chown claude:claude /var/www/html/.mcp.json 2>/dev/null || true
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

# Removed obsolete entrypoint creation function - now using docker/entrypoint.*.sh files directly
# The localhost mapping and other helper functions are still available above for reference

# Check if container is already running
claude_docker_is_running() {
    local container_name="$1"
    docker compose ps "$container_name" 2>/dev/null | grep -q "Up"
}

# Start container with connection
claude_docker_connect() {
    local container_name="$1"

    # Check if container is already running
    if claude_docker_is_running "$container_name"; then
        echo "✅ Container already running!"
        echo "🔗 Connecting to existing $container_name container as claude user..."
        docker compose exec -u claude "$container_name" bash
        echo "✅ Session ended"
    else
        echo "Starting containers..."
        docker compose up -d
        sleep 3
        if claude_docker_is_running "$container_name"; then
            echo "✅ Container started successfully!"
            echo "🔗 Connecting to $container_name container as claude user..."
            echo "📁 Credentials stored in Docker volume: claude-${container_name##*-}-data"
            docker compose exec -u claude "$container_name" bash
            echo "✅ Session ended"
        else
            echo "Failed to start. Check logs:"
            docker compose logs "$container_name"
            exit 1
        fi
    fi
}


claude_docker_connect_as_root() {
  local container_name="$1"
  if docker compose ps "$container_name" 2>/dev/null | grep -q "Up"; then
      echo "✅ Connecting as root"
      docker compose exec "$container_name" bash
  else
      echo "Connecting as root failed. Check logs:"
      docker compose logs "$container_name"
      exit 1
  fi
}

claude_docker_playwright_config() {
    if [ ! -f "playwright.config.js" ] && [ ! -f "playwright.config.ts" ]; then
        echo "📝 Creating default playwright.config.js (customize as needed)..."
        cat > "playwright.config.js" << 'PWCONFIG'
// @ts-check
const { defineConfig, devices } = require('@playwright/test');

/**
 * Playwright configuration for Claude Flow
 * @see https://playwright.dev/docs/test-configuration
 */
module.exports = defineConfig({
  testDir: './playwright-tests',
  outputDir: './playwright-results',

  // Maximum time one test can run
  timeout: 30 * 1000,

  // Run tests in parallel
  fullyParallel: true,

  // Fail the build on CI if you accidentally left test.only
  forbidOnly: !!process.env.CI,

  // Retry on CI only
  retries: process.env.CI ? 2 : 0,

  // Parallel workers on CI, single on local
  workers: process.env.CI ? 1 : undefined,

  // Reporter configuration
  reporter: [
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['list'],
    ['json', { outputFile: 'playwright-results/results.json' }]
  ],

  use: {
    // Base URL for all tests
    baseURL: process.env.BASE_URL || 'http://localhost',

    // Collect trace when retrying the failed test
    trace: 'on-first-retry',

    // Screenshot on failure
    screenshot: {
      mode: 'only-on-failure',
      fullPage: true
    },

    // Video on failure
    video: 'retain-on-failure',

    // Artifacts folder
    artifactsPath: './playwright-results/artifacts'
  },

  // Configure projects for major browsers
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    // Mobile testing
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },
  ],

  // Local dev server (if needed)
  webServer: process.env.NO_WEBSERVER ? undefined : {
    command: 'echo "Using localhost from host machine"',
    url: 'http://localhost',
    reuseExistingServer: true,
  },
});
PWCONFIG
        echo "✅ Created playwright.config.js - you can customize it as needed"
    else
        echo "✅ Using existing playwright.config.js/ts"
    fi

    # Setup test directories with playwright prefix
    echo "📁 Setting up Playwright directories..."
    mkdir -p playwright-tests
    mkdir -p playwright-results
    mkdir -p playwright-report

    # Simple gitignore - just playwright*
    if [ -f ".gitignore" ]; then
        grep -q "^playwright" .gitignore || echo -e "\n# Playwright artifacts\nplaywright*" >> .gitignore
    else
        cat > .gitignore << 'GITIGNORE'
# Playwright artifacts
playwright*

# Docker
docker-compose.override.yml

# Claude
.claude.docker.json
GITIGNORE
    fi
}
