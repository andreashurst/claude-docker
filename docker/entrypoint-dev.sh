#!/bin/bash
set -e

echo 'Claude Dev Environment Starting...'
echo '================================='
echo 'Node.js version:' && node --version
echo 'NPM version:' && npm --version
echo 'Claude Code version:' && claude --version
echo ''

echo 'Network Configuration:'
echo '====================='
echo 'Host Gateway: host.docker.internal'
ping -c 1 host.docker.internal > /dev/null 2>&1 && echo '✓ Host connection: OK' || echo '✗ Host connection: FAILED'
echo 'DNS Servers: 8.8.8.8, 1.1.1.1'
echo ''

echo 'Host Services Configuration:'
echo "- Configured Frontend: http://${FRONTEND_URL:-localhost:3000}"
echo '- Common Alternatives:'
echo '  - React/Next.js: http://host.docker.internal:3000'
echo '  - Vite Dev:      http://host.docker.internal:5173'
echo '  - Angular:       http://host.docker.internal:4200'
echo '- Backend:         http://host.docker.internal:8000'
echo '- Database:        host.docker.internal:5432'
echo ''

echo 'Testing Host Connectivity:'
echo '  ping host.docker.internal'
echo "  test-port ${FRONTEND_PORT:-3000}"
echo "  curl -I http://${FRONTEND_URL:-host.docker.internal:3000}"
echo ''

echo '✓ Claude Dev Environment ready!'
echo ''

# Keep container running
exec tail -f /dev/null