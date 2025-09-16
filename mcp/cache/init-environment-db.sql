-- Initialize environment facts database for Claude
-- This database is pre-populated during Docker image build
-- It provides immediate access to environment configuration without rediscovery

CREATE TABLE IF NOT EXISTS environment_facts (
    category TEXT NOT NULL,
    fact TEXT NOT NULL,
    details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (category, fact)
);

-- Playwright Testing Framework
INSERT OR REPLACE INTO environment_facts (category, fact, details) VALUES
('Playwright', 'Version', 'v1.55.0 installed globally at /usr/local/bin/playwright'),
('Playwright', 'Browsers', 'Chromium-1187, Firefox-1490, WebKit-2203 at /opt/playwright-browsers/'),
('Playwright', 'Test Directory', '/var/www/html/playwright/tests/ - ALWAYS save test files here'),
('Playwright', 'Results Directory', '/var/www/html/playwright/results/ - ALWAYS save screenshots/artifacts here'),
('Playwright', 'Report Directory', '/var/www/html/playwright/report/ - HTML reports generated here'),
('Playwright', 'Import Path', 'require("playwright") or require("@playwright/test")'),
('Playwright', 'Commands', 'npx playwright test, npx playwright codegen, npx playwright show-report');

-- MCP Servers (Model Context Protocol)
INSERT OR REPLACE INTO environment_facts (category, fact, details) VALUES
('MCP-Servers', 'filesystem', 'File operations at /var/www/html'),
('MCP-Servers', 'memory', 'In-memory data storage'),
('MCP-Servers', 'git', 'Git repository operations at /var/www/html'),
('MCP-Servers', 'sqlite', 'Database at /home/claude/.claude/databases/main.db'),
('MCP-Servers', 'webserver-env', 'External webserver monitoring (read-only)');

-- MCP Context Servers (Documentation)
INSERT OR REPLACE INTO environment_facts (category, fact, details) VALUES
('MCP-Context', 'playwright-context', 'Playwright testing framework documentation at /home/claude/mcp/servers/'),
('MCP-Context', 'playwright-advanced-context', 'Advanced Playwright patterns at /home/claude/mcp/servers/'),
('MCP-Context', 'tailwind-context', 'Tailwind CSS v4.1 documentation'),
('MCP-Context', 'daisyui-context', 'DaisyUI component library documentation'),
('MCP-Context', 'vite-hmr-context', 'Vite HMR configuration help'),
('MCP-Context', 'claude-flow-context', 'Claude Flow automation framework');

-- Package Managers
INSERT OR REPLACE INTO environment_facts (category, fact, details) VALUES
('Package-Managers', 'Node.js', 'npm, yarn, pnpm, bun - all installed globally'),
('Package-Managers', 'Python', 'pip, pipenv, poetry'),
('Package-Managers', 'PHP', 'composer'),
('Package-Managers', 'Ruby', 'gem, bundler'),
('Package-Managers', 'Go', 'go mod'),
('Package-Managers', 'Rust', 'cargo'),
('Package-Managers', 'APK-Blocked', 'Use host system for APK package management');

-- Development Languages
INSERT OR REPLACE INTO environment_facts (category, fact, details) VALUES
('Languages', 'Node.js', 'v22.12.0 with npm 10.9.2'),
('Languages', 'PHP', '8.3 with composer'),
('Languages', 'Python', '3.13 with pip'),
('Languages', 'Ruby', '3.3 with bundler'),
('Languages', 'Go', '1.23'),
('Languages', 'Rust', 'Latest with cargo'),
('Languages', 'Deno', 'Runtime available in flow container');

-- Docker Environment
INSERT OR REPLACE INTO environment_facts (category, fact, details) VALUES
('Docker-Environment', 'Container-Type', 'claude-flow with Playwright and testing tools'),
('Docker-Environment', 'Working-Directory', '/var/www/html'),
('Docker-Environment', 'User', 'claude (uid 1010)'),
('Docker-Environment', 'Host-Access', 'Check /etc/hosts for host mappings - dynamically configured at startup'),
('Docker-Environment', 'Volume', 'claude-flow-data for persistence'),
('Docker-Environment', 'Platform', 'Linux Alpine');

-- Container Info
INSERT OR REPLACE INTO environment_facts (category, fact, details) VALUES
('Container-Info', 'Type', 'You are INSIDE the claude-flow container'),
('Container-Info', 'Purpose', 'Development and testing environment with Playwright'),
('Container-Info', 'Note', 'Docker commands are for HOST use only, not from inside container');

-- Important Paths
INSERT OR REPLACE INTO environment_facts (category, fact, details) VALUES
('Paths', 'Working-Directory', '/var/www/html - Your project is mounted here'),
('Paths', 'CRITICAL-NOTE', '/var/www/html contains YOUR PROJECT files, not claude-docker files'),
('Paths', 'Claude-Home', '/home/claude'),
('Paths', 'MCP-Runtime', '/home/claude/mcp/ - MCP servers available at runtime (symlinked from /opt/mcp-assets)'),
('Paths', 'Claude-Config', '/home/claude/.claude.json'),
('Paths', 'Databases', '/home/claude/.claude/databases/'),
('Paths', 'Context-Files', '/home/claude/.claude/context/'),
('Paths', 'System-MCP', '/opt/mcp-assets/ - Read-only MCP files from Docker image');

-- Critical Reminders
INSERT OR REPLACE INTO environment_facts (category, fact, details) VALUES
('IMPORTANT', 'CLAUDE-MD', 'ALL this information comes from CLAUDE.md - READ IT at session start!'),
('IMPORTANT', 'No-Discovery', 'Do NOT rediscover what is already documented here'),
('IMPORTANT', 'Playwright-Dirs', 'ALWAYS use playwright/tests/, playwright/results/, playwright/report/'),
('IMPORTANT', 'Check-First', 'Query this database BEFORE searching for environment info');

-- Add metadata
INSERT OR REPLACE INTO environment_facts (category, fact, details) VALUES
('Metadata', 'Database-Purpose', 'Pre-cached environment facts from CLAUDE.md to prevent rediscovery'),
('Metadata', 'Created-During', 'Docker image build process'),
('Metadata', 'Query-Command', 'SELECT * FROM environment_facts WHERE category = ? OR fact LIKE ?');