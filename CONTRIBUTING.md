# Contributing to Claude Docker

Thank you for considering contributing to Claude Docker! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Project Structure](#project-structure)
- [Coding Standards](#coding-standards)

## Code of Conduct

Be respectful, constructive, and professional. We're all here to make Claude Docker better.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/claude-docker.git
   cd claude-docker
   ```
3. **Add upstream remote**:
   ```bash
   git remote add upstream https://github.com/andreashurst/claude-docker.git
   ```

## Development Setup

### Prerequisites

- Docker Desktop (Mac/Windows) or Docker Engine (Linux)
- Bash (for scripts)
- jq (for JSON manipulation)
- Basic understanding of Docker, MCP, and Claude Code

### Local Testing

```bash
# Run installation tests
./tests/test-install.sh

# Build images locally
./docker/build.sh

# Test locally built images
docker run --rm -it claude-docker:local-dev bash
docker run --rm -it claude-docker:local-flow bash
```

## Making Changes

### Branch Naming

- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation only
- `refactor/description` - Code refactoring
- `test/description` - Test additions/changes

Example:
```bash
git checkout -b feature/add-golang-support
```

### Commit Messages

Follow the format used in `git-commit-ai`:

```
# [Title] - YYYY-MM-DD

## Übersicht
Brief overview in German (or English)

## Hauptänderungen

### 1. [Category]
**Problem**: Description

**Lösung**:
- Change 1
- Change 2

## Geänderte Dateien

1. `path/to/file`
   - What changed
   - Why it changed
```

Or use simple conventional commits:
```
feat: add golang compiler to dev image
fix: correct MCP server path in config
docs: update installation instructions
```

### What to Contribute

**Good Contributions:**
- Bug fixes
- New MCP servers for popular frameworks
- Documentation improvements
- Performance optimizations
- New useful aliases or commands
- Test coverage improvements

**Please Discuss First:**
- Major architectural changes
- Breaking changes
- New languages/tools in Docker images
- Changes to core functionality

## Testing

### Before Submitting

Run all tests:
```bash
# 1. Installation tests
./tests/test-install.sh

# 2. Build both images
./docker/build.sh

# 3. Test dev environment
docker run --rm -v $(pwd):/var/www/html claude-docker:local-dev \
  bash -c "node --version && php --version && python3 --version"

# 4. Test flow environment (if changed)
docker run --rm -v $(pwd):/var/www/html claude-docker:local-flow \
  bash -c "playwright --version && deno --version"

# 5. Validate MCP structure
docker run --rm -v $(pwd):/var/www/html claude-docker:local-dev \
  bash /var/www/html/tests/validate-mcp.sh

# 6. Check bash syntax
bash -n install.sh
bash -n bin/claude-dev
bash -n bin/claude-flow
```

### Test Checklist

- [ ] All existing tests pass
- [ ] New features have tests
- [ ] Documentation is updated
- [ ] CHANGELOG.md is updated
- [ ] No merge conflicts with main
- [ ] Images build successfully
- [ ] Bash syntax is valid

## Submitting Changes

1. **Update your fork**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Push to your fork**:
   ```bash
   git push origin feature/your-feature
   ```

3. **Create Pull Request** on GitHub:
   - Use the PR template
   - Link related issues
   - Describe changes clearly
   - Add screenshots if relevant

4. **Respond to feedback**:
   - Address review comments
   - Update PR as needed
   - Keep discussion focused

## Project Structure

```
claude-docker/
├── bin/                    # Global commands
│   ├── claude-dev         # Main launcher
│   ├── claude-flow        # Testing variant
│   ├── claude-health      # Health checker
│   ├── git-commit-ai      # AI commit tool
│   ├── mcp-status         # MCP status tool
│   └── claude-docker.lib.sh  # Shared library
│
├── docker/                # Docker definitions
│   ├── Dockerfile.dev     # Dev image
│   ├── Dockerfile.flow    # Flow image
│   └── bin/               # Container scripts
│       ├── entrypoint.dev
│       ├── entrypoint.flow
│       ├── curl-wrapper
│       └── npx-wrapper
│
├── mcp/                   # Model Context Protocol
│   ├── servers/           # Custom MCP servers (7 files)
│   ├── context/           # Pre-cached docs by tool
│   ├── cache/             # Build-time templates
│   └── config.json        # MCP configuration
│
├── tests/                 # Automated tests
│   ├── test-install.sh    # Installation tests
│   └── validate-mcp.sh    # MCP validation
│
├── .github/
│   └── workflows/         # CI/CD pipelines
│
└── docs/                  # Documentation
    ├── README.md
    ├── CHANGELOG.md
    ├── CLAUDE.md
    └── CONTRIBUTING.md
```

## Coding Standards

### Bash Scripts

```bash
# Use strict mode
set -e

# Use meaningful variable names
CONTAINER_NAME="claude-dev"

# Comment complex sections
# This function detects the project type
claude_docker_detect_project() {
    # ...
}

# Use consistent formatting
if [ "$STATUS" = "running" ]; then
    echo "Container is running"
fi
```

### Dockerfile

```dockerfile
# Comment each major section
# Install development languages

# Minimize layers
RUN apt-get update && apt-get install -y \
    package1 \
    package2 \
    && apt-get clean

# Use specific versions when critical
RUN npm install -g playwright@1.40.0

# Clean up in same layer
RUN some-install && rm -rf /tmp/*
```

### MCP Servers (JavaScript)

```javascript
#!/usr/bin/env node

// Use MCP SDK
const { Server } = require("@modelcontextprotocol/sdk/server/index.js");

// Document the server purpose
/**
 * Tailwind CSS Context Server
 * Provides cached Tailwind documentation
 */

// Handle errors gracefully
server.onerror = (error) => {
    console.error("[ERROR]", error);
};
```

### JSON Files

```json
{
  "key": "value",
  "array": [
    "item1",
    "item2"
  ]
}
```

Use `jq` to validate:
```bash
jq empty file.json
```

## Common Tasks

### Adding a New MCP Server

1. Create server file: `mcp/servers/your-server.js`
2. Add context files: `mcp/context/your-tool/`
3. Update config: `mcp/config.json`
4. Update Dockerfile if new dependencies needed
5. Document in README.md
6. Add tests to `validate-mcp.sh`

### Adding a New Language to Docker Images

1. Update `docker/Dockerfile.dev` (and/or `Dockerfile.flow`)
2. Add to project detection in `bin/claude-docker.lib.sh`
3. Update README.md features list
4. Update CLAUDE.md with usage examples
5. Test thoroughly
6. Update CHANGELOG.md

### Adding a New Command

1. Create script in `bin/`
2. Make executable: `chmod +x bin/your-command`
3. Update `install.sh` to copy it
4. Add to bashrc if should be alias
5. Document in README.md
6. Add tests to `test-install.sh`

## Documentation

### Update These When Relevant

- **README.md** - User-facing features, usage
- **CHANGELOG.md** - All changes (following Keep a Changelog)
- **CLAUDE.md** - Instructions for Claude Code AI
- **CONTRIBUTING.md** - Development guidelines
- Comments in code for complex logic

### Documentation Style

- **Concise** - Get to the point
- **Examples** - Show, don't just tell
- **Complete** - Cover edge cases
- **Updated** - Keep in sync with code

## Release Process

(For maintainers)

1. Update version in `bin/claude-dev` and `bin/claude-flow`
2. Update CHANGELOG.md with release date
3. Create git tag: `git tag -a v3.3.0 -m "Release 3.3.0"`
4. Push tag: `git push origin v3.3.0`
5. GitHub Actions will build and publish Docker images
6. Create GitHub Release with changelog

## Getting Help

- **Issues**: Check existing issues first
- **Discussions**: For questions and ideas
- **Discord**: (Link if available)
- **Email**: (Contact if available)

## Recognition

Contributors will be:
- Listed in release notes
- Mentioned in CHANGELOG.md
- Credited in commit messages

Thank you for contributing to Claude Docker! 🙏

---

**Questions?** Open an issue with the label `question`.
