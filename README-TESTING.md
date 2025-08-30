# Comprehensive Docker Testing Suite for Curl & Playwright

A comprehensive testing framework designed specifically for testing curl and Playwright functionality within Docker environments, with advanced networking diagnostics and validation procedures.

## 🎯 Purpose

This testing suite addresses common challenges when using curl and Playwright in containerized environments, particularly:

- Network connectivity issues between containers and host services
- DNS resolution problems with `host.docker.internal`
- Port binding conflicts and accessibility issues
- URL rewriting for local development servers (Vite, webpack-dev-server)
- Screenshot corruption from HMR (Hot Module Replacement)
- Environment detection and fallback mechanisms
- Permission and security restriction problems

## 🏗️ Architecture

```
test/
├── scripts/                          # Executable test scripts
│   ├── curl-comprehensive-test.sh    # Curl functionality testing
│   ├── playwright-comprehensive-test.js # Playwright browser automation
│   ├── validation-tests.sh           # Environment validation
│   ├── debug-networking.sh           # Network diagnostics
│   └── run-all-tests.sh             # Master test runner
├── config/                          # Configuration files
│   ├── test-config.json            # Main configuration
│   ├── flow.playwright.config.example.js
│   └── flow.example-vite-test.spec.js
├── results/                         # Generated test results
│   ├── curl/                       # Curl test outputs
│   ├── playwright/                 # Playwright test outputs
│   ├── validation/                 # Validation results
│   └── debug/                      # Debug session outputs
└── docs/                          # Documentation
    ├── NETWORKING.md
    └── PLAYWRIGHT.md
```

## 🚀 Quick Start

### Run All Tests

```bash
# Execute comprehensive test suite
./test/scripts/run-all-tests.sh

# Quick test run
./test/scripts/run-all-tests.sh --quick

# Verbose output
./test/scripts/run-all-tests.sh --verbose
```

### Run Individual Test Suites

```bash
# Curl tests only
./test/scripts/run-all-tests.sh --curl-only

# Playwright tests only  
./test/scripts/run-all-tests.sh --playwright-only

# Validation tests only
./test/scripts/run-all-tests.sh --validation-only

# Debug procedures only
./test/scripts/run-all-tests.sh --debug-only
```

### Individual Test Scripts

```bash
# Run curl comprehensive tests
./test/scripts/curl-comprehensive-test.sh

# Run Playwright tests
node ./test/scripts/playwright-comprehensive-test.js

# Run validation tests
./test/scripts/validation-tests.sh

# Run network debugging
./test/scripts/debug-networking.sh
```

## 📋 Test Categories

### 1. Curl Comprehensive Tests

**Purpose**: Validate curl functionality across various scenarios in Docker environments.

**Test Coverage**:
- ✅ Basic HTTP requests to host services
- ✅ HTTPS with certificate validation
- ✅ Different ports (3000, 5173, 8080, etc.)
- ✅ POST requests with various data formats
- ✅ Headers and authentication mechanisms
- ✅ Timeout handling and recovery
- ✅ Performance and response time testing
- ✅ Error handling for various failure modes

**Key Features**:
- Tests `host.docker.internal` connectivity
- Validates port accessibility from containers
- Measures response times and sizes
- Tests SSL/TLS certificate handling
- Validates HTTP authentication mechanisms

**Sample Output**:
```
✅ PASS: Basic HTTP - http://host.docker.internal (Status: 200)
✅ PASS: HTTPS - https://httpbin.org/get (SSL verification successful)
❌ FAIL: Port Test - host.docker.internal:9999 (Port not accessible)
✅ PASS: POST - https://httpbin.org/post (Response: 200)
```

### 2. Playwright Comprehensive Tests

**Purpose**: Test browser automation and screenshot capabilities in containerized environments.

**Test Coverage**:
- ✅ Screenshot capture with CSS loading
- ✅ Browser automation across multiple engines
- ✅ Vite dev server integration with URL rewriting
- ✅ Network request interception and modification
- ✅ Error recovery and resilience testing
- ✅ Multi-viewport responsive testing

**Key Features**:
- Supports Chromium, Firefox, and WebKit
- Handles Vite HMR interference prevention
- URL rewriting for `localhost` → `host.docker.internal`
- Screenshot generation with proper CSS loading
- Network interception for development servers

