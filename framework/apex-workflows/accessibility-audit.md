# Workflow: Accessibility Audit

## Goal
Audit and remediate an existing web application for WCAG 2.1 AA compliance. Covers semantic HTML, keyboard navigation, screen reader support, color contrast, and automated/manual testing.

## Prerequisites
- Existing web application with rendered UI
- Access to browser developer tools
- Screen reader available for manual testing (VoiceOver, NVDA, or JAWS)

## Phases

### Phase 1: Automated Audit & Triage
- Run automated accessibility scanner (axe-core, Lighthouse, or pa11y) on all pages
- Categorize findings by severity: critical (blocks usage), major (degrades experience), minor (best practice)
- Audit semantic HTML: headings hierarchy (h1→h2→h3), landmark regions (nav, main, aside, footer)
- Check all images for alt text (decorative images get `alt=""`)
- Check all form inputs for associated labels (`<label for>` or `aria-label`)
- Verify: automated scanner runs on all pages; findings documented with severity

### Phase 2: Keyboard & Focus Management
- Test full keyboard navigation (Tab, Shift+Tab, Enter, Escape, Arrow keys)
- Ensure visible focus indicators on all interactive elements
- Fix focus traps in modals, dropdowns, and popups (Escape closes, focus returns)
- Add skip navigation link ("Skip to main content")
- Ensure logical tab order matches visual layout
- Add `aria-live` regions for dynamic content updates
- Verify: every interactive element reachable by keyboard; no focus traps; skip link works

### Phase 3: Visual & Screen Reader Remediation
- Check color contrast ratios (4.5:1 for normal text, 3:1 for large text)
- Ensure information is not conveyed by color alone (add icons, patterns, or text)
- Add ARIA roles and properties where semantic HTML is insufficient
- Test with screen reader: all content announced correctly, interactive elements have roles
- Ensure error messages are programmatically associated with their inputs
- Add `prefers-reduced-motion` media query for animations
- Verify: contrast ratios pass; screen reader announces all content correctly; animations respect motion preferences

## Skills Required
- Frontend framework skill (react, nextjs, vue, etc.)
- Accessibility (a11y) expertise

## Security Invariants
- Accessibility fixes MUST NOT remove or bypass existing security controls
- ARIA attributes MUST NOT expose sensitive data to assistive technology
- Skip links MUST NOT bypass authentication or authorization checks
