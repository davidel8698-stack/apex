# Audit Findings — PS-R22

**Round summary.** Terminal-check round after R21 closed PASS / CONVERGED
(63/69 = 91%, 0 OPEN, 0 narrative-blocking). STEP 1 found no machine FAILs to
re-confirm — `ac-results-R22.json` reports 62 PASS / 6 UNAVAILABLE / 1 MANUAL,
with AC-106 already CLOSED via attestation in `loop.json`. STEP 4 confirms
zero regressions: every CLOSED AC still reports PASS, every BLOCKED AC still
reports UNAVAILABLE (env=browser carry-forward). STEP 5 swept all 12 axes
against the R21 integrations now LIVE in `src/`. **Outcome: 0 CONFIRMED, 1
SUSPECTED finding (F-22-01, P3, UX edge case).** No P0/P1/P2 findings; the
single P3 SUSPECTED finding is non-blocking and recorded for orchestrator
visibility per STEP 5's "do not filter early" rule.

---

## AC findings

**None.** Zero machine FAILs; zero re-confirmable gaps.

---

## Investigation findings

### F-22-01 — Compact-viewport FloatingToggle re-expand is inert (P3, SUSPECTED)

**Axis 9 — Edge cases / hollow-interaction.**

R-21-01 (PinScope.tsx:433-446) added a compact-viewport branch that collapses
the HUD to `<FloatingToggle onShow={() => setHudVisible(true)} />` when
`isCompactViewport(viewport.width)` returns true. The inline comment at L435
promises *"so the user can re-expand by tapping it"*. But `hudVisible`
defaults to `true` (L162) and the compact-viewport check fires BEFORE the
`!hudVisible` check (order: hidden-first L424, then compact L439). So on a
sub-768px viewport the user lands on the compact branch with `hudVisible ===
true`. Tapping the FloatingToggle calls `setHudVisible(true)` — a no-op
because `hudVisible` is already `true`. The compact branch re-renders, the
toggle stays, and there is no way for the user to expand the HUD on a small
viewport. The transition reverses correctly only on window-width change
(verified by R-21-01 test 3, which resizes back to 1280px); a real mobile
user has no `resize` event available.

**Gap:** SPEC §12 wording *"HUD collapsible < 768px"* is borderline-normative.
`collapsible` literally implies the user can toggle the collapse, and the
R-21-01 inline comment explicitly promises *"the user can re-expand by
tapping it"*. The implementation only collapses; the re-expand interaction
is hollow. AC-064's verify (R-21-01 test 3) exercises only the resize-driven
round trip (innerWidth=600 collapses, innerWidth=1280 re-expands), so the
tap-to-expand promise is not witnessed. P3 (not P2) because AC-064 is itself
P2-severity, the SPEC's "collapsible" wording does not strictly require a
user-driven re-expand on a compact viewport, and reasonable readers can argue
`collapsible` just means *"collapses automatically below 768px"*. SUSPECTED
(not CONFIRMED) because the interpretation is contestable; recorded for
planner visibility per STEP 5's *"do not filter early"*.

**re_read:** Read `pinscope/src/runtime/PinScope.tsx` — L162
`const [hudVisible, setHudVisible] = useState(true);` confirms default `true`.
L424-431 `if (!hudVisible)` branch returns toggle with `onShow={() =>
setHudVisible(true)}`. L439-446 `if (isCompactViewport(viewport.width))`
branch returns toggle with the SAME `onShow={() => setHudVisible(true)}`.
L435 inline comment claims *"so the user can re-expand by tapping it"*.
`grep -n 'setHudVisible' src/runtime/PinScope.tsx` → 4 hits (L162 declare,
L400 toggle-hud shortcut, L427 hidden-branch toggle, L442 compact-branch
toggle). On compact (viewport.width < 768) `setHudVisible(true)` cannot
change `hudVisible` because it is already `true` — React bails on identical
state, the compact branch re-renders the same toggle. Tested at
`tests/unit/runtime/pinscope.test.tsx:567-615` (R-21-01 test 3) — the test
only asserts the resize-driven round trip, never simulates a tap on the
compact-mode toggle expecting expand.

---

## BLOCKED (env / manual — never `OPEN`)

