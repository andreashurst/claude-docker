# Migration Guide

Guide for migrating to Claude Docker from other Claude Code setups.

---

## From Native Claude Code

If you're currently running Claude Code directly on your host machine, here's how to migrate.

### Why Migrate?

✅ **Security**: Isolated container environment
✅ **Consistency**: Same environment across machines
✅ **Pre-configured**: 11 MCP servers included
✅ **Localhost Mapping**: Automatic webserver detection
✅ **No Host Pollution**: Tools stay in container

### Migration Steps

1. **Install Claude Docker**

```bash
curl -sSL https://raw.githubusercontent.com/andreashurst/claude-docker/main/install.sh | bash
```

2. **Backup Your Credentials**

```bash
# Native credentials location
cp -r ~/.config/claude ~/.config/claude.backup
```

3. **First Run**

```bash
cd your-project/
claude-dev              # Starts container

# Inside container
claude auth login       # Login with your credentials
```

4. **Verify MCP Servers**

```bash
mcp                     # Should show 11 servers loaded
```

5. **Test Localhost Mapping**

```bash
# Start a server on host (e.g., localhost:3000)
# Inside container:
curl localhost:3000     # Should reach host server
```

### What Changes?

**Before (Native)**:
- Claude runs directly on host
- MCP servers manually configured
- Tools installed globally on host
- Credentials in `~/.config/claude`

**After (Docker)**:
- Claude runs in isolated container
- 11 MCP servers pre-configured
- Tools isolated in container
- Credentials in Docker volume

### Can I Run Both?

Yes! Native and Docker installations don't conflict.

```bash
# Native
claude                  # Runs on host

# Docker
claude-dev              # Runs in container
```

---

## From Other Docker Setups

### From Custom Docker Containers

If you built your own Docker container for Claude Code:

1. **Compare Features**

Check what Claude Docker includes:
- 11 pre-configured MCP servers
- Multi-language support (Node, PHP, Python, Ruby, Go, Rust)
- Automatic localhost mapping
- Playwright testing (claude-flow)
- Pre-cached documentation

2. **Export Custom Configuration**

```bash
# In your current container
cat ~/.config/claude/config.json > ~/claude-config.backup.json
cat ~/.claude/settings.local.json > ~/claude-settings.backup.json
```

3. **Import to Claude Docker**

```bash
# Start Claude Docker
claude-dev

# Inside container
mkdir -p ~/.config/claude
cp /var/www/html/claude-config.backup.json ~/.config/claude/config.json
```

### From docker-compose Setups

If you have a `docker-compose.yml` with Claude Code:

1. **Claude Docker Creates Override File**

Claude Docker uses `docker-compose.override.yml` to avoid conflicts with your existing `docker-compose.yml`.

2. **Integration Example**

Your existing `docker-compose.yml`:
```yaml
services:
  mysql:
    image: mysql:8
    ports:
      - "3306:3306"

  app:
    image: your-app
    ports:
      - "3000:3000"
```

Run Claude Docker in same directory:
```bash
claude-dev              # Creates docker-compose.override.yml
```

Both services run together! Claude can access `http://localhost:3000`.

---

## From Devcontainers

### VS Code Devcontainer Migration

If you're using VS Code Remote Containers:

1. **Keep Devcontainer for VS Code**

Your `.devcontainer/devcontainer.json` remains unchanged.

2. **Add Claude Docker**

```bash
# In same project
claude-dev              # Runs alongside devcontainer
```

3. **Share Configuration**

Both can share project files:
- `.claude/settings.local.json` - Claude permissions
- `.gitignore` - Both respect gitignore
- `package.json` - Both use same dependencies

### Why Use Both?

- **Devcontainer**: VS Code development with extensions
- **Claude Docker**: AI-powered coding with Claude Code CLI

They complement each other!

---

## From GitHub Codespaces

### Migrating from Codespaces

If you're developing in GitHub Codespaces:

1. **Local Development with Claude Docker**

```bash
# Clone repo locally
git clone https://github.com/your-org/your-repo.git
cd your-repo

# Start Claude Docker
claude-dev
```

2. **Cloud + Local Workflow**

- **Codespaces**: Cloud development, VS Code web
- **Claude Docker**: Local development with Claude AI

3. **Sync Configuration**

Add to your repo:
```bash
.claude/settings.local.json     # Claude permissions
docker-compose.override.yml     # Claude Docker config (in .gitignore)
```

Commit `.claude/settings.local.json` for team consistency.

---

## From GitPod

