# Claude Docker 🐳

[![GitHub Release](https://img.shields.io/github/v/release/andreashurst/claude-docker)](https://github.com/andreashurst/claude-docker/releases)
[![Docker Pulls](https://img.shields.io/docker/pulls/andreashurst/claude-docker)](https://hub.docker.com/r/andreashurst/claude-docker)
[![Docker Image Size](https://img.shields.io/docker/image-size/andreashurst/claude-docker/latest-dev?label=dev%20image)](https://hub.docker.com/r/andreashurst/claude-docker)
[![CI Status](https://img.shields.io/github/actions/workflow/status/andreashurst/claude-docker/ci.yml?branch=main)](https://github.com/andreashurst/claude-docker/actions)
[![License](https://img.shields.io/github/license/andreashurst/claude-docker)](LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/andreashurst/claude-docker?style=social)](https://github.com/andreashurst/claude-docker)

Run Claude Code securely in Docker containers with automatic localhost mapping and credential management.

## Quick Start

```bash
# Install globally (one-time setup)
curl -sSL https://raw.githubusercontent.com/andreashurst/claude-docker/main/install.sh | bash

# Run in any project directory
cd your-project/
claude-dev
```

That's it! Claude Code starts automatically in the container.

## Features

- 🔒 **Secure** - Isolated containers, non-root user, no host access
- 🔗 **Localhost Works** - `curl localhost` automatically mapped to host
- 🔑 **Persistent** - Credentials stored in Docker volumes
- 🚀 **Fast** - Lightweight Alpine Linux, instant startup
- 🎯 **Smart** - Auto-detects project type (Node, PHP, Python, Ruby, Go, Rust)
- 🤖 **11 MCP Servers** - Pre-configured: Tailwind, DaisyUI, Playwright, Git, SQLite, etc.
- 🛠️ **All Package Managers** - npm, yarn, pnpm, bun, pip, composer, bundler
- 🎨 **Media Tools** - ImageMagick, FFmpeg, PDF handling built-in
- 🤖 **AI Git Commits** - `commit` command generates smart commit messages

## Two Environments

### claude-dev (Development)
Basic development environment - perfect for most projects.

```bash
claude-dev          # Start container in current directory
claude-dev --stop   # Stop container
claude-dev --clean  # Remove container and volumes
```

**Includes:** Node.js, PHP, Python, Ruby, Go, Rust, all package managers, Git, SQLite, MCP servers

### claude-flow (Testing)
Advanced environment with browser automation and testing tools.

```bash
claude-flow          # Start with Playwright and testing tools
claude-flow --stop   # Stop container
claude-flow --clean  # Remove all data
```

**Additional:** Playwright (Chromium, Firefox, WebKit), Deno, Claude Flow automation, Python MCP servers

## Management Commands

```bash
# Container Management
claude-health             # Check container status
claude-update             # Check for updates

# Analysis & Reports
docker-image-report       # Docker image size analysis
make benchmark            # Run performance benchmarks (requires make)

# Inside Container
mcp                       # Show MCP server status
commit                    # AI-generated git commits
```

## How It Works

1. **Installer** creates minimal Docker configuration
2. **Container** starts with localhost mapping
3. **Claude Code** runs with full access to your project
4. **Credentials** persist between sessions

## Project Structure

```
claude-docker/
├── bin/
│   ├── claude-dev           # Main installer
│   ├── claude-flow          # Testing variant
│   └── claude-docker.lib.sh # Shared functions
├── docker/
│   ├── Dockerfile.dev       # Development image
│   ├── Dockerfile.flow      # Testing image
│   ├── entrypoint.dev.sh    # Dev container init
│   └── entrypoint.flow.sh   # Flow container init
└── mcp/                     # Model Context Protocol
    ├── servers/             # MCP server implementations
    ├── context/             # Context data by tool
    ├── cache/               # Build-time templates
    └── config.json          # MCP configuration
```

## Requirements

- Docker Desktop (Mac/Windows) or Docker Engine (Linux)
- 8GB RAM recommended
- macOS, Linux, or WSL2

## Common Workflows

### First Time Setup
```bash
# Inside the container (runs automatically on start)
claude auth login   # Login to Claude
```

### Development
```bash
# Make changes, then commit with AI
git status
commit              # Generates smart commit message
git push
```

### Testing (claude-flow only)
```bash
playwright test                    # Run all tests
playwright codegen                 # Record browser actions
npx playwright test --headed       # See browser window
```

### Troubleshooting
```bash
claude-health       # Check if containers are running
mcp                 # Verify all MCP servers are loaded
```

## Common Issues

**Localhost not working?**
- Container automatically maps `localhost` to host webserver
- Test with: `curl localhost` inside container

**Credentials not saving?**
- Stored in Docker volumes: `claude-dev-data` or `claude-flow-data`
- Persist across container restarts
- Use `--clean` flag only if you want to reset everything

**Permission issues?**
- Container runs as user `claude` (uid 1010) for security
- Has sudo access when needed
- Cannot modify host system outside project directory

## Security

- ✅ **Isolated** - Containers run as non-root user (uid 1010)
- ✅ **Sandboxed** - No access to host files outside mounted project
- ✅ **Read-only MCP** - System context files are immutable
- ✅ **Safe Defaults** - Dangerous commands blocked (rm -rf, dd, mkfs)
- ✅ **Git Push Disabled** - Explicit permission required for push operations
- ✅ **Volume Isolation** - Credentials stored separately from project

## Documentation

- [CLAUDE.md](CLAUDE.md) - Instructions for Claude Code when working in this repo
- [bin/README-COMMIT-AI.md](bin/README-COMMIT-AI.md) - AI commit command documentation
- [LOCALHOST-HANDLING.md](LOCALHOST-HANDLING.md) - How localhost mapping works
- [CHANGES.md](CHANGES.md) - Project changelog

## Advanced Usage

### Custom MCP Servers
MCP configuration in `/home/claude/mcp/config.json` can be extended per-project.

### Pre-configured Permissions
Edit `.claude/settings.local.json` to customize allowed commands.

### TRON-ID System
The `commit` command supports project tracking IDs:
```bash
export TRON_ID="1234"          # Set ID for session
# OR use branch names: feature/1234-description
# OR save to .claude/.tron-id
```

## Project Structure

```
claude-docker/
├── bin/                    # Global commands
│   ├── claude-dev         # Main launcher
│   ├── claude-flow        # Testing variant
│   ├── claude-health      # Status checker
│   ├── git-commit-ai      # AI commit generator
│   └── mcp-status         # MCP server status
├── docker/                # Container definitions
│   ├── Dockerfile.dev     # Development image
│   ├── Dockerfile.flow    # Testing image
│   └── bin/               # Entrypoints and wrappers
└── mcp/                   # Model Context Protocol
    ├── servers/           # 7 custom MCP servers
    ├── context/           # Pre-cached documentation
    ├── cache/             # Build-time templates
    └── config.json        # MCP configuration
```

## Quick Reference

```bash
# Development
make help          # Show all commands
make test          # Run tests
make build         # Build images
make dev           # Start dev environment
make flow          # Start flow environment

# Inside container
commit             # AI-generated git commit
mcp                # Check MCP servers
health             # Container health (outside)
gs                 # git status
pwt                # playwright test (flow only)
```

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

- **Issues**: [GitHub Issues](https://github.com/andreashurst/claude-docker/issues)
- **Discussions**: [GitHub Discussions](https://github.com/andreashurst/claude-docker/discussions)
- **Pull Requests**: Use the PR template

## License

MIT License - See LICENSE file for details

---

**Built with ❤️ for developers who value security and simplicity.**

**Key Philosophy:** Everything pre-configured, nothing to install at runtime, works offline.