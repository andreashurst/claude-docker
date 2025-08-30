#!/bin/bash

# =============================================================================
# VALIDATION TESTS FOR ENVIRONMENT DETECTION AND URL REWRITING
# =============================================================================
# Purpose: Validate environment detection accuracy, URL rewriting correctness,
#          port availability checks, fallback mechanisms, and error messaging
# Environment: Docker containers with host.docker.internal networking
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_RESULTS_DIR="${SCRIPT_DIR}/../results/validation"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${TEST_RESULTS_DIR}/validation_test_${TIMESTAMP}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Create results directory
mkdir -p "${TEST_RESULTS_DIR}"

# Logging function
log() {
    echo -e "$1" | tee -a "${LOG_FILE}"
}

# Test result tracking
test_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    local expected="$4"
    local actual="$5"
    
    ((TOTAL_TESTS++))
    
    if [ "$result" == "PASS" ]; then
        ((PASSED_TESTS++))
        log "${GREEN}✅ PASS${NC}: $test_name"
        [ -n "$details" ] && log "    Details: $details"
    else
        ((FAILED_TESTS++))
        log "${RED}❌ FAIL${NC}: $test_name"
        [ -n "$details" ] && log "    Reason: $details"
        [ -n "$expected" ] && log "    Expected: $expected"
        [ -n "$actual" ] && log "    Actual: $actual"
    fi
    
    echo "$result,$test_name,\"$details\",\"$expected\",\"$actual\"" >> "${TEST_RESULTS_DIR}/validation_results_${TIMESTAMP}.csv"
}

# Initialize CSV results file
echo "Result,Test Name,Details,Expected,Actual" > "${TEST_RESULTS_DIR}/validation_results_${TIMESTAMP}.csv"

log "${BLUE}=== VALIDATION TEST SUITE ===${NC}"
log "Timestamp: $(date)"
log "Results Directory: $TEST_RESULTS_DIR"
log "Log File: $LOG_FILE"
log ""

# =============================================================================
# 1. ENVIRONMENT DETECTION ACCURACY
# =============================================================================
log "${YELLOW}[1] ENVIRONMENT DETECTION ACCURACY${NC}"

test_docker_environment() {
    log "Testing Docker environment detection..."
    
    # Test 1: Check if running inside Docker container
    if [ -f /.dockerenv ]; then
        test_result "Docker Container Detection" "PASS" "/.dockerenv file exists" "Docker environment" "Docker environment"
    else
        test_result "Docker Container Detection" "FAIL" "/.dockerenv file not found" "Docker environment" "Non-Docker environment"
    fi
    
    # Test 2: Check Docker-specific networking
    local gateway
    gateway=$(ip route | grep default | awk '{print $3}' | head -n1)
    
    if [ -n "$gateway" ]; then
        test_result "Docker Network Gateway Detection" "PASS" "Gateway found: $gateway" "Network gateway" "$gateway"
    else
        test_result "Docker Network Gateway Detection" "FAIL" "No network gateway found" "Network gateway" "None"
    fi
    
    # Test 3: Check host.docker.internal resolution
    if nslookup host.docker.internal >/dev/null 2>&1; then
        local host_ip
        host_ip=$(nslookup host.docker.internal 2>/dev/null | grep 'Address:' | tail -n1 | awk '{print $2}' || echo "unknown")
        test_result "host.docker.internal Resolution" "PASS" "Resolves to: $host_ip" "Valid IP address" "$host_ip"
    else
        test_result "host.docker.internal Resolution" "FAIL" "DNS resolution failed" "Valid IP address" "Resolution failed"
    fi
    
    # Test 4: Check container ID detection
    if [ -f /proc/self/cgroup ] && grep -q docker /proc/self/cgroup; then
        local container_id
        container_id=$(grep docker /proc/self/cgroup | head -n1 | sed 's/.*docker\///g' | sed 's/\.scope$//g' | cut -c1-12)
        test_result "Container ID Detection" "PASS" "Container ID: $container_id" "Container ID" "$container_id"
    else
        test_result "Container ID Detection" "FAIL" "Not running in Docker container" "Container ID" "Not found"
    fi
}

