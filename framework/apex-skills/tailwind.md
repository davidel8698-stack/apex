# Tailwind CSS Patterns for APEX

## Conventions
- Utility-first: prefer utilities over custom CSS
- Component extraction: only when pattern repeats 3+ times
- Config: tailwind.config.ts for theme extensions
- Dark mode: class strategy with dark: prefix

## Anti-Patterns — NEVER
- Never use @apply in component files (only in globals.css for base styles)
- Never mix Tailwind with inline styles
- Never hardcode colors — use theme tokens (text-primary, bg-background)
- Never use arbitrary values ([23px]) when a token exists (p-6)

## Responsive Pattern
```html
<div class="flex flex-col md:flex-row gap-4 p-4 md:p-6">
  <main class="flex-1">...</main>
  <aside class="w-full md:w-64">...</aside>
</div>
```

## Common Gotchas
- Purge: ensure content paths cover all template files
- Dynamic classes: never concatenate class names dynamically (use clsx/cn)
- Typography: use prose class for markdown/rich content