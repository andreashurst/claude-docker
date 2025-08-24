# Claude Docker Entrypoint Scripts

The Docker entrypoint scripts have been refactored to separate container initialization from login information display.

## Structure

### Container Initialization (entrypoint.*.sh)
- **entrypoint.dev.sh**: Initializes Claude Dev environment
- **entrypoint.flow.sh**: Initializes Claude Flow environment with additional tools

These scripts:
1. Set up environment markers (/.claude-dev-env or /.claude-flow-env)
2. Detect project type (DDEV or Standard)
3. Configure frontend URL (asked once at container start)
4. Copy info scripts to /usr/local/bin/
5. Set up .bashrc for automatic info display on login
6. Start the interactive shell

### Information Display Scripts
- **claude.info.sh**: Shows environment info on each login
- **claude.help.sh**: Extended help documentation (run with `claude-help`)

## How it Works

1. **On Container Start**:
   - Entrypoint script runs once
   - Asks for frontend URL configuration
   - Sets up the environment
   - Creates .bashrc with info display

2. **On Each Login** (docker exec -it container bash):
   - .bashrc is sourced
   - claude-info script displays current environment status
   - No repeated URL prompts

## Dockerfile Integration

Add these lines to your Dockerfile:

```dockerfile
# Copy all docker scripts
COPY docker/*.sh /docker/

# Make entrypoint executable
RUN chmod +x /docker/entrypoint.*.sh

# Set the appropriate entrypoint
ENTRYPOINT ["/docker/entrypoint.flow.sh"]  # or entrypoint.dev.sh
```

## Benefits

- **Clean Separation**: Container init vs login info
- **Better UX**: URL prompt only on container start, not on every login
- **Persistent Config**: Frontend URL saved between sessions
- **Helpful Commands**: `claude-info` and `claude-help` available anytime
- **User-specific**: Different configs for root (dev) vs claude user (flow)

## Environment Markers

- `/.claude-dev-env`: Marks a Dev container
- `/.claude-flow-env`: Marks a Flow container

These files help scripts identify the environment type and show appropriate information.