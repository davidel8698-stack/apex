---
description: PinScope self-healing convergence loop. One invocation drives the full repair mechanism — audit, plan, schedule, execute, verify, close — round after round until PinScope converges on its frozen North-Star or a circuit breaker halts it. Usage: /ps-heal [once | --verify | --audit | --max-rounds N | --resume].
---

<context>
## PURPOSE
`/ps-heal` is the **orchestrator** of the PinScope `PS-R{N}` self-healing
convergence loop. One invocation runs the entire repair mechanism: it audits
the `pinscope/` tree against its frozen North-Star, plans and schedules every
gap into dependency-ordered waves, executes, verifies, closes the round, and
repeats — until PinScope converges or a circuit breaker halts it.

The orchestrator runs deterministic SCRIPTS for mechanics and spawns FRESH,
context-isolated SUB-AGENTS for judgement. Every sub-agent is **purpose-built
for this loop** — the orchestrator never borrows a generic APEX build-pipeline
agent. The agent that audits is never the agent that fixed, and the agent that
fixed is never the agent that verifies — the loop self-*checks*, it does not
self-*assert*.

Mode from $ARGUMENTS:
- *(none)* — heal round after round to the terminal condition.
- `once` — run exactly one round, then stop.
- `--verify` — run the verification matrix + render `STATUS.md` only; no
  sub-agents, no commit.
- `--audit` — STEP 0–3 only (audit + findings written); no remediation, no commit.
- `--max-rounds N` — stop after N rounds this invocation.
- `--resume` — resume an interrupted round (auto-detected even without the flag).

## GUARD
- Run from the apex repo root. If `pinscope/SPEC.md` is missing:
  print "❌ pinscope/SPEC.md not found" and STOP.
- `pinscope/SPEC.md` must be `status: FROZEN`. If not: STOP.
- `pinscope/SPEC.md` is **READ-ONLY**. The loop changes `pinscope/` reality to
  match the spec — NEVER the spec to match reality.
- All loop machinery lives in `pinscope/convergence/`.

## INPUTS
- North-Star: `pinscope/SPEC.md` — §1–§17 (design narrative), Appendix A
  (acceptance criteria), Appendix B (loop contract).
- `pinscope/convergence/ac-matrix.json` — the verification matrix.
- `pinscope/convergence/loop.json` — live loop state (source of truth).
- `framework/docs/REMEDIATION-STYLE.md` — remediation authoring standard.
- `pinscope/convergence/LOOP.md` — conventions + JSON shapes.
- Agents — all purpose-built for this loop:
  audit `spec-auditor`, `narrative-auditor`, `auditor`; plan
  `ps-remediation-planner`; schedule `ps-scheduler`; execute
  `ps-wave-executor`; verify `ps-verifier`.
- Artifact paths: source `pinscope/convergence/lib/round-paths.sh`, then call
  `round_path <kind> <N>`.

## POST-TASK FILE VERIFICATION  *(applies after EVERY sub-agent Task)*
A sub-agent's deliverable is its file(s) on disk — never its summary message.
After every `Task()` returns, before acting on it:
1. Verify each declared output file exists on disk and is non-empty.
2. If the agent returned `WRITE_FAILED`, or a file is missing or empty, the
   task **failed** — regardless of what the summary claims.
3. NEVER reconstruct an agent's output from its inline summary. The summary
   describes intent; only the file is evidence.
On a failed task: an audit / plan / schedule / verify step → **halt the round**
and report which file is missing. A wave step → restore the wave snapshot and
retry the wave (a 3rd failure trips the breaker, STEP 5).

## TOOL BUDGET  *(per-unit, auto-reset at every boundary)*
Every sub-agent runs under the `maxTurns` budget declared in its frontmatter.
Because each step and each wave spawns a **fresh** agent, that budget resets at
every step/wave boundary automatically — a runaway unit is bounded without
weakening the convergence breaker. An agent that exhausts `maxTurns` without
writing its output is handled exactly as a missing-output failure above. The
orchestrator additionally caps wave retries at 3 and re-plan attempts at 2.

