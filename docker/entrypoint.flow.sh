#!/bin/bash

# Set paths
export PATH="/home/claude/.deno/bin:/usr/local/bin:$PATH"
export NODE_PATH="/usr/local/lib/node_modules:$NODE_PATH"
export PLAYWRIGHT_BROWSERS_PATH="/opt/playwright-browsers"

ROOT="/var/www/html"

# Setup localhost mapping
HOST_IP=$(ip route | grep default | awk '{print $3}')
if [ -n "$HOST_IP" ]; then
    cp /etc/hosts /etc/hosts.bak
    echo "$HOST_IP localhost" > /etc/hosts
    cat /etc/hosts.bak >> /etc/hosts

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

# Setup /home/claude directories (since it's volume-mounted)
mkdir -p /home/claude/.claude/plugins /home/claude/.claude/databases /home/claude/.claude/context
mkdir -p /home/claude/.npm-global/bin
mkdir -p /home/claude/.claude-flow /home/claude/.hive-mind /home/claude/.swarm /home/claude/memory /home/claude/coordination

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

# Switch to claude user
cd /var/www/html
exec su - claude -c "export PLAYWRIGHT_BROWSERS_PATH=/opt/playwright-browsers && export NODE_PATH=/usr/local/lib/node_modules && cd /var/www/html && exec bash"
