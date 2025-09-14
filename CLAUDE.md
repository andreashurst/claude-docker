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
- **Dockerfile.dev**: Base Alpine Linux image with:
  - Development languages: Node.js, PHP 8.3, Python 3, Ruby, Go, Rust
  - Package managers: npm, yarn, pnpm, bun, pip, composer
  - MCP servers for Claude integration
  - Claude Code CLI installed globally
  - Image/PDF handling tools (ImageMagick, ffmpeg, etc.)
- **Dockerfile.flow**: Extends dev image with:
  - Playwright and @playwright/test for browser automation
  - Chromium, Firefox, and WebKit browsers
  - Deno runtime for additional scripting
  - Python MCP servers (mcp-server-git, hive-mine)
- **entrypoint.dev.sh** and **entrypoint.flow.sh**: Container initialization scripts that handle localhost mapping and environment setup

### Key Design Decisions
1. **Localhost Mapping**: Containers automatically detect and map localhost to host services using Docker's host.docker.internal
2. **Credential Persistence**: Uses Docker volumes (claude-dev-data, claude-flow-data) for credential storage across sessions
3. **Project Detection**: Automatically detects project type (Node, Laravel, Django, etc.) based on config files
4. **Non-root Security**: Containers run as user 'claude' (uid 1010) with sudo access when needed
5. **Override Pattern**: Uses docker-compose.override.yml to avoid modifying user's existing docker-compose.yml

### Container Communication
- Containers mount current directory at /var/www/html
- Host network access via host.docker.internal (mapped to localhost inside container)
- Shared credentials via Docker volume mounted at /home/claude

## Important Notes

### Available Development Tools
The containers now include all major package managers and development tools:
- **Node.js ecosystem**: npm, yarn, pnpm, bun
- **Python**: pip, pipenv, poetry
- **PHP**: composer
- **Git**: Full git support for version control
- **MCP servers**: Pre-configured Model Context Protocol servers:
  - `mcp-server-filesystem`: File system operations
  - `mcp-server-memory`: In-memory data storage
  - `mcp-server-git`: Git repository operations
  - `mcp-server-sqlite`: SQLite database management
  - Configuration file at `/etc/claude/mcp.json` (copied to project as `.mcp.json`)
  - Context files included for: Playwright, Tailwind CSS v4.1, DaisyUI, Claude Flow

### Claude CLI Setup
The claude command is installed via npm as `@anthropic-ai/claude-code`. The following paths are configured in PATH:
- `/usr/local/bin` (where symlink is created)
- `/usr/local/lib/node_modules/.bin` (npm global bin directory)

The entrypoint scripts properly set PATH and check for claude command availability before running it. If claude doesn't start automatically, run `claude auth login` first.

### Security Note
Only the APK package manager is blocked to prevent accidental system modifications. All development tools are fully functional within the container.