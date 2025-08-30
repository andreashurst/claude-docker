#!/bin/bash

# =============================================================================
# CURL COMPREHENSIVE TEST SUITE FOR DOCKER ENVIRONMENTS
# =============================================================================
# Purpose: Test curl functionality in Docker with various scenarios including
#          different ports, protocols, authentication, and error handling
# Environment: Docker containers with host.docker.internal networking
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_RESULTS_DIR="${SCRIPT_DIR}/../results/curl"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${TEST_RESULTS_DIR}/curl_test_${TIMESTAMP}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
    
    ((TOTAL_TESTS++))
    
    if [ "$result" == "PASS" ]; then
        ((PASSED_TESTS++))
        log "${GREEN}✅ PASS${NC}: $test_name"
    else
        ((FAILED_TESTS++))
        log "${RED}❌ FAIL${NC}: $test_name - $details"
    fi
    
    echo "$result,$test_name,$details" >> "${TEST_RESULTS_DIR}/results_${TIMESTAMP}.csv"
}

# Initialize CSV results file
echo "Result,Test Name,Details" > "${TEST_RESULTS_DIR}/results_${TIMESTAMP}.csv"

log "${BLUE}=== CURL COMPREHENSIVE TEST SUITE ===${NC}"
log "Timestamp: $(date)"
log "Results Directory: $TEST_RESULTS_DIR"
log "Log File: $LOG_FILE"
log ""

# =============================================================================
# 1. BASIC HTTP REQUESTS TO HOST SERVICES
# =============================================================================
log "${YELLOW}[1] BASIC HTTP REQUESTS TO HOST SERVICES${NC}"

test_basic_http() {
    local url="$1"
    local expected_status="$2"
    local test_name="Basic HTTP - $url"
    
    log "Testing: $url (expecting $expected_status)"
    
    # Test with timeout and follow redirects
    local response_code
    response_code=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 10 "$url" 2>/dev/null || echo "000")
    
    if [ "$response_code" == "$expected_status" ]; then
        test_result "$test_name" "PASS" "Status: $response_code"
    else
        test_result "$test_name" "FAIL" "Expected: $expected_status, Got: $response_code"
    fi
}

# Test various host services
test_basic_http "http://host.docker.internal" "200"
test_basic_http "http://host.docker.internal:80" "200"
test_basic_http "http://localhost" "200"
test_basic_http "https://www.google.com" "200"

# Test non-existent service
test_basic_http "http://host.docker.internal:9999" "000"

# =============================================================================
# 2. HTTPS WITH CERTIFICATES
# =============================================================================
log ""
log "${YELLOW}[2] HTTPS WITH CERTIFICATES${NC}"

test_https() {
    local url="$1"
    local test_name="HTTPS - $url"
    
    log "Testing HTTPS: $url"
    
    # Test with SSL verification
    local ssl_result
    ssl_result=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")
    
    if [ "$ssl_result" == "200" ]; then
        test_result "$test_name (SSL Verify)" "PASS" "SSL verification successful"
    else
        test_result "$test_name (SSL Verify)" "FAIL" "SSL verification failed: $ssl_result"
        
        # Test with SSL verification disabled
        local ssl_skip_result
        ssl_skip_result=$(curl -k -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")
        
        if [ "$ssl_skip_result" == "200" ]; then
            test_result "$test_name (SSL Skip)" "PASS" "SSL skip successful"
        else
            test_result "$test_name (SSL Skip)" "FAIL" "Failed even with SSL skip: $ssl_skip_result"
        fi
    fi
}

# Test HTTPS endpoints
test_https "https://www.google.com"
test_https "https://httpbin.org/get"
test_https "https://self-signed.badssl.com" # Should fail SSL verification

# =============================================================================
# 3. DIFFERENT PORTS (3000, 5173, 8080, etc.)
# =============================================================================
log ""
log "${YELLOW}[3] TESTING DIFFERENT PORTS${NC}"

test_port() {
    local host="$1"
    local port="$2"
    local test_name="Port Test - $host:$port"
    
    log "Testing port: $host:$port"
    
    # First check if port is open with timeout
    if timeout 5 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
        # Port is open, test HTTP
        local response
        response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$host:$port" 2>/dev/null || echo "000")
        
        if [ "$response" != "000" ]; then
            test_result "$test_name" "PASS" "Port open, HTTP response: $response"
        else
            test_result "$test_name" "FAIL" "Port open but no HTTP response"
        fi
    else
        test_result "$test_name" "FAIL" "Port not accessible or connection refused"
    fi
}

# Common development ports
declare -a common_ports=("3000" "5173" "8080" "8000" "3001" "4000" "9000")

for port in "${common_ports[@]}"; do
    test_port "host.docker.internal" "$port"
done

# =============================================================================
# 4. POST REQUESTS WITH DATA
# =============================================================================
log ""
log "${YELLOW}[4] POST REQUESTS WITH DATA${NC}"

test_post() {
    local url="$1"
    local data="$2"
    local content_type="$3"
    local test_name="POST - $url"
    
    log "Testing POST to: $url"
    
    local response_code
    response_code=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST \
        -H "Content-Type: $content_type" \
        -d "$data" \
        --max-time 10 \
        "$url" 2>/dev/null || echo "000")
    
    if [ "$response_code" != "000" ] && [ "$response_code" != "404" ]; then
        test_result "$test_name" "PASS" "Response: $response_code"
    else
        test_result "$test_name" "FAIL" "No response or 404: $response_code"
    fi
}

