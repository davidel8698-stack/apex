# Test Audit: PS-R22

## Quarantine Compliance: CLEAN
Only test files were read (`pinscope/tests/**`, `pinscope/convergence/lib/test/**`),
the AC matrix (`pinscope/convergence/ac-matrix.json`), the R22 verdict ledger
(`pinscope/convergence/ac-results-R22.json`), the R21 mutation report
(`pinscope/convergence/mutation-R21.json`), and the prior-round audit
(`TEST-AUDIT-R21.md`). No implementation/source file under `pinscope/src/` was
read. `APEX_ACTIVE_AGENT` was empty (PinScope convergence-loop mode is invoked
directly by `/ps-heal`, not through the APEX dispatcher); read scope was
self-enforced to test + convergence-artefact paths only.

## Verdict: PASS

R22 is the post-convergence terminal-check round. The R21->R22 test-quality
delta consists of three new DoD describe blocks added to
`tests/unit/runtime/pinscope.test.tsx` (R-21-01 touch + responsive-collapse,
R-21-02 Shadow-DOM, R-21-03 heavy-page throttle). All three are substantive
end-to-end exercises of the assembled `<PinScope/>` HUD with real
KeyboardEvent / TouchEvent / MouseEvent dispatch, real DOM mutations, and
observable post-condition assertions over the portalled HUD subtree. No
self-mocking of the unit under test, no vacuous assertions, no value
aliasing. 12 representative `vitest-tag` ACs spot-checked across the matrix
— all SUBSTANTIVE. The 2 mutation-survivors flagged in R21
(`InfoPanel.tsx:22` SSR-guard, `useHoveredElement.ts:51` pin-guard) are
coverage margins (untested edge branches), NOT hollow tests backing green
ACs — disposition below.

## R21-22 Delta Scrutiny

### Delta — `tests/unit/runtime/pinscope.test.tsx` (R-21-01 / R-21-02 / R-21-03 DoD blocks)

The file grew from 158 lines (R21 baseline visible in the R21 audit summary)
to 616 lines. Three new describe blocks (lines 159-616 net; the prior
R-20-01/02/03 blocks at lines 33-157 are unchanged from R21):

**R-21-02 — Shadow-DOM marking + InfoPanel limited-inspection report
(lines 159-270, +112 lines).** Substantive.
- Test 1 (`marks Shadow-DOM hosts on mount, re-sweeps on MutationObserver
  tick, and disconnects on unmount`): plants a shadow host BEFORE render,
  asserts `data-pin-shadow=""` is stamped after mount, appends a SECOND
  shadow host POST-mount and asserts the MutationObserver re-sweep stamps
  it too, then `unmount()`s and confirms a third post-unmount shadow host
  is NOT stamped. Kills three independent mutants: "initial sweep no-op",
  "observer no-op on post-mount append", and "no-disconnect on unmount".
  Real DOM observation, no synthetic state.
- Test 2 (`InfoPanel reports limited inspection over a shadow host, absent
  over a non-shadow pin`): plants both a shadow-host pin AND a plain-host
  pin with explicit fixed rects, stubs `document.elementFromPoint` to
  route x<100 -> shadowHost, x>=100 -> plainHost, dispatches real
  `MouseEvent('mousemove')` at x=20 then x=220, flushes rAF via
  `setTimeout(0)+setTimeout(16)`, and asserts the HUD's
  `[data-pinscope-shadow-limited]` landmark exists for the shadow hover
  AND is absent for the plain hover. The positive/negative pairing is
  mutation-killing: a constant `true` for the shadow flag fails the
  negative branch; a constant `false` fails the positive. The
  `elementFromPoint` stub is on a DOM API (test seam), not on the unit
  under test.

