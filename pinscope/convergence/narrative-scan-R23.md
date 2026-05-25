# Narrative Scan — PS-R23

**Auditor:** narrative-auditor (sub-agent inline, orchestrator-recorded)
**Round:** 23
**Date:** 2026-05-25
**SPEC hash:** unchanged from R22 (frozen v2.0.0)

## Summary

| Metric | R22 | R23 | Delta |
|---|---|---|---|
| Total normative claims | 57 | **61** | +4 |
| Covered (AC-witnessed + code_satisfied) | 36 | **37** | +1 |
| Uncovered | 21 | **24** | +3 |
| Uncovered-satisfied | 21 | **23** | +2 |
| **Uncovered-UNsatisfied (blocking)** | **0** | **1** | **+1** |
| Candidate ACs (for future SPEC bump) | 21 | **24** | +3 |
| Strengthen proposals | 8 | **9** | +1 |

## The one blocking finding — NF-23-01

§12 cross-origin iframe outline-only behavior is a normative SPEC
claim with no covering AC AND no runtime code. AC-061 is manual+BLOCKED
— a manual check that never runs cannot fail when the claim is
violated, so per the coverage rule it does NOT cover the claim. The
helper `markCrossOriginFrames` exists but has 0 runtime consumers.

R-23-06 plans to delete `iframe-overlay.ts`. That deletion moves the
gap from "dormant helper exists" to "no code exists" — both states
violate the §12 claim.

**Two honest dispositions** (pending user decision):
1. **Wire the helper into PinScopeHud** + add a covering env=browser AC
   (still BLOCKED in node, but at least the claim has a witness shape).
2. **Propose a SPEC bump** (v2.0.0 → v2.1.0) removing the §12
   cross-origin-outline clause if the feature is genuinely deferred.

R-23-06 deletion is gated on this decision.

## Three new candidate ACs

These are normative SPEC claims that R22's audit missed entirely:

| Candidate | Source | Severity | Status |
|---|---|---|---|
| **AC-NEW-23** | NC-13-03 §13 "Selection update < 16ms (Critical)" | P1 | No code measurement |
| **AC-NEW-24** | NC-13-04 §13 "Grid mode switch < 32ms" | P3 | No code measurement |
| (NC-12-06 covering AC) | §12 cross-origin iframe | P3 | Awaits NF-23-01 decision |

All three require user-approved SPEC matrix additions. Recorded as
backlog for R24.

## New strengthen proposal — SP-23-01

**Target:** AC-073 (bundle size, P0)
**Current:** `package.json` size-limit has ONE entry `{ limit: '80 KB' }`.
**Issue:** SPEC §13 dual budget "80 KB minified AND 25 KB gzipped" — but
the 25 KB gz sub-budget is not enforced. A regression to e.g. 24 KB
minified + 30 KB gz (unlikely but possible) would silently pass.
**Proposed:** Split into TWO size-limit entries: one minified, one
gzipped. Pair with F-23-01 R-23-01 KB-assertion script.

## Deletion-safety warnings (CRITICAL for R-23-06 scope)

R-23-06 originally proposed deleting 3 utility files. The narrative
scan caught that 2 of them are AC-backed:

| File | Test consumer | AC | Verdict |
|---|---|---|---|
| `pinscope/src/runtime/utils/iframe-overlay.ts` | `iframe-overlay.test.ts` | AC-061 manual+BLOCKED | **SAFE TO DELETE** (but worsens NF-23-01) |
| `pinscope/src/runtime/utils/screenshot.ts` | `screenshot.test.ts` | AC-076 vitest-tag | **DO NOT DELETE** — would cause AC-076 CLOSED→FAIL regression |
| `pinscope/src/runtime/utils/rect-math.ts` | `edge-utils.test.ts` | AC-062 vitest-tag | **DO NOT DELETE** — would cause AC-062 CLOSED→FAIL regression |

R-23-06 scope must be corrected to delete only `iframe-overlay.ts`.

## R22 carry-forward (unchanged)

All 57 R22 NC ids retain their R22 status. NC-12-02 (>500 pins → 30fps
throttle + skip <16×16 badges) remains `code_satisfied: true` after
R-21-03 closure.

## Cross-auditor reconciliation note

The R23 spec-auditor found F-23-07 (AC-071 perf test does NOT measure
the rAF callback its verify clause names) — same shape as F-23-01
(AC-073 verify exits 0 without measuring KB). The narrative scan
strengthen proposal SP-23-01 is the **third** instance of the same
underlying pattern: a SPEC verify clause names a measurement the
test/config does not actually perform.

**Pattern: verify-clause-vs-test-mismatch.** Recommends R24 systematic
sweep across all `vitest-tag` and `command` ACs — read every
SPEC §A.NN verify clause, compare to what the actual test/command
does. The same false-PASS shape may exist in more ACs we haven't
caught.

## Validation

All JSON invariants pass:
- `covered + uncovered == total_claims` (37 + 24 = 61) ✓
- `uncovered_satisfied + uncovered_unsatisfied == uncovered` (23 + 1 = 24) ✓
- `blocking_findings.length == uncovered_unsatisfied` (1 == 1) ✓
- no duplicate claim_ids ✓
- spec_hash unchanged ✓
