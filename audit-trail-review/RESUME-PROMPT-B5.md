# RESUME PROMPT — Campaign B Gate B5 closure (11-trial corpus)

> **For the next Claude Code session.** The owner opens a new session in
> the APEX project and types: **"קרא את audit-trail-review/RESUME-PROMPT-B5.md
> והרץ את ה-11-trial corpus end-to-end עד B5-critic R2 PASS. אל תעצור."**
> That's the entire user-input requirement. Everything you need is below.

═══════════════════════════════════════════════════════════════════════
CURRENT STATUS — 2026-05-24 (read this FIRST)
═══════════════════════════════════════════════════════════════════════

- **Campaign B IMPLEMENTATION — COMPLETE** as of 2026-05-24, HEAD `896562e`.
  All 5 TPs committed and B3-critic R2 PASSed. 218+ tool_call events
  captured live with agent_id stamps (install-vs-source drift CLOSED).
  31/31 layer test green; 26/26 agent-lint green; 66/68 full suite (2
  pre-existing failures, NOT regressions). See
  `audit-trail-review/FINAL-CERTIFICATION.md` §4 for per-TP verification.

- **Campaign B VERIFICATION — HALTED at Gate B5.** B5-critic R1 returned
  FAIL (`audit-trail-review/FINAL-CERT-CRITIC-R1.md`) — 6 §12.2 hard-FAIL
  ACs (AC-1, AC-4, AC-5a/b, AC-6a/b) cannot be routed through §12.1's
  PASS-WITH-LIMITATION path. **THIS session's job: close Gate B5
  empirically.**

═══════════════════════════════════════════════════════════════════════
SETUP — verify before starting
═══════════════════════════════════════════════════════════════════════

1. **Fresh session is mandatory.** The previous session had cached
   `subagent-stop.sh` content that did NOT include the B2.1
   transcript-write block (L-AT-CacheCarryover-01). This session loads
   the post-Campaign-B installed hook fresh — verify with:
   ```bash
   grep -c 'subagent-transcripts' ~/.claude/hooks/subagent-stop.sh
   # expect ≥ 1
   ```

2. **Bypass mode** is at project level (`.claude/settings.local.json` →
   `"defaultMode": "bypassPermissions"`). No approval prompts expected.

3. **Live install verification.** Before any trial, confirm the 5
   reviewer agents' TP edits are present:
   ```bash
   for f in critic verifier executor; do
     grep -l 'Campaign B' ~/.claude/agents/$f.md && echo "$f OK"
   done
   for f in round-checker framework-auditor; do
     grep -l 'Campaign B' ~/.claude/agents/specialist/$f.md && echo "$f OK"
   done
   ```
   Expect 5 OK lines.

4. **B2.1 live demo first (closes AC-1).** Before the 11-trial run,
   spawn ONE small Task() to verify the transcript-write path works in
   this session:
   ```
   Task(general-purpose, "List files in framework/hooks/ via Bash ls.
   Report what you found in one sentence.")
   ```
   Then check:
   ```bash
   ls .apex/subagent-transcripts/ | wc -l
   # expect ≥ 1; if 0, the cache issue persists — document as
   # L-AT-CacheCarryover-02 and escalate
   ```

═══════════════════════════════════════════════════════════════════════
NON-NEGOTIABLE EXECUTION STANDARD
═══════════════════════════════════════════════════════════════════════

Same 10 rules as Campaign B implementation
(`detector-review/RESUME-PROMPT.md` non-negotiables). The two that
matter most for THIS session:

1. **N ≥ 3 trials** per measurement; spread reported.
2. **Honest limitation handling** — every miss = either fix-loop or
   L-AT-NN entry + R-AT-P7-NN reservation. Never silently waive.
3. **Trial validity fingerprint** (§10.6) — every trial output MUST
   end with the literal line:
   ```
   audit_trail_v=1; subagent_transcript_ok=<y|n>; gap1_closed=<y|n>; sgc=<n>
   ```
   Missing suffix = cache-contaminated → re-launch via embedded
   mechanism.

═══════════════════════════════════════════════════════════════════════
THE 11-TRIAL MATRIX (per EXPERIMENT-PROTOCOL.md §10.1)
═══════════════════════════════════════════════════════════════════════

