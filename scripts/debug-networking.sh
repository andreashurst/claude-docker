#!/bin/bash

# =============================================================================
# DEBUGGING PROCEDURES FOR NETWORKING AND CONNECTIVITY ISSUES
# =============================================================================
# Purpose: Comprehensive debugging tools for network connectivity issues,
#          DNS resolution problems, port binding conflicts, and permission errors
# Environment: Docker containers with host.docker.internal networking
# =============================================================================

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEBUG_RESULTS_DIR="${SCRIPT_DIR}/../results/debug"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${DEBUG_RESULTS_DIR}/debug_${TIMESTAMP}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Create results directory
mkdir -p "${DEBUG_RESULTS_DIR}"

# Logging function with levels
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        "INFO")  echo -e "${CYAN}[INFO]${NC}  ${timestamp}: ${message}" | tee -a "${LOG_FILE}" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC}  ${timestamp}: ${message}" | tee -a "${LOG_FILE}" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} ${timestamp}: ${message}" | tee -a "${LOG_FILE}" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} ${timestamp}: ${message}" | tee -a "${LOG_FILE}" ;;
        "OK")    echo -e "${GREEN}[OK]${NC}    ${timestamp}: ${message}" | tee -a "${LOG_FILE}" ;;
        *)       echo -e "${timestamp}: ${message}" | tee -a "${LOG_FILE}" ;;
    esac
}

# Header
log "INFO" "=== NETWORKING DEBUG SUITE ==="
log "INFO" "Starting comprehensive network debugging session"
log "INFO" "Results directory: $DEBUG_RESULTS_DIR"
log "INFO" "Debug log: $LOG_FILE"
log "INFO" ""

# =============================================================================
# 1. NETWORK CONNECTIVITY ISSUES
# =============================================================================
log "INFO" "[1] NETWORK CONNECTIVITY DIAGNOSTICS"

debug_network_connectivity() {
    log "DEBUG" "Starting network connectivity diagnostics..."
    
    # Test 1: Basic network interface information
    log "INFO" "Gathering network interface information..."
    {
        echo "=== Network Interfaces ==="
        ip addr show 2>/dev/null || ifconfig 2>/dev/null || echo "No network interface tools available"
        echo ""
        
        echo "=== Routing Table ==="
        ip route 2>/dev/null || route -n 2>/dev/null || echo "No routing tools available"
        echo ""
        
        echo "=== Network Statistics ==="
        ss -tuln 2>/dev/null || netstat -tuln 2>/dev/null || echo "No network statistics tools available"
        echo ""
    } > "${DEBUG_RESULTS_DIR}/network_info_${TIMESTAMP}.txt"
    
    log "OK" "Network interface information saved"
    
    # Test 2: Gateway connectivity
    log "INFO" "Testing gateway connectivity..."
    local gateway
    gateway=$(ip route | grep default | awk '{print $3}' | head -n1 2>/dev/null || echo "")
    
    if [ -n "$gateway" ]; then
        log "INFO" "Default gateway: $gateway"
        
        if ping -c 3 -W 3 "$gateway" >/dev/null 2>&1; then
            log "OK" "Gateway is reachable"
        else
            log "ERROR" "Gateway is unreachable"
            log "DEBUG" "Running traceroute to gateway..."
            timeout 10 traceroute "$gateway" 2>/dev/null | head -10 | tee -a "${LOG_FILE}" || log "WARN" "Traceroute failed"
        fi
    else
        log "ERROR" "No default gateway found"
    fi
    
    # Test 3: DNS connectivity
    log "INFO" "Testing DNS connectivity..."
    local dns_servers=("8.8.8.8" "1.1.1.1" "8.8.4.4")
    
    for dns in "${dns_servers[@]}"; do
        if ping -c 1 -W 3 "$dns" >/dev/null 2>&1; then
            log "OK" "DNS server $dns is reachable"
        else
            log "WARN" "DNS server $dns is unreachable"
        fi
    done
    
    # Test 4: Internet connectivity
    log "INFO" "Testing internet connectivity..."
    local test_hosts=("google.com" "github.com" "httpbin.org")
    
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 5 "$host" >/dev/null 2>&1; then
            log "OK" "Can reach $host"
        else
            log "ERROR" "Cannot reach $host"
        fi
    done
    
    # Test 5: Docker-specific networking
    log "INFO" "Testing Docker-specific networking..."
    
    # Check if we're in a Docker container
    if [ -f /.dockerenv ]; then
        log "OK" "Running inside Docker container"
        
        # Test host.docker.internal
        if ping -c 1 -W 3 host.docker.internal >/dev/null 2>&1; then
            log "OK" "host.docker.internal is reachable"
        else
            log "ERROR" "host.docker.internal is unreachable"
            log "DEBUG" "Attempting DNS resolution of host.docker.internal..."
            nslookup host.docker.internal 2>&1 | tee -a "${LOG_FILE}"
        fi
    else
        log "WARN" "Not running in Docker container"
    fi
}

