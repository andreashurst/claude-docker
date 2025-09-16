#!/usr/bin/env node

/**
 * MCP Server for Vite HMR Context
 *
 * This MCP server provides cached Vite Hot Module Replacement (HMR) context
 * to help with configuring and debugging Vite development servers.
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
} = require('@modelcontextprotocol/sdk/types.js');
const fs = require('fs').promises;
const path = require('path');

class ViteHMRContextMCP {
  constructor() {
    this.contextData = null;
    this.contextPath = path.join(__dirname, '..', 'context', 'vite-hmr.mcp.json');

    this.server = new Server(
      {
        name: 'mcp-vite-hmr-context',
        version: '1.0.0',
      },
      {
        capabilities: {
          tools: {},
          resources: {},
        },
      }
    );

    this.setupHandlers();
  }

  async loadContext() {
    try {
      const data = await fs.readFile(this.contextPath, 'utf-8');
      this.contextData = JSON.parse(data);
      console.error('Vite HMR context loaded and cached successfully');
    } catch (error) {
      console.error('Error loading Vite HMR context:', error.message);
      this.contextData = {
        name: 'vite-hmr',
        version: '1.0.0',
        error: `Failed to load context: ${error.message}`
      };
    }
  }

  setupHandlers() {
    // List available resources
    this.server.setRequestHandler(ListResourcesRequestSchema, async () => ({
      resources: [
        {
          uri: 'vite://context/full',
          name: 'Vite HMR Full Context',
          description: 'Complete Vite HMR configuration and API documentation',
          mimeType: 'application/json'
        },
        {
          uri: 'vite://context/configuration',
          name: 'Vite Configuration',
          description: 'Vite configuration options and examples',
          mimeType: 'application/json'
        },
        {
          uri: 'vite://context/hmr-api',
          name: 'HMR API Reference',
          description: 'Hot Module Replacement API documentation',
          mimeType: 'application/json'
        },
        {
          uri: 'vite://context/troubleshooting',
          name: 'HMR Troubleshooting',
          description: 'Common HMR issues and solutions',
          mimeType: 'application/json'
        },
        {
          uri: 'vite://context/plugins',
          name: 'Vite Plugins',
          description: 'Plugin configuration for HMR',
          mimeType: 'application/json'
        }
      ]
    }));

    // Read resource content
    this.server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
      const { uri } = request.params;

      if (!this.contextData) {
        await this.loadContext();
      }

      const context = this.contextData.context || {};

      switch (uri) {
        case 'vite://context/full':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify(this.contextData, null, 2)
              }
            ]
          };

        case 'vite://context/configuration':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify({
                  configuration: context.configuration || {},
                  server_options: context.server || {}
                }, null, 2)
              }
            ]
          };

        case 'vite://context/hmr-api':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify({
                  hmr_api: context.hmr_api || {},
                  lifecycle: context.lifecycle || {}
                }, null, 2)
              }
            ]
          };

        case 'vite://context/troubleshooting':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify({
                  troubleshooting: context.troubleshooting || {},
                  common_issues: context.common_issues || {}
                }, null, 2)
              }
            ]
          };

        case 'vite://context/plugins':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify({
                  plugins: context.plugins || {},
                  plugin_api: context.plugin_api || {}
                }, null, 2)
              }
            ]
          };

        default:
          throw new Error(`Unknown resource: ${uri}`);
      }
    });

    // List available tools
    this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
      tools: [
        {
          name: 'get_vite_config',
          description: 'Get Vite configuration examples and options',
          inputSchema: {
            type: 'object',
            properties: {
              topic: {
                type: 'string',
                description: 'Configuration topic',
                enum: ['server', 'hmr', 'build', 'plugins', 'all'],
                default: 'all'
              }
            }
          }
        },
        {
          name: 'get_hmr_api_info',
          description: 'Get HMR API usage information',
          inputSchema: {
            type: 'object',
            properties: {
              api_method: {
                type: 'string',
                description: 'HMR API method to get info about',
                enum: ['accept', 'dispose', 'invalidate', 'decline', 'prune', 'data', 'all']
              }
            },
            required: ['api_method']
          }
        },
        {
          name: 'troubleshoot_hmr',
          description: 'Get troubleshooting help for HMR issues',
          inputSchema: {
            type: 'object',
            properties: {
              issue: {
                type: 'string',
                description: 'Type of HMR issue',
                enum: ['not-updating', 'full-reload', 'connection-lost', 'slow-updates', 'module-errors']
              }
            },
            required: ['issue']
          }
        }
      ]
    }));

    // Handle tool calls
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      if (!this.contextData) {
        await this.loadContext();
      }

      switch (name) {
        case 'get_vite_config':
          return this.getViteConfig(args);

        case 'get_hmr_api_info':
          return this.getHMRApiInfo(args);

        case 'troubleshoot_hmr':
          return this.troubleshootHMR(args);

        default:
          throw new Error(`Unknown tool: ${name}`);
      }
    });
  }

  async getViteConfig({ topic = 'all' }) {
    const configs = {
      server: {
        port: 5173,
        host: true,
        hmr: {
          protocol: 'ws',
          host: 'localhost',
          port: 5173,
          clientPort: 5173,
          overlay: true
        },
        watch: {
          usePolling: false
        }
      },
      hmr: {
        enable: true,
        overlay: true,
        timeout: 30000,
        protocol: 'ws',
        host: 'localhost'
      },
      build: {
        target: 'modules',
        minify: 'esbuild',
        sourcemap: true
      },
      plugins: {
        react: '@vitejs/plugin-react',
        vue: '@vitejs/plugin-vue',
        svelte: '@sveltejs/vite-plugin-svelte'
      },
      all: this.contextData
    };

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(configs[topic] || configs.all, null, 2)
        }
      ]
    };
  }

  async getHMRApiInfo({ api_method }) {
    const apiInfo = {
      accept: {
        description: 'Accept updates for the module',
        usage: 'import.meta.hot.accept((newModule) => { /* handle update */ })',
        example: `if (import.meta.hot) {
  import.meta.hot.accept((newModule) => {
    // Update logic here
    console.log('Module updated:', newModule);
  });
}`
      },
      dispose: {
        description: 'Clean up side effects before module replacement',
        usage: 'import.meta.hot.dispose((data) => { /* cleanup */ })',
        example: `if (import.meta.hot) {
  import.meta.hot.dispose((data) => {
    // Clean up side effects
    clearInterval(timer);
    data.timer = timer;
  });
}`
      },
      invalidate: {
        description: 'Invalidate the module and trigger a full reload',
        usage: 'import.meta.hot.invalidate()',
        example: `if (import.meta.hot) {
  if (cannotHandleUpdate) {
    import.meta.hot.invalidate();
  }
}`
      },
      decline: {
        description: 'Mark the module as not accepting updates',
        usage: 'import.meta.hot.decline()',
        example: `if (import.meta.hot) {
  import.meta.hot.decline();
}`
      },
      prune: {
        description: 'Clean up modules that are no longer imported',
        usage: 'import.meta.hot.prune((data) => { /* cleanup */ })',
        example: `if (import.meta.hot) {
  import.meta.hot.prune((data) => {
    // Clean up pruned module
    console.log('Module pruned');
  });
}`
      },
      data: {
        description: 'Persistent data between module reloads',
        usage: 'import.meta.hot.data',
        example: `if (import.meta.hot) {
  // Restore state
  const state = import.meta.hot.data?.state || initialState;

  import.meta.hot.dispose((data) => {
    // Save state
    data.state = state;
  });
}`
      },
      all: {
        accept: 'Accept updates for the module',
        dispose: 'Clean up side effects before replacement',
        invalidate: 'Trigger a full reload',
        decline: 'Mark as not accepting updates',
        prune: 'Clean up pruned modules',
        data: 'Persistent data storage'
      }
    };

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(apiInfo[api_method] || apiInfo.all, null, 2)
        }
      ]
    };
  }

  async troubleshootHMR({ issue }) {
    const solutions = {
      'not-updating': {
        issue: 'HMR not updating changes',
        causes: [
          'Missing import.meta.hot.accept() call',
          'Circular dependencies',
          'Module boundary issues'
        ],
        solutions: [
          'Add import.meta.hot.accept() to the module',
          'Check for circular dependencies',
          'Ensure proper module boundaries',
          'Verify HMR is enabled in config'
        ],
        example: `// Add to your module
if (import.meta.hot) {
  import.meta.hot.accept();
}`
      },
      'full-reload': {
        issue: 'Page doing full reload instead of HMR',
        causes: [
          'Module not accepting updates',
          'Parent module not handling updates',
          'Error in update handler'
        ],
        solutions: [
          'Add proper accept handlers',
          'Handle updates in parent modules',
          'Fix errors in update handlers',
          'Check console for errors'
        ]
      },
      'connection-lost': {
        issue: 'HMR connection lost',
        causes: [
          'WebSocket connection issues',
          'Proxy configuration problems',
          'Network firewall blocking'
        ],
        solutions: [
          'Check WebSocket connection',
          'Configure proxy properly',
          'Verify firewall settings',
          'Use polling as fallback'
        ],
        config: {
          server: {
            hmr: {
              protocol: 'ws',
              host: 'localhost',
              port: 5173
            }
          }
        }
      },
      'slow-updates': {
        issue: 'HMR updates are slow',
        causes: [
          'Large module graphs',
          'Heavy computations in accept handlers',
          'File watching issues'
        ],
        solutions: [
          'Optimize module structure',
          'Simplify accept handlers',
          'Configure file watching',
          'Use selective accepts'
        ]
      },
      'module-errors': {
        issue: 'Module errors during HMR',
        causes: [
          'Runtime errors in updated code',
          'State management issues',
          'Side effect cleanup problems'
        ],
        solutions: [
          'Fix runtime errors',
          'Properly manage state',
          'Clean up side effects in dispose',
          'Add error boundaries'
        ]
      }
    };

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(solutions[issue] || {
            error: 'Unknown issue type',
            available: Object.keys(solutions)
          }, null, 2)
        }
      ]
    };
  }

  async run() {
    // Pre-load and cache the context
    await this.loadContext();

    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error('MCP Vite HMR Context Server running on stdio');
  }
}

const server = new ViteHMRContextMCP();
server.run().catch(console.error);