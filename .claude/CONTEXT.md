# Discourse Plugins - Context Summary

## Project Overview
Two custom Discourse plugins have been developed to enhance user title functionality in posts:

1. **discourse-post-title-position** - Controls where user titles appear in post metadata
2. **discourse-user-fancy-titles** - Enables HTML/CSS styling in user titles

---

## Plugin 1: discourse-post-title-position

**Location:** `/home/coder/projects/discourse/discourse-post-title-position`

### Purpose
A theme component that allows administrators to control the positioning of user titles in the post header metadata area.

### Features
- Three positioning options:
  - `default` - Standard Discourse position (order: 30, after status)
  - `after_username` - Immediately after username on same line (order: 15)
  - `below_username` - On new line below username (order: 15, flex-basis: 100%)

### Key Implementation Details

**Files:**
- `settings.yml` - Theme component settings
- `common/common.scss` - CSS for title positioning
- `javascripts/discourse/api-initializers/post-title-position.js` - Adds HTML class for CSS targeting

**CSS Strategy:**
- Uses flexbox with `flex-wrap: wrap` on `.names.trigger-user-card`
- Controls layout via `order` property (increments of 10: 1, 10, 30, 40, 50)
- Title positioning uses order 15 to place between username (10) and status (30)
- `below_username` uses `flex-basis: 100%` to force line break
- `row-gap: 0.1em` provides minimal spacing for below_username option

**Element Orders:**
- `.poster-name-icons`: 0 (mobile), 60 (desktop)
- `.first` (username): 1
- `.second`: 10
- `.user-title` (after/below): 15
- `.user-title` (default): 30
- `.user-status-message-wrap`: 30
- `.user-badge-buttons`: 40

**Settings:**
```yaml
title_position:
  type: enum
  default: default
  choices: [default, after_username, below_username]
```

---

## Plugin 2: discourse-user-fancy-titles

**Location:** `/home/coder/projects/discourse/discourse-user-fancy-titles`

### Purpose
Allows moderators to use HTML and inline CSS in user titles without needing admin-level CSS access.

### Problem Solved
- Moderators can set user titles but cannot write CSS (admin-only)
- Users want styled/fun titles for engagement
- Solution: Allow HTML/CSS directly in the title field

### Security Implementation

**HTML Sanitization:**
- Strips all dangerous tags (`<script>`, `<iframe>`, `<img>`, etc.)
- Removes all event handlers (`onclick`, `onload`, etc.)
- Only allows specific safe tags and styles

**Allowed HTML:**
- Tags: `<span>`, `<strong>`, `<em>`, `<i>`, `<b>`
- Attributes: `style` (on `<span>` only)
- CSS Properties: `color`, `font-weight`, `font-style`

### Technical Implementation

**File:** `javascripts/discourse/api-initializers/user-fancy-titles.js`

**Approach:**
1. Registers a value transformer for `poster-name-user-title`
2. Sanitizes HTML using custom `sanitizeUserTitle()` function
3. Returns sanitized HTML wrapped with `htmlSafe()` from `@ember/template`

**Key Functions:**
```javascript
// Main transformer
api.registerValueTransformer("poster-name-user-title", ({ value }) => {
  if (!value) return value;
  const sanitized = sanitizeUserTitle(value);
  return htmlSafe(sanitized);
});

// Sanitization logic
function sanitizeUserTitle(html) {
  // Creates temp DOM element
  // Removes disallowed tags (preserves text content)
  // Strips disallowed attributes
  // Filters style properties to allowed list
  return temp.innerHTML;
}
```

### Usage Examples
```html
<span style="color: red;">The Syrup Master</span>
<span style="color: #4A90E2; font-weight: bold;">VIP Member</span>
<strong>Admin</strong>
<em>Moderator</em>
```

---

## Discourse Core Integration Points

### Value Transformers
Both plugins leverage Discourse's value transformer system:

**Location in Core:** `/home/coder/projects/discourse/discourse/frontend/discourse/app/components/post/meta-data/poster-name.gjs`

