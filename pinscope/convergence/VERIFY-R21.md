# Verify — PS-R21

**Verdict:** PASS

Independent clean-room re-verification of PS-R21. Every claimed closure
re-confirmed against its pre-written Definition of Done; mutation report
re-read; regression scan over all 63 CLOSED ACs; harness integrity diff +
skip-marker count; Rendering Gap commit count over the round window.

---

## Confirmed closures

### R-21-01 — touch tap/long-press + responsive HUD collapse (< 768px)

**Status:** CONFIRMED CLOSED.

DoD clause-by-clause re-check (`pinscope/tests/unit/runtime/pinscope.test.tsx`,
named describe block exists at L443: `describe('R-21-01 — touch + responsive
collapse', () => { ... })`):

- *DoD clause 1 — "tap selects":* test 1 in the named block (touchstart →
  touchend < 500 ms at known clientX/clientY, stubbed `elementFromPoint`,
  asserts `[data-pin-selected]` resolves to the pin) — present and GREEN
  on the re-run.
- *DoD clause 2 — "long-press locks":* test 2 (`vi.useFakeTimers()` +
  `advanceTimersByTime(600)`, asserts the lock survives a subsequent
  `mouseleave`) — present and GREEN.
- *DoD clause 3 — "compact viewport collapses HUD":* test 3 (`innerWidth=
  600` + resize fires the `[data-pin-badges]`-absent + `[data-pinscope-
  toggle]`-present assertions; restore `innerWidth=1280` + resize reverses
  it) — present and GREEN.

Production-side wiring re-checked by direct grep:
- `grep -nE 'LongPressDetector|isCompactViewport' pinscope/src/runtime/PinScope.tsx`
  → 5 hits (L35 import, L263/274 detector use, L436/439 compact-viewport
  branch). ≥ 2 ✓
- `grep -nE 'touchstart|touchend' pinscope/src/runtime/PinScope.tsx` → 6
  hits inside the new `useEffect` (L263–264 doc, L297–298 listener
  registration, L300–301 cleanup `removeEventListener`). Inside a
  `useEffect` body ✓.
- `grep -rn 'LongPressDetector' pinscope/src/` → 2 files
  (`utils/long-press.ts` definition + `PinScope.tsx` consumer). ≥ 2 ✓
- `grep -rn 'isCompactViewport' pinscope/src/` → 2 files
  (`utils/long-press.ts` definition + `PinScope.tsx` consumer). ≥ 2 ✓

Targeted re-run: `npx vitest run tests/unit/runtime/pinscope.test.tsx` →
14 passed (1 file, 14 tests, 999 ms). All three R-21-01 tests transitioned
red→green per the wave-result evidence and stay GREEN on the clean-room
re-run.

### R-21-02 — Shadow-DOM host marking + InfoPanel limited-inspection report

**Status:** CONFIRMED CLOSED.

DoD clause-by-clause re-check (named describe block exists at L160:
`describe('R-21-02 — Shadow-DOM marking + InfoPanel limited-inspection
report', () => { ... })`):

- *DoD clause 1 — PinScopeHud marks Shadow-DOM hosts on mount:* test 1 in
  the named block attaches a shadow root to `host1` pre-render, asserts
  `getAttribute('data-pin-shadow') === ''` after the initial flush — GREEN.
- *DoD clause 2 — MutationObserver re-sweep on dynamic content:* same
  test appends `host2` post-mount, flushes microtasks, asserts `host2`
  is marked — GREEN.
- *DoD clause 3 — Observer disconnects on unmount:* same test unmounts,
  appends `host3`, flushes, asserts `host3.getAttribute('data-pin-shadow')
  === null` — GREEN.
- *DoD clause 4 — InfoPanel reports limited inspection over a shadow
  host:* test 2 pre-mounts a shadow host, fires `mousemove`, asserts
  `[data-pinscope-shadow-limited]` is present inside `[data-pinscope-ui=
  "root"]` — GREEN.
- *DoD clause 5 — InfoPanel hides the row over a non-shadow pin:* same
  test fires `mousemove` to a plain pin, asserts the row is absent —
  GREEN.

