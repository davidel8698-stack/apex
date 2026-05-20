---
description: APEX framework self-healing loop. Runs audit→plan→schedule→execute→check rounds until convergence (2 consecutive rounds with 0 P0/P1) or max-rounds cap. Anchored on apex-spec.md.
---

<context>

## ARGUMENTS

Optional flags (parse from invocation):
- `--max-rounds N` (default 10) — safety cap on total rounds.
- `--resume` — internal flag passed by /apex:resume; skips first-run
  initialization and reads `current_step` from `STATE.self_heal`.

No `--from-round` override in v1 — round detection is automatic via
First-Run Initialization.

## PROPOSALS MODE GUARD

Read `.apex/STATE.json` → `proposals_mode`. If `proposals_mode == true`:
NEVER ask open-ended questions in this command. The self-heal loop is
fully autonomous; it never solicits user input mid-loop.

## VISUAL IDENTITY

Read `~/.claude/apex-branding.md` before producing output. Render
Section 13 status bar at major transitions (round start, round close,
loop close). Render the signature line at end of every output.

## REPO ROOT RESOLUTION

Resolve repo root once at start:
```
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
```
If empty (cwd is not a git repo): output a clear error and exit. All
artifact reads/writes use `$REPO_ROOT/<filename>` for the round
artifacts.

## BREAKER COUNTER MANAGEMENT

`circuit-breaker.sh` increments `STATE.circuit_breaker.total_tool_calls_this_task`
on every Bash PostToolUse. The counter caps at
`max_tool_calls_per_task` (default 80, often bumped to 400). A
self-heal round legitimately spans 5 sub-agents × multiple waves —
far more total Bash invocations than fit in a single per-task budget.

**Each step transition (A→B, B→C, C→D, D→E, E→next-round) AND each
wave boundary inside Step D is a fresh "task" from the breaker's
perspective.** Reset the breaker counters at every such transition
using this snippet (call it `RESET_BREAKER`):

```
source framework/hooks/_state-update.sh
APEX_HOOK_SOURCE=self-heal _state_update '
  .circuit_breaker.total_tool_calls_this_task = 0
  | .circuit_breaker.consecutive_no_change_actions = 0
  | .circuit_breaker.last_file_hash = null
  | .circuit_breaker.triggered = false
  | .circuit_breaker.trigger_reason = null
'
```

Reset points (mandatory):
- After First-Run Initialization, before Step A
- After persisting `current_step = "plan"` (entering Step B)
- After persisting `current_step = "schedule"` (entering Step C)
- After persisting `current_step = "execute" | current_wave = 1` (entering Step D, first wave)
- Before each subsequent wave inside Step D (after `current_wave += 1`)
- After persisting `current_step = "check"` (entering Step E)
- At the start of each new round in the main loop (after incrementing `current_round`)