debug_port_connectivity() {
    log "INFO" "Testing port connectivity..."
    
    # Common ports to test
    local test_ports=(
        "host.docker.internal:80"
        "host.docker.internal:443"
        "host.docker.internal:3000"
        "host.docker.internal:5173"
        "host.docker.internal:8080"
        "google.com:80"
        "google.com:443"
    )
    
    for host_port in "${test_ports[@]}"; do
        IFS=':' read -r host port <<< "$host_port"
        
        log "DEBUG" "Testing connectivity to $host:$port..."
        
        if timeout 5 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
            log "OK" "Port $host:$port is open"
            
            # Test HTTP if it's a common HTTP port
            if [[ "$port" =~ ^(80|443|3000|5173|8080)$ ]]; then
                local protocol="http"
                [ "$port" == "443" ] && protocol="https"
                
                local response
                response=$(curl -s -m 5 -I "$protocol://$host:$port" 2>/dev/null | head -n1 || echo "")
                if [[ "$response" =~ HTTP ]]; then
                    log "OK" "HTTP service detected on $host:$port"
                else
                    log "WARN" "Port open but no HTTP service on $host:$port"
                fi
            fi
        else
            log "ERROR" "Port $host:$port is closed or unreachable"
        fi
    done
}

# Run network connectivity tests
debug_network_connectivity
debug_port_connectivity

# =============================================================================
# 2. DNS RESOLUTION PROBLEMS
# =============================================================================
log "INFO" ""
log "INFO" "[2] DNS RESOLUTION DIAGNOSTICS"

