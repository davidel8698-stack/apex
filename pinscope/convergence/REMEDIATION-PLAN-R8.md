# PinScope Remediation Plan — PS-R8

> Per `framework/docs/REMEDIATION-STYLE.md`. Scope: Cluster C control surface.
> Source of findings: `audit-findings-R8.md`.

## Remediation R-801 — SelectionManager
**Linked finding:** F-8-01 · **Severity:** P1 · **Spec anchor:** "SelectionManager"
(SPEC §8.9), AC-041.
### Ecosystem analysis
Tracks `selectedPin`/`isLocked`/history, moves the `data-pin-selected`
attribute, and mirrors selection to the URL hash `#select=e_N` — restored on
construction (= reload).
### Execution plan
**Create:** `src/runtime/managers/SelectionManager.ts`. **Rollback:** AC-041
test fails.
### Acceptance criteria
- [ ] `select` sets `#select=e_N`; a fresh instance restores it locked (AC-041).
### Dependencies / Risk
None / Low.

## Remediation R-802 — TopBar + StatePanel
**Linked finding:** F-8-02, F-8-04 · **Severity:** P2 · **Spec anchor:** "TopBar"
(§8.5), "StatePanel" (§8.8), AC-037/AC-040.
### Ecosystem analysis
`TopBar` shows viewport / grid mode / state override / live pin count
(`querySelectorAll('[data-pin]').length`). `StatePanel` writes
`[data-state-override]` onto `<html>`.
### Execution plan
**Create:** `src/runtime/components/TopBar.tsx`, `components/StatePanel.tsx`.
**Rollback:** AC-037/040 tests fail.
### Acceptance criteria
- [ ] TopBar's four fields render; pin count equals the DOM count (AC-037).
- [ ] StatePanel sets `<html data-state-override>` (AC-040).
### Dependencies / Risk
None / Low.

## Remediation R-803 — CommandBar
**Linked finding:** F-8-03 · **Severity:** P1 · **Spec anchor:** "CommandBar"
(§8.6), AC-038.
### Ecosystem analysis
An input that focuses on `Cmd/Ctrl+K` and `/`, walks history with arrows, and
blurs on `Esc`.
### Execution plan
**Create:** `src/runtime/components/CommandBar.tsx`. **Rollback:** AC-038 fails.
### Acceptance criteria
- [ ] `Cmd/Ctrl+K` focuses the input; `Esc` blurs it; arrows walk history (AC-038).
### Dependencies / Risk
None / Low–medium (focus tracking in happy-dom).

## Remediation R-804 — Keyboard shortcuts + touch
**Linked finding:** F-8-05, F-8-06 · **Severity:** P2 · **Spec anchor:**
"Keyboard shortcuts" (§8.11), "mobile/touch" (§12), AC-043/AC-064.
### Ecosystem analysis
`useKeyboardShortcuts` + a `matchShortcut` table for the §8.11 set; a
`LongPressDetector` (tap vs 500ms long-press) + `isCompactViewport` (< 768px).
### Execution plan
**Create:** `src/runtime/hooks/useKeyboardShortcuts.ts`,
`src/runtime/utils/long-press.ts`. **Rollback:** AC-043/064 tests fail.
### Acceptance criteria
- [ ] ≥95% of the §8.11 shortcuts dispatch their handler (AC-043).
- [ ] `LongPressDetector` distinguishes tap from 500ms hold; `isCompactViewport`
  flags < 768px (AC-064).
### Dependencies / Risk
None / Low.

## Remediation R-805 — Verification
**Linked finding:** F-8-01..F-8-06 · **Severity:** P1
### Execution plan
**Create:** `tests/unit/runtime/controls.test.tsx`,
`tests/unit/runtime/selection.test.ts`, `tests/unit/runtime/shortcuts.test.tsx`,
`tests/unit/long-press.test.ts`. **Verification:** `npm run typecheck` +
`npx vitest run`. **Circuit breaker:** no green after 3 attempts → halt.
### Acceptance criteria
- [ ] AC-037/038/040/041/043/064 verified; 213 prior tests still green.
### Dependencies / Risk
R-801..R-804 / Low.
