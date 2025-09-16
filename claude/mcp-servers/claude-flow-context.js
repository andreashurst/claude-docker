#!/usr/bin/env node

/**
 * MCP Server for Claude Flow Context
 *
 * This MCP server provides cached Claude Flow automation and orchestration context
 * to help with building automated workflows and test scenarios.
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

class ClaudeFlowContextMCP {
  constructor() {
    this.contextData = null;
    this.contextPath = path.join(__dirname, '..', 'context', 'claude-flow.mcp.json');

    this.server = new Server(
      {
        name: 'mcp-claude-flow-context',
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
      console.error('Claude Flow context loaded and cached successfully');
    } catch (error) {
      console.error('Error loading Claude Flow context:', error.message);
      this.contextData = {
        name: 'claude-flow',
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
          uri: 'claude-flow://context/full',
          name: 'Claude Flow Full Context',
          description: 'Complete Claude Flow automation framework documentation',
          mimeType: 'application/json'
        },
        {
          uri: 'claude-flow://context/workflows',
          name: 'Claude Flow Workflows',
          description: 'Workflow patterns and orchestration',
          mimeType: 'application/json'
        },
        {
          uri: 'claude-flow://context/automation',
          name: 'Automation Features',
          description: 'Automation capabilities and tools',
          mimeType: 'application/json'
        },
        {
          uri: 'claude-flow://context/integration',
          name: 'Integration Guide',
          description: 'Integration with testing frameworks',
          mimeType: 'application/json'
        },
        {
          uri: 'claude-flow://context/api',
          name: 'Claude Flow API',
          description: 'API reference and usage',
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
        case 'claude-flow://context/full':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify(this.contextData, null, 2)
              }
            ]
          };

        case 'claude-flow://context/workflows':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify({
                  workflows: context.workflows || {},
                  orchestration: context.orchestration || {}
                }, null, 2)
              }
            ]
          };

        case 'claude-flow://context/automation':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify({
                  automation: context.automation || {},
                  features: context.features || {}
                }, null, 2)
              }
            ]
          };

        case 'claude-flow://context/integration':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify({
                  integration: context.integration || {},
                  frameworks: context.frameworks || {}
                }, null, 2)
              }
            ]
          };

        case 'claude-flow://context/api':
          return {
            contents: [
              {
                uri,
                mimeType: 'application/json',
                text: JSON.stringify({
                  api: context.api || {},
                  methods: context.methods || {}
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
          name: 'get_flow_info',
          description: 'Get Claude Flow framework information',
          inputSchema: {
            type: 'object',
            properties: {
              topic: {
                type: 'string',
                description: 'Topic to get info about',
                enum: ['workflows', 'automation', 'integration', 'api', 'all'],
                default: 'all'
              }
            }
          }
        },
        {
          name: 'get_workflow_example',
          description: 'Get workflow pattern examples',
          inputSchema: {
            type: 'object',
            properties: {
              pattern: {
                type: 'string',
                description: 'Workflow pattern type',
                enum: ['sequential', 'parallel', 'conditional', 'loop', 'error-handling', 'data-pipeline']
              }
            },
            required: ['pattern']
          }
        },
        {
          name: 'get_automation_recipe',
          description: 'Get automation recipe for common tasks',
          inputSchema: {
            type: 'object',
            properties: {
              task: {
                type: 'string',
                description: 'Automation task',
                enum: ['web-scraping', 'api-testing', 'ui-automation', 'data-processing', 'report-generation']
              }
            },
            required: ['task']
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
        case 'get_flow_info':
          return this.getFlowInfo(args);

        case 'get_workflow_example':
          return this.getWorkflowExample(args);

        case 'get_automation_recipe':
          return this.getAutomationRecipe(args);

        default:
          throw new Error(`Unknown tool: ${name}`);
      }
    });
  }

  async getFlowInfo({ topic = 'all' }) {
    const context = this.contextData.context || {};
    let result = {};

    switch (topic) {
      case 'workflows':
        result = {
          workflows: context.workflows || {},
          orchestration: context.orchestration || {}
        };
        break;

      case 'automation':
        result = {
          automation: context.automation || {},
          features: context.features || {}
        };
        break;

      case 'integration':
        result = {
          integration: context.integration || {},
          frameworks: context.frameworks || {}
        };
        break;

      case 'api':
        result = {
          api: context.api || {},
          methods: context.methods || {}
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

  async getWorkflowExample({ pattern }) {
    const examples = {
      sequential: {
        description: 'Sequential workflow execution',
        example: `// Sequential workflow
const workflow = new ClaudeFlow.Workflow('sequential-test');

workflow
  .step('login', async (context) => {
    await context.page.goto('/login');
    await context.page.fill('#username', 'user');
    await context.page.fill('#password', 'pass');
    await context.page.click('button[type="submit"]');
  })
  .step('navigate', async (context) => {
    await context.page.click('a[href="/dashboard"]');
    await context.page.waitForSelector('.dashboard');
  })
  .step('verify', async (context) => {
    const title = await context.page.title();
    expect(title).toBe('Dashboard');
  });

await workflow.run();`
      },
      parallel: {
        description: 'Parallel workflow execution',
        example: `// Parallel workflow
const workflow = new ClaudeFlow.Workflow('parallel-test');

workflow.parallel([
  {
    name: 'test-chrome',
    fn: async (context) => {
      const browser = await chromium.launch();
      const page = await browser.newPage();
      await page.goto('/');
      await browser.close();
    }
  },
  {
    name: 'test-firefox',
    fn: async (context) => {
      const browser = await firefox.launch();
      const page = await browser.newPage();
      await page.goto('/');
      await browser.close();
    }
  }
]);

await workflow.run();`
      },
      conditional: {
        description: 'Conditional workflow execution',
        example: `// Conditional workflow
const workflow = new ClaudeFlow.Workflow('conditional-test');

workflow
  .step('check-feature', async (context) => {
    const response = await fetch('/api/features');
    context.featureEnabled = response.ok;
  })
  .conditional('feature-test', {
    condition: (context) => context.featureEnabled,
    then: async (context) => {
      // Test new feature
      await context.page.goto('/new-feature');
      await context.page.click('.feature-button');
    },
    else: async (context) => {
      // Test old flow
      await context.page.goto('/old-flow');
    }
  });

await workflow.run();`
      },
      loop: {
        description: 'Loop workflow pattern',
        example: `// Loop workflow
const workflow = new ClaudeFlow.Workflow('loop-test');

const testData = [
  { username: 'user1', expected: 'Welcome user1' },
  { username: 'user2', expected: 'Welcome user2' },
  { username: 'user3', expected: 'Welcome user3' }
];

workflow.forEach(testData, async (data, context) => {
  await context.page.goto('/login');
  await context.page.fill('#username', data.username);
  await context.page.click('button[type="submit"]');

  const welcome = await context.page.textContent('.welcome');
  expect(welcome).toBe(data.expected);
});

await workflow.run();`
      },
      'error-handling': {
        description: 'Error handling in workflows',
        example: `// Error handling workflow
const workflow = new ClaudeFlow.Workflow('error-handling');

workflow
  .step('risky-operation', async (context) => {
    try {
      await context.page.goto('/unstable-page');
      await context.page.click('.might-not-exist');
    } catch (error) {
      context.error = error;
      throw error;
    }
  })
  .onError(async (error, context) => {
    // Log error
    console.error('Workflow failed:', error);

    // Take screenshot
    await context.page.screenshot({
      path: \`error-\${Date.now()}.png\`
    });

    // Attempt recovery
    await context.page.goto('/');
  })
  .finally(async (context) => {
    // Cleanup
    await context.browser?.close();
  });

await workflow.run();`
      },
      'data-pipeline': {
        description: 'Data processing pipeline',
        example: `// Data pipeline workflow
const workflow = new ClaudeFlow.Pipeline('data-processing');

workflow
  .source(async () => {
    // Fetch data
    const response = await fetch('/api/data');
    return response.json();
  })
  .transform(async (data) => {
    // Process data
    return data.map(item => ({
      ...item,
      processed: true,
      timestamp: Date.now()
    }));
  })
  .filter(async (item) => {
    // Filter valid items
    return item.valid === true;
  })
  .batch(10) // Process in batches of 10
  .sink(async (batch) => {
    // Save processed data
    await fetch('/api/save', {
      method: 'POST',
      body: JSON.stringify(batch)
    });
  });

await workflow.run();`
      }
    };

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(examples[pattern] || {
            error: 'Pattern not found',
            available: Object.keys(examples)
          }, null, 2)
        }
      ]
    };
  }

  async getAutomationRecipe({ task }) {
    const recipes = {
      'web-scraping': {
        description: 'Web scraping automation',
        recipe: `// Web scraping with Claude Flow
const scraper = new ClaudeFlow.Scraper({
  headless: true,
  timeout: 30000
});

const data = await scraper
  .goto('https://example.com/products')
  .waitForSelector('.product-list')
  .extract({
    products: {
      selector: '.product',
      multiple: true,
      data: {
        name: '.product-name',
        price: '.product-price',
        image: { selector: 'img', attr: 'src' },
        link: { selector: 'a', attr: 'href' }
      }
    }
  })
  .paginate('.next-page', { maxPages: 5 })
  .run();

console.log('Scraped products:', data);`
      },
      'api-testing': {
        description: 'API testing automation',
        recipe: `// API testing with Claude Flow
const apiTest = new ClaudeFlow.APITest({
  baseURL: 'https://api.example.com',
  headers: {
    'Authorization': 'Bearer token'
  }
});

await apiTest
  .get('/users')
  .expect(200)
  .expect('Content-Type', /json/)
  .expect((res) => {
    expect(res.body).toHaveProperty('users');
    expect(res.body.users).toBeArray();
  });

await apiTest
  .post('/users', {
    name: 'Test User',
    email: 'test@example.com'
  })
  .expect(201)
  .expect('Location', /\\/users\\/\\d+/);`
      },
      'ui-automation': {
        description: 'UI automation flow',
        recipe: `// UI automation with Claude Flow
const automation = new ClaudeFlow.UIAutomation();

await automation
  .launch({ headless: false })
  .goto('https://example.com')
  .type('#search', 'playwright')
  .press('Enter')
  .waitForSelector('.results')
  .screenshot('search-results.png')
  .evaluate(() => {
    return document.querySelectorAll('.result').length;
  })
  .then(count => {
    console.log(\`Found \${count} results\`);
  })
  .close();`
      },
      'data-processing': {
        description: 'Data processing automation',
        recipe: `// Data processing with Claude Flow
const processor = new ClaudeFlow.DataProcessor();

await processor
  .loadCSV('input.csv')
  .filter(row => row.status === 'active')
  .transform(row => ({
    ...row,
    processed_at: new Date().toISOString(),
    score: calculateScore(row)
  }))
  .validate({
    score: { type: 'number', min: 0, max: 100 },
    email: { type: 'email' }
  })
  .aggregate({
    totalScore: { sum: 'score' },
    avgScore: { avg: 'score' },
    count: { count: '*' }
  })
  .saveJSON('output.json')
  .saveCSV('output.csv');`
      },
      'report-generation': {
        description: 'Automated report generation',
        recipe: `// Report generation with Claude Flow
const reporter = new ClaudeFlow.Reporter();

await reporter
  .collectMetrics({
    performance: await getPerformanceMetrics(),
    errors: await getErrorLogs(),
    usage: await getUsageStats()
  })
  .generateCharts({
    type: 'line',
    data: 'performance.responseTime',
    title: 'Response Time Trend'
  })
  .addSection('Executive Summary', {
    template: 'summary.md',
    data: { date: new Date() }
  })
  .addSection('Performance Analysis', {
    content: performanceAnalysis
  })
  .export({
    format: 'pdf',
    filename: 'report.pdf',
    email: 'team@example.com'
  });`
      }
    };

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(recipes[task] || {
            error: 'Task not found',
            available: Object.keys(recipes)
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
    console.error('MCP Claude Flow Context Server running on stdio');
  }
}

const server = new ClaudeFlowContextMCP();
server.run().catch(console.error);