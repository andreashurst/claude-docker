// @ts-check
const { defineConfig, devices } = require('@playwright/test');

/**
 * Playwright configuration for Docker environment
 *
 * Usage:
 * 1. Copy this file to your project:
 *    cp /usr/local/share/claude/examples/playwright.config.js ./playwright.config.js
 *
 * 2. Adjust testDir and other paths as needed for your project structure
 */
module.exports = defineConfig({
  testDir: './tests',
  outputDir: './test-results',

  // Run tests in parallel
  fullyParallel: true,

  // Fail the build on CI if you accidentally left test.only in the source code
  forbidOnly: !!process.env.CI,

  // Retry on CI only
  retries: process.env.CI ? 2 : 0,

  // Reporter to use
  reporter: [
    ['html', { outputFolder: '/var/www/html/playwright/test-results/html' }],
    ['json', { outputFile: '/var/www/html/playwright/test-results/results.json' }]
  ],

  // Shared settings for all projects
  use: {
    // Base URL for Docker environment
    baseURL: process.env.BASE_URL || 'http://localhost',

    // Collect trace when retrying the failed test
    trace: 'on-first-retry',

    // Screenshot on failure
    screenshot: 'only-on-failure',

    // Video on failure
    video: 'retain-on-failure',
  },

  // Configure projects for major browsers
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
    },
    // Mobile viewports
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },
  ],
});
