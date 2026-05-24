# PinScope Remediation Plan — PS-R6

> Per `framework/docs/REMEDIATION-STYLE.md`. Scope: edge-case behaviours
> (SPEC §12). Source of findings: `audit-findings-R6.md`.

---

## Remediation R-601 — Runtime-id MutationObserver

**Linked finding:** F-6-01
**Severity:** P2
**Spec anchor:** "Dynamic content (MutationObserver assigns `e_r{N}` runtime
IDs)" (SPEC §12), AC-025.

### Ecosystem analysis
`RuntimePinObserver` watches `childList`/`subtree` and assigns `e_r{N}` ids to
elements added after build time, so dynamically-rendered UI is still pinnable.
Distinct namespace (`e_r` vs build-time `e_`) keeps the two id spaces separate.

### Execution plan
**Files to create:** `src/runtime/managers/RuntimePinObserver.ts`.
**Order:** `assign()` (sync) → `start()`/`stop()` (observer).
**Rollback trigger:** AC-025 integration test fails.

### Acceptance criteria
- [ ] An element added at runtime receives `data-pin` starting `e_r` (AC-025).

### Dependencies
None.

### Risk assessment
Low. happy-dom implements `MutationObserver`.

---

## Remediation R-602 — Shadow DOM + SVG + throttle utilities

**Linked finding:** F-6-02, F-6-03, F-6-04
**Severity:** P2
**Spec anchor:** "Shadow DOM ... SVG (`getBBox`+`getCTM`) ... many elements
(throttle to 30fps > 500 elements, skip badges < 16×16)" (SPEC §12),
AC-060/062/065.

### Ecosystem analysis
Three pure-ish utilities: `shadow-dom.ts` marks shadow hosts `data-pin-shadow`;
`rect-math.ts` returns viewport-space rects, using `getBBox`+`getCTM` for SVG
graphics; `throttle.ts` provides a rAF-friendly throttle plus the heavy-page
thresholds and the small-badge-skip predicate.

### Execution plan
**Files to create:** `src/runtime/utils/shadow-dom.ts`,
`src/runtime/utils/rect-math.ts`, `src/runtime/utils/throttle.ts`.
**Order:** independent — any order.
**Rollback trigger:** any of AC-060/062/065 unit tests fail.

### Acceptance criteria
- [ ] Shadow hosts marked `data-pin-shadow`; `isShadowLimited` reflects it
  (AC-060).
- [ ] `elementRect` uses `getBBox`+`getCTM` for SVG, `getBoundingClientRect`
  otherwise (AC-062).
- [ ] `throttle` caps call rate; `shouldSkipBadge` skips < 16×16 (AC-065).

### Dependencies
None.

### Risk assessment
Low.

---

## Remediation R-603 — Verification

**Linked finding:** F-6-01..F-6-04
**Severity:** P1

### Execution plan
**Files to create:** `tests/unit/runtime/edge-cases.test.ts` (DOM: observer,
shadow), `tests/unit/edge-utils.test.ts` (rect-math, throttle).
**Verification:** `npm run typecheck` + `npx vitest run`.
**Rollback trigger:** any check fails or a PS-R1–R5 test regresses.
**Circuit breaker:** no green verification after 3 attempts → halt.

### Acceptance criteria
- [ ] AC-025, AC-060, AC-062, AC-065 verified; 192 prior tests still green.

### Dependencies
R-601, R-602.

### Risk assessment
Low.
