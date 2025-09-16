#!/bin/bash

# Check if Docker is installed and running
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker is not installed. Please install Docker first."
        exit 1
    fi
    if ! docker info &> /dev/null; then
        echo "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Install global commands
install_commands() {
    sudo cp bin/claude-dev /usr/local/bin/claude-dev
    sudo cp bin/claude-flow /usr/local/bin/claude-flow
    sudo cp bin/claude-docker.lib.sh /usr/local/bin/claude-docker.lib.sh
    sudo chmod +x /usr/local/bin/claude-dev /usr/local/bin/claude-flow
    sudo chmod 644 /usr/local/bin/claude-docker.lib.sh

    # Install MCP configuration files if they exist
    if [ -f docker/mcp.json ]; then
        sudo mkdir -p /usr/local/share/claude-docker
        sudo cp docker/mcp.json /usr/local/share/claude-docker/mcp.json
        sudo cp docker/mcp-init.sh /usr/local/share/claude-docker/mcp-init.sh
        sudo chmod 644 /usr/local/share/claude-docker/mcp.json
        sudo chmod +x /usr/local/share/claude-docker/mcp-init.sh
        echo "MCP configuration files installed"
    fi

    # Copy context files if they exist
    if [ -d claude/context ]; then
        sudo mkdir -p /usr/local/share/claude-docker/context
        sudo cp -r claude/context/*.json /usr/local/share/claude-docker/context/ 2>/dev/null || true
        echo "Context files installed"
    fi

    # Copy MCP servers if they exist
    if [ -d claude/mcp-servers ]; then
        sudo mkdir -p /usr/local/share/claude-docker/mcp-servers
        sudo cp -r claude/mcp-servers/* /usr/local/share/claude-docker/mcp-servers/ 2>/dev/null || true
        sudo chmod +x /usr/local/share/claude-docker/mcp-servers/*.js 2>/dev/null || true
        echo "MCP servers installed"
    fi

    echo "Global commands installed: claude-dev, claude-flow"
}

# Pull Docker images
pull_images() {
    docker pull andreashurst/claude-docker:latest-dev
    docker pull andreashurst/claude-docker:latest-flow
    echo "Docker images pulled successfully"
}

# Main installation
main() {
    echo "###############################################################"
    echo "🚀 Claude Docker Environment Installer"
    echo "###############################################################"
    echo ""
    check_docker
    install_commands
    pull_images
    hash -d claude-dev 2>/dev/null || true
    hash -d claude-flow 2>/dev/null || true
    
    echo "✅ Installation completed successfully!"
    echo ""
    echo "🎯 Usage:"
    echo "  claude-dev    # Basic Claude Code environment"
    echo "  claude-flow   # Advanced environment with Claude-Flow and Playwright"
    echo ""
    echo "📁 Run from any directory - your current directory will be mounted"
    echo ""
}

main "$@"
