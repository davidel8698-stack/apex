# Test Audit: PS-R21

## Quarantine Compliance: CLEAN
Only test files were read (`pinscope/tests/**`, `pinscope/convergence/lib/test/**`)
and `pinscope/convergence/ac-matrix.json`. No implementation/source file accessed.
APEX_ACTIVE_AGENT was empty (PinScope convergence-loop mode is invoked directly
by `/ps-heal`, not through the APEX dispatcher); read scope was self-enforced to
test artefacts only.

## Verdict: PASS

## R20-21 Delta Scrutiny

### Delta 1 — `tests/unit/runtime/pinscope.test.tsx` (+128 lines, AC-020/021/022 surface + R-20-01/02/03 DoD)
Substantive. The three new describe blocks (`R-20-01 — VoidBadges mount`,
`R-20-02 — RuntimePinObserver lifecycle`, `R-20-03 — §8.11 Shift+P / Shift+C
toggles`) all render the real `<PinScope/>` assembly imported from
`src/runtime/PinScope.js` and query observable DOM landmarks against the live
HUD subtree portalled into `document.body`. R-20-01 plants a void `<img
data-pin="e_9">` in the host, then asserts both that the `[data-pinscope-void-
badges]` portal exists inside the `[data-pinscope-ui="root"]` tree AND that a
specific `[data-void-badge="e_9"]` element is materialised — kills the
"VoidBadges rendered into the void" mutant. R-20-02 exercises the
`RuntimePinObserver` round-trip: appends a fresh `<span>` after mount, waits
two microtask flushes, asserts the runtime assigned an `e_r\d+`-shape id, then
unmounts and confirms a post-unmount append receives NO `data-pin` (proving
the observer disconnected — a no-op `unmount` would fail this branch). R-20-03
dispatches real `KeyboardEvent('keydown', { key:'P', shiftKey:true })`/`'C'`
on document, asserts both badge layers disappear AND reappear, and asserts the
crosshair toggles around a mouse-move. All assertions are over post-render DOM
state of the assembled HUD; no synthetic handlers, no dummy state, no mocking
of the unit under test.

### Delta 2 — `tests/unit/runtime/controls.test.tsx` (+51 lines, R-20-05 `snapshot foo` / `measure e_2 to e_3` Enter-path)
Real, not clones. The two added `R-20-05` cases each construct a real
`HistoryManager(new MemoryHistoryStore())`, spy `append`, render the real
`<CommandBar history={history} />`, type a VALID grammar string (`snapshot
foo`, `measure e_2 to e_3`) into the actual `[data-pinscope-command]` input,
fire a real `keyDown(Enter)`, and assert the spy was called exactly once with
a payload carrying `raw_input` equal to the typed string, `parsed: null`
(local-only marker), and `result: 'applied'`. They differ from the existing
`select e_1` clones because they exercise *the other two disjuncts* of
`isLocalOnlyCommand` (the comment at L257/L283 names L49 in `CommandBar.tsx`
explicitly). The R18 `or-to-and` mutant on that disjunction would have
collapsed `isLocalOnlyCommand` to require ALL of `select && snapshot &&
measure` simultaneously — under that mutant `snapshot foo` and `measure e_2 to
e_3` would route through `ClaudeBridge` instead, the CommandBar would NOT
append (or append with a non-null `parsed`), and `appendSpy` would receive 0
calls (or a different shape) — both new tests would red. Real mutation-kill.

### Delta 3 — `tests/unit/deployment.test.ts` AC-090 subprocess rewrite
Real import, not a smoke check. The subprocess code is `import(<file URL>).
then(m => { if (m && typeof m === 'object') process.exit(0); else exit(1) }).
catch(e => exit(2))`. Three reasons this is substantive: (1) the catch branch
exits 2 — any syntax/import-time evaluation error in the dist entry-point
surfaces as a non-zero status, and the `.toBe(0)` assertion fails with stderr
piped through the `result.stderr` template. (2) The success branch requires
the resolved namespace to be a non-null object — a dist file that *only*
errored during top-level await or bad re-export would resolve to a rejected
promise and never reach exit-0. (3) The sibling `it.each` test on L22 already
asserts `fs.existsSync(target)` for every subpath, so a completely empty file
slipping through would still need to exist on disk and be a real ESM
namespace; combined, the trio defends "declared, exists, ESM-loadable".
Limitation noted: an empty `export {}` file would yield an empty namespace
object that *would* pass — the test doesn't assert export shape per subpath.
That's a pre-existing gap (carried from R20's matrix design, which has AC-091
`public-api.test.ts` covering the public-export-shape contract for the root
subpath only), not a R21 regression. The rewrite faithfully ports R20's
import-loadability semantics out of the broken Vite-loader path.

## Spot-checks (10 representative vitest-tag ACs)