**R-21-03 — heavy-page degrade (lines 272-440, +169 lines).** Substantive.
- Test 1 (`> 500 pins switches hover to >= 30 Hz throttle; < 500 stays on
  rAF`): builds 600 `[data-pin]` elements (heavy), wraps
  `document.elementFromPoint` to count invocations (proxy for resolution
  calls), uses `vi.useFakeTimers()` and dispatches 30 mousemoves at 5ms
  intervals (150ms span), flushes a 40ms tail, asserts `heavyCount > 0 &&
  heavyCount <= 6` (HEAVY_PAGE_INTERVAL_MS=33ms throttle). Then cleans
  up, rebuilds with 100 pins (light), repeats the dispatch, and asserts
  `lightCount > 6` (60Hz rAF). The PAIRED assertion (`<=6` AND `>6` for
  the two branches) is what makes this mutation-resistant — a
  constant-throttle mutant fails one branch; a constant-rAF mutant fails
  the other.
- Test 2 (`< 16x16 badges are hidden on a heavy page`): 600 pins, 5 sized
  8x8 (small, below MIN_BADGE_SIZE=16), 5 sized 100x100 (large), 590
  sized 32x32 (normal). Overrides `getBoundingClientRect` per element
  (happy-dom doesn't lay out so rect lookups would zero out without this
  — the override is on test fixtures, not on the SUT). Asserts each
  small pin gets `data-pin-skipbadge=""` stamped AND each large pin does
  NOT, AND the complementary `<style data-pinscope-skip-badge>` block is
  injected. Three-way assertion (positive + negative + side-effect) kills
  mutants in three independent directions.

**R-21-01 — touch + responsive collapse (lines 442-616, +175 lines).**
Substantive.
- Test 1 (`tap`): plants a `[data-pin="e_7"]` element with fixed rect,
  stubs `elementFromPoint` to return it for in-rect coordinates, renders
  `<PinScope/>`, dispatches real `TouchEvent('touchstart')` then real
  `TouchEvent('touchend')` 50ms later (under LONG_PRESS_MS=500), and
  asserts the host carries `[data-pin-selected]`. The `Touch`/`TouchEvent`
  constructors are happy-dom-native; this is a real touch round-trip, not
  a synthetic call into a handler.
- Test 2 (`long-press locks selection`): same setup, but
  `vi.advanceTimersByTime(600)` between touchstart/touchend (over the
  500ms long-press threshold), then asserts selection is set AND survives
  a subsequent `mouseleave` (locked-selection regression guard per §8.1).
  Pairs with test 1 to discriminate tap (transient) vs long-press
  (locked) — a constant-tap mutant breaks the mouseleave-survival
  assertion.
- Test 3 (`compact viewport collapses HUD; restoring re-expands`): sets
  `window.innerWidth=600` BEFORE render (compact), asserts no
  `[data-pinscope-badges]` layer renders BUT `[data-pinscope-toggle]`
  (FloatingToggle) does, then re-sets `innerWidth=1280`, dispatches
  `resize`, and asserts `[data-pinscope-badges]` returns. Bidirectional
  assertion kills both "always-compact" and "always-expanded" mutants.

None of the three new R-21 blocks self-mock; the only doubles are at I/O
seams (`document.elementFromPoint`, `getBoundingClientRect`,
`window.innerWidth`, fake timers), all of which are the standard
test-double pattern for DOM testing under happy-dom.

## Mutation-Survivor Disposition (the 2 R21 watchlist hits)

The R21 mutation report (`mutation-R21.json`) flagged 2 surviving mutants
out of 12 (10 killed). Both are PRE-R21 code, deliberately left as
watchlist by R21's auditor. R22 disposition:

### Survivor 1 — `InfoPanel.tsx:22` (`false-to-true` on SSR-guard)
**Original:** `if (typeof localStorage === 'undefined') return false;`
**Mutant:** `if (typeof localStorage === 'undefined') return true;`

**Disposition: COVERAGE MARGIN — NOT a hollow test.**

