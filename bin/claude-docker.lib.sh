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
# Note: version attribute is no longer needed in modern Docker Compose
services: {}
EOF
        echo "✅ Created minimal docker-compose.yml"
    fi
}

# Create docker-compose.yml with webserver for claude-flow
claude_docker_create_flow_compose_with_webserver() {
    # Function to find a free port
    find_free_port() {
        local port=8080
        while [ $port -le 9000 ]; do
            # Check if port is in use on host
            if ! nc -z localhost $port 2>/dev/null; then
                # Also check if port is in docker-compose.yml
                if [ -f "docker-compose.yml" ]; then
                    if ! grep -q "\"$port:" docker-compose.yml && ! grep -q "'$port:" docker-compose.yml; then
                        echo $port
                        return
                    fi
                else
                    echo $port
                    return
                fi
            fi
            port=$((port + 1))
        done
        echo "8888"  # Fallback
    }

    # Only add test webserver if docker-compose.yml doesn't exist
    if [ ! -f "docker-compose.yml" ]; then
        # Find a free port
        FREE_PORT=$(find_free_port)

        # Create minimal compose with test server on free port
        cat > "docker-compose.yml" << EOF
# Docker Compose for Claude Flow with test webserver
services:
  claude-test-server:
    image: nginx:alpine
    container_name: claude-test-server
    ports:
      - "$FREE_PORT:80"
    volumes:
      - ./public:/usr/share/nginx/html:ro
    restart: unless-stopped
EOF
        echo "✅ Created docker-compose.yml with test server on port $FREE_PORT"
        WEBSERVER_PORT="$FREE_PORT"
    else
        # docker-compose.yml exists - don't modify it
        echo "ℹ️  Using existing docker-compose.yml"
        echo "   If you need a test server, manually add claude-test-server"
        WEBSERVER_PORT="80"  # Assume existing setup uses standard port
    fi

        # Create public folder and index.html if they don't exist
        if [ ! -d "public" ]; then
            mkdir -p public
            # Note: We use regular heredoc (not quoted) to allow variable substitution
            cat > "public/index.html" << HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Claude Flow - Testing Environment</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
        }
        .container {
            background: white;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
        }
        h1 {
            color: #764ba2;
            border-bottom: 3px solid #667eea;
            padding-bottom: 10px;
        }
        .section {
            margin: 20px 0;
            padding: 15px;
            background: #f7f7f7;
            border-radius: 5px;
        }
        code {
            background: #2d2d2d;
            color: #f8f8f2;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: 'Monaco', 'Courier New', monospace;
        }
        .test-section {
            background: #e8f5e9;
            border-left: 4px solid #4caf50;
        }
        .command {
            background: #263238;
            color: #aed581;
            padding: 10px;
            border-radius: 5px;
            margin: 10px 0;
            font-family: monospace;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎭 Claude Flow Testing Environment</h1>

        <div class="section">
            <h2>✅ Test Webserver is Running!</h2>
            <p>If you can see this page, your test webserver is successfully running on port $WEBSERVER_PORT.</p>
            <p><strong>Note:</strong> Port $WEBSERVER_PORT was automatically selected as it was free.</p>
        </div>

        <div class="section test-section">
            <h2>🧪 Quick Test Commands</h2>
            <p>Run these from inside the Claude Flow container:</p>
            <div class="command">curl localhost:$WEBSERVER_PORT</div>
            <div class="command">curl http://localhost:$WEBSERVER_PORT</div>
            <div class="command">playwright test</div>
            <div class="command">playwright codegen http://localhost</div>
        </div>

        <div class="section">
            <h2>📁 How to Use</h2>
            <ul>
                <li>Place your HTML/CSS/JS files in the <code>public/</code> folder</li>
                <li>They will be immediately available at <code>http://localhost/</code></li>
                <li>The webserver auto-reloads when files change</li>
                <li>Access from Claude Flow: <code>curl localhost</code></li>
            </ul>
        </div>

        <div class="section">
            <h2>🎯 Playwright Testing</h2>
            <p>Create test files in <code>playwright-tests/</code> folder:</p>
            <div class="command">
// Example test
test('homepage loads', async ({ page }) => {
  await page.goto('http://localhost');
  await expect(page).toHaveTitle(/Claude Flow/);
});
            </div>
        </div>

        <div class="section">
            <h2>🚀 Next Steps</h2>
            <ol>
                <li>Edit this file: <code>public/index.html</code></li>
                <li>Add your application files to <code>public/</code></li>
                <li>Write Playwright tests in <code>playwright-tests/</code></li>
                <li>Run tests with <code>playwright test</code></li>
            </ol>
        </div>

        <p style="text-align: center; color: #666; margin-top: 30px;">
            Claude Flow v3.2.0 | <a href="https://github.com/andreashurst/claude-docker">GitHub</a>
        </p>
    </div>
</body>
</html>
HTML
            echo "✅ Created public/index.html with howto guide on port $WEBSERVER_PORT"
        fi
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
    # Simply overwrite /etc/hosts with ONE line - localhost pointing to host
    echo "$HOST_IP localhost" > /etc/hosts

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


# Create helper commands and SAFE blockers (ONLY in Docker containers!)
claude_docker_create_command_blocker() {
    cat << 'EOF'
# CRITICAL: Only run this inside Docker containers, NEVER on host!
if [ ! -f /.dockerenv ] && [ ! -f /run/.containerenv ]; then
    echo "⚠️  WARNING: Not in a Docker container - skipping blocker installation"
    echo "   This protects your host system from being affected"
    return 0
fi

echo "✅ Install Helper Commands (Docker container confirmed)"

# Only block APK to prevent container system modifications
# npm, yarn, pnpm, git are NOT blocked - they're available for use
cat > /usr/local/bin/apk << 'BLOCKER'
#!/bin/sh
# Double-check we're in Docker before blocking
if [ ! -f /.dockerenv ] && [ ! -f /run/.containerenv ]; then
    # On host system - run real apk
    /sbin/apk "$@"
else
    # In Docker - block it
    echo "⚠️  Use the host system for APK package management!"
    echo "   This is blocked to prevent accidental container modifications."
    exit 1
fi
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

# Create command blockers as aliases (backup method, also Docker-safe)
claude_docker_create_command_blockers() {
    cat << 'EOF'
# CRITICAL: Only set aliases in Docker containers
if [ ! -f /.dockerenv ] && [ ! -f /run/.containerenv ]; then
    echo "⚠️  Not in Docker - skipping alias blockers for safety"
    return 0
fi

echo "✅ Install Safety Aliases (Docker container confirmed)"
# Only block APK to prevent system modifications
alias apk='echo "⚠️  Use the host system for APK package management!" && false'
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

    entrypoint: ["/docker/entrypoint.sh"]

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

# Create MCP configuration for Claude Code (system location)
claude_docker_create_mcp_config() {
    cat << 'EOF'
# MCP config is managed at system level (/etc/claude/mcp.json)
# This is handled by the entrypoint scripts which copy from docker/mcp.json
echo "✅ MCP configuration managed at /etc/claude/mcp.json (system location)"
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

# Claude files
GITIGNORE
    fi
}
