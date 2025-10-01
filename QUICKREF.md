# Quick Reference Card

One-page reference for Claude Docker commands and workflows.

---

## Installation

```bash
# Install globally (one-time)
curl -sSL https://raw.githubusercontent.com/andreashurst/claude-docker/main/install.sh | bash

# Update
claude-update --check && claude-update
```

---

## Start/Stop

```bash
# Development Environment
claude-dev              # Start in current directory
claude-dev --stop       # Stop container
claude-dev --clean      # Remove container + volumes
claude-dev --root       # Start as root (debug)
claude-dev --version    # Show version

# Testing Environment (with Playwright)
claude-flow             # Start with browser automation
claude-flow --stop      # Stop container
claude-flow --clean     # Remove container + volumes
claude-flow --root      # Start as root (debug)
```

---

## Inside Container

### Essential Commands

```bash
mcp                     # Check MCP server status
commit                  # AI-powered git commit
claude auth login       # Login to Claude (first time)
```

### Git Shortcuts

```bash
gs                      # git status
gd                      # git diff
ga                      # git add
gc                      # git commit
gp                      # git pull
commit                  # AI commit message generator
```

### Playwright (claude-flow only)

```bash
pwt                     # playwright test (run all tests)
playwright test         # Run tests
playwright test --headed # Show browser
playwright test --debug  # Debug mode
playwright codegen      # Generate test code
playwright show-report  # View HTML report
```

### Package Managers

```bash
# Node.js
npm install / yarn / pnpm install / bun install

# Python
pip install package-name
poetry install

# PHP
composer install

# Ruby
bundle install

# Go
go get / go mod download

# Rust
cargo build
```

---

## Outside Container

### Management Commands

```bash
claude-health           # Check container status
claude-update           # Check for updates
docker-image-report     # Docker image analysis
```

### Make Commands (in project root)

```bash
make help               # Show all commands
make dev                # Start dev environment
make flow               # Start flow environment
make stop               # Stop all containers
make clean              # Remove containers + volumes
make logs               # Show container logs
make shell              # Open shell in container
make test               # Run tests
make ci                 # Run CI checks
make benchmark          # Run performance benchmarks
```

---

## File Locations

### Container Paths

```
/var/www/html/                  # Your project (mounted)
/home/claude/                   # User home (persistent volume)
/home/claude/.config/claude/    # Claude credentials
/home/claude/mcp/               # MCP configuration (symlink)
/opt/mcp-assets/                # Pre-cached MCP files (read-only)
```

### Project Paths

```
.claude/                        # Claude settings (create if needed)
.claude/settings.local.json     # Permissions and config
.claude/.tron-id                # Project tracking ID
docker-compose.override.yml     # Docker config (auto-generated)
playwright/tests/               # Playwright tests (flow only)
playwright/results/             # Test artifacts (flow only)
playwright/report/              # HTML reports (flow only)
```

---

## Configuration

### Permissions (.claude/settings.local.json)

```json
{
  "allowed_commands": [
    "npm *",
    "git add *",
    "git commit *",
    "git pull"
  ],
  "disallowed_commands": [
    "rm -rf",
    "dd if=",
    "mkfs"
  ]
}
```

### TRON-ID (Project Tracking)

```bash
# Method 1: Environment variable (session)
export TRON_ID="1234"

# Method 2: File (persistent)
echo "1234" > .claude/.tron-id

# Method 3: Branch name (auto-detected)
git checkout -b feature/1234-description
# Extracts: 1234

# Method 4: Interactive prompt (fallback)
commit
# Asks: "Enter TRON-ID:"
```

---

## MCP Servers (11 Pre-configured)

### Core Servers

| Server | Purpose |
|--------|---------|
| `mcp-server-filesystem` | File operations |
| `mcp-server-memory` | In-memory storage |
| `mcp-server-git` | Git operations |
| `mcp-server-sqlite` | SQLite database |

### Context Servers

| Server | Purpose |
|--------|---------|
| `webserver-env` | Localhost monitoring |
| `tailwind-context` | Tailwind CSS v4.1 docs |
| `daisyui-context` | DaisyUI components |
| `playwright-context` | Playwright testing docs |
| `playwright-advanced-context` | Advanced patterns |
| `vite-hmr-context` | Vite HMR help |
| `claude-flow-context` | Automation framework |

