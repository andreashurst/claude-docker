# Networking & Host Access

## Quick Reference

Access services on your host machine from inside the container:

```bash
# Test connectivity
test-port 3000

# Access services
curl http://host.docker.internal:3000
psql -h host.docker.internal -p 5432
```

## How It Works

Docker provides `host.docker.internal` as a special DNS name that resolves to your host machine.

```
Container → host.docker.internal → Host Machine
```

## Common Services

### Frontend Dev Servers

| Service | Default Port | Access URL |
|---------|-------------|------------|
| React/Next.js | 3000 | `http://host.docker.internal:3000` |
| Vite | 5173 | `http://host.docker.internal:5173` |
| Angular | 4200 | `http://host.docker.internal:4200` |
| Vue/webpack | 8080 | `http://host.docker.internal:8080` |

### Backend APIs

| Service | Default Port | Access URL |
|---------|-------------|------------|
| Express/Node | 3000/8000 | `http://host.docker.internal:8000` |
| Django/FastAPI | 8000 | `http://host.docker.internal:8000` |
| Flask | 5000 | `http://host.docker.internal:5000` |
| Rails | 3000 | `http://host.docker.internal:3000` |

### Databases

```bash
# PostgreSQL
psql -h host.docker.internal -p 5432 -U username dbname

# MySQL
mysql -h host.docker.internal -P 3306 -u username -p

# MongoDB
mongosh mongodb://host.docker.internal:27017/dbname

# Redis
redis-cli -h host.docker.internal -p 6379
```

## Testing Connectivity

### Quick Tests

```bash
# Test specific port
test-port 3000

# Test common ports
test-host-connectivity

# Manual test
nc -zv host.docker.internal 3000
curl -I http://host.docker.internal:3000
```

### Debugging

```bash
# Check what's listening on host
# Run on host machine:
lsof -i :3000           # Mac/Linux
netstat -an | grep 3000 # Windows

# Inside container:
ping host.docker.internal
nslookup host.docker.internal
```

## Configuration

### Docker Compose

The containers are configured with:

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

This ensures compatibility across all platforms (Mac, Windows, Linux).

### Service Binding

⚠️ **Important**: Services on your host must bind to `0.0.0.0` or your network interface, not just `127.0.0.1`.

```javascript
// ❌ Won't work from Docker
server.listen(3000, '127.0.0.1');

// ✅ Accessible from Docker
server.listen(3000, '0.0.0.0');
// or
server.listen(3000); // Usually defaults to 0.0.0.0
```

## DDEV Integration

DDEV projects have their own networking with automatic domain detection:

```bash
# DDEV domains (auto-detected from config.yaml)
https://myproject.ddev.site       # Default TLD
https://myproject.ddev.local      # Custom project_tld
https://custom.domain.test        # additional_fqdns

# With Vite dev server
https://myproject.ddev.site:5173  # Port automatically appended
```

The `screenshot` command automatically:
- Detects DDEV environment
- Reads `.ddev/config.yaml` for custom TLDs
- Uses environment variables (DDEV_HOSTNAME, DDEV_PRIMARY_URL)
- Handles `project_tld` and `additional_fqdns` settings

## Security Notes

- Services exposed on `0.0.0.0` are accessible from your local network
- Use firewall rules if needed
- Consider using authentication for sensitive services
- In production, use proper service discovery instead

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Connection refused | Service not running | Start the service on host |
| Connection refused | Bound to localhost only | Bind to `0.0.0.0` instead |
| Timeout | Firewall blocking | Check firewall rules |
| Can't resolve host.docker.internal | Old Docker version | Update Docker Desktop |

## Platform-Specific Notes

### macOS & Windows
- `host.docker.internal` works out of the box
- Provided by Docker Desktop

### Linux
- Requires Docker 20.10+ 
- Add `--add-host=host.docker.internal:host-gateway` to docker run
- Our scripts handle this automatically