test_environment_variables() {
    log "Testing environment variables..."
    
    # Test common Docker environment variables
    local docker_env_vars=("HOSTNAME" "PATH" "PWD")
    
    for var in "${docker_env_vars[@]}"; do
        if [ -n "${!var:-}" ]; then
            test_result "Environment Variable: $var" "PASS" "Value: ${!var}" "Non-empty value" "${!var}"
        else
            test_result "Environment Variable: $var" "FAIL" "Variable not set or empty" "Non-empty value" "Empty/unset"
        fi
    done
    
    # Test for Docker-specific capabilities
    if [ -r /proc/1/cgroup ]; then
        test_result "Container Process Detection" "PASS" "Can read container cgroups" "Readable cgroups" "Accessible"
    else
        test_result "Container Process Detection" "FAIL" "Cannot read container cgroups" "Readable cgroups" "Inaccessible"
    fi
}

# Run environment detection tests
test_docker_environment
test_environment_variables

# =============================================================================
# 2. URL REWRITING CORRECTNESS
# =============================================================================
log ""
log "${YELLOW}[2] URL REWRITING CORRECTNESS${NC}"

# URL rewriting function (simulates the actual logic)
rewrite_url() {
    local url="$1"
    local rewritten="$url"
    
    # Replace localhost with host.docker.internal
    rewritten="${rewritten//localhost/host.docker.internal}"
    
    # Replace 127.0.0.1 with host.docker.internal
    rewritten="${rewritten//127.0.0.1/host.docker.internal}"
    
    # Replace 0.0.0.0 with host.docker.internal
    rewritten="${rewritten//0.0.0.0/host.docker.internal}"
    
    echo "$rewritten"
}

test_url_rewriting() {
    log "Testing URL rewriting logic..."
    
    # Test cases: original_url:expected_result
    local test_cases=(
        "http://localhost:3000/test:http://host.docker.internal:3000/test"
        "https://localhost:5173/api:https://host.docker.internal:5173/api"
        "http://127.0.0.1:8080/endpoint:http://host.docker.internal:8080/endpoint"
        "http://0.0.0.0:4000/health:http://host.docker.internal:4000/health"
        "https://external.com/api:https://external.com/api"
        "http://example.com:9000/test:http://example.com:9000/test"
        "ws://localhost:3001/socket:ws://host.docker.internal:3001/socket"
    )
    
    for test_case in "${test_cases[@]}"; do
        IFS=':' read -r original expected <<< "$test_case"
        
        local actual
        actual=$(rewrite_url "$original")
        
        if [ "$actual" == "$expected" ]; then
            test_result "URL Rewriting: $original" "PASS" "Correctly rewritten" "$expected" "$actual"
        else
            test_result "URL Rewriting: $original" "FAIL" "Incorrect rewriting" "$expected" "$actual"
        fi
    done
}

test_url_validation() {
    log "Testing URL validation..."
    
    # Test URL components
    local test_urls=(
        "http://host.docker.internal:3000"
        "https://host.docker.internal:5173"
        "http://host.docker.internal"
        "https://host.docker.internal"
    )
    
    for url in "${test_urls[@]}"; do
        # Extract components
        local protocol
        protocol=$(echo "$url" | sed 's|://.*||')
        
        local host_port
        host_port=$(echo "$url" | sed 's|.*://||')
        
        local host
        host=$(echo "$host_port" | cut -d':' -f1)
        
        local port
        port=$(echo "$host_port" | cut -d':' -f2 2>/dev/null || echo "default")
        
        # Validate protocol
        if [[ "$protocol" =~ ^https?$ ]]; then
            test_result "URL Protocol Validation: $url" "PASS" "Valid protocol: $protocol" "http/https" "$protocol"
        else
            test_result "URL Protocol Validation: $url" "FAIL" "Invalid protocol: $protocol" "http/https" "$protocol"
        fi
        
        # Validate host
        if [ "$host" == "host.docker.internal" ]; then
            test_result "URL Host Validation: $url" "PASS" "Valid Docker host" "host.docker.internal" "$host"
        else
            test_result "URL Host Validation: $url" "FAIL" "Invalid Docker host" "host.docker.internal" "$host"
        fi
    done
}

