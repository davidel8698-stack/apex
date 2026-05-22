# Clean-Room Verification — PS-R18

**Verdict:** `PASS`

Round 18 carried one R-item (R-18-01, P2 — consolidate the split
`.pinscope/history.json` append+persist into a single HistoryManager-owned
hook, closing F-18-01). Independently re-verified clean-room: claim confirmed,
zero rejected claims, zero regressions, zero harness findings, non-empty commit
window. One mutation-coverage observation, non-blocking.

---

## Confirmed closures

### R-18-01 — history persist single-owner consolidation (closes F-18-01)

Checked clause-by-clause against the pre-written Definition of Done.

**DoD 1 — new red→green test exists and passes.** CONFIRMED.
Re-ran `npx vitest run tests/unit/runtime/history-persist-ownership.test.tsx`
independently → `1 passed`. The test renders the real `<PinScope/>`, stubs
`fetch`, captures every `/__pinscope/history` POST body, submits two
operation-kind commands (`e_7.bg → red`, `e_7.padding → 8px`) via the CommandBar
Enter path, and asserts on the last POST body: `entries.length === 2`; both
`entries[*].parsed` non-null `Operation`s with matching pin/property/value;
submission order (`entries[0].raw_input` / `entries[1].raw_input`); no duplicate
`raw_input`+`timestamp` pair; and the session's final operation
(`e_7.padding → 8px`) present in a persisted body. The executor's pasted RED
trace (`expected 3 to be 2`, `kinds=[null,op:sent,null]`) matches F-18-01's live
trace — failed for the right reason pre-fix.

**DoD 2 — single-persist-owner predicate.** CONFIRMED.
`grep -rn '/__pinscope/history' pinscope/src/runtime` → exactly one site:
`PinScope.tsx:116` (the `HISTORY_ENDPOINT` const consumed by the `persistHistory`
hook wired into the `HistoryManager` in the `command` useMemo). The local
`persistHistory`/`HISTORY_ENDPOINT` are gone from `CommandBar.tsx`
(`grep -rn 'persistHistory\|HISTORY_ENDPOINT' CommandBar.tsx` → 0 matches). The
other `fetch` calls in `src/runtime` are `EndpointSnapshotStore` (the unrelated
flow-D `/__pinscope/snapshot` route) — not a second history-persist path.

**DoD 3 — no placeholder duplication predicate.** CONFIRMED.
The single residual `parsed: null` in `CommandBar.tsx` (L117) is inside the
`isLocalOnlyCommand(command)` branch — reached only for `select`/`measure`/
`snapshot`, which produce no `Operation` and so correctly carry `parsed: null`
per §9.4. An operation/class/query submit appends nothing in `CommandBar.tsx`;
its one real `parsed: <Operation>` row comes from `ClaudeBridge.send`
(persistence-agnostic, untouched). The DoD-1 test directly asserts length-2 /
no-`parsed:null` / no-duplicate on the persisted body.

**DoD 4 — no regression.** CONFIRMED.
Re-ran the full suite independently: `npx vitest run` → `30 passed (30)` /
`303 passed (303)`. `npx tsc --noEmit` → exit 0. AC-053 isolated-`ClaudeBridge`
test (`claude-bridge.test.ts:77`, directly-constructed `HistoryManager` with no
persist hook) passes its `entries.length` `toBe(1)` assertion — the persist hook
is an optional constructor parameter, absent there, so isolated `append`
behaviour is unchanged. AC-054 autocomplete-latency and the 1000-entry cap test
pass unchanged.

All four DoD clauses rest on reproduced on-disk evidence; the wave's claims
matched independent re-runs exactly.

---

## Rejected claims

None.

---

## Regressions

None. All 62 `CLOSED` ACs in `loop.json` show `PASS` in `ac-results-R18.json`;
all 7 `BLOCKED` ACs (AC-023/030/061/063/082/083/106) show `UNAVAILABLE` for
their declared `browser`/`apex-install` env reason — expected, not regressions.
Provenance spot-check: every `CLOSED` AC carries a `provenance` block with a
`verify` descriptor and `closed_round`/`at` — no unverifiable closure.

