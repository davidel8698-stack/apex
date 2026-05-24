# PinScope Convergence Loop — Operator Guide

How the `/ps-heal` self-healing loop works, its conventions, and its files.
This is the operator reference; the loop's contract is `pinscope/SPEC.md`
Appendix B; the North-Star is `pinscope/SPEC.md` (frozen, read-only).

## Run it

Inside a Claude Code session the loop is the `/ps-heal` slash command:

```
/ps-heal              # heal round after round until converged
/ps-heal once         # one round, then stop
/ps-heal --verify     # mechanical re-verify + STATUS.md only
/ps-heal --audit      # audit only (STEP 0–3), no remediation
/ps-heal --max-rounds N   # stop after N rounds this invocation
/ps-heal --resume     # resume an interrupted round (auto-detected)
```

`/ps-heal` is the full agent-driven loop; `lib/` ships the deterministic
mechanics it calls. On an already-converged tree the loop is a safe no-op: it
audits, confirms zero gaps, and stops.

## How it works

`/ps-heal` is an **orchestrator**. It runs deterministic scripts for mechanics
and spawns **fresh, context-isolated sub-agents** for judgement — the agent
that audits is never the agent that fixed, and the agent that fixed is never
the agent that verifies. The loop self-*checks*, it does not self-*assert*.

Every sub-agent is **purpose-built for this loop**. The orchestrator never
borrows a generic APEX build-pipeline agent.

Per round `N`:

```
preflight
  → audit            1A spec-auditor   (AC re-confirm + 12-axis investigation)
                     1B narrative-auditor (narrative gaps → blocking findings)
                     1C auditor        (test-quality, PinScope mode)
  → record + terminal check
  → circuit-breaker gate
  → remediate        ps-remediation-planner  (root-caused R-items + DoD)
  → schedule         ps-scheduler            (plan gate + dependency waves)
  → execute          ps-wave-executor        (test-first, per wave)
  → verify           ps-verifier             (clean-room, mutation + regression)
  → close → commit
```

After **every** sub-agent task the orchestrator runs POST-TASK FILE
VERIFICATION: the deliverable is the file on disk, never the summary message.
A missing / empty / `WRITE_FAILED` output halts the round (or restores the
wave snapshot) — output is never reconstructed from inline text.

## Agents

All under `framework/agents/`, all purpose-built for the convergence loop:

- `spec-auditor` (STEP 1A) — re-confirms machine `FAIL`s AND runs a 12-axis
  free investigation over the whole spec, emitting `CONFIRMED` / `SUSPECTED`
  findings. It is an investigator, not just a confirmer.
- `narrative-auditor` (STEP 1B) — scans the §1–§17 narrative; proposes
  candidate ACs for uncaptured behavior and raises **blocking findings** for
  real un-AC'd code gaps.
- `auditor` (STEP 1C, PinScope mode) — filesystem-quarantined test-quality
  audit: a green `vitest-tag` AC behind a vacuous or self-mocking test is a
  false PASS.
- `ps-remediation-planner` (STEP 4) — one root-caused R-item per finding, each
  with the five REMEDIATION-STYLE sections + a pre-written Definition of Done.
- `ps-scheduler` (STEP 4b) — gates the plan (rejects missing sections, symptom
  fixes, hollow DoDs, silent scope reduction), then writes dependency-ordered,
  write-serial-safe waves.
- `ps-wave-executor` (STEP 5) — implements one wave test-first (red → green),
  under named-failure prohibitions against hollow code and phantom verification.
- `ps-verifier` (STEP 6) — clean-room: independent re-verification, mutation
  check, anti-skip + harness integrity, regression scan, Rendering-Gap check.

Every agent carries a **WRITE-FIRST CONTRACT**: write the file, re-read it
from disk, only then emit a summary; on a write failure, emit `WRITE_FAILED`.
Each runs under a `maxTurns` tool budget that resets fresh at every spawn.

## Files

### Authored, durable
- `pinscope/SPEC.md` — North-Star (frozen, **read-only** — the loop never edits it).
- `ac-matrix.json` — the verification matrix: every AC → its verify kind +
  command + environment requirement. Derived once from SPEC Appendix A.
- `loop.json` — live machine-readable loop state (source of truth): round,
  per-AC status + provenance, finding history, metric + metric_history,
  narrative coverage, breaker log. Written **atomically** (temp + rename).
- `CONVERGENCE-REPORT.md` — human-authored terminal report, refreshed on
  convergence.

### Generated (never hand-edit)
- `STATUS.md` — the dashboard, rendered from `loop.json` by `render-status.mjs`.
- `env-capabilities.json` — written by `preflight.sh` each run.
- `ac-results-R{N}.json` — per-AC verdicts for round N, written by `ac-verify.mjs`.
- `loop-events.jsonl` — append-only round event log (phase transitions,
  spawns, breaker trips), one JSON object per line.