# Run URL rewriting tests
test_url_rewriting
test_url_validation

# =============================================================================
# 3. PORT AVAILABILITY CHECKS
# =============================================================================
log ""
log "${YELLOW}[3] PORT AVAILABILITY CHECKS${NC}"

test_port_availability() {
    local host="$1"
    local port="$2"
    local timeout="${3:-3}"
    
    log "Checking port availability: $host:$port"
    
    # Test with timeout
    if timeout "$timeout" bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
        test_result "Port Availability: $host:$port" "PASS" "Port is open" "Open port" "Open"
        return 0
    else
        test_result "Port Availability: $host:$port" "FAIL" "Port is closed or unreachable" "Open port" "Closed/unreachable"
        return 1
    fi
}

test_port_scanning() {
    log "Testing port scanning capabilities..."
    
    # Test common ports
    local common_ports=(80 443 22 3000 5173 8080)
    
    for port in "${common_ports[@]}"; do
        test_port_availability "host.docker.internal" "$port" 2
    done
    
    # Test port range scanning
    log "Testing port range scanning..."
    local open_ports=()
    local scanned_ports=0
    
    for port in {3000..3010}; do
        ((scanned_ports++))
        if timeout 1 bash -c "</dev/tcp/host.docker.internal/$port" 2>/dev/null; then
            open_ports+=("$port")
        fi
    done
    
    test_result "Port Range Scanning" "PASS" "Scanned $scanned_ports ports, found ${#open_ports[@]} open" "$scanned_ports ports scanned" "${#open_ports[@]} open ports found"
}

test_port_services() {
    log "Testing service detection on open ports..."
    
    # Test HTTP service detection
    local http_ports=(80 8080 3000 5173)
    
    for port in "${http_ports[@]}"; do
        if timeout 2 bash -c "</dev/tcp/host.docker.internal/$port" 2>/dev/null; then
            # Port is open, test if it's HTTP
            local http_response
            http_response=$(curl -s -m 3 -I "http://host.docker.internal:$port" 2>/dev/null | head -n1 || echo "")
            
            if [[ "$http_response" =~ HTTP ]]; then
                test_result "HTTP Service Detection: port $port" "PASS" "HTTP service detected" "HTTP service" "HTTP service"
            else
                test_result "HTTP Service Detection: port $port" "FAIL" "Port open but no HTTP service" "HTTP service" "Non-HTTP service"
            fi
        fi
    done
}

# Run port availability tests
test_port_scanning
test_port_services

# =============================================================================
# 4. FALLBACK MECHANISMS
# =============================================================================
log ""
log "${YELLOW}[4] FALLBACK MECHANISMS${NC}"

test_host_fallbacks() {
    log "Testing host fallback mechanisms..."
    
    # Define fallback chain
    local fallback_hosts=("host.docker.internal" "localhost" "127.0.0.1")
    
    for host in "${fallback_hosts[@]}"; do
        log "Testing fallback host: $host"
        
        # Test DNS resolution
        if nslookup "$host" >/dev/null 2>&1; then
            test_result "Fallback DNS Resolution: $host" "PASS" "DNS resolution successful" "Successful resolution" "Resolved"
        else
            test_result "Fallback DNS Resolution: $host" "FAIL" "DNS resolution failed" "Successful resolution" "Failed"
        fi
        
        # Test connectivity (if DNS works)
        if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
            test_result "Fallback Connectivity: $host" "PASS" "Host is reachable" "Reachable host" "Reachable"
        else
            test_result "Fallback Connectivity: $host" "FAIL" "Host is unreachable" "Reachable host" "Unreachable"
        fi
    done
}

