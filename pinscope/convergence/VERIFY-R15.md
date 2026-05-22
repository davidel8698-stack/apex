# VERIFY-R15 — Clean-Room Verification (PS-R15, STEP 6)

**Verifier:** ps-verifier (clean-room, context-isolated)
**Round:** 15 · **Verified at:** 2026-05-22
**Inputs:** ac-results-R15.json · REMEDIATION-PLAN-R15.md · WAVE-R15-RESULT.md ·
loop.json · mutation-R15.json
**Independently re-run:** full vitest suite (293/293), 11 R-item DoD checks,
regression scan over 62 CLOSED ACs, harness/config diff, perf probe, commit-window scan.

---

## Verdict: `PARTIAL`

A round is `PASS` only with zero rejected claims, zero regressions, zero harness
findings, and a non-empty commit window. This round has **zero rejected
claims**, **zero regressions**, a **non-empty commit window** (2 fix commits) —
but **4 mutation-survivor coverage findings** in code R-15-06/R-15-07 touched
this round. Those survivors do not falsify any DoD's core behavioral assertion
(see STEP 3) so no claim is *rejected*, but they are genuine harness/coverage
findings that bar a clean `PASS`. Verdict: **PARTIAL**.

---

## Confirmed closures (11 of 11 R-items)

All 11 R-items independently re-verified. Full suite re-run by the verifier:
`28 files / 293 tests passed`, `tsc --noEmit` exit 0.

| R-item | Closure | Check the verifier ran |
|--------|---------|------------------------|
| R-15-01 | HUD root re-assembly + FloatingToggle | `grep -cE 'Rulers\|Crosshair\|GridOverlay\|TopBar\|CommandBar' PinScope.tsx` → **13** (≥5); `defaultGridMode`/`shortcutsEnabled` both in `PinScopeProps`; `FloatingToggle.tsx` exists + referenced (4×); HUD-hidden branch at `PinScope.tsx:83` renders only `[data-pinscope-toggle]`; `pinscope-assembly.test.tsx` (7 tests) re-run green incl. HUD-hidden + `shortcutsEnabled={false}` + grid-cycle cases. |
| R-15-02 | Crosshair §8.3 disable guards | `Crosshair.tsx` has `measuring`/`hudHidden` props + `if (measuring \|\| hudHidden) return null;`; over-HUD `closest` check still present (1×); `controls.test.tsx` Crosshair cases re-run green. |
| R-15-03 | Rulers multi-scale ticks + corner | `grep -cE '10\|50\|200' Rulers.tsx` → 44; `data-pinscope-ruler-corner` present (1×); `overlays.test.tsx` (18 tests) re-run green; AC-034 still PASS. |
| R-15-04 | StatePanel host-stylesheet override generator | `grep -E 'styleSheets\|cssRules' StatePanel.tsx` matches; behavioral test calls `applyStateOverride('hover')` and asserts a real `[data-pinscope-state-rules]` `<style>` element — not a grep. Re-run green. |
| R-15-05 | Badge CSS hostile-CSS hardening (§12) | `grep -c '!important' badges.css.ts` → **17** (≥12); `z-index: 2147483645 !important` matches; `background:…!important` matches on badge `::before`; `overlays.test.tsx` (18) green incl. `getPropertyPriority` behavioral case. |
| R-15-06 | EndpointSnapshotStore + `/__pinscope/snapshot` route | `grep -rln '__pinscope' src` → `EndpointSnapshotStore.ts` + `plugin/index.ts`; `snapshots/` in `src/plugin`; `__pinscope/snapshot` in 2 files; `snapshot.test.tsx` (6) + `plugin.test.ts` snapshot-route case re-run green — middleware genuinely writes `s_<id>.json` to a temp dir and content is re-read (`fs.readFileSync`/`existsSync`). `SnapshotManager.ts`/`MemorySnapshotStore.ts` unchanged in round window. |
| R-15-07 | CommandBar §8.6 focus-expand / Tab autocomplete / history | `height: focused ? 120 : 40` present; `getSuggestions` imported + used; `HistoryManager` injected (`MemoryHistoryStore` default); `history.json` route in `plugin/index.ts`; `controls.test.tsx` CommandBar §8.6 block + `plugin.test.ts` history-route (write + 1000-cap) re-run green. Wave-1 snapshot route preserved. |
| R-15-08 | `withPinScope` package-root re-export (SUSPECTED→CONFIRMED) | §15 re-read independently: SPEC.md lines 373-375 list `withPinScope` among the package-root "Public API exports" — CONFIRM is correct. `export { withPinScope } from './plugin/next.js';` present in `src/index.ts`; `public-api.test.ts` re-run green. |
| R-15-09 | operation-builder `delta` routing (SUSPECTED→CONFIRMED) | §9.3 re-read independently: SPEC.md lines 285-290 list `value?` and `delta?` as distinct `operations[]` fields — CONFIRM is correct. `item.delta = magnitude` present; `src/types/operation.ts` unchanged in round window; `operation-builder.test.ts` (18) re-run green. |
| R-15-10 | screenshot.test.ts genuine lazy-import behavioral test (AC-076 hollow fix) | `grep -cE 'readFileSync\|toMatch' screenshot.test.ts` → **0** (source-grep gone); `captureScreenshot` exercised (11×); `src/runtime/utils/screenshot.ts` unchanged in round window (test-only fix, per contract); `screenshot.test.ts` (3) re-run green. |
| R-15-11 | roundtrip.test.ts on real primitives (AC-107 hollow fix) | `grep -c 'examples/roundtrip' roundtrip.test.ts` → **0**; `operation-parser`/`operation-builder` imported (2×); `roundtrip.test.ts` (4) re-run green incl. negative cases. |