# Test POST requests
test_post "https://httpbin.org/post" '{"test": "data"}' "application/json"
test_post "https://httpbin.org/post" "key=value&test=data" "application/x-www-form-urlencoded"

# =============================================================================
# 5. HEADERS AND AUTHENTICATION
# =============================================================================
log ""
log "${YELLOW}[5] HEADERS AND AUTHENTICATION${NC}"

test_headers() {
    local url="$1"
    local test_name="Headers - $url"
    
    log "Testing custom headers: $url"
    
    local response
    response=$(curl -s -w "%{http_code}" \
        -H "User-Agent: CURL-TEST-SUITE/1.0" \
        -H "X-Test-Header: test-value" \
        -H "Accept: application/json" \
        --max-time 10 \
        "$url" 2>/dev/null || echo "000")
    
    local status_code="${response: -3}"
    
    if [ "$status_code" == "200" ]; then
        test_result "$test_name" "PASS" "Custom headers accepted"
    else
        test_result "$test_name" "FAIL" "Headers test failed: $status_code"
    fi
}

test_basic_auth() {
    local url="https://httpbin.org/basic-auth/user/pass"
    local test_name="Basic Auth"
    
    log "Testing basic authentication"
    
    # Test without auth (should fail)
    local no_auth_response
    no_auth_response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")
    
    # Test with correct auth
    local auth_response
    auth_response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 -u "user:pass" "$url" 2>/dev/null || echo "000")
    
    if [ "$no_auth_response" == "401" ] && [ "$auth_response" == "200" ]; then
        test_result "$test_name" "PASS" "Auth working correctly"
    else
        test_result "$test_name" "FAIL" "No auth: $no_auth_response, With auth: $auth_response"
    fi
}

# Test headers and authentication
test_headers "https://httpbin.org/headers"
test_basic_auth

# =============================================================================
# 6. TIMEOUT HANDLING
# =============================================================================
log ""
log "${YELLOW}[6] TIMEOUT HANDLING${NC}"

test_timeout() {
    local url="$1"
    local timeout="$2"
    local test_name="Timeout - ${timeout}s"
    
    log "Testing timeout ($timeout seconds): $url"
    
    local start_time=$(date +%s)
    local response_code
    response_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" "$url" 2>/dev/null || echo "timeout")
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    
    if [ "$response_code" == "timeout" ] && [ "$elapsed" -le $((timeout + 2)) ]; then
        test_result "$test_name" "PASS" "Timeout handled correctly in ${elapsed}s"
    elif [ "$response_code" == "200" ]; then
        test_result "$test_name" "PASS" "Response received in ${elapsed}s"
    else
        test_result "$test_name" "FAIL" "Unexpected result: $response_code in ${elapsed}s"
    fi
}

