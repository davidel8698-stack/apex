# Prompt Caching Protocol (R13-004 / F-304)

**Purpose.** Mark each agent's stable prompt prefix with Anthropic
`cache_control: {"type": "ephemeral", "ttl": "..."}` so subsequent calls
within the TTL pay ~10% of the prefix token cost and ~15% of the latency
(R2-C092). APEX makes 5-7 agent calls per task; without caching, the
stable prefix repeats every call and millions of tokens are wasted across
a project.

**Spec anchors.**
- "Cost-aware execution." — apex-spec.md principle-line
- Design-note: "Prompt caching: stable prefix first, volatile last → 90%
  input cost reduction (R7)"
- `framework/commands/apex/next.md` comment anchor: "Stable prefix FIRST
  (for cache hits), volatile LAST"
- `framework/CONTEXT_BUDGET.default.json` zone anchor:
  `stable_prefix.policy = "Always loaded. Never evicted."`

## Mechanics

Anthropic's prompt caching is opt-in via a `cache_control` directive
attached to a specific prompt segment. The harness reads each agent's
frontmatter `cache_breakpoints:` directive at invocation time and splits
the prompt at the matching XML tag. Everything BEFORE the tag is the
stable prefix; everything AFTER is volatile per-call input.

```yaml
---
name: <agent>
cache_breakpoints:
  - after: "<stable_prefix>"
    ttl: "5m"    # auditor uses "1h"
---

<stable_prefix>
...stable, deterministic role / domain / contract content...
</stable_prefix>

...task-specific volatile content (TASK_MAP, diff, RESULT.json, ...)...
```

The harness sends the stable prefix once per TTL window. Subsequent
agent calls within the window pay the cached read cost (~10% of full
prefix) and skip the cache-write step entirely.

## What belongs in the stable_prefix

- Role declaration ("You are a senior software architect ...")
- Domain invariants ("Your input MUST stay under 30K tokens ...")
- Named failure prohibitions
- Output contract / RESULT.json schema
- Behavioral protocol (clean-room, reflexion, debiasing, ...)
- Static reference tables (verify ladder, decision-mode rules, ...)

## What does NOT belong in stable_prefix

The cache key is a hash of the exact prefix bytes. Anything that varies
per call would force a fresh cache write each time and net-cost more
than no caching:

- `{{datetime}}`, `{{session_id}}`, `{{task_id}}`, current phase
- `STATE.json` contents, `DECISIONS.md` last-decisions slice
- `IMPACTED_TESTS.txt`, `TASK_MAP.md`
- The `<task>` XML block

These belong AFTER `</stable_prefix>`.

## Per-agent TTL table

| Agent | TTL | Rationale |
|---|---|---|
| architect | `5m` | Multiple architect calls per task in autopilot bursts; 5 minutes covers a typical task batch. |
| executor | `5m` | Same — repeated executor calls within a wave or reflexion retry chain. |
| critic | `5m` | Clean-room contract — debiasing prefix is stable across all critic calls of a session. |
| verifier | `5m` | Phase-level verifier reads the same verification ladder + strict-mode rules each call. |
| auditor | `1h` | Filesystem-quarantined auditor runs less often; the role prefix changes only on framework upgrades. 1-hour TTL nets positive even with 1-2 calls per phase. |

## Break-even

Cache writes cost ~25% more than no-cache for the FIRST call within a
TTL. Net positive requires 2+ cache hits within the TTL window. For
APEX's 5-7 agent-calls-per-task pattern this is comfortably met in the
common case.

If a project runs single isolated agent calls separated by >TTL gaps,
caching is net neutral or slightly negative. The `apex_cache_control_supported`
adapter capability flag (see `framework/hooks/_adapter-detect.sh`) gates
activation: caching engages only when the adapter reports support.

## Verification

The `STATE.tokens.cache_hits` and `STATE.tokens.cache_writes` counters
are incremented by `framework/hooks/subagent-stop.sh` whenever the
SubagentStop payload carries non-zero `usage.cache_read_input_tokens`
(hit) or `usage.cache_creation_input_tokens` (write). The R13-006
dashboard renders hit rate as `cache_hits / (cache_hits + cache_writes)`.

`framework/hooks/_tokens-update.sh` exposes the narrow
`apex_tokens_update <agent> <in> <out> [cache_r] [cache_c]` contract;
the two cache args default to 0 so adapters that omit them are graceful.

## Stacking with observation masking (R13-002)

Observation masking trims downstream **tool-result** content from
working_memory (Z3). Prompt caching reduces upstream **prefix** input
cost. The two are orthogonal:

- Masking: deletes stale bytes from the *transcript that gets sent next*.
- Caching: re-uses bytes from the *previous prefix send*.

Cumulative effect on a realistic 5-7 agent call task is approximately
55% input-cost reduction (~50% from caching the stable prefix + a smaller
contribution from masking-induced transcript shrinkage).

## Cache-key sensitivity (silent-failure risk)

The cache key is a content hash. **A single byte change inside the
`<stable_prefix>` region invalidates the entire cache window** for that
agent. Common pitfalls:

- Inserting a timestamp comment
- Inlining `STATE.json` data instead of referencing it
- Including a per-session UUID in any greeting line

The R13-004 acceptance criterion explicitly asserts no
`{{datetime}}` / `{{session_id}}` markers inside any agent's stable_prefix
region. Tests should grep for these markers in any future agent edit.

## Adapter capability flag

`_adapter-detect.sh` exposes `apex_cache_control_supported` indirectly
via the adapter sidecar / env-var chain. Adapters that lack
`cache_control` API support (older Cursor, some self-hosted SDKs) get
`false`; the harness skips the cache_control directive and the prompt
ships verbatim. The frontmatter is unchanged — it is read by the
harness, not by the adapter wire protocol.

## What MUST NOT change

- **Agent invocation sequence** (`/apex:next` Step 0 → 1 → 2 → ...).
  R13-004 only adds cache-control markup; it does not re-order agents.
- **Critic clean-room contract.** Caching affects only the
  system+debiasing portion (the stable_prefix). Critic input — task XML,
  diff, modified-file re-reads, RESULT.json subset — remains as-is.
- **`framework/hooks/apex-prompt-guard.cjs`.** No cache-aware logic is
  introduced; prompt-injection detection still runs over the full
  rendered prompt.
- **`STATE.schema.json framework_overhead`** — separate ledger from
  cache. The cache counters are `cache_hits` and `cache_writes`, not
  `framework_overhead`.

## Cross-references

- `framework/agents/architect.md`, `executor.md`, `critic.md`,
  `verifier.md`, `auditor.md` — frontmatter `cache_breakpoints:` per
  agent.
- `framework/hooks/subagent-stop.sh` — extracts
  `usage.cache_read_input_tokens` and `usage.cache_creation_input_tokens`
  from the SubagentStop payload (R12-001 + R13-004).
- `framework/hooks/_tokens-update.sh` — accumulates cache hits/writes
  into `STATE.tokens`.
- `framework/schemas/STATE.schema.json` — `tokens.cache_hits` and
  `tokens.cache_writes` properties.
- `framework/docs/OBSERVATION-MASKING.md` — the stacking partner.