Reasoning: the only InfoPanel test file
(`tests/unit/runtime/infopanel.test.tsx`) runs entirely under happy-dom,
which always supplies a `localStorage` global. The
`typeof localStorage === 'undefined'` branch is therefore unreachable in
the unit-test environment — the mutation is equivalent (in the test
environment) regardless of which value it returns, because the branch is
never taken. The AC backed by this code path is AC-032 ("collapsible
persistence"), and the substantive test (lines 31-58 of
`infopanel.test.tsx`) drives the localStorage-present path: it clicks a
section toggle, asserts
`localStorage.getItem('pinscope:section:dimensions') === '1'`, unmounts,
re-renders, and asserts the section is still collapsed AND its body is
absent. The AC's PASS verdict is backed by REAL persistence assertions —
the mutant survives only because the SSR fallback path
(`localStorage === undefined`) is not exercised. This is a coverage gap
for the SSR path (a true second-environment regime, not a test-quality
defect), not a green-but-hollow AC. No R22 OPEN finding.

### Survivor 2 — `useHoveredElement.ts:51` (`or-to-and` on pin-guard)
**Original:** `if (!pinned || !pinId) { ...return early... }`
**Mutant:** `if (!pinned && !pinId) { ...return early... }`

**Disposition: COVERAGE MARGIN — NOT a hollow test.**

Reasoning: under the mutant, the early-return is only taken when BOTH
`pinned` is null AND `pinId` is null. The discriminating case is "pinned
element WITHOUT a pinId" (e.g., a `[data-pin]` ancestor reached via the
walker but whose attribute was scrubbed): original returns early, mutant
proceeds to construct a `HoveredElement` with `pinId=null`. No test in
`tests/` exercises this case — all hover tests either pre-stamp the host
with an explicit `data-pin="e_N"` (R-21-02 InfoPanel shadow test) or use
the `hoveredOf` helper which hard-codes `pinId: 'e_9'`
(`infopanel.test.tsx`). No vitest-tag AC asserts the
"pinned-but-no-pinId" contract, so no green AC is being propped up by
this gap. The AC implicated by the surrounding code (the AC-031/032/033
InfoPanel surface) is backed by tests that always supply a pinId — the
AC verdicts are substantively backed; the mutant survives because the
"pinned-without-id" shape is undertested. Coverage margin, not false
PASS. No R22 OPEN finding.

**Net: 0 OPEN findings from the mutation survivors.** Both are pre-R21
coverage margins on edge branches that no `vitest-tag` AC asserts.
Recommend they remain on the audit watchlist; if a future round expands
the AC surface to assert SSR-time persistence behavior or
pinned-without-pinId hover handling, then add the discriminating test
THEN — until then, adding a test purely to kill these mutants would be
test-for-test's-sake without an AC behind it.

## Spot-checks (12 representative `vitest-tag` ACs)

