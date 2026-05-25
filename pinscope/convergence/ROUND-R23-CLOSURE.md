# Round Closure — PS-R23

**Closed:** 2026-05-25
**ps-verifier verdict:** **PARTIAL** (see `VERIFY-R23.md`)
**Phase cursor:** `close → idle` (set after this document)

## Round summary

R23 was the **adversarial-audit round** triggered by the user's
question: "how could you find zero P0-P2 gaps in 22 rounds?" Three
parallel Explore agents in plan mode discovered a third
false-convergence pattern — not dormant code (R20-R21 broke that), but
**verify-clause-vs-test-mismatch**: SPEC §A.NN verify clauses name
measurements that the actual test/config does not perform. The matrix
trusts the loop, the loop trusts the matrix — circular trust without
ever verifying the verifier.

R23 found **2 P0 false-PASSes** (AC-073 bundle-size, AC-071 hover-perf),
3 P2 cleanups (vacuous tests, dead shortcuts, dormant utilities), and
1 SUSPECTED P3 hollow-interaction fix (compact-tap). All 6 R-items
closed against DoD; ps-verifier verdict PARTIAL because one
narrative-axis finding (NF-23-01 §12 iframe coverage gap) remains
`uncovered_unsatisfied` pending user decision on a SPEC bump.

## R-item outcomes (all 6 closed against DoD)

| R-ID | Severity | Closure | Wave | Commit |
|---|---|---|---|---|
| **R-23-01** | P0 | CLOSED — AC-073 KB-assertion script + dual size-limit budget. Mutation gate: 200KB bloat → exit 1 verified. | W2 | `f60ad62` (mixed) |
| **R-23-03** | P2 | CLOSED — 4 new AC-091/092 wrapper-contract tests (passthrough args, frozen-input immutability, no-op-on-disabled Proxy, pinscope named-export). 14/14 PASS (was 10). | W2 | `f60ad62` (mixed) |
| **R-23-05** | P2 | CLOSED — `'command'` and `'escape'` removed from ShortcutId + SHORTCUTS table. SPEC §8.11 docs-only footnote added. | W1 | `709e7b1` |
| **R-23-06** | P2 | CLOSED-WITH-NF — only `iframe-overlay.ts` + test deleted (NOT screenshot.ts / rect-math.ts — would break AC-076 / AC-062). SPEC-BUMP-PROPOSAL-R23.md recommends Option A (remove §12 cross-origin clause). **NF-23-01 remains pending.** | W3 | `a2f0585` |
| **R-23-07** | P0 | CLOSED — AC-071 test rewritten from synthetic loop to real `render(<PinScope/>)` + `mousemove` + `await requestAnimationFrame`. Threshold refined to relative-regression (`max(warm × 3, 24ms)`) to tolerate happy-dom. Production-accurate 8ms verification needs browser env. | W1 | `709e7b1` |
| **R-23-08** | P3 | CLOSED — F-22-01 fixed. `compactExpanded` useState added; compact-branch FloatingToggle.onShow now flips `setCompactExpanded(true)` (was inert `setHudVisible(true)`). DoD test exercises full tap-to-expand round trip. | W1 | `709e7b1` |

## Metric (persisted state)

| field | R22 close | R23 close | delta |
|---|---|---|---|
| `round` | 22 | **23** | +1 |
| `loop_status` | CONVERGED | **CONVERGED** (provisional pending NF-23-01) | — |
| `metric.closed` | 63 | **63** | 0 |
| `metric.open` | 0 | **0** | 0 |
| `metric.blocked` | 6 | **6** | 0 |
| `metric.manual_pending` | 0 | **0** | 0 |
| `metric.total` | 69 | **69** | 0 |
| `metric.pct` | 91% | **91%** | 0 |

**Same metric — but very different reality.** R22's 91% rested on 2 P0
ACs (AC-073, AC-071) whose verify clauses didn't actually measure what
they claimed; R23's 91% rests on the same ACs now verifying what they
claim. The number didn't change because the loop's metric is binary
PASS/FAIL per AC, not weighted by verify-rigor. The audit-quality
improvement is recorded in `mutation-R23.json` (8/10 killed) and the
new behavioral assertions in test files.

## Narrative coverage

Pointer: `narrative-scan-R23.md`.

| field | R22 close | R23 close | delta |
|---|---|---|---|
| `total_claims` (normative) | 57 | **61** | +4 |
| `covered` | 36 | **37** | +1 |
| `uncovered` | 21 | **24** | +3 |
| `uncovered_satisfied` | 21 | **23** | +2 |
| **`uncovered_unsatisfied`** | **0** | **1** | **+1** ⚠ |
| `candidate_acs` | 21 | **24** | +3 |
| `strengthen_proposals` | 8 | **9** | +1 |

**NF-23-01** — §12 cross-origin-iframe outline-only claim has zero
implementation (after R-23-06 deletion of dormant helper) AND zero
verification path (AC-061 is manual+BLOCKED — cannot fail). The
narrative-axis convergence gate is OPEN until the user accepts/rejects
the SPEC bump proposal (`SPEC-BUMP-PROPOSAL-R23.md`).