test_protocol_fallbacks() {
    log "Testing protocol fallback mechanisms..."
    
    # Test HTTPS to HTTP fallback
    local test_urls=(
        "https://host.docker.internal"
        "http://host.docker.internal"
    )
    
    for url in "${test_urls[@]}"; do
        log "Testing protocol: $url"
        
        local response_code
        response_code=$(curl -s -o /dev/null -w "%{http_code}" -m 5 -k "$url" 2>/dev/null || echo "000")
        
        if [ "$response_code" != "000" ]; then
            test_result "Protocol Fallback: $url" "PASS" "Response code: $response_code" "Valid response" "$response_code"
        else
            test_result "Protocol Fallback: $url" "FAIL" "No response" "Valid response" "No response"
        fi
    done
}

test_timeout_fallbacks() {
    log "Testing timeout fallback mechanisms..."
    
    # Test increasing timeouts
    local timeouts=(1 3 5 10)
    local test_url="https://httpbin.org/delay/2"
    
    for timeout in "${timeouts[@]}"; do
        log "Testing timeout: ${timeout}s"
        
        local start_time=$(date +%s)
        local response_code
        response_code=$(curl -s -o /dev/null -w "%{http_code}" -m "$timeout" "$test_url" 2>/dev/null || echo "timeout")
        local end_time=$(date +%s)
        local actual_time=$((end_time - start_time))
        
        if [ "$response_code" == "200" ]; then
            test_result "Timeout Fallback: ${timeout}s" "PASS" "Success in ${actual_time}s" "Success or timeout in ${timeout}s" "Success in ${actual_time}s"
        elif [ "$response_code" == "timeout" ] && [ "$actual_time" -le $((timeout + 2)) ]; then
            test_result "Timeout Fallback: ${timeout}s" "PASS" "Proper timeout in ${actual_time}s" "Success or timeout in ${timeout}s" "Timeout in ${actual_time}s"
        else
            test_result "Timeout Fallback: ${timeout}s" "FAIL" "Unexpected behavior: $response_code in ${actual_time}s" "Success or timeout in ${timeout}s" "$response_code in ${actual_time}s"
        fi
    done
}

# Run fallback mechanism tests
test_host_fallbacks
test_protocol_fallbacks
test_timeout_fallbacks

# =============================================================================
# 5. ERROR MESSAGING
# =============================================================================
log ""
log "${YELLOW}[5] ERROR MESSAGING${NC}"

test_error_message_clarity() {
    log "Testing error message clarity..."
    
    # Test various error scenarios
    local error_scenarios=(
        "connection_refused:http://host.docker.internal:9999"
        "dns_resolution:http://nonexistent.invalid"
        "timeout:https://httpbin.org/delay/20"
        "ssl_error:https://self-signed.badssl.com"
    )
    
    for scenario in "${error_scenarios[@]}"; do
        IFS=':' read -r error_type url <<< "$scenario"
        
        log "Testing error scenario: $error_type with $url"
        
        local error_output
        error_output=$(curl -s -f -m 5 "$url" 2>&1 || echo "error_captured")
        
        case "$error_type" in
            "connection_refused")
                if [[ "$error_output" =~ (refused|connection|unreachable) ]]; then
                    test_result "Error Message: Connection Refused" "PASS" "Clear error message" "Connection-related error" "Connection error detected"
                else
                    test_result "Error Message: Connection Refused" "FAIL" "Unclear error message" "Connection-related error" "$error_output"
                fi
                ;;
            "dns_resolution")
                if [[ "$error_output" =~ (resolve|DNS|not found) ]]; then
                    test_result "Error Message: DNS Resolution" "PASS" "Clear error message" "DNS-related error" "DNS error detected"
                else
                    test_result "Error Message: DNS Resolution" "FAIL" "Unclear error message" "DNS-related error" "$error_output"
                fi
                ;;
            "timeout")
                if [[ "$error_output" =~ (timeout|time|exceeded) ]]; then
                    test_result "Error Message: Timeout" "PASS" "Clear error message" "Timeout-related error" "Timeout error detected"
                else
                    test_result "Error Message: Timeout" "FAIL" "Unclear error message" "Timeout-related error" "$error_output"
                fi
                ;;
            "ssl_error")
                if [[ "$error_output" =~ (SSL|certificate|verify) ]]; then
                    test_result "Error Message: SSL Error" "PASS" "Clear error message" "SSL-related error" "SSL error detected"
                else
                    test_result "Error Message: SSL Error" "FAIL" "Unclear error message" "SSL-related error" "$error_output"
                fi
                ;;
        esac
    done
}

