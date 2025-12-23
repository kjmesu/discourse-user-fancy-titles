# Discourse User Fancy Titles

A Discourse plugin that enables HTML rendering in user titles, allowing moderators to style titles with inline CSS and basic HTML formatting without needing admin-level CSS access.

## Features

- Render HTML in user titles
- Safe HTML sanitization to prevent XSS attacks
- Support for basic formatting: color, bold, italic
- Moderator-friendly (no CSS knowledge required beyond inline styles)

## Supported HTML

- **Tags**: `<span>`, `<strong>`, `<em>`, `<i>`, `<b>`
- **Attributes**: `style` (on `<span>` only)
- **CSS Properties**: `color`, `font-weight`, `font-style`

## Examples

```html
<span style="color: red;">The Syrup Master</span>
<span style="color: #4A90E2; font-weight: bold;">Blue Bold Title</span>
<strong>Bold Title</strong>
<em>Italic Title</em>
```

## Installation

1. Add this repository to your `plugins` folder
2. Rebuild your Discourse instance
3. Enable the plugin in Admin > Plugins

## Security

All user titles are sanitized before rendering to prevent XSS attacks. Only safe HTML tags and CSS properties are allowed.

## License

MIT
