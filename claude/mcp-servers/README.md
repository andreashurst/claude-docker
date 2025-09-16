# MCP Webserver Environment Monitor

## Overview
The `webserver-env` MCP server provides **read-only** access to monitor and check the external webserver running outside the Docker container. This server is designed to:

- **Never modify** the external webserver
- **Never clear caches** or restart services
- **Only monitor** status and connectivity
- Provide helpful diagnostics for debugging connectivity issues

## Available Tools

### 1. `check_webserver_status`
Checks if the external webserver is responding.

**Parameters:**
- `url` (string): URL to check (default: `http://localhost`)
- `timeout` (number): Timeout in seconds (default: 5)

**Example:**
```javascript
{
  "tool": "check_webserver_status",
  "arguments": {
    "url": "http://localhost:8080",
    "timeout": 3
  }
}
```

### 2. `get_webserver_headers`
Retrieves HTTP headers from the webserver without fetching the body.

**Parameters:**
- `url` (string): URL to check (default: `http://localhost`)

### 3. `check_webserver_endpoints`
Tests multiple endpoints on the webserver.

**Parameters:**
- `endpoints` (array): List of endpoints to check (default: `['/']`)
- `base_url` (string): Base URL (default: `http://localhost`)

**Example:**
```javascript
{
  "tool": "check_webserver_endpoints",
  "arguments": {
    "endpoints": ["/", "/api", "/health"],
    "base_url": "http://localhost:3000"
  }
}
```

### 4. `get_docker_webserver_info`
Gets information about Docker webserver container if running.

**Parameters:**
- `container_name` (string): Container name pattern (default: `webserver`)

### 5. `test_webserver_connectivity`
Tests connectivity from inside the container to various host configurations.

**Parameters:**
- `hosts` (array): Hosts to test (default: `['localhost', 'webserver', 'host.docker.internal']`)

## Configuration

The MCP server is configured in `/etc/claude/mcp.json`:

```json
{
  "webserver-env": {
    "command": "node",
    "args": ["/var/www/html/claude/mcp-servers/webserver-env.js"],
    "description": "External webserver environment monitoring (read-only, no cache clearing)"
  }
}
```

## Host Mapping

The Docker containers are configured to map various hostnames to the external webserver:

- `localhost` → Mapped to host machine via /etc/hosts
- `webserver` → Docker service name (if using docker-compose)
- `host.docker.internal` → Docker's built-in host access (macOS/Windows)
- `host-gateway` → Docker's host gateway (Linux)

## Usage in Claude

When Claude CLI is running with MCP configured, you can use these tools to:

1. **Check if webserver is running:**
   - Use `check_webserver_status` to verify the webserver is accessible

2. **Debug connectivity issues:**
   - Use `test_webserver_connectivity` to test different host configurations
   - Check which hostname works from inside the container

3. **Monitor endpoints:**
   - Use `check_webserver_endpoints` to verify multiple routes are working
   - Useful for health checks and API monitoring

4. **Inspect configuration:**
   - Use `get_webserver_headers` to see server configuration
   - Check for security headers, caching policies, etc.

## Safety Features

This MCP server is designed with safety in mind:

- ✅ **Read-only operations** - Never modifies the webserver
- ✅ **No cache clearing** - Doesn't interfere with webserver caching
- ✅ **No service restarts** - Never attempts to restart or reload services
- ✅ **Timeout protection** - All requests have configurable timeouts
- ✅ **Error handling** - Gracefully handles connection failures

## Troubleshooting

If the webserver isn't accessible:

1. Check if it's running on the host machine
2. Verify the port mapping in docker-compose.yml
3. Use `test_webserver_connectivity` to find working hostname
4. Check firewall rules on the host machine
5. Ensure the webserver is listening on all interfaces (0.0.0.0) not just localhost

## Notes

- This server runs inside the Docker container but monitors the external webserver
- It respects the container's network isolation while providing useful diagnostics
- All operations are designed to be non-intrusive and safe for production environments