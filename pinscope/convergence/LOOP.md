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

Per round N: `preflight → audit (spec-auditor) → terminal check → breaker gate
→ remediate (architect) → execute (executor/frontend) → verify (verifier,
clean-room) → close → commit`.

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
`audit-findings-R{N}.{md,json}` · `REMEDIATION-PLAN-R{N}.md` · `WAVES-R{N}.md`
· `WAVE-R{N}-RESULT.md` · `ROUND-R{N}-CLOSURE.md`

### `lib/` — deterministic mechanics
- `round-paths.sh` — canonical artifact paths (sourced helper).
- `preflight.sh` — probes environment capabilities (browser / npm registry /
  APEX install) → `env-capabilities.json`.
- `ac-verify.mjs` — runs the per-AC verification matrix → `ac-results-R{N}.json`.
- `loop-state.mjs` — reads/updates `loop.json`; computes the metric; enforces
  monotonic convergence; the circuit-breaker ledger.
- `render-status.mjs` — renders `STATUS.md` from `loop.json`.

## JSON shapes

`ac-matrix.json` — `{ spec_version, criteria: [ { id, phase, severity, env,
verify: { kind, ... } } ] }`. `verify.kind` ∈ `vitest-tag` | `grep` |
`build-grep` | `command` | `manual`. `env` ∈ `node` | `browser` | `apex-install`.

`loop.json` — `{ schema, north_star_version, round, loop_status, metric,
metric_history, env_capabilities, criteria: { AC-xxx: { status, round,
last_verified_round } }, findings: [ { id, ac, status, rounds_unchanged,
history } ], current_round: { phase, wave_snapshot_ref } }`.

Statuses: `CLOSED` (verified) · `OPEN` (gap) · `BLOCKED` (built + tested, but
the AC's verify needs an unavailable environment) · `BACKLOG` (P3 deferred).

## Circuit breaker

A finding unchanged for 3 consecutive rounds, or a wave failing verification
3 times, trips the breaker (`loop_status = BREAKER_TRIPPED`). The loop halts
and never reports `CONVERGED` while tripped.