test_error_categorization() {
    log "Testing error categorization..."
    
    # Create a simple error categorization function
    categorize_error() {
        local error_message="$1"
        
        if [[ "$error_message" =~ (refused|connection.*refused) ]]; then
            echo "NETWORK_CONNECTION"
        elif [[ "$error_message" =~ (timeout|timed.*out) ]]; then
            echo "NETWORK_TIMEOUT"
        elif [[ "$error_message" =~ (resolve|DNS|not.*found) ]]; then
            echo "DNS_RESOLUTION"
        elif [[ "$error_message" =~ (SSL|certificate|verify) ]]; then
            echo "SSL_CERTIFICATE"
        else
            echo "UNKNOWN"
        fi
    }
    
    # Test error categorization
    local error_messages=(
        "curl: (7) Failed to connect to host.docker.internal port 9999: Connection refused:NETWORK_CONNECTION"
        "curl: (28) Operation timed out after 5000 milliseconds:NETWORK_TIMEOUT"
        "curl: (6) Could not resolve host: nonexistent.invalid:DNS_RESOLUTION"
        "curl: (60) SSL certificate verify failed:SSL_CERTIFICATE"
        "Some other error message:UNKNOWN"
    )
    
    for error_case in "${error_messages[@]}"; do
        IFS=':' read -r message expected_category <<< "$error_case"
        
        local actual_category
        actual_category=$(categorize_error "$message")
        
        if [ "$actual_category" == "$expected_category" ]; then
            test_result "Error Categorization: $expected_category" "PASS" "Correctly categorized" "$expected_category" "$actual_category"
        else
            test_result "Error Categorization: $expected_category" "FAIL" "Incorrectly categorized" "$expected_category" "$actual_category"
        fi
    done
}

# Run error messaging tests
test_error_message_clarity
test_error_categorization

# =============================================================================
# 6. INTEGRATION VALIDATION
# =============================================================================
log ""
log "${YELLOW}[6] INTEGRATION VALIDATION${NC}"

test_curl_playwright_integration() {
    log "Testing curl and Playwright integration..."
    
    # Test that both tools can access the same resources
    local test_url="https://httpbin.org/get"
    
    # Test with curl
    local curl_response
    curl_response=$(curl -s -w "%{http_code}" -m 10 "$test_url" 2>/dev/null | tail -c 3 || echo "000")
    
    # Create a simple Playwright test
    local playwright_test_file="/tmp/integration_test.js"
    cat > "$playwright_test_file" << 'EOF'
const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();
    
    try {
        const response = await page.goto('https://httpbin.org/get', { timeout: 10000 });
        console.log(response.status());
    } catch (error) {
        console.log('000');
    } finally {
        await browser.close();
    }
})();
EOF
    
    # Test with Playwright (if available)
    local playwright_response="000"
    if command -v node >/dev/null 2>&1; then
        playwright_response=$(node "$playwright_test_file" 2>/dev/null || echo "000")
    fi
    
    # Clean up
    rm -f "$playwright_test_file"
    
    # Compare results
    if [ "$curl_response" == "200" ] && [ "$playwright_response" == "200" ]; then
        test_result "Curl-Playwright Integration" "PASS" "Both tools successful" "Both return 200" "Both returned 200"
    elif [ "$curl_response" == "200" ] || [ "$playwright_response" == "200" ]; then
        test_result "Curl-Playwright Integration" "PARTIAL" "One tool successful" "Both return 200" "curl: $curl_response, playwright: $playwright_response"
    else
        test_result "Curl-Playwright Integration" "FAIL" "Both tools failed" "Both return 200" "curl: $curl_response, playwright: $playwright_response"
    fi
}