Production-side wiring re-checked by direct grep:
- `grep -nE 'markShadowHosts' pinscope/src/runtime/PinScope.tsx` → 4 hits
  (L33 import, L197 doc, L207/211/214 in the new useEffect — sweep +
  fallback + observer callback). ≥ 1 ✓
- `grep -nE 'isShadowLimited' pinscope/src/runtime/components/InfoPanel.tsx`
  → 2 hits (L7 import, L150 use). ≥ 1 ✓
- `grep -rn 'markShadowHosts' pinscope/src/` → 2 files
  (`utils/shadow-dom.ts` + `PinScope.tsx`). ≥ 2 ✓
- `grep -rn 'isShadowLimited' pinscope/src/` → 2 files
  (`utils/shadow-dom.ts` + `components/InfoPanel.tsx`). ≥ 2 ✓

### R-21-03 — heavy-page degrade (30fps throttle + skip-small-badge)

**Status:** CONFIRMED CLOSED.

DoD clause-by-clause re-check (named describe block exists at L273:
`describe('R-21-03 — heavy-page degrade', () => { ... })`):

- *DoD clause 1 — > 500 pins switches hover to ≥ 30 Hz throttle:* test 1
  Case A in the named block (600 pins, 30 mousemoves @ 5 ms via
  `useFakeTimers`, asserts resolution count `≤ 6` over 150 ms) — GREEN.
- *DoD clause 2 — < 500 pins stays on the rAF path:* test 1 Case B
  (100-pin control, asserts resolution count `> 6`) — GREEN.
- *DoD clause 3 — < 16×16 badges hidden on a heavy page:* test 2 (600
  pins, 5 carry inline 8×8 + stubbed rect, asserts `data-pin-skipbadge=
  ''` on small pins, absent on normal pins, and `style[data-pinscope-
  skip-badge]` present) — GREEN.

Production-side wiring re-checked by direct grep:
- `grep -nE 'isHeavyPage|HEAVY_PAGE_INTERVAL_MS|throttle'
  pinscope/src/runtime/hooks/useHoveredElement.ts` → 11 hits across L8–11
  (named imports), L18–20/30–33/39 (docs/refs), L68–74 (heavy-branch body),
  L94 (cleanup). ≥ 2 ✓
- `grep -nE 'shouldSkipBadge|data-pin-skipbadge' pinscope/src/runtime/PinScope.tsx`
  → 6 hits including L34 import, L223–224 sweep doc, L239–240 stamp, L457
  doc + L460 complementary `<style>` block. ≥ 1 each ✓
- `grep -rn 'isHeavyPage' pinscope/src/` → 3 files (`utils/throttle.ts`,
  `hooks/useHoveredElement.ts`, `PinScope.tsx`). ≥ 2 ✓
- `grep -rn 'shouldSkipBadge' pinscope/src/` → 2 files
  (`utils/throttle.ts`, `PinScope.tsx`). ≥ 2 ✓

### R-21-04 — cross-origin iframe outline (investigation, refuted-branch)

**Status:** CONFIRMED CLOSED via `### Resolution` (no code change).

DoD clause-by-clause re-check (refuted-branch path):

- *DoD clause 1 — STEP 1 performed and recorded:* `WAVE-R21-RESULT.md` W4
  block contains the verbatim §12 + AC-061 SPEC re-read, the four greps
  with full output, and the REFUTED verdict. ✓
- *DoD clause 2 — pre-fix grep state recorded:* `grep -rn
  'markCrossOriginFrames' pinscope/src/` returns one hit only —
  `pinscope/src/runtime/utils/iframe-overlay.ts:31`. No `src/` consumer.
  ✓
- *DoD clause 3 — `git diff --stat HEAD~3 -- pinscope/src/` shows 0
  R-21-04-attributable changes:* re-run `git diff --stat f7da264~1..f7da264
  -- pinscope/src/` → empty output (zero source files changed in the W4
  commit). ✓
