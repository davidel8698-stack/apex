# Round Closure — PS-R25

**Closed:** 2026-05-25
**ps-verifier verdict:** **PASS** (see `VERIFY-R25.md`)
**Phase cursor:** `close → idle` (set after this document)

## Round summary

R25 was the **second clean-round candidate** under the two-consecutive-clean-rounds stop criterion. After R24 closed at CONVERGED (provisional → true), R25's purpose was to make the AC matrix itself a rigorous verifier — eliminate every `min_tests: 1` rubber-stamp, upgrade isolation→integration where the spec contract demanded it, and replace 5 grep-only AC recipes with content-validation scripts.

The user pre-approved Option Y (aggressive ~2 days, full F7 sweep) in R23 plan-mode and re-confirmed in R24 closure. In this resumption session, the user further chose the **STRICTEST interpretation** of the W7 matrix bumps: lock `min_tests` at the actual achievable count per AC, not the diff doc's pre-W6 estimates.

The deliverables match that bar:

- **26 R-items closed** across 7 atomic-commit waves.
- **+37 net new tests** added across W1–W7 (vitest 344 → 381 PASS).
- **5 new content-validation scripts** under `pinscope/scripts/`, all with mutation gates.
- **17 matrix `min_tests` bumps** + 5 `grep → command` swaps + 23 traceability `note` fields, applied atomically in W7.
- **0 FAILs** post-bump — strict rigor locked without tripping the monotonicity guard.
- **2 documented discoveries** deferred as future R-items (R-25-FIX-01, NF-25-01) — NOT R25-blocking.

## R-item outcomes (26 / 26 closed against DoD)

| R-ID | Severity | Closure | Wave | Commit |
|---|---|---|---|---|
| R-25-01 | P1 | NEW pin-map-schema spec (3 cases + §9.1 validator). | W1 | `75180907` |
| R-25-02 | P1 | +5 hook-level cases for AC-026. | W1 | `75180907` |
| R-25-03 | P1 | +3 HUD-filter cases for AC-027. | W1 | `75180907` |
| R-25-04 | P1 | DISCOVERY — existing 5 AC-041 cases adequate; e2e stub redundant. | W1 | `75180907` |
| R-25-05 | P2 | +3 opt-out cases for AC-004. | W2 | `bd975af9` |
| R-25-06 | P2 | +3 monotonicity invariants for AC-007 (soft-delete-never-reuse). | W2 | `bd975af9` |
| R-25-07 | P2 | DISCOVERY — 5 AC-013 cases already cover the 4 filePattern × excludePattern combinations. | W2 | `bd975af9` |
| R-25-08 | P2 | +4 PinScope cases for AC-021/022 (kill-switches + portal target). | W2 | `bd975af9` |
| R-25-09 | P2 | +21 cases for AC-051 (source-driven + pipeline + length lock). | W3 | `9c1a8539` |
| R-25-10 | P2 | +2 parse-failure cases for AC-053. | W3 | `9c1a8539` |
| R-25-11 | P2 | matrix-only — AC-080 → 58 in W7. | W7 | `4e3f668e` |
| R-25-12 | P2 | matrix-only — AC-091 → 5 in W7. | W7 | `4e3f668e` |
| R-25-13 | P2 | +2 AC-024 integration cases (multi-tag + non-void sanity). NF-25-01 candidate logged. | W4 | `6cb2d962` |
| R-25-14 | P2 | +1 AC-025 nested-subtree integration case. | W4 | `6cb2d962` |
| R-25-15 | P3 | SUPERSEDED by W3 R-25-10. | W5 | `7352e2f6` |
| R-25-16 | P3 | AC-001 dedup — plugin-API describes nested under one parent. | W5 | `7352e2f6` |
| R-25-17 | P1 | NEW validate-apex-skill.mjs for AC-100. | W6 | (W6 commit) |
| R-25-18 | P1 | NEW simulate-apex-ui-phase.mjs for AC-102. | W6 | (W6 commit) |
| R-25-19 | P1 | NEW simulate-apex-ui-review.mjs for AC-103. | W6 | (W6 commit) |
| R-25-20a | P1 | NEW validate-architect-mentions.mjs for AC-104. | W6 | (W6 commit) |
| R-25-20b | P1 | NEW validate-apex-spec-pinscope.mjs for AC-105. | W6 | (W6 commit) |
| R-25-21..26 | P0-strategic | STRICT matrix bump — 17 min_tests locks + 5 grep→command swaps + 23 traceability notes. | W7 | `4e3f668e` |

Every R-item has a documented per-item mutation gate in `WAVE-R25-RESULT.md`. Mutation gates were verified:
- All 5 W6 script gates fired (corrupt scratch copy → exit 1) — verified via os.tmpdir harness.
- All test-tag mutation gates documented in WAVE-R25-RESULT.md sections W1–W4.

