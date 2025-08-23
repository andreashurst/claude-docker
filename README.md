# Claude Docker Environments

Run Claude Code CLI in secure, containerized environments with pre-configured development tools.

## Quick Start

```bash
# Install globally
curl -sSL https://raw.githubusercontent.com/andreashurst/claude-docker/main/install.sh | bash

# Or run directly
./bin/claude-dev   # Basic environment
./bin/claude-flow  # Advanced with Playwright & MCP
```

## Environments

### `claude-dev` - Lightweight Development
- Alpine Linux base
- Claude Code CLI (secure by default)
- Git, Node.js, npm
- Minimal footprint (~200MB)

### `claude-flow` - Full-Stack Testing
- Everything in claude-dev plus:
- Playwright with browsers
- MCP servers (filesystem, git, playwright)
- Deno runtime
- Python 3
- Universal screenshot tool

## Security First

Both environments run Claude in **secure mode by default**:

```bash
claude "your prompt"          # Secure (restricted commands)
claude-insecure "your prompt" # Unrestricted access
```

### Security Levels

| Environment | Git | System Commands | Package Managers |
|-------------|-----|-----------------|------------------|
| `claude-dev` | ✅ Allowed | ❌ Blocked | ❌ Blocked |
| `claude-flow` | ❌ Blocked | ❌ Blocked | ❌ Blocked |

## Key Features

### Universal Screenshot (claude-flow)
Automatically detects your environment and handles Vite/webpack dev servers:

```bash
screenshot http://localhost screenshot.png
# → DDEV: Uses project domain (auto-detects custom TLDs)
# → Docker: Uses host.docker.internal  
# → Local: Direct access
```

### Host Service Access
Access services running on your host machine:

```bash
# Test host connectivity
test-port 3000

# Access host services
curl http://host.docker.internal:3000
```

### Playwright Testing
```bash
# Generate tests
playwright codegen http://localhost

# Run tests
playwright-test

# UI mode
playwright-ui
```

## Project Structure

```
claude-docker/
├── bin/
│   ├── claude-dev          # Launch script
│   └── claude-flow         # Launch script
├── config/
│   ├── dev.settings.local.json     # Security settings
│   └── flow.*.json                 # Flow configs
└── docs/
    ├── PLAYWRIGHT.md       # Testing guide
    └── NETWORKING.md       # Host access guide
```

## Common Tasks

### Working with Vite/Webpack

```bash
# On host: Start dev server
npm run dev

# In container: Take screenshot with CSS
screenshot http://localhost screenshot.png
```

### Running Tests

```bash
# Copy example test  
cp /usr/local/share/claude/examples/example-test.spec.js tests/

# Run all tests
playwright-test
```

### Accessing Databases

```bash
# PostgreSQL on host
psql -h host.docker.internal -p 5432 -U user dbname

# MySQL on host
mysql -h host.docker.internal -P 3306 -u user -p
```

## Requirements

- Docker Desktop (Mac/Windows) or Docker Engine (Linux)
- 4GB RAM recommended for claude-flow
- Internet connection for initial setup

## Docker Images

Pre-built images available on Docker Hub:
- `andreashurst/claude-docker:latest-dev`
- `andreashurst/claude-docker:latest-flow`

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Connection refused" | Check service is running on host |
| Screenshots without CSS | Vite/webpack server not accessible |
| Large screenshots (>600KB) | HMR corruption - use `screenshot` command |
| Permission denied | Run without sudo, Docker group membership required |

## Documentation

- [Playwright & Testing Guide](docs/PLAYWRIGHT.md)
- [Networking & Host Access](docs/NETWORKING.md)

## License

MIT - See LICENSE file for details