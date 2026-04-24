# NEW-FINDINGS-W3.md — Findings discovered during Wave 3 execution

**Wave:** 3 (R-009, R-001, R-003)
**Executor:** Wave Executor (Claude Opus 4.7)
**Date:** 2026-04-24
**Destination:** R3 audit round for triage

These findings were observed during Wave 3 execution but are **out of scope** for Wave 3 per executor rule 1 ("Scope מוגבל... אם גילית פער נוסף — אל תתקן אותו"). They are logged here for the next audit round.

---

## NEW-F-W3-001 — Stale `workflow-guard.sh` header comment

**Severity:** P3 (documentation drift)
**File:** `framework/hooks/workflow-guard.sh` line 4
**Observed:** During R-001 pre-state inventory.

**Current state:**
```bash
#!/bin/bash
set -u
# Workflow recipe injection scanner — defense-in-depth layer
# Hook type: Explicit invocation by /apex:workflow (NOT auto-fired)
```

**Problem:** The line-4 comment says "NOT auto-fired". But R-006 (Wave 2, commit `99c8212`) wired `workflow-guard.sh` as `PreToolUse` on `Read` in `framework/settings.json`. The comment is now stale and misleading — a developer reading the file will conclude the hook only runs on explicit invocation, when in reality it fires on every `Read` tool call.

**Why not fixed in Wave 3:** R-001's do-not-touch zone explicitly lists "All individual guard .sh files — their logic is correct" and the execution plan forbids refactoring guard internals. Even a 1-line comment update counts as touching the file.

**Suggested R3 action:** Change line 4 to:
```bash
# Hook type: PreToolUse (Read) — auto-wired in settings.json. Also callable explicitly by /apex:workflow.
```

---

## NEW-F-W3-002 — R-003 plan references 28 files; actual count is 29

**Severity:** P3 (plan-vs-reality drift)
**File:** `REMEDIATION-PLAN-R2.md` §R-003 Acceptance criterion C1 and Non-obvious insight #10
**Observed:** During R-003 execution.

**Current state in plan:**
- "Criterion 1: All 28 files from `framework/hooks/` appear in the classification table"
- "There are 28 files in `framework/hooks/`: 5 prefixed with `_`..."

**Current state in reality:** `ls framework/hooks/ | wc -l` → **29**.

The delta is `framework/hooks/_date-parse.sh`, added by Wave 1 R-005 (commit not cited but observable in git log). Library-prefixed files went from 5 to 6.

**Why not fixed in Wave 3:** Modifying `REMEDIATION-PLAN-R2.md` (an audit artifact) was not in the R-003 execution plan. I documented the delta in `HOOK-CLASSIFICATION.md` under "Delta from R-003 original acceptance criterion" and here.

**Suggested R3 action:** Either (a) update `REMEDIATION-PLAN-R2.md` acceptance criterion to read "29 files" for historical accuracy, or (b) treat acceptance criteria as written at plan time and rely on the self-correcting note in `HOOK-CLASSIFICATION.md`. Option (b) preserves the audit trail.

---

## NEW-F-W3-003 — `resolve_model()` is pseudocode, not executable code

**Severity:** P3 (architecture note)
**File:** `framework/commands/apex/next.md` lines 163–170
**Observed:** During R-009 execution.

**Current state:** The `resolve_model()` definition is a narrative/pseudocode block embedded in a command `.md` file:
```
resolve_model(agent_type, verify_level, mode):
  model = routing[agent_type].default
  If verify_level AND routing[agent_type].downgrade_on_verify_level[verify_level] exists → use that
  ...
```

**Problem:** This is instruction text the AI reads and follows — there is no bash/JS/Python runtime that parses it. R-009's addition of the `mode` parameter is therefore a contract change the AI is expected to honor when following the command, not a code change validated by a compiler or test. There is no automated check that `resolve_model()` actually resolves models correctly at runtime.

**Why this is probably fine:** APEX commands are AI-instructions-as-code by design (see `apex-spec.md` capabilities). The AI reading `next.md` has to interpret the pseudocode. No other mechanism is feasible — the model resolution happens inside AI reasoning, not a shell.

**Suggested R3 consideration:** If future audits want stronger guarantees for routing logic, consider extracting `resolve_model()` into an actual bash function (`_resolve-model.sh`) sourced by a real hook. For now, the pseudocode is consistent with every other decision block in `next.md`.

---

## NEW-F-W3-004 — `circuit-breaker.sh` noise persists

**Severity:** P2 (operator experience / hook wiring)
**File:** `framework/hooks/circuit-breaker.sh`
**Observed:** Every Bash tool call during Wave 3 execution produced:
> PostToolUse:Bash hook blocking error from command: "bash ~/.claude/hooks/circuit-breaker.sh": [bash ~/.claude/hooks/circuit-breaker.sh]: No stderr output

(Already logged as NEW-F-W2-002 in Wave 2; repeated here because it still fires in Wave 3.)

**Problem:** The hook apparently exits non-zero for routine Bash invocations without emitting actionable stderr. The message "No stderr output" suggests the Claude Code runtime classifies exit code 1 (or similar) without accompanying message as a non-blocking warning, but the user still sees it. Commits and edits were not blocked — the hook's non-zero exit is non-fatal for the tool call but triggers a visible "blocking error" notification.

**Why not fixed in Wave 3:** `circuit-breaker.sh` is not in any Wave 3 R-ID's execution plan. Modifying it would be out-of-scope scope expansion.

**Suggested R3 action:** Inspect `circuit-breaker.sh` exit paths. If the hook intends to be advisory (not blocking), it should exit 0 always and emit warnings via stderr only when a circuit breaker actually trips. If it intends to block, the block message is missing. Either way, the current behavior is degraded.

---

## Summary

| Finding | Severity | Scope | R3 action |
|---|---|---|---|
| NEW-F-W3-001 | P3 | `workflow-guard.sh:4` stale comment | 1-line comment edit |
| NEW-F-W3-002 | P3 | `REMEDIATION-PLAN-R2.md` count vs reality (28→29) | Optional audit-note update |
| NEW-F-W3-003 | P3 | `resolve_model()` is pseudocode | Consideration, no fix needed |
| NEW-F-W3-004 | P2 | `circuit-breaker.sh` emits spurious "blocking error" messages | Investigate exit paths |

All four findings are **non-blocking** for Wave 3 completion. None require revert of any Wave 3 R-ID.