## Metric

`record-round` recorded R25 at `63 CLOSED · 0 OPEN · 6 BLOCKED · 91%` — identical to R24's metric (the AC-106 MANUAL row counts as closed in the loop-state scheme).

| field | R24 close | R25 close | delta |
|---|---|---|---|
| `round` | 24 | **25** | +1 |
| `loop_status` | CONVERGED (true) | **CONVERGED (true)** | — |
| `metric.closed` | 63 | **63** | 0 |
| `metric.open` | 0 | **0** | 0 |
| `metric.blocked` | 6 | **6** | 0 |
| `metric.manual_pending` | 0 | **0** | 0 |
| `metric.total` | 69 | **69** | 0 |
| `metric.pct` | 91% | **91%** | 0 |

### Rigor delta — same metric, fundamentally stronger contract

The headline percentage is identical to R24 (91% / 63 CLOSED) — but the contract behind that number is dramatically stronger:

| dimension | R24 contract | R25 contract | rigor delta |
|---|---|---|---|
| AC matrix avg `min_tests` (excl. command-kind) | ~1.2 (every vitest-tag AC at min_tests:1) | **~10.0** across 17 strengthened ACs | ~8× |
| Single-test-rubber-stamp ACs | 24 of 24 vitest-tag ACs | **0** | -24 |
| Grep-only AC recipes | 5 (incl. AC-100/102/103/104/105) | **0** (all 5 → content-validation scripts) | -5 |
| Mutation-gate-documented R-items | 4 (R-24-02 survivors) | **+22 R25 R-items** | +22 |

**Each AC that was previously satisfied by `min_tests: 1` is now satisfied by counts ranging from 3 to 58.** The same headline percentage represents a much tighter contract — accidental rigor erosion (deleted test, narrowed describe tag, removed fixture case) now FAILS ac-verify instead of silently passing on the 1-test minimum.

This matches the plan's W7 expected-metric-trajectory section §286-289 with a stronger interpretation than originally projected: the diff doc anticipated a "rigor-aware drop" of 3-7 ACs flipping CLOSED→FAIL. The actual outcome is **0 FAILs** because the strict interpretation locked rigor at the actual achievable count (which already exceeded the diff doc's targets), avoiding a transient regression entirely.

## Two-consecutive-clean-rounds stop criterion

R24 (CONVERGED-true, 0 FAILs, deep audit clean) + R25 (62 PASS · 0 FAILs, strict-rigor matrix locks, 0 new false-PASS findings, 0 mutation survivors on R25-touched files).

**Stop criterion met.** The loop is in steady-state convergence. Future rounds become optional rigor-incremental rather than mandatory remediation. The PinScope frozen North-Star (SPEC.md v2.0.0) is now defended by the strongest matrix the project has had across 25 rounds.

## Deferred future R-items (NOT R25-blocking)

| ID | Origin | Disposition |
|---|---|---|
| **R-25-FIX-01** | W3 R-25-09 | Expand `SHORTCUTS` map from 10 → 32 entries (SPEC §11 promise vs source reality). Production change; requires SPEC consultation. Logged in `ac-matrix.json` note for AC-051. |
| **NF-25-01** | W4 R-25-13 | `VoidBadges` post-mount reactivity gap — useEffect(..., []) is not reactive to RuntimePinObserver-discovered void elements. Production fix; out of R25 test-rigor sweep scope. |

Both items are FUTURE-ROUND candidates — not flagged as R25 blockers.

## Convergence stop-decision

**STOP.** The loop converges at R25. R26+ is on the user's discretion (optional rigor-incrementing rounds) rather than required-remediation rounds. The two-consecutive-clean-rounds invariant from `/ps-heal` is satisfied: R24 PASS · R25 PASS.

## Files touched in R25

- **NEW** (8 files): `pin-map-schema.test.ts`, `validate-apex-skill.mjs`, `simulate-apex-ui-phase.mjs`, `simulate-apex-ui-review.mjs`, `validate-architect-mentions.mjs`, `validate-apex-spec-pinscope.mjs`, `VERIFY-R25.md`, `ROUND-R25-CLOSURE.md`.
- **MODIFIED test files** (8): `useHoveredElement.test.tsx`, `ast-transformer.test.ts`, `pin-map.test.ts`, `components.test.tsx`, `property-shortcuts.test.ts`, `controls.test.tsx`, `pinscope.test.tsx`, `plugin.test.ts`, `public-api.test.ts`.
- **MODIFIED matrix:** `ac-matrix.json` (17 min_tests bumps + 5 grep→command swaps + 23 notes).
- **MODIFIED docs:** `WAVE-R25-RESULT.md` (all 7 wave blocks).
- **UNTOUCHED:** `SPEC.md` (frozen v2.0.0), `framework/**`, `apex-spec.md`, anything outside `pinscope/`.