| AC | Test file | Verdict |
|---|---|---|
| AC-020/021/022 | runtime/pinscope.test.tsx L11-31 | SUBSTANTIVE. Renders real `<PinScope/>`; toggles `NODE_ENV=production`, `enabled={false}`, asserts portal lives under `document.body`. Three distinct DOM observations per case — no vacuous claims. |
| AC-038 | runtime/controls.test.tsx L162-189, L192-368 | SUBSTANTIVE. Ctrl+K focus/Escape blur, ArrowUp recall, Tab autocomplete against seeded `[data-pin]` elements, focus-expand 40→120px, and the R-18-01 single-owner fetch-spy test (`/__pinscope/history` POST body asserted to carry `{ version: '1.0', entries: [...] }` containing the submitted raw_input). |
| AC-040 | runtime/controls.test.tsx L42-65, L67-90, L92-140 | SUBSTANTIVE. `StatePanel` click sets `[data-state-override]` on `<html>` (positive AND clear), TopBar reflects the live override (R-17-03 wiring), and stylesheet-scan generator emits `[data-state-override="hover"]` selectors and clears them on `'none'`. |
| AC-050/AC-081 | unit/operation-parser.test.ts L53-65 | SUBSTANTIVE. 27 valid cases × `it.each` parse-kind assertion + 12 invalid cases × `OperationParseError` rejection; supplementary field-extraction tests assert specific `pin`/`property`/`op`/`value` field shapes. Mutation-resistant via dense table. |
| AC-053 | unit/claude-bridge.test.ts L61-95 | SUBSTANTIVE. Real `FileHistoryStore`+`MockClipboard`, real `parseCommand→buildOperation→bridge.send` chain, asserts clipboard content equals returned JSON AND parses to a pin matching the source command, AND history file persisted on disk with `result: 'sent'`. |
| AC-076 | unit/screenshot.test.ts L48-90 | SUBSTANTIVE. The one `vi.mock` in the suite targets the THIRD-PARTY `html2canvas` and is load-bearing: the `moduleState.evaluated` factory-side flag proves the SUT defers the `html2canvas` import to call time, killing a static-import refactor. Carries the documented anti-grep header from R20. |
| AC-090 | unit/deployment.test.ts L15-54 | SUBSTANTIVE. Export-map declared + dist file exists + subprocess `node --input-type=module -e "import(URL)..."` per entry point. R21 rewrite preserves R20 semantics outside Vite's broken percent-encoding loader. Gap on per-export shape noted in Delta 3, not a regression. |
| AC-091 | unit/runtime/public-api.test.ts | SUBSTANTIVE. (Verified by R20 audit — unchanged R20→R21.) Asserts the public-API surface against the production `runtime` entry point. |
| AC-070/071 | unit/runtime/perf.test.tsx | SUBSTANTIVE. AC-070 measures `render(<PinScope />)` wall time < 50 ms after a warm pass (paired observation: the render produced a non-null portal — implicit via `unmount()` chain). AC-071 walks `findPinnedAncestor` + `getBoundingClientRect` 100 times, asserts per-frame avg < 8 ms. Performance budgets paired with a correctness side-effect (rect read), so a no-op `findPinnedAncestor` would return null and skip the read. |
| AC-107 | unit/roundtrip.test.ts L55-102 | SUBSTANTIVE. R20-hardened: completeness predicate defined IN-TEST (not imported from demo); positive case (`e_47.padding-y → 12px` → 1 round), positive delta case (`+-> 4` → 1 round), negative under-specified case (`? layout` → 2 rounds, `not.toBe(1)`), and reject-path case (`select e_47` → `OperationBuildError`). Red/green dual proven. |

Across the spot-checks: zero `expect(true).toBe(true)`, zero `.skip`/`.todo`/
`xit`/`xdescribe`, zero hardcoded-pass assertions, zero self-mocking of the
unit under test, zero implementation-alias importing of computed-expected
values.

## Notes

- N-1 (carried R19→R20→R21): browser-env ACs AC-023 / AC-030 / AC-061 / AC-063
  / AC-082 / AC-083 remain Playwright/browser-binary-gated. The convergence
  engine self-tests (`convergence/lib/test/ac-eval.test.mjs`) confirm such ACs
  resolve to UNAVAILABLE — they are not green-but-hollow.
- N-2 (carried from R20): the only `vi.mock` in the suite still targets
  `html2canvas` (third-party). All other test doubles (`MemoryHistoryStore`,
  `MemorySnapshotStore`, `MockClipboard`, `FileHistoryStore`, `FakeMiddleware`,
  `fetch` global stub) are dependency injection at I/O seams, not mocking of
  the SUT.
- N-3 (new, R21 advisory — non-blocking): AC-090's subprocess-import
  verifies *loadability* per dist entry point but not per-entry-point *export
  shape*. AC-091 covers the root export. If a future R round needs to defend
  per-subpath exports (`./vite`, `./next`, `./webpack`, `./runtime`), extend
  the subprocess script to read a known export name out of each `m`. Not a
  R21 regression; the prior R20 form had the same scope.
- N-4 (R20→R21 continuity): R20's CONVERGED test-quality claims are preserved
  by R21's deltas — every new R-20-XX test ADDED a behavioral assertion path;
  none replaced a previously-substantive assertion with a weaker one.

## Coverage Map Match
All node-env `vitest-tag` ACs in `ac-matrix.json` satisfied — every tag
discoverable via `grep -E '(AC-NNN)'` in `pinscope/tests/` resolves to at
least one substantive `it(...)` carrying the tag in either the describe or it
name (vitest `-t` matches both). Browser-env ACs (AC-023/030/061/063/082/083)
and APEX-install AC (AC-106) remain manual/gated, as intended.

## Summary
Audited the R20→R21 test-quality delta for PinScope convergence loop. All
three R21 deltas (R-20-01/02/03 DoD additions, R-20-05 disjunct kill, AC-090
subprocess rewrite) are substantive: they assemble the real production
modules, drive observable inputs (real DOM mutations, real keyboard events,
real subprocess `import()`), and assert post-condition state — no
self-mocking, no synthetic handlers, no value aliasing. 10 representative
vitest-tag ACs spot-checked across the matrix, all SUBSTANTIVE. Zero false
PASS surfaced — the CONVERGED green AC verdicts are backed by real
behavioral coverage.
