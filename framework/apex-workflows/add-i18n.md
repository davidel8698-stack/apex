# Workflow: Add Internationalization (i18n)

## Goal
Add multi-language support to an existing application. Covers translation infrastructure, locale detection, content translation, and RTL support.

## Prerequisites
- Existing application with user-facing text
- Target languages identified (at minimum: primary language + one additional)
- i18n library selected (i18next, react-intl, vue-i18n, gettext, or framework-native)

## Phases

### Phase 1: i18n Infrastructure
- Install i18n library matching project stack
- Create translation file structure (`locales/en.json`, `locales/es.json`, etc.)
- Extract all hardcoded user-facing strings into translation keys
- Configure locale detection: URL prefix (`/en/`, `/es/`) or Accept-Language header or user preference
- Add language switcher UI component
- Configure default/fallback locale
- Verify: application renders in default locale; language switcher changes language; missing keys fall back to default

### Phase 2: Content Translation
- Translate all UI strings for target languages
- Handle pluralization rules per locale (one/few/many/other)
- Handle date, time, number, and currency formatting per locale
- Translate email templates and notification text
- Handle dynamic content (user-generated content is NOT translated — only UI chrome)
- Verify: all UI strings display correctly in each target language; dates and numbers formatted per locale

### Phase 3: RTL & Polish
- Add RTL (right-to-left) stylesheet support for Arabic, Hebrew, etc. (if applicable)
- Use CSS logical properties (`margin-inline-start` instead of `margin-left`)
- Test layout in RTL mode — icons, alignment, text direction
- Add locale to URL structure for SEO (`hreflang` tags, canonical URLs)
- Configure server-side rendering locale detection (if SSR)
- Verify: RTL layout renders correctly; SEO tags present; no broken layouts in any language

## Skills Required
- i18n library matching stack
- Frontend framework skill

## Security Invariants
- Translation files MUST NOT contain executable code (only strings)
- User-selected locale MUST be validated against allowed locales (prevent path traversal via locale param)
- Translated strings MUST be escaped when rendered in HTML (prevent XSS via translations)