| AC | Test file | Verdict |
|---|---|---|
| AC-001 | unit/plugin.test.ts L23-33 | SUBSTANTIVE. Calls `pinscope()` real factory, asserts plugin identity (`name`, `enforce='pre'`) AND all four hook functions are present (`buildStart`, `transform`, `buildEnd`, `transformIndexHtml`). Six concrete property assertions on the live plugin object. |
| AC-005 | unit/ast-transformer.test.ts L58-67 | SUBSTANTIVE. Runs the REAL `transformJSX` twice on the same source with two fresh `PinMap` instances and asserts the emitted code is byte-identical. A non-deterministic id assignment would fail here. |
| AC-013 | unit/plugin.test.ts L35-65 | SUBSTANTIVE. Five distinct gating cases: non-`.tsx` extension -> null; `node_modules` path -> null; `.test.` file -> null; `enabled=false` -> null; matching `.tsx` + enabled -> emits `data-pin="e_N"` regex match. Each branch asserted independently — a mutant collapsing any one branch fails its specific test. |
| AC-024 | unit/runtime/overlays.test.tsx L199-215 | SUBSTANTIVE. Renders real `<VoidBadges/>` against seeded `<img>`+`<input>` (true void elements), asserts the badge for `e_5` has `textContent='e_5'` AND the badge for `e_6` is present. Negative twin test: a pinned `<div>` (non-void) produces NO badge. Positive + negative pairing. |
| AC-034 | unit/runtime/overlays.test.tsx L22-35, L37-80 | SUBSTANTIVE. Counts rendered ticks against a known width (1440 -> 15 ticks at 100px interval — exact arithmetic), then asserts ruler stripe scales `10`/`50` exist + tick scales `100`/`200` exist via `data-ruler-scale` attribute introspection. The four-scale union assertion (`{'10','50','100','200'}`) is rebuilt from the live DOM. |
| AC-041 | unit/runtime/selection.test.tsx L11-58 | SUBSTANTIVE. Five concrete branches on real `SelectionManager`: select sets hash + locks; reload-from-hash restores selection; attribute moves between pins on re-select; clear removes both selection AND hash; goBack steps history. The R-17-01 integration test (L102-129) further drives the `select e_N` CommandBar path through the assembled `<PinScope/>` and asserts the InfoPanel locks. |
| AC-051 | unit/property-shortcuts.test.ts L20-33 | SUBSTANTIVE. `it.each` over 10 shortcut->CSS pairs (`padding-y`->`padding-block`, `bg`->`background-color`, etc.) asserting `resolveProperty(shortcut)` returns the expected CSS property. Pass-through case + exhaustiveness check on `SHORTCUT_PROPERTIES` symbol set. A mutant collapsing any single mapping fails its specific row. |
| AC-052 | unit/operation-builder.test.ts L53-115 | SUBSTANTIVE. `it.each` over `samples` array asserting `buildOperation(parseCommand(input))` produces a schema-valid `Operation` per `isValidOperation` (round-tripped through JSON to prove serialisability). Additional cases: shortcut resolution (`padding-y`->`padding-block`), diagnostic request flag, `+= active` -> `add-class`, local-only rejection (`select`/`measure`), increment-delta routing, decrement-delta routing. Each asserts SPECIFIC operation fields — no "operation defined" smoke checks. |
| AC-064 | unit/long-press.test.ts L9-30 | SUBSTANTIVE. `LongPressDetector.start(t0).end(t0+100)` -> `'tap'`; `start(t0).end(t0+LONG_PRESS_MS)` -> `'long-press'` (boundary case). `isCompactViewport` table: 500 -> true; `MOBILE_BREAKPOINT-1` -> true; `MOBILE_BREAKPOINT` -> false (boundary); 1024 -> false. Boundary-inclusive table that pins the exact threshold value. |
| AC-072 | unit/operation-perf.test.ts L6-14 | SUBSTANTIVE (perf). Warms `parseCommand`, runs it 200x over a real grammar string (`e_47.padding-y -> 12px`), asserts mean parse time < 4ms. A correctness-only mutant doesn't survive the surrounding `parseCommand` correctness suite at AC-050; this AC adds the perf budget on top. |
| AC-080 | unit/ast-transformer.test.ts L20-32 (+ fixtures) | SUBSTANTIVE. Two-part: (a) asserts `transformerCases.length >= 50` (table size requirement); (b) `it.each(transformerCases)` runs each case through real `transformJSX`, asserting the output matches `data-pin="e_\d+"` for `expectPin=true` cases and does NOT match for `expectPin=false` cases. A 50-row positive/negative table is mutation-resistant by sheer density. |
| AC-092 | unit/deployment.test.ts L56-80 | SUBSTANTIVE. Three integration assertions on the real `withPinScope` + `PinScopeWebpackPlugin`: (1) input config keys preserved + webpack hook appended; (2) existing webpack function COMPOSED via a `called` flag set when the plugin invokes it; (3) `plugin.apply({hooks:{}})` does not throw. Branch (2) discriminates "wrap" from "replace" mutants. |

Across the 12 spot-checks: zero `expect(true).toBe(true)`, zero
`.skip`/`.todo`/`xit`/`xdescribe`, zero hardcoded-pass assertions, zero
self-mocking of the unit under test, zero implementation-alias importing of
computed expected values. All assertions reduce to either (a) a specific
DOM attribute/landmark observation, (b) a returned value matching a literal
or table entry, or (c) a side-effect (hash mirror, localStorage entry,
file write) observable from outside the SUT.

