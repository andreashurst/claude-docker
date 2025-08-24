// @ts-check
const { defineConfig, devices } = require('@playwright/test');

/**
 * Playwright configuration for Docker environment
 * Place this in /var/www/html/playwright/playwright.config.js
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
    ['html', { outputFolder: './test-results/html' }],
    ['json', { outputFile: './test-results/results.json' }]
  ],

  // Shared settings for all projects
  use: {
    // Base URL for Docker environment
    baseURL: process.env.BASE_URL || 'http://host.docker.internal',
    
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

  // Run local dev server before starting tests (if needed)
  // webServer: {
  //   command: 'npm run dev',
  //   url: 'http://host.docker.internal:3000',
  //   reuseExistingServer: !process.env.CI,
  // },
});