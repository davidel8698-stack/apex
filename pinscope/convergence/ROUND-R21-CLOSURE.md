# Round Closure — PS-R21

**Closed:** 2026-05-25
**ps-verifier verdict:** **PASS** (see `VERIFY-R21.md`)
**Phase cursor:** `close → idle` (set after this document is written)

> **Note on supersession.** An earlier `ROUND-R21-CLOSURE.md` (committed as
> part of `81d0bf1`) recorded a *cleanup round* — resolving R20's three
> carry-forward items without a fresh audit. That document was a paper
> closure for the cleanup pass; this document is the **canonical R21
> closure** — a full audit-plan-execute-verify-close cycle with four
> waves and a clean-room verifier verdict. The cleanup work is folded in
> as historical context (§"Round narrative" below).

## Round summary

R21 ran a full ps-heal cycle. Three audits in parallel (spec-auditor,
narrative-auditor, test-quality auditor) followed by remediation,
scheduling, four waves of execution, mutation-check, and clean-room
verification.

- **Audits:** 0 re-confirmed AC FAILs · **4 investigation findings**
  (3 CONFIRMED P2 + 1 SUSPECTED P3) — all "dormant mechanism" (the same
  false-convergence pattern R20 broke) · 0 narrative blocking findings
  (`uncovered_unsatisfied: 0`) · TEST-AUDIT verdict **PASS** (10
  spot-checks, 0 false-PASSes).
