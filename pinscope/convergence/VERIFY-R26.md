# Verify Report — PS-R26
Status: complete
Verdict: PASS
Generated: 2026-05-27

## Inputs verified

- `pinscope/convergence/ac-results-R26.json` — 62 PASS · 6 UNAVAILABLE · 1 MANUAL · 0 FAIL · 69 total · `harness_ok: true` · `skip_markers: 0`.
- `pinscope/convergence/mutation-R26.json` — 1 mutant on `iframe-overlay.ts`, 1 killed, 0 survived.
- `pinscope/convergence/REMEDIATION-PLAN-R26.md` — read DoD predicates for R-26-01 (6 clauses) and R-26-02 (6 clauses).
- `pinscope/convergence/loop.json` — 63 ACs CLOSED; all spot-checks PASS with `provenance` block present.
- `git log -1 9b56da68 --stat` — exactly 4 files: `pinscope/src/index.ts`, `pinscope/src/runtime/constants.ts`, `pinscope/src/runtime/utils/iframe-overlay.ts`, `pinscope/tests/unit/runtime/iframe-overlay.test.ts` (+30 / −2).
- Wave executor's `WAVE-R26-RESULT.md` consulted as a claim only; not used as evidence.

## R-item verdicts

### R-26-01 — PASS

- DoD-1 (reconciliation query exists in source) — `Grep 'querySelectorAll.*data-pinscope-iframe-overlay' pinscope/src/runtime/utils/iframe-overlay.ts` → 1 match at line 38 (inside the R-26-01 reconciliation block at lines 32-41). **PASS.**
- DoD-2 (new test exists) — `Grep 'idempotent under repeated invocation' pinscope/tests/unit/runtime/iframe-overlay.test.ts` → 1 match at line 125 inside the new `it('AC-061 / NC-12-06 — idempotent under repeated invocation (R-26-01)', …)` case. **PASS.**
- DoD-3 (`npx vitest run tests/unit/runtime/iframe-overlay.test.ts --reporter=dot` exits 0 with 9 tests) — Re-ran: `1 file passed`, `9 tests passed`. Duration 1.07s. **PASS.**
- DoD-4 (full vitest exits 0, ≥ 382 tests) — Re-ran `npx vitest run --reporter=dot`: `32 files passed`, `382 tests passed`. Duration 9.54s. **PASS.**
- DoD-5 (`ac-verify --round 26` shows ≥ 62 PASS, no AC regresses) — Re-ran: `ac-verify R26: 62 PASS · 6 UNAVAILABLE · 1 MANUAL`. Idempotent vs prior result. **PASS.**
- DoD-6 (mutation gate: reconciliation pass kills a deliberate mutant) — `mutation-R26.json` lists 1 mutant on `pinscope/src/runtime/utils/iframe-overlay.ts`, killed, 0 survived. **PASS.**

Mutation-gate independent confirmation: file reports `summary.survived === 0` with `mutants: 1, killed: 1`. No surviving mutants on changed code.

Rendering Gap: confirmed real path. `iframe-overlay.test.ts` lines 125-140 invoke `markCrossOriginFrames(document)` twice on real jsdom DOM with a `makeCrossOrigin(frame, 'throw')`-rigged iframe appended to `document.body`, then asserts `document.querySelectorAll('[data-pinscope-iframe-overlay]').length === 1` AND `frame.hasAttribute('data-pin-iframe') === true` AND `overlays[0].textContent` contains `'e_idem'`. This exercises the exact branch added by R-26-01 (the `Array.from(overlayHost.querySelectorAll('[data-pinscope-iframe-overlay]'))` reconciliation purge at lines 37-41 of `iframe-overlay.ts`). No mock — direct DOM execution.

### R-26-02 — PASS

- DoD-1 (`§15.5` removed from `pinscope/src/index.ts`) — `Grep` count: 0 matches. **PASS.**
- DoD-2 (`§12.6` removed from `pinscope/src/runtime/constants.ts`) — `Grep` count: 0 matches. **PASS.**
- DoD-3 (`§15` still present in `pinscope/src/index.ts`) — `Grep`: line 1 `/** PinScope public API — see SPEC.md §15. */`. **PASS.**
- DoD-4 (`§12` still present in `pinscope/src/runtime/constants.ts`) — `Grep`: line 12 `/** Reserved z-index range — see SPEC §12 (max 32-bit signed int). */`. **PASS.**
- DoD-5 (`npx tsc --noEmit` exits 0) — Re-ran: tsc exit 0, no diagnostics. **PASS.**
- DoD-6 (full vitest exits 0, same count as after R-26-01) — Re-ran: 382 tests passed. **PASS.**

