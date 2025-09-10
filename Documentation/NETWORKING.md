# Docker Networking Guide

## Overview
This guide explains networking in the Docker environment and how to connect to services running on your host machine.

## Quick Reference

### From Docker Container → Host Services

| Host Service | Use This URL |
|-------------|--------------|
| `localhost:3000` | `http://host.docker.internal:3000` |
| `127.0.0.1:5173` | `http://host.docker.internal:5173` |
| `localhost:8080` | `http://host.docker.internal:8080` |

## Environment Detection

Use the detection script to identify your environment:
```bash
/test/bin/detect-environment
# Output: Docker, DDEV, or Local
```

## Using the curl Wrapper

The curl wrapper automatically rewrites URLs for Docker environments:

```bash
# Instead of:
curl http://localhost:3000

# Just use:
/test/bin/curl http://localhost:3000
# Automatically becomes: http://host.docker.internal:3000
```

## Common Development Ports

### Vite/Frontend
- **5173** - Vite default port
- **3000** - Alternative dev server
- **4173** - Vite preview port

### Backend Services
- **8080** - Common API server port
- **3306** - MySQL
- **5432** - PostgreSQL
- **6379** - Redis
- **27017** - MongoDB

## Testing Connectivity

### Quick Test
```bash
# Test if host is reachable
curl -I http://host.docker.internal

# Test specific port
curl -I http://host.docker.internal:3000
```

### Using the curl Wrapper
```bash
# Automatically handles URL rewriting
/test/bin/curl http://localhost:5173
```

## Troubleshooting

### Connection Refused
If you get "Connection refused", check:
1. Is the service running on the host?
2. Is it bound to `0.0.0.0` not just `127.0.0.1`?
3. Is the port exposed through any firewall?

### Vite Dev Server
For Vite, ensure your `vite.config.js` has:
```javascript
server: {
  host: '0.0.0.0',  // Listen on all interfaces
  port: 5173,
  strictPort: true
}
```

### DDEV Projects
If using DDEV, the curl wrapper will automatically detect and use your DDEV domain:
- Detects from `.ddev/config.yaml`
- Rewrites `localhost` → `yourproject.ddev.site`

## Direct Commands

Remember, you can always use curl directly:
```bash
# Direct curl (no URL rewriting)
curl http://host.docker.internal:3000

# With wrapper (automatic rewriting)
/test/bin/curl http://localhost:3000
```

## Environment Variables

The container sets:
- `DOCKER_CONTAINER=true`
- `DOCKER_ENV=true`

You can check these in your scripts:
```bash
if [ -n "$DOCKER_CONTAINER" ]; then
  echo "Running in Docker"
fi
```

---
*Last updated: 2025-08-30*