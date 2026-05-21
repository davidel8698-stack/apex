# PinScope Convergence Loop — Operator Guide

How the `/ps-heal` self-healing loop works, its conventions, and its files.
This is the operator reference; the loop's contract is `pinscope/SPEC.md`
Appendix B; the North-Star is `pinscope/SPEC.md` (frozen, read-only).

## Run it

```sh
bash pinscope/convergence/self-heal.sh            # heal until converged
bash pinscope/convergence/self-heal.sh --once     # one round, then stop
bash pinscope/convergence/self-heal.sh --verify   # mechanical re-verify only
bash pinscope/convergence/self-heal.sh --audit    # audit only, no remediation
```

Inside a Claude Code session the same loop is the `/ps-heal` slash command.
On an already-converged tree the loop is a safe no-op: it audits, confirms
zero gaps, and stops.

## How it works

`/ps-heal` is an **orchestrator**. It runs deterministic scripts for mechanics
and spawns **fresh, context-isolated sub-agents** for judgement — the agent
that audits is never the agent that fixed, so the loop self-*checks* rather
than self-*asserts*.

Per round N: `preflight → audit (spec-auditor + narrative-auditor) → terminal
check → breaker gate → remediate (architect) → execute (executor/frontend) →
verify (verifier, clean-room) → close → commit`.

## Files

### Authored, durable
- `pinscope/SPEC.md` — North-Star (frozen, **read-only** — the loop never edits it).
- `ac-matrix.json` — the verification matrix: every AC → its verify kind +
  command + environment requirement. Derived once from SPEC Appendix A.
- `loop.json` — live machine-readable loop state (source of truth): round,
  per-AC status, finding history, env capabilities, the computed metric.
- `CONVERGENCE-REPORT.md` — human-authored terminal report, refreshed on
  convergence.

### Generated (never hand-edit)
- `STATUS.md` — the dashboard, rendered from `loop.json` by `render-status.mjs`.
- `env-capabilities.json` — written by `preflight.sh` each run.
- `ac-results-R{N}.json` — per-AC verdicts for round N, written by `ac-verify.mjs`.

### Per-round artifacts (pinned naming — see `lib/round-paths.sh`)
`audit-findings-R{N}.{md,json}` · `narrative-scan-R{N}.{md,json}` ·
`REMEDIATION-PLAN-R{N}.md` · `WAVES-R{N}.md` · `WAVE-R{N}-RESULT.md` ·
`ROUND-R{N}-CLOSURE.md`

### `lib/` — deterministic mechanics (thin CLI drivers)
- `round-paths.sh` — canonical artifact paths (sourced helper).
- `preflight.sh` — probes environment capabilities (browser / npm registry /
  APEX install / SPEC hash) → `env-capabilities.json`.
- `ac-verify.mjs` — runs the per-AC verification matrix → `ac-results-R{N}.json`.
- `loop-state.mjs` — reads/updates `loop.json`; computes the metric; enforces
  monotonic convergence; the circuit-breaker ledger; `manual-attest`.
- `render-status.mjs` — renders `STATUS.md` from `loop.json`.

### `lib/core/` — pure logic (no I/O, unit-tested)
`verdict.mjs` (verdict/status vocabulary + exit codes) · `ac-eval.mjs` (report
parsing + matrix evaluation) · `loop-logic.mjs` (metric, findings,
monotonicity, breaker) · `render.mjs` (STATUS.md builder) · `schema.mjs` (JSON
validators) · `spec-hash.mjs` (SPEC-drift hashing). The CLI drivers above are
thin shells around these.

### `lib/test/` — the engine's own test suite
`bash pinscope/convergence/lib/test/run.sh` (or `npm run test:engine` in
`pinscope/`) runs the `node --test` suite for every `core/` module — the
convergence engine is itself verified. The suite is `.mjs` under
`convergence/`, so vitest and ac-verify's AC-tag scan never see it.

## JSON shapes

`ac-matrix.json` — `{ spec_version, criteria: [ { id, phase, severity, env,
verify: { kind, ... } } ] }`. `verify.kind` ∈ `vitest-tag` | `grep` |
`build-grep` | `command` | `manual`. `env` ∈ `node` | `browser` | `apex-install`.

`loop.json` — `{ schema, north_star_version, round, loop_status, metric,
metric_history, env_capabilities, criteria: { AC-xxx: { status, round,
last_verified_round } }, findings: [ { id, ac, status, rounds_unchanged,
history } ], current_round: { phase, wave_snapshot_ref },
narrative_coverage }`.