## STATE MACHINE & RESUME
Phases, in order: `idle → preflight → audit → record → breaker → remediate →
schedule → wave → verify → close → idle`. `loop.json.current_round.phase` is
the cursor; `loop-state.mjs` writes loop.json **atomically** (temp + rename),
so a crash can never corrupt it. `loop-state.mjs set-phase` appends every
transition to `loop-events.jsonl` (the round event log). Each phase is
idempotent — re-running it reproduces its artifact. `--resume` (auto-detected
whenever `current_round.phase != idle`) re-enters at the recorded phase.

## PROCEDURE — one round, repeated until terminal

### STEP 0 — Preflight + state load  *(deterministic)*
- `bash pinscope/convergence/lib/preflight.sh` → writes `env-capabilities.json`.
- `node pinscope/convergence/lib/loop-state.mjs read` → read `round`,
  `loop_status`, `current_round.phase`.
- If `loop_status == BREAKER_TRIPPED`: read the latest `breaker_log` entry.
  Report where the loop is stuck — a stalled finding, repeated wave failure,
  or a **diverging trajectory** (`reason: diverging`) — and STOP. A tripped
  breaker is cleared only by a human resolving the stall, never by the loop.
- If `current_round.phase != idle` → **resume** at that phase. Otherwise
  `N = round + 1` and begin a new round.

### STEP 1A — AC matrix audit + free investigation  *(fresh `spec-auditor`)*
- `node pinscope/convergence/lib/ac-verify.mjs --round N` → writes
  `ac-results-R{N}.json` (per-AC `PASS`/`FAIL`/`UNAVAILABLE`/`MANUAL`).
  - **Exit 2 (HARNESS_ERROR)** — the test harness itself failed; this is NOT
    an implementation gap. STOP, report the harness failure, do not spawn the
    auditor, do not record the round.
  - **Exit 4 (SPEC drift)** — `pinscope/SPEC.md` changed and `ac-matrix.json`
    is stale. STOP. Regenerating the matrix from SPEC Appendix A is a
    deliberate, user-approved step — the loop never auto-edits the matrix.
  - **Exit 5 (schema-invalid)** — a loop JSON file is malformed. STOP, fix it.
- `loop-state.mjs set-phase audit`.
- Spawn `spec-auditor` with a clean context, given: the SPEC Appendix A + B
  paths, `ac-matrix.json`, `ac-results-R{N}.json`, `env-capabilities.json`,
  round `N`, and the `audit-md` / `audit-json` paths. It re-confirms every
  `FAIL` AND runs the STEP 5 free-investigation sweep (12 axes) over the whole
  spec, writing `audit-findings-R{N}.{json,md}` with `findings`,
  `investigation_findings` (CONFIRMED + SUSPECTED), and a `coverage` ledger.
- **POST-TASK FILE VERIFICATION** on both audit files.

### STEP 1B — Narrative deep-scan  *(fresh `narrative-auditor`)*
Runs every round. Skipped under `--verify`; runs under `--audit`.
- Spawn `narrative-auditor` with a clean context, given: `pinscope/SPEC.md`,
  `ac-matrix.json`, round `N`, the `narrative-md` / `narrative-json` paths,
  and the prior `narrative-scan-R{N-1}.json` if it exists. It writes
  `narrative-scan-R{N}.{json,md}`: `claims`, `candidate_acs`,
  `strengthen_proposals`, `blocking_findings`, and `coverage`.
