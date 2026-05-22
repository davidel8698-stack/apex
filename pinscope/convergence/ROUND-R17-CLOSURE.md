# Round Closure — PS-R17 (residual flow-seam gaps)

**Round:** PS-R17 — close the three residual seam gaps a fresh audit of the
R16-wired tree surfaced: the §11 `select e_N` command not locking the
InfoPanel, a swallowed §10-D snapshot-persist error, and a hardcoded TopBar
`stateOverride`.
**Status:** IN_PROGRESS — `loop_status: CONVERGED`, but the loop has not yet
declared termination (see Terminal condition).
**ps-verifier verdict:** `PASS`
**Date:** 2026-05-22

## Outcome

R17 opened as a convergence-confirmation re-audit of the R16-remediated tree:

- **spec-auditor (1A)** — 0 AC findings, 0 regressions; the 12-axis free
  investigation surfaced **3 off-matrix findings** (1 CONFIRMED, 2 SUSPECTED):
  R16 wired most §10 flows, but three seams remained incomplete.
- **narrative-auditor (1B)** — independently re-read all 52 normative claims;
  **0 blocking findings**, `uncovered_unsatisfied` 0. The narrative gate is
  clear.
- **auditor (1C, PinScope mode)** — verdict `WARN` (advisory): R15/R16/R17
  test additions all confirmed substantive; 2 advisory notes (AC-037, AC-075).

3 findings → 3 R-items, scheduled into 3 single-R-item waves (all three touch
`PinScope.tsx`, so write-serial safety forced one R-item per wave), executed
test-first, clean-room verified `PASS`.

## Findings remediated this round — 3 R-items, 3 findings

| R-item | Sev | Closes | Fix |
|--------|-----|--------|-----|
| R-17-01 | P2 | F-17-01 (CONFIRMED) | Drop the orphan duplicate `SelectionManager` from `PinScope.tsx`'s `command` `useMemo`; route the §11 `select e_N` command through the canonical `SelectionManager` the `useSelectedElement` hook owns, so the command locks the InfoPanel (not just the click path) |
| R-17-02 | P2 | F-17-02 (SUSPECTED → CONFIRMED) | Flow D `onSnapshot` now `flush()`es the `EndpointSnapshotStore` with an observed `.catch()` (`console.warn`) — a `SnapshotPersistError` is surfaced, never a silent unhandled rejection; mirrors Flow C's convention |
| R-17-03 | P3 | F-17-03 (SUSPECTED → CONFIRMED) | Lift `StatePanel`'s component-local override state to `PinScopeHud` via an `onStateChange` callback; feed the live value to `<TopBar>`, replacing the hardcoded `stateOverride={null}`. Also resolves the AC-037 TEST-AUDIT advisory as a side effect |

All 3 independently re-verified closed by the clean-room `ps-verifier`: full
suite re-run **302/302**, `tsc --noEmit` exit 0, 0 rejected claims, 0
regressions, 0 harness findings. Both SUSPECTED findings carried a STEP-1
confirm/refute step — each was independently CONFIRMED before the fix landed.

## Acceptance criteria closed this round — 0

Metric holds at 62/69. As in R15/R16, every R17 finding was an **un-AC'd**
off-matrix seam gap — closing it moves no AC counter.

## Convergence metric

| Round | Closed | Total | %   |
|-------|--------|-------|-----|
| PS-R15 | 62 | 69 | 90% |
| PS-R16 | 62 | 69 | 90% |
| **PS-R17** | **62** | 69 | **90%** |

CLOSED 62 · BLOCKED 7 · **OPEN 0**. Monotonic (closed non-decreasing). ✓

## Trajectory — STAGNANT (AC metric) · strongly converging in substance

AC metric flat (90%); `p01_open` 0. But the substance is **converging hard**,
and the evidence is the finding stream itself:

| Round | Off-matrix findings | Top severity | Mutation survivors | Verifier verdict |
|-------|--------------------|--------------|--------------------|------------------|
| R15 | 11 | P1 | 4 | PARTIAL |
| R16 | 8 | P1 | 4 | PASS |
| R17 | 3 | P2 | 1 | PASS |

Finding count, top severity, and mutation survivors all fall monotonically
round over round — the loop is peeling successive real layers (mounting →
flow-wiring → residual seams), each smaller than the last. This is root-cause
convergence, not thrash; the divergence breaker never approached.

## Still OPEN — 0 acceptance criteria

Zero `OPEN` ACs at every severity. One non-blocking carry-over to R18:

- **1 mutation survivor** — `or-to-and` at `useSelectedElement.ts:24`. The R17
  clean-room verifier adjudicated it: the mutation sits in the SSR / null-pin
  guard margin, which carries no R-17-01 DoD assertion. Reported as a
  non-blocking coverage finding, **not** a `hollow-test` — it did not bar the
  `PASS`. R18's audit decides whether the guard margin warrants an R-item.

## Still BLOCKED — 7 (all environment-gated, implementation present)

AC-023, AC-030, AC-082 (`browser`), AC-061, AC-063, AC-083 (`browser`),
AC-106 (`apex-install`). Unchanged; each unblocks verbatim on a capable CI.

## Circuit breaker

Clear. Never tripped across all 17 rounds. No re-plan this round (STEP 4b
accepted the plan first pass).

## Narrative coverage

Per `narrative-scan-R17.md`: 52 normative claims · **33 AC-covered** ·
19 uncovered, **0 unsatisfied** — every normative behavior independently
re-confirmed satisfied. 19 candidate ACs + 6 strengthen proposals remain
recorded as **proposals** (adoption is a separate user-approved SPEC version
bump); they do not block. `uncovered_unsatisfied` = 0.

## Terminal condition — met by state, pending independent re-confirmation

> Convergence requires ALL of: zero `OPEN` criteria at P0–P2; every Phase-DoD
> AC `CLOSED`/`BLOCKED`; zero `uncovered_unsatisfied` narrative gaps; the last
> `ps-verifier` verdict not `FAIL`.

Every clause holds: 62 `CLOSED` / 7 `BLOCKED` / 0 `OPEN`;
`uncovered_unsatisfied` 0; verdict `PASS`. `record-round` set
`loop_status: CONVERGED`.

But the loop **self-checks, it does not self-assert**: the STEP-2 convergence
gate fires only on a round whose `spec-auditor` reports **zero CONFIRMED
findings** — R17's reported 1 (F-17-01). The loop continues to **R18**: a
fresh, context-isolated audit of the now fully mounted-and-wired tree. If R18's
spec-auditor confirms zero off-matrix findings (narrative gate clear,
TEST-AUDIT not `FAIL`), R18 declares convergence at STEP 2 and the loop
terminates.
