/**
 * Tailwind CSS v4.1 & DaisyUI Complete Safelist Configuration
 *
 * This configuration ensures all Tailwind and DaisyUI classes are available in production builds.
 * Use this when you need dynamic class names that can't be detected at build time.
 *
 * WARNING: This will significantly increase your CSS bundle size.
 * Only use specific patterns you need in production.
 */

module.exports = {
  content: [
    './src/**/*.{html,js,jsx,ts,tsx,vue}',
    './pages/**/*.{html,js,jsx,ts,tsx,vue}',
    './components/**/*.{html,js,jsx,ts,tsx,vue}',
    './app/**/*.{html,js,jsx,ts,tsx,vue}',
    // Include the reference files to ensure all classes are scanned
    './tailwind-complete-classes.html',
    './daisyui-complete-components.html'
  ],

  // Safelist specific patterns for dynamic classes
  safelist: [
    // Color utilities for all variants
    {
      pattern: /^(bg|text|border|ring|divide|placeholder|from|via|to|decoration|outline|accent|caret|fill|stroke)-(inherit|current|transparent|black|white)/,
    },
    {
      pattern: /^(bg|text|border|ring|divide|placeholder|from|via|to|decoration|outline|accent|caret|fill|stroke)-(slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-(50|100|200|300|400|500|600|700|800|900|950)/,
    },

    // Spacing utilities
    {
      pattern: /^(p|m|px|py|pt|pr|pb|pl|mx|my|mt|mr|mb|ml|space-x|space-y|gap|gap-x|gap-y)-(0|px|0\.5|1|1\.5|2|2\.5|3|3\.5|4|5|6|7|8|9|10|11|12|14|16|20|24|28|32|36|40|44|48|52|56|60|64|72|80|96)/,
    },

    // Width/Height utilities
    {
      pattern: /^(w|h|min-w|min-h|max-w|max-h|size)-(0|px|0\.5|1|1\.5|2|2\.5|3|3\.5|4|5|6|7|8|9|10|11|12|14|16|20|24|28|32|36|40|44|48|52|56|60|64|72|80|96|auto|full|screen|min|max|fit)/,
    },
    {
      pattern: /^(w|h|size)-(1\/2|1\/3|2\/3|1\/4|2\/4|3\/4|1\/5|2\/5|3\/5|4\/5|1\/6|2\/6|3\/6|4\/6|5\/6|1\/12|2\/12|3\/12|4\/12|5\/12|6\/12|7\/12|8\/12|9\/12|10\/12|11\/12)/,
    },

    // Flexbox & Grid
    {
      pattern: /^(flex|grid-cols|grid-rows|col-span|row-span|col-start|col-end|row-start|row-end)-(1|2|3|4|5|6|7|8|9|10|11|12|auto|full|none)/,
    },

    // Border radius
    {
      pattern: /^rounded(-none|-sm|-md|-lg|-xl|-2xl|-3xl|-full)?$/,
    },
    {
      pattern: /^rounded-(t|r|b|l|tl|tr|br|bl|s|e|ss|se|es|ee)(-none|-sm|-md|-lg|-xl|-2xl|-3xl|-full)?$/,
    },

    // Shadows
    {
      pattern: /^shadow(-sm|-md|-lg|-xl|-2xl|-inner|-none)?$/,
    },

    // Opacity
    {
      pattern: /^(opacity|backdrop-opacity)-(0|5|10|15|20|25|30|35|40|45|50|55|60|65|70|75|80|85|90|95|100)/,
    },

    // Transforms
    {
      pattern: /^(scale|scale-x|scale-y)-(0|50|75|90|95|100|105|110|125|150)/,
    },
    {
      pattern: /^rotate-(0|1|2|3|6|12|45|90|180)/,
    },
    {
      pattern: /^(translate-x|translate-y)-(0|px|0\.5|1|1\.5|2|2\.5|3|3\.5|4|5|6|7|8|9|10|11|12|14|16|20|24|28|32|36|40|44|48|52|56|60|64|72|80|96|1\/2|1\/3|2\/3|1\/4|2\/4|3\/4|full)/,
    },

    // Transitions & Animations
    {
      pattern: /^(transition|duration|delay)-(0|75|100|150|200|300|500|700|1000)/,
    },
    {
      pattern: /^animate-(none|spin|ping|pulse|bounce)/,
    },

    // Typography
    {
      pattern: /^text-(xs|sm|base|lg|xl|2xl|3xl|4xl|5xl|6xl|7xl|8xl|9xl)/,
    },
    {
      pattern: /^font-(thin|extralight|light|normal|medium|semibold|bold|extrabold|black)/,
    },
    {
      pattern: /^(leading|tracking)-(none|tight|snug|normal|relaxed|loose)/,
    },

    // Filters
    {
      pattern: /^(blur|brightness|contrast|grayscale|hue-rotate|invert|saturate|sepia)-(0|50|75|90|95|100|105|110|125|150|200)?$/,
    },
    {
      pattern: /^backdrop-(blur|brightness|contrast|grayscale|hue-rotate|invert|saturate|sepia)-(0|50|75|90|95|100|105|110|125|150|200)?$/,
    },

    // Display & Position
    {
      pattern: /^(block|inline-block|inline|flex|inline-flex|grid|inline-grid|hidden|table|table-row|table-cell|contents|list-item|flow-root)$/,
    },
    {
      pattern: /^(static|fixed|absolute|relative|sticky)$/,
    },
    {
      pattern: /^(inset|top|right|bottom|left)-(0|px|0\.5|1|1\.5|2|2\.5|3|3\.5|4|5|6|7|8|9|10|11|12|14|16|20|24|28|32|36|40|44|48|52|56|60|64|72|80|96|auto|1\/2|1\/3|2\/3|1\/4|2\/4|3\/4|full)/,
    },

    // Z-index
    {
      pattern: /^z-(0|10|20|30|40|50|auto)/,
    },

    // Overflow
    {
      pattern: /^overflow(-x|-y)?-(auto|hidden|clip|visible|scroll)$/,
    },

    // DaisyUI Button variants
    {
      pattern: /^btn(-neutral|-primary|-secondary|-accent|-ghost|-link|-info|-success|-warning|-error|-outline|-active|-disabled|-lg|-md|-sm|-xs|-wide|-block|-circle|-square)?$/,
    },

    // DaisyUI Badge variants
    {
      pattern: /^badge(-neutral|-primary|-secondary|-accent|-ghost|-info|-success|-warning|-error|-outline|-lg|-md|-sm|-xs)?$/,
    },

    // DaisyUI Card variants
    {
      pattern: /^card(-side|-compact|-normal|-bordered)?$/,
    },

    // DaisyUI Alert variants
    {
      pattern: /^alert(-info|-success|-warning|-error)?$/,
    },

    // DaisyUI Input variants
    {
      pattern: /^(input|select|textarea|checkbox|radio|toggle|range|file-input)(-bordered|-ghost|-primary|-secondary|-accent|-info|-success|-warning|-error|-lg|-md|-sm|-xs)?$/,
    },

    // DaisyUI Loading variants
    {
      pattern: /^loading-(spinner|dots|ring|ball|bars|infinity)$/,
    },
    {
      pattern: /^loading-(xs|sm|md|lg)$/,
    },

    // DaisyUI Modal variants
    {
      pattern: /^modal(-open|-bottom|-middle)?$/,
    },

    // DaisyUI Dropdown variants
    {
      pattern: /^dropdown(-end|-top|-bottom|-left|-right|-hover|-open)?$/,
    },

    // DaisyUI Tab variants
    {
      pattern: /^tabs(-boxed|-bordered|-lifted)?$/,
    },
    {
      pattern: /^tab(-active|-disabled)?$/,
    },

    // DaisyUI Toast positions
    {
      pattern: /^toast-(start|center|end|top|middle|bottom)?$/,
    },

    // DaisyUI Tooltip variants
    {
      pattern: /^tooltip(-open|-top|-bottom|-left|-right|-primary|-secondary|-accent|-info|-success|-warning|-error)?$/,
    },

    // DaisyUI Mask shapes
    {
      pattern: /^mask-(squircle|heart|hexagon|hexagon-2|decagon|pentagon|diamond|square|circle|parallelogram|parallelogram-2|parallelogram-3|parallelogram-4|star|star-2|triangle|triangle-2|triangle-3|triangle-4|half-1|half-2)?$/,
    },

    // DaisyUI themes
    'data-theme',
    '[data-theme="light"]',
    '[data-theme="dark"]',
    '[data-theme="cupcake"]',
    '[data-theme="bumblebee"]',
    '[data-theme="emerald"]',
    '[data-theme="corporate"]',
    '[data-theme="synthwave"]',
    '[data-theme="retro"]',
    '[data-theme="cyberpunk"]',
    '[data-theme="valentine"]',
    '[data-theme="halloween"]',
    '[data-theme="garden"]',
    '[data-theme="forest"]',
    '[data-theme="aqua"]',
    '[data-theme="lofi"]',
    '[data-theme="pastel"]',
    '[data-theme="fantasy"]',
    '[data-theme="wireframe"]',
    '[data-theme="black"]',
    '[data-theme="luxury"]',
    '[data-theme="dracula"]',
    '[data-theme="cmyk"]',
    '[data-theme="autumn"]',
    '[data-theme="business"]',
    '[data-theme="acid"]',
    '[data-theme="lemonade"]',
    '[data-theme="night"]',
    '[data-theme="coffee"]',
    '[data-theme="winter"]',
    '[data-theme="dim"]',
    '[data-theme="nord"]',
    '[data-theme="sunset"]',

    // Responsive modifiers
    {
      pattern: /^(sm|md|lg|xl|2xl):/,
      variants: ['sm', 'md', 'lg', 'xl', '2xl'],
    },

    // State modifiers
    {
      pattern: /^(hover|focus|focus-within|focus-visible|active|visited|target|first|last|only|odd|even|first-of-type|last-of-type|only-of-type|empty|disabled|enabled|checked|indeterminate|default|required|valid|invalid|in-range|out-of-range|placeholder-shown|autofill|read-only):/,
    },

    // Dark mode
    {
      pattern: /^dark:/,
    },

    // Group and peer modifiers
    {
      pattern: /^(group|peer)(-hover|-focus|-active|-visited|-disabled|-checked)?/,
    },

    // Container queries
    {
      pattern: /^@(container|sm|md|lg|xl|2xl|3xl|4xl|5xl|6xl|7xl):/,
    },

    // Arbitrary values - common patterns
    {
      pattern: /^\[.+\]$/,
    },

    // Important modifier
    {
      pattern: /^!/,
    },

    // Print modifier
    {
      pattern: /^print:/,
    },

    // Motion preferences
    {
      pattern: /^(motion-safe|motion-reduce):/,
    },

    // Contrast preferences
    {
      pattern: /^(contrast-more|contrast-less):/,
    },

    // Orientation
    {
      pattern: /^(portrait|landscape):/,
    },

    // RTL/LTR
    {
      pattern: /^(rtl|ltr):/,
    },

    // Aria modifiers
    {
      pattern: /^aria-(checked|disabled|expanded|hidden|pressed|readonly|required|selected):/,
    },

    // Data attribute modifiers
    {
      pattern: /^data-\[.+\]:/,
    },

    // Has modifier
    {
      pattern: /^has-\[.+\]:/,
    },
  ],

  theme: {
    extend: {
      // Add any custom theme extensions here
    },
  },

  plugins: [
    require('daisyui'),
  ],

  daisyui: {
    themes: true, // Enable all themes
    darkTheme: "dark",
    base: true,
    styled: true,
    utils: true,
    prefix: "",
    logs: false,
  },
};