- *DoD clause 4 — `### Resolution` reasoning re-checks via named greps:*
  - `grep -rn 'markCrossOriginFrames' pinscope/src/` → 1 hit (definition
    only — `utils/iframe-overlay.ts:31`). ✓
  - `grep -rn 'iframe' pinscope/src/runtime/` → 1 file
    (`utils/iframe-overlay.ts` only — no consumer file references). ✓
  - `grep -rn 'crossOrigin' pinscope/src/runtime/` → no matches (the
    hyphenated "cross-origin" term lives only in `utils/iframe-overlay.ts`
    comments). ✓
  - `grep` for `*IframeOverlay*` files in `pinscope/src/runtime/` → no
    files (no React component named `*IframeOverlay*`). ✓
- *DoD clause 5 — `npm test` stays green:* clean-room re-run, see Harness
  integrity below — 316/316 GREEN. ✓

By symmetry with R-20-04, R-21-04 closes as a refuted-for-this-loop
investigation. The recommended strengthen-proposal for AC-061 is
forwarded to the loop owner per the plan.

---

## Rejected claims

**None.** Zero rejected claims this round.

---

## Regressions

**None.** Full regression scan over the 63 ACs `loop.json` records as
CLOSED → 100 % still PASS in `ac-results-R21.json`:

- All 56 `vitest-tag` CLOSED ACs report PASS in `ac-results-R21.json`.
- All 5 `grep` / `build-grep` CLOSED ACs (AC-100 .. AC-105 — excluding
  AC-106 which is manual) report PASS.
- 2 `command` CLOSED ACs (AC-073 size + AC-084 typecheck) report PASS
  (`exit 0`).
- AC-106 (`manual`) — closed at R20 via `loop-state.mjs manual-attest`;
  still CLOSED.
- The 6 env=browser BLOCKED ACs (AC-023, AC-030, AC-061, AC-063, AC-082,
  AC-083) report UNAVAILABLE — expected (carry-forward).

Spot-checks on the R20–R21 cleanup fixes called out in the verifier
mandate:
- **AC-090** — `7 AC-090 tests pass` (the `deployment.test.ts` fix R21
  restored). HOLDS ✓.
- **AC-104** — `2 matches >= 2` (the `framework/modules/apex-frontend/agent.md`
  path the R20 manual-attest fixed). HOLDS ✓.

Provenance ledger spot-check: every `CLOSED` AC in `loop.json` carries a
`provenance` block with `closed_round`, `verify`, and `at`. No CLOSED AC
is unverifiable.

**AC-070 timing-flake watchlist:** `ac-results-R21.json` reports
`AC-070 — 1 AC-070 tests pass`. The `tests/unit/runtime/perf.test.tsx`
file (which holds the AC-070 mount-budget test at L12: `it('mounts
<PinScope/> in under 50 ms (AC-070)', () => {...})`) was GREEN on both
the targeted vitest run and the full-suite run during this verification.
No flake observed this round.

---

## Harness integrity

**Skip-marker count:** 0.
- `ac-results-R21.json.harness.skip_markers === 0`.
- Independent grep against `pinscope/tests/` for `\.skip\(|\.todo\(|it\.only\(
  |describe\.only\(|describe\.skip\(|it\.skip\(` returns zero files.
- Matches the R20 baseline (per the mandate: R20 reported 30 files / 303
  tests / 0 skip-markers). R21 expands to 30 files / 316 tests (+13
  net: 2 R-21-02 + 2 R-21-03 + 3 R-21-01 + carry-forward of prior R20
  cleanup deltas) / 0 skip-markers.

**Config diff over the round window:**
- `git diff --stat a149f18^..HEAD -- pinscope/vitest.config.* pinscope/tsconfig*
  pinscope/package.json` → empty output (zero harness-config files
  changed across W1–W4). No threshold loosened, no test glob narrowed,
  no script weakened.

**`ac-verify` harness state:**
- `ac-results-R21.json.harness_ok === true` ✓.
- `ac-results-R21.json.harness.config_hash` recorded
  (`sha256:ca5f158debc914b985f0ec75f1bd58901e04789548e967fca5c70a09f4d75454`).
