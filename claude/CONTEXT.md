Pr# Claude Code Context

This project includes comprehensive reference documentation for Tailwind CSS v4.1 and DaisyUI.

## Available Context Files

### Tailwind CSS v4.1
- **MCP Context**: `context/tailwind-v4.1.mcp.json`
- **Complete Classes Reference**: `context/tailwind-complete-classes.html`
- **Documentation**: `context/tailwind-v4.1-mcp-docs.html`

### DaisyUI
- **MCP Context**: `context/daisyui.mcp.json`
- **Complete Components Reference**: `context/daisyui-complete-components.html`

### Configuration
- **Safelist Config**: `context/tailwind.safelist.config.js`

## Key Information

### Tailwind CSS v4.1 Features
- Oxide engine for 10x faster builds
- Lightning CSS integration
- Native cascade layers support
- Built-in container queries
- Enhanced color system with automatic shades
- Zero-configuration setup
- Native CSS variables for all utilities
- Improved TypeScript support
- Optimized JIT compiler performance

### DaisyUI Features
- 50+ ready-to-use components
- 30+ built-in themes
- Semantic component classes
- Full Tailwind CSS compatibility
- No JavaScript required
- Accessibility compliant (WCAG 2.1)
- RTL support
- Responsive by default

## Usage Instructions

### Including All Classes in Production

To ensure all Tailwind and DaisyUI classes are available in your production build, include the context files in your `tailwind.config.js`:

```javascript
module.exports = {
  content: [
    './src/**/*.{html,js,jsx,ts,tsx}',
    './context/tailwind-complete-classes.html',
    './context/daisyui-complete-components.html'
  ],
  plugins: [
    require('daisyui')
  ]
}
```

### Using the Safelist Configuration

For dynamic class generation, use the safelist configuration:

```javascript
const safelistConfig = require('./context/tailwind.safelist.config.js');
module.exports = safelistConfig;
```

## Quick Reference

### Tailwind CSS v4.1 Installation
```bash
npm install tailwindcss@^4.1.0
```

### DaisyUI Installation
```bash
npm install -D daisyui@latest
```

### Common Patterns

#### Responsive Design
- Breakpoints: `sm:` `md:` `lg:` `xl:` `2xl:`
- Container queries: `@container` `@sm` `@md` `@lg` `@xl`

#### State Modifiers
- Interactive: `hover:` `focus:` `active:`
- Dark mode: `dark:`
- Group/Peer: `group-hover:` `peer-checked:`

#### DaisyUI Components
- Buttons: `btn btn-primary btn-secondary btn-accent`
- Cards: `card card-body card-title card-actions`
- Modals: `modal modal-box modal-backdrop`
- Forms: `input select textarea checkbox radio toggle`
- Alerts: `alert alert-info alert-success alert-warning alert-error`

## Framework Compatibility
- React, Vue, Angular, Svelte
- Next.js, Nuxt, Remix, Astro
- Vite, Laravel, Rails
- Node.js ≥ 18.0.0

## Resources
- [Tailwind CSS Docs](https://tailwindcss.com/docs)
- [DaisyUI Docs](https://daisyui.com)
- [Tailwind Play](https://play.tailwindcss.com)
- [GitHub - Tailwind](https://github.com/tailwindlabs/tailwindcss)
- [GitHub - DaisyUI](https://github.com/saadeghi/daisyui)