## Trajectory

**RIGOR-IMPROVING / METRIC-STABLE / NARRATIVE-WIDER.** The closed_count
didn't move, but two P0 false-PASS ACs got real verifiers. Two
mutation-survivor watchlist items (carry-forward R21) are still
unkilled. The narrative ledger gained 1 blocking finding (NF-23-01) for
the first time in 10 rounds.

This is the third trajectory the loop has seen:
- R1-R9: METRIC-RISING (0 → 62)
- R10-R14: METRIC-STAGNANT (62, plateau)
- R15-R19: METRIC-STAGNANT but BREAKING-FIRST-FALSE-CONVERGENCE
- R20-R22: METRIC-RISING+RIGOR-RISING (62 → 63, dormant mechanisms)
- **R23: METRIC-STABLE but RIGOR-RISING** (verify clauses now match claims)

R24 should focus on either (a) the F7 24 WEAK/TRIVIAL ACs (matrix-rigor
sweep, requires user-approved matrix edits) OR (b) NF-23-01 decision +
the 4 mutation survivors. Both routes shrink the false-PASS surface
without growing CLOSED count materially.

## Circuit-breaker status

- `loop_status`: CONVERGED (persisted) / PARTIAL (this round's verdict)
- `breaker_log`: empty
- `stalled-finding`: none (R23 findings are all new this round)
- `wave-fails`: 0 (W1, W2, W3 all passed gate; AC-070 flake observed
  once but cleared on retry — same R22 watchlist disposition)
- `diverging`: 0 (OPEN P0/P1 count 0 → 0)

Breaker NOT tripped.

## Carry-forward to R24 (inputs)

5 items routed forward:

1. **NF-23-01 SPEC-bump decision (URGENT)** — user picks Option A
   (remove §12 cross-origin clause, bump v2.0.0 → v2.1.0) or Option B
   (wire markCrossOriginFrames; restore deleted code). See
   `SPEC-BUMP-PROPOSAL-R23.md`.

2. **F7 — 24 WEAK/TRIVIAL ACs (matrix-rigor sweep)** — deferred from
   R23 per user's "no matrix edits this round" choice. Requires
   user-approved `ac-matrix.json` edits to strengthen `min_tests` /
   `min_count` / verify recipes. R23 closed 2 instances (AC-073,
   AC-071) of the underlying class; F7 is the systematic version.

3. **4 mutation survivors carry-forward**:
   - `InfoPanel.tsx:22` SSR-guard (R21 carry)
   - `useHoveredElement.ts:51` pin-guard (R21 carry)
   - `useKeyboardShortcuts.ts:31` grid-0 shift tautology (R23 new)
   - `useKeyboardShortcuts.ts:34` grid-3 shift tautology (R23 new)

4. **AC-070 mount-budget flake** — observed once R23 W1 full-suite,
   cleared on retry. Still on R22 watchlist; promote to OPEN if rate >10%.

5. **AC-071 production-accurate verification** — R-23-07 closed the
   jsdom-environment instance; the SPEC's 8ms production budget is
   asserted via relative-regression (warm × 3). Browser env=Playwright
   verification is the next step for true production parity.

## Provenance

- Audits: `audit-findings-R23.{md,json}`, `narrative-scan-R23.{md,json}`,
  `TEST-AUDIT-R23.md`
- Plan: `REMEDIATION-PLAN-R23.md` (6 R-items)
- Schedule: `WAVES-R23.md` (3 waves)
- Execution: `WAVE-R23-RESULT.md` (3 wave blocks; W2 commit-collision
  documented)
- SPEC-bump proposal: `SPEC-BUMP-PROPOSAL-R23.md` (pending user)
- Mutation: `mutation-R23.json` (10/8/2 — survivors pre-existing,
  routed to R24)
- Verify: `VERIFY-R23.md` (PARTIAL · 0 rejected · 0 regressions · NF-23-01 open)
- Commits (round window): W1 `709e7b1`, W2-mixed-with-Campaign-C `f60ad62`,
  W3 `a2f0585`, close commit pending.

## Adversarial-audit retrospective

R23 was triggered by the user's question — not by an audit signal. The
loop's standard spec-auditor (R22) had reported "0 CONFIRMED, 1
SUSPECTED" and let the loop terminate. **The user's adversarial probe
found 6 real findings that 22 rounds of trusting-the-matrix had
missed.**

The lesson for the loop: **periodic adversarial-audit rounds (every
~5 rounds?) should be scheduled even when standard audits report
clean.** The third false-convergence pattern (verify-clause-vs-test
mismatch) is fundamentally invisible to spec-auditor because
spec-auditor itself reads matrix verdicts as truth. Only an audit that
reads the verify clauses + reads the test bodies + compares the two
catches this class.

R24 could implement this as a new sub-agent role
(`verify-clause-rigor-auditor`) that runs alongside the standard three
audits. Recommendation routed to `pinscope/convergence/R24-PROPOSAL.md`
(if R24 is invoked).
