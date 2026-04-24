---
description: UI verification pass against 6-Pillar Design Contract.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## PURPOSE
Verification-only pass that checks implemented UI work against the 6-Pillar Design Contract.
Does NOT re-run the frontend-specialist agent — this is a post-execution audit.

Use /apex:ui-phase to execute UI work. Use this command to verify after execution.

## GUARD
If no .apex/STATE.json: "❌ No APEX project. Run /apex:start first." STOP.
Read STATE.json → current_phase.
If no RESULT.json files in current phase: "❌ No completed work to review." STOP.

## 6-PILLAR VERIFICATION

For each completed task in the current phase, scan the changed files for pillar compliance:

### Pillar 1: Responsive Layout (320px–2560px)
- Search for: media queries, breakpoint definitions, responsive CSS classes (flex, grid, container queries)
- Red flag: fixed-width containers (width: 1200px without max-width), pixel-only sizing without relative units
- Verdict: PASS if responsive patterns found | WARN if no responsive patterns in UI files | N/A if no UI files

### Pillar 2: Accessibility (WCAG 2.1 AA)
- Search for: aria-label, aria-describedby, role= attributes, alt= on images, semantic HTML (nav, main, article, aside)
- Red flag: img without alt, button without accessible name, div with onClick (should be button)
- Verdict: PASS if accessibility patterns found | WARN if red flags detected | N/A if no UI files

### Pillar 3: State Coverage (loading/error/empty/populated)
- Search for: loading state patterns (isLoading, Spinner, Skeleton), error boundaries, empty state UI, fallback components
- Red flag: data fetch without loading indicator, no error handling in async operations
- Verdict: PASS if state patterns found | WARN if incomplete coverage | N/A if no data-fetching components

### Pillar 4: Keyboard Navigation
- Search for: onKeyDown, tabIndex, focus management, focus-visible CSS, keyboard event handlers
- Red flag: onClick without onKeyDown on non-button elements, tabIndex=-1 on interactive elements
- Verdict: PASS if keyboard patterns found | WARN if red flags detected | N/A if no interactive elements

### Pillar 5: Form Validation UX
- Search for: onBlur validation, inline error messages, form error state management, required attributes
- Red flag: form submit without validation, alert() for errors, no error messages near fields
- Verdict: PASS if validation patterns found | WARN if forms exist without validation | N/A if no forms

### Pillar 6: Performance Budget
- Search for: lazy loading (React.lazy, dynamic import), image optimization (next/image, srcset, loading="lazy"), code splitting
- Red flag: large bundle imports without code splitting, synchronous loading of heavy assets
- Verdict: PASS if performance patterns found | WARN if heavy assets without optimization | N/A if no performance-sensitive code

## REPORT FORMAT

```
═══════════════════════════════════════
  APEX UI REVIEW — 6-Pillar Audit
  Phase: {current_phase}
═══════════════════════════════════════

  Pillar 1 (Responsive):    {PASS|WARN|N/A}  {detail}
  Pillar 2 (Accessibility): {PASS|WARN|N/A}  {detail}
  Pillar 3 (State Coverage):{PASS|WARN|N/A}  {detail}
  Pillar 4 (Keyboard Nav):  {PASS|WARN|N/A}  {detail}
  Pillar 5 (Form UX):       {PASS|WARN|N/A}  {detail}
  Pillar 6 (Performance):   {PASS|WARN|N/A}  {detail}

  Overall: {N}/6 pillars passed
  Files scanned: {N}
═══════════════════════════════════════
```

## OUTPUT

Display report to user.
If any pillar is WARN: "⚠️ {N} pillar(s) need attention. Run /apex:ui-phase to address."
If all pillars PASS or N/A: "✅ All applicable pillars pass."

## ERROR HANDLING
- If no UI files found in changed files: "ℹ️ No UI files detected in this phase. All pillars N/A."
- If grep/glob fails: mark that pillar as "SKIP — scan error" and continue.
</context>
