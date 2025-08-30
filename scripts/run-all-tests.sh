#!/bin/bash

# =============================================================================
# MASTER TEST RUNNER FOR CURL AND PLAYWRIGHT IN DOCKER
# =============================================================================
# Purpose: Execute all test suites in sequence and generate comprehensive report
# Usage: ./run-all-tests.sh [options]
# Options: 
#   --curl-only       Run only curl tests
#   --playwright-only Run only Playwright tests
#   --validation-only Run only validation tests
#   --debug-only      Run only debug procedures
#   --quick          Run abbreviated test suite
#   --verbose        Enable verbose logging
#   --help           Show help message
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${SCRIPT_DIR}/../results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
MASTER_LOG="${RESULTS_DIR}/master_test_${TIMESTAMP}.log"
FINAL_REPORT="${RESULTS_DIR}/comprehensive_report_${TIMESTAMP}.md"

# Default options
RUN_CURL=true
RUN_PLAYWRIGHT=true
RUN_VALIDATION=true
RUN_DEBUG=true
QUICK_MODE=false
VERBOSE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Create results directory
mkdir -p "${RESULTS_DIR}"

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --curl-only)
                RUN_CURL=true
                RUN_PLAYWRIGHT=false
                RUN_VALIDATION=false
                RUN_DEBUG=false
                shift
                ;;
            --playwright-only)
                RUN_CURL=false
                RUN_PLAYWRIGHT=true
                RUN_VALIDATION=false
                RUN_DEBUG=false
                shift
                ;;
            --validation-only)
                RUN_CURL=false
                RUN_PLAYWRIGHT=false
                RUN_VALIDATION=true
                RUN_DEBUG=false
                shift
                ;;
            --debug-only)
                RUN_CURL=false
                RUN_PLAYWRIGHT=false
                RUN_VALIDATION=false
                RUN_DEBUG=true
                shift
                ;;
            --quick)
                QUICK_MODE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Help message
show_help() {
    cat << EOF
${BOLD}Master Test Runner for Curl and Playwright in Docker${NC}

${BOLD}USAGE:${NC}
    $0 [OPTIONS]

${BOLD}OPTIONS:${NC}
    --curl-only       Run only curl tests
    --playwright-only Run only Playwright tests  
    --validation-only Run only validation tests
    --debug-only      Run only debug procedures
    --quick          Run abbreviated test suite
    --verbose        Enable verbose logging
    --help, -h       Show this help message

${BOLD}EXAMPLES:${NC}
    $0                        # Run all test suites
    $0 --curl-only           # Run only curl tests
    $0 --quick --verbose     # Quick run with verbose output
    $0 --validation-only     # Run only validation tests

${BOLD}OUTPUT:${NC}
    Results are saved to: ${RESULTS_DIR}/
    Master log: master_test_${TIMESTAMP}.log
    Final report: comprehensive_report_${TIMESTAMP}.md
EOF
}

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo -e "${CYAN}[INFO]${NC}  ${timestamp}: ${message}" | tee -a "${MASTER_LOG}" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC}  ${timestamp}: ${message}" | tee -a "${MASTER_LOG}" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} ${timestamp}: ${message}" | tee -a "${MASTER_LOG}" ;;
        "OK")    echo -e "${GREEN}[OK]${NC}    ${timestamp}: ${message}" | tee -a "${MASTER_LOG}" ;;
        "TITLE") echo -e "${BOLD}${BLUE}${message}${NC}" | tee -a "${MASTER_LOG}" ;;
        *)       echo -e "${timestamp}: ${message}" | tee -a "${MASTER_LOG}" ;;
    esac
    
    if [ "$VERBOSE" = true ]; then
        echo "$level: $message" >> "${MASTER_LOG}"
    fi
}

# Test result tracking
declare -A TEST_RESULTS
TEST_RESULTS["curl_status"]="NOT_RUN"
TEST_RESULTS["playwright_status"]="NOT_RUN" 
TEST_RESULTS["validation_status"]="NOT_RUN"
TEST_RESULTS["debug_status"]="NOT_RUN"