`narrative_coverage` (optional, additive — written by `record-narrative`) —
`{ last_scanned_round, total_claims, covered, uncovered, candidate_acs,
strengthen_proposals, uncovered_satisfied, uncovered_unsatisfied,
history: [ { round, covered, total, candidate_acs } ] }`.

`narrative-scan-R{N}.json` (written by `narrative-auditor`) — `{ round,
generated_at, spec_version, spec_hash, claims: [ { claim_id, section, claim,
normative, covered_by, code_satisfied, re_read } ], candidate_acs: [ {
claim_id, proposed_ac, phase, severity, category, verify, code_satisfied,
carried_over } ], strengthen_proposals: [ { ac, claim_id, current_verify,
claim_quote, proposed_verify } ], coverage: { total_claims, covered,
uncovered, candidate_acs, strengthen_proposals, uncovered_satisfied,
uncovered_unsatisfied } }`.

Statuses: `CLOSED` (verified) · `OPEN` (gap) · `BLOCKED` (built + tested, but
the AC's verify needs an unavailable environment) · `MANUAL_PENDING` (a
`manual`-kind AC whose environment is now available — awaiting `manual-attest`)
· `BACKLOG` (P3 deferred).

## loop-state.mjs commands

`read [field]` · `set-phase <phase>` · `record-round <ac-results> <round>` ·
`record-narrative <narrative-scan> <round>` · `add-finding '<json>'` ·
`breaker-check` ·
`manual-attest <AC-id> <pass|fail> "<evidence>" [--by <name>]`.

`manual-attest` is the **only** path that closes a `manual`-kind AC (AC-061,
063, 082, 083, 106) — it records an explicit human/agent verification, never
an automated proxy.

## Exit codes (engine-wide)

`0` ok · `1` bad input / a real FAIL · `2` HARNESS_ERROR (the verifier engine
itself failed — *not* an implementation gap) or circuit-breaker tripped · `3`
monotonicity violation (a round would decrease `closed`) · `4` SPEC drift
(`SPEC.md` changed, `ac-matrix.json` stale) · `5` schema-invalid JSON.

A `HARNESS_ERROR` round is **refused** by `record-round` — a broken test
harness can never masquerade as 69 implementation regressions.

## SPEC-drift detection

`ac-matrix.json` records `generated_from_hash` (a SHA-256 of `SPEC.md`).
`ac-verify` recomputes the hash each run; a mismatch exits `4` and halts the
loop. The matrix is regenerated only by a deliberate, user-approved step —
the loop never auto-edits it.

## Narrative deep-scan

STEP 1 of each round has two parts. STEP 1A (`spec-auditor`) audits the 69
acceptance criteria. STEP 1B (`narrative-auditor`) is the **narrative
deep-scan**: every round it compares the whole SPEC narrative (§1–§17) against
the code and against Appendix A, and reports normative behavior the 69 ACs do
not capture.

It is a **secondary signal**. It never changes an AC status, never moves the
convergence metric, and never blocks convergence — `metric.open === 0` alone
still decides that. Its result is recorded in `loop.json.narrative_coverage`
(via `record-narrative`) and shown in `STATUS.md` under `## Narrative coverage`.

The scan emits two kinds of proposal in `narrative-scan-R{N}.json`:
- **candidate ACs** — a normative narrative claim with no AC, drafted as an
  Appendix-A-format row;
- **strengthen-AC proposals** — an existing AC whose `verify:` under-checks
  its narrative claim.

### Adopting a candidate AC

`SPEC.md` is FROZEN — candidate ACs are NEVER auto-adopted. Adoption is a
deliberate, user-approved step:

1. Review the candidate ACs in `narrative-scan-R{N}.md`.
2. Bump `SPEC.md` `north_star_version` (e.g. 2.0.0 → 2.1.0) and add the
   approved rows to Appendix A, continuing the `AC-###` sequence.
3. Regenerate `ac-matrix.json`: add the matching `criteria` rows and recompute
   `generated_from_hash` (the SHA-256 of the new `SPEC.md`, computed by
   `lib/core/spec-hash.mjs`). No generator script exists yet — this is a hand
   edit; a future `lib/gen-matrix.mjs` (parse Appendix A → matrix) would make
   it deterministic.
4. The next `/ps-heal` round no longer exits 4 (SPEC drift); the loop heals
   the new ACs through its normal AC machinery.

## Circuit breaker

A finding unchanged for 3 consecutive rounds, or a wave failing verification
3 times, trips the breaker (`loop_status = BREAKER_TRIPPED`). The loop halts
and never reports `CONVERGED` while tripped. The breaker is **not a sticky
latch** — once the stalling finding resolves, `breaker-check` / `record-round`
auto-reset `loop_status` to `IN_PROGRESS` and append the event to
`loop.json.breaker_log`.
