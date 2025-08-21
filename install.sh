#!/bin/bash

# set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed and running
check_docker() {
    log_info "Checking Docker installation..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi

    log_success "Docker is installed and running"
}

# Install global commands
install_commands() {
    log_info "Installing global commands..."

    # Copy scripts to /usr/local/bin
    sudo cp bin/claude-dev /usr/local/bin/claude-dev
    sudo cp bin/claude-flow /usr/local/bin/claude-flow
    sudo chmod +x /usr/local/bin/claude-dev /usr/local/bin/claude-flow

    log_success "Global commands installed: claude-dev, claude-flow"
}

# Pull Docker images
pull_images() {
    log_info "Pulling Docker images from Docker Hub..."

    docker pull andreashurst/claude-docker:latest-dev
    docker pull andreashurst/claude-docker:latest-flow

    log_success "Docker images pulled successfully"
}

# Main installation
main() {
    echo "🚀 Claude Docker Environment Installer"
    echo "======================================"
    echo ""

    check_docker
    install_commands
    pull_images

    echo ""
    log_success "Installation completed successfully!"
    echo ""
    echo "🎯 Usage:"
    echo "  claude-dev    # Basic Claude Code environment"
    echo "  claude-flow   # Advanced environment with Playwright"
    echo ""
    echo "📁 Run from any directory - your current directory will be mounted"
    echo ""
}

main "$@"