# Pre-flight checks
preflight_checks() {
    log "TITLE" "=== PRE-FLIGHT CHECKS ==="
    
    # Check if we're in Docker
    if [ -f /.dockerenv ]; then
        log "OK" "Running inside Docker container"
    else
        log "WARN" "Not detected as Docker environment"
    fi
    
    # Check required tools
    local required_tools=("curl" "bash" "bc")
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            log "OK" "$tool is available"
        else
            log "ERROR" "$tool is missing"
            missing_tools+=("$tool")
        fi
    done
    
    # Check for Playwright if needed
    if [ "$RUN_PLAYWRIGHT" = true ]; then
        if command -v node >/dev/null 2>&1; then
            log "OK" "Node.js is available for Playwright"
        else
            log "ERROR" "Node.js is missing - Playwright tests will fail"
        fi
    fi
    
    # Check script permissions
    local test_scripts=("curl-comprehensive-test.sh" "playwright-comprehensive-test.js" "validation-tests.sh" "debug-networking.sh")
    
    for script in "${test_scripts[@]}"; do
        if [ -f "${SCRIPT_DIR}/${script}" ]; then
            if [ -x "${SCRIPT_DIR}/${script}" ]; then
                log "OK" "$script is executable"
            else
                log "WARN" "$script is not executable - fixing..."
                chmod +x "${SCRIPT_DIR}/${script}"
            fi
        else
            log "ERROR" "$script not found"
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log "ERROR" "Missing required tools: ${missing_tools[*]}"
        log "ERROR" "Please install missing tools before running tests"
        exit 1
    fi
    
    log "OK" "Pre-flight checks completed"
}

# Run curl tests
run_curl_tests() {
    if [ "$RUN_CURL" != true ]; then
        return 0
    fi
    
    log "TITLE" ""
    log "TITLE" "=== RUNNING CURL COMPREHENSIVE TESTS ==="
    
    local start_time=$(date +%s)
    local curl_script="${SCRIPT_DIR}/curl-comprehensive-test.sh"
    
    if [ ! -f "$curl_script" ]; then
        log "ERROR" "Curl test script not found: $curl_script"
        TEST_RESULTS["curl_status"]="ERROR"
        return 1
    fi
    
    log "INFO" "Starting curl tests..."
    log "INFO" "Script: $curl_script"
    
    # Run curl tests
    local curl_exit_code=0
    if [ "$VERBOSE" = true ]; then
        bash "$curl_script" 2>&1 | tee -a "${MASTER_LOG}" || curl_exit_code=$?
    else
        bash "$curl_script" >> "${MASTER_LOG}" 2>&1 || curl_exit_code=$?
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ $curl_exit_code -eq 0 ]; then
        log "OK" "Curl tests completed successfully in ${duration}s"
        TEST_RESULTS["curl_status"]="PASSED"
    else
        log "ERROR" "Curl tests failed (exit code: $curl_exit_code) after ${duration}s"
        TEST_RESULTS["curl_status"]="FAILED"
    fi
    
    TEST_RESULTS["curl_duration"]="$duration"
    return $curl_exit_code
}

# Run Playwright tests
run_playwright_tests() {
    if [ "$RUN_PLAYWRIGHT" != true ]; then
        return 0
    fi
    
    log "TITLE" ""
    log "TITLE" "=== RUNNING PLAYWRIGHT COMPREHENSIVE TESTS ==="
    
    local start_time=$(date +%s)
    local playwright_script="${SCRIPT_DIR}/playwright-comprehensive-test.js"
    
    if [ ! -f "$playwright_script" ]; then
        log "ERROR" "Playwright test script not found: $playwright_script"
        TEST_RESULTS["playwright_status"]="ERROR"
        return 1
    fi
    
    log "INFO" "Starting Playwright tests..."
    log "INFO" "Script: $playwright_script"
    
    # Check if we can run Node.js
    if ! command -v node >/dev/null 2>&1; then
        log "ERROR" "Node.js not available - cannot run Playwright tests"
        TEST_RESULTS["playwright_status"]="ERROR"
        return 1
    fi
    
    # Run Playwright tests
    local playwright_exit_code=0
    if [ "$VERBOSE" = true ]; then
        node "$playwright_script" 2>&1 | tee -a "${MASTER_LOG}" || playwright_exit_code=$?
    else
        node "$playwright_script" >> "${MASTER_LOG}" 2>&1 || playwright_exit_code=$?
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ $playwright_exit_code -eq 0 ]; then
        log "OK" "Playwright tests completed successfully in ${duration}s"
        TEST_RESULTS["playwright_status"]="PASSED"
    else
        log "ERROR" "Playwright tests failed (exit code: $playwright_exit_code) after ${duration}s"
        TEST_RESULTS["playwright_status"]="FAILED"
    fi
    
    TEST_RESULTS["playwright_duration"]="$duration"
    return $playwright_exit_code
}

