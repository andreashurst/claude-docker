# Docker Host Networking Guide

## Was ist host.docker.internal?

`host.docker.internal` ist ein spezieller DNS-Name, der Docker-Containern ermöglicht, auf Services zuzugreifen, die auf dem Host-System laufen.

## Funktionsweise

### In unserer Konfiguration:
```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

- **host.docker.internal** → Zeigt auf die Host-IP-Adresse
- **host-gateway** → Automatische Docker-Gateway-IP

## Praktische Verwendung

### Frontend-Services erreichen:

```bash
# React Dev Server (Standard: Port 3000)
curl http://host.docker.internal:3000

# Vite Dev Server (Standard: Port 5173)  
curl http://host.docker.internal:5173

# Next.js Dev Server (Standard: Port 3000)
curl http://host.docker.internal:3000

# Angular Dev Server (Standard: Port 4200)
curl http://host.docker.internal:4200
```

### Backend-APIs erreichen:

```bash
# Express/Node.js API
curl http://host.docker.internal:8000/api

# Django Development Server
curl http://host.docker.internal:8000

# Flask Development Server
curl http://host.docker.internal:5000

# Rails Development Server
curl http://host.docker.internal:3000
```

### Datenbanken erreichen:

```bash
# PostgreSQL (Standard: Port 5432)
psql -h host.docker.internal -p 5432 -U username dbname

# MySQL (Standard: Port 3306)
mysql -h host.docker.internal -P 3306 -u username -p

# MongoDB (Standard: Port 27017)
mongo mongodb://host.docker.internal:27017/dbname

# Redis (Standard: Port 6379)
redis-cli -h host.docker.internal -p 6379
```

## Testing Commands

### Network Connectivity Tests:

```bash
# Test Host Gateway Connection
ping host.docker.internal

# Test Specific Port
nc -zv host.docker.internal 3000

# Test HTTP Services
curl -I http://host.docker.internal:3000

# Test Multiple Ports
for port in 3000 5173 8000 5000; do
  echo "Testing port $port..."
  timeout 3 bash -c "</dev/tcp/host.docker.internal/$port" && echo "Port $port: OPEN" || echo "Port $port: CLOSED"
done
```

### Service Discovery:

```bash
# Show all listening ports on host
ss -tulpn | grep LISTEN

# Check specific service
curl -s http://host.docker.internal:3000 | head -n 10
```

## Common Host Services

### Development Servers:

| Service | Default Port | URL |
|---------|--------------|-----|
| React/CRA | 3000 | `http://host.docker.internal:3000` |
| Vite | 5173 | `http://host.docker.internal:5173` |
| Webpack Dev Server | 8080 | `http://host.docker.internal:8080` |
| Next.js | 3000 | `http://host.docker.internal:3000` |
| Angular | 4200 | `http://host.docker.internal:4200` |
| Vue CLI | 8080 | `http://host.docker.internal:8080` |

### Backend Services:

| Service | Default Port | Connection |
|---------|--------------|------------|
| Express.js | 3000/8000 | `http://host.docker.internal:PORT` |
| Django | 8000 | `http://host.docker.internal:8000` |
| Flask | 5000 | `http://host.docker.internal:5000` |
| Rails | 3000 | `http://host.docker.internal:3000` |
| FastAPI | 8000 | `http://host.docker.internal:8000` |

### Databases:

| Service | Default Port | Connection String |
|---------|--------------|-------------------|
| PostgreSQL | 5432 | `postgresql://user:pass@host.docker.internal:5432/db` |
| MySQL | 3306 | `mysql://user:pass@host.docker.internal:3306/db` |
| MongoDB | 27017 | `mongodb://host.docker.internal:27017/db` |
| Redis | 6379 | `redis://host.docker.internal:6379` |
| Elasticsearch | 9200 | `http://host.docker.internal:9200` |

## Troubleshooting

### Common Issues:

1. **Connection Refused:**
   ```bash
   # Check if service is running on host
   sudo lsof -i :3000
   
   # Check if port is bound to localhost only
   netstat -tulpn | grep :3000
   ```

2. **Service bound to localhost (127.0.0.1):**
   ```bash
   # Start service on all interfaces instead
   # Instead of: localhost:3000
   # Use: 0.0.0.0:3000
   ```

3. **Firewall Issues:**
   ```bash
   # Check if firewall blocks the port
   sudo ufw status
   
   # Allow port if needed
   sudo ufw allow 3000
   ```

### Network Debugging:

```bash
# Show container network configuration
ip addr show
ip route show

# Show DNS resolution
nslookup host.docker.internal
dig host.docker.internal

# Test with different protocols
telnet host.docker.internal 3000
nc -v host.docker.internal 3000
```

## Security Considerations

### Port Exposure:
- Services auf host.docker.internal sind vom Container aus erreichbar
- Keine automatische Firewall-Regel
- Sensitive Services sollten authentifiziert sein

### Best Practices:
- Verwende spezifische Ports statt Wildcard (0.0.0.0)
- Implementiere proper Authentication für APIs
- Verwende HTTPS in Production
- Begrenze Zugriff auf notwendige Services

## Dynamic Configuration

### MCP Configuration
The container automatically generates a dynamic MCP configuration:

- **Frontend URL**: Automatically detected based on project type (DDEV projects) or defaults to localhost:3000
- **Project Path**: Always uses current working directory (PWD) for consistency
- **Port Extraction**: Automatically extracts port from the detected frontend URL

**Important**: The scripts always use the current directory as project path to ensure consistency between container names and Docker volume mounts.

### Template System
```json
{
  "configuredFrontendUrl": "{{FRONTEND_URL}}",
  "projectPath": "{{PROJECT_PATH}}",
  "frontendPort": "{{FRONTEND_PORT}}"
}
```

These placeholders are replaced with your actual values when the container starts.

## Examples for Claude Code

### Web Scraping mit Playwright:
```javascript
// Use your configured frontend URL
await page.goto('http://YOUR_CONFIGURED_FRONTEND_URL');

// Or access the environment info via MCP
const frontendUrl = environmentInfo.hostNetworking.configuredFrontendUrl;
await page.goto(`http://${frontendUrl}`);
```

### API Testing:
```javascript
// Test your configured frontend
const response = await fetch(`http://${process.env.FRONTEND_URL || 'host.docker.internal:3000'}`);

// Test backend services
const apiResponse = await fetch('http://host.docker.internal:8000/api/users');
```

### Database Connections:
```javascript
// Connect to host database
const db = new Client({
  host: 'host.docker.internal',
  port: 5432,
  database: 'myapp',
  user: 'developer',
  password: 'secret'
});
```

### Dynamic Port Testing:
```javascript
// Test your specific frontend port
const frontendPort = process.env.FRONTEND_PORT || '3000';
const response = await fetch(`http://host.docker.internal:${frontendPort}`);
```