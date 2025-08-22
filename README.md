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
- ✅ **Internal web server** on port 80 (accessible from host on port 8080)

## Requirements

- Docker installed and running
- Internet connection (for Docker Hub image download)

## Internal Web Server (claude-flow only)

The claude-flow environment includes an internal Python HTTP server for Playwright testing:

- **Auto-detection**: Automatically detects `public`, `src`, `dist`, or `build` directories in your mounted project
- **Custom directory**: Prompts for custom directory if standard ones aren't found
- **Port mapping**: Internal port 80 → Host port 8080
- **Access URLs**:
  - From container/Playwright: `http://localhost:80`
  - From host browser: `http://localhost:8080`

### How Claude Can Use Playwright

Claude Code has full access to Playwright and can run tests directly. The MCP configuration tells Claude about the internal web server. Example:

```javascript
// Claude can create and run this test automatically
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  
  // Navigate to the internal web server
  await page.goto('http://localhost:80');
  
  // Perform tests
  const title = await page.title();
  console.log('Page title:', title);
  
  await browser.close();
})()
```

### Testing the Web Server

```bash
# Generate Playwright tests interactively
playwright codegen http://localhost:80

# Check if web server is running
ps aux | grep "[p]ython3 -m http.server"

# View web server logs
tail -f /var/log/webserver.log
```

## Docker Hub Images

- `andreashurst/claude-docker:latest-dev`
- `andreashurst/claude-docker:latest-flow`

Built automatically via GitHub Actions with multi-platform support (AMD64/ARM64).