debug_dns_resolution() {
    log "DEBUG" "Starting DNS resolution diagnostics..."
    
    # Test 1: DNS configuration
    log "INFO" "Checking DNS configuration..."
    {
        echo "=== /etc/resolv.conf ==="
        cat /etc/resolv.conf 2>/dev/null || echo "Cannot read /etc/resolv.conf"
        echo ""
        
        echo "=== /etc/hosts ==="
        cat /etc/hosts 2>/dev/null || echo "Cannot read /etc/hosts"
        echo ""
        
        echo "=== /etc/nsswitch.conf (DNS section) ==="
        grep -E "^hosts:" /etc/nsswitch.conf 2>/dev/null || echo "Cannot read /etc/nsswitch.conf"
        echo ""
    } > "${DEBUG_RESULTS_DIR}/dns_config_${TIMESTAMP}.txt"
    
    log "OK" "DNS configuration saved"
    
    # Test 2: DNS server testing
    log "INFO" "Testing DNS servers..."
    
    local dns_servers
    dns_servers=$(grep -E "^nameserver" /etc/resolv.conf 2>/dev/null | awk '{print $2}' || echo "8.8.8.8")
    
    for dns_server in $dns_servers; do
        log "DEBUG" "Testing DNS server: $dns_server"
        
        # Test DNS server reachability
        if ping -c 1 -W 3 "$dns_server" >/dev/null 2>&1; then
            log "OK" "DNS server $dns_server is reachable"
        else
            log "ERROR" "DNS server $dns_server is unreachable"
        fi
        
        # Test DNS resolution using specific server
        local test_domains=("google.com" "github.com" "host.docker.internal")
        
        for domain in "${test_domains[@]}"; do
            if nslookup "$domain" "$dns_server" >/dev/null 2>&1; then
                log "OK" "Can resolve $domain using $dns_server"
            else
                log "ERROR" "Cannot resolve $domain using $dns_server"
                log "DEBUG" "Detailed DNS query for $domain:"
                nslookup "$domain" "$dns_server" 2>&1 | tee -a "${LOG_FILE}"
            fi
        done
    done
    
    # Test 3: Different DNS resolution methods
    log "INFO" "Testing different DNS resolution methods..."
    
    local test_domain="google.com"
    
    # nslookup
    if command -v nslookup >/dev/null; then
        if nslookup "$test_domain" >/dev/null 2>&1; then
            log "OK" "nslookup can resolve $test_domain"
        else
            log "ERROR" "nslookup cannot resolve $test_domain"
        fi
    else
        log "WARN" "nslookup not available"
    fi
    
    # dig
    if command -v dig >/dev/null; then
        if dig "$test_domain" >/dev/null 2>&1; then
            log "OK" "dig can resolve $test_domain"
        else
            log "ERROR" "dig cannot resolve $test_domain"
        fi
    else
        log "WARN" "dig not available"
    fi
    
    # getent
    if command -v getent >/dev/null; then
        if getent hosts "$test_domain" >/dev/null 2>&1; then
            log "OK" "getent can resolve $test_domain"
        else
            log "ERROR" "getent cannot resolve $test_domain"
        fi
    else
        log "WARN" "getent not available"
    fi
}

debug_dns_caching() {
    log "INFO" "Checking DNS caching..."
    
    # Test DNS cache if available
    if command -v systemd-resolve >/dev/null; then
        log "DEBUG" "Checking systemd-resolved cache..."
        systemd-resolve --statistics 2>&1 | tee -a "${LOG_FILE}" || log "WARN" "Cannot access systemd-resolve statistics"
    fi
    
    # Test nscd if available
    if command -v nscd >/dev/null; then
        log "DEBUG" "Checking nscd cache..."
        nscd -g 2>&1 | tee -a "${LOG_FILE}" || log "WARN" "Cannot access nscd statistics"
    fi
    
    # DNS timing test
    log "INFO" "Testing DNS resolution timing..."
    local test_domains=("google.com" "github.com" "stackoverflow.com")
    
    for domain in "${test_domains[@]}"; do
        local start_time=$(date +%s%3N)
        if nslookup "$domain" >/dev/null 2>&1; then
            local end_time=$(date +%s%3N)
            local duration=$((end_time - start_time))
            
            if [ "$duration" -lt 100 ]; then
                log "OK" "$domain resolved in ${duration}ms (fast)"
            elif [ "$duration" -lt 500 ]; then
                log "OK" "$domain resolved in ${duration}ms (normal)"
            else
                log "WARN" "$domain resolved in ${duration}ms (slow)"
            fi
        else
            log "ERROR" "Failed to resolve $domain"
        fi
    done
}

# Run DNS resolution tests
debug_dns_resolution
debug_dns_caching

# =============================================================================
# 3. PORT BINDING CONFLICTS
# =============================================================================
log "INFO" ""
log "INFO" "[3] PORT BINDING CONFLICT ANALYSIS"

