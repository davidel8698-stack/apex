# APEX Detection Standard — Self-Heal Pipeline Sensitivity Contract

> **Status:** authoritative. Authored post-detector-hardening campaign
> 2026-05-23 → 2026-05-24. Reference implementation: commits
> `3a78d9f` (CR-01) through `b80936c` (CR-spec) past baseline `8ac2a85`.
> Re-runnable sensitivity check: `detector-review/EXPERIMENT-PROTOCOL.md`.
> Frozen mutant corpora: `detector-review/manifests/WORKING-CORPUS.md`
> + `detector-review/manifests/HELDOUT-CORPUS.md.sealed`.

## 1. Why this exists

Before the detector-hardening campaign, the `/apex:self-heal` loop
was empirically non-deterministic in depth. Phase-2 measurement
(`detector-review/BASELINE.md`) showed:

- Same lab, same mutated framework, same neutral prompt shape, three
  trials of the `framework-auditor` agent. R201 caught 3/13 mutants
  in 114 tool calls. R202 caught 3/13 in 70 calls. R203 caught 13/13
  in 162 calls.
- The loop closed whenever the auditor's depth happened to land
  shallow. "Quiet" round was indistinguishable from "clean" round.
- R23 historically claimed "6 hits" for IMP-039 coverage; live grep
  returns 0. R24 ratified the fabricated count. F-204-013 was the
  empirical evidence.

The detection process WAS broken. This document is the post-fix
standard that prevents the failure mode from recurring.

## 2. The detection floor

The post-fix `framework-auditor` (live at `~/.claude/agents/specialist/
framework-auditor.md`, reference source at `framework/agents/
specialist/framework-auditor.md`) enforces a 13-axis investigation
with a procedural depth floor. Every Step-A invocation MUST produce
the following on disk:

- **A 13-axis coverage map** with explicit per-axis count + confidence
  rating. Axis 13 (Adversarial Falsification) row MUST carry
  `bypass_attempts=<n>` and `silent_failure_probes=<m>` per
  spec-named hook. A row with both counts at 0 is an incomplete
  audit, NOT a clean one.
- **A test-suite evidence line** under coverage-map "Test suite":
  either OBSERVED (literal `passed:/failed:/skipped:/errored:` line
  quoted verbatim from `run-all.sh`) OR BLIND SPOT (literal
  declaration + a P3 finding `Test-suite observation deferred`).
  Inheritance from prior rounds is FORBIDDEN.
- **An anti-priming declaration** in CORE PRINCIPLES that the
  orchestrator's framing of the round (round number, prior-findings
  content, labels like "post-convergence" / "confirmation" / "stable")
  is NOT evidence. A clean prior round is NOT evidence this round is
  clean. Audit depth must not vary with framing.
- **A SPEC-GAP-CANDIDATE section** (advisory, uncounted, after the
  regular findings list) for evidence-grounded observations that
  would be findings if the spec were extended to cover them.
- **A final-line `sgc=<n>` suffix** on `AUDIT_COMPLETE: ...` —
  separate from the P0/P1/P2/P3 counts.

## 3. The closure floor

The post-fix `round-checker` (live at `~/.claude/agents/specialist/
round-checker.md`) enforces a 4-conjunct stop criterion that
includes a load-bearing audit-credibility spot-check:

- **The 4th stop-criterion conjunct:** the audit's coverage map must
  show (a) every axis investigated with recorded evidence, (b) Axis
  13 exercised on every spec-named guard with a recorded exit code,
  AND (c) the test suite either OBSERVED or BLIND SPOT. "Two clean
  rounds" means "two DEEP clean rounds."
- **PROCESS step 6 — Audit-credibility spot-check.** Before
  declaring CLOSED on any P0+P1==0 round, the round-checker
  independently re-verifies 3 items from the audit's coverage map
  (preferring security guards + self-heal-loop files). A discrepancy
  emits a P1 under "Audit-credibility regression" + Status: CONTINUE.
- **A new posture rung — `clean-pending-spot-check`.** If P0+P1==0
  but spot-check is skipped/failed OR axis-13 records 0 attempts OR
  test-suite is BLIND SPOT/missing, posture maps to
  `clean-pending-spot-check` NOT `stable`. The user-facing word
  never lies on the audit's behalf.
- **Orphan-filename contract enforcement.** The orchestrator
  collects both `NEW-FINDINGS-R<N>-W<X>.md` AND
  `NEW-FINDINGS-ORCHESTRATOR-R<N>.md`; any other file matching
  `NEW-FINDINGS-*-R<N>*.md` is flagged as `orphan_new_findings` and
  becomes an open P1 under "Filename-contract regression".

## 4. The orchestrator floor

The post-fix `/apex:self-heal` command (live at `~/.claude/commands/
apex/self-heal.md`) enforces:

- **No priming, no framing in AUDIT_CONTEXT.** The orchestrator does
  NOT append free-form framing about convergence, confirmation,
  quiet rounds, stability, or the previous round's verdict to the
  task prompt or AUDIT_CONTEXT block. `previous_findings_path` is
  the only trajectory channel and carries data only.
- **Dual-pattern new-findings collection in Step E.** Both
  `NEW-FINDINGS-R<N>-W<X>.md` AND
  `NEW-FINDINGS-ORCHESTRATOR-R<N>.md` collected explicitly + orphan
  glob `NEW-FINDINGS-*-R<N>*.md` for rogue patterns.

## 5. Sensitivity re-measurement (continuous verification)

The frozen mutant corpora + experiment protocol form a re-runnable
detection-sensitivity check. To re-verify the detection floor at any
future date:

1. Clone the current framework HEAD to `.lab/apex-detector-lab-recheck/`.
2. Apply the 13 working A-E mutants per `detector-review/manifests/
   WORKING-CORPUS.md`.