### Per-round artifacts (pinned naming — see `lib/round-paths.sh`)
`audit-findings-R{N}.{md,json}` · `narrative-scan-R{N}.{md,json}` ·
`TEST-AUDIT-R{N}.md` · `REMEDIATION-PLAN-R{N}.md` · `WAVES-R{N}.md` ·
`WAVE-R{N}-RESULT.md` · `mutation-R{N}.json` · `VERIFY-R{N}.md` ·
`ROUND-R{N}-CLOSURE.md`

### `lib/` — deterministic mechanics (thin CLI drivers)
- `round-paths.sh` — canonical artifact paths (sourced helper).
- `preflight.sh` — probes environment capabilities → `env-capabilities.json`.
- `ac-verify.mjs` — runs the per-AC verification matrix → `ac-results-R{N}.json`;
  also emits a harness-integrity fingerprint.
- `mutation-check.mjs` — mutates changed source, re-runs the suite per mutant,
  records survivors → `mutation-R{N}.json`.
- `loop-state.mjs` — reads/updates `loop.json`; metric, monotonic guard,
  circuit-breaker ledger, event log, `manual-attest`.
- `render-status.mjs` — renders `STATUS.md` from `loop.json`.

### `lib/core/` — pure logic (no I/O, unit-tested)
`verdict.mjs` (verdict/status vocabulary + exit codes) · `ac-eval.mjs` (report
parsing + matrix evaluation) · `loop-logic.mjs` (metric, findings,
monotonicity, trajectory, breaker) · `mutate.mjs` (source mutant generator) ·
`render.mjs` (STATUS.md builder) · `schema.mjs` (JSON validators) ·
`spec-hash.mjs` (SPEC-drift hashing). The CLI drivers above are thin shells
around these.

### `lib/test/` — the engine's own test suite
`bash pinscope/convergence/lib/test/run.sh` (or `npm run test:engine` in
`pinscope/`) runs the `node --test` suite for every `core/` module — the
convergence engine is itself verified.

## JSON shapes

`loop.json` — `{ schema, north_star_version, round, loop_status, metric,
metric_history, env_capabilities, criteria: { AC-xxx: { status, round,
last_verified_round, provenance? } }, findings: [ { id, ac, severity, status,
rounds_unchanged, history } ], current_round: { phase, wave_snapshot_ref,
wave_verify_fails }, narrative_coverage, breaker_log }`.

- `metric_history[]` — `{ round, closed, open, p01_open, pct, note? }`.
  `p01_open` (OPEN P0/P1 finding count) is the trajectory signal.
- `criteria[id].provenance` — on a CLOSED criterion: `{ closed_round, verify,
  evidence, wave, at }` (the auditable closure trail; D5.5).
- `narrative_coverage` — `{ last_scanned_round, total_claims, covered,
  uncovered, candidate_acs, strengthen_proposals, uncovered_satisfied,
  uncovered_unsatisfied, history }`.