**Sample Output**:
```
✅ PASS: Screenshot Basic - chromium (Size: 245678 bytes)
✅ PASS: Vite URL Rewriting - firefox (Interception successful)
✅ PASS: Mobile Viewport - webkit (375x667, Size: 198432 bytes)
❌ FAIL: Navigation - chromium (Timeout after 30s)
```

### 3. Validation Tests

**Purpose**: Validate core environment detection, URL rewriting, and fallback mechanisms.

**Test Coverage**:
- ✅ Environment detection accuracy (Docker container, networking)
- ✅ URL rewriting correctness (localhost → host.docker.internal)
- ✅ Port availability checks and scanning
- ✅ Fallback mechanism testing (multiple host options)
- ✅ Error message clarity and categorization
- ✅ Integration validation between tools

**Key Features**:
- Docker environment detection
- DNS resolution validation
- Port accessibility testing
- URL rewriting logic validation
- Error categorization and messaging

**Sample Output**:
```
✅ PASS: Docker Container Detection (/.dockerenv file exists)
✅ PASS: URL Rewriting: http://localhost:3000 (Correctly rewritten)
❌ FAIL: Port Availability: host.docker.internal:9999 (Port closed)
✅ PASS: Fallback DNS Resolution: host.docker.internal (Successful resolution)
```

### 4. Debug Procedures

**Purpose**: Comprehensive network and connectivity diagnostics with automated fixing.

**Test Coverage**:
- ✅ Network connectivity diagnostics
- ✅ DNS resolution problem identification
- ✅ Port binding conflict analysis
- ✅ Permission and security restriction detection
- ✅ Automated fix generation
- ✅ Comprehensive diagnosis reporting

**Key Features**:
- Network interface analysis
- DNS server testing
- Port conflict detection
- Docker-specific networking diagnostics
- Automated fix script generation
- Detailed diagnosis reports

**Sample Output**:
```
✅ HEALTHY: Network configuration appears healthy
⚠️ MINOR ISSUES: DNS resolution slower than optimal
🚨 CRITICAL ISSUES: host.docker.internal unreachable
📋 Generated diagnosis report with 3 recommendations
🔧 Auto-fix script created: auto_fix_20250830_143022.sh
```

## 🔧 Configuration

### Main Configuration File

The test suite uses `test/config/test-config.json` for centralized configuration:

```json
{
  "environment": {
    "hostAccess": "host.docker.internal",
    "expectedServices": {
      "webserver": {
        "host": "host.docker.internal",
        "port": 80,
        "protocol": "http"
      }
    }
  },
  "curl": {
    "timeouts": { "default": 10, "quick": 5, "extended": 30 },
    "commonPorts": [80, 443, 3000, 5173, 8080]
  },
  "playwright": {
    "browsers": ["chromium", "firefox", "webkit"],
    "viewports": {
      "mobile": {"width": 375, "height": 667},
      "desktop": {"width": 1920, "height": 1080}
    }
  }
}
```

### Environment Variables

```bash
# Optional environment variables
export QUICK_MODE=true          # Run abbreviated tests
export VERBOSE_LOGGING=true     # Enable detailed logging
export SKIP_SCREENSHOT=false    # Skip screenshot generation
export RESULTS_DIR=./results    # Custom results directory
```

## 📊 Output and Reporting

### Generated Files

Each test run generates comprehensive outputs:

```
results/
├── master_test_20250830_143022.log           # Master execution log
├── comprehensive_report_20250830_143022.md   # Executive summary
├── curl/
│   ├── curl_test_20250830_143022.log         # Curl test log
│   ├── results_20250830_143022.csv           # CSV results data
│   └── summary_20250830_143022.md            # Curl summary
├── playwright/
│   ├── results-20250830_143022.json          # JSON test results
│   ├── report-20250830_143022.md             # Playwright report
│   └── screenshots/                          # Generated screenshots
│       ├── basic-chromium.png
│       ├── mobile-firefox.png
│       └── desktop-webkit.png
├── validation/
│   ├── validation_results_20250830_143022.csv
│   ├── validation_test_20250830_143022.log
│   └── validation_report_20250830_143022.md
└── debug/
    ├── debug_20250830_143022.log
    ├── diagnosis_20250830_143022.md
    ├── auto_fix_20250830_143022.sh
    └── network_info_20250830_143022.txt
```