- Independent full-suite re-run: `cd pinscope && npm test` → exit 0;
  **30 test files, 316 tests, 316 passed, 0 failed, 0 skipped.** Stderr
  noise from the `claude-bridge` / `pin-map` / `deployment` tests is
  expected (network fetches in happy-dom + intentional unsupported-
  version warnings) and does not affect verdicts.

No harness-integrity findings.

---

## Rendering Gap

Commit window over the round: `git log a149f18^..HEAD --oneline --
pinscope/` returns **4 commits**, one per wave:

```
f7da264  fix(pinscope): R-21-04 W4 — cross-origin iframe (Resolution/no code change)
e56b8d0  fix(pinscope): R-21-01 W3 — touch tap/long-press + responsive-collapse
69679ca  fix(pinscope): R-21-03 W2 — heavy-page throttle + skip-small-badge
a149f18  fix(pinscope): R-21-02 W1 — Shadow-DOM host marking + InfoPanel limited-inspection
```

Non-empty commit window ✓. W1/W2/W3 commits each carry `pinscope/src/`
changes confirmed by `git log --name-only a149f18^..HEAD -- pinscope/src/`
(touched: `PinScope.tsx` W1+W2+W3, `InfoPanel.tsx` W1, `useHoveredElement.ts`
W2). W4 commit carries zero source changes — consistent with the refuted-
branch DoD ("the WAVE-R21-RESULT.md update IS the wave's deliverable").

Rendering Gap: **none.** Every R-item closure is backed by either a real
source-tree commit (W1–W3) or the explicit refuted-branch convergence
artifact (W4).

---

## Notes for R22

1. **Pre-R21 mutation survivors (R22 watchlist, not R21 failure).** The
   mutation report (`mutation-R21.json`) records 12 mutants, 10 killed,
   2 survived. Both survivors are in code R21 did NOT touch:
   - `InfoPanel.tsx:22` — `if (typeof localStorage === 'undefined')
     return false;` mutated to `return true;` survives. This is a
     pre-existing hollow test against the SSR-guard branch, not an R21
     fabrication. Recommend R22 add a test that asserts the SSR /
     `localStorage`-undefined branch yields `false`.
   - `useHoveredElement.ts:51` — `if (!pinned || !pinId) { ... }`
     mutated to `&&` survives. This is the guard-clause OR-vs-AND
     mutation; pre-existing hollow test (the OR-branch is correctly
     active in production but no test exercises the `!pinned && pinId`
     XOR cases). Recommend R22 add tests for the two XOR cases so the
     `||` choice is observable.
   Per the verifier mandate, survivors outside R21-touched code are R22
   watchlist items, not R21-round failures — the R21 wave-touched lines
   in these files (e.g. the `markShadowHosts` `useEffect` in `PinScope.tsx`,
   the `isShadowLimited` use in `InfoPanel.tsx:150`, the `isHeavyPage`
   gate in `useHoveredElement.ts:71`) are NOT in the survivor list, so
   no R21 closure is fabricated.

2. **AC-070 timing-flake watchlist.** No flake observed this round; the
   AC-070 mount-budget perf test (`perf.test.tsx:12`) was GREEN on both
   the targeted vitest run and the full-suite re-run. R-20-02's
   queueMicrotask deferral plus the cheap R-21-01/02/03 effects keep
   mount-time within the 50 ms budget. Continue monitoring next round in
   case the per-mousemove `querySelectorAll('[data-pin]')` count in the
   R-21-03 heavy-page gate begins to nudge AC-071 hover-budget on dense
   pages.

3. **AC-061 strengthen-proposal (carry-forward from W4 Resolution).** The
   R-21-04 refuted branch fired because AC-061's `verify` is `env:
   browser` BLOCKED and the helper's correctness is machine-proven via
   `iframe-overlay.test.ts`. The forwarded recommendation — a jsdom RTL
   surrogate calling `markCrossOriginFrames(document)` against an iframe
   fixture from within an assembled `<PinScope/>` mount — would re-
   classify F-21-04 from SUSPECTED to CONFIRMED in a future round and
   trigger the STEP-2 wiring branch. Loop owner's call.

---

**verdict: PASS · rejected: 0 · regressions: 0 · mutation-survivors-in-R21-touched-code: 0**