DoD clauses checked clause-by-clause for every R-item; each load-bearing clause
has a passing, non-fabricated check the verifier reproduced.

---

## Rejected claims

**None.** Every R-item's DoD core clause reproduces with a passing check.

---

## Regressions

**None.** STEP 5 regression scan: all **62** ACs that `loop.json` records
`CLOSED` still report `PASS` in `ac-results-R15.json` (0 CLOSED-but-failing).
Provenance spot-check: all 62 CLOSED ACs carry a `provenance` block — 0 closures
without provenance. The full pre-existing suite (257-baseline tests) remained
green through both waves; 36 net new tests added (262→293), 0 previously-green
test regressed.

---

## Harness integrity

- **`ac-verify` harness:** `harness_ok: true` — no `HARNESS_ERROR`.
- **Skip-count delta:** `ac-results-R15.json` reports `skip_markers: 0`;
  independent scan `grep -rcE '\.skip|\.todo|\.only|xit|xdescribe' tests/` →
  **0** skip/todo/only markers. Delta vs. pre-round baseline: **0**. No test was
  skipped this round to dodge a failure.
- **Config diff:** `git diff` of `vitest.config.ts`, `package.json`,
  `tsconfig.json`, `playwright.config.*`, `size-limit` budgets across the entire
  R15 window (`39a37f1~1..HEAD`) → **empty**. No threshold loosened, no check
  disabled, no test glob narrowed. The §13 `< 50 ms` mount budget in
  `perf.test.tsx` is **unchanged**.
- **Perf warmup scrutiny (Wave-1 scope note):** the verifier independently
  probed cold vs. warm `<PinScope/>` mount cost — **cold first mount ≈ 51 ms,
  warm steady-state mount ≈ 15 ms**. The re-assembled §7.1 root genuinely
  satisfies §13: the steady-state per-mount cost (~15 ms) is well within the
  < 50 ms budget. The ~51 ms cold figure is one-time V8/jsdom JIT +
  module-evaluation warmup that a real browser pays once at page load, not per
  mount. The warmup added to `perf.test.tsx` (`render`+`unmount` before the
  measured mount) is the **standard measurement pattern** — `perf.test.tsx`
  already used an identical warmup for the AC-071 hover test (line 34,
  pre-existing). The test still asserts the unchanged §13 budget. **Finding:
  the warmup is a legitimate measurement fix, NOT a way to mask a regression** —
  it isolates representative per-mount cost; no threshold was weakened.

