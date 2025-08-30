#!/usr/bin/env node
// Simple HTTP/WebSocket proxy for Vite HMR in Docker
// No external dependencies required
// Part of claude-docker: https://github.com/andreashurst/claude-docker

const http = require('http');
const net = require('net');
const { URL } = require('url');

const PORT = process.argv[2] || 3000;
const TARGET_HOST = 'host.docker.internal';
const TARGET_PORT = PORT;

console.log(`\n🚀 Vite HMR Proxy for Docker`);
console.log(`   Listening on: http://localhost:${PORT}`);
console.log(`   Forwarding to: http://${TARGET_HOST}:${TARGET_PORT}`);
console.log(`   HTTP: ✅ Supported`);
console.log(`   WebSocket: ✅ Supported (for HMR)\n`);

// Create HTTP server
const server = http.createServer((req, res) => {
  const options = {
    hostname: TARGET_HOST,
    port: TARGET_PORT,
    path: req.url,
    method: req.method,
    headers: {
      ...req.headers,
      host: `${TARGET_HOST}:${TARGET_PORT}`
    }
  };

  console.log(`[HTTP] ${req.method} ${req.url}`);

  const proxy = http.request(options, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res, { end: true });
  });

  proxy.on('error', (err) => {
    console.error(`[HTTP] Error: ${err.message}`);
    res.writeHead(502);
    res.end('Bad Gateway');
  });

  req.pipe(proxy, { end: true });
});

// Handle WebSocket upgrades for HMR
server.on('upgrade', (req, socket, head) => {
  console.log(`[WS] Upgrade request: ${req.url}`);
  
  const targetSocket = net.connect(TARGET_PORT, TARGET_HOST, () => {
    targetSocket.write(`GET ${req.url} HTTP/1.1\r\n`);
    
    for (const [key, value] of Object.entries(req.headers)) {
      if (key.toLowerCase() === 'host') {
        targetSocket.write(`Host: ${TARGET_HOST}:${TARGET_PORT}\r\n`);
      } else {
        targetSocket.write(`${key}: ${value}\r\n`);
      }
    }
    
    targetSocket.write('\r\n');
    targetSocket.write(head);
    
    socket.pipe(targetSocket);
    targetSocket.pipe(socket);
  });

  targetSocket.on('error', (err) => {
    console.error(`[WS] Error: ${err.message}`);
    socket.end();
  });

  socket.on('error', (err) => {
    console.error(`[WS] Socket error: ${err.message}`);
    targetSocket.end();
  });
});

// Start server
server.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Proxy ready! Use http://localhost:${PORT} in your Docker container\n`);
});

// Handle errors
server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`❌ Port ${PORT} is already in use`);
  } else {
    console.error(`❌ Server error: ${err.message}`);
  }
  process.exit(1);
});

// Graceful shutdown
process.on('SIGINT', () => {
  console.log('\n👋 Shutting down proxy...');
  server.close(() => {
    process.exit(0);
  });
});