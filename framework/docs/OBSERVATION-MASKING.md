# Observation Masking Protocol (R13-002 / F-302)

**Purpose.** Trim the working_memory zone (Z3) by deleting stale tool-result
blocks from the transcript and replacing each with a single-line stub. The
mechanism is **extractive** (R2-C034) — it removes content rather than
summarizing it — and is the configured first step of the
`context_reduction_priority` chain in `CONTEXT_BUDGET.default.json`.

**Spec anchors.**
- "Honest scope over marketing scope." — apex-spec.md principle-line
- "Configuration declarative = theatre until code consumes it." — R12 carried
  principle
- "Re-read from disk after compaction." — R2-C040, codified in
  `framework/agents/critic.md` and `framework/agents/executor.md`
- Design-note: "Observation masking > LLM summarization (R2: JetBrains
  study, 50% cost, equal quality)"

## Extractive vs abstractive

| Mode | What it does | Cost | Information loss |
|---|---|---|---|
| **Extractive (R13-002)** | Deletes stale tool-result body; leaves an instruction to re-read from disk if needed | ~0 — pure text deletion | Bounded — anything needed can be re-derived from disk because file paths remain in the stub |
| Abstractive (`/compact`) | LLM summarizes the entire transcript | ~2× baseline token cost; ~15% latency per R2-C033 | Unbounded — the summarizer chooses what to drop, and failure patterns get smoothed away |

R13-002 implements the extractive form. `/compact` remains as a fall-through
fallback in `pre-compact.sh` for the case where the working_memory zone is
still over budget after masking.

## Three-turn default window — rationale

Default `masking_window_turns = 3` in
`CONTEXT_BUDGET.default.json.zones.working_memory`. The rationale:

- One turn back: the agent typically still has the tool output in active
  consideration.
- Two turns back: the result may be referenced by the in-flight action.
- Three turns back: the result is past the planning horizon; if it is
  needed again, the file path is preserved in the stub and the agent
  re-reads from disk.

Window may be raised to 5 for exploratory phases and lowered to 2 for
budget-pressured phases. The override mechanism is per-task-type and is
deferred to Phase 12 M12 — NOT in R13.

## Re-read trade-off

Masking surfaces stale-reference bugs *faster*: if the executor or critic
re-reads a file from disk and the disk state has drifted from what was
masked, the bug appears immediately. Per R2-C040 this is **desirable**:
proof-of-process beats proof-of-promise; better a loud disk re-read than a
quiet stale memory.

The single risk is when the underlying file was deleted or renamed between
the masking and the re-read. The stub format
(`[masked: <tool_name> at turn <N>, re-read from disk if needed]`) preserves
the tool name but not the file path, so the agent has to consult
`TASK_MAP.md` or the file system. Acceptable; the alternative — preserving
file paths verbatim — would re-create a stale-reference cache that masking
is meant to delete.

## Cross-harness transcript access

The mask hook resolves the transcript path via:

1. `APEX_TRANSCRIPT_PATH` environment variable (if set and readable);
2. fallback to `.apex/event-log.jsonl`.

| Harness | Transcript location | `APEX_TRANSCRIPT_PATH` |
|---|---|---|
| Claude Code (canonical) | In-process | Provided by adapter when available |
| Cursor / Aider / others | Adapter-specific | Set by adapter on Stop event |
| None / standalone | n/a | Mask hook falls back to event-log; emits `observation.mask.fallback` if neither is accessible (fail-safe — never blocks the pipeline) |

## The `observation_masking_active` debug switch

`STATE.context.observation_masking_active` is the operational on/off
switch. Set to `false` to bypass masking for a single session (debugging
re-read race conditions, for example). The hook exits 0 with
`observation.mask.bypassed` written to event-log when bypassed. Default is
`true`.

## State + event-log

| Field | Meaning |
|---|---|
| `STATE.context.last_mask_at` | RFC 3339 timestamp of the most recent mask fire. Architect Step 0 freshness check compares this against the last 3 turns. |
| Event `observation.mask.fired` | Recorded on every successful mask pass; includes `masked_count` and `masking_window`. |
| Event `observation.mask.fallback` | Recorded when the hook could not resolve a transcript or atomic-replace failed. Never blocks; the pipeline falls through to `/compact`. |
| Event `observation.mask.bypassed` | Recorded when `observation_masking_active = false` short-circuits the hook. |
| Event `observation.mask.stub` | Recorded for each tool-result block replaced; carries `tool_name` and `turn` so the dashboard can attribute mask events. |

## Sequence inversion is load-bearing

`pre-compact.sh` MUST invoke `observation-mask.sh` BEFORE Claude Code's
built-in `/compact`. If `/compact` ran first, the stale tool-results would
already be summarized into the rolled-up transcript and the masking pass
would deliver 0% benefit (per R2-C034). Test
`framework/tests/test-observation-mask.sh` case (b) asserts this sequence
via stub instrumentation.

## Stacking with prompt caching (R13-004)

- Observation masking removes stale **tool-result** content from Z3
  (working_memory).
- Prompt caching marks the stable **prompt prefix** for re-use across
  agent calls.

The two are orthogonal: masking trims downstream input; caching reduces
upstream input cost. Cumulative effect is approximately 55% input-cost
reduction on a realistic 5-7 agent call task.

## What MUST NOT be masked

- `DECISIONS.md`, `PLAN_META.json`, `STATE.json` — structured artifacts;
  these are NEVER touched (R2-C117).
- Critic input — masking applies to the **executor** transcript only; the
  critic's clean-room contract (spec + diff + files re-read + RESULT.json
  subset) is preserved.
- Auditor reads — auditor operates under filesystem quarantine; its
  transcript inputs are separate.
- `/compact` itself — the Claude Code built-in is preserved as the
  fall-through after masking.

## Cross-references

- `framework/hooks/observation-mask.sh` — the hook implementation.
- `framework/hooks/pre-compact.sh` — invokes the mask first, then falls
  through to `/compact`.
- `framework/CONTEXT_BUDGET.default.json` — declares
  `working_memory.masking_window_turns` and the `context_reduction_priority`
  chain.
- `framework/schemas/STATE.schema.json` — declares
  `context.last_mask_at`.
- `framework/HOOK-CLASSIFICATION.md` — Library/Command row for
  `observation-mask.sh` (three-places contract).
- `framework/tests/test-observation-mask.sh` — six-case test battery.