debug_port_conflicts() {
    log "DEBUG" "Analyzing port binding conflicts..."
    
    # Test 1: List all listening ports
    log "INFO" "Gathering listening port information..."
    {
        echo "=== Listening Ports (TCP) ==="
        ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null || echo "No port listing tools available"
        echo ""
        
        echo "=== Listening Ports (UDP) ==="
        ss -ulnp 2>/dev/null || netstat -ulnp 2>/dev/null || echo "No port listing tools available"
        echo ""
        
        echo "=== All Active Connections ==="
        ss -tulnp 2>/dev/null | head -20 || netstat -tulnp 2>/dev/null | head -20 || echo "No connection listing tools available"
        echo ""
    } > "${DEBUG_RESULTS_DIR}/port_analysis_${TIMESTAMP}.txt"
    
    log "OK" "Port analysis saved"
    
    # Test 2: Check common development ports
    log "INFO" "Checking common development ports for conflicts..."
    
    local common_ports=(80 443 3000 3001 4000 5000 5173 8000 8080 8443 9000)
    
    for port in "${common_ports[@]}"; do
        local port_info
        port_info=$(ss -tlnp 2>/dev/null | grep ":$port " || netstat -tlnp 2>/dev/null | grep ":$port " || echo "")
        
        if [ -n "$port_info" ]; then
            log "WARN" "Port $port is in use:"
            echo "$port_info" | tee -a "${LOG_FILE}"
        else
            log "OK" "Port $port is available"
        fi
    done
    
    # Test 3: Docker port mapping analysis
    if command -v docker >/dev/null 2>&1; then
        log "INFO" "Analyzing Docker port mappings..."
        
        # List Docker containers with port mappings
        local docker_ports
        docker_ports=$(docker ps --format "table {{.Names}}\t{{.Ports}}" 2>/dev/null || echo "Cannot access Docker")
        
        if [[ "$docker_ports" != "Cannot access Docker" ]]; then
            log "DEBUG" "Docker container port mappings:"
            echo "$docker_ports" | tee -a "${LOG_FILE}"
        else
            log "WARN" "Cannot access Docker information (not running as privileged user?)"
        fi
    else
        log "WARN" "Docker command not available"
    fi
    
    # Test 4: Process analysis for port usage
    log "INFO" "Analyzing processes using network ports..."
    
    if command -v lsof >/dev/null; then
        log "DEBUG" "Network connections by process:"
        lsof -i -P -n 2>/dev/null | head -20 | tee -a "${LOG_FILE}" || log "WARN" "lsof failed"
    else
        log "WARN" "lsof not available for detailed process analysis"
    fi
}

debug_port_accessibility() {
    log "INFO" "Testing port accessibility from container..."
    
    # Test ports that should be accessible from Docker
    local test_configs=(
        "localhost:80:Host web server"
        "localhost:443:Host HTTPS server"
        "host.docker.internal:80:Docker host web server"
        "host.docker.internal:443:Docker host HTTPS server"
        "host.docker.internal:3000:Development server"
        "host.docker.internal:5173:Vite dev server"
    )
    
    for config in "${test_configs[@]}"; do
        IFS=':' read -r host port description <<< "$config"
        
        log "DEBUG" "Testing $description ($host:$port)..."
        
        # Test TCP connection
        if timeout 3 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
            log "OK" "$description is accessible"
            
            # Test HTTP if applicable
            if [[ "$port" =~ ^(80|443|3000|5173|8080)$ ]]; then
                local protocol="http"
                [ "$port" == "443" ] && protocol="https"
                
                local http_test
                http_test=$(curl -s -m 3 -I "$protocol://$host:$port" 2>/dev/null | head -n1 || echo "")
                
                if [[ "$http_test" =~ HTTP ]]; then
                    log "OK" "HTTP service confirmed on $host:$port"
                else
                    log "WARN" "Port accessible but no HTTP response on $host:$port"
                fi
            fi
        else
            log "ERROR" "$description is not accessible ($host:$port)"
        fi
    done
}

# Run port conflict analysis
debug_port_conflicts
debug_port_accessibility

# =============================================================================
# 4. PERMISSION ERRORS
# =============================================================================
log "INFO" ""
log "INFO" "[4] PERMISSION ERROR ANALYSIS"

