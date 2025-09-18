#!/bin/bash

# Set paths
export PATH="/home/claude/.deno/bin:/usr/local/bin:$PATH"
export NODE_PATH="/usr/local/lib/node_modules:$NODE_PATH"
export PLAYWRIGHT_BROWSERS_PATH="/opt/playwright-browsers"

ROOT="/var/www/html"

# Setup localhost mapping with MULTIPLE FALLBACK METHODS

# Function to validate IP address
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    fi
    return 1
}

# Method 1: Try resolv.conf (most reliable in Docker)
HOST_IP=$(cat /etc/resolv.conf 2>/dev/null | awk '/nameserver/ {print $2; exit}')

# Validate Method 1
if ! validate_ip "$HOST_IP"; then
    echo "Warning: Method 1 (resolv.conf) failed or returned invalid IP: $HOST_IP"

    # Method 2: Try host.docker.internal resolution
    HOST_IP=$(getent hosts host.docker.internal 2>/dev/null | awk '{print $1}')

    if ! validate_ip "$HOST_IP"; then
        echo "Warning: Method 2 (host.docker.internal) failed or returned invalid IP: $HOST_IP"

        # Method 3: Try ip route command as fallback
        HOST_IP=$(ip route 2>/dev/null | grep default | awk '{print $3}' | head -n1)

        if ! validate_ip "$HOST_IP"; then
            echo "Warning: Method 3 (ip route) failed or returned invalid IP: $HOST_IP"

            # Method 4: Try common Docker bridge IPs
            for test_ip in "172.17.0.1" "192.168.65.2" "10.0.2.2"; do
                if ping -c 1 -W 1 $test_ip &>/dev/null; then
                    HOST_IP=$test_ip
                    echo "Warning: Using fallback Docker bridge IP: $HOST_IP"
                    break
                fi
            done
        fi
    fi
fi

# Final validation
if ! validate_ip "$HOST_IP"; then
    echo "ERROR: ALL HOST IP DETECTION METHODS FAILED!"
    echo "Setting HOST_IP to 0.0.0.0 as last resort (binds to all interfaces)"
    HOST_IP="0.0.0.0"
fi

echo "Successfully detected HOST_IP: $HOST_IP"

cp /etc/hosts /etc/hosts.bak
echo "$HOST_IP localhost" > /etc/hosts

