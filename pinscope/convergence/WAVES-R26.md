# Waves — PS-R26
Status: complete
Round: 26
Plan gate: PASS

## Plan validation

**Result:** ACCEPTED

Audit against `framework/docs/REMEDIATION-STYLE.md` and the PS-R26 inputs (`audit-findings-R26.json`, `narrative-scan-R26.json`, `TEST-AUDIT-R26.md`):

| Check | R-26-01 | R-26-02 |
|---|---|---|
| Linked finding ID present | F-26-01 + NC-12-06 + AC-061 FAIL class-4 | F-26-03 |
| Severity | P1 | P3 |
| Root cause names defect (not symptom) | non-idempotent helper + MutationObserver self-feedback (not "tests are flaky") | stale `§15.5`/`§12.6` doc anchors point to non-existent subsections (not "comments wrong") |
| Ecosystem analysis (10 questions) | present | present |
| Execution plan | present (content anchors only) | present (content anchors only) |
| Acceptance criteria | 6 grep/exit-code predicates + mutation gate | 6 grep/exit-code predicates |
| Dependencies section | present | present |
| Risk assessment | present | present |
| Definition of Done mechanically checkable | yes — grep counts, vitest exit codes, ac-verify PASS count, mutation gate | yes — grep counts (=0 for stale, ≥1 for corrected), tsc + vitest exit codes |
| No raw `file:line` anchors in body | confirmed | confirmed |

**Scope-reduction sweep (cross-reference with R26 audit inputs):**
- F-26-01 (CONFIRMED P1) → covered by R-26-01.
- NC-12-06 (uncovered_unsatisfied, blocking) → covered by R-26-01.
- AC-061 FAIL-class-4 in `TEST-AUDIT-R26.md` → covered by R-26-01 (mutation-gated new test).
- F-26-03 (SUSPECTED P3) → covered by R-26-02.
- F-26-02 (SUSPECTED P3 — §15 vs §18 I-1 design tension) → explicitly deferred to ST-26-01 with rationale: SPEC bump vs code expansion is not auto-remediable; durable record exists in `narrative-scan-R26.md`. Deferral is reasoned, not silent.

No findings are silently dropped. No DoD checkbox is "looks right." No body references raw line numbers.

## Dependency analysis

R-26-01 and R-26-02 have **no inter-dependency**:
- R-26-01 owns `pinscope/src/runtime/utils/iframe-overlay.ts` and its sibling test file.
- R-26-02 owns `pinscope/src/index.ts` and `pinscope/src/runtime/constants.ts`.
- Neither reads any file the other writes in final form. R-26-02 is comment-only and does not change semantics for R-26-01's helper module.
- Both target the runtime layer (per `pinscope/SPEC.md` §12 / §15); no build-module vs runtime ordering applies. No APEX-integration surface is touched.

The dependency graph is two isolated nodes. Single wave is sufficient.

## Waves

### Wave 1 — iframe-overlay idempotency + SPEC anchor cleanup

R-items: **R-26-01**, **R-26-02**

Owner files (per R-item):
- **R-26-01:** `pinscope/src/runtime/utils/iframe-overlay.ts`, `pinscope/tests/unit/runtime/iframe-overlay.test.ts`
- **R-26-02:** `pinscope/src/index.ts`, `pinscope/src/runtime/constants.ts`

Snapshot (pre-wave): captured by orchestrator via `git stash create` per `/ps-heal` STEP 5.

Verification gate (post-wave, all must pass):
- `cd pinscope && npx vitest run tests/unit/runtime/iframe-overlay.test.ts --reporter=dot` exits 0 with **9** tests passing (8 prior AC-061 + 1 new R-26-01 case).
- `cd pinscope && npx vitest run --reporter=dot` exits 0 with **≥ 382** tests passing (R25 baseline 381 + 1).
- `cd pinscope && npx tsc --noEmit` exits 0.
- `node pinscope/convergence/lib/ac-verify.mjs --round 26 2>&1 | grep 'PASS'` shows ≥ 62 PASS (no AC regresses below R25 baseline).
- `grep -c 'querySelectorAll.*data-pinscope-iframe-overlay' pinscope/src/runtime/utils/iframe-overlay.ts` ≥ 1 (R-26-01 reconciliation present).
- `grep -n 'idempotent under repeated invocation' pinscope/tests/unit/runtime/iframe-overlay.test.ts` returns a line (R-26-01 test present).
- `grep -c '§15\.5' pinscope/src/index.ts` returns 0 AND `grep -c '§12\.6' pinscope/src/runtime/constants.ts` returns 0 (R-26-02 stale anchors gone).
- `grep -c '§15' pinscope/src/index.ts` ≥ 1 AND `grep -c '§12' pinscope/src/runtime/constants.ts` ≥ 1 (R-26-02 corrected anchors present).
- Mutation gate (R-26-01): removing the reconciliation pass causes the new test to go RED with assertion `expected 1, received 2` on `[data-pinscope-iframe-overlay]` count.

Rollback trigger (observable):
- Any of the 8 prior AC-061 tests regress to RED, OR the new R-26-01 idempotency test stays RED after the fix lands, OR `npx vitest run` fails on any file outside `iframe-overlay.test.ts`, OR `npx tsc --noEmit` returns non-zero.
- Rollback command: `git checkout pinscope/src/runtime/utils/iframe-overlay.ts pinscope/tests/unit/runtime/iframe-overlay.test.ts pinscope/src/index.ts pinscope/src/runtime/constants.ts`.

## Conflict matrix

| File | R-26-01 | R-26-02 |
|---|:---:|:---:|
| `pinscope/src/runtime/utils/iframe-overlay.ts` | write | — |
| `pinscope/tests/unit/runtime/iframe-overlay.test.ts` | write | — |
| `pinscope/src/index.ts` | — | write |
| `pinscope/src/runtime/constants.ts` | — | write |

No file is written by more than one R-item in Wave 1. Write-serial safety holds: one owner per file per wave.
