#!/usr/bin/env node

/**
 * MCP Server for DaisyUI Context
 *
 * This MCP server provides cached DaisyUI component library context and documentation
 * to help with building beautiful UIs using DaisyUI components with Tailwind CSS.
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

class DaisyUIContextMCP {
  constructor() {
    this.contextData = null;
    this.contextPath = path.join(__dirname, '..', 'context', 'daisyui.mcp.json');

    this.server = new Server(
      {
        name: 'mcp-daisyui-context',
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
      console.error('DaisyUI context loaded and cached successfully');
    } catch (error) {
      console.error('Error loading DaisyUI context:', error.message);
      this.contextData = {
        name: 'daisyui',
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
          uri: 'daisyui://context/full',
          name: 'DaisyUI Full Context',
          description: 'Complete DaisyUI component library documentation',
          mimeType: 'application/json'
        },
        {
          uri: 'daisyui://context/components',
          name: 'DaisyUI Components',
          description: 'All available DaisyUI components with examples',
          mimeType: 'application/json'
        },
        {
          uri: 'daisyui://context/themes',
          name: 'DaisyUI Themes',
          description: 'Theme system and available themes',
          mimeType: 'application/json'
        },
        {
          uri: 'daisyui://context/utilities',
          name: 'DaisyUI Utilities',
          description: 'Utility classes and modifiers',
          mimeType: 'application/json'
        },
        {
          uri: 'daisyui://context/colors',
          name: 'DaisyUI Colors',
          description: 'Color system and semantic colors',
          mimeType: 'application/json'
        },
        {
          uri: 'daisyui://context/installation',
          name: 'DaisyUI Installation',
          description: 'Installation and configuration guide',
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
        case 'daisyui://context/full':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify(this.contextData, null, 2)
              }
            ]
          };

        case 'daisyui://context/components':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify({
                  components: context.components || {},
                  examples: context.examples || {}
                }, null, 2)
              }
            ]
          };

        case 'daisyui://context/themes':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify({
                  themes: context.themes || {},
                  theming: context.theming || {}
                }, null, 2)
              }
            ]
          };

        case 'daisyui://context/utilities':
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

        case 'daisyui://context/colors':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify({
                  colors: context.colors || {},
                  semantic_colors: context.semantic_colors || {}
                }, null, 2)
              }
            ]
          };

        case 'daisyui://context/installation':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify({
                  installation: context.installation || {},
                  configuration: context.configuration || {},
                  integration: context.integration || {}
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
          name: 'get_daisyui_component',
          description: 'Get information about a specific DaisyUI component',
          inputSchema: {
            type: 'object',
            properties: {
              component: {
                type: 'string',
                description: 'Component name (e.g., button, card, modal, navbar)'
              }
            },
            required: ['component']
          }
        },
        {
          name: 'search_daisyui_components',
          description: 'Search for DaisyUI components by functionality',
          inputSchema: {
            type: 'object',
            properties: {
              query: {
                type: 'string',
                description: 'Search query'
              },
              category: {
                type: 'string',
                description: 'Component category',
                enum: ['actions', 'data-display', 'data-input', 'layout', 'navigation', 'feedback', 'all']
              }
            },
            required: ['query']
          }
        },
        {
          name: 'get_daisyui_theme_info',
          description: 'Get information about DaisyUI themes',
          inputSchema: {
            type: 'object',
            properties: {
              theme: {
                type: 'string',
                description: 'Theme name or "all" for all themes',
                default: 'all'
              }
            }
          }
        },
        {
          name: 'get_daisyui_examples',
          description: 'Get DaisyUI component examples',
          inputSchema: {
            type: 'object',
            properties: {
              component: {
                type: 'string',
                description: 'Component to get examples for'
              },
              variant: {
                type: 'string',
                description: 'Specific variant or style'
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
        case 'get_daisyui_component':
          return this.getDaisyUIComponent(args);

        case 'search_daisyui_components':
          return this.searchDaisyUIComponents(args);

        case 'get_daisyui_theme_info':
          return this.getDaisyUIThemeInfo(args);

        case 'get_daisyui_examples':
          return this.getDaisyUIExamples(args);

        default:
          throw new Error(`Unknown tool: ${name}`);
      }
    });
  }

  async getDaisyUIComponent({ component }) {
    const context = this.contextData.context || {};
    const components = context.components || {};

    const componentInfo = components[component] ||
      Object.values(components).flat().find(c =>
        c && typeof c === 'object' && c.name === component
      );

    if (!componentInfo) {
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify({
              error: `Component '${component}' not found`,
              available: Object.keys(components)
            }, null, 2)
          }
        ]
      };
    }

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            component,
            info: componentInfo
          }, null, 2)
        }
      ]
    };
  }

  async searchDaisyUIComponents({ query, category = 'all' }) {
    const searchLower = query.toLowerCase();
    const results = [];
    const context = this.contextData.context || {};
    const components = context.components || {};

    const searchInCategory = (catName, catData) => {
      if (!catData) return;

      if (Array.isArray(catData)) {
        catData.forEach(item => {
          if (typeof item === 'string' && item.toLowerCase().includes(searchLower)) {
            results.push({
              category: catName,
              component: item
            });
          } else if (typeof item === 'object' && item.name) {
            if (item.name.toLowerCase().includes(searchLower) ||
                (item.description && item.description.toLowerCase().includes(searchLower))) {
              results.push({
                category: catName,
                component: item.name,
                description: item.description
              });
            }
          }
        });
      } else if (typeof catData === 'object') {
        for (const [key, value] of Object.entries(catData)) {
          if (key.toLowerCase().includes(searchLower)) {
            results.push({
              category: catName,
              component: key,
              info: value
            });
          }
        }
      }
    };

    if (category === 'all') {
      for (const [catName, catData] of Object.entries(components)) {
        searchInCategory(catName, catData);
      }
    } else if (components[category]) {
      searchInCategory(category, components[category]);
    }

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            query,
            category,
            found: results.length,
            results: results.slice(0, 20)
          }, null, 2)
        }
      ]
    };
  }

  async getDaisyUIThemeInfo({ theme = 'all' }) {
    const context = this.contextData.context || {};
    const themes = context.themes || {};

    if (theme === 'all') {
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify({
              themes: themes,
              theming: context.theming || {}
            }, null, 2)
          }
        ]
      };
    }

    const themeInfo = themes[theme] || themes.available?.find(t => t === theme);

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            theme,
            info: themeInfo || `Theme '${theme}' not found`,
            available: themes.available || Object.keys(themes)
          }, null, 2)
        }
      ]
    };
  }

  async getDaisyUIExamples({ component, variant }) {
    const examples = {
      button: {
        primary: '<button class="btn btn-primary">Primary</button>',
        secondary: '<button class="btn btn-secondary">Secondary</button>',
        accent: '<button class="btn btn-accent">Accent</button>',
        ghost: '<button class="btn btn-ghost">Ghost</button>',
        link: '<button class="btn btn-link">Link</button>',
        outline: '<button class="btn btn-outline">Outline</button>',
        sizes: {
          tiny: '<button class="btn btn-xs">Tiny</button>',
          small: '<button class="btn btn-sm">Small</button>',
          normal: '<button class="btn">Normal</button>',
          large: '<button class="btn btn-lg">Large</button>'
        }
      },
      card: {
        basic: '<div class="card bg-base-100 shadow-xl"><div class="card-body"><h2 class="card-title">Card title!</h2><p>Card content</p></div></div>',
        image: '<div class="card bg-base-100 shadow-xl"><figure><img src="/image.jpg" alt="Image" /></figure><div class="card-body"><h2 class="card-title">Card title!</h2><p>Card content</p></div></div>',
        actions: '<div class="card bg-base-100 shadow-xl"><div class="card-body"><h2 class="card-title">Card title!</h2><p>Card content</p><div class="card-actions justify-end"><button class="btn btn-primary">Action</button></div></div></div>'
      },
      modal: {
        basic: '<dialog class="modal"><div class="modal-box"><h3 class="font-bold text-lg">Hello!</h3><p class="py-4">Modal content</p><div class="modal-action"><form method="dialog"><button class="btn">Close</button></form></div></div></dialog>',
        backdrop: '<dialog class="modal"><div class="modal-box"><h3 class="font-bold text-lg">Hello!</h3><p class="py-4">Modal content</p></div><form method="dialog" class="modal-backdrop"><button>close</button></form></dialog>'
      },
      navbar: {
        basic: '<div class="navbar bg-base-100"><div class="flex-1"><a class="btn btn-ghost text-xl">daisyUI</a></div><div class="flex-none"><ul class="menu menu-horizontal px-1"><li><a>Link</a></li></ul></div></div>',
        dropdown: '<div class="navbar bg-base-100"><div class="flex-1"><a class="btn btn-ghost text-xl">daisyUI</a></div><div class="flex-none"><div class="dropdown dropdown-end"><div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar"><div class="w-10 rounded-full"><img src="/avatar.jpg" /></div></div><ul class="menu menu-sm dropdown-content bg-base-100 rounded-box z-[1] mt-3 w-52 p-2 shadow"><li><a>Profile</a></li><li><a>Settings</a></li><li><a>Logout</a></li></ul></div></div></div>'
      },
      form: {
        input: '<input type="text" placeholder="Type here" class="input input-bordered w-full max-w-xs" />',
        select: '<select class="select select-bordered w-full max-w-xs"><option disabled selected>Pick one</option><option>Option 1</option><option>Option 2</option></select>',
        checkbox: '<div class="form-control"><label class="label cursor-pointer"><span class="label-text">Remember me</span><input type="checkbox" class="checkbox" /></label></div>',
        toggle: '<input type="checkbox" class="toggle" />',
        range: '<input type="range" min="0" max="100" value="40" class="range" />'
      }
    };

    const componentExamples = examples[component] || {};

    if (variant && componentExamples[variant]) {
      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify({
              component,
              variant,
              example: componentExamples[variant]
            }, null, 2)
          }
        ]
      };
    }

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({
            component,
            examples: componentExamples
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
    console.error('MCP DaisyUI Context Server running on stdio');
  }
}

const server = new DaisyUIContextMCP();
server.run().catch(console.error);