**How it works:**
- `applyValueTransformer("poster-name-user-title", this.user.title, { post, user })`
- Returns transformed value that gets rendered in template
- Multiple plugins can register transformers (they're chained)

**Template rendering (line 218-230):**
```handlebars
{{#if this.userTitle}}
  <span class={{concatClass "user-title" this.titleClassNames}}>
    {{#if (and this.user.primary_group_name @post.title_is_group)}}
      <GroupLink>{{this.userTitle}}</GroupLink>
    {{else}}
      {{this.userTitle}}
    {{/if}}
  </span>
{{/if}}
```

### DOM Structure
```html
<div class="topic-meta-data">
  <div class="names trigger-user-card">
    <span class="first username">Username</span>
    <span class="user-title">Title Here</span>
    <div class="user-status-message-wrap">...</div>
    <div class="user-badge-buttons">...</div>
    <div class="poster-name-icons">...</div>
  </div>
</div>
```

---

## Development Notes

### discourse-post-title-position
- Originally had 5 options (after_username, after_status, after_badges, after_icons, below_username)
- Reduced to 3 options (default, after_username, below_username) for simplicity
- All comments removed from CSS per user request
- Initially used decimal order values (2.5, 4.5) but switched to whole numbers (15, 25, 45, etc.)
- `below_username` was tricky - tried multiple approaches before settling on `flex-basis: 100%` with `row-gap: 0.1em`

### discourse-user-fancy-titles
- Created as separate plugin (not part of post-title-position)
- User chose "Basic formatting only" (color, bold, italic) over extended or full CSS
- Sanitization is critical for security - XSS prevention
- Plain text titles still work (backward compatible)

---

## File Locations Reference

### discourse-post-title-position
```
/home/coder/projects/discourse/discourse-post-title-position/
├── about.json
├── LICENSE
├── README.md
├── settings.yml
├── common/
│   └── common.scss
└── javascripts/
    └── discourse/
        └── api-initializers/
            └── post-title-position.js
```

### discourse-user-fancy-titles
```
/home/coder/projects/discourse/discourse-user-fancy-titles/
├── about.json
├── LICENSE
├── README.md
└── javascripts/
    └── discourse/
        └── api-initializers/
            └── user-fancy-titles.js
```

---

## Future Considerations

### Potential Enhancements
- Add plugin setting to toggle HTML rendering on/off
- Add more CSS properties (background-color, text-decoration, font-size)
- Cache sanitized titles for performance
- Add admin UI for testing sanitization
- Support for custom emoji/icons in titles

### Known Limitations
- HTML parsing on every title render (performance concern for large topics)
- No support for images or links in titles
- Limited to inline styles (no external classes)
- Moderators need basic HTML knowledge

---

## Testing Checklist

### discourse-post-title-position
- [ ] Test all three positions (default, after_username, below_username)
- [ ] Verify on mobile and desktop
- [ ] Check with/without user status messages
- [ ] Test with group-linked titles
- [ ] Verify spacing/gaps are correct

### discourse-user-fancy-titles
- [ ] Plain text titles still work
- [ ] `<span style="color: red;">Title</span>` renders red
- [ ] XSS attempts are blocked: `<script>alert('xss')</script>`
- [ ] Event handlers stripped: `<span onclick="alert()">Title</span>`
- [ ] Dangerous tags removed: `<iframe>`, `<img>`, `<a>`
- [ ] Multiple styles work: `color: blue; font-weight: bold;`
- [ ] Disallowed styles filtered: `background-image`, `position`

---

## Git History Notes

### discourse-post-title-position
- Started with badge-style box around titles (border, background, padding)
- Removed box styling for `below_username` option (plain text)
- Simplified to whole number order values
- Reduced from 5 options to 3

### discourse-user-fancy-titles
- Created fresh as standalone plugin
- No connection to post-title-position plugin
- Single feature: HTML rendering with sanitization
