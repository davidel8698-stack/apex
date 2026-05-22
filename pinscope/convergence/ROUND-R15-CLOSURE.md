# Round Closure — PS-R15 (false-convergence correction)

**Round:** PS-R15 — break a *false* convergence: `metric.open == 0` while the
shipping `<PinScope/>` root mounted only the inspection layer and the entire
measurement / control / state / operation HUD was built, individually
test-passing, but never wired into the product.
**Status:** IN_PROGRESS — loop has NOT converged (see Terminal condition).
**ps-verifier verdict:** `PARTIAL`
**Date:** 2026-05-22

## Outcome

R15 is the first round after four NO_FINDINGS re-audits (R11–R14). It did not
rubber-stamp them. Three context-isolated auditors ran:

- **spec-auditor (1A)** — 0 AC findings, 0 regressions, but the 12-axis free
  investigation surfaced **11 off-matrix findings** (9 CONFIRMED, 2 SUSPECTED):
  the assembled `<PinScope/>` was hollow. No AC asserts the §7.1 HUD assembly,
  so the matrix sailed past it — the 90% figure was a false convergence.
- **narrative-auditor (1B)** — 52 claims, 33 AC-covered, **9 blocking findings**
  (NF-15-01..09: real un-AC'd code gaps), corroborating the spec-auditor.
- **auditor (1C, PinScope mode)** — verdict `FAIL`: AC-076 and AC-107 were
  green only because their tests were hollow (a source-text grep; a
  self-fulfilling demo) — two false PASSes.

22 raw findings (13 distinct after de-dup) were planned into 11 R-items (one
plan rejected once for a silent scope reduction, then re-authored), scheduled
into 2 write-serial-safe waves, executed test-first, and clean-room verified.

## Findings remediated this round — 11 R-items, 13 distinct findings

| R-item | Sev | Closes | Fix |
|--------|-----|--------|-----|
| R-15-01 | P1 | F-15-01/02/03 · NF-15-01/02/03 | Re-assemble the §7.1 HUD root in `PinScope.tsx`; add `defaultGridMode`/`shortcutsEnabled` props; add `FloatingToggle` + HUD-hidden branch |
| R-15-02 | P2 | F-15-06 | Crosshair §8.3 disable guards (measurement mode, HUD hidden) |
| R-15-03 | P2 | F-15-05 | Rulers §8.2 multi-scale ticks (10/50/100/200) + live-coord corner |
| R-15-04 | P2 | F-15-08 · NF-15-06 | StatePanel §8.8 host-stylesheet override-rule generator |
| R-15-05 | P1 | F-15-04 · NF-15-08 | Badge CSS §12 hostile-CSS `!important` hardening |
| R-15-06 | P2 | F-15-09 · NF-15-07 | Snapshot persistence: `EndpointSnapshotStore` + `/__pinscope/snapshot` dev-server route |
| R-15-07 | P2 | F-15-07 · NF-15-04/05 | CommandBar §8.6: focus expand-to-120px, Tab autocomplete, history persistence |
| R-15-08 | P3 | F-15-10 · NF-15-09 | `withPinScope` package-root re-export (SUSPECTED → CONFIRMED vs §15) |
| R-15-09 | P3 | F-15-11 | operation-builder `delta` field routing (SUSPECTED → CONFIRMED vs §9.3) |
| R-15-10 | P2 | AC-076 | Replace hollow `screenshot.test.ts` with a genuine behavioral test |
| R-15-11 | P2 | AC-107 | Replace self-fulfilling `roundtrip.test.ts` with a real-primitives test |

All 11 independently re-verified closed by the clean-room `ps-verifier`: full
suite re-run **293/293**, `tsc --noEmit` clean, 0 rejected claims, every DoD
clause reproduced with a passing check.

## Acceptance criteria closed this round — 0

No AC moved to `CLOSED`; the metric holds at 62/69. By design: every R15
finding was an **un-AC'd** gap (off-matrix investigation finding or narrative
blocking finding) — the matrix never named them, so closing them moves no AC
counter. The remediation's effect on the matrix is the absence of a future
regression, not a metric bump.

