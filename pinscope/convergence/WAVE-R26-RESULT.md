# Wave R26-W1 Result
Status: complete
Wave: 1
R-items: R-26-01, R-26-02

---

## R-26-01 — markCrossOriginFrames idempotency  (P1, closed)

### Files modified
- `pinscope/src/runtime/utils/iframe-overlay.ts` — added a reconciliation pass
  at the top of `export function markCrossOriginFrames(root: ParentNode = document): number`
  that queries `[data-pinscope-iframe-overlay]` on
  `(root as Node).ownerDocument ?? document`, materializes the NodeList with
  `Array.from(...)`, and removes each stale overlay before the existing
  `for (const frame of Array.from(root.querySelectorAll('iframe')))` sweep.
- `pinscope/tests/unit/runtime/iframe-overlay.test.ts` — appended
  `it('AC-061 / NC-12-06 — idempotent under repeated invocation (R-26-01)', ...)`
  inside `describe('Cross-origin iframe overlay (AC-061)', ...)`. The test
  creates a single cross-origin iframe with `data-pin="e_idem"`, invokes
  `markCrossOriginFrames(document)` twice, asserts one overlay survives,
  asserts the frame has `data-pin-iframe`, and asserts the surviving overlay
  contains `'e_idem'`.

### Test-first evidence (red -> green)

RED — before the fix (`cd pinscope && npx vitest run tests/unit/runtime/iframe-overlay.test.ts --reporter=dot`):

```
 ❯ tests/unit/runtime/iframe-overlay.test.ts  (9 tests | 1 failed) 111ms
   ❯ Cross-origin iframe overlay (AC-061) > AC-061 / NC-12-06 — idempotent under repeated invocation (R-26-01)
     → expected 2 to be 1 // Object.is equality

 Test Files  1 failed (1)
      Tests  1 failed | 8 passed (9)
```

GREEN — after the reconciliation pass (same command):

```
 ✓ tests/unit/runtime/iframe-overlay.test.ts  (9 tests) 115ms

 Test Files  1 passed (1)
      Tests  9 passed (9)
```

### Mutation-gate evidence

Block re-commented out (lines `const overlayHost = ...` through `stale.remove();`);
re-ran the same vitest command:

```
 ❯ tests/unit/runtime/iframe-overlay.test.ts  (9 tests | 1 failed) 94ms
   ❯ Cross-origin iframe overlay (AC-061) > AC-061 / NC-12-06 — idempotent under repeated invocation (R-26-01)
     → expected 2 to be 1 // Object.is equality

 Test Files  1 failed (1)
      Tests  1 failed | 8 passed (9)
```

Block restored; final re-run:

```
 ✓ tests/unit/runtime/iframe-overlay.test.ts  (9 tests) 81ms
 Test Files  1 passed (1)
      Tests  9 passed (9)
```

### Acceptance criteria — all checked

- [x] `Grep` `querySelectorAll.*data-pinscope-iframe-overlay` against
  `pinscope/src/runtime/utils/iframe-overlay.ts` (output_mode=count) -> 1
  (>= 1). PASS.
- [x] `Grep` `idempotent under repeated invocation` against
  `pinscope/tests/unit/runtime/iframe-overlay.test.ts`
  (output_mode=files_with_matches) -> file found. PASS.
- [x] `cd pinscope && npx vitest run tests/unit/runtime/iframe-overlay.test.ts --reporter=dot`
  -> exit 0, 9 tests passing. PASS (output captured above).
- [x] `cd pinscope && npx vitest run --reporter=dot` -> exit 0, 382 tests
  passing (R25 baseline = 381, delta = +1). PASS (output captured under
  R-26-02 section).
- [x] `node pinscope/convergence/lib/ac-verify.mjs --round 26` ->
  `ac-verify R26: 62 PASS · 6 UNAVAILABLE · 1 MANUAL`,
  `harness_ok: true`, 0 FAILs. PASS.
- [x] Mutation gate: removing the reconciliation pass -> the new test goes
  RED with `expected 2 to be 1`. PASS (output captured above).

---

## R-26-02 — stale doc-comment anchors  (P3, closed)

### Files modified
- `pinscope/src/index.ts` — line 1 doc comment `§15.5` -> `§15`.
- `pinscope/src/runtime/constants.ts` — line 12 doc comment `§12.6` -> `§12`.

### Acceptance criteria — all checked

- [x] `Grep` `§15\.5` against `pinscope/src/index.ts` (output_mode=count) ->
  0 (== 0). PASS. ("No matches found / Found 0 total occurrences across 0 files.")
- [x] `Grep` `§12\.6` against `pinscope/src/runtime/constants.ts`
  (output_mode=count) -> 0 (== 0). PASS. ("No matches found / Found 0 total
  occurrences across 0 files.")
- [x] `Grep` `§15` against `pinscope/src/index.ts` (output_mode=count) ->
  1 (>= 1). PASS.
- [x] `Grep` `§12` against `pinscope/src/runtime/constants.ts`
  (output_mode=count) -> 1 (>= 1). PASS.
- [x] `cd pinscope && npx tsc --noEmit` -> exit 0 (no output). PASS.
- [x] `cd pinscope && npx vitest run --reporter=dot` -> exit 0,
  `Test Files 32 passed (32) / Tests 382 passed (382)`. PASS.

Full-suite vitest output (proof for the 382-test count used above):

```
 Test Files  32 passed (32)
      Tests  382 passed (382)
   Start at  20:42:25
   Duration  9.86s
```

ac-verify harness output (proof for the harness AC above):

```
ac-verify R26: 62 PASS · 6 UNAVAILABLE · 1 MANUAL
→ ...\pinscope\convergence\ac-results-R26.json
```

`harness_ok: true` confirmed via
`node -e "const r = require('./pinscope/convergence/ac-results-R26.json'); console.log('harness_ok:', r.harness_ok)"`
-> `harness_ok: true`.

---

## Scope notes
Only the four files named in the plan were modified:
1. `pinscope/src/runtime/utils/iframe-overlay.ts` (R-26-01 source).
2. `pinscope/tests/unit/runtime/iframe-overlay.test.ts` (R-26-01 test).
3. `pinscope/src/index.ts` (R-26-02).
4. `pinscope/src/runtime/constants.ts` (R-26-02).

No `NEW-FINDINGS-W1.md` was created; nothing else broken was observed during
execution.

## Commit
- Hash: `9b56da68536aaf2940bafaf467fd9b8ae01008e6`
- Message: `ps-heal(R26 W1): close R-26-01 + R-26-02 — markCrossOriginFrames idempotency + stale §15.5/§12.6 anchors`
- Files in commit (4): `pinscope/src/index.ts`, `pinscope/src/runtime/constants.ts`,
  `pinscope/src/runtime/utils/iframe-overlay.ts`,
  `pinscope/tests/unit/runtime/iframe-overlay.test.ts`
  (insertions: 30, deletions: 2).
