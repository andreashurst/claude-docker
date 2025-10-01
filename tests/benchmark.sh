#!/bin/bash
#
# Performance Benchmarking for Claude Docker
# Tests startup time, build time, and runtime performance
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "════════════════════════════════════════════════════════"
echo "  ⚡ Claude Docker Performance Benchmark"
echo "════════════════════════════════════════════════════════"
echo ""

# Benchmark 1: Container Startup Time
echo -e "${CYAN}[1/5] Container Startup Time${NC}"
echo "Testing how fast containers start..."
echo ""

benchmark_startup() {
    local container_name=$1
    local image_name=$2
    
    # Stop if running
    docker stop $container_name 2>/dev/null || true
    docker rm $container_name 2>/dev/null || true
    
    # Measure startup
    local start=$(date +%s%N)
    docker run -d --name $container_name $image_name sleep 3600 >/dev/null
    docker exec $container_name echo "ready" >/dev/null 2>&1
    local end=$(date +%s%N)
    
    local duration=$(( (end - start) / 1000000 ))
    echo -e "  ${container_name}: ${GREEN}${duration}ms${NC}"
    
    # Cleanup
    docker stop $container_name >/dev/null 2>&1
    docker rm $container_name >/dev/null 2>&1
    
    echo $duration
}

DEV_STARTUP=$(benchmark_startup "bench-dev" "andreashurst/claude-docker:latest-dev")
FLOW_STARTUP=$(benchmark_startup "bench-flow" "andreashurst/claude-docker:latest-flow")

echo ""

# Benchmark 2: Command Execution Speed
echo -e "${CYAN}[2/5] Command Execution Speed${NC}"
echo "Testing command execution times..."
echo ""

benchmark_command() {
    local image=$1
    local command=$2
    local name=$3
    
    local start=$(date +%s%N)
    docker run --rm $image bash -c "$command" >/dev/null 2>&1
    local end=$(date +%s%N)
    
    local duration=$(( (end - start) / 1000000 ))
    echo -e "  $name: ${GREEN}${duration}ms${NC}"
    
    echo $duration
}

NODE_TIME=$(benchmark_command "andreashurst/claude-docker:latest-dev" "node --version" "node --version")
PHP_TIME=$(benchmark_command "andreashurst/claude-docker:latest-dev" "php --version" "php --version")
PYTHON_TIME=$(benchmark_command "andreashurst/claude-docker:latest-dev" "python3 --version" "python3 --version")

echo ""

# Benchmark 3: MCP Server Load Time
echo -e "${CYAN}[3/5] MCP Server Initialization${NC}"
echo "Testing MCP server load times..."
echo ""

MCP_START=$(date +%s%N)
docker run --rm -v $(pwd):/var/www/html andreashurst/claude-docker:latest-dev \
    bash -c "test -f /home/claude/mcp/config.json && cat /home/claude/mcp/config.json | jq '.mcpServers | length'" >/dev/null 2>&1
MCP_END=$(date +%s%N)
MCP_TIME=$(( (MCP_END - MCP_START) / 1000000 ))

echo -e "  MCP config load: ${GREEN}${MCP_TIME}ms${NC}"
echo ""

# Benchmark 4: Image Size
echo -e "${CYAN}[4/5] Docker Image Size${NC}"
echo "Checking image sizes..."
echo ""

get_image_size() {
    local image=$1
    docker images $image --format "{{.Size}}" 2>/dev/null || echo "N/A"
}

DEV_SIZE=$(get_image_size "andreashurst/claude-docker:latest-dev")
FLOW_SIZE=$(get_image_size "andreashurst/claude-docker:latest-flow")

echo -e "  claude-docker:latest-dev:  ${YELLOW}${DEV_SIZE}${NC}"
echo -e "  claude-docker:latest-flow: ${YELLOW}${FLOW_SIZE}${NC}"
echo ""

# Benchmark 5: Layer Count
echo -e "${CYAN}[5/5] Docker Layer Analysis${NC}"
echo "Analyzing image layers..."
echo ""

get_layer_count() {
    local image=$1
    docker history $image 2>/dev/null | wc -l
}

DEV_LAYERS=$(get_layer_count "andreashurst/claude-docker:latest-dev")
FLOW_LAYERS=$(get_layer_count "andreashurst/claude-docker:latest-flow")

echo -e "  claude-docker:latest-dev:  ${YELLOW}${DEV_LAYERS} layers${NC}"
echo -e "  claude-docker:latest-flow: ${YELLOW}${FLOW_LAYERS} layers${NC}"
echo ""

# Summary Report
echo "════════════════════════════════════════════════════════"
echo "  📊 Benchmark Summary"
echo "════════════════════════════════════════════════════════"
echo ""
echo -e "${BLUE}Container Startup:${NC}"
echo "  dev:  ${DEV_STARTUP}ms"
echo "  flow: ${FLOW_STARTUP}ms"
echo ""
echo -e "${BLUE}Command Execution:${NC}"
echo "  node:   ${NODE_TIME}ms"
echo "  php:    ${PHP_TIME}ms"
echo "  python: ${PYTHON_TIME}ms"
echo ""
echo -e "${BLUE}MCP Loading:${NC}"
echo "  config: ${MCP_TIME}ms"
echo ""
echo -e "${BLUE}Image Sizes:${NC}"
echo "  dev:  ${DEV_SIZE}"
echo "  flow: ${FLOW_SIZE}"
echo ""
echo -e "${BLUE}Layer Counts:${NC}"
echo "  dev:  ${DEV_LAYERS}"
echo "  flow: ${FLOW_LAYERS}"
echo ""

# Performance Rating
echo "════════════════════════════════════════════════════════"
echo "  🎯 Performance Rating"
echo "════════════════════════════════════════════════════════"
echo ""

rate_performance() {
    local value=$1
    local threshold_good=$2
    local threshold_ok=$3
    
    if [ $value -lt $threshold_good ]; then
        echo -e "${GREEN}⭐⭐⭐ Excellent${NC}"
    elif [ $value -lt $threshold_ok ]; then
        echo -e "${YELLOW}⭐⭐ Good${NC}"
    else
        echo -e "${RED}⭐ Needs Improvement${NC}"
    fi
}

echo -n "  Startup Speed: "
rate_performance $DEV_STARTUP 2000 5000

echo -n "  Command Speed: "
rate_performance $NODE_TIME 1000 3000

echo -n "  MCP Loading:   "
rate_performance $MCP_TIME 1000 3000

echo ""
echo "════════════════════════════════════════════════════════"
echo ""

# Generate JSON report
REPORT_FILE="benchmark-report.json"
cat > $REPORT_FILE << JSON_EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "version": "$(docker run --rm andreashurst/claude-docker:latest-dev cat /docker/version.txt 2>/dev/null || echo 'unknown')",
  "results": {
    "startup": {
      "dev_ms": $DEV_STARTUP,
      "flow_ms": $FLOW_STARTUP
    },
    "commands": {
      "node_ms": $NODE_TIME,
      "php_ms": $PHP_TIME,
      "python_ms": $PYTHON_TIME
    },
    "mcp": {
      "load_ms": $MCP_TIME
    },
    "images": {
      "dev_size": "$DEV_SIZE",
      "flow_size": "$FLOW_SIZE",
      "dev_layers": $DEV_LAYERS,
      "flow_layers": $FLOW_LAYERS
    }
  }
}
JSON_EOF

echo -e "${GREEN}✅ Benchmark complete!${NC}"
echo -e "Report saved to: ${CYAN}$REPORT_FILE${NC}"
echo ""