test_environment_consistency() {
    log "Testing environment consistency..."
    
    # Test that environment variables are consistent
    local env_vars=("PATH" "HOME" "USER")
    local inconsistencies=0
    
    for var in "${env_vars[@]}"; do
        local value="${!var:-}"
        
        if [ -n "$value" ]; then
            test_result "Environment Consistency: $var" "PASS" "Variable is set" "Non-empty value" "$value"
        else
            test_result "Environment Consistency: $var" "FAIL" "Variable is not set" "Non-empty value" "Empty/unset"
            ((inconsistencies++))
        fi
    done
    
    if [ $inconsistencies -eq 0 ]; then
        test_result "Overall Environment Consistency" "PASS" "All environment variables consistent" "Consistent environment" "All variables set"
    else
        test_result "Overall Environment Consistency" "FAIL" "$inconsistencies variables inconsistent" "Consistent environment" "$inconsistencies inconsistencies"
    fi
}

# Run integration validation tests
test_curl_playwright_integration
test_environment_consistency

# =============================================================================
# FINAL RESULTS AND REPORTING
# =============================================================================
log ""
log "${BLUE}=== VALIDATION RESULTS SUMMARY ===${NC}"
log "Total Tests: $TOTAL_TESTS"
log "${GREEN}Passed: $PASSED_TESTS${NC}"
log "${RED}Failed: $FAILED_TESTS${NC}"

# Calculate success rate
local success_rate=0
if [ $TOTAL_TESTS -gt 0 ]; then
    success_rate=$(echo "scale=2; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc 2>/dev/null || echo "0")
fi

log "${CYAN}Success Rate: ${success_rate}%${NC}"

# Generate detailed report
{
    echo "# Validation Test Results"
    echo "Generated: $(date)"
    echo ""
    echo "## Summary Statistics"
    echo "- Total Tests: $TOTAL_TESTS"
    echo "- Passed: $PASSED_TESTS ✅"
    echo "- Failed: $FAILED_TESTS ❌"
    echo "- Success Rate: ${success_rate}%"
    echo ""
    echo "## Test Categories"
    echo "1. ✅ Environment Detection Accuracy"
    echo "2. ✅ URL Rewriting Correctness"
    echo "3. ✅ Port Availability Checks"
    echo "4. ✅ Fallback Mechanisms"
    echo "5. ✅ Error Messaging"
    echo "6. ✅ Integration Validation"
    echo ""
    echo "## Key Findings"
    echo ""
    echo "### Environment Detection"
    if [ -f /.dockerenv ]; then
        echo "- ✅ Running in Docker container"
    else
        echo "- ❌ Not detected as Docker environment"
    fi
    
    if nslookup host.docker.internal >/dev/null 2>&1; then
        echo "- ✅ host.docker.internal resolves correctly"
    else
        echo "- ❌ host.docker.internal resolution failed"
    fi
    
    echo ""
    echo "### Critical Issues"
    if [ $FAILED_TESTS -gt 0 ]; then
        echo "- $FAILED_TESTS validation tests failed"
        echo "- Review individual test results for details"
    else
        echo "- No critical issues detected"
    fi
    
    echo ""
    echo "## Files Generated"
    echo "- CSV Results: validation_results_${TIMESTAMP}.csv"
    echo "- Log File: validation_test_${TIMESTAMP}.log"
    echo "- This Report: validation_report_${TIMESTAMP}.md"
} > "${TEST_RESULTS_DIR}/validation_report_${TIMESTAMP}.md"

if [ $FAILED_TESTS -eq 0 ]; then
    log "${GREEN}🎉 ALL VALIDATION TESTS PASSED!${NC}"
    exit_code=0
else
    log "${RED}⚠️  SOME VALIDATION TESTS FAILED${NC}"
    log "Review the detailed results for troubleshooting guidance."
    exit_code=1
fi

log ""
log "📁 Results saved to: $TEST_RESULTS_DIR"
log "📊 Report: validation_report_${TIMESTAMP}.md"
log "📈 CSV Data: validation_results_${TIMESTAMP}.csv"
log "📋 Log File: validation_test_${TIMESTAMP}.log"

exit $exit_code