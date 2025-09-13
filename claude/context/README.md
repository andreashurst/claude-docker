# Tailwind CSS & DaisyUI Context Files

This directory contains comprehensive context and reference files for Tailwind CSS v4.1 and DaisyUI.

## Files

### MCP (Model Context Protocol) Files
- **`tailwind-v4.1.mcp.json`** - Tailwind CSS v4.1 context for AI models
- **`daisyui.mcp.json`** - DaisyUI component library context for AI models

### HTML Reference Files
- **`tailwind-complete-classes.html`** - Complete list of all Tailwind CSS v4.1 utility classes
- **`daisyui-complete-components.html`** - Complete list of all DaisyUI components and variants

### Configuration Files
- **`tailwind.safelist.config.js`** - Safelist configuration for production builds to ensure all classes are available

## Usage

### For Development
Include these files in your Tailwind configuration to ensure all classes are available:

```javascript
// tailwind.config.js
module.exports = {
  content: [
    './src/**/*.{html,js,jsx,ts,tsx}',
    './context/tailwind-complete-classes.html',
    './context/daisyui-complete-components.html'
  ],
  // ... rest of config
}
```

### For Dynamic Classes
Use the safelist configuration when you need dynamic class names:

```javascript
// tailwind.config.js
const safelistConfig = require('./context/tailwind.safelist.config.js');

module.exports = {
  ...safelistConfig,
  // Your custom configuration
}
```

### As Documentation
Open the HTML files in a browser to see all available classes and components visually.

## Notes
- These files ensure all Tailwind and DaisyUI classes are available in production builds
- Including all classes will increase your CSS bundle size significantly
- For production, consider using only the specific classes you need