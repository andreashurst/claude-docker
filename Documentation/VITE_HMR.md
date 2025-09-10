# Vite HMR Configuration for Docker

## Quick Answer: Yes, HMR works with different ports!

HMR (Hot Module Replacement) can work with different ports in Docker environments. Here's how to configure it properly:

## Standard Configuration (Port 3000)

```typescript
// vite.config.ts
server: {
  host: '0.0.0.0',        // Listen on all interfaces
  port: 3000,
  strictPort: true,
  hmr: {
    port: 3000,           // HMR on same port
    host: 'localhost',    // Client connects to localhost
  },
}
```

## Using Different Ports (e.g., 5173)

```typescript
// vite.config.ts
server: {
  host: '0.0.0.0',
  port: 5173,
  strictPort: true,
  hmr: {
    port: 5173,           // Match the server port
    host: 'localhost',
  },
}
```

## Separate HMR Port

If you need HMR on a different port (useful for proxies):

```typescript
// vite.config.ts
server: {
  host: '0.0.0.0',
  port: 3000,
  strictPort: true,
  hmr: {
    port: 24678,          // Different port for WebSocket
    host: 'localhost',
  },
}
```

## Docker-Specific Settings

For reliable HMR in Docker containers:

```typescript
// vite.config.ts
server: {
  host: '0.0.0.0',        // REQUIRED: Bind to all interfaces
  port: 5173,
  strictPort: true,
  hmr: {
    port: 5173,
    host: 'localhost',    // Browser connects to localhost
    protocol: 'ws',       // WebSocket protocol
  },
  watch: {
    usePolling: true,     // REQUIRED: For Docker file watching
    interval: 1000,       // Check every second
  },
}
```

## DDEV Configuration

For DDEV environments with custom domains:

```typescript
// vite.config.ts
server: {
  host: '0.0.0.0',
  port: 5173,
  strictPort: true,
  origin: 'https://myproject.ddev.site:5173',
  hmr: {
    port: 5173,
    host: 'myproject.ddev.site',
    protocol: 'wss',      // Secure WebSocket for HTTPS
  },
}
```

## Troubleshooting HMR

### Check HMR Connection
```bash
# From Docker container
nc -zv host.docker.internal 3000  # Main server
nc -zv host.docker.internal 24678 # HMR port (if different)
```

### Common Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| HMR not connecting | Wrong host binding | Use `host: '0.0.0.0'` in server config |
| Changes not detected | Docker file system | Add `usePolling: true` to watch config |
| WebSocket errors | Port mismatch | Ensure HMR port matches server port |
| Connection refused | Firewall/proxy | Check Docker port mapping |

### Testing HMR

1. Start Vite on host:
```bash
npm run dev
```

2. Check from Docker container:
```bash
# Test main server
curl http://host.docker.internal:5173

# Watch console for HMR messages
[vite] connected.
[vite] hot updated: /src/App.tsx
```

## Port Summary

- **3000**: Common dev server port (React, Next.js)
- **5173**: Vite default port
- **24678**: Common HMR WebSocket port
- **4173**: Vite preview port

All these ports support HMR when properly configured!

## Example: Multiple Vite Instances

Running multiple Vite dev servers with different ports:

```typescript
// App 1: vite.config.ts
server: {
  host: '0.0.0.0',
  port: 3000,
  hmr: { port: 3000 }
}

// App 2: vite.config.ts
server: {
  host: '0.0.0.0',
  port: 3001,
  hmr: { port: 3001 }
}

// App 3: vite.config.ts
server: {
  host: '0.0.0.0',
  port: 5173,
  hmr: { port: 5173 }
}
```

Each instance maintains its own HMR connection on its respective port.