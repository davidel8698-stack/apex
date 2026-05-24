# Audit Findings — PS-R21

**Round:** 21
**Generated:** 2026-05-24T22:35:00Z
**ac-results-R21:** 62 PASS · 6 UNAVAILABLE · 1 MANUAL (AC-106 already CLOSED via attestation; provenance in `loop.json`)
**FAILs to re-confirm:** 0
**Regressions (STEP 4):** 0
**Investigation findings (STEP 5):** 3 CONFIRMED · 1 SUSPECTED

---

## STEP 1–4 — re-confirmation & regression scan

Independently re-ran every env-capable verify on the current tree:

| check | result |
|---|---|
| `npm test` (vitest) | 30 files · **309 tests pass** (+6 from R20's 303 — R-20-05 CommandBar Enter tests landed) |
| `npm run build` (tsc) | exit 0 |
| `npm run typecheck` (AC-084) | implied PASS by ac-verify |
| `cd examples/vite-react && npx vite build` (AC-010 / AC-074) | exit 0; rebuilt artifacts |
| `grep -rcE 'data-pin\|PinScope\|pinscope' examples/vite-react/dist` | `index.html: 0`, `assets/index-9fjr-cn8.js: 0` — **production-zero holds** |
| AC-090 fix (R21 cleanup) | `tests/unit/deployment.test.ts` all 10 cases PASS via `spawnSync` subprocess-import; Hebrew-cwd loader bypass works |
| AC-104 fix (R21 cleanup) | matrix path now `framework/modules/apex-frontend/agent.md` (2 hits, PASS) |
| AC-106 attestation | `loop.json.criteria['AC-106'].manual_attestation.verdict = "pass"`, by `ps-heal-orchestrator-R21` |

Every `closed_round=20` provenance entry still verifies PASS in `ac-results-R21.json`. **Zero regressions.**

---

## STEP 5 — investigation findings (4)

The R21 sweep continues the R20 dormant-mechanism pattern. R20 closed 3 such gaps (VoidBadges, RuntimePinObserver, Shift+P/C) by adding `PinScopeHud` wiring. This sweep finds **4 more utilities** that are implemented, unit-tested in isolation, and named by the spec — but never invoked by the assembled `<PinScope/>` HUD. Same false-PASS pattern; same fix shape.

### F-21-01 — CONFIRMED · P2 — Touch tap/long-press + responsive collapse dormant

**Axis:** 9 — Edge cases / dormant mechanism
**Current state:** `src/runtime/utils/long-press.ts` exports `LongPressDetector` (tap vs long-press @ `LONG_PRESS_MS=500`), `isCompactViewport(width)`, `MOBILE_BREAKPOINT=768` — all unit-tested in `tests/unit/long-press.test.ts` (AC-064 PASS, 3 tests). `PinScope.tsx` and every component file have **zero** `touchstart`/`touchend` handlers, never construct a `LongPressDetector`, never read `isCompactViewport`. In the shipped HUD: a tap does NOT select, a long-press does NOT lock, viewports < 768px do NOT collapse.
**Gap:** SPEC §12 (`mobile/touch (tap=select, long-press=lock, HUD collapsible < 768px)`) and AC-064 require these end-to-end in the running HUD. AC-064 PASSES because the verify is a vitest-tag on `long-press.test.ts` that constructs the detector directly — identical to the F-20-01/02 false-PASS pattern.
**re-read:**
```
grep -rn 'LongPressDetector|isCompactViewport|MOBILE_BREAKPOINT' src/runtime/
  -> sole hits inside src/runtime/utils/long-press.ts; zero src/ importer.
grep -rn 'touchstart|touchend|onTouch' src/runtime/
  -> ZERO matches.
# PinScope.tsx full read (353 lines): no touch listener, no LongPressDetector import, no responsive-collapse branch.
```

### F-21-02 — CONFIRMED · P2 — Shadow-DOM host marking dormant

**Axis:** 9 — Edge cases / dormant mechanism
**Current state:** `src/runtime/utils/shadow-dom.ts` exports `markShadowHosts(root)` which stamps every Shadow-DOM host with `data-pin-shadow`. `tests/unit/runtime/edge-cases.test.ts` (AC-060 PASS, 2 tests) calls it directly. `PinScope.tsx` never imports nor calls it. In the shipped HUD, a host that mounts a Shadow-DOM element never receives `data-pin-shadow`, so InfoPanel cannot report "limited inspection" as §12 requires.
**Gap:** SPEC §12 (`Shadow DOM (mark data-pin-shadow, limited inspection)`) and AC-060 require the host-marking to be live in the HUD. The utility is dead code in the runtime tree's perspective; same false-PASS pattern.
**re-read:**
```
grep -rn 'markShadowHosts|SHADOW_ATTR|shadow-dom' src/runtime/
  -> sole hits inside src/runtime/utils/shadow-dom.ts; no src/ consumer.
grep -rn 'markShadowHosts' tests/
  -> only edge-cases.test.ts:48,57 — direct call.
# PinScope.tsx full read: only useEffect is the queueMicrotask RuntimePinObserver; no shadow-host sweep.
```

### F-21-03 — CONFIRMED · P3 — Heavy-page throttle + skip-small-badge dormant

**Axis:** 10 — Performance / dormant mechanism
**Current state:** `src/runtime/utils/throttle.ts` defines `isHeavyPage(pinCount)` (>500), `shouldSkipBadge(w,h)` (<16px), `HEAVY_PAGE_INTERVAL_MS=33` (~30fps), and a `throttle(fn, ms)` leading+trailing — all unit-tested under AC-065 (PASS, 3 tests). But `src/runtime/hooks/useHoveredElement.ts` uses **only** `requestAnimationFrame` (~60fps); it never reads `isHeavyPage(documentPinCount)` and never switches to the 30fps throttle on heavy pages. `PinBadges.tsx` is pure CSS-`::before` that renders for ALL badges regardless of size; it never reads `shouldSkipBadge`.
**Gap:** SPEC §12 (`many elements (throttle to 30fps > 500 elements, skip badges < 16×16, data-pin-ignore opt-out)`) and AC-065 require BOTH switches live in the HUD. P3 (not P2) because AC-065 is itself P2-severity, the real-world impact is graceful-degradation on extreme pages rather than a broken capability, and `data-pin-ignore` IS honored by the AST transform.
**re-read:**
```
grep -rn 'isHeavyPage|shouldSkipBadge|HEAVY_PAGE_THRESHOLD|HEAVY_PAGE_INTERVAL_MS' src/
  -> sole hits inside src/runtime/utils/throttle.ts; ZERO src/ consumer.
grep -rn 'throttle\(|import.*throttle' src/
  -> ZERO matches — the throttle() function is never imported by any other src/ module.
# useHoveredElement.ts full read (54 lines): only rAF; no isHeavyPage gate.
```

### F-21-04 — SUSPECTED · P3 — Cross-origin iframe outline overlay dormant

**Axis:** 9 — Edge cases / dormant mechanism
**Current state:** `src/runtime/utils/iframe-overlay.ts` implements `markCrossOriginFrames(root)` (sweeps `<iframe>`s, draws dashed outline + label overlay for cross-origin frames), `isCrossOriginFrame`, `isIframeLimited` — all unit-tested in `tests/unit/runtime/iframe-overlay.test.ts`. `PinScope.tsx` never calls `markCrossOriginFrames`. In the shipped HUD, cross-origin iframes are NOT outlined-and-labeled.
**Gap:** SPEC §12 (`iframes (same-origin inject, cross-origin outline only)`) and AC-061 require the overlay live in the HUD. **SUSPECTED** (not CONFIRMED) and P3 because AC-061 is env=browser BLOCKED (cannot be machine-verified without two real origins), the AC's own severity is P3, and the implementation IS sound — the wiring gap mirrors F-21-01/02 but is masked by the env block rather than by a unit test. Planner-level note: a single `PinScope.tsx` useEffect can fold F-21-01 (touch + responsive) + F-21-02 (shadow sweep) + F-21-04 (iframe sweep) into one lifecycle-bound DOM setup.
**re-read:**
```
grep -rn 'markCrossOriginFrames|isCrossOriginFrame|isIframeLimited|IFRAME_ATTR' src/
  -> sole hits inside src/runtime/utils/iframe-overlay.ts; no src/ consumer.
# PinScope.tsx full read: no iframe-overlay import, no markCrossOriginFrames call.
```

---

## Blocked (env-only, 6)

| AC | severity | reason |
|---|---|---|
| AC-023 | P0 | env `browser` unavailable — Playwright `::before` content read needs a browser |
| AC-030 | P1 | env `browser` unavailable — Playwright InfoPanel hover assertion |
| AC-061 | P3 | manual / `browser` — cross-origin iframe needs two real origins (also see F-21-04: wiring also absent) |
| AC-063 | P3 | manual / `browser` — `@media print` rendering needs a browser print engine |
| AC-082 | P1 | manual / `browser` — Playwright integration suite |
| AC-083 | P3 | manual / `browser` — visual-regression screenshots |

AC-106 is **NOT** in this list — it CLOSED in R21 via manual-attest (`loop.json.criteria['AC-106'].manual_attestation`); ac-verify reports it stateless but the loop's provenance ledger holds the CLOSED status.

---

## Watchlist (not findings)

### AC-070 mount-time perf flake
R21 closure logged one transient FAIL under heavy concurrent load (perf.test.tsx — single render measured against 50 ms). Our R21 re-run **PASSES** AC-070. Implementation is sound: `PinScope.tsx:177-191` defers `RuntimePinObserver` setup via `queueMicrotask` so the synchronous mount path stays under budget. A single transient under jsdom + machine-load variance is not falsifiable evidence of a code defect. **Carried to watchlist; would warrant a P3 follow-up R-item only if failure rate exceeds ~10% across 10 sampled runs** (R21 closure rule). Not escalated.

### Annotation `request_type` / §10-E flow (carry from F-20-04)
`grep -rn 'request_type' src/` still shows only `'operation'` and `'diagnostic'`; `'annotation'` is never emitted; `captureScreenshot` has no `src/runtime/` caller. **R20 closed this as Resolution** (refuted): §10-E is non-normative prose, no Appendix-A AC requires it. **Not re-recorded.** Noted for blind-spot continuity only.

### §5 file-structure utils not implemented
SPEC §5 names `color-utils.ts`, `selector-generator.ts`, `style-formatter.ts` under `src/runtime/utils/`; none exist. §5 is structural prose with no AC reducing it to a falsifiable check. Not a gap; noted for blind-spot continuity.

---

## Coverage ledger

**Axes swept (12 of 12):**

1. Build pipeline — clean (AC-001..013 all PASS; production rebuild grep = 0)
2. Pin-ID stability — clean
3. Production-zero — clean (rebuilt `examples/vite-react/dist`; 0 hits in both `index.html` and emitted JS)
4. Runtime isolation — clean (portal + z-index + `data-pinscope-ui="root"`)
5. Inspection layer — R20's VoidBadges fix verified live in `PinScopeHud:330`; `pinsVisible` gate at `329-330` toggles both layers (R-20-03)
6. Measurement layer — Crosshair `enabled` prop wired (R-20-03), GridOverlay cycle order verified
7. Operation protocol — parser + CommandBar Enter/Cmd+K/`/` wiring verified; R-20-05 two tests landed
8. Data schemas — Operation/Snapshot/History match §9; `request_type='annotation'` still never emitted but no AC requires it (R-20-04 Resolution stands)
9. Edge cases — **DEFICITS FOUND: F-21-01 (long-press), F-21-02 (shadow-dom), F-21-04 (iframe-overlay) all dormant in HUD**
10. Performance budgets — bundle/parse/snapshot/html2canvas-dynamic all PASS; **DEFICIT: F-21-03 heavy-page throttle + skip-small-badge dormant**
11. Integration surface — Vite plugin live; deployment.test.ts now 10/10 PASS via subprocess-import (AC-090 R21 fix verified)
12. Phase DoD — P1-P5 ACs all PASS or BLOCKED-by-env; 309/309 tests green (+6 from R20)

**Sections reviewed (18):** §3 · §4 · §5 · §6 · §7 · §8 · §9 · §10 · §11 · §12 · §13 · §14 · §15 · §16 · §17 · §18 · Appendix A (69 ACs) · Appendix B (loop contract)

---

## Summary

| field | value |
|---|---|
| `open` (machine FAILs) | **0** |
| `blocked` (env=browser) | **6** |
| `regressions` (CLOSED → FAIL) | **0** |
| `confirmed` (investigation) | **3** |
| `suspected` (investigation) | **1** |

**Convergence note.** R21 reproduces the R20 metric (63 CLOSED, 0 OPEN P0/P1) with **zero machine FAILs and zero regressions**. The 4 STEP-5 findings are all **off-matrix dormant-mechanism gaps** in the SAME class as the 3 R20 fixed last round — implemented utilities that the assembled `<PinScope/>` HUD never invokes, whose ACs PASS via isolated unit construction. This is the false-convergence pattern this auditor role exists to catch; the planner should consider a single PinScope.tsx useEffect that batch-wires long-press touch listeners + shadow-host sweep + iframe-overlay sweep + heavy-page throttle gate against the same lifecycle that R-20-02 installed for `RuntimePinObserver`. Convergence is **provisional** until the planner decides whether to remediate or to amend the AC verify recipes to test against the assembled `<PinScope/>` rather than direct utility construction.