Rendering Gap: N/A. R-26-02 is a doc-comment-only change; no runtime path or test asserts the strings. The DoD predicates themselves (grep counts + tsc + vitest) are the verification.

## Regression scan

Scanned all 63 CLOSED ACs in `loop.json.criteria` against `ac-results-R26.json`:
- 62 CLOSED ACs verdict === `PASS`.
- 1 CLOSED AC (AC-106) verdict === `MANUAL` — this is **not a regression**. AC-106 has `verify.kind === 'manual'` and was closed via `manual_attestation` (R20, by `ps-heal-orchestrator-R21`, with provenance block + evidence). The harness reports `MANUAL` for it by design every round; the closure rests on the attestation, not on the ephemeral verdict. `last_verified_round: 26` shows the harness re-acknowledged the manual carrier this round.

Spot-checks (per mandate):
- AC-001 → `PASS` · loop CLOSED · provenance present.
- AC-026 → `PASS` · loop CLOSED · provenance present.
- AC-051 → `PASS` · loop CLOSED · provenance present.
- AC-090 → `PASS` · loop CLOSED · provenance present.
- AC-102 → `PASS` · loop CLOSED · provenance present.

No regressions. No CLOSED AC without a provenance block.

## Harness integrity

- `it.skip` / `it.todo` / `describe.skip` / `it.fails` / `it.only` / `describe.only` count in `pinscope/tests/` — **0 hits** (Grep returned no matches across the directory). No skip markers introduced.
- `ac-results-R26.json.harness_ok` — `true`.
- `ac-results-R26.json.harness.skip_markers` — `0`.
- `ac-results-R26.json.harness.config_hash` — `sha256:1a4076caa8e0bef39abd848c9fc35c056f275e3b7f351cd756187ed3055f149c` (recorded; no anti-skip findings imply no config tampering).
- `ac-verify` re-run produced identical counts (62/6/1) — idempotent, no HARNESS_ERROR.

## Hollow-test check

- R-26-01 new test (`iframe-overlay.test.ts` lines 125-140) asserts:
  - `overlays.length === 1` — **tight bound** (exact equality, not `> 0`). PASS.
  - `frame.hasAttribute('data-pin-iframe') === true` — **tight bound** (boolean equality). PASS.
  - `overlays[0]?.textContent` `.toContain('e_idem')` — content-bound, validates the label sourcing (`data-pin` first, not host). PASS.
- Mutation report confirms a deliberate break of the reconciliation pass produced a killed mutant (would have yielded `overlays.length === 2`, caught by the tight `=== 1` assertion).
- R-26-02 changes are doc-comments only; no test surface to evaluate.

No hollow tests.

## Provenance

- Commit `9b56da68` author/date/message: `david` · `2026-05-27 20:46:14 +0300` · `ps-heal(R26 W1): close R-26-01 + R-26-02 — markCrossOriginFrames idempotency + stale §15.5/§12.6 anchors`.
- Commit lists exactly the 4 prescribed files (REMEDIATION-PLAN-R26 "Conflict matrix"): **confirmed.** No extras, no missing files. Diff stats: 30 insertions / 2 deletions across the 4 paths.

## Rendering Gap (round-window commit check)

- Round window has 1 commit (`9b56da68`). R-26-01 and R-26-02 each map to specific file changes inside that commit. Non-empty commit window — closures are backed by real code on disk.

## Final verdict

**PASS** — all 12 DoD predicates (6 per R-item) re-verified independently with passing evidence; full vitest 382/382 GREEN; tsc exit 0; ac-verify idempotent at 62 PASS · 6 UNAVAILABLE · 1 MANUAL · 0 FAIL; mutation gate 1 killed / 0 survived; harness `harness_ok: true` with 0 skip markers; commit `9b56da68` carries exactly the 4 prescribed files; 0 actual regressions across 63 previously-CLOSED ACs; new R-26-01 test exercises real jsdom DOM with tight `=== 1` bounds.
