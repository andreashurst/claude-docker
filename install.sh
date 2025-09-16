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
    # Copy main scripts
    sudo cp bin/claude-dev /usr/local/bin/
    sudo cp bin/claude-flow /usr/local/bin/
    sudo cp bin/claude-docker.lib.sh /usr/local/bin/

    # Set permissions
    sudo chmod +x /usr/local/bin/claude-dev
    sudo chmod +x /usr/local/bin/claude-flow
    sudo chmod 644 /usr/local/bin/claude-docker.lib.sh

    echo "✅ Commands installed: claude-dev, claude-flow"
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
    # Clear command cache
    hash -r 2>/dev/null || true
    
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