**Check status**: `mcp` (inside container)

---

## Common Workflows

### First Time Setup

```bash
# 1. Install
curl -sSL https://raw.githubusercontent.com/andreashurst/claude-docker/main/install.sh | bash

# 2. Start container
cd your-project/
claude-dev

# 3. Login (inside container, auto-prompted)
claude auth login

# 4. Verify
mcp                     # Should show 11 servers
```

### Daily Development

```bash
# Start
cd project/
claude-dev

# Work with Claude...

# Commit changes
git add .
commit                  # AI generates commit message
git push

# Stop
claude-dev --stop
```

### Testing Workflow (claude-flow)

```bash
# Start
claude-flow

# Write tests in playwright/tests/
# Run tests
pwt

# Generate test code
playwright codegen https://example.com

# View reports
playwright show-report playwright/report/
```

### Update Workflow

```bash
# Check for updates
claude-update --check

# Update
claude-update

# Or manual update
curl -sSL https://raw.githubusercontent.com/andreashurst/claude-docker/main/install.sh | bash
docker pull andreashurst/claude-docker:latest-dev
docker pull andreashurst/claude-docker:latest-flow
```

---

## Troubleshooting

### Container Won't Start

```bash
docker info             # Check Docker is running
docker ps -a            # Check for conflicts
claude-dev --clean      # Remove and restart
```

### Localhost Not Working

```bash
mcp                     # Check webserver-env status
curl http://host.docker.internal:3000  # Test explicitly
```

### MCP Servers Not Loading

```bash
mcp                     # Check status
cat /home/claude/mcp/config.json  # Verify config
ls -la /home/claude/mcp/  # Check symlinks
```

### Permission Errors

```bash
# Outside container
sudo chown -R $(id -u):$(id -g) .

# Or use root mode
claude-dev --root
```

### Performance Issues

```bash
docker stats            # Check resource usage

# Increase Docker Desktop resources:
# Settings → Resources → Increase CPU/Memory

# Use lighter image
claude-dev              # Instead of claude-flow
```

---

## Environment Info

### Included Languages

- **Node.js** 22 (npm, yarn, pnpm, bun)
- **PHP** 8.3 (composer)
- **Python** 3.12 (pip, pipenv, poetry)
- **Ruby** 3.2 (bundler)
- **Go** 1.21
- **Rust** 1.75 (cargo)

### Included Tools

- Git, SQLite, curl, wget
- ImageMagick, FFmpeg (image/video processing)
- jq, yq (JSON/YAML processing)
- Playwright (claude-flow only)
- Deno (claude-flow only)

### Supported Platforms

- **linux/amd64** (Intel/AMD)
- **linux/arm64** (Apple Silicon)

---

## Image Sizes

| Image | Size | Use Case |
|-------|------|----------|
| `latest-dev` | ~800MB | General development |
| `latest-flow` | ~2.5GB | Browser automation + testing |

---

## Security

- ✅ Non-root user (uid 1010)
- ✅ Isolated container
- ✅ No host access outside project
- ✅ Read-only system files
- ✅ Dangerous commands blocked
- ✅ Git push disabled by default

---

## Resources

- **Docs**: [README.md](README.md)
- **FAQ**: [FAQ.md](FAQ.md)
- **Migration**: [MIGRATION.md](MIGRATION.md)
- **Security**: [.github/SECURITY.md](.github/SECURITY.md)
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **Changelog**: [CHANGELOG.md](CHANGELOG.md)
- **Roadmap**: [ROADMAP.md](ROADMAP.md)

- **GitHub**: https://github.com/andreashurst/claude-docker
- **Docker Hub**: https://hub.docker.com/r/andreashurst/claude-docker
- **Issues**: https://github.com/andreashurst/claude-docker/issues

---

## Version

Current: **v3.2.0**

```bash
claude-dev --version    # Check installed version
```

---

**Print this page for quick reference!**

**Last Updated**: 2024-12-30
