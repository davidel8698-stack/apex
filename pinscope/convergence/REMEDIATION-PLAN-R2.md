# PinScope Remediation Plan — PS-R2

> Per `framework/docs/REMEDIATION-STYLE.md` — content anchors, five sections.
> Scope: runtime foundation (Cluster B) + AC-030 + AC-091.

---

## Remediation R-201 — Runtime primitives

**Linked finding:** F-2-02, F-2-03 (shared dependency)
**Severity:** P1
**Spec anchor:** "Pin badge strategy" (SPEC §7.2), "constants.ts" (SPEC §5).

### Ecosystem analysis
Pure, React-free modules every runtime file depends on: shared constants
(HUD attribute name, z-index reservations) and the badge CSS string. The
DOM-walking logic of `useHoveredElement` is extracted here as pure functions
so it is unit-testable without `elementFromPoint` (which happy-dom cannot lay
out).

### Execution plan
**Files to create:** `src/runtime/constants.ts`,
`src/runtime/styles/badges.css.ts`, `src/runtime/utils/element-walker.ts`.
**Files that MUST remain untouched:** `src/plugin/**`, `src/types/**`.
**Order of operations:** `constants.ts` → `element-walker.ts` → `badges.css.ts`.
**Rollback trigger:** `tsc --noEmit` fails on `src/runtime/`.

### Acceptance criteria
- [ ] `escapeHud` / `findPinnedAncestor` exported and pure (AC-026/027 logic).
- [ ] `tsc --noEmit` clean.

### Dependencies
None — Wave 1 root.

### Risk assessment
Low. No React, no DOM layout.

---

## Remediation R-202 — Runtime hooks

**Linked finding:** F-2-03
**Severity:** P1
**Spec anchor:** "Hover detection hook" (SPEC §7.3), "useDevState" (SPEC §8.8).

### Ecosystem analysis
`useViewportSize`, `useHoveredElement` (composes `element-walker` +
`requestAnimationFrame` throttling + `elementFromPoint`), and `useDevState`
(state-override hook, also needed for the `src/index.ts` public API).

### Execution plan
**Files to create:** `src/runtime/hooks/useViewportSize.ts`,
`src/runtime/hooks/useHoveredElement.ts`, `src/runtime/hooks/useDevState.ts`.
**Order of operations:** `useViewportSize` → `useHoveredElement` → `useDevState`.
**Rollback trigger:** `tsc --noEmit` fails or hook tests fail.

### Acceptance criteria
- [ ] `useHoveredElement` walks to the nearest `[data-pin]` ancestor and
  escapes `[data-pinscope-ui]` (AC-026/027 via the walker).
- [ ] `useDevState` returns the dev override when set, else the real value.

### Dependencies
R-201.

### Risk assessment
Medium. `elementFromPoint` is browser-only; the testable logic is the walker.

---

## Remediation R-203 — Components: PinBadges + InfoPanel

**Linked finding:** F-2-02, F-2-04
**Severity:** P1
**Spec anchor:** "PinBadges" (SPEC §7.2), "InfoPanel" (SPEC §8.1).

### Ecosystem analysis
`PinBadges` injects the CSS-only badge `<style>`. `InfoPanel` renders the
Dimensions / Spacing / Typography sections from a `HoveredElement`. Both are
pure-render components driven by props — unit-testable for render logic; their
ACs (AC-023, AC-030) carry Playwright `verify:` and are NOT claimed this round.

### Execution plan
**Files to create:** `src/runtime/components/PinBadges.tsx`,
`src/runtime/components/InfoPanel.tsx`.
**Order of operations:** `PinBadges` → `InfoPanel`.
**Rollback trigger:** `tsc --noEmit` fails.

### Acceptance criteria
- [ ] `PinBadges` injects a `<style>` containing `[data-pin]::before`.
- [ ] `InfoPanel` renders width / height / padding / font-size from props.

### Dependencies
R-201.

### Risk assessment
Low–medium. React + TSX; `@types/react` required.

---

## Remediation R-204 — PinScope root + public API

**Linked finding:** F-2-01, F-2-05
**Severity:** P0
**Spec anchor:** "Root component" (SPEC §7.1), "Public API" (SPEC §15.5).

### Ecosystem analysis
`<PinScope/>` returns `null` in production / when disabled, else portals the
PS-R2 HUD subset (`PinBadges` + `InfoPanel`) into `document.body` under
`[data-pinscope-ui="root"]`. `src/index.ts` gains `PinScope` and `useDevState`.

### Execution plan
**Files to create:** `src/runtime/PinScope.tsx`.
**Files to modify:** `src/index.ts` (add two exports).
**Order of operations:** `PinScope.tsx` → `src/index.ts`.
**Rollback trigger:** AC-020/021/022 RTL tests fail.

### Acceptance criteria
- [ ] `null` under `NODE_ENV=production` (AC-020) and `enabled={false}` (AC-021).
- [ ] portals under `[data-pinscope-ui="root"]` in `document.body` (AC-022).
- [ ] `src/index.ts` re-exports `pinscope`, `PinScope`, `useDevState`, 4 types
  (AC-091).

### Dependencies
R-202, R-203.

### Risk assessment
Medium. `createPortal` under React Testing Library + happy-dom.

---

## Remediation R-205 — Test suite + DOM env + verification

**Linked finding:** F-2-01..F-2-05
**Severity:** P1
**Spec anchor:** "Testing Strategy" (SPEC §14).

### Ecosystem analysis
Runtime tests need React + a DOM environment. Add `react`, `react-dom`,
`@testing-library/react`, `happy-dom`, `@types/react`, `@types/react-dom`.
Vitest runs build-module tests in `node` and runtime tests in `happy-dom` via
`environmentMatchGlobs`.

### Execution plan
**Files to create:** `tests/unit/runtime/element-walker.test.ts`,
`tests/unit/runtime/pinscope.test.tsx`,
`tests/unit/runtime/components.test.tsx`,
`tests/unit/runtime/public-api.test.ts`.
**Files to modify:** `package.json` (devDependencies), `vitest.config.ts`.
**Rollback trigger:** `npm test` non-zero exit, or PS-R1's 86 tests regress.
**Circuit breaker:** no green `npm test` after 3 attempts → halt + escalate.

### Acceptance criteria
- [ ] AC-020, AC-021, AC-022, AC-026, AC-027, AC-091 verified passing.
- [ ] All PS-R1 tests still pass (no regression).

### Dependencies
R-201..R-204.

### Risk assessment
Medium. `npm install` of React + happy-dom; registry confirmed reachable.