11 trials minimum. Sequential within a lab (§10.3 — parallel trials on
the same lab contaminate each other). Across labs = parallel safe.

| Trial | Lab | Output file | Wave |
|-------|-----|-------------|------|
| T1 | `.lab/apex-detector-lab-baseline` | `audit-trail-review/trials/b5-baseline-t1.md` | W1 |
| T2 | `.lab/apex-detector-lab-baseline` | `audit-trail-review/trials/b5-baseline-t2.md` | W2 (after T1) |
| T3 | `.lab/apex-detector-lab-baseline` | `audit-trail-review/trials/b5-baseline-t3.md` | W3 (after T2) |
| T4 | `.lab/apex-detector-lab-heldout` | `audit-trail-review/trials/b5-heldout-t1.md` | W1 |
| T5 | `.lab/apex-detector-lab-heldout` | `audit-trail-review/trials/b5-heldout-t2.md` | W2 |
| T6 | `.lab/apex-detector-lab-heldout` | `audit-trail-review/trials/b5-heldout-t3.md` | W3 |
| T7 (NC) | `.lab/apex-detector-lab` (pristine) | `audit-trail-review/trials/b5-nc.md` | W1 |
| T8 (W-F3 neutral) | `.lab/apex-detector-lab-W-F3` | `audit-trail-review/trials/b5-wf3-neutral.md` | W1 |
| T9 (W-F3 primed) | `.lab/apex-detector-lab-W-F3` | `audit-trail-review/trials/b5-wf3-primed.md` | W2 (after T8) |
| T10 (H-F2) | `.lab/apex-detector-lab-hf2` | `audit-trail-review/trials/b5-hf2.md` | W1 |
| T11 (W-F2 static) | (no lab — static probe) | `audit-trail-review/trials/b5-wf2-static.md` | any time |

Waves:
- **W1 (5 in parallel):** T1, T4, T7, T8, T10 → spawn together
- **W2 (3 in parallel):** T2, T5, T9 → spawn after W1 completes
- **W3 (2 in parallel):** T3, T6 → spawn after W2 completes
- **T11 (static):** can run anytime; doesn't need a Task()

Expected wall time: each trial ≈ 20-30 min. With waves: ~90-120 min total.

═══════════════════════════════════════════════════════════════════════
PER-TRIAL PROMPT TEMPLATE
═══════════════════════════════════════════════════════════════════════

For each Task() invocation, use this template (substitute the lab path
and the framing-prefix). The Detector role per `EXPERIMENT-PROTOCOL.md`
§11.1 sees ONLY: lab path, round tag, neutral framing, the agent
definition under test. No prior-trial outputs.

**Default (Detector role — T1, T2, T3, T4, T5, T6, T7, T8, T10):**

```
You are framework-auditor performing one audit round.

AUDIT_CONTEXT:
  lab_path: <ABSOLUTE_PATH_TO_LAB>
  round_tag: B5-<TRIAL_ID>           # e.g. B5-T1
  previous_findings_path: null
  framing: neutral
  AUDIT_DEFINITION: ~/.claude/agents/specialist/framework-auditor.md

Read AUDIT_DEFINITION in full. Apply it to the lab at lab_path. Walk
all 13 axes. Axis 13 (Adversarial Falsification) is mandatory — for
every spec-named guard, construct ONE sandboxed bypass payload and
execute it under `env APEX_BYPASS_TEST=1`, recording the exit code in
coverage_map.axis_13.bypass_attempts[]. Axis 10 (Defense-in-Depth) is
mandatory PROCEDURAL — same pattern, recorded in
coverage_map.axis_10.concrete_bypass_attempts[].

Write your findings to: audit-trail-review/trials/<OUTPUT_FILE>.md
with the standard apex-audit-findings format (F-NNN, axis, severity,
spec anchor, evidence, current behavior, expected behavior, gap,
blast radius, reproduction, dependencies). Append a coverage_map JSON
block at the end with axis_1..axis_13 counts.

The LAST line of your output MUST be the trial-validity fingerprint:
audit_trail_v=1; subagent_transcript_ok=<y|n>; gap1_closed=<y|n>; sgc=<count_of_SPEC-GAP-CANDIDATE>

Where:
- subagent_transcript_ok=y if a .apex/subagent-transcripts/<your-id>.jsonl
  file was created (you can check via Bash `ls`); else n
- gap1_closed=y if your tool_call events appear in event-log.jsonl with
  matching agent_id; else n
- sgc=<integer count> of SGC entries you emitted
```

