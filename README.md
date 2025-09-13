# Claude Docker 🐳

Run Claude Code securely in Docker containers with automatic localhost mapping and credential management.

## Quick Start

```bash
# Install claude-dev globally
curl -sSL https://raw.githubusercontent.com/andreashurst/claude-docker/main/install.sh | bash

# Run in any project
claude-dev
```

## Features

- 🔒 **Secure** - Claude Code runs isolated in containers
- 🔗 **Localhost Works** - `curl localhost` automatically mapped
- 🔑 **Credentials** - Shared across projects via `~/.claude.docker.json`
- 🚀 **Fast** - Lightweight Alpine Linux base
- 🎯 **Smart** - Auto-detects project type (Node, PHP, Python, etc.)

## Two Flavors

### claude-dev
Basic development environment with Claude Code.

```bash
claude-dev          # Start container
claude-dev --stop   # Stop container
claude-dev --clean  # Remove all files
```

### claude-flow
Advanced testing environment with Playwright and browser automation.

```bash
claude-flow         # Start with testing tools
flow-test          # Run Playwright tests
flow-screenshot    # Take screenshots
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
├── Dockerfile.dev           # Development image
├── Dockerfile.flow          # Testing image
└── docker/                  # Container scripts
```

## Requirements

- Docker Desktop (Mac/Windows) or Docker Engine (Linux)
- 8GB RAM recommended
- macOS, Linux, or WSL2

## Common Commands

Inside the container:

```bash
claude auth login   # Login to Claude (first time only)
ctest              # Test localhost connectivity
curl localhost     # Access your webserver
```

## Troubleshooting

### Localhost not working?
The container automatically maps localhost to your webserver. Check with `ctest`.

### Credentials not saving?
Credentials are stored in `~/.claude.docker.json` on your host system.

### Permission issues?
The container runs as user `claude` (uid 1010) for security.

## Security

- Containers run as non-root user
- Command blockers prevent accidental system changes
- Credentials isolated from web Claude
- No access to host system files outside project

## Contributing

Issues and PRs welcome at [github.com/andreashurst/claude-docker](https://github.com/andreashurst/claude-docker)

## License

MIT License - See LICENSE file for details

---

Built with ❤️ for developers who value security and simplicity.