debug_permissions() {
    log "DEBUG" "Analyzing permission-related issues..."
    
    # Test 1: User and group information
    log "INFO" "Gathering user and group information..."
    {
        echo "=== Current User Information ==="
        id 2>/dev/null || echo "Cannot get user ID information"
        echo ""
        
        echo "=== Groups ==="
        groups 2>/dev/null || echo "Cannot get group information"
        echo ""
        
        echo "=== Sudo Capabilities ==="
        sudo -l 2>/dev/null || echo "No sudo access or sudo not available"
        echo ""
        
        echo "=== Process User ==="
        ps -o user,pid,comm -p $$ 2>/dev/null || echo "Cannot get process information"
        echo ""
    } > "${DEBUG_RESULTS_DIR}/permissions_${TIMESTAMP}.txt"
    
    log "OK" "Permission information saved"
    
    # Test 2: File system permissions
    log "INFO" "Testing file system permissions..."
    
    local test_locations=("/tmp" "/var/tmp" "." "$HOME")
    
    for location in "${test_locations[@]}"; do
        if [ -d "$location" ]; then
            log "DEBUG" "Testing permissions in $location..."
            
            # Test write permissions
            local test_file="$location/permission_test_$$"
            
            if touch "$test_file" 2>/dev/null; then
                log "OK" "Write permission available in $location"
                rm -f "$test_file" 2>/dev/null
            else
                log "ERROR" "No write permission in $location"
            fi
            
            # Test execute permissions
            if [ -x "$location" ]; then
                log "OK" "Execute permission available in $location"
            else
                log "ERROR" "No execute permission in $location"
            fi
        else
            log "WARN" "$location does not exist"
        fi
    done
    
    # Test 3: Network permissions
    log "INFO" "Testing network-related permissions..."
    
    # Test raw socket creation (requires root)
    if ping -c 1 -W 1 127.0.0.1 >/dev/null 2>&1; then
        log "OK" "Can create ICMP sockets (ping works)"
    else
        log "WARN" "Cannot create ICMP sockets (may need privileges)"
    fi
    
    # Test binding to privileged ports
    local privileged_ports=(80 443 22)
    
    for port in "${privileged_ports[@]}"; do
        # Try to bind temporarily (will fail but shows permission status)
        if timeout 1 nc -l "$port" 2>&1 | grep -q "Permission denied"; then
            log "WARN" "No permission to bind to privileged port $port"
        else
            log "OK" "Can attempt to bind to port $port (or port already in use)"
        fi
    done
    
    # Test 4: Docker-specific permissions
    if [ -f /.dockerenv ]; then
        log "INFO" "Testing Docker-specific permissions..."
        
        # Test Docker socket access
        if [ -S /var/run/docker.sock ]; then
            if [ -r /var/run/docker.sock ]; then
                log "OK" "Docker socket is readable"
            else
                log "WARN" "Docker socket exists but not readable"
            fi
        else
            log "INFO" "Docker socket not mounted (normal for most containers)"
        fi
        
        # Test capability analysis
        if command -v capsh >/dev/null; then
            log "DEBUG" "Container capabilities:"
            capsh --print 2>&1 | tee -a "${LOG_FILE}" || log "WARN" "Cannot analyze capabilities"
        else
            log "WARN" "capsh not available for capability analysis"
        fi
    fi
}

debug_security_restrictions() {
    log "INFO" "Analyzing security restrictions..."
    
    # Test SELinux if available
    if command -v getenforce >/dev/null; then
        local selinux_status
        selinux_status=$(getenforce 2>/dev/null || echo "Unknown")
        log "INFO" "SELinux status: $selinux_status"
        
        if [ "$selinux_status" == "Enforcing" ]; then
            log "WARN" "SELinux is enforcing - may cause permission issues"
        fi
    fi
    
    # Test AppArmor if available
    if command -v aa-status >/dev/null; then
        if aa-status >/dev/null 2>&1; then
            log "WARN" "AppArmor is active - may cause permission issues"
        fi
    fi
    
    # Test namespace restrictions
    log "INFO" "Testing namespace restrictions..."
    
    if [ -r /proc/self/ns/net ]; then
        local net_ns
        net_ns=$(readlink /proc/self/ns/net 2>/dev/null || echo "unknown")
        log "DEBUG" "Network namespace: $net_ns"
    fi
    
    if [ -r /proc/self/ns/pid ]; then
        local pid_ns
        pid_ns=$(readlink /proc/self/ns/pid 2>/dev/null || echo "unknown")
        log "DEBUG" "PID namespace: $pid_ns"
    fi
}