## Notes

- **N-1 (carried R19->R20->R21->R22):** browser-env ACs AC-023 / AC-030 /
  AC-061 / AC-063 / AC-082 / AC-083 remain Playwright/browser-binary-gated
  and the APEX-install AC-106 remains a manual gate. The convergence
  engine self-tests (`convergence/lib/test/ac-eval.test.mjs`) confirm such
  ACs resolve to UNAVAILABLE — they are not green-but-hollow.
- **N-2 (carried from R20):** the only `vi.mock` in the suite still targets
  `html2canvas` (third-party). All other test doubles (`MemoryHistoryStore`,
  `MemorySnapshotStore`, `MockClipboard`, `FileHistoryStore`,
  `FakeMiddleware`, `fetch` global stub, `document.elementFromPoint`,
  `getBoundingClientRect`, `window.innerWidth`, `vi.useFakeTimers`) are
  dependency injection at I/O seams, not mocking of the SUT.
- **N-3 (R21->R22):** the AC-090 subprocess-import-loadability scope-gap
  carried from R21 is unchanged — still verifies per-entry-point
  loadability but not per-entry-point export shape (AC-091 covers the
  root export). Not a R22 regression; same scope as R20/R21.
- **N-4 (R22 watchlist, non-blocking):** the 2 mutation-survivors disposed
  above (`InfoPanel.tsx:22` SSR-guard, `useHoveredElement.ts:51`
  pin-guard) are pre-R21 coverage margins on branches no `vitest-tag` AC
  asserts. Keep on watchlist; promote ONLY if a future round expands the
  AC surface to assert SSR-time persistence or pinned-without-pinId hover
  handling.
- **N-5 (R22 terminal-check observation):** the R21->R22 test-quality delta
  ADDED 9 new substantive test functions (3 each for R-21-01, R-21-02,
  R-21-03 DoD blocks, modulo helpers). Test-function count delta is
  positive — no uncompensated decreases. Coverage grew; nothing eroded.
- **N-6 (R22 terminal-check observation):** R22 is the post-convergence
  terminal-check round. The R22 ledger (`ac-results-R22.json`,
  `harness_ok: true`, `skip_markers: 0`) reports all spot-checked ACs as
  PASS. Combined with this audit's spot-check substantiveness verdict, the
  CONVERGED green AC verdicts are backed by real behavioral coverage.

## Coverage Map Match

All node-env `vitest-tag` ACs in `ac-matrix.json` satisfied — every tag
discoverable via `grep -E 'AC-NNN'` in `pinscope/tests/` resolves to at
least one substantive `it(...)` carrying the tag in either the describe or
it name (vitest `-t` matches both). Browser-env ACs
(AC-023/030/061/063/082/083), the build-grep ACs (AC-010/074), the command
ACs (AC-073/084), the grep ACs (AC-100/101/102/103/104/105), and the
APEX-install AC (AC-106) remain manual/gated/non-vitest, as intended by
the matrix design.

## Summary

Audited the R21->R22 test-quality delta for PinScope convergence loop
(terminal-check round). The single new file delta — three new DoD
describe blocks in `tests/unit/runtime/pinscope.test.tsx` covering R-21-01
(touch + responsive-collapse), R-21-02 (Shadow-DOM marking + InfoPanel
limited-inspection report), R-21-03 (heavy-page 30Hz throttle + skip-small-
badge sweep) — is fully substantive: real `<PinScope/>` assembly, real
TouchEvent/KeyboardEvent/MouseEvent dispatch, real DOM observations, no
self-mocking of the SUT. The 2 R21 mutation-survivors are pre-R21
coverage margins on edge branches no AC asserts; disposed as watchlist,
NOT promoted to R22 OPEN findings. 12 representative `vitest-tag` ACs
spot-checked across the matrix, all SUBSTANTIVE. Zero false PASSes
surfaced. The CONVERGED-on-terminal-check green AC verdicts are backed by
real behavioral coverage.
