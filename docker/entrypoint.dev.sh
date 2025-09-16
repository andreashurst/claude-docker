#!/bin/bash

ROOT="/var/www/html"

# Setup localhost mapping

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
        fi

        # Additional FQDNs
        ADDITIONAL_FQDNS=$(grep "^additional_fqdns:" /var/www/html/.ddev/config.yaml 2>/dev/null | cut -d':' -f2- | tr -d '[]"' | tr ',' '\n')
        if [ -n "$ADDITIONAL_FQDNS" ]; then
            for domain in $ADDITIONAL_FQDNS; do
                domain=$(echo $domain | tr -d ' ')
                if [ -n "$domain" ]; then
                    echo "$HOST_IP $domain" >> /etc/hosts
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
                fi
            done
        fi
    fi

    # Check for .claude-domains file for custom domain mappings
    if [ -f "/var/www/html/.claude-domains" ]; then
        while IFS= read -r domain || [ -n "$domain" ]; do
            # Skip empty lines and comments
            if [ -n "$domain" ] && [[ ! "$domain" =~ ^# ]]; then
                domain=$(echo $domain | tr -d '\r' | tr -d ' ')
                echo "$HOST_IP $domain" >> /etc/hosts
            fi
        done < "/var/www/html/.claude-domains"
    fi

else
    echo "ERROR: Could not determine Docker host IP!"
fi

# Setup /home/claude directories (since it's volume-mounted)
mkdir -p /home/claude/.claude/plugins /home/claude/.claude/databases /home/claude/.claude/context
mkdir -p /home/claude/.npm-global/bin
chown -R claude:claude /home/claude

# Setup MCP configuration
if [ ! -f /home/claude/.claude.json ]; then
    cp /opt/mcp-cache/claude-template.json /home/claude/.claude.json

    # Update the currentProject path if needed
    sed -i "s|\"currentProject\": \"/var/www/html\"|\"currentProject\": \"$ROOT\"|g" /home/claude/.claude.json
    sed -i "s|\"/var/www/html\": {|\"$ROOT\": {|g" /home/claude/.claude.json

fi

# Ensure MCP config is available
if [ -f /opt/mcp-cache/mcp.json ]; then
    ln -sf /opt/mcp-cache/mcp.json /home/claude/.claude/plugins/mcp.json
fi

# Create symlinks to MCP assets from system location
if [ -d /opt/mcp-assets ]; then
    # Symlink MCP assets to /home/claude/mcp
    mkdir -p /home/claude/mcp
    ln -sfn /opt/mcp-assets/servers /home/claude/mcp/servers
    ln -sfn /opt/mcp-assets/context /home/claude/mcp/context
    ln -sfn /opt/mcp-assets/config.json /home/claude/mcp/config.json
    ln -sfn /opt/mcp-assets/init.sh /home/claude/mcp/init.sh

    # Also create context symlinks in .claude/context for compatibility
    mkdir -p /home/claude/.claude/context
    find /opt/mcp-assets/context -name "*.json" -type f | while read context_file; do
        filename=$(basename "$context_file")
        ln -sf "$context_file" "/home/claude/.claude/context/$filename"
    done

    # Ensure servers are executable
    chmod +x /opt/mcp-assets/servers/*.js 2>/dev/null || true
    chown -R claude:claude /home/claude/mcp
fi

# Ensure proper ownership and permissions
chown -R claude:claude /home/claude/.claude
chmod 755 /home/claude/.claude
chmod 644 /home/claude/.claude.json 2>/dev/null || true
if [ -d /home/claude/.claude/plugins ]; then
    chmod 755 /home/claude/.claude/plugins
    chmod 644 /home/claude/.claude/plugins/* 2>/dev/null || true
fi

# Setup claude user bashrc from system template
ln -sf /opt/mcp-cache/bashrc /home/claude/.bashrc

chown -R claude:claude /home/claude

# Switch to claude user and start shell
cd /var/www/html
exec su - claude -c "cd /var/www/html && exec bash"