# Run permission analysis
debug_permissions
debug_security_restrictions

# =============================================================================
# 5. COMPREHENSIVE DIAGNOSIS AND RECOMMENDATIONS
# =============================================================================
log "INFO" ""
log "INFO" "[5] COMPREHENSIVE DIAGNOSIS AND RECOMMENDATIONS"

generate_diagnosis() {
    log "INFO" "Generating comprehensive diagnosis..."
    
    local issues_found=0
    local recommendations=()
    
    # Analyze collected data
    log "DEBUG" "Analyzing collected diagnostic data..."
    
    # Check network connectivity issues
    if ! ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
        ((issues_found++))
        recommendations+=("CRITICAL: No internet connectivity - check network configuration")
    fi
    
    # Check Docker-specific issues
    if [ -f /.dockerenv ] && ! ping -c 1 -W 3 host.docker.internal >/dev/null 2>&1; then
        ((issues_found++))
        recommendations+=("CRITICAL: host.docker.internal unreachable - check Docker networking")
    fi
    
    # Check DNS resolution issues
    if ! nslookup google.com >/dev/null 2>&1; then
        ((issues_found++))
        recommendations+=("HIGH: DNS resolution failing - check /etc/resolv.conf")
    fi
    
    # Check port accessibility
    local critical_ports_down=0
    for port in 80 443; do
        if ! timeout 3 bash -c "</dev/tcp/host.docker.internal/$port" 2>/dev/null; then
            ((critical_ports_down++))
        fi
    done
    
    if [ $critical_ports_down -gt 0 ]; then
        ((issues_found++))
        recommendations+=("MEDIUM: Some critical ports inaccessible - check host services")
    fi
    
    # Generate diagnosis report
    local diagnosis_file="${DEBUG_RESULTS_DIR}/diagnosis_${TIMESTAMP}.md"
    
    {
        echo "# Network Debugging Diagnosis Report"
        echo "Generated: $(date)"
        echo ""
        echo "## Executive Summary"
        
        if [ $issues_found -eq 0 ]; then
            echo "✅ **Status: HEALTHY** - No critical networking issues detected"
        elif [ $issues_found -lt 3 ]; then
            echo "⚠️ **Status: WARNING** - $issues_found networking issues detected"
        else
            echo "❌ **Status: CRITICAL** - $issues_found networking issues detected"
        fi
        
        echo ""
        echo "## Issues Detected"
        
        if [ $issues_found -eq 0 ]; then
            echo "- No issues detected"
        else
            for recommendation in "${recommendations[@]}"; do
                echo "- $recommendation"
            done
        fi
        
        echo ""
        echo "## Detailed Findings"
        echo ""
        echo "### Network Connectivity"
        
        # Internet connectivity
        if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
            echo "- ✅ Internet connectivity: Working"
        else
            echo "- ❌ Internet connectivity: Failed"
        fi
        
        # Gateway connectivity
        local gateway
        gateway=$(ip route | grep default | awk '{print $3}' | head -n1 2>/dev/null || echo "")
        if [ -n "$gateway" ] && ping -c 1 -W 3 "$gateway" >/dev/null 2>&1; then
            echo "- ✅ Gateway connectivity: Working ($gateway)"
        else
            echo "- ❌ Gateway connectivity: Failed"
        fi
        
        # Docker host connectivity
        if [ -f /.dockerenv ]; then
            if ping -c 1 -W 3 host.docker.internal >/dev/null 2>&1; then
                echo "- ✅ Docker host connectivity: Working"
            else
                echo "- ❌ Docker host connectivity: Failed"
            fi
        fi
        
        echo ""
        echo "### DNS Resolution"
        
        # DNS servers
        if nslookup google.com >/dev/null 2>&1; then
            echo "- ✅ DNS resolution: Working"
        else
            echo "- ❌ DNS resolution: Failed"
        fi
        
        # DNS configuration
        local dns_servers
        dns_servers=$(grep -E "^nameserver" /etc/resolv.conf 2>/dev/null | wc -l || echo "0")
        echo "- DNS servers configured: $dns_servers"
        
        echo ""
        echo "### Port Accessibility"
        
        # Test key ports
        local test_ports=(80 443 3000 5173 8080)
        for port in "${test_ports[@]}"; do
            if timeout 3 bash -c "</dev/tcp/host.docker.internal/$port" 2>/dev/null; then
                echo "- ✅ Port $port: Accessible"
            else
                echo "- ❌ Port $port: Not accessible"
            fi
        done
        
        echo ""
        echo "## Troubleshooting Steps"
        echo ""
        
        if [ $issues_found -gt 0 ]; then
            echo "### Immediate Actions"
            echo "1. Review the detailed logs in: $LOG_FILE"
            echo "2. Check Docker container networking configuration"
            echo "3. Verify host services are running"
            echo "4. Test connectivity from host system"
            echo ""
            echo "### Advanced Debugging"
            echo "1. Review network interface configuration: \`ip addr show\`"
            echo "2. Check routing table: \`ip route\`"
            echo "3. Verify DNS configuration: \`cat /etc/resolv.conf\`"
            echo "4. Test specific services: \`curl -v http://host.docker.internal\`"
        else
            echo "No immediate actions required. Network configuration appears healthy."
        fi
        
        echo ""
        echo "## Files Generated"
        echo "- Network info: network_info_${TIMESTAMP}.txt"
        echo "- DNS config: dns_config_${TIMESTAMP}.txt"
        echo "- Port analysis: port_analysis_${TIMESTAMP}.txt"
        echo "- Permissions: permissions_${TIMESTAMP}.txt"
        echo "- Debug log: debug_${TIMESTAMP}.log"
        echo "- This report: diagnosis_${TIMESTAMP}.md"
        
    } > "$diagnosis_file"
    
    log "OK" "Diagnosis report generated: $diagnosis_file"
    
    # Display summary
    log "INFO" ""
    log "INFO" "=== DIAGNOSIS SUMMARY ==="
    
    if [ $issues_found -eq 0 ]; then
        log "OK" "✅ Network configuration appears healthy"
        log "OK" "No critical issues detected"
    else
        log "ERROR" "❌ $issues_found networking issues detected"
        log "ERROR" "Review diagnosis report for details: $diagnosis_file"
        
        for recommendation in "${recommendations[@]}"; do
            log "WARN" "$recommendation"
        done
    fi
}

