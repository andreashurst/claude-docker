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

# Check if containers are already running
check_running_containers() {
    local dev_running=$(docker ps --filter "name=claude-dev" --format "{{.Names}}" 2>/dev/null)
    local flow_running=$(docker ps --filter "name=claude-flow" --format "{{.Names}}" 2>/dev/null)

    if [ -n "$dev_running" ] || [ -n "$flow_running" ]; then
        echo "⚠️  Warning: Claude containers are currently running:"
        [ -n "$dev_running" ] && echo "  - $dev_running"
        [ -n "$flow_running" ] && echo "  - $flow_running"
        echo ""
        echo "Stop them before reinstalling:"
        [ -n "$dev_running" ] && echo "  claude-dev --stop"
        [ -n "$flow_running" ] && echo "  claude-flow --stop"
        echo ""
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            exit 0
        fi
    fi
}

# Install global commands
install_commands() {
    # Copy main scripts
    sudo cp bin/claude-dev /usr/local/bin/
    sudo cp bin/claude-flow /usr/local/bin/
    sudo cp bin/claude-health /usr/local/bin/
    sudo cp bin/claude-update /usr/local/bin/
    sudo cp bin/docker-image-report /usr/local/bin/
    sudo cp bin/claude-docker.lib.sh /usr/local/bin/

    # Set permissions
    sudo chmod +x /usr/local/bin/claude-dev
    sudo chmod +x /usr/local/bin/claude-flow
    sudo chmod +x /usr/local/bin/claude-health
    sudo chmod +x /usr/local/bin/claude-update
    sudo chmod +x /usr/local/bin/docker-image-report
    sudo chmod 644 /usr/local/bin/claude-docker.lib.sh

    echo "✅ Commands installed: claude-dev, claude-flow, claude-health, claude-update, docker-image-report"
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
    check_running_containers
    install_commands
    pull_images
    # Clear command cache
    hash -r 2>/dev/null || true
    
    echo "✅ Installation completed successfully!"
    echo ""
    echo "🎯 Quick Start:"
    echo "  claude-dev      # Basic Claude Code environment"
    echo "  claude-flow     # Advanced environment with testing tools"
    echo "  claude-info     # Show system information"
    echo ""
    echo "📚 More Commands:"
    echo "  claude-health   # Check container health"
    echo "  claude-update   # Check for updates"
    echo "  make help       # Show all commands"
    echo ""
    echo "📁 Run from any directory - your current directory will be mounted"
    echo ""
}

main "$@"
