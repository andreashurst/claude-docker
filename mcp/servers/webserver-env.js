#!/usr/bin/env node
/**
 * Webserver Environment MCP Server
 * Provides tools to check external webserver status
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import http from 'http';
import https from 'https';

const server = new Server(
  {
    name: 'webserver-env',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Helper function to check URL status
async function checkUrl(url, timeout = 5000, originalHostname = null) {
  return new Promise((resolve) => {
    const urlObj = new URL(url);
    const isHttps = urlObj.protocol === 'https:';
    const client = isHttps ? https : http;

    // Use original hostname for Host header, or current hostname if not provided
    const hostHeader = originalHostname || urlObj.hostname;

    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port || (isHttps ? 443 : 80),
      path: urlObj.pathname + urlObj.search,
      method: 'GET',
      timeout: timeout,
      headers: {
        'Host': hostHeader,
        'User-Agent': 'webserver-env-mcp/1.0'
      }
    };

    const req = client.request(options, (res) => {
      resolve({
        success: true,
        status: res.statusCode,
        statusMessage: res.statusMessage,
        headers: res.headers,
      });
      res.resume(); // Consume response
    });

    req.on('error', (error) => {
      resolve({
        success: false,
        error: error.message,
      });
    });

    req.on('timeout', () => {
      req.destroy();
      resolve({
        success: false,
        error: 'Request timeout',
      });
    });

    req.end();
  });
}

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'check_webserver_status',
        description: 'Check if the external webserver is responding',
        inputSchema: {
          type: 'object',
          properties: {
            url: {
              type: 'string',
              description: 'URL to check (default: http://localhost)',
              default: 'http://localhost',
            },
            timeout: {
              type: 'number',
              description: 'Timeout in seconds (default: 5)',
              default: 5,
            },
          },
        },
      },
      {
        name: 'get_webserver_headers',
        description: 'Get HTTP headers from the webserver',
        inputSchema: {
          type: 'object',
          properties: {
            url: {
              type: 'string',
              description: 'URL to check (default: http://localhost)',
              default: 'http://localhost',
            },
          },
        },
      },
      {
        name: 'check_webserver_endpoints',
        description: 'Check multiple webserver endpoints for availability',
        inputSchema: {
          type: 'object',
          properties: {
            base_url: {
              type: 'string',
              description: 'Base URL (default: http://localhost)',
              default: 'http://localhost',
            },
            endpoints: {
              type: 'array',
              items: { type: 'string' },
              description: 'List of endpoints to check',
              default: ['/'],
            },
          },
        },
      },
      {
        name: 'get_docker_webserver_info',
        description: '[DEPRECATED] Docker commands not available inside container',
        inputSchema: {
          type: 'object',
          properties: {
            container_name: {
              type: 'string',
              description: 'Container name pattern to search for',
              default: 'webserver',
            },
          },
        },
      },
      {
        name: 'test_webserver_connectivity',
        description: 'Test connectivity to webserver from inside container',
        inputSchema: {
          type: 'object',
          properties: {
            hosts: {
              type: 'array',
              items: { type: 'string' },
              description: 'Hosts to test',
              default: ['localhost'],
            },
          },
        },
      },
    ],
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    if (name === 'check_webserver_status') {
      const url = args.url || 'http://localhost';
      const timeout = (args.timeout || 5) * 1000;
      const urlObj = new URL(url);
      const originalHostname = urlObj.hostname;

      // Try direct connection first
      let result = await checkUrl(url, timeout);

      // If direct connection fails and hostname is localhost, try host.docker.internal
      if (!result.success && originalHostname === 'localhost') {
        const fallbackUrl = url.replace('localhost', 'host.docker.internal');
        result = await checkUrl(fallbackUrl, timeout, originalHostname);
        if (result.success) {
          result.note = 'Connected via host.docker.internal with Host: localhost header';
        }
      }

      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(result, null, 2),
          },
        ],
      };
    }

    if (name === 'get_webserver_headers') {
      const url = args.url || 'http://localhost';
      const urlObj = new URL(url);
      const originalHostname = urlObj.hostname;

      // Try direct connection first
      let result = await checkUrl(url, 5000);

      // If direct connection fails and hostname is localhost, try host.docker.internal
      if (!result.success && originalHostname === 'localhost') {
        const fallbackUrl = url.replace('localhost', 'host.docker.internal');
        result = await checkUrl(fallbackUrl, 5000, originalHostname);
      }

      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(result.headers || {}, null, 2),
          },
        ],
      };
    }

    if (name === 'check_webserver_endpoints') {
      const baseUrl = args.base_url || 'http://localhost';
      const endpoints = args.endpoints || ['/'];
      const baseUrlObj = new URL(baseUrl);
      const originalHostname = baseUrlObj.hostname;
      const results = [];

      for (const endpoint of endpoints) {
        const url = baseUrl + endpoint;

        // Try direct connection first
        let result = await checkUrl(url, 5000);

        // If direct connection fails and hostname is localhost, try host.docker.internal
        if (!result.success && originalHostname === 'localhost') {
          const fallbackUrl = url.replace('localhost', 'host.docker.internal');
          result = await checkUrl(fallbackUrl, 5000, originalHostname);
        }

        results.push({
          endpoint,
          ...result,
        });
      }

      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(results, null, 2),
          },
        ],
      };
    }

    if (name === 'get_docker_webserver_info') {
      return {
        content: [
          {
            type: 'text',
            text: 'Docker commands are not available inside the container. Use check_webserver_status instead.',
          },
        ],
      };
    }

    if (name === 'test_webserver_connectivity') {
      const hosts = args.hosts || ['localhost'];
      const results = [];

      for (const host of hosts) {
        const url = `http://${host}`;

        // Try direct connection first
        let result = await checkUrl(url, 3000);

        // If direct connection fails and host is localhost, try host.docker.internal
        if (!result.success && host === 'localhost') {
          const fallbackUrl = 'http://host.docker.internal';
          result = await checkUrl(fallbackUrl, 3000, 'localhost');
        }

        results.push({
          host,
          ...result,
        });
      }

      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(results, null, 2),
          },
        ],
      };
    }

    throw new Error(`Unknown tool: ${name}`);
  } catch (error) {
    return {
      content: [
        {
          type: 'text',
          text: `Error: ${error.message}`,
        },
      ],
      isError: true,
    };
  }
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((error) => {
  console.error('Server error:', error);
  process.exit(1);
});