# Run validation tests
run_validation_tests() {
    if [ "$RUN_VALIDATION" != true ]; then
        return 0
    fi
    
    log "TITLE" ""
    log "TITLE" "=== RUNNING VALIDATION TESTS ==="
    
    local start_time=$(date +%s)
    local validation_script="${SCRIPT_DIR}/validation-tests.sh"
    
    if [ ! -f "$validation_script" ]; then
        log "ERROR" "Validation test script not found: $validation_script"
        TEST_RESULTS["validation_status"]="ERROR"
        return 1
    fi
    
    log "INFO" "Starting validation tests..."
    log "INFO" "Script: $validation_script"
    
    # Run validation tests
    local validation_exit_code=0
    if [ "$VERBOSE" = true ]; then
        bash "$validation_script" 2>&1 | tee -a "${MASTER_LOG}" || validation_exit_code=$?
    else
        bash "$validation_script" >> "${MASTER_LOG}" 2>&1 || validation_exit_code=$?
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ $validation_exit_code -eq 0 ]; then
        log "OK" "Validation tests completed successfully in ${duration}s"
        TEST_RESULTS["validation_status"]="PASSED"
    elif [ $validation_exit_code -eq 1 ]; then
        log "WARN" "Validation tests completed with warnings in ${duration}s"
        TEST_RESULTS["validation_status"]="WARNING"
    else
        log "ERROR" "Validation tests failed (exit code: $validation_exit_code) after ${duration}s"
        TEST_RESULTS["validation_status"]="FAILED"
    fi
    
    TEST_RESULTS["validation_duration"]="$duration"
    return $validation_exit_code
}

# Run debug procedures
run_debug_procedures() {
    if [ "$RUN_DEBUG" != true ]; then
        return 0
    fi
    
    log "TITLE" ""
    log "TITLE" "=== RUNNING DEBUG PROCEDURES ==="
    
    local start_time=$(date +%s)
    local debug_script="${SCRIPT_DIR}/debug-networking.sh"
    
    if [ ! -f "$debug_script" ]; then
        log "ERROR" "Debug script not found: $debug_script"
        TEST_RESULTS["debug_status"]="ERROR"
        return 1
    fi
    
    log "INFO" "Starting debug procedures..."
    log "INFO" "Script: $debug_script"
    
    # Run debug procedures
    local debug_exit_code=0
    if [ "$VERBOSE" = true ]; then
        bash "$debug_script" 2>&1 | tee -a "${MASTER_LOG}" || debug_exit_code=$?
    else
        bash "$debug_script" >> "${MASTER_LOG}" 2>&1 || debug_exit_code=$?
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ $debug_exit_code -eq 0 ]; then
        log "OK" "Debug procedures completed successfully in ${duration}s"
        TEST_RESULTS["debug_status"]="PASSED"
    elif [ $debug_exit_code -eq 1 ]; then
        log "WARN" "Debug procedures completed with warnings in ${duration}s"
        TEST_RESULTS["debug_status"]="WARNING"
    else
        log "ERROR" "Debug procedures found critical issues (exit code: $debug_exit_code) after ${duration}s"
        TEST_RESULTS["debug_status"]="CRITICAL"
    fi
    
    TEST_RESULTS["debug_duration"]="$duration"
    return $debug_exit_code
}

