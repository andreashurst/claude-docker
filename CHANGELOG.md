# Changelog

All notable changes to Claude Docker will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `claude-health` command for checking container status
- `mcp-status` command (alias: `mcp`) for MCP server overview
- `commit` command for AI-generated git commits with TRON-ID support
- Interactive TRON-ID prompt when ID not found
- Install script health check (warns if containers running)
- Timeout handling for git-commit-ai (60s with retry)
- Docker Compose health checks for containers
- Automated tests: `tests/test-install.sh`
- MCP validation: `tests/validate-mcp.sh`
- Comprehensive README.md with workflows and advanced usage
- Permission granularity with explicit allow/deny lists
- npm commands to allowed permissions (install, run, test, build)
- git stash to allowed permissions
- Dangerous commands to deny list (git reset --hard, git clean, mkfs, fdisk)

### Changed
- **BREAKING**: `.tron-id` moved to `.claude/.tron-id` (automatically ignored)
- MCP files copied earlier in Dockerfile for better layer caching
- Entrypoint scripts cleaned up: removed 192 lines of commented code (49% smaller)
- README.md expanded from 3.2KB to 6.6KB with comprehensive documentation
- Permission patterns now more granular (e.g., `git:status` and `git:status:*`)
- Docker layer caching optimized for faster rebuilds

### Fixed
- Double-slash pattern in permissions (`//` → `/`)
- Redundant permission paths removed

### Security
- Git push now explicitly denied by default
- Explicit deny list for destructive commands
- Granular command permissions instead of wildcards

## [3.2.0] - 2025-09-30

### Added
- npx-wrapper for transparent `npx playwright` → `playwright` redirection
- Standardized Playwright directory structure
- MCP context files for 7 custom servers

### Changed
- 45+ occurrences of `npx playwright` corrected to `playwright`
- Unified all MCP context files with consistent commands
- Standardized on `playwright/tests/`, `playwright/results/`, `playwright/report/`

### Fixed
- Inconsistent Playwright command usage across MCP files
- Directory path inconsistencies in documentation

## [3.1.0] - 2025-01-13

### Added
- KISS principle implementation for MCP structure
- 11 pre-configured MCP servers
- Pre-cached context files for Tailwind, DaisyUI, Playwright
- Automatic project settings initialization

### Changed
- MCP files moved to `/opt/mcp-assets/` (outside project)
- Symlinks in `/home/claude/mcp/` for accessibility
- 60% code reduction in MCP structure

## [3.0.0] - 2025-01-10

### Added
- Claude Flow environment with Playwright and browser automation
- Separate `claude-dev` and `claude-flow` commands
- Docker volume persistence for credentials
- Project type auto-detection

### Changed
- Split into two Docker images: dev and flow
- Non-root user (claude, uid 1010) for security
- Alpine Linux base for smaller images

## [2.0.0] - 2024-12-15

### Added
- Docker Compose configuration
- Localhost mapping support
- MCP server integration

### Changed
- Migrated from single script to Docker-based architecture

## [1.0.0] - 2024-11-01

### Added
- Initial release
- Basic Claude Code CLI wrapper
- Directory mounting

---

## Version Guidelines

### Major (X.0.0)
- Breaking changes to container structure
- Breaking changes to command interface
- Major architectural changes

### Minor (x.Y.0)
- New features (commands, MCP servers, etc.)
- Non-breaking enhancements
- New container capabilities

### Patch (x.y.Z)
- Bug fixes
- Documentation updates
- Performance improvements
- Security patches

## Migration Guides

### Upgrading from 3.1.x to 3.2.x
No breaking changes. Existing containers continue to work.

New features:
- `claude-health` - Check container status
- `mcp` - Check MCP server status
- `commit` - AI git commits

### Upgrading from 3.0.x to 3.1.x
No breaking changes. MCP files moved to system location but remain accessible.

### Upgrading from 2.x to 3.0
**Breaking changes:**
- Command renamed: `claude-docker` → `claude-dev`
- New command: `claude-flow` for testing
- Volumes now named: `claude-dev-data` and `claude-flow-data`

Migration:
```bash
# Stop old containers
docker stop claude-docker

# Install new version
curl -sSL https://raw.githubusercontent.com/andreashurst/claude-docker/main/install.sh | bash

# Start new container
claude-dev  # or claude-flow
```

## Support

- **Issues**: [GitHub Issues](https://github.com/andreashurst/claude-docker/issues)
- **Documentation**: [README.md](README.md)
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)
