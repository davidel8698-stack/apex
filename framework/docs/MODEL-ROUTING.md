# Model Routing (M04, Phase 12.01)

**Purpose.** Eliminate shared blind spots between the executor and the
verification agents (critic, verifier, auditor) by routing them to
different model families. Cost optimization is a bonus.

**Spec anchors.**
- `apex-spec.md` §"היכולות הנדרשות" (capability inventory)
- `apex-spec.md` §"עקרונות העבודה" (working principles — adversarial
  separation is one of the core invariants)
- Research evidence: **R2-C107** (Anthropic measured Opus-lead +
  Sonnet-workers at +90.2% on a research task — the lead/worker model
  diversity is the documented win); **R2-C125** (cost-aware execution
  guidance); **R2-C123** (critic input is small ~5-10K tokens, so a
  high-accuracy model is high-leverage).
- Canonical routing: `framework/apex-model-routing.json` (synced to
  `~/.claude/apex-model-routing.json`).

## Why diversity

When the executor and the reviewing agents share a model, they share
training biases, hallucination patterns, and blind spots. A bug the
executor introduces because the model misreads a contract is *exactly*
the bug the critic, also on the same model, will miss. R2 research
(Anthropic SWE evaluations + the Opus-lead/Sonnet-workers result) shows
diversity at the model layer is the strongest defense.

APEX exploits this by routing:

| Agent       | Default model        | Rationale |
|-------------|----------------------|-----------|
| `planner`   | `sonnet`             | Classification + checklist; cheap. |
| `architect` | `sonnet`             | Orchestration, plan-shape — cheap; escalates to `opus` at complexity levels 3-4. |
| `executor`  | `sonnet`             | Bulk implementation; ~98% of Opus quality at 1/5 the cost. Downgrades to `haiku` for verify-level A; escalates to `opus` on retry or complexity 4. |
| `critic`    | **`opus`**           | Adversarial review on small input — max accuracy is high-leverage. `cross_model_required: true` plus `fallback_if_same: opus` keep the diversity invariant even when the executor was also routed to opus. |
| `verifier`  | **`opus`**           | Phase-level verification; verdict gates phase tagging. |
| `auditor`   | **`opus`**           | Filesystem-quarantined test auditor for verify-level C/D — runs rarely but on the highest-risk surfaces. Sonnet 4.6 caught fewer subtle test smells in pilot runs. |
| `security-specialist` | `opus`     | Threat-model reasoning requires adversarial depth (unchanged from R7). |
| `test-architect`      | `haiku`    | Pre-execution test strategy — small, structural; escalates to sonnet in phase mode. |

**Frontmatter declares the assertion.** Each agent's `expected_model:` in
its YAML frontmatter is the agent's own claim about which model it
expects to run on. `agent-lint.sh` warns (not blocks) if
`expected_model` disagrees with the routing default.

## Cost / quality table (production assumptions)

Costs are normalized to Sonnet 4.6 = 1× (input + output, approximate).

| Model            | Cost (×Sonnet) | Quality (Opus = 100) |
|------------------|----------------|----------------------|
| `haiku` (4.5)    | ~0.33×         | ~90 (vs Sonnet)      |
| `sonnet` (4.6)   | 1×             | 98                   |
| `opus` (4.7)     | ~5×            | 100                  |

Net session-cost projection vs all-Opus baseline:

| Agent      | Calls / task (typical) | All-Opus cost | Diverse routing cost |
|------------|-----------------------:|--------------:|---------------------:|
| executor   | 3-5                    | ~5×           | ~1×                  |
| architect  | 1-2                    | ~5×           | ~1×                  |
| critic     | 1                      | ~5×           | ~5× (unchanged)      |
| verifier   | 0-1                    | ~5×           | ~5× (unchanged)      |
| auditor    | 0-1 (C/D only)         | ~5×           | ~5× (unchanged)      |

**Effect.** ~30-40% session-level cost reduction (executor dominates
call volume), with critic/verifier/auditor quality **improved** because
they moved from sonnet to opus.

## Cache invalidation per model

Anthropic prompt caching is keyed per model. Sonnet and Opus do not
share cache prefixes. The diversity routing means each agent maintains
its own cache prefix in its own model family:

- `executor` (sonnet) prefix → cached on sonnet
- `critic` (opus) prefix → cached on opus

A user who switches APEX between two projects within a 5-minute TTL
window pays the per-model prefix once per model, not once per agent.
See `framework/docs/PROMPT-CACHING.md` for the full mechanics.

## When to override

Manual override is a per-task escape hatch, not a default. Reasons to
override:

1. **Cost pressure on a low-stakes task.** A verify-level A
   documentation pass does not need an opus critic; route critic to
   sonnet for the duration of the task. Use the `escalate_on_level`
   inverse: temporarily set `critic.default` to `sonnet` for one task.
2. **Pilot a model upgrade.** A new model release ships → temporarily
   route a single agent to it, watch quality / cost telemetry, then
   roll out.
3. **Adapter constraint.** A non-Claude-Code adapter that does not
   expose `opus` falls back to the routing.fallback chain. Cursor
   adapter currently supports both; verify with
   `framework/adapters/<adapter>/adapter.json`.

Override mechanism: edit `framework/apex-model-routing.json`, re-run
`framework/scripts/sync-to-claude.sh`. The change takes effect on the
next agent invocation.

## What is NOT changed by M04

- **The clean-room contract for critic.** Model diversity is one
  isolation axis among several; the input contract (spec + diff +
  RESULT.json subset, never executor reasoning) is independent.
- **Agent prompt bodies.** Same prompts run on different models; no
  rewriting required.
- **`security-specialist`** stays on opus (was already opus pre-M04;
  threat-model reasoning needs the depth).
- **The 9 failure modes.** Diversity prevents a class of correlated
  failures; the failure taxonomy itself is unchanged.

## Forward work (out of M04 scope)

- `/apex:_debate` and `/apex:_roundtable` spawn multiple specialists.
  Routing them to diverse models (e.g., security-specialist on opus,
  performance-specialist on sonnet) is a natural extension; tracked as
  a follow-up.
- Per-task model overrides via PLAN_META are not yet supported;
  current override is project-wide via the routing JSON.

## Validation

Run `framework/tests/test-model-routing.sh` after any change to:
- `framework/apex-model-routing.json`
- `expected_model:` lines in `framework/agents/*.md`

The test asserts: (a) routing JSON is valid, (b) each agent with an
`expected_model:` frontmatter matches its routing default, (c) the
diversity invariant holds (executor != critic at default).