---

## Harness integrity

- **Skip count:** 0. `grep -rEn '\.skip|\.todo|it\.only|describe\.only|xit\(|
  xdescribe\(' tests` → 0 — matches `ac-results-R18.json` `harness.skip_markers:
  0`. No test skipped this round to dodge a failure.
- **Config diff:** `git diff 651da1f~1 651da1f` over `vitest.config.*`,
  `playwright.config.*`, `package.json`, `tsconfig.json` → empty. No threshold
  loosened, no check disabled, no test glob narrowed. The R18 commit touches
  three source files, two test files, and the wave-result doc only.
- **Harness status:** `ac-results-R18.json` `harness_ok: true`; the `ac-verify`
  run did not exit HARNESS_ERROR.

No harness-integrity findings.

---

## Mutation check (STEP 3)

`mutation-R18.json`: 10 mutants, 9 killed, 1 survived.

- `PinScope.tsx` — 5/5 killed.
- `HistoryManager.ts` — 0 mutants run.
- `CommandBar.tsx` — 4/5 killed. **Survivor M3**, `or-to-and` at L49 of
  `isLocalOnlyCommand`: `kind === 'select' || kind === 'measure' && kind ===
  'snapshot'`. Because `&&` binds tighter, the mutant is `select || (measure &&
  snapshot)`; a single `kind` string can never be both, so the mutant reduces to
  `kind === 'select'`.

**Verdict on M3: coverage finding only — does NOT block R-18-01.**
Judged precisely: the mutant survives in an un-asserted margin, not a
load-bearing assertion.
- The binding DoD-1 closure test submits only **operation-kind** commands;
  `isLocalOnlyCommand` returns `false` for those under both the original and the
  mutant, so the closure test is unaffected. DoD 2/3/4 are grep/suite predicates
  independent of L49.
- Confirmed empirically: injected M3 into `CommandBar.tsx` L49 and re-ran
  `controls.test.tsx` → all 16 tests still passed. The `measure e_2 e_3` ArrowUp
  recall test does not kill it because `parseCommand('measure e_2 e_3')`
  *throws* (`Unrecognised command`), so `isLocalOnlyCommand` returns `true` via
  its `catch` branch — L49 is never reached for `measure`. No test submits a
  `snapshot`-kind command through the CommandBar, so the `snapshot` disjunct of
  L49 is unexercised.
- M3 therefore falsifies no test backing the R-18-01 closure. It is a pre-
  existing coverage gap in the `snapshot`/`measure` margin of `isLocalOnlyCommand`,
  reported as a coverage observation, not a `hollow-test` rejection.

No AC's closing test has a load-bearing surviving mutant.

---

## Rendering Gap (STEP 6)

Commit window for R18: **1 commit** — `651da1f` *"fix(pinscope): R-18-W1 —
consolidate history persist into a single HistoryManager-owned hook"*.
`git show --stat 651da1f` confirms it modifies the three source files the
R-item's Execution plan names (`HistoryManager.ts`, `PinScope.tsx`,
`CommandBar.tsx`) plus the new closure test and `controls.test.tsx`.
`src/plugin/index.ts` and `ClaudeBridge.ts` are untouched, honouring the
preservation contract. The commit window is non-empty — the claimed closure is
backed by real code.

---

## Summary

| Gate | Result |
| --- | --- |
| Rejected claims | 0 |
| Regressions | 0 |
| Harness findings | 0 |
| Commit window | 1 (`651da1f`) — non-empty |
| Mutation | 1 survivor, non-load-bearing — coverage finding only |

R-18-01 is a genuine root-cause fix: append-and-persist ownership is
consolidated onto the `HistoryManager` persist hook, the duplicate `parsed:
null` placeholder is eliminated for operation submits, and the session's last
operation now reaches disk. The off-matrix finding stream (11→8→3→1) is on track
to converge; round 19 may re-audit to closure.

**Verdict: `PASS`.**