## Convergence metric

| Round | Closed | Total | %   |
|-------|--------|-------|-----|
| PS-R13 | 62 | 69 | 90% |
| PS-R14 | 62 | 69 | 90% |
| **PS-R15** | **62** | 69 | **90%** |

CLOSED 62 · BLOCKED 7 · **OPEN 0**. Monotonic (closed non-decreasing). ✓

## Trajectory — STAGNANT (AC metric) · substantive off-matrix remediation

The headline AC metric is **STAGNANT** (90% → 90%, closed 62 → 62) and
`p01_open` is 0 (no divergence). But the metric is structurally blind to this
round's work: 11 R-items closed and a false convergence was corrected. The
*real* trajectory resolves at R16, when the narrative re-scan re-measures
`uncovered_unsatisfied` (expected 9 → 0) and the spec-auditor re-confirms the
11 investigation findings resolved. R15 is a correction round, not a
metric-movement round.

## Still OPEN — 0 acceptance criteria

Zero `OPEN` ACs at every severity. **But the round did NOT converge** — see
below. Two classes of work carry into R16:
1. The 9 narrative blocking findings (NF-15-01..09) were remediated but the
   fix is not yet re-scanned — `loop.json.narrative_coverage.uncovered_unsatisfied`
   still reads 9 (the stale R15 pre-fix scan).
2. **4 mutation-survivor coverage findings** (ps-verifier STEP 3): 3 in
   `src/plugin/index.ts` (un-asserted response-body `ok` flag ×2; an
   unexercised `mkdirSync recursive` branch), 1 in `CommandBar.tsx` (the
   CommandBar → `fetch` POST seam is unasserted). None rejects a R15 closure,
   but each is a real test-coverage gap → input finding for R16.

## Still BLOCKED — 7 (all environment-gated, implementation present)

AC-023, AC-030, AC-082 (`browser`), AC-061, AC-063, AC-083 (`browser`),
AC-106 (`apex-install`). Each unblocks verbatim on a capable CI; none masks an
absent deliverable. Unchanged from R14.

## Circuit breaker

Clear. Never tripped across all 15 rounds. One plan rejection this round
(STEP 4b, silent scope reduction) was resolved by a single re-plan — well
within the 2-attempt cap; no breaker condition approached.

## Narrative coverage

Per `narrative-scan-R15.md` (full detail there):

- 52 normative narrative claims · **33 AC-covered** · 19 uncovered.
- Of the 19 uncovered: 10 already satisfied (candidate ACs — paperwork) and
  **9 NOT satisfied** → blocking findings NF-15-01..09, all remediated this
  round (mapped into R-15-01/04/05/06/07/08 above).
- 19 candidate ACs + 6 strengthen proposals recorded — **proposals only**,
  adoption is a separate user-approved SPEC version bump; they do not block.
- `loop.json.narrative_coverage.uncovered_unsatisfied` = 9 (the R15 pre-fix
  scan). The R16 narrative re-scan re-measures it against the now-fixed code;
  convergence is gated on it reaching 0.

## Terminal condition — NOT met

> Convergence requires ALL of: zero `OPEN` criteria at P0–P2; every Phase-DoD
> AC `CLOSED`/`BLOCKED`; zero `uncovered_unsatisfied` narrative gaps; the last
> `ps-verifier` verdict not `FAIL`.

ACs: 62 `CLOSED` / 7 `BLOCKED` / 0 `OPEN` ✓. Verdict `PARTIAL` (not `FAIL`) ✓.
But `uncovered_unsatisfied` = 9 ✗ — `record-round` correctly holds
`loop_status: IN_PROGRESS`. The loop continues to **R16**: re-scan the
narrative against the remediated code, and remediate the 4 mutation-survivor
coverage findings this round's verifier surfaced.