| AC | Severity | Reason |
|---|---|---|
| AC-023 | P0 | `env: browser` unavailable — Playwright `::before` content read needs a browser engine. |
| AC-030 | P1 | `env: browser` unavailable — Playwright InfoPanel hover assertion needs a browser engine. |
| AC-061 | P3 | `env: browser` / `manual` — cross-origin iframe needs two real origins. (R-21-04 carry-forward: `markCrossOriginFrames` helper is fully tested but not wired into `PinScope.tsx`; closed as Resolution last round, AC remains env-blocked.) |
| AC-063 | P3 | `env: browser` / `manual` — `@media print` rendering needs a browser print engine. |
| AC-082 | P1 | `env: browser` / `manual` — Playwright integration suite, browser binary unavailable. |
| AC-083 | P3 | `env: browser` / `manual` — visual-regression screenshots need a browser. |

All 6 BLOCKED carry-forward from R21 (unchanged set). None are findings;
none are proposed for remediation in a browser-less env.

---

## Coverage ledger (12-axis sweep)

1. **Build pipeline** — AC-001..013 all PASS in `ac-results-R22.json`;
   production rebuild + grep over `examples/vite-react/dist` returns 0
   pinscope tokens; `transformJSX`, `excludeTags`, `data-pin-ignore`,
   `filePattern`/`excludePattern` all verified by ≥1 vitest test each.
2. **Pin-ID stability** — `stable_key = file:line:column`, `getOrAssign`
   monotonic + no-reuse via AC-005/007/008; `pin-map.ts` re-read clean;
   `PinMap.reconcile` soft-delete unchanged from R21.
3. **Production-zero** — AC-010 + AC-074 both report `0 files match` in
   `ac-results-R22.json`; the rebuilt `examples/vite-react/dist` carries zero
   `data-pin|PinScope|pinscope` tokens.
4. **Runtime isolation** — `createPortal` to `document.body` under
   `[data-pinscope-ui="root"]`; PinScope.tsx L448-482 unchanged from R21.
5. **Inspection layer** — `useHoveredElement` rAF + `escapeHud` + R-21-03
   heavy-page gate now live; `InfoPanel` with R-21-02 shadow-limited row at
   L150/157; `PinBadges` CSS-`::before` + `VoidBadges` JS-overlay both gated
   on `pinsVisible` at L453-454.
6. **Measurement layer** — `Rulers`, `Crosshair` with `enabled` prop at
   L466, `GridOverlay` 4 modes + cycle order, `MeasurementTool` gated on
   `measuring`; unchanged from R20 closure.
7. **Operation protocol** — `parseCommand` grammar + typed errors;
   CommandBar Cmd+K / `/` / Esc / Tab / Enter handled in its own onKeyDown
   at CommandBar.tsx:71-142; pre-R21 wiring untouched.
8. **Data schemas** — Operation/Snapshot/History match §9; AC-052/AC-042/
   AC-053 PASS; annotation request_type still not emitted but §10-E is
   non-normative per R20 Resolution.
9. **Edge cases** — R-21-01 long-press + touch listeners wired at
   PinScope.tsx:272-303; R-21-02 `markShadowHosts` wired in useEffect
   L203-220; R-21-03 skip-small-badge sweep L231-257. R-21-04 iframe-overlay
   remains unwired by Resolution (F-21-04 carry-forward). **NEW SUSPECTED
   F-22-01:** compact-viewport FloatingToggle `onShow` is inert
   (`setHudVisible(true)` when already `true`).
10. **Performance budgets** — AC-070..076 all PASS; R-21-03 heavy-page
    throttle now in `useHoveredElement`; skip-small-badge sweep idempotent
    and non-attribute-mutating so the R-21-02 MutationObserver does not
    infinite-loop on its own attribute writes.
11. **Integration surface** — Vite plugin live; package.json export map
    verified by AC-090 (7 tests PASS); `deployment.test.ts` subprocess-import
    unchanged.
12. **Phase DoD** — P1–P5 DoD ACs all PASS or BLOCKED-by-env; 316 unit
    tests green per VERIFY-R21; harness diff over R21 window shows zero
    config files touched.

**Sections reviewed:** §3 System Architecture · §4 Technical Stack · §5
File Structure · §6 Build-Time Module · §7 Runtime Module · §8 Component
Specs · §9 Data Schemas · §10 Behavioral Flows · §11 Operation Protocol ·
§12 Edge Cases · §13 Performance · §14 Testing Strategy · §15 Deployment ·
§16 Phase Plan/DoD · §17 APEX Integration · §18 Resolved Inconsistencies ·
Appendix A (69 ACs) · Appendix B (loop contract).

---

## Notes