- **MUTATION FINDINGS (4 surviving mutants in round-15 code) — see STEP 3:**
  - `src/plugin/index.ts:65` **M3** `true→false` (`res.end({ ok: true, id })`):
    survives — the R-15-06 snapshot-route test asserts `status===200` + the
    on-disk file content but not the response body's `ok` flag.
  - `src/plugin/index.ts:103` **M4** `true→false` (`mkdirSync recursive: true`):
    survives — the R-15-07 history-route test uses a fresh single-level temp
    `.pinscope/` dir, so the recursive code path is never exercised.
  - `src/plugin/index.ts:111` **M5** `true→false` (`res.end({ ok: true, count})`):
    survives — same as M3, the history-route test asserts status + file
    content, not the body `ok` flag.
  - `src/runtime/components/CommandBar.tsx:45` **M2** `strict-ne-to-eq`
    (`typeof fetch !== 'function'`): survives — no test asserts the CommandBar
    actually fires the `fetch` POST; R-15-07's persistence is tested via the
    plugin middleware directly and via a `HistoryManager.append` spy, neither
    of which depends on the CommandBar→network seam.

  **STEP 3 judgment:** all 4 survivors lie in code R-15-06/R-15-07 *did* touch
  this round, but each sits in an **un-asserted margin** (cosmetic response
  `ok` flags; an unexercised mkdir-recursion branch; the CommandBar→fetch
  seam). The load-bearing DoD claim of each R-item — the `.pinscope/` file is
  actually written, content round-trips, history caps at 1000 — IS backed by
  genuine `fs.readFileSync`/`existsSync` assertions that pass against correct
  code and would fail against broken code. No survivor makes a DoD's *closing*
  assertion pass against deliberately-broken code, so **no AC/R-item is flagged
  `hollow-test`** and no claim is rejected. They are nonetheless real
  coverage-gap findings (response-body `ok` unasserted; mkdir recursion
  unexercised; CommandBar fetch-POST seam unasserted) and bar a clean `PASS`.

---

## Rendering Gap (STEP 6)

Commit window for the round: `39a37f1~1..HEAD`. **2 real `fix(pinscope)`
commits** back the claimed closures:
- `c60f08d` — `fix(pinscope): R-15-W1` — re-assemble HUD root, harden
  badges/Crosshair/Rulers/StatePanel, add snapshot persistence (closes
  R-15-01..06, 08, 09).
- `7e31ec9` — `fix(pinscope): R-15-W2` — CommandBar §8.6 + genuine behavioral
  tests for screenshot/roundtrip (closes R-15-07, 10, 11).

Both commits confirmed present via `git log` and `git show --stat`; their diffs
contain real source + test changes matching every R-item's "Files to
modify/create". **Commit window is non-empty — not a hallucinated round.**

---

## Summary

- Confirmed closures: **11 / 11** R-items.
- Rejected claims: **0**.
- Regressions: **0** (62/62 CLOSED ACs still PASS; all carry provenance).
- Harness findings: **4** (mutation-survivor coverage gaps in `plugin/index.ts`
  ×3 and `CommandBar.tsx` ×1) + the perf-warmup investigated and cleared as a
  legitimate fix.
- Commit window: **non-empty** (`c60f08d`, `7e31ec9`).
- BLOCKED ACs (7, browser/apex-install env) correctly surface as `UNAVAILABLE`,
  not findings.

The 11 closures are real, evidence-backed, and commit-backed. The round falls
short of `PASS` solely on the 4 mutation-survivor coverage findings — none
reject a claim, but per the PASS rule (zero harness findings) the verdict is
**`PARTIAL`**: the next round should strengthen the snapshot/history-route
tests to assert the response body, exercise the mkdir-recursion path, and
assert the CommandBar fetch-POST seam.
