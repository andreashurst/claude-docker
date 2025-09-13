// @ts-check
const { defineConfig, devices } = require('@playwright/test');

/**
 * Playwright configuration for Claude Flow
 * @see https://playwright.dev/docs/test-configuration
 */
module.exports = defineConfig({
  testDir: './playwright-tests',
  outputDir: './playwright-results',
  
  // Maximum time one test can run
  timeout: 30 * 1000,
  
  // Run tests in parallel
  fullyParallel: true,
  
  // Fail the build on CI if you accidentally left test.only
  forbidOnly: !!process.env.CI,
  
  // Retry on CI only
  retries: process.env.CI ? 2 : 0,
  
  // Parallel workers on CI, single on local
  workers: process.env.CI ? 1 : undefined,
  
  // Reporter configuration
  reporter: [
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['list'],
    ['json', { outputFile: 'playwright-results/results.json' }]
  ],
  
  use: {
    // Base URL for all tests
    baseURL: process.env.BASE_URL || 'http://localhost',
    
    // Collect trace when retrying the failed test
    trace: 'on-first-retry',
    
    // Screenshot on failure
    screenshot: {
      mode: 'only-on-failure',
      fullPage: true
    },
    
    // Video on failure
    video: 'retain-on-failure',
    
    // Artifacts folder
    artifactsPath: './playwright-results/artifacts'
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
    // Mobile testing
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
    },
  ],

  // Local dev server (if needed)
  webServer: process.env.NO_WEBSERVER ? undefined : {
    command: 'echo "Using existing webserver"',
    url: 'http://localhost',
    reuseExistingServer: true,
  },
});
