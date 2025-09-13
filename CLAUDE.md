# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

Claude Docker enables users to run Claude Code CLI securely in Docker containers with automatic localhost mapping and credential management. The project provides two main tools:
- `claude-dev`: Basic development environment
- `claude-flow`: Advanced testing environment with Playwright and browser automation

## Key Commands

### Building Docker Images
```bash
./docker.build.sh                    # Build both dev and flow images locally
./docker.push.sh                     # Build and push to Docker Hub
./docker.push.sh --no-cache          # Force rebuild without cache and push
./docker.push.sh --skip-build        # Push existing images only
```

### Installation and Usage
```bash
./install.sh                         # Install claude-dev and claude-flow globally
claude-dev                           # Start dev container in current directory
claude-dev --stop                    # Stop container
claude-dev --clean                   # Remove container, volume and config
claude-flow                          # Start flow container with testing tools
```

## Architecture Overview

### Installer Scripts (bin/)
- **claude-dev** and **claude-flow**: Main entry points that create Docker Compose configuration and start containers
- **claude-docker.lib.sh**: Shared library containing common functions for project detection, Docker checks, and configuration creation

### Docker Images (docker/)
- **Dockerfile.dev**: Base Alpine Linux image with development tools (Node, PHP, Python, Ruby, Go, Rust) and Claude Code
- **Dockerfile.flow**: Extends dev image with Playwright, browser automation tools, and testing capabilities
- **entrypoint.dev.sh** and **entrypoint.flow.sh**: Container initialization scripts that handle localhost mapping and environment setup

### Key Design Decisions
1. **Localhost Mapping**: Containers automatically detect and map localhost to host services using Docker's host.docker.internal
2. **Credential Persistence**: Uses ~/.claude.docker.json on host for credential storage across sessions
3. **Project Detection**: Automatically detects project type (Node, Laravel, Django, etc.) based on config files
4. **Non-root Security**: Containers run as user 'claude' (uid 1010) with sudo access when needed
5. **Override Pattern**: Uses docker-compose.override.yml to avoid modifying user's existing docker-compose.yml

### Container Communication
- Containers mount current directory at /var/www/html
- Host network access via host.docker.internal (mapped to localhost inside container)
- Shared credentials via bind mount to ~/.claude.docker.json