# Generate comprehensive report
generate_final_report() {
    log "TITLE" ""
    log "TITLE" "=== GENERATING COMPREHENSIVE REPORT ==="
    
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    local warning_tests=0
    
    # Calculate totals
    for status in "${TEST_RESULTS[@]}"; do
        case "$status" in
            "PASSED") ((passed_tests++)) ;;
            "FAILED"|"ERROR"|"CRITICAL") ((failed_tests++)) ;;
            "WARNING") ((warning_tests++)) ;;
            "NOT_RUN") continue ;;
        esac
        ((total_tests++))
    done
    
    # Generate comprehensive markdown report
    {
        echo "# Comprehensive Test Suite Results"
        echo "Generated: $(date)"
        echo "Duration: $(date -d @$SECONDS -u +%H:%M:%S) (total runtime)"
        echo ""
        
        echo "## Executive Summary"
        
        if [ $failed_tests -eq 0 ] && [ $warning_tests -eq 0 ]; then
            echo "🎉 **Status: EXCELLENT** - All tests passed successfully"
        elif [ $failed_tests -eq 0 ]; then
            echo "⚠️ **Status: GOOD** - All tests passed with $warning_tests warnings"  
        elif [ $failed_tests -lt 2 ]; then
            echo "❌ **Status: NEEDS ATTENTION** - $failed_tests test suite failed"
        else
            echo "🚨 **Status: CRITICAL** - $failed_tests test suites failed"
        fi
        
        echo ""
        echo "### Quick Stats"
        echo "- **Total Test Suites**: $total_tests"
        echo "- **Passed**: $passed_tests ✅"
        echo "- **Failed**: $failed_tests ❌"
        echo "- **Warnings**: $warning_tests ⚠️"
        if [ $total_tests -gt 0 ]; then
            local success_rate=$(echo "scale=1; $passed_tests * 100 / $total_tests" | bc)
            echo "- **Success Rate**: ${success_rate}%"
        fi
        
        echo ""
        echo "## Test Suite Results"
        echo ""
        
        # Curl tests
        echo "### 1. Curl Comprehensive Tests"
        case "${TEST_RESULTS[curl_status]}" in
            "PASSED") echo "- **Status**: ✅ PASSED" ;;
            "FAILED") echo "- **Status**: ❌ FAILED" ;;
            "ERROR")  echo "- **Status**: 🚨 ERROR" ;;
            *)        echo "- **Status**: ⏭️ NOT RUN" ;;
        esac
        [ -n "${TEST_RESULTS[curl_duration]:-}" ] && echo "- **Duration**: ${TEST_RESULTS[curl_duration]}s"
        echo "- **Purpose**: Test curl functionality in Docker with various scenarios"
        echo "- **Coverage**: HTTP requests, HTTPS certificates, different ports, POST data, authentication, timeouts"
        echo ""
        
        # Playwright tests  
        echo "### 2. Playwright Comprehensive Tests"
        case "${TEST_RESULTS[playwright_status]}" in
            "PASSED") echo "- **Status**: ✅ PASSED" ;;
            "FAILED") echo "- **Status**: ❌ FAILED" ;;
            "ERROR")  echo "- **Status**: 🚨 ERROR" ;;
            *)        echo "- **Status**: ⏭️ NOT RUN" ;;
        esac
        [ -n "${TEST_RESULTS[playwright_duration]:-}" ] && echo "- **Duration**: ${TEST_RESULTS[playwright_duration]}s"
        echo "- **Purpose**: Test Playwright browser automation in Docker environment"
        echo "- **Coverage**: Screenshot capture, browser automation, Vite integration, network interception, error recovery"
        echo ""
        
        # Validation tests
        echo "### 3. Validation Tests"
        case "${TEST_RESULTS[validation_status]}" in
            "PASSED")  echo "- **Status**: ✅ PASSED" ;;
            "WARNING") echo "- **Status**: ⚠️ WARNING" ;;
            "FAILED")  echo "- **Status**: ❌ FAILED" ;;
            "ERROR")   echo "- **Status**: 🚨 ERROR" ;;
            *)         echo "- **Status**: ⏭️ NOT RUN" ;;
        esac
        [ -n "${TEST_RESULTS[validation_duration]:-}" ] && echo "- **Duration**: ${TEST_RESULTS[validation_duration]}s"
        echo "- **Purpose**: Validate environment detection, URL rewriting, port availability, and fallback mechanisms"
        echo "- **Coverage**: Environment detection, URL rewriting, port scanning, fallback logic, error messaging"
        echo ""
        
        # Debug procedures
        echo "### 4. Debug Procedures"
        case "${TEST_RESULTS[debug_status]}" in
            "PASSED")   echo "- **Status**: ✅ HEALTHY" ;;
            "WARNING")  echo "- **Status**: ⚠️ MINOR ISSUES" ;;
            "CRITICAL") echo "- **Status**: 🚨 CRITICAL ISSUES" ;;
            "FAILED")   echo "- **Status**: ❌ DEBUG FAILED" ;;
            "ERROR")    echo "- **Status**: 🚨 ERROR" ;;
            *)          echo "- **Status**: ⏭️ NOT RUN" ;;
        esac
        [ -n "${TEST_RESULTS[debug_duration]:-}" ] && echo "- **Duration**: ${TEST_RESULTS[debug_duration]}s"
        echo "- **Purpose**: Comprehensive network and connectivity diagnostics"
        echo "- **Coverage**: Network connectivity, DNS resolution, port conflicts, permissions, security restrictions"
        echo ""
        
        echo "## Key Findings"
        echo ""
        
        # Docker environment
        if [ -f /.dockerenv ]; then
            echo "### Environment"
            echo "- ✅ Running in Docker container"
            if nslookup host.docker.internal >/dev/null 2>&1; then
                echo "- ✅ host.docker.internal resolves correctly"
            else
                echo "- ❌ host.docker.internal resolution failed"
            fi
        fi
        
        # Network connectivity
        echo ""
        echo "### Network Connectivity"
        if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
            echo "- ✅ Internet connectivity working"
        else
            echo "- ❌ No internet connectivity"
        fi
        
        if ping -c 1 -W 3 host.docker.internal >/dev/null 2>&1 2>/dev/null; then
            echo "- ✅ Docker host connectivity working"
        else
            echo "- ❌ Docker host connectivity failed"
        fi
        
        echo ""
        echo "## Recommendations"
        echo ""
        
        if [ $failed_tests -eq 0 ] && [ $warning_tests -eq 0 ]; then
            echo "🎉 **Excellent!** Your Docker environment is optimally configured for curl and Playwright."
            echo ""
            echo "### Next Steps"
            echo "1. Use the test scripts regularly to monitor environment health"
            echo "2. Integrate successful patterns into your development workflow"
            echo "3. Share these configurations with your team"
        else
            echo "### Immediate Actions Required"
            
            if [[ "${TEST_RESULTS[curl_status]}" == "FAILED" ]]; then
                echo "1. **Fix curl issues**: Review curl test results and network connectivity"
            fi
            
            if [[ "${TEST_RESULTS[playwright_status]}" == "FAILED" ]]; then
                echo "2. **Fix Playwright issues**: Check Node.js installation and browser dependencies"
            fi
            
            if [[ "${TEST_RESULTS[validation_status]}" == "FAILED" ]]; then
                echo "3. **Fix validation issues**: Review environment detection and URL rewriting logic"
            fi
            
            if [[ "${TEST_RESULTS[debug_status]}" =~ ^(CRITICAL|FAILED)$ ]]; then
                echo "4. **Critical network issues**: Run debug procedures and apply suggested fixes"
            fi
            
            echo ""
            echo "### Detailed Investigation"
            echo "- Review individual test logs in the results directories"
            echo "- Run specific test suites with --verbose flag"
            echo "- Use debug procedures to identify root causes"
            echo "- Apply automated fixes where available"
        fi
        
        echo ""
        echo "## Files Generated"
        echo ""
        echo "### Master Test Files"
        echo "- **Master Log**: [master_test_${TIMESTAMP}.log](./master_test_${TIMESTAMP}.log)"
        echo "- **This Report**: [comprehensive_report_${TIMESTAMP}.md](./comprehensive_report_${TIMESTAMP}.md)"
        echo ""
        
        echo "### Individual Test Results"
        if [ "$RUN_CURL" = true ]; then
            echo "- **Curl Results**: \`results/curl/\` directory"
        fi
        if [ "$RUN_PLAYWRIGHT" = true ]; then
            echo "- **Playwright Results**: \`results/playwright/\` directory"  
        fi
        if [ "$RUN_VALIDATION" = true ]; then
            echo "- **Validation Results**: \`results/validation/\` directory"
        fi
        if [ "$RUN_DEBUG" = true ]; then
            echo "- **Debug Results**: \`results/debug/\` directory"
        fi
        
        echo ""
        echo "## Test Configuration"
        echo ""
        echo "- **Timestamp**: $TIMESTAMP"
        echo "- **Quick Mode**: $QUICK_MODE"
        echo "- **Verbose Mode**: $VERBOSE"
        echo "- **Curl Tests**: $RUN_CURL"
        echo "- **Playwright Tests**: $RUN_PLAYWRIGHT"
        echo "- **Validation Tests**: $RUN_VALIDATION"
        echo "- **Debug Procedures**: $RUN_DEBUG"
        
        echo ""
        echo "---"
        echo ""
        echo "*Generated by Docker Test Suite v1.0*"
        echo "*For support and updates, see project documentation*"
        
    } > "$FINAL_REPORT"
    
    log "OK" "Comprehensive report generated: $FINAL_REPORT"
}