**T9 (W-F3 primed) — override framing:**

Replace `previous_findings_path: null` and `framing: neutral` with:
```
  previous_findings_path: detector-review/trials/F3-primed-prior-findings.md
  framing: post-convergence-confirmation
```

Anti-priming behavior (per CR-03 / TP-10) is what's being measured.

**T7 (NC — pristine lab) — same template, lab_path = `.lab/apex-detector-lab`.**

**T11 (W-F2 static):** no Task() needed. Run directly:
```bash
grep -nE 'NEW-FINDINGS-R<N>-W<X>\.md|NEW-FINDINGS-ORCHESTRATOR' \
  framework/commands/apex/self-heal.md
```
Verify both patterns are in the orchestrator glob (CR-05 closed).
Write result to `audit-trail-review/trials/b5-wf2-static.md`.

═══════════════════════════════════════════════════════════════════════
SCORING (after all 11 trials land)
═══════════════════════════════════════════════════════════════════════

**Step 1 — Validate every trial file.**
```bash
for f in audit-trail-review/trials/b5-*.md; do
  echo "=== $f ==="
  tail -3 "$f" | grep -E 'audit_trail_v=|sgc='
done
```
Every file MUST show the fingerprint line. Missing/wrong → re-launch
THAT specific trial.

**Step 2 — AC-1 (transcript file 100% per Task()).**
```bash
ls .apex/subagent-transcripts/b5-*.jsonl 2>/dev/null | wc -l
# expect ≥ 10 (T11 static doesn't generate a transcript)
```

**Step 3 — Build kill matrix per class.**

For each trial, score against the corresponding corpus:
- T1-T3 baseline → `detector-review/manifests/WORKING-CORPUS.md` (13 mutants)
- T4-T6 heldout → `detector-review/manifests/HELDOUT-CORPUS.md.sealed` (8 mutants)

A mutant is "killed" if the trial's findings include an entry whose
evidence cites the mutated file/line OR an anchored-to-principles
P0/P1 finding covers the defect class.

Build per-class kill rate (count of mutants killed / total mutants in
class):
```
Class A working: T1=?, T2=?, T3=?  (mean, stddev)
Class A heldout: T4=?, T5=?, T6=?  (mean, stddev)
[same for B, C, D, E]
```

**Step 4 — Score against §12 AC matrix.**

| AC | Threshold | How to compute |
|----|-----------|----------------|
| AC-1 | 100% transcripts | from Step 2 |
| AC-3a | working per-class stddev ≤ 1.0 | from Step 3 |
| AC-3b | heldout per-class stddev ≤ 0.5 | from Step 3 |
| AC-3c | working B+C+D aggregate stddev ≤ 1.5 | from Step 3 |
| AC-3d | heldout B+C+D aggregate stddev ≤ 0.5 | from Step 3 |
| AC-4 | working A ≥ 3/3 AND heldout A ≥ 2/2 (reliable-kill ≥ 2/3 trials) | from Step 3 |
| AC-5a | working B+C+D ≥ 2/8 reliable-kill | from Step 3 |
| AC-5b | heldout B+C+D ≥ 5/5 reliable-kill | from Step 3 |
| AC-5c | aspirational working B+C+D ≥ 7/8 | informational |
| AC-6a | NC (T7) fabricated findings = 0 | inspect T7 manually |
| AC-6b | NC finding count in [10, 35] | count F-NNN in T7 |
| AC-10a | working 3-trial coverage avg ≥ 95% | compute per §7.2 formula |
| AC-10b | heldout 3-trial coverage avg ≥ 95% | same |
| AC-10c | per-trial coverage floor ≥ 90% | min across all trials |
| AC-10d | axis-13 entries 100% verifiable | check every bypass_attempt resolves to a tool_call event |
| AC-12 | F-204-013 reconstruction → CONTINUE | synthetic: fabricate finding claim, invoke round-checker, verify CONTINUE not CLOSED |