# Run comprehensive diagnosis
generate_diagnosis

# =============================================================================
# 6. AUTOMATED FIXING SUGGESTIONS
# =============================================================================
log "INFO" ""
log "INFO" "[6] AUTOMATED FIXING SUGGESTIONS"

generate_fix_scripts() {
    log "INFO" "Generating automated fix scripts..."
    
    # Create fix script for common issues
    local fix_script="${DEBUG_RESULTS_DIR}/auto_fix_${TIMESTAMP}.sh"
    
    {
        echo "#!/bin/bash"
        echo "# Automated fix script generated by network debugging"
        echo "# Generated: $(date)"
        echo ""
        echo "set -euo pipefail"
        echo ""
        echo "echo 'Starting automated network fixes...'"
        echo ""
        
        # DNS fix
        echo "# Fix 1: Reset DNS configuration"
        echo "fix_dns() {"
        echo "    echo 'Fixing DNS configuration...'"
        echo "    # Add Google DNS as fallback"
        echo "    if ! grep -q '8.8.8.8' /etc/resolv.conf 2>/dev/null; then"
        echo "        echo 'nameserver 8.8.8.8' >> /etc/resolv.conf"
        echo "    fi"
        echo "    echo 'DNS fix applied'"
        echo "}"
        echo ""
        
        # Network interface fix
        echo "# Fix 2: Reset network interfaces"
        echo "fix_network() {"
        echo "    echo 'Checking network interfaces...'"
        echo "    ip addr show"
        echo "    echo 'Network interface check complete'"
        echo "}"
        echo ""
        
        # Port accessibility fix
        echo "# Fix 3: Test port accessibility"
        echo "fix_ports() {"
        echo "    echo 'Testing port accessibility...'"
        echo "    local ports=(80 443 3000 5173)"
        echo "    for port in \"\${ports[@]}\"; do"
        echo "        if timeout 3 bash -c \"</dev/tcp/host.docker.internal/\$port\" 2>/dev/null; then"
        echo "            echo \"Port \$port: OK\""
        echo "        else"
        echo "            echo \"Port \$port: FAILED\""
        echo "        fi"
        echo "    done"
        echo "}"
        echo ""
        
        # Main execution
        echo "# Main execution"
        echo "echo 'Running network fixes...'"
        echo "fix_dns"
        echo "fix_network"  
        echo "fix_ports"
        echo "echo 'Network fixes completed'"
        
    } > "$fix_script"
    
    chmod +x "$fix_script"
    log "OK" "Fix script generated: $fix_script"
    
    # Create validation script
    local validate_script="${DEBUG_RESULTS_DIR}/validate_fixes_${TIMESTAMP}.sh"
    
    {
        echo "#!/bin/bash"
        echo "# Validation script to test fixes"
        echo ""
        echo "validate_network() {"
        echo "    echo 'Validating network fixes...'"
        echo "    "
        echo "    # Test internet connectivity"
        echo "    if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then"
        echo "        echo '✅ Internet connectivity: OK'"
        echo "    else"
        echo "        echo '❌ Internet connectivity: FAILED'"
        echo "    fi"
        echo "    "
        echo "    # Test DNS resolution"
        echo "    if nslookup google.com >/dev/null 2>&1; then"
        echo "        echo '✅ DNS resolution: OK'"
        echo "    else"
        echo "        echo '❌ DNS resolution: FAILED'"
        echo "    fi"
        echo "    "
        echo "    # Test Docker host"
        echo "    if ping -c 1 -W 3 host.docker.internal >/dev/null 2>&1; then"
        echo "        echo '✅ Docker host: OK'"
        echo "    else"
        echo "        echo '❌ Docker host: FAILED'"
        echo "    fi"
        echo "}"
        echo ""
        echo "validate_network"
        
    } > "$validate_script"
    
    chmod +x "$validate_script"
    log "OK" "Validation script generated: $validate_script"
}

