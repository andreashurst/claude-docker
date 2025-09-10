# Playwright Testing Guide

## Quick Start

```bash
# Take a screenshot
playwright screenshot http://localhost screenshot.png

# Generate a test
playwright codegen http://localhost

# Run tests
playwright test
```

## Taking Screenshots

Playwright can take screenshots directly:

```bash
# Basic screenshot
playwright screenshot http://localhost output.png

# Full page screenshot
playwright screenshot --full-page http://localhost full.png

# Mobile viewport
playwright screenshot --viewport-size=375,667 http://localhost mobile.png
```

### Docker Networking

When running Playwright in Docker, use `host.docker.internal` to access services on your host:

```bash
# Access Vite dev server from Docker
playwright screenshot http://host.docker.internal:5173 screenshot.png

# Access DDEV site
playwright screenshot https://myproject.ddev.site screenshot.png
```

## Writing Tests

### Setup

```bash
# Create test directory
mkdir -p /var/www/html/playwright/tests

# Create a simple test file
cat > /var/www/html/playwright/tests/example.spec.js << 'EOF'
const { test, expect } = require('@playwright/test');

test('homepage loads', async ({ page }) => {
  await page.goto('http://host.docker.internal:3000');
  await expect(page).toHaveTitle(/.*/)
  await page.screenshot({ path: 'homepage.png' });
});
EOF
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
  await page.goto('http://host.docker.internal:3000');
  await expect(page).toHaveTitle(/My Site/);

  // Take screenshot
  await page.screenshot({
    path: './screenshots/homepage.png',
    fullPage: true
  });
});
```

## Commands Reference

| Command | Description |
|---------|-------------|
| `playwright screenshot <url> <output>` | Take a screenshot |
| `playwright test` | Run all tests |
| `playwright test --ui` | Run with UI mode |
| `playwright codegen <url>` | Generate test code |
| `playwright --help` | Show all options |

## Working with Dev Servers

### Vite
```bash
# Host: Start Vite
npm run dev

# Container: Screenshot from Docker
playwright screenshot http://host.docker.internal:5173 screenshot.png
```

### DDEV Projects
```bash
# Use DDEV domain directly
playwright screenshot https://myproject.ddev.site screenshot.png

# Or with custom TLD
playwright screenshot https://myproject.ddev.local screenshot.png
```

### Common Development Ports
- **3000** - React, Next.js, Express
- **5173** - Vite default
- **8080** - webpack-dev-server
- **4200** - Angular
- **4173** - Vite preview

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No CSS in screenshots | Check dev server is running |
| Connection refused | Use `host.docker.internal` from Docker |
| DDEV site not accessible | Check DDEV is running with `ddev status` |
| Timeout errors | Increase timeout with `--timeout=60000` |

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
  await page.goto('http://host.docker.internal:3000');
  const loadTime = Date.now() - startTime;
  expect(loadTime).toBeLessThan(3000);
});
```

### Visual Regression
```javascript
test('visual comparison', async ({ page }) => {
  await page.goto('http://host.docker.internal:3000');
  await expect(page).toHaveScreenshot('homepage.png');
});
```