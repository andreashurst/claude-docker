# MCP (Model Context Protocol) - Clean Structure

**Version**: 2.0 (Rebuilt from scratch - KISS principle)

## Structure

```
mcp/
├── config.json                 # Main MCP configuration
├── init.sh                     # Initialization script
├── cache/                      # Build-time templates
│   ├── bashrc.dev              # Dev container bashrc
│   ├── bashrc.flow             # Flow container bashrc
│   ├── bashrc.root             # Root bashrc
│   ├── claude-config-template.json
│   ├── claude-project-settings-template.json  # Pre-configured project settings
│   ├── README-SETTINGS-TEMPLATE.md           # Settings documentation
│   └── init-environment-db.sql # Environment facts database
├── context/                    # Context data (JSON)
│   ├── playwright/
│   │   └── playwright.json     # Playwright documentation
│   ├── tailwind/
│   │   └── tailwind.json       # Tailwind CSS v4.1
│   ├── daisyui/
│   │   └── daisyui.json        # DaisyUI components
│   ├── vite/
│   │   └── vite.json           # Vite HMR config
│   └── claude-flow/
│       └── claude-flow.json    # Automation framework
└── servers/                    # MCP servers (executable)
    ├── webserver-env.js        # Webserver monitoring
    ├── playwright-context.js   # Playwright docs server
    ├── playwright-advanced-context.js
    ├── tailwind-context.js     # Tailwind CSS server
    ├── daisyui-context.js      # DaisyUI server
    ├── vite-hmr-context.js     # Vite HMR server
    └── claude-flow-context.js  # Claude Flow server
```

## Key Principles

1. **KISS** - Keep It Simple, Stupid
2. **Separation of Concerns** - Context (JSON) vs Servers (JS)
3. **Caching** - Load once, serve fast
4. **Correct Commands** - Use `playwright` NOT `npx playwright`
5. **Host Headers** - Preserve localhost headers in fallbacks

## Deployment

### Docker Build
Files are copied to `/opt/mcp-assets/` during build

### Runtime
At container startup, symlinks are created:
- `/home/claude/mcp/` → `/opt/mcp-assets/`
- `/home/claude/.claude/plugins/mcp.json` → `/opt/mcp-cache/mcp.json`

### Permissions
Claude Code can access `/home/claude/mcp/**` without asking because it's outside the project directory. The path follows symlinks to `/opt/mcp-assets/` automatically.

### Project Settings Template
New projects automatically get pre-configured settings:
- File: `claude-project-settings-template.json`
- Applied on first container start
- Includes all MCP servers and safe permissions
- See `cache/README-SETTINGS-TEMPLATE.md` for details
