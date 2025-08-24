// @ts-check
const { test, expect } = require('@playwright/test');

/**
 * Example Playwright test with Vite dev server integration
 * Place this in /var/www/html/playwright/tests/
 */

// Helper to rewrite Vite URLs for Docker environment
async function setupViteInterception(page) {
  await page.route('**/*', async (route) => {
    const url = route.request().url();
    
    // Rewrite localhost Vite URLs to host.docker.internal
    if (url.includes('localhost:3000') || url.includes('localhost:5173')) {
      const newUrl = url
        .replace('localhost:3000', 'host.docker.internal:3000')
        .replace('localhost:5173', 'host.docker.internal:5173');
      
      const response = await page.context().request.fetch(newUrl);
      await route.fulfill({ response });
    }
    // Block Vite HMR to prevent screenshot corruption
    else if (url.includes('/@vite/client') || url.includes('/__vite_ping')) {
      await route.abort();
    }
    else {
      await route.continue();
    }
  });
}

test.describe('Vite Integration Tests', () => {
  test.beforeEach(async ({ page }) => {
    // Setup Vite URL interception for each test
    await setupViteInterception(page);
  });

  test('homepage loads with CSS from Vite', async ({ page }) => {
    await page.goto('/');
    
    // Wait for CSS to load
    await page.waitForLoadState('networkidle');
    
    // Check that page has expected content
    await expect(page).toHaveTitle(/Your Site Title/);
    
    // Take a screenshot
    await page.screenshot({ 
      path: './screenshots/homepage-with-css.png',
      fullPage: true 
    });
  });

  test('check responsive design', async ({ page }) => {
    // Test mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');
    await page.screenshot({ 
      path: './screenshots/homepage-mobile.png' 
    });
    
    // Test tablet viewport
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.screenshot({ 
      path: './screenshots/homepage-tablet.png' 
    });
    
    // Test desktop viewport
    await page.setViewportSize({ width: 1920, height: 1080 });
    await page.screenshot({ 
      path: './screenshots/homepage-desktop.png' 
    });
  });

  test('navigation works', async ({ page }) => {
    await page.goto('/');
    
    // Click on navigation links and verify
    const navLinks = await page.locator('nav a').all();
    
    for (const link of navLinks.slice(0, 3)) { // Test first 3 links
      const href = await link.getAttribute('href');
      if (href && !href.startsWith('http')) {
        await link.click();
        await page.waitForLoadState('networkidle');
        
        // Take screenshot of each page
        const pageName = href.replace(/\//g, '-') || 'index';
        await page.screenshot({ 
          path: `./screenshots/page${pageName}.png` 
        });
      }
    }
  });
});

test.describe('Performance Tests', () => {
  test('page load time is acceptable', async ({ page }) => {
    const startTime = Date.now();
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    const loadTime = Date.now() - startTime;
    
    console.log(`Page load time: ${loadTime}ms`);
    expect(loadTime).toBeLessThan(5000); // Should load in under 5 seconds
  });
});