### Report Types

1. **Executive Summary** (`comprehensive_report_*.md`)
   - Overall health assessment
   - Quick statistics and success rates
   - Key findings and recommendations
   - Next steps and action items

2. **Detailed Test Logs** (`.log` files)
   - Complete execution traces
   - Error messages and stack traces
   - Performance timing data
   - Debug information

3. **CSV Data Files** (`.csv` files)
   - Machine-readable test results
   - Performance metrics
   - Success/failure tracking
   - Suitable for data analysis

4. **Screenshots** (`.png` files)
   - Visual verification of rendering
   - Multi-viewport comparisons
   - CSS loading validation
   - Browser compatibility checks

## 🚨 Common Issues and Solutions

### Network Connectivity Issues

**Problem**: `curl: (7) Failed to connect to host.docker.internal`

**Solutions**:
```bash
# 1. Verify Docker networking
docker network ls
docker network inspect bridge

# 2. Test from host system
curl http://localhost

# 3. Check Docker Desktop settings (Mac/Windows)
# Enable "Use host networking" in Docker Desktop

# 4. Alternative hosts to try
curl http://localhost
curl http://127.0.0.1
curl http://gateway.docker.internal  # Some configurations
```

### DNS Resolution Problems

**Problem**: `nslookup: can't resolve 'host.docker.internal'`

**Solutions**:
```bash
# 1. Check DNS configuration
cat /etc/resolv.conf

# 2. Add fallback DNS
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# 3. Test DNS servers
nslookup google.com 8.8.8.8

# 4. Use IP address directly
# Find host IP: ip route | grep default
```

### Playwright Screenshot Issues

**Problem**: Screenshots are corrupted or show development artifacts

**Solutions**:
```bash
# 1. Disable HMR in your application
# Add to vite.config.js:
server: {
  hmr: process.env.NODE_ENV === 'test' ? false : true
}

# 2. Use the built-in Vite interception
# The test suite automatically handles this

# 3. Wait for network idle
await page.waitForLoadState('networkidle');

# 4. Use the universal screenshot command
screenshot http://localhost screenshot.png
```

### Port Binding Conflicts

**Problem**: `Port already in use` or connection refused

**Solutions**:
```bash
# 1. Check what's using the port
ss -tlnp | grep :3000
netstat -tlnp | grep :3000

# 2. Kill conflicting processes
kill $(lsof -ti:3000)

# 3. Use different ports
# Configure your application to use alternative ports

# 4. Docker port mapping
docker run -p 3001:3000 myapp
```

### Permission Errors

**Problem**: Permission denied or insufficient privileges

**Solutions**:
```bash
# 1. Check current user
id
whoami

# 2. Fix file permissions
chmod +x test/scripts/*.sh

# 3. Docker socket access (if needed)
# Add user to docker group (host system)
sudo usermod -aG docker $USER

# 4. Run with appropriate user
docker run --user $(id -u):$(id -g) myimage
```

## 🔍 Advanced Usage

### Custom Test Configuration

Create custom test configurations for specific environments:

```json
{
  "customEnvironment": {
    "hostAccess": "custom.docker.internal",
    "additionalHosts": ["dev.local", "test.local"],
    "customPorts": [3000, 4000, 5000],
    "specialHandling": {
      "viteServer": true,
      "webpackDevServer": true,
      "nextjsDev": true
    }
  }
}
```

### Integration with CI/CD

```yaml
# .github/workflows/docker-tests.yml
name: Docker Environment Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Docker Tests
        run: |
          chmod +x test/scripts/run-all-tests.sh
          ./test/scripts/run-all-tests.sh --quick
      - name: Upload Results
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: test-results
          path: test/results/
```

### Custom Playwright Configuration

```javascript
// playwright.config.js
module.exports = {
  use: {
    baseURL: process.env.BASE_URL || 'http://host.docker.internal',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    {
      name: 'docker-chromium',
      use: { 
        ...devices['Desktop Chrome'],
        launchOptions: {
          args: ['--no-sandbox', '--disable-dev-shm-usage']
        }
      },
    },
  ],
};
```

## 📈 Performance Benchmarks

### Expected Performance Ranges

**Curl Tests**:
- Basic HTTP: < 1s response time
- HTTPS with SSL: < 2s response time  
- Port scanning: < 5s for 10 ports
- DNS resolution: < 500ms

