# Docker Binary Wrappers

This directory contains wrapper scripts that enhance container functionality and ensure compatibility.

## Available Wrappers

### curl-wrapper
**Purpose**: Automatically maps `localhost` to `host.docker.internal` inside containers

**Usage**: Automatically installed in both dev and flow containers
```bash
# Automatically redirects localhost to host.docker.internal
curl http://localhost:3000  # Works inside container!
```

**Installation**:
```bash
./curl-wrapper-install
# Or manually:
cp curl-wrapper /usr/local/bin/curl
chmod +x /usr/local/bin/curl
```

### npx-wrapper
**Purpose**: Redirects `npx playwright` to global `playwright` command

**Why**: Playwright is globally installed in claude-flow container. This wrapper ensures compatibility when users or scripts use `npx playwright` commands.

**Usage**: Automatically installed in both dev and flow containers
```bash
# These commands are automatically redirected:
npx playwright test       → playwright test
npx playwright codegen    → playwright codegen
npx playwright install    → playwright install

# Other npx commands work normally:
npx create-react-app my-app  # Works as expected
```

**Installation**:
```bash
./npx-wrapper-install
# Or manually:
cp npx-wrapper /usr/local/bin/npx
chmod +x /usr/local/bin/npx
```

## Entrypoint Integration

Both wrappers are automatically installed during container startup:

**entrypoint.dev**:
```bash
cp /var/www/html/docker/bin/curl-wrapper /usr/local/bin/curl
cp /var/www/html/docker/bin/npx-wrapper /usr/local/bin/npx
```

**entrypoint.flow**:
```bash
cp /var/www/html/docker/bin/curl-wrapper /usr/local/bin/curl
cp /var/www/html/docker/bin/npx-wrapper /usr/local/bin/npx
```

## How Wrappers Work

Each wrapper:
1. Finds the real binary using `which -a` (avoiding self-reference)
2. Intercepts specific patterns
3. Either transforms the command or passes through to the real binary

### curl-wrapper Logic
```bash
if [command contains "localhost"]; then
  replace "localhost" with "host.docker.internal"
  add "Host: localhost" header
else
  pass through unchanged
fi
```

### npx-wrapper Logic
```bash
if [first argument is "playwright"]; then
  remove "playwright" from arguments
  execute: playwright [remaining arguments]
else
  pass through to real npx
fi
```

## Testing Wrappers

### Test curl-wrapper
```bash
# Inside container:
curl http://localhost:3000
# Should work even though localhost normally doesn't exist in container
```

### Test npx-wrapper
```bash
# Inside claude-flow container:
npx playwright --version
# Should show Playwright version (redirected to global playwright)

npx create-next-app test
# Should work normally (passes through to real npx)
```

## Creating New Wrappers

To create a new wrapper:

1. Create `tool-wrapper` script:
```bash
#!/bin/bash
REAL_TOOL=$(which -a tool | grep -v "$0" | head -n1)

# Your interception logic here
if [condition]; then
  # Transform command
else
  exec "$REAL_TOOL" "$@"
fi
```

2. Create `tool-wrapper-install` script:
```bash
#!/bin/bash
cp /var/www/html/docker/bin/tool-wrapper /usr/local/bin/tool
chmod +x /usr/local/bin/tool
```

3. Add to entrypoint scripts:
```bash
cp /var/www/html/docker/bin/tool-wrapper /usr/local/bin/tool
chmod +x /usr/local/bin/tool
```

## Benefits

- **Seamless localhost access**: No need to remember host.docker.internal
- **Command compatibility**: `npx playwright` works automatically
- **Zero configuration**: Users don't need to change their workflow
- **Transparent**: Wrappers intercept only when needed
- **Maintainable**: Centralized in docker/bin/ directory
