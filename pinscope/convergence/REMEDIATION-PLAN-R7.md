# PinScope Remediation Plan — PS-R7

> Per `framework/docs/REMEDIATION-STYLE.md`. Scope: Cluster C visual overlays.
> Source of findings: `audit-findings-R7.md`.

---

## Remediation R-701 — Rulers + Crosshair + useViewportSize

**Linked finding:** F-7-01, F-7-02
**Severity:** P1
**Spec anchor:** "Rulers" (SPEC §8.2), "Crosshair" (SPEC §8.3), AC-034/AC-035.

### Ecosystem analysis
`useViewportSize` (deferred from PS-R2) feeds `Rulers`; `Rulers` renders
monospace tick labels at a fixed interval; `Crosshair` tracks `mousemove` and
hides over the HUD.

### Execution plan
**Files to create:** `src/runtime/hooks/useViewportSize.ts`,
`src/runtime/components/Rulers.tsx`, `src/runtime/components/Crosshair.tsx`.
**Rollback trigger:** AC-034/035 RTL tests fail.

### Acceptance criteria
- [ ] `Rulers` renders ticks at the configured interval, monospace (AC-034).
- [ ] `Crosshair` tracks the cursor and hides over `[data-pinscope-ui]` (AC-035).

### Dependencies
None — Wave 1.

### Risk assessment
Low.

---

## Remediation R-702 — GridOverlay

**Linked finding:** F-7-03
**Severity:** P1
**Spec anchor:** "GridOverlay — 4 modes" (SPEC §8.4), AC-036.

### Ecosystem analysis
`nextGridMode` implements the `off→pixel→baseline→column→spacing→off` cycle;
`GridOverlay` renders an SVG `<pattern>` per mode.

### Execution plan
**Files to create:** `src/runtime/components/GridOverlay.tsx`.
**Rollback trigger:** the cycle order or per-mode pattern test fails.

### Acceptance criteria
- [ ] `nextGridMode` cycles in SPEC order; each mode renders its pattern (AC-036).

### Dependencies
None.

### Risk assessment
Low.

---

## Remediation R-703 — MeasurementTool + VoidBadges

**Linked finding:** F-7-04, F-7-05
**Severity:** P2
**Spec anchor:** "MeasurementTool" (SPEC §8.7), "void elements" (SPEC §7.2),
AC-039/AC-024.

### Ecosystem analysis
`measure(a,b)` computes Δx/Δy/diagonal/gap; `MeasurementTool` captures two
clicks and renders the labels. `VoidBadges` renders a JS-overlay badge over
each void `[data-pin]` element (img/input/br), since `::before` cannot attach
to void elements.

### Execution plan
**Files to create:** `src/runtime/components/MeasurementTool.tsx`,
`src/runtime/components/VoidBadges.tsx`.
**Rollback trigger:** AC-039/AC-024 tests fail.

### Acceptance criteria
- [ ] `measure` math correct; two clicks render four labels (AC-039).
- [ ] `VoidBadges` renders an overlay carrying the matching pin id (AC-024).

### Dependencies
None.

### Risk assessment
Low.

---

## Remediation R-704 — Verification

**Linked finding:** F-7-01..F-7-05
**Severity:** P1

### Execution plan
**Files to create:** `tests/unit/runtime/overlays.test.tsx`.
**Verification:** `npm run typecheck` + `npx vitest run`.
**Rollback trigger:** any check fails or a PS-R1–R6 test regresses.
**Circuit breaker:** no green verification after 3 attempts → halt.

### Acceptance criteria
- [ ] AC-024, AC-034, AC-035, AC-036, AC-039 verified; 202 prior tests green.

### Dependencies
R-701, R-702, R-703.

### Risk assessment
Low.