generate_fix_scripts

# =============================================================================
# FINAL SUMMARY AND NEXT STEPS
# =============================================================================
log "INFO" ""
log "INFO" "=== DEBUG SESSION COMPLETE ==="

# Display final summary
log "OK" "Network debugging session completed successfully"
log "INFO" "Generated files:"
log "INFO" "  📊 Main debug log: $LOG_FILE"
log "INFO" "  📋 Diagnosis report: diagnosis_${TIMESTAMP}.md"
log "INFO" "  🔧 Auto-fix script: auto_fix_${TIMESTAMP}.sh"
log "INFO" "  ✅ Validation script: validate_fixes_${TIMESTAMP}.sh"
log "INFO" "  📁 All files in: $DEBUG_RESULTS_DIR"

log "INFO" ""
log "INFO" "Next steps:"
log "INFO" "1. Review the diagnosis report for detailed findings"
log "INFO" "2. Run auto-fix script if issues were detected"
log "INFO" "3. Use validation script to confirm fixes"
log "INFO" "4. Re-run this debug script to verify resolution"

log "INFO" ""
log "INFO" "Debug session completed at: $(date)"

# Return appropriate exit code
if grep -q "CRITICAL" "${DEBUG_RESULTS_DIR}/diagnosis_${TIMESTAMP}.md" 2>/dev/null; then
    exit 2
elif grep -q "WARNING" "${DEBUG_RESULTS_DIR}/diagnosis_${TIMESTAMP}.md" 2>/dev/null; then
    exit 1
else
    exit 0
fi