# CSS Naming Guidelines

## Overview
This document defines the CSS naming conventions for the TYPO3 v11.5.41 project with Tailwind v4.1 integration, based on the brunnen.de/module design patterns.

## Naming Conventions

### 1. Component Prefixes
Based on the analysis of brunnen.de/module, the following prefixes are used:

- `csm_` - Content management system elements (legacy from brunnen.de)
- `typo3-` - TYPO3-specific elements
- `brunnen-` - Brand-specific components
- `tw-` - Custom Tailwind utilities

### 2. BEM-like Structure
For complex components, use a modified BEM approach:

```css
.brunnen-card {} /* Block */
.brunnen-card__header {} /* Element */
.brunnen-card--featured {} /* Modifier */
```

### 3. Tailwind Utility Classes
Tailwind v4.1 utilities should be used directly without prefixing:

```html
<!-- Correct -->
<div class="flex items-center justify-between p-4">

<!-- Avoid custom utility creation unless necessary -->
<div class="tw-custom-utility"> <!-- Only when Tailwind doesn't provide -->
```

### 4. TYPO3 Content Elements
All TYPO3 content elements maintain their standard classes with additional Tailwind utilities:

```html
<div class="typo3-content-element text-with-image flex flex-col lg:flex-row gap-6">
  <div class="typo3-content-element__text prose prose-lg">
  <div class="typo3-content-element__image aspect-video rounded-lg overflow-hidden">
</div>
```

### 5. Color Scheme Classes
Based on brunnen.de analysis, use semantic color names:

```css
/* Primary brand colors */
.text-brunnen-blue     /* #2563eb */
.text-brunnen-red      /* #dc2626 */
.text-brunnen-yellow   /* #fbbf24 */
.text-brunnen-green    /* #16a34a */

/* Neutral colors */
.text-brunnen-gray-50  /* #f9fafb */
.text-brunnen-gray-900 /* #111827 */
```

### 6. Responsive Prefixes
Use Tailwind's responsive prefixes consistently:

```html
<div class="w-full md:w-1/2 lg:w-1/3 xl:w-1/4">
```

### 7. State Classes
For interactive states, use Tailwind's state variants:

```html
<button class="hover:bg-brunnen-blue focus:ring-2 active:scale-95">
```

### 8. Layout Components
Grid and container classes following brunnen.de's 12-column system:

```css
.brunnen-container      /* Main container */
.brunnen-grid          /* 12-column grid */
.brunnen-grid-1        /* Single column */
.brunnen-grid-2        /* 2 columns */
/* ... up to brunnen-grid-12 */
```

### 9. Typography Classes
Following the clean, modern sans-serif approach:

```css
.brunnen-heading-1     /* Main headings */
.brunnen-heading-2     /* Section headings */
.brunnen-body          /* Body text */
.brunnen-caption       /* Image captions */
```

### 10. Image and Media Classes
For the image-centric design:

```css
.brunnen-image         /* Base image styling */
.brunnen-image-hero    /* Hero images (1600x900) */
.brunnen-image-thumb   /* Thumbnails */
.brunnen-gallery       /* Image galleries */
```

## File Organization

### Directory Structure
```
/var/www/html/
├── frontend/styles/tailwind/
│   ├── main.css           # Main entry point
│   ├── base/              # Reset and foundations
│   ├── components/        # Component styles
│   ├── utilities/         # Custom utilities
│   └── themes/            # Theme configurations
└── packages/tailwind/
    ├── config/            # Tailwind configuration
    ├── plugins/           # Custom plugins
    └── presets/           # TYPO3 presets
```

### Import Order
1. Tailwind base
2. TYPO3 compatibility styles
3. Brunnen theme variables
4. Component styles
5. Utility overrides

## Best Practices

### 1. Specificity Management
- Prefer utility classes over custom CSS
- Use `@layer` directives for custom styles
- Avoid `!important` except for critical overrides

### 2. Class Order
Follow this order for readability:
1. Layout (display, position)
2. Box model (width, padding, margin)
3. Typography
4. Visual (colors, borders)
5. Effects (transforms, transitions)
6. State variants (hover, focus)

### 3. Semantic HTML
Always use semantic HTML elements with appropriate ARIA attributes:

```html
<nav class="brunnen-nav" role="navigation" aria-label="Main navigation">
<main class="brunnen-content" role="main">
<aside class="brunnen-sidebar" role="complementary">
```

### 4. Performance Considerations
- Minimize custom CSS
- Use Tailwind's JIT mode
- Purge unused styles in production
- Optimize critical CSS path

### 5. Accessibility
- Ensure sufficient color contrast
- Include focus states for all interactive elements
- Use semantic class names for screen readers
- Test with keyboard navigation

## Migration from Old Site

When migrating styles from brunnen.de/module:

1. Identify the component type (navigation, content, media)
2. Map old classes to new naming convention
3. Apply appropriate Tailwind utilities
4. Add brand-specific classes only when needed
5. Test responsiveness across all breakpoints

## Version Compatibility

- **TYPO3**: v11.5.41
- **Tailwind CSS**: v4.1
- **Browsers**: Modern browsers (Safari 16.4+, Chrome 111+, Firefox 128+)

## Examples

### Navigation Component
```html
<nav class="brunnen-nav bg-white shadow-md">
  <div class="brunnen-container mx-auto px-4">
    <ul class="brunnen-nav__list flex items-center space-x-6">
      <li class="brunnen-nav__item">
        <a href="#" class="brunnen-nav__link text-brunnen-gray-700 hover:text-brunnen-blue transition-colors">
          Home
        </a>
      </li>
    </ul>
  </div>
</nav>
```

### Content Card
```html
<article class="brunnen-card bg-white rounded-lg shadow-sm hover:shadow-lg transition-shadow">
  <div class="brunnen-card__image aspect-video">
    <img src="image.jpg" alt="" class="w-full h-full object-cover">
  </div>
  <div class="brunnen-card__content p-6">
    <h3 class="brunnen-heading-2 text-brunnen-gray-900 mb-2">Title</h3>
    <p class="brunnen-body text-brunnen-gray-600">Description</p>
  </div>
</article>
```

## Compliance Checklist

- [ ] All custom classes follow naming conventions
- [ ] Tailwind utilities used appropriately
- [ ] TYPO3 compatibility maintained
- [ ] Responsive design implemented
- [ ] Accessibility standards met
- [ ] Performance optimized
- [ ] Documentation updated