- **STEP 1 — re-confirm.** ac-results-R22.json reports 62 PASS / 6
  UNAVAILABLE / 1 MANUAL / 0 FAIL. Zero machine FAILs to re-confirm.
  AC-106 MANUAL is already CLOSED via `loop.json.criteria['AC-106'].
  manual_attestation` (R20 attestation, R21 verification carried forward).
  All 62 PASS verdicts consistent with VERIFY-R21's clean-room re-run of
  316/316 green.
- **STEP 4 — regression scan.** Every CLOSED AC still appears PASS in
  ac-results-R22.json (or MANUAL/CLOSED in AC-106's case). Verdict-for-
  verdict match against the closed_round=20/21 provenance. Zero
  regressions.
- **STEP 5 — investigation outcome.** The three R-21 integrations are live
  end-to-end: Shadow-DOM marker (PinScope.tsx L203-220), heavy-page throttle
  (useHoveredElement.ts L8-11/30-33/68-74), touch listeners + responsive
  collapse (PinScope.tsx L272-303 + L439-446). The iframe-overlay
  refutation holds: still no src/ consumer of `markCrossOriginFrames`
  outside `utils/iframe-overlay.ts`. Per the spec-auditor STEP 5 mandate,
  one SUSPECTED finding (F-22-01) is recorded — a hollow-interaction in the
  newly-wired R-21-01 compact-viewport branch.
- **Other potential dormant-mechanism scan (NOT findings).**
  - `long-press.ts` `Gesture` type — computed by `detector.end()` and
    discarded in PinScope.tsx (both tap and long-press route to
    `selectPin(pinId)`, locking via `SelectionManager.select(locked=true)`).
    Per R-21-01 plan this is intentional; the lock semantic is identical
    for both gestures.
  - `useKeyboardShortcuts` `SHORTCUTS` table `command`/`escape` ids —
    defined but not bound in PinScope.tsx's useKeyboardShortcuts handlers;
    consumed instead by CommandBar.tsx (Cmd+K + Escape on input) and
    `useSelectedElement` (Escape clear). Pre-existing pattern, predates
    R21.
  - `iframe-overlay.ts` `IFRAME_OVERLAY_ATTR` constant — exported but
    unimported outside the file; carry-forward of F-21-04 (Resolution
    stands).
- **MutationObserver loop-safety.** R-21-02 + R-21-03 both observe
  `{subtree: true, childList: true}` (NOT `attributes: true`), so the
  `setAttribute('data-pin-shadow'|'data-pin-skipbadge')` writes inside the
  sweeps do not re-fire the observers. Both functions are idempotent.
  Empirically corroborated by VERIFY-R21's 316/316 green test run.
- **Pre-R21 mutation survivors (R22 watchlist — investigated, NOT auto-
  flagged).**
  - `InfoPanel.tsx:22` (`typeof localStorage === 'undefined'` SSR-guard) —
    the `return false` mutated to `return true` survives because no test
    asserts the SSR branch. The runtime behavior IS correct (production
    branch returns the localStorage read result; SSR returns false). This
    is a test-coverage margin, not a code defect.
  - `useHoveredElement.ts:51` (`if (!pinned || !pinId)`) — the `||` vs
    `&&` mutation survives because the XOR cases are unreachable in
    practice (`findPinnedAncestor` only returns an `HTMLElement` carrying
    `data-pin`, so `pinId` is guaranteed non-null when `pinned` is non-null).
    The OR semantics ARE correct.
  - Per VERIFY-R21 mandate NOT to auto-flag these as P2 (they are
    coverage margins, not code defects), they are NOT recorded as R22
    investigation findings. Either could be promoted to a future R-item if
    a planner decides to harden test coverage; not blocking convergence.
- **AC-070 timing-flake watchlist.** No flake observed in R22's ac-verify
  run (AC-070 reports `1 AC-070 tests pass`). R-20-02 queueMicrotask
  deferral + lightweight R-21-01/02/03 effects keep mount under 50 ms.
  Carry forward to R23 watchlist only if flake re-emerges.

---

**Round R22 verdict: terminal-check PASS. 0 CONFIRMED, 1 SUSPECTED (P3,
non-blocking). 0 regressions, 0 new blocked, 6 carry-forward blocked. The
loop's STEP-2 terminal check fires "CONVERGED — nothing P0/P1/P2 to heal";
F-22-01 is eligible for BACKLOG by user decision or for a P3 follow-up
R-item that wires the compact-viewport `setHudVisible` toggle to a real
collapse/expand state.**