**Playwright Tests**:
- Screenshot generation: < 10s per screenshot
- Page navigation: < 5s per page
- Multi-viewport: < 15s for 3 viewports
- Network interception: < 2s overhead

**Validation Tests**:
- Environment detection: < 2s
- URL rewriting validation: < 1s
- Port availability checks: < 10s
- DNS validation: < 3s

**Debug Procedures**:
- Network diagnostics: < 30s
- Comprehensive analysis: < 60s
- Report generation: < 5s

### Performance Optimization Tips

1. **Use `--quick` mode** for faster iteration during development
2. **Enable result caching** for repeated tests
3. **Limit browser engines** to only what you need
4. **Use smaller viewports** for screenshot tests
5. **Implement parallel execution** for independent test categories

## 🤝 Contributing

### Adding New Test Cases

1. **Curl Tests**: Add test functions to `curl-comprehensive-test.sh`
2. **Playwright Tests**: Add test categories to `playwright-comprehensive-test.js`
3. **Validation Tests**: Add validation functions to `validation-tests.sh`
4. **Debug Procedures**: Add diagnostic procedures to `debug-networking.sh`

### Test Structure Template

```bash
# Curl test template
test_new_feature() {
    local test_name="New Feature Test"
    local url="http://host.docker.internal/feature"
    
    log "Testing new feature: $url"
    
    local response_code
    response_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    
    if [ "$response_code" == "200" ]; then
        test_result "$test_name" "PASS" "Feature working"
    else
        test_result "$test_name" "FAIL" "Response: $response_code"
    fi
}
```

### Extending Validation Logic

```bash
# Validation test template
test_custom_validation() {
    log "Testing custom validation logic..."
    
    local expected="expected_value"
    local actual=$(get_actual_value)
    
    if [ "$actual" == "$expected" ]; then
        test_result "Custom Validation" "PASS" "Values match" "$expected" "$actual"
    else
        test_result "Custom Validation" "FAIL" "Values don't match" "$expected" "$actual"
    fi
}
```

## 🆘 Support and Troubleshooting

### Getting Help

1. **Check the logs**: Review detailed logs in the `results/` directory
2. **Run debug procedures**: Use `debug-networking.sh` for network issues
3. **Use verbose mode**: Add `--verbose` flag for detailed output
4. **Review configuration**: Check `test-config.json` for environment settings

### Common Command Reference

```bash
# Quick health check
./test/scripts/run-all-tests.sh --quick --validation-only

# Full diagnostic run
./test/scripts/debug-networking.sh

# Playwright screenshot test only
node test/scripts/playwright-comprehensive-test.js

# Network connectivity test
curl -I http://host.docker.internal

# DNS resolution test
nslookup host.docker.internal

# Port accessibility test
timeout 3 bash -c "</dev/tcp/host.docker.internal/3000"
```

### Emergency Debugging

If all tests fail, run this emergency diagnostic:

```bash
#!/bin/bash
echo "=== Emergency Docker Network Debug ==="
echo "1. Docker environment:"
[ -f /.dockerenv ] && echo "✅ In Docker" || echo "❌ Not in Docker"

echo "2. Network interfaces:"
ip addr show | grep -E "inet|eth|docker"

echo "3. DNS resolution:"
nslookup host.docker.internal || echo "❌ DNS failed"

echo "4. Gateway connectivity:"
ping -c 1 $(ip route | grep default | awk '{print $3}') || echo "❌ Gateway failed"

echo "5. Internet connectivity:"  
ping -c 1 8.8.8.8 || echo "❌ Internet failed"

echo "6. Port accessibility:"
timeout 3 bash -c "</dev/tcp/host.docker.internal/80" && echo "✅ Port 80 open" || echo "❌ Port 80 closed"
```

---

## 📝 License and Credits

Created by Claude Code Hive Mind for comprehensive Docker environment testing.

**Key Features**:
- ✅ Production-ready test suites
- ✅ Comprehensive error handling
- ✅ Detailed reporting and diagnostics
- ✅ Docker-optimized networking
- ✅ Multi-browser Playwright support
- ✅ Automated fixing procedures
- ✅ CI/CD integration ready

**For updates and documentation**: Check the project repository and documentation files.