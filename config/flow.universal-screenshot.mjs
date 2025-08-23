#!/usr/bin/env node

/**
 * Universal Playwright Screenshot Script
 * Auto-detects environment (DDEV, Docker, Local) and handles Vite accordingly
 * 
 * Usage: universal-screenshot <url> <output-path>
 */

import { chromium } from 'playwright';
import { execSync } from 'child_process';
import fs from 'fs';
import dns from 'dns';
import { promisify } from 'util';

const resolve4 = promisify(dns.resolve4);

// Parse arguments
const args = process.argv.slice(2);
if (args.length < 2) {
  console.error('Usage: universal-screenshot <url> <output-path>');
  console.error('Example: universal-screenshot http://localhost screenshot.png');
  process.exit(1);
}

const [inputUrl, outputPath] = args;

// Environment detection
class EnvironmentDetector {
  constructor() {
    this.isDDEV = false;
    this.isDocker = false;
    this.ddevSiteName = null;
    this.ddevDomain = null;
    this.ddevTLD = 'ddev.site';
    this.vitePort = null;
    this.detectedEnv = 'local';
  }

  async detect() {
    // Check if we're in DDEV
    this.isDDEV = this.checkDDEV();
    
    // Check if we're in Docker (but not DDEV)
    if (!this.isDDEV) {
      this.isDocker = this.checkDocker();
    }

    // Detect Vite port
    this.vitePort = await this.detectVitePort();

    // Set environment type
    if (this.isDDEV) {
      this.detectedEnv = 'ddev';
    } else if (this.isDocker) {
      this.detectedEnv = 'docker';
    } else {
      this.detectedEnv = 'local';
    }

    return this;
  }

