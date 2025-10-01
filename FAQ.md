# Frequently Asked Questions (FAQ)

## General Questions

### What is Claude Docker?

Claude Docker provides secure, isolated Docker containers to run Claude Code CLI with automatic localhost mapping, persistent credentials, and 11 pre-configured MCP (Model Context Protocol) servers.

### Why use Claude Docker instead of native Claude Code?

**Security**: Runs in isolated container with non-root user (uid 1010)
**Convenience**: Pre-configured with all tools, MCP servers, and language support
**Portability**: Same environment on any machine with Docker
**Safety**: Can't modify host system outside project directory
**Localhost Mapping**: Automatically maps localhost to host services

### What's the difference between claude-dev and claude-flow?

**claude-dev** (800MB):
- Lightweight Alpine Linux base
- Node.js, PHP, Python, Ruby, Go, Rust
- All package managers (npm, yarn, pnpm, bun, pip, composer)
- 11 MCP servers
- Perfect for general development

**claude-flow** (2.5GB):
- Everything from dev plus:
- Playwright with Chromium, Firefox, WebKit browsers
- Deno runtime
- Claude Flow automation framework
- Browser testing and automation

---

## Installation & Setup

### How do I install Claude Docker?

```bash
curl -sSL https://raw.githubusercontent.com/andreashurst/claude-docker/main/install.sh | bash
```

This installs globally: `claude-dev`, `claude-flow`, `claude-health`, `claude-update`, `docker-image-report`

### Do I need to install Claude Code separately?

No! Claude Code CLI is pre-installed in the containers. Just run `claude auth login` on first start.

### What are the system requirements?

- Docker Desktop (Mac/Windows) or Docker Engine (Linux)
- 8GB RAM recommended (4GB minimum)
- macOS, Linux, or WSL2
- Internet connection for initial image pull

### Can I run it offline?

Yes! After pulling images once, everything works offline. All MCP context files are pre-cached, and no runtime installations occur.

---

## Usage

### How do I start Claude Code?

```bash
cd your-project/
claude-dev          # Start dev environment
# OR
claude-flow         # Start testing environment
```

Container starts automatically and launches Claude Code.

### How do I stop the container?

```bash
claude-dev --stop    # Stop dev container
claude-flow --stop   # Stop flow container
```

### How do I completely remove everything?

```bash
claude-dev --clean   # Remove container, volume, config
claude-flow --clean  # Remove container, volume, config
```

**Warning**: `--clean` deletes stored credentials and MCP data.

### Where are my credentials stored?

In Docker volumes:
- `claude-dev-data` → `/home/claude` in dev container
- `claude-flow-data` → `/home/claude` in flow container

These persist across container restarts but are deleted with `--clean`.

### Can I run both dev and flow at the same time?

Yes! They use separate containers and volumes:

```bash
# Terminal 1
cd project-a/
claude-dev

# Terminal 2
cd project-b/
claude-flow
```

---

## Localhost & Networking

### How does localhost mapping work?

Containers automatically detect host webservers and map `localhost` to `host.docker.internal`. When you `curl localhost` inside the container, it reaches your host machine.

See [LOCALHOST-HANDLING.md](LOCALHOST-HANDLING.md) for details.

### My localhost:3000 server isn't accessible!

1. Check server is running on host: `curl localhost:3000` (outside container)
2. Inside container, webserver should be auto-detected
3. Try explicit: `curl http://host.docker.internal:3000`
4. Check `mcp-server-webserver-env` status: `mcp` command

### Can the container access my database on localhost?

Yes! MySQL, PostgreSQL, Redis, etc. running on `localhost:3306`, `localhost:5432`, `localhost:6379` on host are accessible from container.

### Can I expose container ports to host?

Yes! Edit `docker-compose.override.yml`:

```yaml
services:
  claude-dev:
    ports:
      - "8080:8080"  # Map container:8080 to host:8080
```

---

## MCP Servers

### What MCP servers are included?

11 pre-configured servers:

**Core**:
1. `mcp-server-filesystem` - File operations
2. `mcp-server-memory` - In-memory storage
3. `mcp-server-git` - Git operations
4. `mcp-server-sqlite` - SQLite database

**Custom Context Servers**:
5. `webserver-env` - External webserver monitoring
6. `tailwind-context` - Tailwind CSS v4.1 docs
7. `daisyui-context` - DaisyUI component library
8. `playwright-context` - Playwright testing docs
9. `playwright-advanced-context` - Advanced patterns
10. `vite-hmr-context` - Vite HMR help
11. `claude-flow-context` - Claude Flow automation

### How do I check MCP server status?

Inside container:
```bash
mcp                  # Show all MCP servers and their status
```

### Can I add custom MCP servers?

Yes! Edit `/home/claude/mcp/config.json` inside container or in your project's `.claude/mcp.json` file.

### Where are MCP context files stored?

- **System**: `/opt/mcp-assets/` (read-only, pre-cached)
- **User**: `/home/claude/mcp/` (symlinked to system)
- **Project**: `.claude/` (optional overrides)

---

## Permissions & Security

### Why can't Claude run `rm -rf /` or `dd`?

Dangerous commands are blocked by default in `.claude/settings.local.json`:

```json
{
  "disallowed_commands": ["rm -rf", "dd if=", "mkfs"]
}
```

You can override this per-project if needed.

### Can Claude push to GitHub?

Git push is **blocked by default** for safety. To enable:

Add to `.claude/settings.local.json`:
```json
{
  "allowed_commands": ["git push"]
}
```

### Does the container have sudo access?

Yes, user `claude` (uid 1010) has passwordless sudo for flexibility. The container is isolated from host, so this is safe.

### Can the container access files outside my project?

No! Only the current directory is mounted at `/var/www/html`. The container cannot read or modify files outside the project.

### How do I run as root (backdoor mode)?

```bash
claude-dev --root    # Dev environment as root
claude-flow --root   # Flow environment as root
```

Use only for debugging/troubleshooting.

---

## Development Tools

### What languages are supported?

- **Node.js 22** (npm, yarn, pnpm, bun)
- **PHP 8.3** (composer)
- **Python 3.12** (pip, pipenv, poetry)
- **Ruby 3.2** (bundler)
- **Go 1.21**
- **Rust 1.75** (cargo)

### What about databases?

**Included**:
- SQLite (with mcp-server-sqlite)

**Accessible via localhost**:
- MySQL/MariaDB on host
- PostgreSQL on host
- Redis on host
- MongoDB on host

### Can I install additional packages?

Yes!

```bash
# Node packages
npm install -g some-package

# Python packages
pip install some-package

# System packages (Alpine - dev only)
sudo apk add --no-cache package-name

# System packages (Debian - flow only)
sudo apt-get update && sudo apt-get install -y package-name
```

**Note**: Packages installed at runtime are NOT persisted. Add to Dockerfile for permanent installation.

---

## Playwright (claude-flow only)

### How do I run Playwright tests?

```bash
playwright test                      # Run all tests
playwright test --headed             # Show browser
playwright test --debug              # Debug mode
playwright codegen                   # Generate test code
```

Alias available: `pwt` = `playwright test`

### Where should I save tests and screenshots?

**CRITICAL - Always use these directories**:

- **Tests**: `playwright/tests/*.spec.js`
- **Screenshots**: `playwright/results/*.png`
- **Reports**: `playwright/report/`

```javascript
await page.screenshot({ path: 'playwright/results/screenshot.png' });
```

### Which browsers are available?

- Chromium (headless and headed)
- Firefox (headless and headed)
- WebKit (headless and headed)

```javascript
const { chromium, firefox, webkit } = require('playwright');
```

### Can I test against external websites?

Yes! Playwright can test any website accessible from the container.

---

## Git & Commits

### What is the `commit` command?

AI-powered git commit message generator using Claude Code CLI.

```bash
git add .
commit              # Generates smart commit message
git push
```

### How does TRON-ID work?

Project tracking IDs for commits. Sourced from (in order):

1. `TRON_ID` environment variable
2. Branch name pattern: `feature/1234-description` → `1234`
3. `.claude/.tron-id` file
4. Interactive prompt

Set via:
```bash
export TRON_ID="1234"                # Session
echo "1234" > .claude/.tron-id       # Project
```

### Can I customize commit message format?

Edit `bin/git-commit-ai` to change the prompt or format.

---

## Troubleshooting

### Container won't start

```bash
# Check Docker is running
docker info

# Check for port conflicts
docker ps -a

# Remove old containers
claude-dev --clean
claude-dev
```

### Claude Code won't authenticate

```bash
# Inside container
claude auth login

# If that fails, check credentials volume
docker volume inspect claude-dev-data
```

### MCP servers not loading

```bash
# Check MCP status
mcp

# Verify config
cat /home/claude/mcp/config.json

# Check symlinks
ls -la /home/claude/mcp/
```

### Performance is slow

```bash
# Check container resources
docker stats

# Increase Docker Desktop resources:
# Docker Desktop → Settings → Resources → Increase CPU/Memory

# Use dev instead of flow if you don't need Playwright
claude-dev
```

### "Permission denied" errors

```bash
# Check file ownership
ls -la

# Fix permissions (outside container)
sudo chown -R $(id -u):$(id -g) .

# Or run as root temporarily
claude-dev --root
```

---

## Updates & Maintenance

### How do I update Claude Docker?

```bash
claude-update --check        # Check for updates
claude-update                # Interactive update
```

Or manually:
```bash
curl -sSL https://raw.githubusercontent.com/andreashurst/claude-docker/main/install.sh | bash
docker pull andreashurst/claude-docker:latest-dev
docker pull andreashurst/claude-docker:latest-flow
```

### How do I check container health?

```bash
claude-health               # Check all containers
```

### How do I see Docker image sizes?

```bash
docker-image-report         # Detailed analysis
```

---

## Advanced

### Can I customize the Docker Compose config?

Yes! Edit `docker-compose.override.yml` in your project:

```yaml
services:
  claude-dev:
    environment:
      - CUSTOM_VAR=value
    volumes:
      - ./custom:/custom
    ports:
      - "8080:8080"
```

### Can I use a different base image?

Not recommended, but you can rebuild:

```bash
git clone https://github.com/andreashurst/claude-docker.git
cd claude-docker
# Edit docker/Dockerfile.dev or docker/Dockerfile.flow
./docker/.build.sh
```

### How do I contribute?

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## Still Have Questions?

- **Documentation**: [README.md](README.md)
- **Issues**: [GitHub Issues](https://github.com/andreashurst/claude-docker/issues)
- **Discussions**: [GitHub Discussions](https://github.com/andreashurst/claude-docker/discussions)
- **Security**: [SECURITY.md](.github/SECURITY.md)

---

**Last Updated**: 2024-12-30