# Display final summary
display_summary() {
    log "TITLE" ""
    log "TITLE" "=== FINAL SUMMARY ==="
    
    local overall_status="UNKNOWN"
    local failed_count=0
    local warning_count=0
    local passed_count=0
    
    # Count results
    for key in "${!TEST_RESULTS[@]}"; do
        if [[ "$key" =~ _status$ ]]; then
            case "${TEST_RESULTS[$key]}" in
                "PASSED") ((passed_count++)) ;;
                "FAILED"|"ERROR"|"CRITICAL") ((failed_count++)) ;;
                "WARNING") ((warning_count++)) ;;
            esac
        fi
    done
    
    # Determine overall status
    if [ $failed_count -eq 0 ] && [ $warning_count -eq 0 ]; then
        overall_status="EXCELLENT"
    elif [ $failed_count -eq 0 ]; then
        overall_status="GOOD"
    elif [ $failed_count -lt 2 ]; then
        overall_status="NEEDS_ATTENTION"
    else
        overall_status="CRITICAL"
    fi
    
    # Display summary
    case "$overall_status" in
        "EXCELLENT")
            log "OK" "🎉 EXCELLENT: All tests passed successfully!"
            ;;
        "GOOD")
            log "OK" "✅ GOOD: All tests passed with $warning_count warning(s)"
            ;;
        "NEEDS_ATTENTION")
            log "WARN" "⚠️ NEEDS ATTENTION: $failed_count test suite(s) failed"
            ;;
        "CRITICAL")
            log "ERROR" "🚨 CRITICAL: $failed_count test suite(s) failed"
            ;;
    esac
    
    log "INFO" ""
    log "INFO" "📊 Test Summary:"
    log "INFO" "   Passed: $passed_count"
    log "INFO" "   Failed: $failed_count"
    log "INFO" "   Warnings: $warning_count"
    
    log "INFO" ""
    log "INFO" "📁 Results Location: $RESULTS_DIR"
    log "INFO" "📋 Master Log: $MASTER_LOG"
    log "INFO" "📊 Final Report: $FINAL_REPORT"
    log "INFO" ""
    
    # Return appropriate exit code
    if [ $failed_count -gt 0 ]; then
        return 1
    elif [ $warning_count -gt 0 ]; then
        return 2
    else
        return 0
    fi
}

