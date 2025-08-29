#!/usr/bin/env node
/**
 * Playwright Vite Integration Handler
 * Intercepts and rewrites requests for Vite HMR compatibility
 */

const { chromium } = require('playwright');
const fs = require('fs');

class PlaywrightViteHandler {
  constructor() {
    this.env = this.detectEnvironment();
  }

  detectEnvironment() {
    if (fs.existsSync('.ddev/config.yaml')) {
      const config = fs.readFileSync('.ddev/config.yaml', 'utf8');
      const name = config.match(/^name:\s*(.+)$/m)?.[1] || 'project';
      const tld = config.match(/^project_tld:\s*(.+)$/m)?.[1] || 'ddev.site';
      return { type: 'ddev', domain: `${name}.${tld}` };
    }
    if (fs.existsSync('/.dockerenv')) {
      return { type: 'docker', domain: 'host.docker.internal' };
    }
    return { type: 'local', domain: 'localhost' };
  }

  rewriteUrl(url) {
    if (this.env.type === 'local') return url;
    return url.replace(/localhost|127\.0\.0\.1/g, this.env.domain);
  }

  async screenshot(url, output, options = {}) {
    const browser = await chromium.launch({ headless: true });
    const context = await browser.newContext({
      viewport: options.viewport || { width: 1920, height: 1080 },
      ignoreHTTPSErrors: true
    });
    const page = await context.newPage();

    // Intercept and rewrite requests
    await page.route('**/*', async (route) => {
      const requestUrl = route.request().url();
      const rewrittenUrl = this.rewriteUrl(requestUrl);
      
      if (requestUrl !== rewrittenUrl) {
        try {
          const response = await context.request.fetch(rewrittenUrl);
          await route.fulfill({ response });
          return;
        } catch (error) {
          // Fallback to original request
        }
      }
      await route.continue();
    });

    // Block WebSocket HMR
    await page.route('ws://*/*', route => route.abort());
    await page.route('wss://*/*', route => route.abort());

    await page.goto(this.rewriteUrl(url), { waitUntil: 'networkidle' });
    await page.screenshot({ path: output, fullPage: options.fullPage !== false });
    await browser.close();
  }
}

// CLI interface
if (require.main === module) {
  const [url, output, ...args] = process.argv.slice(2);
  
  if (!url || !output) {
    console.log('Usage: playwright-vite <url> <output> [options]');
    process.exit(1);
  }

  const handler = new PlaywrightViteHandler();
  const options = {};
  
  // Parse options
  args.forEach(arg => {
    if (arg === '--no-fullpage') options.fullPage = false;
    if (arg.startsWith('--width=')) options.viewport = { ...options.viewport, width: parseInt(arg.split('=')[1]) };
    if (arg.startsWith('--height=')) options.viewport = { ...options.viewport, height: parseInt(arg.split('=')[1]) };
  });

  handler.screenshot(url, output, options)
    .then(() => console.log(`✅ Screenshot saved: ${output}`))
    .catch(error => {
      console.error('Error:', error.message);
      process.exit(1);
    });
}

module.exports = PlaywrightViteHandler;