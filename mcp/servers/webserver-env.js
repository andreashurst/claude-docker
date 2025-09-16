#!/usr/bin/env node

/**
 * MCP Server for External Webserver Environment
 *
 * This MCP server provides safe, read-only access to the external webserver
 * running outside the Docker container. It allows checking status, logs,
 * and configuration without modifying or interfering with the webserver.
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} = require('@modelcontextprotocol/sdk/types.js');
const http = require('http');
const https = require('https');
const { exec } = require('child_process');
const { promisify } = require('util');
const execAsync = promisify(exec);

class WebServerMCP {
  constructor() {
    this.server = new Server(
      {
        name: 'mcp-webserver-env',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupHandlers();
  }

  setupHandlers() {
    // List available tools
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
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
                default: 'http://localhost'
              },
              timeout: {
                type: 'number',
                description: 'Timeout in seconds (default: 5)',
                default: 5
              }
            }
          }
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
                default: 'http://localhost'
              }
            }
          }
        },
        {
          name: 'check_webserver_endpoints',
          description: 'Check multiple webserver endpoints for availability',
          inputSchema: {
            type: 'object',
            properties: {
              endpoints: {
                type: 'array',
                items: { type: 'string' },
                description: 'List of endpoints to check',
                default: ['/']
              },
              base_url: {
                type: 'string',
                description: 'Base URL (default: http://localhost)',
                default: 'http://localhost'
              }
            }
          }
        },
        {
          name: 'get_docker_webserver_info',
          description: 'Get information about Docker webserver container if running',
          inputSchema: {
            type: 'object',
            properties: {
              container_name: {
                type: 'string',
                description: 'Container name pattern to search for',
                default: 'webserver'
              }
            }
          }
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
                default: ['localhost', 'webserver', 'host.docker.internal']
              }
            }
          }
        }
      ]
    }));

    // Handle tool calls
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      switch (name) {
        case 'check_webserver_status':
          return this.checkWebserverStatus(args);

        case 'get_webserver_headers':
          return this.getWebserverHeaders(args);

        case 'check_webserver_endpoints':
          return this.checkWebserverEndpoints(args);

        case 'get_docker_webserver_info':
          return this.getDockerWebserverInfo(args);

        case 'test_webserver_connectivity':
          return this.testWebserverConnectivity(args);

        default:
          throw new Error(`Unknown tool: ${name}`);
      }
    });
  }

  async checkWebserverStatus({ url = 'http://localhost', timeout = 5 }) {
    return new Promise((resolve) => {
      const urlObj = new URL(url);
      const client = urlObj.protocol === 'https:' ? https : http;

      const options = {
        hostname: urlObj.hostname,
        port: urlObj.port || (urlObj.protocol === 'https:' ? 443 : 80),
        path: urlObj.pathname,
        method: 'HEAD',
        timeout: timeout * 1000
      };

      const req = client.request(options, (res) => {
        resolve({
          content: [
            {
              type: 'text',
              text: JSON.stringify({
                status: 'online',
                statusCode: res.statusCode,
                statusMessage: res.statusMessage,
                url: url,
                server: res.headers['server'] || 'unknown',
                contentType: res.headers['content-type'] || 'unknown'
              }, null, 2)
            }
          ]
        });
      });

      req.on('error', (error) => {
        resolve({
          content: [
            {
              type: 'text',
              text: JSON.stringify({
                status: 'offline',
                url: url,
                error: error.message,
                code: error.code
              }, null, 2)
            }
          ]
        });
      });

      req.on('timeout', () => {
        req.destroy();
        resolve({
          content: [
            {
              type: 'text',
              text: JSON.stringify({
                status: 'timeout',
                url: url,
                timeout: timeout
              }, null, 2)
            }
          ]
        });
      });

      req.end();
    });
  }

  async getWebserverHeaders({ url = 'http://localhost' }) {
    return new Promise((resolve) => {
      const urlObj = new URL(url);
      const client = urlObj.protocol === 'https:' ? https : http;

      const options = {
        hostname: urlObj.hostname,
        port: urlObj.port || (urlObj.protocol === 'https:' ? 443 : 80),
        path: urlObj.pathname,
        method: 'HEAD',
        timeout: 5000
      };

      const req = client.request(options, (res) => {
        resolve({
          content: [
            {
              type: 'text',
              text: JSON.stringify({
                url: url,
                statusCode: res.statusCode,
                headers: res.headers
              }, null, 2)
            }
          ]
        });
      });

      req.on('error', (error) => {
        resolve({
          content: [
            {
              type: 'text',
              text: `Error getting headers from ${url}: ${error.message}`
            }
          ]
        });
      });

      req.end();
    });
  }

  async checkWebserverEndpoints({ endpoints = ['/'], base_url = 'http://localhost' }) {
    const results = [];

    for (const endpoint of endpoints) {
      const url = new URL(endpoint, base_url).toString();
      const result = await this.checkWebserverStatus({ url, timeout: 3 });
      const data = JSON.parse(result.content[0].text);
      results.push({
        endpoint,
        url,
        status: data.status,
        statusCode: data.statusCode
      });
    }

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            base_url,
            endpoints_checked: endpoints.length,
            results
          }, null, 2)
        }
      ]
    };
  }

  async getDockerWebserverInfo({ container_name = 'webserver' }) {
    try {
      // Get container info
      const { stdout: containers } = await execAsync(
        `docker ps --filter "name=${container_name}" --format "{{json .}}" 2>/dev/null || echo "[]"`
      );

      const containerList = containers.trim().split('\n').filter(Boolean).map(line => {
        try {
          return JSON.parse(line);
        } catch {
          return null;
        }
      }).filter(Boolean);

      // Get network info if container exists
      let networkInfo = null;
      if (containerList.length > 0) {
        try {
          const { stdout: networks } = await execAsync(
            `docker inspect ${containerList[0].Names} --format '{{json .NetworkSettings.Networks}}' 2>/dev/null || echo "{}"`
          );
          networkInfo = JSON.parse(networks.trim());
        } catch {
          networkInfo = {};
        }
      }

      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify({
              containers: containerList,
              networks: networkInfo,
              found: containerList.length > 0
            }, null, 2)
          }
        ]
      };
    } catch (error) {
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify({
              error: error.message,
              hint: 'Docker might not be accessible from this container'
            }, null, 2)
          }
        ]
      };
    }
  }

  async testWebserverConnectivity({ hosts = ['localhost', 'webserver', 'host.docker.internal'] }) {
    const results = [];

    for (const host of hosts) {
      try {
        // Try HTTP connection
        const httpResult = await this.checkWebserverStatus({
          url: `http://${host}`,
          timeout: 2
        });
        const httpData = JSON.parse(httpResult.content[0].text);

        // Try HTTPS connection
        const httpsResult = await this.checkWebserverStatus({
          url: `https://${host}`,
          timeout: 2
        });
        const httpsData = JSON.parse(httpsResult.content[0].text);

        // Try ping
        let pingable = false;
        try {
          await execAsync(`ping -c 1 -W 1 ${host} 2>/dev/null`);
          pingable = true;
        } catch {
          pingable = false;
        }

        results.push({
          host,
          http: httpData.status,
          https: httpsData.status,
          pingable
        });
      } catch (error) {
        results.push({
          host,
          error: error.message
        });
      }
    }

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            tested_hosts: hosts,
            results,
            summary: {
              reachable: results.filter(r => r.http === 'online' || r.https === 'online').map(r => r.host),
              unreachable: results.filter(r => r.http !== 'online' && r.https !== 'online').map(r => r.host)
            }
          }, null, 2)
        }
      ]
    };
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('MCP Webserver Environment Server running on stdio');
  }
}

const server = new WebServerMCP();
server.run().catch(console.error);