# Test timeout scenarios
test_timeout "https://httpbin.org/delay/2" 5  # Should succeed
test_timeout "https://httpbin.org/delay/10" 3 # Should timeout

# =============================================================================
# 7. ENVIRONMENT DETECTION ACCURACY
# =============================================================================
log ""
log "${YELLOW}[7] ENVIRONMENT DETECTION${NC}"

test_environment_detection() {
    log "Detecting Docker environment characteristics"
    
    # Check if we're in Docker
    if [ -f /.dockerenv ]; then
        test_result "Docker Environment Detection" "PASS" "Running inside Docker container"
    else
        test_result "Docker Environment Detection" "FAIL" "Not detected as Docker environment"
    fi
    
    # Test host.docker.internal resolution
    if nslookup host.docker.internal >/dev/null 2>&1; then
        test_result "host.docker.internal Resolution" "PASS" "DNS resolution successful"
    else
        test_result "host.docker.internal Resolution" "FAIL" "Cannot resolve host.docker.internal"
    fi
    
    # Test network connectivity
    local gateway
    gateway=$(ip route | grep default | awk '{print $3}' | head -n1)
    if [ -n "$gateway" ]; then
        if ping -c 1 -W 3 "$gateway" >/dev/null 2>&1; then
            test_result "Network Gateway Connectivity" "PASS" "Can reach gateway: $gateway"
        else
            test_result "Network Gateway Connectivity" "FAIL" "Cannot reach gateway: $gateway"
        fi
    else
        test_result "Network Gateway Detection" "FAIL" "Cannot detect network gateway"
    fi
}

test_environment_detection

# =============================================================================
# 8. URL REWRITING CORRECTNESS
# =============================================================================
log ""
log "${YELLOW}[8] URL REWRITING TESTS${NC}"

test_url_rewriting() {
    local original_url="$1"
    local expected_rewritten="$2"
    local test_name="URL Rewriting - $original_url"
    
    log "Testing URL rewriting: $original_url -> $expected_rewritten"
    
    # Simulate URL rewriting logic
    local rewritten_url="$original_url"
    
    # Replace localhost with host.docker.internal
    rewritten_url="${rewritten_url//localhost/host.docker.internal}"
    
    # Replace 127.0.0.1 with host.docker.internal
    rewritten_url="${rewritten_url//127.0.0.1/host.docker.internal}"
    
    if [ "$rewritten_url" == "$expected_rewritten" ]; then
        test_result "$test_name" "PASS" "Correctly rewritten"
    else
        test_result "$test_name" "FAIL" "Expected: $expected_rewritten, Got: $rewritten_url"
    fi
}

# Test URL rewriting scenarios
test_url_rewriting "http://localhost:3000/test" "http://host.docker.internal:3000/test"
test_url_rewriting "http://127.0.0.1:8080/api" "http://host.docker.internal:8080/api"
test_url_rewriting "https://external.com/test" "https://external.com/test" # Should not change

# =============================================================================
# 9. PERFORMANCE AND RESPONSE TIME TESTS
# =============================================================================
log ""
log "${YELLOW}[9] PERFORMANCE TESTS${NC}"

test_performance() {
    local url="$1"
    local max_time="$2"
    local test_name="Performance - $url"
    
    log "Testing performance: $url (max ${max_time}s)"
    
    local curl_output
    curl_output=$(curl -s -o /dev/null -w "%{time_total},%{time_connect},%{time_starttransfer},%{size_download},%{speed_download}" --max-time 10 "$url" 2>/dev/null || echo "error,error,error,error,error")
    
    IFS=',' read -r time_total time_connect time_starttransfer size_download speed_download <<< "$curl_output"
    
    if [ "$time_total" != "error" ]; then
        local time_comparison=$(echo "$time_total < $max_time" | bc -l 2>/dev/null || echo "0")
        if [ "$time_comparison" == "1" ]; then
            test_result "$test_name" "PASS" "Time: ${time_total}s, Size: ${size_download}B, Speed: ${speed_download}B/s"
        else
            test_result "$test_name" "FAIL" "Too slow: ${time_total}s > ${max_time}s"
        fi
    else
        test_result "$test_name" "FAIL" "Performance test failed"
    fi
}