  checkDDEV() {
    // Multiple ways to detect DDEV
    if (process.env.IS_DDEV_PROJECT === 'true') {
      this.detectDDEVDomain();
      return true;
    }
    
    if (process.env.DDEV_SITENAME) {
      this.ddevSiteName = process.env.DDEV_SITENAME;
      this.detectDDEVDomain();
      return true;
    }
    
    // Check for DDEV files
    if (fs.existsSync('/.ddev') || fs.existsSync('/var/www/html/.ddev')) {
      // Try to get site name and TLD from config
      try {
        const config = fs.readFileSync('/var/www/html/.ddev/config.yaml', 'utf8');
        
        // Get site name
        const nameMatch = config.match(/name:\s*(.+)/);
        if (nameMatch) {
          this.ddevSiteName = nameMatch[1].trim();
        }
        
        // Get custom TLD (project_tld or default)
        const tldMatch = config.match(/project_tld:\s*(.+)/);
        this.ddevTLD = tldMatch ? tldMatch[1].trim() : 'ddev.site';
        
        // Check for additional_fqdns or additional_hostnames
        const fqdnMatch = config.match(/additional_fqdns:\s*\[([^\]]+)\]/);
        if (fqdnMatch) {
          const fqdns = fqdnMatch[1].split(',')[0].trim().replace(/['"]/g, '');
          if (fqdns) {
            // Extract domain from first FQDN
            this.ddevDomain = fqdns;
          }
        }
        
        return true;
      } catch (e) {
        // Config not readable, but we're still in DDEV
        return true;
      }
    }
    
    return false;
  }

  detectDDEVDomain() {
    // Check environment variables for DDEV domain info
    if (process.env.DDEV_HOSTNAME) {
      this.ddevDomain = process.env.DDEV_HOSTNAME;
    } else if (process.env.DDEV_PRIMARY_URL) {
      // Extract domain from URL
      const url = process.env.DDEV_PRIMARY_URL.replace(/https?:\/\//, '').split('/')[0];
      this.ddevDomain = url;
    } else if (this.ddevSiteName) {
      // Construct from site name and TLD
      const tld = process.env.DDEV_TLD || this.ddevTLD || 'ddev.site';
      this.ddevDomain = `${this.ddevSiteName}.${tld}`;
    }
  }

  checkDocker() {
    // Check if we're in a Docker container
    if (process.env.DOCKER_CONTAINER === 'true') return true;
    if (fs.existsSync('/.dockerenv')) return true;
    
    try {
      const cgroup = fs.readFileSync('/proc/1/cgroup', 'utf8');
      return cgroup.includes('docker') || cgroup.includes('containerd');
    } catch (e) {
      return false;
    }
  }

  async detectVitePort() {
    // Common Vite ports
    const vitePorts = [5173, 3000, 5174, 3001];
    
    for (const port of vitePorts) {
      if (await this.isPortOpen(port)) {
        console.log(`✓ Detected Vite on port ${port}`);
        return port;
      }
    }
    
    // Check environment variable
    if (process.env.VITE_PORT) {
      return parseInt(process.env.VITE_PORT);
    }
    
    return 5173; // Default
  }

  async isPortOpen(port) {
    try {
      if (this.isDDEV) {
        // In DDEV, check if port is exposed using detected domain
        const domain = this.ddevDomain || `${this.ddevSiteName}.${this.ddevTLD}`;
        const result = execSync(`curl -s -o /dev/null -w "%{http_code}" http://${domain}:${port}`, { encoding: 'utf8' });
        return result !== '000';
      } else if (this.isDocker) {
        // In Docker, check host.docker.internal
        const result = execSync(`timeout 1 bash -c "</dev/tcp/host.docker.internal/${port}" 2>/dev/null`, { encoding: 'utf8' });
        return true;
      } else {
        // Local environment
        const result = execSync(`timeout 1 bash -c "</dev/tcp/localhost/${port}" 2>/dev/null`, { encoding: 'utf8' });
        return true;
      }
    } catch (e) {
      return false;
    }
  }
}

// URL Rewriter based on environment
class URLRewriter {
  constructor(env) {
    this.env = env;
  }

  rewriteUrl(url) {
    const { detectedEnv, ddevSiteName, ddevDomain, ddevTLD, vitePort } = this.env;
    
    // Define all possible Vite URL patterns
    const vitePatterns = [
      { pattern: /localhost:(\d+)/, type: 'localhost' },
      { pattern: /127\.0\.0\.1:(\d+)/, type: 'localhost' },
      { pattern: /0\.0\.0\.0:(\d+)/, type: 'any' },
      { pattern: /:(\d+)\/(@vite|@id|@fs|src|node_modules)/, type: 'vite-resource' }
    ];

    // Check if URL contains Vite resources
    const isViteUrl = vitePatterns.some(p => p.pattern.test(url));
    if (!isViteUrl) return url;

    console.log(`Rewriting URL for ${detectedEnv} environment: ${url}`);

    switch (detectedEnv) {
      case 'ddev':
        // In DDEV, rewrite to DDEV domain (with custom TLD support)
        const domain = ddevDomain || `${ddevSiteName}.${ddevTLD}`;
        if (domain) {
          return url
            .replace(/localhost:(\d+)/, `${domain}:$1`)
            .replace(/127\.0\.0\.1:(\d+)/, `${domain}:$1`);
        }
        break;
        
      case 'docker':
        // In Docker, rewrite to host.docker.internal
        return url
          .replace(/localhost:(\d+)/, 'host.docker.internal:$1')
          .replace(/127\.0\.0\.1:(\d+)/, 'host.docker.internal:$1');
        
      case 'local':
        // Local environment, no rewriting needed
        return url;
    }
    
    return url;
  }
}

// Main screenshot function
async function takeUniversalScreenshot() {
  console.log('🔍 Detecting environment...');
  const env = await new EnvironmentDetector().detect();
  
  console.log(`📍 Environment: ${env.detectedEnv.toUpperCase()}`);
  if (env.ddevSiteName) {
    const domain = env.ddevDomain || `${env.ddevSiteName}.${env.ddevTLD}`;
    console.log(`📍 DDEV Site: ${env.ddevSiteName}`);
    console.log(`📍 DDEV Domain: ${domain}`);
    if (env.ddevTLD !== 'ddev.site') {
      console.log(`📍 Custom TLD: ${env.ddevTLD}`);
    }
  }
  
  const urlRewriter = new URLRewriter(env);
  
  // Launch browser
  const browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const context = await browser.newContext({
    viewport: { width: 1920, height: 1080 }
  });

  const page = await context.newPage();

  // Set up intelligent request interception
  await page.route('**/*', async (route) => {
    const originalUrl = route.request().url();
    const rewrittenUrl = urlRewriter.rewriteUrl(originalUrl);
    
    // Block HMR/Vite client in all environments
    if (originalUrl.includes('/@vite/client') || 
        originalUrl.includes('/@react-refresh') ||
        originalUrl.includes('/__vite_ping')) {
      console.log(`🚫 Blocking HMR: ${originalUrl}`);
      await route.abort();
      return;
    }
    
    // If URL was rewritten, fetch from new URL
    if (rewrittenUrl !== originalUrl) {
      console.log(`♻️  Rewriting: ${originalUrl.substring(0, 50)}...`);
      console.log(`   → ${rewrittenUrl.substring(0, 50)}...`);
      
      try {
        const response = await page.context().request.fetch(rewrittenUrl);
        await route.fulfill({ response });
      } catch (error) {
        console.error(`Failed to fetch ${rewrittenUrl}:`, error.message);
        await route.abort();
      }
    } else {
      await route.continue();
    }
  });

  // Rewrite the main URL if needed
  const targetUrl = urlRewriter.rewriteUrl(inputUrl);
  console.log(`📸 Loading page: ${targetUrl}`);
  
  try {
    await page.goto(targetUrl, {
      waitUntil: 'networkidle',
      timeout: 30000
    });

    // Wait for any lazy-loaded content
    await page.waitForTimeout(2000);

    // Take screenshot
    await page.screenshot({
      path: outputPath,
      fullPage: true
    });

    console.log(`✅ Screenshot saved to: ${outputPath}`);

    // Verify file size
    const stats = fs.statSync(outputPath);
    const fileSizeKB = Math.round(stats.size / 1024);
    
    if (fileSizeKB > 500) {
      console.warn(`⚠️  Large file size (${fileSizeKB}KB) - possible HMR corruption`);
    } else {
      console.log(`📊 File size: ${fileSizeKB}KB`);
    }
    
    // Environment-specific success message
    switch (env.detectedEnv) {
      case 'ddev':
        console.log('💡 DDEV Tip: Make sure Vite is running with "ddev vite" or exposed ports');
        break;
      case 'docker':
        console.log('💡 Docker Tip: Vite on host is accessible via host.docker.internal');
        break;
      case 'local':
        console.log('💡 Local environment: Direct access to all services');
        break;
    }

  } catch (error) {
    console.error('❌ Screenshot failed:', error.message);
    
    // Provide environment-specific troubleshooting
    console.log('\n🔧 Troubleshooting tips for your environment:');
    switch (env.detectedEnv) {
      case 'ddev':
        console.log('- Check if Vite is running: ddev exec "ps aux | grep vite"');
        console.log('- Verify port exposure in .ddev/config.yaml');
        console.log('- Try: ddev get ddev/ddev-viteserve');
        break;
      case 'docker':
        console.log('- Verify Vite is running on host: ps aux | grep vite');
        console.log('- Test connection: curl http://host.docker.internal:' + env.vitePort);
        console.log('- Check Docker networking: docker network ls');
        break;
      case 'local':
        console.log('- Check if Vite is running: ps aux | grep vite');
        console.log('- Verify port: lsof -i :' + env.vitePort);
        break;
    }
    
    process.exit(1);
  } finally {
    await browser.close();
  }
}

// Run the screenshot
takeUniversalScreenshot().catch(console.error);