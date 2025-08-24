# Playwright Testing Guide

## Quick Start

```bash
# Take a screenshot (auto-detects environment)
screenshot http://localhost screenshot.png

# Generate a test
playwright codegen http://localhost

# Run tests
playwright-test
```

## Universal Screenshot Tool

The `screenshot` command automatically detects and adapts to your environment:

### Environment Detection
- **DDEV**: Auto-detects domain and custom TLDs (reads from `.ddev/config.yaml`)
- **Docker**: Rewrites to `host.docker.internal`
- **Local**: Uses localhost directly

### How It Works

```javascript
// Automatic URL rewriting examples:
"localhost:3000" → "myproject.ddev.site:3000"    // DDEV default
"localhost:3000" → "myproject.ddev.local:3000"   // DDEV custom TLD
"localhost:3000" → "custom.domain.test:3000"     // DDEV with additional_fqdns
"localhost:3000" → "host.docker.internal:3000"   // Docker
"localhost:3000" → "localhost:3000"              // Local
```

### Features
- ✅ No vite.config changes needed
- ✅ Blocks HMR to prevent corruption
- ✅ Works with any dev server (Vite, webpack, etc.)
- ✅ Handles all common ports automatically

## Writing Tests

### Setup

```bash
# Copy example configuration
cp /usr/local/share/claude/examples/playwright.config.js /var/www/html/playwright/playwright.config.js

# Copy example test
cp /usr/local/share/claude/examples/example-test.spec.js /var/www/html/playwright/tests/example.spec.js
```

### Test Structure

```
/var/www/html/playwright/
├── tests/              # Your test files
├── screenshots/        # Screenshot outputs
├── test-results/       # Test results and reports
└── playwright.config.js
```

### Example Test

```javascript
const { test, expect } = require('@playwright/test');

test('homepage loads', async ({ page }) => {
  await page.goto('http://localhost');
  await expect(page).toHaveTitle(/My Site/);

  // Screenshot with automatic environment handling
  await page.screenshot({
    path: './screenshots/homepage.png',
    fullPage: true
  });
});
```

## Commands Reference

| Command | Description |
|---------|-------------|
| `screenshot <url> <output>` | Universal screenshot tool |
| `playwright-test` | Run all tests |
| `playwright-ui` | Run with UI mode |
| `playwright codegen <url>` | Generate test code |
| `playwright --help` | Show all options |

## Working with Dev Servers

### Vite
```bash
# Host: Start Vite
npm run dev

# Container: Screenshot with CSS
screenshot http://localhost screenshot.png
```

### DDEV Projects
```bash
# DDEV automatically detected (including custom TLDs)
screenshot http://localhost screenshot.png
# → Rewrites to your DDEV domain:
#   - myproject.ddev.site (default)
#   - myproject.ddev.local (custom project_tld)
#   - custom.domain.test (additional_fqdns)
```

### Custom Ports
The tool automatically checks common ports:
- 3000 (React, Next.js)
- 5173 (Vite)
- 8080 (webpack)
- 4200 (Angular)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No CSS in screenshots | Check dev server is running |
| Large files (>600KB) | HMR corruption - tool blocks this automatically |
| Connection refused | Verify port with `test-port 3000` |
| DDEV not detected | Check `.ddev/config.yaml` exists |

## Advanced Usage

### Custom Viewport Sizes
```javascript
await page.setViewportSize({ width: 375, height: 667 });  // Mobile
await page.setViewportSize({ width: 768, height: 1024 }); // Tablet
await page.setViewportSize({ width: 1920, height: 1080 }); // Desktop
```

### Performance Testing
```javascript
test('page load time', async ({ page }) => {
  const startTime = Date.now();
  await page.goto('http://localhost');
  const loadTime = Date.now() - startTime;
  expect(loadTime).toBeLessThan(3000);
});
```

### Visual Regression
```javascript
test('visual comparison', async ({ page }) => {
  await page.goto('http://localhost');
  await expect(page).toHaveScreenshot('homepage.png');
});
```