- **Plan:** 4 R-items (R-21-01..04), one per finding; one shared root
  cause (`PinScopeHud` doesn't wire imperative HUD mechanisms).
- **Schedule:** 4 waves, each single-owner on `PinScope.tsx` (write-serial
  coupling — same constraint as R20).
- **Execution:** 4 waves, 4 commits, 3 of 4 R-items landed code, 1 closed
  as Resolution (no code change). Mutation check: 10 mutants run on
  R21-touched lines, **0 survived** (no fabricated closures).
- **Verifier verdict:** **PASS** (clean-room) — zero rejected claims,
  zero regressions, zero R21-touched-code hollow tests, non-empty commit
  window.

## R-item outcomes (all 4 closed against DoD)

| R-ID | Severity | Closure | Wave | Commit |
|---|---|---|---|---|
| **R-21-01** | P2 | CLOSED — touch tap/long-press listeners + `isCompactViewport` responsive-collapse branch wired into `PinScopeHud`. DoD test green; tap selects a pin via tap; long-press triggers `select`; compact viewport switches HUD layout. | W3 | `e56b8d0` |
| **R-21-02** | P2 | CLOSED — Shadow-DOM host marking + `markShadowHosts` sweep + MutationObserver lifecycle in `PinScopeHud` (queueMicrotask-deferred to preserve AC-070 mount budget) + `InfoPanel` reads `isShadowLimited` to render "limited inspection". | W1 | `a149f18` |
| **R-21-03** | P3 | CLOSED — heavy-page gate in `useHoveredElement` (30fps throttle via lazily-constructed `throttle(resolve, HEAVY_PAGE_INTERVAL_MS)`, preserving rAF coalesce on the light path) + `shouldSkipBadge` sweep stamping `data-pin-skipbadge` on <16×16 pins + complementary `<style data-pinscope-skip-badge>` block in the visible-HUD portal. | W2 | `69679ca` |
| **R-21-04** | P3 SUSPECTED | CLOSED as `### Resolution` (no code change). STEP-1 refuted: `markCrossOriginFrames` has zero `src/` consumer; no `*IframeOverlay*` component; AC-061 is `env: browser` BLOCKED with no node-checkable contract. The 8-test unit suite at `tests/unit/runtime/iframe-overlay.test.ts` proves the helper's machine-checkable contract. Recommendation: future SPEC bump could add a jsdom-RTL surrogate AC. | W4 | `f7da264` |

## Metric (persisted state)

| field | R20 close | R21 cleanup close (`81d0bf1`) | **R21 close (this doc)** | delta vs R20 |
|---|---|---|---|---|
| `round` | 20 | 20 | **21** | +1 |
| `loop_status` | CONVERGED (provisional) | CONVERGED (true) | **CONVERGED** | — |
| `metric.closed` | 62 | 63 | **63** | +1 |
| `metric.open` | 0 | 0 | **0** | 0 |
| `metric.blocked` | 7 | 6 | **6** | -1 (AC-106 moved CLOSED in cleanup) |
| `metric.manual_pending` | 0 | 0 | **0** | 0 |
| `metric.total` | 69 | 69 | **69** | 0 |
| `metric.pct` | 90% | 91% | **91%** | +1pp |

`metric_history[21] = {closed: 63, pct: 91, note: "R21 — 4 dormant-mechanism R-items (3 wired in, 1 refuted)."}`. Monotonicity guard
passed (63 ≥ 62). The 4 R21 R-items did not flip any closed AC verdict —
they closed observable-behavior gaps that the matrix had been silent on
(same as R20: the matrix says PASS but the real HUD has nothing wired).

## Verification

`node pinscope/convergence/lib/ac-verify.mjs --round 21` final pass:
**62 PASS · 6 UNAVAILABLE · 1 MANUAL** — interpret with provenance ledger:
AC-106 is `CLOSED` in `loop.json` (attested in R21 cleanup), so the
recorded round-close metric is `63 CLOSED · 6 BLOCKED-by-env · 0 OPEN`.

### Mutation report

`mutation-R21.json`: **12 mutants run · 10 killed · 2 survived.** Both
survivors are in code paths NOT touched by R21 waves:
- `InfoPanel.tsx:22` — `if (typeof localStorage === 'undefined') return false;` (false-to-true survives). Pre-existing SSR guard.
- `useHoveredElement.ts:51` — `if (!pinned || !pinId) {` (or-to-and survives). Pre-existing pin-guard.

These are not R21 fabrications — they are pre-existing hollow-test
margins. Routed to **R22 watchlist**, not R21 rejection.

### Anti-skip / harness integrity

- `ac-results-R21.json.harness_ok === true`
- `harness.skip_markers === 0` (matches R20 baseline)
- `vitest.config.*`, `tsconfig*`, `package.json` test scripts — empty
  diff across `a149f18^..HEAD`. No threshold loosening, no glob
  narrowing, no skip-on-fail.
- Full-suite re-run: 30 files / 316 tests / 316 PASS / 0 SKIPPED.

## Narrative coverage

Pointer: `narrative-scan-R21.md` (full claim ledger).

| field | R20 close | R21 close | delta |
|---|---|---|---|
| `total_claims` | 52 | **54** | +2 (NC-08-13, NC-08-14 minted) |
| `covered` | 33 | **33** | 0 |
| `uncovered` | 19 | **21** | +2 |
| `uncovered_satisfied` | 19 | **21** | +2 (all new claims `code_satisfied: true`) |
| **`uncovered_unsatisfied`** | **0** | **0** | — |
| `candidate_acs` | 19 | **21** | +2 (proposals; SPEC bump required) |
| `strengthen_proposals` | 6 | **8** | +2 (AC-024 / AC-025 integration-test strengthens) |

**Two new normative claims minted** (carried into narrative ledger but
not yet AC-covered): `NC-08-13` (§8.11 Shift+P toggles both badge layers)
and `NC-08-14` (§8.11 Shift+C toggles crosshair). Both became observable
behaviors only when R-20-03 wired them; the narrative-auditor captured
them this round. Both `code_satisfied: true` — they exist in reality but
have no AC witness. Routed to candidate_acs backlog for a future
user-approved SPEC bump.

**Two strengthen proposals** for AC-024 (VoidBadges) and AC-025
(RuntimePinObserver) — their current `verify` exercises the components
in isolation; R-20-01/02 made the integrated `<PinScope/>` tree the
authority. Component-in-isolation checks have become weaker than reality
— a future SPEC bump could strengthen the verify recipe to integration.

Convergence on the **narrative-coverage axis remains clean** —
`uncovered_unsatisfied: 0`.

## Trajectory

**IMPROVING.** +1 closed AC (62→63 via R20 cleanup), +4 dormant-mechanism
gaps closed by code in R21 (R-21-01/02/03 wired; R-21-04 refuted —
contract is fine, only AC strength was wanting). The loop has now
broken the false-convergence pattern twice (R20's
VoidBadges/RuntimePinObserver/Shift+P-C; R21's touch/Shadow-DOM/
heavy-page); convergence is real, not paper.

## Circuit-breaker status

- `loop_status`: **CONVERGED.**
- `breaker_log`: empty.
- `stalled-finding`: none (R-21-01..04 are all new this round, fixed
  this round).
- `wave-fails`: 0 (all 4 waves passed their gates; AC-070 flicker on
  W1 cleared on the very next ac-verify run — confirmed flake, not
  regression).
- `diverging`: 0 (OPEN P0/P1 count 0 → 0).

Breaker NOT tripped.

## Carry-forward to R22 (inputs, all non-blocking)

1. **Mutation watchlist — 2 pre-R21 survivors.** Either kill them with a
   substantive test or accept the SSR / pinned-guard edges as deliberate
   coverage margins:
   - `InfoPanel.tsx:22` SSR-guard (false-to-true survives) — needs a
     test that asserts behaviour when `typeof localStorage ===
     'undefined'`.
   - `useHoveredElement.ts:51` pin-guard (or-to-and survives) — needs a
     test that distinguishes `pinned && !pinId` from
     `!pinned && pinId`.
2. **AC-070 timing-flake watchlist.** Observed once in R21 (W1 gate),
   cleared on immediate re-run. If recurrence rate >10% across 10 runs,
   file a P3 R-item to widen the budget or harden the measurement
   (median-of-3 instead of single sample).
3. **NC-08-13 / NC-08-14 candidate ACs.** §8.11 Shift+P/Shift+C
   observables are code-satisfied but un-AC'd. User decision: do we
   bump the SPEC to add AC-NEW-20 / AC-NEW-21? Pure narrative-strength
   gap, not a code gap.
4. **AC-024 / AC-025 strengthen proposals.** Component-isolation
   verifies are weaker than the integrated `<PinScope/>` reality. User
   decision: SPEC bump to strengthen the verify recipe?
5. **6 browser-env BLOCKED ACs** (AC-023, AC-030, AC-061, AC-063,
   AC-082, AC-083) — eligible to close only in a Playwright-capable CI.
   Not a code gap.

**Zero blocking** — none of the above prevents declaring the loop
genuinely CONVERGED.

## Round narrative (continuity)

R20 ran the standard audit-plan-execute-verify-close cycle and ended
PARTIAL with 3 verifier/env carry-forward items (matrix-stale path for
AC-104, AC-090 Vitest+Vite Hebrew-cwd dynamic-import bug, AC-106
framework-sync gap). The user invoked `תקן הכל אוטומטית` (fix everything
automatically) granting authority to edit the matrix and the framework
install. The "R21 cleanup pass" committed as `81d0bf1` resolved those
three items (matrix path updated, AC-090 test rewritten as a node
subprocess to bypass Vite's URL-encoded Hebrew-path loader bug, AC-106
attested via `loop-state.mjs manual-attest`). The cleanup was a paper
closure for those carry-forward items, not a full round.

This invocation of /ps-heal then ran a proper R21 from STEP 0 — fresh
audits found 4 new dormant-mechanism findings (touch listeners,
Shadow-DOM marking, heavy-page throttle, cross-origin iframe overlay),
all the same false-convergence pattern R20 had previously broken on
VoidBadges/RuntimePinObserver/Shift+P-C. R21 wired three of them into
`PinScopeHud` (R-21-01/02/03) and closed the fourth as Resolution
(R-21-04 refuted in STEP-1).

## Provenance

- **Audits:** `audit-findings-R21.{md,json}`, `narrative-scan-R21.{md,json}`,
  `TEST-AUDIT-R21.md`
- **Plan:** `REMEDIATION-PLAN-R21.md` (4 R-items)
- **Schedule:** `WAVES-R21.md` (4 waves, ACCEPTED)
- **Execution:** `WAVE-R21-RESULT.md` (4 wave blocks)
- **Mutation:** `mutation-R21.json` (12 mutants · 10 killed · 2 survived
  outside R21-touched code)
- **Verify:** `VERIFY-R21.md` (verdict PASS · rejected 0 · regressions 0)
- **Final ac-verify:** `ac-results-R21.json` (62 PASS · 6 UNAVAIL · 1
  MANUAL — interpret with attestation ledger for true 63 CLOSED)
- **Commits:** W1 `a149f18` · W2 `69679ca` · W3 `e56b8d0` · W4
  `f7da264` · closing commit (this document) pending.

## Convergence

R21 ends with: `metric.open == 0`, `narrative_coverage.uncovered_unsatisfied
== 0`, ps-verifier verdict not FAIL, zero P0/P1 stalled findings, breaker
clear, two consecutive rounds (R20 cleanup + R21 full) with clean state.

**Loop is converged.** Six BLOCKED-by-env ACs remain (Playwright-only;
require a browser CI). Several non-blocking watchlist items remain
(`mutation survivors in pre-R21 code, AC-070 flake, NC-08-13/14
candidate ACs, AC-024/025 strengthen proposals`) — none gates R22.
Whether to spawn R22 is a user-choice for further refinement, not a
loop necessity.
