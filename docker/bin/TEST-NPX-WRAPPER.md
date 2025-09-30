# npx-wrapper Test Guide

## Purpose
The npx-wrapper ensures that `npx playwright` commands automatically redirect to the globally installed `playwright` binary in the claude-flow container.

## Test Scenarios

### Scenario 1: Basic playwright command
```bash
# Old way (still works):
npx playwright --version

# What happens:
# 1. npx-wrapper intercepts the command
# 2. Detects "playwright" as first argument
# 3. Redirects to: playwright --version
# 4. Returns Playwright version number

# Expected output:
# Version 1.x.x
```

### Scenario 2: Playwright test command
```bash
# Command:
npx playwright test

# What happens:
# 1. Wrapper redirects to: playwright test
# 2. Runs tests with global Playwright installation

# Expected output:
# Running tests...
```

### Scenario 3: Playwright codegen
```bash
# Command:
npx playwright codegen https://example.com

# What happens:
# 1. Wrapper removes "playwright" from args
# 2. Executes: playwright codegen https://example.com
# 3. Opens codegen UI

# Expected output:
# Opens Playwright Inspector
```

### Scenario 4: Other npx commands (pass-through)
```bash
# Command:
npx create-react-app my-app

# What happens:
# 1. Wrapper detects first arg is NOT "playwright"
# 2. Passes through to real npx
# 3. Downloads and runs create-react-app

# Expected output:
# Creating a new React app in...
```

### Scenario 5: Complex playwright command
```bash
# Command:
npx playwright test --headed --debug playwright/tests/example.spec.js

# What happens:
# 1. Wrapper removes "playwright"
# 2. Executes: playwright test --headed --debug playwright/tests/example.spec.js

# Expected output:
# Opens test in headed mode with debugger
```

## Verification Commands

### Check if wrapper is installed
```bash
which npx
# Should show: /usr/local/bin/npx

file /usr/local/bin/npx
# Should show: Bourne-Again shell script
```

### Check real npx location
```bash
which -a npx
# Should show:
# /usr/local/bin/npx (wrapper)
# /usr/local/lib/node_modules/.bin/npx (real npx)
```

### Test wrapper behavior
```bash
# Should redirect to playwright:
npx playwright --version

# Should use real npx:
npx cowsay hello
```

## Benefits

✅ **Backward Compatibility**: Old scripts using `npx playwright` still work
✅ **Performance**: No npx overhead, direct execution of global playwright
✅ **Consistency**: All documentation/examples with `npx playwright` work out of the box
✅ **Transparency**: Users don't need to know about the wrapper
✅ **Flexibility**: Other npx commands work normally

## Edge Cases

### Edge Case 1: npx with package version
```bash
npx playwright@latest test
# Passes through to real npx (version specified)
```

### Edge Case 2: npx with full package name
```bash
npx @playwright/test
# Passes through to real npx (different package)
```

### Edge Case 3: Multiple arguments
```bash
npx playwright test --reporter=html --workers=4
# Correctly redirects all arguments
```

## Debugging

### Enable verbose mode
```bash
# Edit npx-wrapper, add at top:
set -x  # Enable debug output

# Then run command:
npx playwright test
# Will show exact command transformations
```

### Check if wrapper is active
```bash
# Run this inside container:
cat /usr/local/bin/npx | head -5

# Should show:
# #!/bin/bash
#
# # npx wrapper that redirects "npx playwright" to "playwright"
```

### Manual test
```bash
# Temporarily bypass wrapper:
/usr/local/lib/node_modules/.bin/npx playwright test

# Use wrapper:
npx playwright test
```

## Troubleshooting

**Problem**: `npx playwright` not working
**Solution**: Check if wrapper is installed:
```bash
ls -la /usr/local/bin/npx
```

**Problem**: Wrapper redirecting wrong commands
**Solution**: Check wrapper logic, should only catch exact "playwright" as $1

**Problem**: Real npx not found
**Solution**: Ensure Node.js is installed and npx exists at:
```bash
/usr/local/lib/node_modules/.bin/npx
```

## Implementation Notes

- Wrapper is installed during container startup (entrypoint.flow)
- Uses `which -a` to find real npx, filtering out self-reference
- Only intercepts when first argument is exactly "playwright"
- Uses `exec` for performance (replaces wrapper process with target process)