# Test performance
test_performance "https://www.google.com" 3.0
test_performance "http://host.docker.internal" 2.0

# =============================================================================
# 10. ERROR HANDLING AND RECOVERY
# =============================================================================
log ""
log "${YELLOW}[10] ERROR HANDLING AND RECOVERY${NC}"

test_error_handling() {
    local scenario="$1"
    local url="$2"
    local expected_behavior="$3"
    local test_name="Error Handling - $scenario"
    
    log "Testing error scenario: $scenario"
    
    local result
    result=$(curl -s -f -w "%{http_code}" --max-time 5 "$url" 2>/dev/null || echo "error")
    
    case "$expected_behavior" in
        "connection_refused")
            if [[ "$result" == "error" ]]; then
                test_result "$test_name" "PASS" "Correctly handled connection refused"
            else
                test_result "$test_name" "FAIL" "Should have failed with connection refused"
            fi
            ;;
        "404")
            if [[ "$result" == "error" ]] || [[ "$result" == *"404"* ]]; then
                test_result "$test_name" "PASS" "Correctly handled 404"
            else
                test_result "$test_name" "FAIL" "Should have failed with 404: $result"
            fi
            ;;
        "timeout")
            if [[ "$result" == "error" ]]; then
                test_result "$test_name" "PASS" "Correctly handled timeout"
            else
                test_result "$test_name" "FAIL" "Should have timed out: $result"
            fi
            ;;
    esac
}

# Test error scenarios
test_error_handling "Connection Refused" "http://host.docker.internal:9876" "connection_refused"
test_error_handling "404 Not Found" "https://httpbin.org/status/404" "404"
test_error_handling "Timeout" "https://httpbin.org/delay/10" "timeout"

# =============================================================================
# FINAL RESULTS AND SUMMARY
# =============================================================================
log ""
log "${BLUE}=== TEST RESULTS SUMMARY ===${NC}"
log "Total Tests: $TOTAL_TESTS"
log "${GREEN}Passed: $PASSED_TESTS${NC}"
log "${RED}Failed: $FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    log "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    exit_code=0
else
    log "${RED}⚠️  SOME TESTS FAILED${NC}"
    exit_code=1
fi

# Generate summary report
{
    echo "# CURL Test Results Summary"
    echo "Generated: $(date)"
    echo ""
    echo "## Statistics"
    echo "- Total Tests: $TOTAL_TESTS"
    echo "- Passed: $PASSED_TESTS"
    echo "- Failed: $FAILED_TESTS"
    echo "- Success Rate: $(echo "scale=2; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc)%"
    echo ""
    echo "## Test Categories Covered"
    echo "1. ✅ Basic HTTP Requests to Host Services"
    echo "2. ✅ HTTPS with Certificates"
    echo "3. ✅ Different Ports (3000, 5173, 8080, etc.)"
    echo "4. ✅ POST Requests with Data"
    echo "5. ✅ Headers and Authentication"
    echo "6. ✅ Timeout Handling"
    echo "7. ✅ Environment Detection Accuracy"
    echo "8. ✅ URL Rewriting Correctness"
    echo "9. ✅ Performance and Response Time"
    echo "10. ✅ Error Handling and Recovery"
    echo ""
    echo "## Files Generated"
    echo "- Log File: $LOG_FILE"
    echo "- CSV Results: ${TEST_RESULTS_DIR}/results_${TIMESTAMP}.csv"
    echo "- Summary Report: ${TEST_RESULTS_DIR}/summary_${TIMESTAMP}.md"
} > "${TEST_RESULTS_DIR}/summary_${TIMESTAMP}.md"

log ""
log "📁 Results saved to: $TEST_RESULTS_DIR"
log "📊 Summary report: ${TEST_RESULTS_DIR}/summary_${TIMESTAMP}.md"
log "📈 CSV data: ${TEST_RESULTS_DIR}/results_${TIMESTAMP}.csv"

exit $exit_code