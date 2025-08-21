# Claude Docker Shell Commands

This directory contains standalone shell commands for running Claude environments using Docker Hub images.

## Commands

- **`claude-dev`** - Basic Claude Code development environment
- **`claude-flow`** - Advanced Claude Flow environment with Playwright, Deno, and MCP servers

## Usage

### From Repository
```bash
# Basic environment
./bin/claude-dev

# Advanced environment  
./bin/claude-flow
```

### Standalone Usage
Download and use individual scripts:

```bash
# Download claude-dev
curl -o claude-dev https://raw.githubusercontent.com/andreashurst/claude-docker/main/bin/claude-dev
chmod +x claude-dev
./claude-dev

# Download claude-flow
curl -o claude-flow https://raw.githubusercontent.com/andreashurst/claude-docker/main/bin/claude-flow  
chmod +x claude-flow
./claude-flow
```

## Features

### claude-dev
- ✅ **Alpine Linux** base for minimal footprint
- ✅ **Claude Code CLI** pre-installed
- ✅ **Host networking** for localhost access
- ✅ **Persistent volumes** for cache and config

### claude-flow
- ✅ **All claude-dev features** plus:
- ✅ **Deno runtime** for modern JavaScript/TypeScript
- ✅ **Playwright** with browsers pre-installed
- ✅ **MCP servers** (filesystem, git, playwright)
- ✅ **Auto-generated MCP configuration**
- ✅ **Python 3** with pip packages

## Requirements

- Docker installed and running
- Internet connection (for Docker Hub image download)

## Docker Hub Images

- `andreashurst/claude-docker:latest-dev`
- `andreashurst/claude-docker:latest-flow`

Built automatically via GitHub Actions with multi-platform support (AMD64/ARM64).