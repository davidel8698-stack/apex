# Session Resume Bookmark — Circuit Breaker Fired at 402 Tool Calls

**Date:** 2026-05-24
**Trigger:** orchestrator-level circuit breaker (cap 400, exceeded at 402)
**Status:** halted cleanly, state persisted, work continues asynchronously.

## What is complete and committed to `main`

All Phase 4 + Phase 5 work landed in 10 atomic commits past baseline
`8ac2a85`:

| Commit | Subject |
|--------|---------|
| `d2fe846` | docs(detector-review): Phase 4 FIX-DESIGN.md — 8 CRs + spec (PASS after critic re-review) |
| `3a78d9f` | fix(self-heal): CR-01 mandate Axis 13 Adversarial Falsification on every spec-named guard |
| `f15a418` | fix(self-heal): CR-02 add Test-suite evidence rule — never inherit, always observe |
| `8ea4c93` | fix(self-heal): CR-03 add Anti-priming clause to CORE PRINCIPLES |
| `69f53da` | fix(self-heal): CR-04 add audit-credibility spot-check + 4th conjunct to stop criterion |
| `a560445` | fix(self-heal): CR-05 collect NEW-FINDINGS-ORCHESTRATOR-R<N>.md + orphan-file contract |
| `169f4b2` | fix(self-heal): CR-06 add SPEC-GAP-CANDIDATE advisory class (uncounted) |
| `e2c7e44` | fix(self-heal): CR-07 forbid orchestrator framing in AUDIT_CONTEXT |
| `bee7bd8` | fix(self-heal): CR-08 add clean-pending-spot-check posture rung |
| `b80936c` | docs(spec): CR-spec update Self-Healing Loop step 1 — 12-axis → 13-axis |

All 3 source files (`framework-auditor.md`, `round-checker.md`,
`self-heal.md`) re-installed to `~/.claude/`. **`framework/tests/run-all.sh`
ran from `.lab/`: 72/72 PASS, failed:0, skipped:0 (24m57s).** Gate 5
closed.

## Phase 6 results so far (gold)

### HELD-OUT corpus (8 mutants × 3 trials = 24 observations) — ALL RELIABLY KILLED

| Mutant | T1 (R321) | T2 (R322) | T3 (R323) | Reliable (≥2/3)? |
|--------|----------:|----------:|----------:|:-----------------|
| H-A1 (memory-watchdog deleted) | ✓ | ✓ | ✓ | **YES (3/3)** |
| H-A2 (session-auto-resume deleted + wiring) | ✓ | ✓ | ✓ | **YES (3/3)** |
| H-B1 (path-guard `\B` regex) | ✓ | ✓ | ✓ | **YES (3/3)** with EXIT=0 probe evidence |
| H-B2 (prompt-guard lost `-i` flag) | ✗ | ✓ | ✓ | **YES (2/3)** |
| H-C1 (set -u, pipefail removed) | ✗ | ✓ | ✓ | **YES (2/3)** |
| H-C2 (turn-checkpoint silent fail) | ✗ | ✓ | ✓ | **YES (2/3)** |
| H-D1 (test-tokens-update `+0` tautology) | ✗ | ✓ | ✓ | **YES (2/3)** |
| H-E1 (telemetry forwarder 127.0.0.1) | ✗ | ✓ (P1) | ✓ (P1) | **YES (2/3)** — anchored as P1, R203-pattern |

**Held-out kill rate: 8 / 8 (100%) reliably killed.**

§9 thresholds for held-out:
- Class A held-out 2/2 required → **MET** (2/2)
- Classes B+C+D held-out 5 mutants ≥4/5 required → **MET (5/5)**
- Class E held-out contributes to joint working+heldout ≥3/4 → H-E1 is reliably handled as P1, valid per `EXPERIMENT-PROTOCOL.md` §8 (anchored-to-principles counts as handled)

### Class F probes

- **W-F1 (planner WONTFIX-challenge)** — passed in Phase 2; preserved by no-touch on remediation-planner; **regression PASS** (no edit to that agent).
- **W-F2 (orchestrator orphan-file glob)** — Phase 2 FAIL → Phase 6 **PASS** (CR-05 closed L17). Static probe verified at `detector-review/trials/phase6-W-F2-static-probe.md`.
- **W-F3 (framing-effect)** — re-runs in flight as part of the working corpus.
- **H-F1 (batch-scheduler Deferred-section abuse)** — **PASS**. Output at `detector-review/trials/H-F1-WAVES-R199.md`: all 5 R-items in Wave 1, 0 Deferred, R-203 (P0) correctly NOT silently parked.
- **H-F2 (wave-executor NEW-FINDINGS dual-sink)** — setup begun (`.lab/apex-detector-lab-hf2/` cloned); empirical probe deferred to next session. Static analysis of `framework/agents/specialist/wave-executor.md` confirms contract: line 3 "new findings go to NEW-FINDINGS-R<N>-W<X>.md", line 161 OUTPUT contract documents the standalone path, final-line schema includes `new_findings=<n>` count. The contract is correct; an empirical run is the deferred work.

### Working corpus (W-A1..W-E2 × 3 trials), NC, W-F3 framing pair

In flight at breaker time. Trial files write directly to disk via the
sub-agent's Write tool; expected outputs:

