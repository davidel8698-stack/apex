# Round Closure — PS-R18 (lossy history persistence)

**Round:** PS-R18 — close the one residual gap a fresh audit of the R17-fixed
tree surfaced: `.pinscope/history.json` was double-written and lossy on the
§10-C operation flow.
**Status:** IN_PROGRESS — `loop_status: CONVERGED`, but the loop has not yet
declared termination (see Terminal condition).
**ps-verifier verdict:** `PASS`
**Date:** 2026-05-22

## Outcome

R18 opened as a convergence-confirmation re-audit:

- **spec-auditor (1A)** — 0 AC findings, 0 regressions; the 12-axis sweep
  surfaced **1 CONFIRMED off-matrix finding** (F-18-01).
- **narrative-auditor (1B)** — independently re-read all 52 normative claims;
  **0 blocking findings**, `uncovered_unsatisfied` 0.
- **auditor (1C, PinScope mode)** — verdict `WARN` (advisory): confirmed the
  R-17-03 fix resolved the AC-037 advisory; one advisory persists (AC-075
  perf-test tree depth/bound — advisory-only, non-blocking).

1 finding → 1 R-item → 1 wave, executed test-first, clean-room verified `PASS`.

## Findings remediated this round — 1 R-item, 1 finding

| R-item | Sev | Closes | Fix |
|--------|-----|--------|-----|
| R-18-01 | P2 | F-18-01 (CONFIRMED) | `.pinscope/history.json` was double-written (a `parsed: null` placeholder from `CommandBar` + the real `parsed: <Operation>` from `ClaudeBridge.send`) and lossy (only `CommandBar` persisted, so a session's final operation never reached disk). Root cause: history append+persist responsibility split across two sites with no owner. Fix: consolidate persistence into a single `HistoryManager`-owned hook — the persisted file now holds exactly the committed operations, in order, no duplicate/placeholder rows, last operation included |

R-18-01 independently re-verified closed by the clean-room `ps-verifier`: full
suite re-run **303/303**, `tsc --noEmit` exit 0, all 4 DoD clauses reproduced,
AC-053 (`ClaudeBridge.send` isolation test) intact, 0 rejected claims, 0
regressions, 0 harness findings.

## Acceptance criteria closed this round — 0

Metric holds at 62/69 — F-18-01 was an un-AC'd off-matrix gap.

## Convergence metric

| Round | Closed | Total | %   |
|-------|--------|-------|-----|
| PS-R16 | 62 | 69 | 90% |
| PS-R17 | 62 | 69 | 90% |
| **PS-R18** | **62** | 69 | **90%** |

CLOSED 62 · BLOCKED 7 · **OPEN 0**. Monotonic (closed non-decreasing). ✓

## Trajectory — STAGNANT (AC metric) · converging, near terminal

AC metric flat (90%); `p01_open` 0. The off-matrix finding stream continues
its monotonic decline:

| Round | Off-matrix findings | Top severity | Mutation survivors | Verifier verdict |
|-------|--------------------|--------------|--------------------|------------------|
| R15 | 11 | P1 | 4 | PARTIAL |
| R16 | 8 | P1 | 4 | PASS |
| R17 | 3 | P2 | 1 | PASS |
| R18 | 1 | P2 | 1 | PASS |

Finding count 11 → 8 → 3 → 1; top severity P1 → P1 → P2 → P2. The loop is
converging on its frozen North-Star — each round resolves a smaller, deeper
residue than the last. R19 is expected to be the terminal confirmation round.
The divergence breaker never approached.

## Still OPEN — 0 acceptance criteria

Zero `OPEN` ACs at every severity. One non-blocking carry-over to R19:

- **1 mutation survivor** — `or-to-and` at `CommandBar.tsx:49`, in an
  un-asserted margin of `isLocalOnlyCommand` (`measure` throws in the parser
  before reaching the line; `snapshot` is never submitted by any test). The
  R18 clean-room verifier injected the mutant empirically and confirmed it
  falsifies no test backing the R-18-01 closure — a coverage finding only, not
  a `hollow-test`; it did not bar the `PASS`. R19's audit decides whether it
  warrants an R-item.

## Still BLOCKED — 7 (all environment-gated, implementation present)

AC-023, AC-030, AC-082 (`browser`), AC-061, AC-063, AC-083 (`browser`),
AC-106 (`apex-install`). Unchanged; each unblocks verbatim on a capable CI.

## Circuit breaker

Clear. Never tripped across all 18 rounds. No re-plan this round.

## Narrative coverage

Per `narrative-scan-R18.md`: 52 normative claims · **33 AC-covered** ·
19 uncovered, **0 unsatisfied**. 19 candidate ACs + 6 strengthen proposals
remain recorded as **proposals** (adoption is a separate user-approved SPEC
version bump); they do not block. `uncovered_unsatisfied` = 0.

## Terminal condition — met by state, pending independent re-confirmation

> Convergence requires ALL of: zero `OPEN` criteria at P0–P2; every Phase-DoD
> AC `CLOSED`/`BLOCKED`; zero `uncovered_unsatisfied` narrative gaps; the last
> `ps-verifier` verdict not `FAIL`.

Every clause holds: 62 `CLOSED` / 7 `BLOCKED` / 0 `OPEN`;
`uncovered_unsatisfied` 0; verdict `PASS`. `record-round` set
`loop_status: CONVERGED`.

The loop **self-checks, it does not self-assert**: the STEP-2 convergence gate
fires only on a round whose `spec-auditor` reports **zero CONFIRMED findings** —
R18's reported 1 (F-18-01). The loop continues to **R19**: a fresh,
context-isolated audit. If R19's spec-auditor confirms zero off-matrix findings
(narrative gate clear, TEST-AUDIT not `FAIL`), R19 declares convergence at
STEP 2 and the loop terminates.