# Main execution
main() {
    parse_args "$@"
    
    # Header
    log "TITLE" "╔═══════════════════════════════════════════════════════════════════╗"
    log "TITLE" "║                    DOCKER TEST SUITE MASTER RUNNER               ║"
    log "TITLE" "║          Comprehensive Testing for Curl & Playwright             ║"
    log "TITLE" "╚═══════════════════════════════════════════════════════════════════╝"
    log "INFO" ""
    log "INFO" "Starting comprehensive test suite..."
    log "INFO" "Timestamp: $TIMESTAMP"
    log "INFO" "Results directory: $RESULTS_DIR"
    
    local start_time=$(date +%s)
    local overall_exit_code=0
    
    # Run pre-flight checks
    preflight_checks
    
    # Run test suites
    run_curl_tests || overall_exit_code=$?
    run_playwright_tests || overall_exit_code=$?
    run_validation_tests || overall_exit_code=$?
    run_debug_procedures || overall_exit_code=$?
    
    # Generate reports
    generate_final_report
    
    # Display summary
    display_summary || overall_exit_code=$?
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    log "INFO" ""
    log "INFO" "⏱️  Total execution time: ${total_duration}s"
    log "INFO" "✅ Test suite execution completed"
    
    exit $overall_exit_code
}

# Execute main function
main "$@"