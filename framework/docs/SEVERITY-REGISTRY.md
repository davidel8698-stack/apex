# Severity Registry (M10, Phase 12.06)

**Purpose.** Single source of truth for the CRITICAL / MAJOR / MINOR
classification of every APEX hook event. Read by
`framework/hooks/_emit_apex_event.sh` validators, by the auditor when
checking hook quality, and by users who want to know why a given
event surfaced (or didn't).

**Spec anchors.**
- `apex-spec.md` — `היכולות הנדרשות` (severity discipline is one of
  the named capabilities).
- `.apex/phases/12-apex-evolution-v8/PLAN.md` task 12.06 §§5-6.
- R5 §7 F5 (alert-fatigue research — >50% false-positive alerts
  cause users to dismiss ALL alerts, including real CRITICAL).
- `framework/HOOK-CLASSIFICATION.md` — the structural list of hooks
  the classifications below refer to.

## The three tiers

### CRITICAL — immediate, visible, budgeted

- Stops the user's current attention.
- Emits to stdout. Caller may chain to a modal (next.md does this
  for Track D via `track-d-modal.sh`).
- **Budget: ≤2-3 per half-day.** The 4th CRITICAL in any 12-hour
  window also emits a follow-up MAJOR `CRITICAL budget exceeded`
  notice. The CRITICAL itself still fires (safety > budget).
- Use for: definite incident, definite security violation, definite
  destructive action, definite data loss risk.
- DO NOT use for: advisory, probable, plausible, "might be wrong".
  Those are MAJOR.

### MAJOR — surfaces passively at the next boundary

- Silent at emit time (no stdout).
- Logged to `.apex/event-log.jsonl` with `severity: "MAJOR"`.
- `/apex:status` renders the most-recent MAJOR events in its
  detailed view (M11 / Phase 12.07).
- `/apex:next` Step F surfaces accumulated MAJORs at phase
  boundary as part of the verdict frame.
- Use for: advisory, "needs review", linting failure that doesn't
  block, drift indicator, regression candidate.

### MINOR — silent log, digest later

- Silent. Logged to `.apex/event-log.jsonl` with `severity: "MINOR"`.
- `framework/hooks/background-digest-hook.sh` fires every 45 min
  via the soft-rotation trigger and emits a batched digest of all
  MINOR events since the last digest.
- Dedup within 5 min collapses repeats to a single record (see
  `_emit_apex_event.sh` for the algorithm).
- Use for: telemetry, post-write style fixups, decorative log,
  routine state update.

## Classification — the 50 hooks

The classification below is the **starter set**. Hooks marked
`(ROUNDTABLE)` need a multi-specialist deliberation before final
classification — `/apex:_roundtable` invocation is queued as a
Phase 12.06 follow-up. Until the roundtable runs, those hooks
inherit the conservative-higher pre-classification.

### Auto-PreToolUse (7)

| Hook | Severity | Notes |
|---|---|---|
| `apex-prompt-guard.cjs` | CRITICAL | Prompt-injection defensive runtime — fail = system compromise risk. |
| `apex-workflow-guard.cjs` | CRITICAL | Workflow boundary enforcement; same defensive runtime. |
| `security.cjs` | CRITICAL | Hard security gates (deny-list patterns, secret exfiltration). |
| `destructive-guard.sh` | CRITICAL | Deny-list match on Write/Edit targets. |
| `owner-guard.sh` | MAJOR | One-file-one-owner enforcement; advisory mode preserved. |
| `path-guard.sh` | MAJOR | Path traversal / unsafe path warnings. |
| `prompt-guard.sh` | CRITICAL | First-fire of structural prompt violation. |

### Auto-PostToolUse (9)

| Hook | Severity | Notes |
|---|---|---|
| `mutation-gate.sh` | CRITICAL when mutation kill-rate below threshold | Test-quality floor breach. |
| `mutation-gate.sh` (above-threshold) | MINOR | Routine success log. |
| `ci-scan.sh` | MAJOR | CI security scanner findings; advisory unless gated to D-level. |
| `phantom-check.sh` | CRITICAL | Fake-completion language detected; verdict is wrong, retry needed. |
| `circuit-breaker.sh` (first-fire) | CRITICAL | Tool-call loop detected. |
| `circuit-breaker.sh` (subsequent in same task) | MAJOR | Already known about; dedup handles. |
| `post-write.sh` | MINOR | Routine post-write style fixups. |
| `tdad-index.sh` (build) | MINOR | Index build telemetry. |
| `cross-phase-audit.sh` (regression found) | MAJOR | Regression detected; review at next boundary. |
| `cross-phase-audit.sh` (clean) | MINOR | Routine clean pass. |
| `memory-watchdog.sh` (above threshold) | MAJOR | Memory pressure — actionable but not yet auto-pause. |
| `memory-watchdog.sh` (auto-pause fire) | CRITICAL | Session-stopping action. |
| `turn-checkpoint.sh` | MINOR | Routine 5-tool-call checkpoint. |

### Command-Invoked / Event-Triggered (17)

| Hook | Severity | Notes |
|---|---|---|
| `phase-tag.sh` | MINOR | Routine git tag emit. |
| `verify-learnings.sh` (clean) | MINOR | Routine SessionStart pass. |
| `verify-learnings.sh` (stale citation / DECAYED / MISSING_PROVENANCE) | MAJOR | Memory integrity drift — review needed. |
| `cross-phase-audit.sh` | (see Auto-PostToolUse row) | Dual-listed. |
| `mutation-gate.sh` | (see Auto-PostToolUse row) | Dual-listed. |
| `context-monitor.sh` (gauge crit) | CRITICAL | Context near hard rotate. |
| `context-monitor.sh` (gauge warn) | MAJOR | Context approaching threshold. |
| `context-monitor.sh` (routine) | MINOR | Routine snapshot. |
| `session-log.sh` | MINOR | Always — by design a passive log. |
| `generate-task-map.sh` | MINOR | Routine architectural map. |
| `tdad-index.sh` | (see Auto-PostToolUse row) | Dual-listed. |
| `tdad-impact.py` | MINOR | Routine impact lookup. |
| `pre-compact.sh` (backup failure) | CRITICAL | STATE backup missed before compaction. |
| `pre-compact.sh` (advisory PLAN/learnings backup fail) | MAJOR | Recoverable — review next session. |
| `pre-compact.sh` (clean) | MINOR | Routine. |
| `subagent-stop.sh` | MINOR | Routine lifecycle event. |
| `state-rebuild.sh` (rebuild ran) | MAJOR | STATE was missing — surface it. |
| `state-rebuild.sh` (fast-path skip) | MINOR | Routine no-op. |
| `agent-lint.sh` (FIX_PLAN written) | MAJOR | Module lint failure — actionable. |
| `agent-lint.sh` (pass) | MINOR | Routine. |
| `decision-gate.sh` (fire) | MAJOR | User decision needed at next reasonable boundary. |
| `decision-gate.sh` (silent) | MINOR | Routine debounce. |
| `session-auto-resume.sh` (banner emit) | MAJOR | Auto-resume triggered — user should know. |
| `session-auto-resume.sh` (silent) | MINOR | Routine no-op. |
| `observation-mask.sh` (fired) | MINOR | Routine masking pass. |
| `observation-mask.sh` (bypassed / fallback) | MAJOR | Masking failed-safe — review. |
| `track-d-modal.sh` (Track D event) | CRITICAL | Irreversible action requires user input. |
| `background-digest-hook.sh` | MINOR | The digest itself is silent; surfaces aggregated MINORs. |

### Library — Sourced (16; includes the new `_emit_apex_event.sh`)

Library files emit through their callers; they do NOT emit events
directly. Severity classification N/A for the library itself.
Callers that source these libs choose the severity for any event
they emit.

### CommonJS — Node-runtime guards (3)

`apex-prompt-guard.cjs`, `apex-workflow-guard.cjs`, `security.cjs`
already listed under Auto-PreToolUse above. All CRITICAL.

## Ambiguous — pending `/apex:_roundtable`

Six hooks have multi-mode behavior where a single severity is too
coarse. These are flagged for a multi-specialist roundtable to
classify per-mode. Conservative-higher pre-classification holds
until the roundtable lands:

1. **`schema-drift.sh`** — CRITICAL on closed-schema break, MAJOR
   on additive drift, MINOR on routine no-op. The closed-vs-additive
   judgment needs the data-specialist + security-specialist.
2. **`ast-kb-check.sh`** — currently advisory MAJOR; could be MINOR
   when no structural change.
3. **`ci-scan.sh`** — CRITICAL on confirmed vuln vs MAJOR on
   advisory finding; depends on the underlying scanner's verdict
   classification.
4. **`workflow-guard.cjs`** — CRITICAL on hard rule violation vs
   MAJOR on advisory; same ambiguity as schema-drift.
5. **`memory-watchdog.sh`** modes already split above but the
   threshold band (above-soft-but-below-hard) needs the
   performance-specialist.
6. **`cross-phase-audit.sh`** regression categorization (test-only
   regression vs prod-path regression) needs the test-architect.

## Dedup, budget, and overflow

- **Dedup window**: 5 min. `(hook_name, severity, dedup_key)` collapses
  to one event. Subsequent collisions increment a `count` field on the
  existing record (planned for follow-up; v0 simply drops the dup).
- **CRITICAL budget**: 4 in any 12h triggers a follow-up MAJOR
  "budget exceeded" notice. The CRITICAL itself still fires.
- **Digest cadence**: `background-digest-hook.sh` runs every 45 min
  on the soft-rotation trigger; emits aggregated MINOR digest with
  top-5 most-frequent (hook, what) pairs.

## How to add a new hook

When authoring a new hook:

1. **Pick the severity it emits.** Use the rules above. Conservative-
   higher when uncertain. Specifically classify per-failure-mode if
   the hook emits at multiple severities.
2. **Source the library**: `source "$(dirname "$0")/_emit_apex_event.sh"`.
3. **Emit through `apex_emit_event`** — never write to event-log.jsonl
   directly.
4. **Document the classification** in this file under the right
   section table.
5. **Add a row to `HOOK-CLASSIFICATION.md`** so the cardinality test
   (R7-011) stays green.

## What this file is NOT

- Not a runtime classifier. The runtime is `_emit_apex_event.sh`;
  this doc is the human-readable source-of-truth that the runtime
  reflects.
- Not a substitute for `framework/HOOK-CLASSIFICATION.md`. That
  file lists every hook and its trigger type; this file classifies
  the SEVERITY of the events those hooks emit.
- Not enforced by tests yet. `test-severity-tiers.sh` covers
  emitter behavior + library contract; per-hook classification
  enforcement is a Phase 12.06 follow-up (mass per-hook rewrite to
  route through `apex_emit_event`).

## Phase 12.06 follow-up backlog

The v0 of this phase ships the SEVERITY INFRASTRUCTURE — the
library, the digest hook, the registry, the test, the schema
fields. The "rewrite all 50 hooks to emit via `apex_emit_event`"
work is documented as follow-up; each hook needs its own small
diff to source the lib + replace ad-hoc `echo "🚫 ..." >&2 ; exit 2`
patterns with `apex_emit_event CRITICAL ...; exit 2`. The exit
codes stay unchanged (R7 contract preserved); severity is ADDITIONAL.

Until the rewrite lands, hooks continue to emit via their existing
paths. The library is callable today; new hooks should adopt it
immediately.
