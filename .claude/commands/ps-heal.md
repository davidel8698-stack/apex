---
description: PinScope self-healing convergence loop. One invocation drives the full repair mechanism — audit, remediate, execute, verify, close — round after round until PinScope converges on its frozen North-Star or a circuit breaker halts it. Usage: /ps-heal [once | --verify | --audit | --max-rounds N | --resume].
---

<context>
## PURPOSE
`/ps-heal` is the **orchestrator** of the PinScope `PS-R{N}` self-healing
convergence loop. One invocation runs the entire repair mechanism: it audits
the `pinscope/` tree against its frozen North-Star, remediates every gap in
dependency-ordered waves, verifies, closes the round, and repeats — until
PinScope converges or a circuit breaker trips.

The orchestrator runs deterministic SCRIPTS for mechanics and spawns FRESH,
context-isolated SUB-AGENTS for judgement. The agent that audits is never the
agent that fixed — the loop self-*checks*, it does not self-*assert*.

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
- North-Star: `pinscope/SPEC.md` — Appendix A (69 acceptance criteria),
  Appendix B (loop contract).
- `pinscope/convergence/ac-matrix.json` — the verification matrix.
- `pinscope/convergence/loop.json` — live loop state (source of truth).
- `framework/docs/REMEDIATION-STYLE.md` — remediation authoring standard.
- `pinscope/convergence/LOOP.md` — conventions + JSON shapes.
- Artifact paths: source `pinscope/convergence/lib/round-paths.sh`, then call
  `round_path <kind> <N>`.

## PROCEDURE — one round, repeated until terminal

### STEP 0 — Preflight + state load  *(deterministic)*
- `bash pinscope/convergence/lib/preflight.sh` → writes `env-capabilities.json`.
- `node pinscope/convergence/lib/loop-state.mjs read` → read `round`,
  `loop_status`, `current_round.phase`.
- If `loop_status == BREAKER_TRIPPED`: report the stuck finding and STOP.
- If `current_round.phase != idle` → **resume** at that phase. Otherwise
  `N = round + 1` and begin a new round.

### STEP 1 — Audit  *(fresh `spec-auditor` sub-agent)*
- Run `node pinscope/convergence/lib/ac-verify.mjs --round N` → writes
  `ac-results-R{N}.json` (per-AC `PASS` / `FAIL` / `UNAVAILABLE`).
- Spawn the `spec-auditor` agent with a clean context, given: the SPEC
  Appendix A + B paths, `ac-matrix.json`, `ac-results-R{N}.json`,
  `env-capabilities.json`, round `N`, and the `audit-md` / `audit-json` paths.
  It re-confirms every `FAIL` by re-reading current code (AP-006) and writes
  `audit-findings-R{N}.{json,md}`. It never sees prior remediation reasoning.

### STEP 2 — Record + terminal check  *(deterministic)*
- `node …/loop-state.mjs record-round <ac-results-R{N}.json> N`.
  - Exit 3 = monotonicity violation (a regression dropped `closed`): STOP and
    report the regression — do NOT commit this as convergence.
- Read `loop-state.mjs read metric`. If `open == 0` **and** the auditor
  confirmed zero real findings: run `render-status.mjs`, print
  **"✅ CONVERGED — nothing to heal"** with the metric, `set-phase idle`,
  STOP. *(This is the safe no-op on an already-healthy tree.)*

### STEP 3 — Circuit-breaker gate  *(deterministic)*
- `node …/loop-state.mjs breaker-check`. Exit 2 = a finding survived 3
  rounds, or a wave failed verification 3×: report where it is stuck, STOP,
  do NOT claim convergence.
- If mode is `--audit`: STOP here — findings are written, nothing else.

### STEP 4 — Remediate  *(fresh `architect` sub-agent)*
- `loop-state.mjs set-phase remediate`.
- Spawn a fresh sub-agent in the `architect` role, given `audit-findings-R{N}.json`
  and `framework/docs/REMEDIATION-STYLE.md`. It writes:
  - `REMEDIATION-PLAN-R{N}.md` — 5 mandatory sections per R-item; content
    anchors, never line numbers.
  - `WAVES-R{N}.md` — dependency-ordered, write-serial-safe (one file = one
    owner per wave).

### STEP 5 — Execute  *(fresh sub-agent per wave)*
- `loop-state.mjs set-phase wave`.
- Before each wave: `git stash create` and record the ref in
  `loop.json.current_round.wave_snapshot_ref`.
- For each wave in order, spawn a fresh sub-agent (the `executor` role; the
  `frontend-specialist` role for React/runtime waves) given ONLY that wave's
  R-items. After the wave, re-run `ac-verify.mjs` for the wave's ACs. If a
  wave fails verification, restore the snapshot and retry — the 3rd failure
  trips the circuit breaker.
- Append `WAVE-R{N}-RESULT.md`.

### STEP 6 — Verify  *(fresh `verifier` sub-agent, clean-room)*
- `loop-state.mjs set-phase verify`.
- Re-run `node …/ac-verify.mjs --round N`.
- Spawn a fresh sub-agent in the `verifier` role, given `ac-results-R{N}.json`
  and the list of every previously-`CLOSED` AC. It confirms each claimed
  closure has a matrix `PASS` and runs the regression check across ALL prior
  closures. It is clean-room — it sees verification results, NOT the
  executor's reasoning. A claim without a passing matrix check stays `OPEN`.
  An AC whose env is unavailable is `BLOCKED`, never `CLOSED` from a proxy.

### STEP 7 — Close  *(deterministic)*
- `node …/loop-state.mjs record-round <ac-results-R{N}.json> N` — final merge
  + monotonic guard.
- `node pinscope/convergence/lib/render-status.mjs` — regenerate `STATUS.md`.
- Write `ROUND-R{N}-CLOSURE.md` — closed this round, still-open, BLOCKED,
  the metric, circuit-breaker status.
- `loop-state.mjs set-phase idle`.

### STEP 8 — Commit + loop
- Commit all `-R{N}` artifacts + `loop.json` + `STATUS.md` + the `pinscope/`
  source changes; push to the working branch.
- If mode is `once`, or `--max-rounds N` is reached: STOP.
- Otherwise loop back to STEP 1 for round `N+1`.

## TERMINAL CONDITION
Zero `OPEN` criteria — every Phase-DoD AC is `CLOSED` or `BLOCKED`. On
termination, refresh `pinscope/convergence/CONVERGENCE-REPORT.md`.

## CIRCUIT BREAKER
`loop-state.mjs breaker-check` trips when a finding is unchanged for 3
consecutive rounds, or a wave fails verification 3×. The loop NEVER reports
`CONVERGED` while the breaker is tripped — it reports where it is stuck.

## OUTPUT
A concise report: starting % and ending %, rounds run this invocation, ACs
newly closed, any new `BLOCKED` entries (with what unblocks each), and the
terminal status.
</context>