The `consecutive_no_change_actions` and `last_file_hash` reset is also
included because audit/plan/schedule/check sub-agents legitimately do
not change source files (they only write artifacts at repo root,
which depending on filter rules may not register as "changes" to the
breaker's `git diff HEAD` snapshot). Without resetting, the no-change
breaker would also trip falsely.

**This does NOT raise the per-unit cap or weaken the breaker.** Each
unit (step or wave) still gets its own 400-call budget. The breaker
still fires if a single unit genuinely runs away.

## POST-TASK FILE VERIFICATION

After every `Task()` invocation in this orchestrator, verify the
expected output file is on disk before trusting the agent's
final-line summary. If the file is missing:

1. Mark the corresponding step or wave as **BLOCKED** in STATE.
2. Do **not** reconstruct the file from the agent's inline content —
   that masks the protocol violation and trains agents to skip the
   file write.
3. For Step D wave failures: break the wave sub-loop and proceed to
   Step E with `partial_round=true`. The round-checker will see the
   missing wave result and surface it as DEFERRED.
4. For Steps A/B/C/E: halt the round (`status = "halted"`,
   `trigger_reason = "agent did not write <expected_file>"`) and
   exit. The user reruns `/apex:self-heal` after investigating.

Verification is a single Read or `test -f` call. Cheap, mandatory.

## FIRST-RUN INITIALIZATION

If `--resume` was NOT passed, run this initialization before Step A.

1. Read `.apex/STATE.json` → `self_heal` (may be absent).

2. If `self_heal` is absent OR `self_heal.status == "idle"`:

   a. Scan `$REPO_ROOT` for the highest existing
      `apex-audit-findings-R<N>.md` (call it `M`, `0` if none) and the
      highest `ROUND-R<N>-CLOSURE.md` (call it `K`, `0` if none).

   b. Decide starting state:
      - If `M == K` (every audit has a closure): start fresh at
        `current_round = M + 1`, `current_step = "audit"`,
        `current_wave = null`.
      - If `M > K` (audit exists but no closure — round in flight):
        `current_round = M`. Derive `current_step` from existing files:
        - `WAVES-R<M>.md` exists AND any `WAVE-<X>-RESULT.md` for round
          M exists → `current_step = "execute"`,
          `current_wave = max(X) + 1` (next wave to run).
        - `WAVES-R<M>.md` exists, no WAVE-RESULT files → "execute",
          `current_wave = 1`.
        - `REMEDIATION-PLAN-R<M>.md` exists, no `WAVES-R<M>.md` →
          "schedule".
        - audit exists, no plan → "plan".
        - All five exist (audit, plan, waves, all wave results, but no
          closure) → "check".
      - If both `M == 0` and `K == 0`: start at `current_round = 1`,
        `current_step = "audit"`.

   c. Compute `consecutive_clean_rounds_before` from previous closures:
      walk back from `ROUND-R<K>-CLOSURE.md` and earlier, count
      consecutive rounds with `P0+P1 == 0` until a non-clean round is
      found. Used by `round-checker` to apply the two-clean-rounds
      stop criterion.

   d. Initialize `STATE.self_heal`:
      ```
      {
        "status": "running",
        "current_round": <derived>,
        "current_step": <derived>,
        "current_wave": <derived or null>,
        "consecutive_clean_rounds": <derived>,
        "max_rounds": <arg or 10>,
        "last_p01_count": null,
        "started_at": <now>,
        "last_round_artifacts": null
      }
      ```

   e. Persist via the standard atomic state-update pattern (use
      `bash framework/hooks/_state-update.sh` or the equivalent jq
      pipeline used by `/apex:next` and other commands).

3. If `--resume` WAS passed: read `STATE.self_heal` directly. If
   `status != "running"` → announce "no active self-heal loop to
   resume" and exit.

## MAIN LOOP

While `STATE.self_heal.status == "running"`:

  Let N = STATE.self_heal.current_round.

  ### Step A — Audit (if current_step == "audit")

  Skip if the audit file already exists at
  `$REPO_ROOT/apex-audit-findings-R<N>.md` (resume case).

  **Run RESET_BREAKER** (see Breaker Counter Management).

  ```
  AUDIT_CONTEXT = {
    spec_path: "$REPO_ROOT/apex-spec.md",
    repo_root: "$REPO_ROOT",
    round_number: N,
    output_path: "$REPO_ROOT/apex-audit-findings-R<N>.md",
    previous_findings_path: "$REPO_ROOT/apex-audit-findings-R<N-1>.md" if N > 1 else null
  }
  Task("framework-auditor", AUDIT_CONTEXT,
       model=resolve_model("framework-auditor"))
  ```

  **POST-TASK VERIFICATION**: confirm
  `$REPO_ROOT/apex-audit-findings-R<N>.md` exists on disk. If missing
  → halt the round per Post-Task File Verification rules. Do not
  proceed to Step B.

  After return (and file verified): parse the agent's final-line
  summary (`AUDIT_COMPLETE: ... | findings=<n> | P0=<n> P1=<n> ...`).
  Update `STATE.self_heal.current_step = "plan"` and persist. Then
  call `bash framework/hooks/context-monitor.sh`. If it signals at
  the 70% threshold, persist STATE and exit cleanly with a "context
  rotation needed — type /apex:resume to continue" message.

  ### Step B — Plan (if current_step == "plan")

  **Run RESET_BREAKER**.

  ```
  PLAN_CONTEXT = {
    findings_path: "$REPO_ROOT/apex-audit-findings-R<N>.md",
    spec_path: "$REPO_ROOT/apex-spec.md",
    style_guide_path: "$REPO_ROOT/framework/docs/REMEDIATION-STYLE.md",
    output_path: "$REPO_ROOT/REMEDIATION-PLAN-R<N>.md"
  }
  Task("remediation-planner", PLAN_CONTEXT,
       model=resolve_model("remediation-planner"))
  ```

  **POST-TASK VERIFICATION**: confirm
  `$REPO_ROOT/REMEDIATION-PLAN-R<N>.md` exists. If missing → halt the
  round.

  Parse final-line summary. Update `current_step = "schedule"`,
  persist, context-monitor check.

  ### Step C — Schedule (if current_step == "schedule")

  **Run RESET_BREAKER**.

  ```
  SCHEDULER_CONTEXT = {
    plan_path: "$REPO_ROOT/REMEDIATION-PLAN-R<N>.md",
    spec_path: "$REPO_ROOT/apex-spec.md",
    output_path: "$REPO_ROOT/WAVES-R<N>.md"
  }
  Task("batch-scheduler", SCHEDULER_CONTEXT,
       model=resolve_model("batch-scheduler"))
  ```

  **POST-TASK VERIFICATION**: confirm `$REPO_ROOT/WAVES-R<N>.md`
  exists. If missing → halt the round.

  Parse final-line summary. Update `current_step = "execute"`,
  `current_wave = 1`, persist, context-monitor check.

  ### Step D — Execute waves (sub-loop, if current_step == "execute")

  Read `$REPO_ROOT/WAVES-R<N>.md`. Determine `total_waves` from the
  wave headers (`## Wave 1`, `## Wave 2`, ...).

  For W from `STATE.self_heal.current_wave` to `total_waves`:

    Skip if `$REPO_ROOT/WAVE-<W>-RESULT.md` already exists with
    `Wave status: DONE` (resume case).

    **Run RESET_BREAKER** before each wave invocation. Each wave gets
    a fresh per-task budget of 400 tool calls. The breaker still
    fires if a single wave genuinely runs away.

    ```
    WAVE_CONTEXT = {
      waves_path: "$REPO_ROOT/WAVES-R<N>.md",
      wave_number: W,
      plan_path: "$REPO_ROOT/REMEDIATION-PLAN-R<N>.md",
      spec_path: "$REPO_ROOT/apex-spec.md",
      findings_path: "$REPO_ROOT/apex-audit-findings-R<N>.md",
      wave_result_path: "$REPO_ROOT/WAVE-<W>-RESULT.md",
      new_findings_path: "$REPO_ROOT/NEW-FINDINGS-W<W>.md"
    }
    Task("wave-executor", WAVE_CONTEXT,
         model=resolve_model("wave-executor"))
    ```

    **POST-TASK VERIFICATION**: confirm
    `$REPO_ROOT/WAVE-<W>-RESULT.md` exists on disk. If missing —
    regardless of what the agent's final-line summary said — treat
    the wave as BLOCKED. Do NOT reconstruct the file from the agent's
    inline content. Mark `WAVE_<W>_RESULT: WRITE_FAILED` in the event
    log, set `partial_round = true`, break the wave sub-loop, proceed
    to Step E.

    Parse final-line summary
    (`WAVE_<W>_RESULT: ... | status=DONE|BLOCKED|PARTIAL | ...`).

    - If `status == DONE` AND file exists: increment `current_wave`,
      persist, context-monitor check, continue loop.
    - If `status == BLOCKED` or `PARTIAL`: break the wave sub-loop,
      proceed to Step E with `partial_round` flag in the closer's
      context. Do NOT mark the round as failed yet — the
      `round-checker` decides closure verdict.
    - If summary is `WAVE_<W>_RESULT: WRITE_FAILED`: same as BLOCKED.

  After all waves processed (or break): update `current_step = "check"`,
  persist.

  ### Step E — Closure check (if current_step == "check")

  **Run RESET_BREAKER**.

  Collect all wave-result paths and new-findings paths from this round:
  `$REPO_ROOT/WAVE-<X>-RESULT.md` for X from 1 to last completed,
  `$REPO_ROOT/NEW-FINDINGS-W<X>.md` where they exist.

  ```
  CLOSER_CONTEXT = {
    findings_path: "$REPO_ROOT/apex-audit-findings-R<N>.md",
    plan_path: "$REPO_ROOT/REMEDIATION-PLAN-R<N>.md",
    waves_path: "$REPO_ROOT/WAVES-R<N>.md",
    wave_results: [list of WAVE-<X>-RESULT.md paths],
    new_findings: [list of NEW-FINDINGS-W<X>.md paths],
    prev_closure_path: "$REPO_ROOT/ROUND-R<N-1>-CLOSURE.md" if N > 1 else null,
    spec_path: "$REPO_ROOT/apex-spec.md",
    output_path: "$REPO_ROOT/ROUND-R<N>-CLOSURE.md",
    current_round: N,
    consecutive_clean_rounds_before: STATE.self_heal.consecutive_clean_rounds
  }
  Task("round-checker", CLOSER_CONTEXT,
       model=resolve_model("round-checker"))
  ```

  **POST-TASK VERIFICATION**: confirm
  `$REPO_ROOT/ROUND-R<N>-CLOSURE.md` exists. If missing → halt the
  round (`status = "halted"`, `trigger_reason = "round-checker did
  not write closure"`).

  Parse final-line summary
  (`CLOSURE_COMPLETE: ... | status=CLOSED|CONTINUE | trajectory=... | p01=<n>`).

  Update `STATE.self_heal.last_p01_count = <p01>`. Update
  `last_round_artifacts` to the list of files produced this round.

  ### Decision branch

  - If `closure.status == CLOSED`:
      Set `STATE.self_heal.status = "closed"`, persist.
      Render Section 13 status bar with `STATUS = "loop closed"`.
      Render summary: total rounds run, total P0+P1 closed across
      rounds, list of `last_round_artifacts`.
      Exit.

  - Else if `closure.trajectory == DIVERGING`:
      Set `STATE.self_heal.status = "halted"`, persist.
      Render escalation message: trajectory growing, manual review
      required. Show last_round_artifacts and recommended seed list
      from closure.
      Exit.

  - Else if `STATE.self_heal.current_round >= STATE.self_heal.max_rounds`:
      Set `STATE.self_heal.status = "halted"`, persist.
      Render cap-reached message with current P0+P1 count and seed
      list. The user can re-run with a higher `--max-rounds` if
      desired.
      Exit.

  - Else (CONTINUE):
      Update `STATE.self_heal`:
        - `current_round += 1`
        - `current_step = "audit"`
        - `current_wave = null`
        - If `closure.p01 == 0`: `consecutive_clean_rounds += 1`
          else: `consecutive_clean_rounds = 0`
      Persist. **Run RESET_BREAKER** before continuing the main loop.
      Loop continues with the next round.

End of main loop.

## EVENT LOGGING

At each major transition (round start, step completion, wave start,
wave done, round close, loop close), append an event to
`.apex/event-log.jsonl` consistent with the format used by other
commands. Also call `bash ~/.claude/hooks/session-log.sh "self-heal" "<event>"`
to keep `SESSION-LOG.md` in sync.

## CIRCUIT BREAKER

After every wave completion, call `bash ~/.claude/hooks/circuit-breaker.sh </dev/null`.
If it triggers (consecutive no-change actions, or total tool-calls
cap), halt the round and exit with `STATE.self_heal.status = "halted"`.

## SAFETY GUARANTEES

- Repo root is always resolved via `git rev-parse --show-toplevel`.
  Refuse to run if cwd is not in a git repo.
- The orchestrator never modifies source code directly. All mutations
  happen inside `wave-executor` invocations.
- `STATE.self_heal` is persisted after every step transition, so a
  hard crash leaves a recoverable state.
- The two-consecutive-clean-rounds criterion eliminates single-round
  flukes.
- The `--max-rounds` cap is the final brake; divergence escalation is
  the second brake.

## FINAL DISPLAY

When the loop ends (closed/halted/exited for resume), render:
1. Section 13 status bar with the final status.
2. A soft frame summary:
   - Round started: R<initial>
   - Round ended: R<final>
   - Final status: CLOSED | HALTED | PAUSED
   - P0+P1 trajectory: [list per round]
   - Artifacts: list of `last_round_artifacts`
3. Signature line.

</context>