if [ -n "$HOST_IP" ]; then

    # DDEV domains
    if [ -f "/var/www/html/.ddev/config.yaml" ]; then
        PROJECT_NAME=$(grep "^name:" /var/www/html/.ddev/config.yaml | cut -d' ' -f2 | tr -d '"' | head -n1)
        PROJECT_TLD=$(grep "^project_tld:" /var/www/html/.ddev/config.yaml 2>/dev/null | cut -d' ' -f2 | tr -d '"' | head -n1)
        [ -z "$PROJECT_TLD" ] && PROJECT_TLD="ddev.site"
        [ -n "$PROJECT_NAME" ] && echo "$HOST_IP ${PROJECT_NAME}.${PROJECT_TLD}" >> /etc/hosts
    fi

    # Custom domains
    if [ -f "/var/www/html/.claude-domains" ]; then
        while IFS= read -r domain; do
            [[ "$domain" =~ ^#.*$ || -z "$domain" ]] && continue
            echo "$HOST_IP $(echo $domain | tr -d '\r ')" >> /etc/hosts
        done < "/var/www/html/.claude-domains"
    fi
else
    echo "ERROR: Could not determine Docker host IP!"
fi
cat /etc/hosts.bak >> /etc/hosts

# Setup /home/claude directories (since it's volume-mounted)
mkdir -p /home/claude/.claude/plugins /home/claude/.claude/databases /home/claude/.claude/context
mkdir -p /home/claude/.npm-global/bin

# Setup claude-flow required directories (from official GitHub documentation)
# These contain SQLite databases and may appear empty but are essential
mkdir -p /home/claude/.hive-mind    # Contains config.json and SQLite session data
mkdir -p /home/claude/.swarm        # Contains memory.db (SQLite database)
mkdir -p /home/claude/memory        # Agent-specific memories (created when agents spawn)
mkdir -p /home/claude/coordination  # Active workflow files (created during tasks)

# Copy pre-built environment facts database if it doesn't exist
if [ ! -f /home/claude/.claude/databases/main.db ] && [ -f /opt/mcp-cache/databases/environment.db ]; then
    cp /opt/mcp-cache/databases/environment.db /home/claude/.claude/databases/main.db
    echo "Environment facts database initialized from CLAUDE.md"
fi

chown -R claude:claude /home/claude

# Setup MCP
if [ ! -f /home/claude/.claude.json ]; then
    cp /opt/mcp-cache/claude-template.json /home/claude/.claude.json
    sed -i "s|/var/www/html|$ROOT|g" /home/claude/.claude.json
fi

# Copy settings to project directory for persistence
mkdir -p /var/www/html/.claude
if [ -f /home/claude/.claude.json ]; then
    cp /home/claude/.claude.json /var/www/html/.claude/settings.local.json
    echo "Settings copied to /var/www/html/.claude/settings.local.json"
fi

[ -f /opt/mcp-cache/mcp.json ] && ln -sf /opt/mcp-cache/mcp.json /home/claude/.claude/plugins/mcp.json

# Create MCP symlinks
[ -d /opt/mcp-assets ] && {
    mkdir -p /home/claude/mcp
    ln -sfn /opt/mcp-assets/servers /home/claude/mcp/servers
    ln -sfn /opt/mcp-assets/context /home/claude/mcp/context
    ln -sfn /opt/mcp-assets/config.json /home/claude/mcp/config.json
    ln -sfn /opt/mcp-assets/init.sh /home/claude/mcp/init.sh

    mkdir -p /home/claude/.claude/context
    find /opt/mcp-assets/context -name "*.json" -type f | while read f; do
        ln -sf "$f" "/home/claude/.claude/context/$(basename "$f")"
    done

    chmod +x /opt/mcp-assets/servers/*.js 2>/dev/null
    chown -R claude:claude /home/claude/mcp /home/claude/.claude
}

# Block package managers
[ -f /.dockerenv ] && {
    cat > /usr/local/bin/apt << 'EOF'
#!/bin/sh
echo "Use the host system for APT package management"
exit 1
EOF
    chmod +x /usr/local/bin/apt
    cp /usr/local/bin/apt /usr/local/bin/apt-get
}

# Detect project type
PROJECT_TYPE="unknown"
[ -f package.json ] && PROJECT_TYPE="Node.js"
[ -f composer.json ] && PROJECT_TYPE="PHP/Laravel"
[ -f requirements.txt ] && PROJECT_TYPE="Python"
[ -f Gemfile ] && PROJECT_TYPE="Ruby"
[ -f go.mod ] && PROJECT_TYPE="Go"
[ -f .ddev/config.yaml ] && PROJECT_TYPE="DDEV"

# Setup Playwright directories
#mkdir -p $ROOT/playwright/{tests,results,report}
#chown -R claude:claude $ROOT/playwright* 2>/dev/null

# Setup bashrc from system template
ln -sf /opt/mcp-cache/bashrc /home/claude/.bashrc

# Add npm global path configuration for claude user
echo "export NPM_CONFIG_PREFIX=/home/claude/.npm-global" >> /home/claude/.bashrc
echo "export PATH=/home/claude/.npm-global/bin:\$PATH" >> /home/claude/.bashrc

# Switch to claude user
cd /var/www/html
exec su - claude -c "export PLAYWRIGHT_BROWSERS_PATH=/opt/playwright-browsers && export NODE_PATH=/usr/local/lib/node_modules && export NPM_CONFIG_PREFIX=/home/claude/.npm-global && export PATH=/home/claude/.npm-global/bin:\$PATH && cd /var/www/html && exec bash"