- **POST-TASK FILE VERIFICATION** on both scan files.
- `node …/loop-state.mjs record-narrative <narrative-scan-R{N}.json> N` merges
  `coverage` into `loop.json.narrative_coverage`. Candidate ACs remain
  proposals (adoption is a user-approved SPEC bump). But `blocking_findings`
  (`uncovered_unsatisfied` — a real un-AC'd code gap) are **not** proposals:
  they are remediated this round and they block convergence.

### STEP 1C — Test-quality audit  *(fresh `auditor`, PinScope mode)*
Runs every round. Skipped under `--verify`; runs under `--audit`.
- Spawn `auditor` in **PinScope convergence-loop mode**, given round `N`, the
  `pinscope/tests/` + `pinscope/convergence/lib/test/` scope, `ac-matrix.json`
  (to map tests to `vitest-tag` ACs), and the `test-audit` path. It writes
  `TEST-AUDIT-R{N}.md`.
- **POST-TASK FILE VERIFICATION** on `TEST-AUDIT-R{N}.md`.
- A `FAIL` verdict means a `vitest-tag` AC is green only because its test is
  vacuous or self-mocking — a **false PASS**. Treat every such AC as an open
  finding fed to remediation (STEP 4), exactly like an audit finding.

### STEP 2 — Record + terminal check  *(deterministic)*
- `node …/loop-state.mjs record-round <ac-results-R{N}.json> N`.
  - Exit 2 = the round carries a `HARNESS_ERROR` — record-round refuses it.
    STOP; fix the harness, never commit a harness-error round.
  - Exit 3 = monotonicity violation (a regression dropped `closed`): STOP and
    report the regression — do NOT commit this as convergence.
- `loop-state.mjs set-phase record`.
- Read `loop-state.mjs read loop_status`. `record-round` sets it `CONVERGED`
  only when `metric.open == 0` **and** `narrative_coverage.uncovered_unsatisfied
  == 0` — a known real failure with no AC can no longer pass as converged.
  If `loop_status == CONVERGED` **and** `spec-auditor` reported zero CONFIRMED
  investigation findings **and** `TEST-AUDIT-R{N}.md` is not `FAIL`: run
  `render-status.mjs`, print **"✅ CONVERGED — nothing to heal"** with the
  metric and the narrative-coverage line, `set-phase idle`, STOP.
  Otherwise continue — there is real work this round.

### STEP 3 — Circuit-breaker gate  *(deterministic)*
- `loop-state.mjs set-phase breaker`; then `node …/loop-state.mjs breaker-check`.
  Exit 2 means the breaker tripped — read the `reason`:
  - `stalled-finding` — a finding survived 3 rounds with no change;
  - `wave-fails` — a wave failed verification 3×;
  - `diverging` — OPEN P0/P1 findings grew by more than 2 between rounds: the
    loop is making things worse.
  Report the reason (and, for `diverging`, the trajectory detail), STOP, and do
  NOT claim convergence. Escalate to a human.
- If mode is `--audit`: STOP here — findings are written, nothing else.

### STEP 4 — Remediate  *(fresh `ps-remediation-planner`)*
- `loop-state.mjs set-phase remediate`.
- Spawn `ps-remediation-planner`, given `audit-findings-R{N}.json`,
  `narrative-scan-R{N}.json` (its `blocking_findings`), the STEP 1C test-audit
  findings, and `framework/docs/REMEDIATION-STYLE.md`. It writes
  `REMEDIATION-PLAN-R{N}.md` — one R-item per finding, each with a root-cause
  line, the five REMEDIATION-STYLE sections, and a pre-written Definition of
  Done. No finding is dropped.
- **POST-TASK FILE VERIFICATION** on `REMEDIATION-PLAN-R{N}.md`.

### STEP 4b — Schedule  *(fresh `ps-scheduler`)*
- `loop-state.mjs set-phase schedule`.
- Spawn `ps-scheduler`, given `REMEDIATION-PLAN-R{N}.md`. It gates the plan
  (rejecting missing sections, symptom-only fixes, hollow DoDs, silent scope
  reduction) and then writes `WAVES-R{N}.md` — dependency-ordered,
  write-serial-safe (one file = one owner per wave).
- **POST-TASK FILE VERIFICATION** on `WAVES-R{N}.md`.
- If `WAVES-R{N}.md` contains `## PLAN REJECTED`: the plan is defective —
  re-run STEP 4 with the rejection reasons. Cap re-plan attempts at 2; a third
  rejection halts the round for human review.

### STEP 5 — Execute  *(fresh `ps-wave-executor` per wave)*
- `loop-state.mjs set-phase wave`.
- For each wave in order:
  - `git stash create` and record the ref in
    `loop.json.current_round.wave_snapshot_ref`.
  - `loop-state.mjs log-event spawn:ps-wave-executor "wave W"`.
  - Spawn `ps-wave-executor` given ONLY that wave's R-items. It implements the
    fixes test-first (red → green), appends its block to `WAVE-R{N}-RESULT.md`,
    and commits the wave.
  - **POST-TASK FILE VERIFICATION**: the wave's block is present in
    `WAVE-R{N}-RESULT.md` AND `git log` shows the wave commit.
  - Re-run `ac-verify.mjs` for the wave's ACs. On failure: restore the wave
    snapshot, increment `current_round.wave_verify_fails`, and retry. The 3rd
    failure trips the circuit breaker (STEP 3 on the next `breaker-check`).

### STEP 6 — Verify  *(fresh `ps-verifier`, clean-room)*
- `loop-state.mjs set-phase verify`.
- Re-run `node …/ac-verify.mjs --round N`.
- `node pinscope/convergence/lib/mutation-check.mjs --round N --files <files
  changed by this round's waves>` → writes `mutation-R{N}.json`. A surviving
  mutant means a test passes against deliberately-broken code — a hollow test.
- Spawn `ps-verifier`, given `ac-results-R{N}.json`, the round's R-items and
  their Definitions of Done, `WAVE-R{N}-RESULT.md`, `loop.json` (all prior
  `CLOSED` ACs + the provenance ledger), and the mutation report. It writes
  `VERIFY-R{N}.md` with a `PASS` / `PARTIAL` / `FAIL` verdict — independently
  re-running each claimed check, running the mutation + anti-skip +
  harness-integrity checks, the regression scan, and the Rendering-Gap check.
  It is clean-room: it never sees the executor's reasoning.
- **POST-TASK FILE VERIFICATION** on `VERIFY-R{N}.md`.
- A claim `ps-verifier` rejects (no passing check, unmet DoD clause,
  hollow test, false closure) stays `OPEN`. A regression, a harness-integrity
  finding, or a Rendering Gap means the round did not converge — each becomes
  an input finding for round `N+1`.
- A `manual`-kind AC whose environment is now available is `MANUAL_PENDING`,
  never `CLOSED` from a proxy — it closes only via
  `loop-state.mjs manual-attest <AC> pass "<evidence>"`.

### STEP 7 — Close  *(deterministic)*
- `node …/loop-state.mjs record-round <ac-results-R{N}.json> N` — final merge,
  monotonic guard, provenance ledger update.
- `node pinscope/convergence/lib/render-status.mjs` — regenerate `STATUS.md`.
- Write `ROUND-R{N}-CLOSURE.md` — closed this round, still-open, `BLOCKED`,
  the metric, the **trajectory** classification (IMPROVING / STAGNANT /
  DIVERGING), circuit-breaker status, the `ps-verifier` verdict, and a
  **Narrative coverage** subsection (claim counts, a pointer to
  `narrative-scan-R{N}.md`, and any `uncovered_unsatisfied` gaps).
- `loop-state.mjs set-phase idle`.

### STEP 8 — Commit + loop
- Commit all `-R{N}` artifacts (`audit-findings`, `narrative-scan`,
  `TEST-AUDIT`, `REMEDIATION-PLAN`, `WAVES`, `WAVE-…-RESULT`, `mutation`,
  `VERIFY`, `ROUND-…-CLOSURE`) + `loop.json` + `loop-events.jsonl` +
  `STATUS.md` + the `pinscope/` source changes; push to the working branch.
- If mode is `once`, or `--max-rounds N` is reached: STOP.
- Otherwise loop back to STEP 1 for round `N+1`.

## TERMINAL CONDITION
Convergence requires ALL of: zero `OPEN` criteria at severity P0–P2; every
Phase-DoD AC `CLOSED` or `BLOCKED`; zero `uncovered_unsatisfied` narrative
gaps; the last `ps-verifier` verdict not `FAIL`. P3 findings may be moved to
`BACKLOG` by explicit user decision. On termination, refresh
`pinscope/convergence/CONVERGENCE-REPORT.md`.

## CIRCUIT BREAKER
`loop-state.mjs breaker-check` trips when ANY of:
- a finding is unchanged for 3 consecutive rounds (`stalled-finding`);
- a wave fails verification 3× (`wave-fails`);
- the trajectory is **diverging** — OPEN P0/P1 findings grew by more than 2
  between the two most recent rounds (`diverging`).
The loop NEVER reports `CONVERGED` while the breaker is tripped — it reports
where it is stuck. The stall and wave-fail conditions are not sticky latches:
once the stalling condition clears, `breaker-check` / `record-round` auto-reset
`loop_status` to `IN_PROGRESS` and append the event to `loop.json.breaker_log`.
A diverging trip halts the loop until a human intervenes — the loop will not
resume itself onto a worsening trajectory.

## OUTPUT
A concise report: starting % and ending %, rounds run this invocation, ACs
newly closed, the trajectory classification, any new `BLOCKED` entries (with
what unblocks each), the `ps-verifier` verdict, and the terminal status.
</context>