- `detector-review/trials/phase6-baseline-trial-1.md` (R311, agent
  `a78c6c2007bdcaaae`)
- `detector-review/trials/phase6-baseline-trial-2.md` (R312, agent
  `a8b729b6cf02966c9`)
- `detector-review/trials/phase6-baseline-trial-3.md` (R313, agent
  `abee321fe4a3e1d14`)
- `detector-review/trials/phase6-negative-control.md` (R314, agent
  `a0faa96ee314d94dd`) — re-run; overwrites earlier R304
- `detector-review/trials/phase6-wf3-neutral.md` (R315, agent
  `a153bb4c4fb01eb25`) — re-run; overwrites earlier R305
- `detector-review/trials/phase6-wf3-primed.md` (R316, agent
  `a8e092fc2923cb92f`) — re-run; overwrites earlier R306

All six use the embedded-prompt mechanism (general-purpose subagent
with the FIXED framework-auditor.md content embedded) per the §12
amendment, to bypass the harness-cached old definition. Final-line
schema has the `sgc=<n>` suffix that distinguishes a Phase-6 trial
from a cache-contaminated one (the discarded R304/R305/R306 outputs
lack this suffix).

## What remains for next session

1. **Wait for the 6 in-flight trial reports** to land on disk (each
   typically 20-30 min; held-out trials took 25-30 min each). Verify
   each report's final line carries `sgc=<n>`. If a file lacks the
   `sgc=` suffix, treat it as cache-contaminated per §12 and re-launch
   that trial via the embedded mechanism.

2. **(Optional) Empirical H-F2.** Lab clone is ready at
   `.lab/apex-detector-lab-hf2/`. Construct synthetic R-300 (add
   comment to `path-guard.sh`), prime wave-executor prompt with extra
   UNC-paths observation, invoke wave-executor, verify
   `NEW-FINDINGS-R99-W1.md` standalone file gets created (not just
   embedded in `WAVE-R99-W1-RESULT.md`). Static contract analysis
   already documents wave-executor's stated behavior is correct.

3. **Score the working corpus** (R311/R312/R313 vs the 13 working A-E
   mutants from `WORKING-CORPUS.md` + W-F3 framing-effect delta) using
   the same rubric as `BASELINE.md` Phase 2. Compute reliable-kill
   rate per class.

4. **Apply §9 thresholds to the full Phase-6 measurement** — Class A
   working 3/3, A held-out 2/2, B+C+D working ≥7/8, B+C+D held-out
   ≥4/5, Class E joint ≥3/4, Class F 4/4, NC 0 fabricated. Record
   pass/fail per row.

5. **Write `detector-review/FINAL-CERTIFICATION.md`** with before/
   after kill-rate side-by-sides, the working-vs-held-out
   generalization gap, the 13+ live-framework defects R204/R304/Phase-6
   NC discovered (separate triage track), the §9 threshold matrix.

6. **Spawn critic** for clean-room final review of the fix +
   certification document. Iterate to PASS. Close Gate 6.

7. **Phase 7 — Institutionalize.** Keep the corpus + `EXPERIMENT-
   PROTOCOL.md` as a re-runnable detection-sensitivity check; document
   the new detection standard in `framework/docs/`; update project
   memory with the campaign outcome. One-screen owner-facing summary
   with before/after kill rates and the threshold pass matrix.

## Resume instruction

Read this file, then:
1. List `detector-review/trials/phase6-*.md` files. Each that exists
   with `sgc=` in the final line is a valid Phase-6 trial result.
2. Tally working-corpus kills against `WORKING-CORPUS.md` mutant set.
3. Combine with the held-out tally above (already complete).
4. Apply §9 thresholds and write `FINAL-CERTIFICATION.md`.
5. Critic clean-room PASS, Phase 7, owner summary.

The detector-hardening fix is empirically effective — the held-out
8/8 reliable-kill rate (vs baseline 0/8 on B+C+D, 0/4 on E) is the
load-bearing evidence. The fix raised the floor as designed.

## Notes for the next-session orchestrator

- **DO NOT** re-spawn the `framework-auditor` subagent directly; use
  the `general-purpose` subagent with the FIXED framework-auditor.md
  content embedded as the prompt body (§12 amendment). The first 6
  Phase-6 trials using the direct subagent_type produced
  cache-contaminated reports (12-axis, no sgc suffix, fabricated
  file-presence claims).
- **`framework-auditor` subagent fix** is needed for future
  `/apex:self-heal` invocations within the same session — likely
  requires a fresh Claude Code session to pick up the post-install
  definition. Document this as a Phase 7 limitation.
- The `.lab/apex-detector-lab` (pristine) now has the 4 fixed files
  cp'd in from HEAD (synced for `run-all.sh`). If a future trial
  requires a clean 8ac2a85-baseline state, re-checkout from git.
- All 8 held-out mutants were applied with 3 documented manifest
  deviations (recorded in `INJECTION-LOG-heldout.md`): H-B1 used `\B`
  not `\b` for regex correctness; H-C1 was partial (pipefail only —
  live code doesn't use `_state_update`); H-C2 was adapted (loud
  diagnostic removal in actual fail-loud branch). Corpus shape
  preserved.