`narrative-scan-R{N}.json` — `claims`, `candidate_acs`, `strengthen_proposals`,
**`blocking_findings`** (`{ id, claim_id, section, gap, severity, re_read }` —
real un-AC'd code gaps), and `coverage`.

`mutation-R{N}.json` — `{ round, generated_at, files: [ { file, mutants_run,
killed, survived: [ { id, rule, line, original, mutated } ] } ], summary }`.

Statuses: `CLOSED` (verified) · `OPEN` (gap) · `BLOCKED` (built + tested, but
the AC's verify needs an unavailable environment) · `MANUAL_PENDING` (a
`manual`-kind AC awaiting `manual-attest`) · `BACKLOG` (P3 deferred).

## loop-state.mjs commands

`read [field]` · `set-phase <phase>` · `record-round <ac-results> <round>` ·
`record-narrative <narrative-scan> <round>` · `add-finding '<json>'` ·
`breaker-check` · `log-event <event> [note]` ·
`manual-attest <AC-id> <pass|fail> "<evidence>" [--by <name>]`.

`manual-attest` is the **only** path that closes a `manual`-kind AC — it
records an explicit human/agent verification, never an automated proxy.
`set-phase` and breaker trips append automatically to `loop-events.jsonl`.

## Exit codes (engine-wide)

`0` ok · `1` bad input / a real FAIL · `2` HARNESS_ERROR (the verifier engine
itself failed — *not* an implementation gap) or circuit-breaker tripped · `3`
monotonicity violation (a round would decrease `closed`) · `4` SPEC drift
(`SPEC.md` changed, `ac-matrix.json` stale) · `5` schema-invalid JSON.

A `HARNESS_ERROR` round is **refused** by `record-round` — a broken test
harness can never masquerade as implementation regressions.

## SPEC-drift detection

`ac-matrix.json` records `generated_from_hash` (a SHA-256 of `SPEC.md`).
`ac-verify` recomputes the hash each run; a mismatch exits `4` and halts the
loop. The matrix is regenerated only by a deliberate, user-approved step.

## Audit — three parts every round

STEP 1 has three context-isolated sub-agents:

- **1A `spec-auditor`** — re-confirms each machine `FAIL`, then runs a
  12-axis free investigation over the whole spec (build pipeline, pin-ID
  stability, production-zero, runtime isolation, inspection, measurement,
  operation protocol, data schemas, edge cases, performance, integration,
  Phase-DoD). The matrix is 69 ACs; the investigation catches the real failure
  no AC happens to name. Findings are `CONFIRMED` or `SUSPECTED` — a SUSPECTED
  one is investigated, never dropped.
- **1B `narrative-auditor`** — the narrative deep-scan. Candidate ACs and
  strengthen proposals are *proposals* (adoption is a user-approved SPEC bump
  — see below) and never block. But `blocking_findings` — a normative claim
  with `covered_by: []` and `code_satisfied: false` — are real un-AC'd code
  gaps: they feed remediation and **block convergence**.
- **1C `auditor`** — test-quality audit in PinScope mode: a green `vitest-tag`
  AC behind a vacuous or self-mocking test is a false PASS, treated as an open
  finding.

## Convergence

`record-round` sets `loop_status = CONVERGED` only when `metric.open === 0`
**and** `narrative_coverage.uncovered_unsatisfied === 0`. The loop terminates
when, in addition, every Phase-DoD AC is `CLOSED`/`BLOCKED` and the last
`ps-verifier` verdict is not `FAIL`. The metric is monotonic — `closed` may
never decrease (exit `3` guards it).

## Circuit breaker

`loop-state.mjs breaker-check` trips (`loop_status = BREAKER_TRIPPED`) on ANY:
- `stalled-finding` — a finding unchanged for 3 consecutive rounds;
- `wave-fails` — a wave fails verification 3 times;
- `diverging` — OPEN P0/P1 findings grew by more than 2 between the two most
  recent rounds (`trajectoryState`). This catches the thrash case the stall
  breaker misses: findings churning so no single one is ever "stuck", yet the
  failure count climbs every round.

The loop NEVER reports `CONVERGED` while tripped. The stall and wave-fail
conditions are not sticky latches — once cleared, `breaker-check` /
`record-round` auto-reset to `IN_PROGRESS` and log the event to `breaker_log`.
A `diverging` trip halts the loop until a human intervenes.

## Mutation check & harness integrity

`mutation-check.mjs` mutates each source file a wave changed (one-token
operator/literal mutations) and re-runs the vitest suite per mutant. A
**surviving** mutant — the suite still passes against deliberately-broken
code — means the test is hollow; `ps-verifier` keeps that AC `OPEN`.

`ac-verify` records a `harness` fingerprint (config-file hash + skipped-test
marker count) in `ac-results`. `ps-verifier` diffs it round over round: a
loosened config or a freshly-skipped test cannot buy a green result.

## Provenance ledger

Every `CLOSED` criterion records a `provenance` block — `closed_round`, the
verify method, the evidence artifact, the wave. A closure with no provenance
is unverifiable and `ps-verifier` treats it as `OPEN`.

## Adopting a candidate AC

`SPEC.md` is FROZEN — candidate ACs are NEVER auto-adopted. Adoption is a
deliberate, user-approved step:

1. Review the candidate ACs in `narrative-scan-R{N}.md`.
2. Bump `SPEC.md` `north_star_version` and add the approved rows to Appendix A.
3. Regenerate `ac-matrix.json` (add the `criteria` rows, recompute
   `generated_from_hash`).
4. The next `/ps-heal` round no longer exits 4 and heals the new ACs normally.

Note: a `blocking_finding` is NOT a candidate AC — it is a real code gap and
is remediated in the same round, with no SPEC change required.

## Relationship to Appendix B

The loop implementation elaborates Appendix B (the frozen loop contract): it
already runs two auditors where Appendix B names one, and it now adds two
behaviors that go beyond Appendix B's literal text — the **divergence breaker**
and **narrative blocking findings**. Both make the loop fulfill Appendix B's
intent more strictly (it halts sooner on a worsening trajectory; it refuses to
declare convergence over a known real gap). If the contract should record them
explicitly, that is a minor user-approved `north_star_version` bump adding two
lines to Appendix B — the implementation does not require it.
