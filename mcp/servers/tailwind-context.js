#!/usr/bin/env node

/**
 * MCP Server for Tailwind CSS v4.1 Context
 *
 * This MCP server provides cached Tailwind CSS v4.1 context and documentation
 * to help with styling applications using the latest Tailwind features.
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

class TailwindContextMCP {
  constructor() {
    this.contextData = null;
    this.contextPath = path.join(__dirname, '..', 'context', 'tailwind-v4.1.mcp.json');

    this.server = new Server(
      {
        name: 'mcp-tailwind-context',
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
      console.error('Tailwind CSS v4.1 context loaded and cached successfully');
    } catch (error) {
      console.error('Error loading Tailwind context:', error.message);
      this.contextData = {
        name: 'tailwind-v4.1',
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
          uri: 'tailwind://context/full',
          name: 'Tailwind CSS v4.1 Full Context',
          description: 'Complete Tailwind CSS v4.1 documentation and utilities',
          mimeType: 'application/json'
        },
        {
          uri: 'tailwind://context/utilities',
          name: 'Tailwind Utility Classes',
          description: 'All available utility classes organized by category',
          mimeType: 'application/json'
        },
        {
          uri: 'tailwind://context/colors',
          name: 'Tailwind Color System',
          description: 'Color palette and utilities',
          mimeType: 'application/json'
        },
        {
          uri: 'tailwind://context/responsive',
          name: 'Tailwind Responsive Design',
          description: 'Breakpoints and responsive utilities',
          mimeType: 'application/json'
        },
        {
          uri: 'tailwind://context/configuration',
          name: 'Tailwind Configuration',
          description: 'Configuration options and customization',
          mimeType: 'application/json'
        },
        {
          uri: 'tailwind://context/v4-features',
          name: 'Tailwind v4 New Features',
          description: 'New features and improvements in v4',
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
        case 'tailwind://context/full':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify(this.contextData, null, 2)
              }
            ]
          };

        case 'tailwind://context/utilities':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify({
                  utilities: context.utilities || {},
                  modifiers: context.modifiers || {}
                }, null, 2)
              }
            ]
          };

        case 'tailwind://context/colors':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify({
                  colors: context.utilities?.colors || {},
                  color_system: context.design_system?.colors || {}
                }, null, 2)
              }
            ]
          };

        case 'tailwind://context/responsive':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify({
                  breakpoints: context.responsive?.breakpoints || {},
                  responsive_design: context.responsive || {}
                }, null, 2)
              }
            ]
          };

        case 'tailwind://context/configuration':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify({
                  configuration: context.configuration || {},
                  customization: context.customization || {}
                }, null, 2)
              }
            ]
          };

        case 'tailwind://context/v4-features':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify({
                  v4_features: context.v4_features || {},
                  migration: context.migration || {}
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
          name: 'get_tailwind_info',
          description: 'Get information about Tailwind CSS v4.1',
          inputSchema: {
            type: 'object',
            properties: {
              topic: {
                type: 'string',
                description: 'Topic to get info about',
                enum: ['utilities', 'colors', 'responsive', 'configuration', 'v4-features', 'all'],
                default: 'all'
              }
            }
          }
        },
        {
          name: 'search_tailwind_classes',
          description: 'Search for Tailwind CSS utility classes',
          inputSchema: {
            type: 'object',
            properties: {
              query: {
                type: 'string',
                description: 'Search query for utility classes'
              },
              category: {
                type: 'string',
                description: 'Category to search within',
                enum: ['layout', 'flexbox', 'grid', 'spacing', 'sizing', 'typography', 'colors', 'borders', 'effects', 'all']
              }
            },
            required: ['query']
          }
        },
        {
          name: 'get_tailwind_examples',
          description: 'Get Tailwind CSS usage examples',
          inputSchema: {
            type: 'object',
            properties: {
              component: {
                type: 'string',
                description: 'Component type to get examples for',
                enum: ['button', 'card', 'form', 'navigation', 'modal', 'grid', 'flex', 'typography']
              }
            },
            required: ['component']
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
        case 'get_tailwind_info':
          return this.getTailwindInfo(args);

        case 'search_tailwind_classes':
          return this.searchTailwindClasses(args);

        case 'get_tailwind_examples':
          return this.getTailwindExamples(args);

        default:
          throw new Error(`Unknown tool: ${name}`);
      }
    });
  }

  async getTailwindInfo({ topic = 'all' }) {
    const context = this.contextData.context || {};
    let result = {};

    switch (topic) {
      case 'utilities':
        result = context.utilities || {};
        break;

      case 'colors':
        result = {
          colors: context.utilities?.colors || {},
          color_system: context.design_system?.colors || {}
        };
        break;

      case 'responsive':
        result = context.responsive || {};
        break;

      case 'configuration':
        result = {
          configuration: context.configuration || {},
          customization: context.customization || {}
        };
        break;

      case 'v4-features':
        result = {
          v4_features: context.v4_features || {},
          migration: context.migration || {}
        };
        break;

      case 'all':
      default:
        result = this.contextData;
        break;
    }

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(result, null, 2)
        }
      ]
    };
  }

  async searchTailwindClasses({ query, category = 'all' }) {
    const searchLower = query.toLowerCase();
    const results = [];
    const context = this.contextData.context || {};
    const utilities = context.utilities || {};

    const searchInCategory = (catName, catData) => {
      if (!catData) return;

      if (typeof catData === 'object' && !Array.isArray(catData)) {
        for (const [key, value] of Object.entries(catData)) {
          if (key.toLowerCase().includes(searchLower)) {
            results.push({
              category: catName,
              class: key,
              description: value
            });
          } else if (typeof value === 'string' && value.toLowerCase().includes(searchLower)) {
            results.push({
              category: catName,
              class: key,
              description: value
            });
          }
        }
      } else if (Array.isArray(catData)) {
        catData.forEach(item => {
          if (typeof item === 'string' && item.toLowerCase().includes(searchLower)) {
            results.push({
              category: catName,
              class: item
            });
          }
        });
      }
    };

    if (category === 'all') {
      for (const [catName, catData] of Object.entries(utilities)) {
        searchInCategory(catName, catData);
      }
    } else if (utilities[category]) {
      searchInCategory(category, utilities[category]);
    }

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            query,
            category,
            found: results.length,
            results: results.slice(0, 30) // Limit to 30 results
          }, null, 2)
        }
      ]
    };
  }

  async getTailwindExamples({ component }) {
    const examples = {
      button: {
        primary: 'bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded',
        secondary: 'bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded',
        outline: 'border-2 border-blue-500 text-blue-500 hover:bg-blue-500 hover:text-white font-bold py-2 px-4 rounded'
      },
      card: {
        basic: 'bg-white rounded-lg shadow-md p-6',
        hover: 'bg-white rounded-lg shadow-md hover:shadow-xl transition-shadow p-6',
        dark: 'bg-gray-800 text-white rounded-lg shadow-xl p-6'
      },
      form: {
        input: 'border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500',
        label: 'block text-sm font-medium text-gray-700 mb-2',
        error: 'text-red-500 text-sm mt-1'
      },
      navigation: {
        navbar: 'bg-gray-800 text-white p-4',
        link: 'text-gray-300 hover:text-white px-3 py-2 rounded-md text-sm font-medium',
        active: 'bg-gray-900 text-white px-3 py-2 rounded-md text-sm font-medium'
      },
      modal: {
        overlay: 'fixed inset-0 bg-black bg-opacity-50 z-40',
        content: 'fixed inset-0 flex items-center justify-center z-50',
        box: 'bg-white rounded-lg shadow-xl p-6 max-w-md w-full'
      },
      grid: {
        responsive: 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4',
        auto: 'grid grid-cols-auto-fit minmax(200px, 1fr) gap-4',
        fixed: 'grid grid-cols-4 gap-4'
      },
      flex: {
        center: 'flex items-center justify-center',
        between: 'flex items-center justify-between',
        column: 'flex flex-col space-y-4'
      },
      typography: {
        heading: 'text-3xl font-bold text-gray-900',
        subheading: 'text-xl font-semibold text-gray-700',
        body: 'text-base text-gray-600 leading-relaxed'
      }
    };

    const result = examples[component] || {};

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            component,
            examples: result,
            usage: `Apply these classes to your HTML elements for ${component} styling`
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
    console.error('MCP Tailwind CSS v4.1 Context Server running on stdio');
  }
}

const server = new TailwindContextMCP();
server.run().catch(console.error);