3. Run the framework-auditor 3 times via the embedded-prompt
   mechanism documented in `EXPERIMENT-PROTOCOL.md` §12 amendment
   2026-05-24 (use `general-purpose` subagent with framework-
   auditor.md content embedded as prompt body, to bypass any
   session-cache contamination).
4. Score per `EXPERIMENT-PROTOCOL.md` §8 rubric. Compare against the
   recorded Phase-6 kill matrix in `FINAL-CERTIFICATION.md` §1.
5. Any regression past Phase-6 levels indicates a re-broken detector.

The held-out corpus (`HELDOUT-CORPUS.md.sealed`) was the anti-
overfitting test for the campaign. It is NOT re-used in routine
re-checks; reserved for the next campaign cycle's clean generalization
test if/when the fix is materially extended.

## 6. Phase-7 follow-up R-items (from the campaign's accepted limitations)

Three R-items are reserved for the next campaign cycle. They do NOT
block release of the current detector-hardening fix; they refine its
edges.

### R-DH-P7-01 — Axis 13.c source-literal carve-out scan

**Origin:** L-DH-01 in `FINAL-CERTIFICATION.md` §3. Working corpus
W-B1/W-B2/W-B3 (magic-string allowlists in destructive-guard,
exfil-guard, owner-guard) reliably-killed 0/3 by the current fix.
The held-out Class B (regex weakness, case-folding gap) reliably
killed 5/5 — the fix generalises to any Class B mechanism that
fails on standard contract-violating payloads but does NOT cover
the specific narrow class of magic-string allowlists.

**Edit:** add to `framework/agents/specialist/framework-auditor.md`
Axis 13 a third sub-pass: **13.c Source-literal carve-out scan.**
For every guard hook, grep its source for early-exit branches
(`exit 0`, `return 0`) conditioned on string-literal matches against
`$COMMAND`, `$FILEPATH`, or stdin envelope content (`grep -Fq`,
`grep -q`, `[[ $X == *literal* ]]`). Any such carve-out not
documented in `framework/docs/HOOK-CLASSIFICATION.md` or the spec is
a finding regardless of behavioral probe outcome.

**Acceptance:** working corpus W-B1/W-B2/W-B3 reliably killed in a
next-cycle Phase-6 re-run.

### R-DH-P7-02 — Raise framework-auditor tool budget 400 → 800

**Origin:** L-DH-02 in `FINAL-CERTIFICATION.md` §3. Every Phase-6
detector trial hit the breaker at 400-410 tool calls during Axis 13
probing. Axes 4, 6, 7, 11, 12 were BLIND SPOT in 3 of 6 trials.
W-D1/W-D2 (vacuous tests) and W-E1/W-E2 (credential string, dead
function) live in axes the trials didn't reach.

**Edit:** in `framework/hooks/circuit-breaker.sh` or via
`CONTEXT_BUDGET.json`, raise the per-task `max_tool_calls_per_task`
for Step-A `framework-auditor` invocations specifically from 400 to
800. Verify no behavioral regression on existing tests.

**Acceptance:** an 800-budget Phase-6 working-corpus re-run reaches
W-D1/W-D2/W-E1/W-E2 axes.

### R-DH-P7-03 — `test-subagent-cache.sh` + fresh-session documentation

**Origin:** L-DH-03 in `FINAL-CERTIFICATION.md` §3. The Claude Code
harness caches subagent definitions at session start; the post-
install `framework-auditor.md` and `round-checker.md` were not
picked up by the cache, forcing the Phase-6 trials to use the
embedded-prompt mechanism (§12 amendment 2026-05-24).

**Edit:** add `framework/tests/test-subagent-cache.sh` that
verifies the framework-auditor subagent picks up the post-install
definition on a fresh session (run installation, spawn subagent,
verify `sgc=<n>` suffix appears in summary line — the fix's
machine-verifiable fingerprint). Add a note to `framework/docs/`
that production self-heal invocations should run in a fresh session
after any fix-install.

**Acceptance:** `test-subagent-cache.sh` PASS on a fresh session
after `sync-to-claude.sh` install.

## 7. Live-framework defects surfaced by the campaign (separate triage track)

The campaign's NC + held-out + W-F3 trials surfaced 10 NEW kinds of
real live-framework defects the OLD detector missed. These are NOT
detection-pipeline issues — they are real gaps now visible because
the fixed detector's depth is higher. See `FINAL-CERTIFICATION.md`
§4 for the full list. Owner triage is a separate track.

## 8. Auditor's quoted output as the canonical signature

Every post-fix `framework-auditor` invocation must end with a
summary line carrying the fix's machine-verifiable fingerprint:

```
AUDIT_COMPLETE: <output_path> | findings=<count> | P0=<n> P1=<n> P2=<n> P3=<n> | sgc=<n>
```

The `sgc=<n>` suffix is the marker that the fix is active. A
post-install audit whose summary line lacks `sgc=<n>` indicates a
session-cache contamination (subagent loaded the pre-fix
definition); recover by switching to the embedded-prompt mechanism
or restarting the session.

## 9. Document mantle

This standard is the floor, not the ceiling. Any future edits to
`framework-auditor.md`, `round-checker.md`, or `self-heal.md` that
weaken any of §2-§4 above must be accompanied by:

1. A new §12 amendment in `EXPERIMENT-PROTOCOL.md` documenting the
   change and its rationale.
2. A re-run of the working-corpus + held-out sensitivity check
   showing no regression past Phase-6 kill rates.
3. A critic clean-room PASS on the new state.

The detector is no longer non-deterministically thorough. It is
procedurally thorough — every axis, every guard, every fail-loud
branch, every test-suite observation, every spot-check. Or it is
flagged as incomplete and the round refuses to close.
