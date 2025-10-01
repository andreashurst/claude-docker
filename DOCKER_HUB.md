# Claude Docker 🐳

**Run Claude Code CLI securely in Docker containers with automatic localhost mapping.**

[![Docker Pulls](https://img.shields.io/docker/pulls/andreashurst/claude-docker)](https://hub.docker.com/r/andreashurst/claude-docker)
[![Docker Image Size](https://img.shields.io/docker/image-size/andreashurst/claude-docker/latest-dev)](https://hub.docker.com/r/andreashurst/claude-docker)
[![GitHub Stars](https://img.shields.io/github/stars/andreashurst/claude-docker)](https://github.com/andreashurst/claude-docker)

## Quick Start

```bash
# Install globally (one-time)
curl -sSL https://raw.githubusercontent.com/andreashurst/claude-docker/main/install.sh | bash

# Run in any project
cd your-project/
claude-dev
```

That's it! Claude Code starts automatically.

## Two Images

### `andreashurst/claude-docker:latest-dev`
**Development environment** - Lightweight Alpine-based image

- **Base**: Node.js 22 Alpine
- **Languages**: Node, PHP 8.3, Python 3, Ruby, Go, Rust
- **Package Managers**: npm, yarn, pnpm, bun, pip, composer
- **Tools**: Git, SQLite, ImageMagick, FFmpeg
- **MCP Servers**: 11 pre-configured servers
- **Size**: ~800MB
- **Use Case**: General development

```bash
docker pull andreashurst/claude-docker:latest-dev
docker run -it -v $(pwd):/var/www/html andreashurst/claude-docker:latest-dev
```

### `andreashurst/claude-docker:latest-flow`
**Testing environment** - Full-featured Debian-based image

- **Base**: Node.js 22 Bookworm
- **Everything from dev** plus:
- **Playwright**: Chromium, Firefox, WebKit browsers
- **Deno**: Additional runtime
- **Claude Flow**: Advanced automation
- **Python MCP**: mcp-server-git, mcp-server-sqlite
- **Size**: ~2.5GB
- **Use Case**: Browser automation, E2E testing

```bash
docker pull andreashurst/claude-docker:latest-flow
docker run -it -v $(pwd):/var/www/html andreashurst/claude-docker:latest-flow
```

## Features

✅ **Secure Isolation** - Runs as non-root user (uid 1010)
✅ **Localhost Mapping** - `curl localhost` works automatically
✅ **Persistent Credentials** - Stored in Docker volumes
✅ **11 MCP Servers** - Pre-configured: Tailwind, Playwright, Git, SQLite, etc.
✅ **AI Git Commits** - `commit` command generates smart messages
✅ **Instant Startup** - No runtime installations
✅ **Offline Ready** - Everything pre-cached

## Environment Variables

```bash
docker run -it \
  -e PROJECT_TYPE=node \
  -e NODE_ENV=development \
  -v $(pwd):/var/www/html \
  -v claude-dev-data:/home/claude \
  andreashurst/claude-docker:latest-dev
```

## Volumes

- **`/var/www/html`** - Your project directory (mount)
- **`/home/claude`** - Credentials & data (volume)
- **`/opt/mcp-assets`** - Pre-cached MCP files (read-only)

## Commands Available Inside Container

```bash
# Development
commit              # AI-generated git commit
mcp                 # Check MCP server status
gs                  # git status (alias)
gd                  # git diff (alias)

# Playwright (flow only)
playwright test     # Run tests
playwright codegen  # Generate tests
pwt                 # playwright test (alias)
```

## Supported Platforms

- **linux/amd64** (Intel/AMD)
- **linux/arm64** (Apple Silicon)

## Pre-configured MCP Servers

1. **filesystem** - File operations
2. **memory** - In-memory storage
3. **git** - Git operations
4. **sqlite** - SQLite database
5. **webserver-env** - Localhost monitoring
6. **playwright-context** - Playwright docs
7. **playwright-advanced-context** - Advanced patterns
8. **tailwind-context** - Tailwind CSS v4.1
9. **daisyui-context** - DaisyUI components
10. **vite-hmr-context** - Vite HMR help
11. **claude-flow-context** - Automation framework

## Version Tags

- `latest-dev` - Latest dev image
- `latest-flow` - Latest flow image
- `3.2.0-dev` - Specific version dev
- `3.2.0-flow` - Specific version flow

## Security

- ✅ Non-root user (claude, uid 1010)
- ✅ No host access outside project
- ✅ Read-only system files
- ✅ Git push blocked by default
- ✅ Dangerous commands blocked

## Support

- **GitHub**: [andreashurst/claude-docker](https://github.com/andreashurst/claude-docker)
- **Issues**: [Report Bug](https://github.com/andreashurst/claude-docker/issues)
- **Docs**: [Full Documentation](https://github.com/andreashurst/claude-docker#readme)

## License

MIT License - See [LICENSE](https://github.com/andreashurst/claude-docker/blob/main/LICENSE)

---

**Built with ❤️ for developers who value security and simplicity.**

**Key Philosophy**: Everything pre-configured, nothing to install at runtime, works offline.