### GitPod to Claude Docker

Similar to Codespaces migration:

1. **Install Docker Locally**

```bash
# Mac
brew install --cask docker

# Linux
curl -fsSL https://get.docker.com | sh
```

2. **Clone and Run**

```bash
git clone your-repo
cd your-repo
claude-dev
```

3. **Configuration Sync**

GitPod uses `.gitpod.yml`, which doesn't conflict with `docker-compose.override.yml`.

---

## From Anthropic Workbench

### Workbench to Docker Migration

If you're using Anthropic's web workbench:

1. **Why Migrate?**

- **Offline**: Works without internet (after initial pull)
- **Localhost**: Access your local servers
- **Integration**: Git, databases, full file system
- **Speed**: No network latency
- **Privacy**: Code stays on your machine

2. **Setup**

```bash
# Install
curl -sSL https://raw.githubusercontent.com/andreashurst/claude-docker/main/install.sh | bash

# Use same API key
claude-dev
claude auth login       # Use your Anthropic account
```

3. **Workflow Changes**

**Before (Workbench)**:
- Upload files to web interface
- Limited to web environment
- No localhost access

**After (Docker)**:
- Full file system access
- Any language/tool
- Localhost mapping
- Git integration

---

## Migration Checklist

Use this checklist for any migration:

### Pre-Migration

- [ ] Backup current Claude credentials
- [ ] Export custom MCP configurations
- [ ] Document custom workflows
- [ ] Note any special tools/dependencies
- [ ] Check disk space (need ~1-3GB for images)

### Installation

- [ ] Install Claude Docker: `curl -sSL ... | bash`
- [ ] Verify installation: `claude-dev --version`
- [ ] Pull images: `docker pull andreashurst/claude-docker:latest-dev`
- [ ] Test Docker: `docker run hello-world`

### Configuration

- [ ] Start container: `claude-dev`
- [ ] Login to Claude: `claude auth login`
- [ ] Verify MCP servers: `mcp`
- [ ] Test localhost mapping: `curl localhost`
- [ ] Import custom settings (if any)

### Validation

- [ ] Run sample project
- [ ] Test git operations
- [ ] Verify file access
- [ ] Check package managers (npm, pip, etc.)
- [ ] Confirm MCP servers working
- [ ] Test any custom workflows

### Cleanup (Optional)

- [ ] Remove old Docker images (if replacing custom setup)
- [ ] Archive old configuration files
- [ ] Update team documentation
- [ ] Uninstall native Claude (if desired)

---

## Rollback Plan

If you need to revert:

### Option 1: Keep Both

```bash
# Use native when needed
claude

# Use Docker when preferred
claude-dev
```

### Option 2: Complete Rollback

```bash
# Stop and remove Docker setup
claude-dev --clean

# Restore native credentials
cp ~/.config/claude.backup/* ~/.config/claude/

# Uninstall Claude Docker (optional)
sudo rm /usr/local/bin/claude-dev
sudo rm /usr/local/bin/claude-flow
sudo rm /usr/local/bin/claude-health
sudo rm /usr/local/bin/claude-update
sudo rm /usr/local/bin/docker-image-report
sudo rm /usr/local/bin/claude-docker.lib.sh
```

---

## Common Migration Issues

### "Docker daemon not running"

```bash
# Mac: Start Docker Desktop
open -a Docker

# Linux: Start Docker service
sudo systemctl start docker
```

### "Port already in use"

Another service using port 80/443:

```bash
# Check what's using port
sudo lsof -i :80

# Stop conflicting service or change port in docker-compose.override.yml
```

### "Permission denied"

```bash
# Add user to docker group (Linux)
sudo usermod -aG docker $USER
newgrp docker

# Or use sudo
sudo claude-dev
```

### "Cannot connect to localhost"

```bash
# Inside container, check webserver detection
mcp

# Manually test
curl http://host.docker.internal:3000
```

---

## Getting Help

### Migration Support

- **Issues**: [GitHub Issues](https://github.com/andreashurst/claude-docker/issues)
- **Discussions**: [GitHub Discussions](https://github.com/andreashurst/claude-docker/discussions)
- **Documentation**: [README.md](README.md), [FAQ.md](FAQ.md)

### Reporting Migration Problems

When reporting issues, include:

1. Previous setup (native, custom docker, devcontainer, etc.)
2. Operating system and Docker version
3. Error messages or unexpected behavior
4. Steps you've tried
5. Output of `claude-health` and `docker ps`

---

**Last Updated**: 2024-12-30
