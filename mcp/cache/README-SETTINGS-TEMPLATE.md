# Claude Project Settings Template

## Purpose

This template provides pre-configured settings for new Claude Code projects, enabling:

1. **Pre-approved permissions** - Common safe operations don't require user approval
2. **All MCP servers** - Filesystem, memory, git, sqlite, and custom context servers
3. **Trust pre-accepted** - No trust dialog on first run

## What's Included

### Permissions (Pre-approved)

**File & System Operations:**
- `Bash(chmod:*)` - Change file permissions
- `Bash(cat:*)` - Read file contents
- `Bash(find:*)` - Search for files
- `Bash(tree:*)` - Display directory structure
- `Bash(ls:*)` - List files
- `Bash(pwd:*)` - Print working directory
- `Bash(which:*)` - Locate commands
- `Bash(whoami:*)` - Show current user
- `Bash(readlink:*)` - Follow symlinks

**Development Tools:**
- `Bash(node:*)` - Run Node.js commands
- `Bash(npm:list*)` - List installed packages
- `Bash(npm:--version*)` - Check npm version
- `Bash(playwright:*)` - Run Playwright tests

**Network & System Monitoring:**
- `Bash(curl:*)` - Make HTTP requests (with localhost mapping)
- `Bash(wget:*)` - Download files
- `Bash(netstat:*)` - Check network connections
- `Bash(ss:*)` - Check socket statistics
- `Bash(ps:*)` - List processes
- `Bash(top:*)` - Monitor system resources

**Git Operations (Safe):**
- `Bash(git:status*)` - Check repository status
- `Bash(git:log*)` - View commit history
- `Bash(git:diff*)` - View changes
- `Bash(git:show*)` - Show commit details
- `Bash(git:branch*)` - List/manage branches
- `Bash(git:fetch*)` - Fetch from remote
- `Bash(git:pull*)` - Pull changes
- `Bash(git:add:*)` - Stage changes
- `Bash(git:commit:*)` - Create commits
- `Bash(git:checkout:*)` - Switch branches

**MCP Access:**
- `Read(/home/claude/mcp/**)` - Read MCP files (symlinks to /opt/mcp-assets)

**Important:** `/home/claude/mcp/` is outside the project directory, so Claude Code won't ask for permission. The path follows symlinks to `/opt/mcp-assets/` automatically.

### Permissions (Explicitly Denied)

Dangerous operations that require explicit user approval:
- `Bash(git:push*)` - Push to remote (prevents accidental pushes)
- `Bash(rm:-rf*)` - Recursive force delete
- `Bash(sudo:rm*)` - Delete with sudo
- `Bash(dd:*)` - Low-level disk operations

### MCP Servers

1. **filesystem** - File operations within `/var/www/html`
2. **memory** - In-memory key-value storage
3. **git** - Git repository operations
4. **sqlite** - SQLite database access (environment facts from CLAUDE.md)
5. **webserver-env** - External webserver monitoring (with Host header support)
6. **playwright-context** - Playwright testing documentation
7. **playwright-advanced-context** - Advanced Playwright patterns
8. **tailwind-context** - Tailwind CSS v4.1 utilities
9. **daisyui-context** - DaisyUI component library
10. **vite-hmr-context** - Vite HMR configuration
11. **claude-flow-context** - Claude Flow automation framework

### Trust Settings

- `hasTrustDialogAccepted: true` - User has accepted trust for this project

## How It Works

### During Docker Build

The Dockerfile copies this template to `/opt/mcp-cache/`:

```dockerfile
COPY mcp/cache/claude-project-settings-template.json /opt/mcp-cache/
```

### During Container Startup

The entrypoint script checks if `.claude/settings.local.json` exists:

```bash
if [ ! -f /var/www/html/.claude/settings.local.json ]; then
  mkdir -p /var/www/html/.claude
  cp /opt/mcp-cache/claude-project-settings-template.json /var/www/html/.claude/settings.local.json
  echo "Claude Code settings initialized"
fi
```

### Result

New projects start with:
- ✅ All MCP servers enabled
- ✅ Common operations pre-approved
- ✅ No trust dialog
- ✅ No permission popups for MCP files

## Customization

Users can customize their settings by editing:
- `/var/www/html/.claude/settings.local.json` (persisted in project)
- `/home/claude/.claude.json` (persisted in Docker volume)

## Security Notes

### What's Safe

These permissions are safe because:
1. **Read-only operations** - `cat`, `find`, `tree`, `ls`, `readlink`
2. **Safe git operations** - View status, diffs, logs (no push!)
3. **MCP files outside project** - Can't accidentally modify project files
4. **Standard tools** - `node`, `playwright`, `curl` with localhost mapping
5. **Network inspection** - `netstat`, `ss`, `ps` are read-only
6. **Explicit denies** - Dangerous operations blocked (git push, rm -rf, dd)

### What Requires Approval

These require explicit user approval:
- **Git push** - Explicitly denied to prevent accidents
- **File deletion** - `rm` (except via Edit/Delete tool with confirmation)
- **Package installation** - `npm install`, `pip install`
- **Database writes** - Must use sqlite MCP tool with confirmation
- **System modifications** - Most `sudo` commands
- **Dangerous operations** - `rm -rf`, `dd`, etc.

## Troubleshooting

### Settings Not Applied

If Claude Code asks for permissions that should be pre-approved:

1. Check if settings file exists:
   ```bash
   ls -la /var/www/html/.claude/settings.local.json
   ```

2. Verify MCP servers are running:
   ```bash
   # In Claude Code, run:
   read /home/claude/.claude.json
   ```

3. Restart container:
   ```bash
   claude-dev --clean  # or claude-flow --clean
   ```

### Permission Denied

If you get "permission denied" for MCP files:

1. Check symlinks exist:
   ```bash
   ls -la /home/claude/mcp/
   ```

2. Verify permissions in settings:
   ```bash
   cat /var/www/html/.claude/settings.local.json | jq .permissions
   ```

3. Verify the permission pattern is correct:
   - ✅ `"Read(/home/claude/mcp/**)"`

## Benefits

1. **Faster onboarding** - New users start with working configuration
2. **Consistent experience** - Same settings across all projects
3. **No surprises** - All permissions documented and explained
4. **Easy updates** - Template updated with Docker image
5. **Project isolation** - Each project can customize independently

## Related Files

- `claude-config-template.json` - Basic Claude configuration (merged into project settings)
- `init-environment-db.sql` - SQLite database initialization
- `bashrc.dev` / `bashrc.flow` - Shell environment configuration