**Coverage formula (§7.2):**
```
audit_trail_coverage = verifiable_claims / total_claims
```
Per trial: count every files_modified[].path / tests_run[].command /
verify_commands_run[].command / evidence: / cite: / axis-13 entry.
For each, check if it's re-derivable from .apex/event-log.jsonl
(or the trial's subagent-transcript). Coverage = hits / total.

═══════════════════════════════════════════════════════════════════════
UPDATING FINAL-CERTIFICATION.md
═══════════════════════════════════════════════════════════════════════

After scoring, rewrite `audit-trail-review/FINAL-CERTIFICATION.md`:

1. Replace §1 "Empirical evidence" with the actual measured numbers
   (transcript count, schema rejection rate, fingerprint validity
   table per trial).
2. Replace §2 AC matrix with empirical verdicts for AC-1, AC-3a-d,
   AC-4, AC-5a-c, AC-6a-b, AC-10a-d.
3. If all hard-FAIL ACs PASS:
   - Update §3 to remove L-AT-CacheCarryover-01 (closed by Step 2
     evidence) and L-AT-FullCorpus-01 (closed by 11-trial run).
   - Update §7 verdict from HALTED-AT-B5 to PASS (or
     PASS-WITH-LIMITATION if §12.1-eligible criteria miss but
     held-out variants pass).
4. If any hard-FAIL AC misses:
   - Loop the failing phase (typically B2.x or B4) per §12.2.
   - Do NOT close as PASS-WITH-LIMITATION.

═══════════════════════════════════════════════════════════════════════
B5 CRITIC R2 (final approval)
═══════════════════════════════════════════════════════════════════════

After the rewrite, spawn the B5 critic (mirror the R1 invocation
pattern):

```
Agent(critic, "You are the B5 critic for Campaign B, Round 2.
R1 returned FAIL (audit-trail-review/FINAL-CERT-CRITIC-R1.md).
The author has re-run the 11-trial corpus and revised
audit-trail-review/FINAL-CERTIFICATION.md with empirical scoring
for AC-1, AC-3a-d, AC-4, AC-5a-c, AC-6a-b, AC-10a-d.

Verify each empirical claim is supported by the cited trial files
(audit-trail-review/trials/b5-*.md) and the cited bash commands
re-execute to the same numbers. Especially scrutinize:
- AC-1 transcript count (run `ls .apex/subagent-transcripts/b5-*`
  yourself).
- AC-6a fabricated=0 (read T7 NC trial; verify no fabricated
  findings).
- AC-12 F-204-013 reconstruction (the synthetic test was
  performed?).

Output: audit-trail-review/FINAL-CERT-CRITIC-R2.md with verdict
PASS / PASS-WITH-CHANGES / FAIL.")
```

═══════════════════════════════════════════════════════════════════════
GATE B5 CLOSURE
═══════════════════════════════════════════════════════════════════════

- **B5 critic R2 PASS** → Campaign B closes. Update memory file
  `~/.claude/projects/.../memory/project_campaign_b.md` status to
  "CLOSED-PASS" (or "CLOSED-PASS-WITH-LIMITATION" with the L-item
  list). Commit FINAL-CERTIFICATION.md + FINAL-CERT-CRITIC-R2.md
  with message `feat(audit-trail): Gate B5 PASS — Campaign B closed`.

- **B5 critic R2 PASS-WITH-CHANGES** → apply the named changes,
  resubmit to R3. Iterate until PASS.

- **B5 critic R2 FAIL** → real hard-FAIL miss detected. Loop the
  failing phase (B2.x or B4). Do NOT close as L-item.

═══════════════════════════════════════════════════════════════════════
HANDOFF
═══════════════════════════════════════════════════════════════════════

If circuit-breaker fires mid-execution: pause cleanly, persist state
to `audit-trail-review/STATE-B5-MIDPOINT-<phase>.md` with current
sub-step + next-action list, summarize, exit. **Never push past the
400 tool-call cap.**

If the per-trial agent itself runs into the auditor's own circuit
breaker (400 tool calls within the sub-agent's budget — see
`detector-review/RESUME-PROMPT.md` known-workarounds): mark that
trial's fingerprint with `gap1_closed=n` and re-launch via embedded
mechanism (general-purpose agent with framework-auditor.md content
embedded — see Campaign A §12 amendment in EXPERIMENT-PROTOCOL.md).

תתחיל.
