# AUDIT-TRAIL STANDARD (Campaign B Institutionalization)

> **Contract for the framework.** Every claim by every APEX agent must
> be verifiable against the tool-call audit trail. Every reviewer
> agent enforces that verification. New agents authored after the
> Campaign B install MUST conform to this contract.
>
> Companion documents:
> - `audit-trail-review/EXPERIMENT-PROTOCOL.md` — frozen methodology
>   (B0 pre-registration), AC-1..AC-12 numeric acceptance criteria.
> - `audit-trail-review/TRUST-POINTS.md` — TP-1..TP-12 register + the
>   5 high-leverage TPs (top-5) with AT-1..AT-5 acceptance tests.
> - `audit-trail-review/FIX-DESIGN.md` — per-TP content-addressable
>   anchors + replacements (B3, B3-critic R2 PASS).
> - `audit-trail-review/FINAL-CERTIFICATION.md` — Campaign B outcome
>   (HALTED-AT-B5; implementation complete; verification deferred).
> - `framework/docs/DETECTION-STANDARD.md` — Campaign A
>   institutionalized standard (Campaign B builds on it).

---

## §1. The contract — three layers

Campaign B installs a three-layer audit-trail architecture. Every
new framework component MUST fit within this architecture.

### §1.1 Data layer (the substrate)

The **event-log** at `.apex/event-log.jsonl` is the append-only
record of every observable framework action. Format: one JSON object
per line, schema-validated per
`framework/schemas/EVENT-LOG-ENTRY.schema.json` (v1, frozen
2026-05-24).

Every entry carries:
- `schema_version`: `"1"` (Campaign B v1; absent = pre-v1 legacy,
  accepted with flag)
- `ts`: ISO-8601 UTC RFC3339 (`2026-05-24T11:01:11Z`)
- `type`: enum (see §1.2 for the v1 type registry)
- `source`: hook or library name (`tool-event-logger`,
  `circuit-breaker`, `subagent-stop`, `pre-subagent-start`,
  `event-log-rotate`, etc.)
- `agent_id`: stable per-invocation ID — `host-<session_uuid>` for
  parent events; `subagent-<agent_name>-<round_tag>-<sha1_8>` for
  sub-agent events (per `pre-subagent-start.sh` synthesis)
- `parent_agent_id`: null for host; `host-<session_uuid>` for
  sub-agent events

Writers:
- `framework/hooks/tool-event-logger.sh` (PostToolUse matcher `*`)
  emits `tool_call` + `tool_input_hash` events for every tool call
- `framework/hooks/pre-subagent-start.sh` (PreToolUse matcher
  `Agent|Task`) emits `subagent_start` boundary events + updates
  `.apex/in-flight-subagents.jsonl` registry
- `framework/hooks/subagent-stop.sh` (SubagentStop event) emits
  `subagent_stop` + `transcript_imported` + (on mismatch)
  `subagent_count_mismatch` P0; writes denormalized transcript to
  `.apex/subagent-transcripts/<agent_name>-<round_tag>-<sha1_8>.jsonl`
- `framework/hooks/event-log-rotate.sh` (SessionStart) rotates at
  10 MB to dated `.gz` archives; prunes archives ≥ 90 days
- `framework/hooks/_state-update.sh` (`_emit_apex_event` function)
  is the central emitter library — sourced by every hook that emits
  events; performs schema validate-before-append; routes failures to
  `.apex/event-log-rejected.jsonl`

### §1.2 Schema layer (the enum)

`framework/schemas/EVENT-LOG-ENTRY.schema.json` v1 enumerates 47
permitted event types. Adding a new type is a MINOR revision per
`audit-trail-review/EXPERIMENT-PROTOCOL.md` §5.5 — add the type to
the enum + the matching variant in `oneOf`. Removing a required
field or changing a type is a MAJOR revision (schema_version bump).

Authors of new hooks/libraries MUST:
1. Pick an event type that EITHER already exists in the enum OR add
   the type to the schema enum + the matching bash
   `_APEX_EVENT_TYPE_ENUM` constant in `_state-update.sh`.
2. Document the event type's required fields in the schema's `oneOf`
   array (or in the catch-all `legacy_or_other` variant for less-
   structured types).
3. Run `bash framework/tests/test-audit-trail-layer.sh` after the
   addition — case C2 verifies schema integrity.

### §1.3 Consumer layer (the verification gates)

Every claim by every APEX agent must be verifiable against the audit
trail OR the agent must EXPLICITLY mark the claim as
`assumption_unverified=true` AND set `status="partial"` (per
executor.md TP-4 escalation). The "informational flag" pattern is
FORBIDDEN — every unverified premise must downgrade the task's
verdict.

The 5 reviewer agents and their verification gates:

| Agent | Gate | Mechanism |
|-------|------|-----------|
| `critic.md` STEP 1.5 (R16-603) | git-trace verification | `git log task_start_sha..HEAD --stat` bounds diff; every `files_modified[].path` must appear |
| `critic.md` STEP 1.6 (R16-623C) | data-value cross-reference | Build CORPUS from event-log; cited numeric values must appear; absent → `phantom_data_value` CRITICAL |
| `critic.md` STEP 1.7 (R16-628) | tool-call cross-reference | Every claimed tool invocation must appear in event-log as `tool_call`; absent → fabricated-tool-call CRITICAL |
| `critic.md` STEP 2 (prelude) (Campaign B TP-4.b) | status-field cap | `RESULT.json.status=='partial'` → verdict capped at PARTIAL regardless of done_criteria counts |
| `critic.md` STEP 2 (cont.) (Campaign B TP-1) | verify-command re-execution | Re-run every `verify_commands_run[].command` (cap N=10, D-level priority); byte-compare actual `(exit, stdout)` to claimed; mismatch → `fabricated_verify_command_output` CRITICAL |
| `critic.md` STEP 4.5 (R16-619) | dry-run-contradicted | Re-runs cited commands; citation `file:line` must resolve |
| `critic.md` STEP 4.6 (R16-635) | citation verification | every `file:line` cited must be valid at HEAD |
| `round-checker.md` step 6 (Campaign B TP-2 — upgrade of CR-04) | full axis-13 + axis-10 re-probe | Reads sub-agent transcript; iterates UNION of `axis_13.bypass_attempts[]` + `axis_10.concrete_bypass_attempts[]`; mismatch → P1 `audit_credibility_regression` + Status CONTINUE; F-204-013 reconstruction → P0 `phantom_grep_count` on cited grep count mismatch ≥ 50% |
| `verifier.md` STEP 1 (cont.) (Campaign B TP-3) | independent git-diff cross-reference | `git diff <task_start_sha>..HEAD --name-only`; set-difference vs `files_modified[]`; omitted → P0 `files_modified_omission`; phantom → P0 `phantom_file_claim` |
| `executor.md` STEP 0.5 (Campaign B TP-4.a) | status=partial escalation | Unverifiable premise → `status="partial"` + `issues_found[]` entry of type `unverifiable_premise_continued`; critic STEP 2 prelude enforces cap |
| `framework-auditor.md` Axis 10 (Campaign B TP-5) | procedural sub-pass | For each named guard, execute one constructed sandboxed bypass under `APEX_BYPASS_TEST=1`; capture exit code into `axis_10.concrete_bypass_attempts[]`; analysis-only = BLIND SPOT; round-checker TP-2 enforces |

---

## §2. How new agents conform to the contract

When authoring a new APEX agent (via `/apex:new-agent` or manually):

1. **Output Contract.** The agent's `Output Contract` section MUST
   specify which fields of `RESULT.json` (or its equivalent
   artifact) are claims that downstream consumers will verify. If
   any claim involves tool-call evidence, list the matching
   `tool_call` event lookup pattern.

2. **No "informational flag" patterns.** If the agent has an
   "unverifiable" branch, it MUST escalate to `status="partial"`
   AND append to `issues_found[]` (per TP-4.a's pattern); it MUST
   NOT silently set an informational field and proceed with
   `status="success"`.

3. **Anti-priming clause.** If the agent reads any "prior findings"
   or "previous trajectory" input, it MUST resist priming actively
   (per `framework-auditor.md` CORE PRINCIPLES and Campaign A CR-03).

4. **Adversarial probing.** If the agent investigates security
   guards or invariants, every named target requires a CONCRETE
   probe (the Axis 13 + TP-5 pattern), not analysis. Analysis-only
   findings should be downgraded to `BLIND SPOT` for the
   round-checker to surface.

5. **Tool-trail honesty.** If the agent cites a numeric value, an
   exit code, a file count, or a grep result, the cited value MUST
   be re-derivable from a `tool_call` event in
   `.apex/event-log.jsonl` (or the agent's own
   `.apex/subagent-transcripts/<...>.jsonl` if sub-agent-scoped).

6. **Schema-aware emission.** If the agent emits any event-log
   entries directly (rare — most agents emit via
   `_emit_apex_event` which handles schema), the entry MUST carry
   `schema_version: "1"` and a `type` in the v1 enum.

---

## §3. How reviewer agents enforce the contract

The 5 reviewer agents (critic, verifier, round-checker, executor
self-review via STEP 0.5, framework-auditor self-review via Axis 10)
collectively verify EVERY high-leverage claim in the framework. The
verification points are documented in `audit-trail-review/TRUST-POINTS.md`
(12 trust points + 4 verify points + 5 new TP-1..TP-5 closures).

A new reviewer agent SHOULD:
1. Read the relevant claim from the upstream producer's artifact.
2. Independently derive the verifying evidence (re-run, re-grep,
   re-read).
3. Compare; emit a finding (severity per the framework's
   `framework/docs/SEVERITY-REGISTRY.md`) on mismatch.
4. Never accept "this is verified because the upstream says so" —
   that pattern IS the F-204-013 anti-pattern Campaign B closes.

---

## §4. The audit-trail layer's intent in one sentence

**Every framework claim is now anchored to a tool-call event the
downstream consumer can independently re-derive.** The
F-204-013-class fabrication ("R23 claimed 6 hits for IMP-039; live
grep returns 0") is structurally unreachable because
`round-checker.md` TP-2 §6.c re-runs the cited grep against the
imported sub-agent transcript and emits P0 `phantom_grep_count` on
mismatch.

---

## §5. Diff from Campaign A's DETECTION-STANDARD.md

Campaign A's `framework/docs/DETECTION-STANDARD.md` mandates the
framework-auditor's depth floor (13 axes, axis-13 adversarial
falsification per spec-named guard). Campaign B's
AUDIT-TRAIL-STANDARD.md (this document) is COMPLEMENTARY:

| Layer | Campaign A standard | Campaign B standard |
|-------|---------------------|---------------------|
| What is detected? | Defects in framework code | Fabricated claims by framework agents |
| What is enforced? | Auditor depth (every axis has evidence) | Consumer-side verification (every claim has a tool-call cross-reference) |
| Failure mode addressed | Shallow audits closed clean rounds | Fabricated audit claims passed unverified |
| Mechanism | 13 audit axes mandatory | Audit-trail re-derivation mandatory |

A framework user running both campaigns gets:
- Reliable defect detection (Campaign A's held-out 8/8 reliable
  kill rate)
- AND reliable claim verification (Campaign B's structural answer
  to F-204-013)

Without Campaign B, even a Campaign-A-strengthened detector can
still ratify a fabricated claim. Without Campaign A, even a
Campaign-B-verified consumer can still pass a shallow audit.
Together they form defense-in-depth.

---

## §6. Campaign B status as of this document

Per `audit-trail-review/FINAL-CERTIFICATION.md` Gate B5 verdict
(post B5-critic R1 FAIL revision): the IMPLEMENTATION is COMPLETE
(B3-critic R2 PASS) and the VERIFICATION is HALTED at Gate B5
pending one of two paths — fresh-session 11-trial corpus run
(R-AT-P7-04 + R-AT-P7-05) or a dated §14 amendment to
`EXPERIMENT-PROTOCOL.md` §12.2 with owner authorization (R-AT-P7-08).

This document describes what was BUILT regardless of the
verification gate's status.

---

## §7. Campaign C extensions (2026-05-25) — Proof-of-Process Maximization

Campaign C added two mechanisms targeting the 3 hard-FAIL ACs left
open in Campaign B R2.

### §7.1 TP-C1 — Axis-1 mechanical enumeration

Every `framework-auditor` round MUST mechanically enumerate every
spec-named hook via dynamic extraction at ROUND TIME against the
lab's `apex-spec.md`:

```bash
grep -oE 'framework/hooks/[a-zA-Z_-]+\.(sh|cjs|ps1)' \
  <lab>/apex-spec.md | sort -u
```

For each extracted hook, the auditor executes `test -f` via a
separate Bash tool_call (never batch) and records
`{hook, exit_code, tool_call_event_ts, finding_id, forward_reference}`
in `coverage_map.axis_1.spec_named_hook_presence[]`.

**Anti-rollup invariant:** every `exit_code != 0` row MUST have a
dedicated per-hook P0 finding with that hook's filename in `cite[]`.
A rolled-up "baseline absent" finding does NOT discharge per-hook
duty. Round-checker REJECTS closure on missing pair.

**Forward-reference classification:** missing hooks with spec
context containing `forward-reference|phase 12|deliverable|planned`
prose downgrade to P3 advisory. Avoids false-P0 flood on roadmap
items.

**Empirical evidence:** 5/5 Campaign C C5 trials emitted the
canonical 17-row table. W-A1 + W-A2 mutants killed in T1 (baseline)
and T8 (W-F3) via per-hook P0 — closing AC-4 working class-A
structurally.

### §7.2 TP-C2 — Three-factor audit-probe carve-out

Host-protected guards (`destructive-guard.sh`, `exfil-guard.sh`,
`sequence-guard.sh`, `prompt-guard.sh`, `apex-prompt-guard.cjs`)
source `framework/hooks/_audit-probe-marker.sh` (or its node
parallel `security.cjs:checkAuditProbeMarker()`) and run a
three-factor check BEFORE pattern matching.

**Marker grammar:** `__APEX_AUDIT_PROBE__:<nonce>:<agent_id> <command>`

**Three factors:**
1. **F1:** marker prefix match.
2. **F2:** parsed `agent_id` resolves to an in-flight registry
   entry with `agent_name=framework-auditor`.
3. **F3:** parsed `nonce` equals that entry's `audit_probe_nonce`
   (generated per-invocation by `pre-subagent-start.sh` for
   framework-auditor agents only).

All three must hold; otherwise the guard's existing pattern-matching
path runs (fail-closed default). Every allowance emits an
`audit_probe_allowed` event with `payload_sha1`, `agent_id`,
`calling_hook`. Round-checker verifies the event chain end-to-end.

**Empirical evidence:** Campaign C layer-test cohort H-C1..H-C8 in
`framework/tests/test-audit-trail-layer.sh` — 8/8 PASS. C5-T7 NC
trial executed 24 procedural probes via the carve-out.

### §7.3 audit_probe_allowed event schema

```json
{
  "schema_version": "1",
  "ts": "<ISO 8601 UTC>",
  "type": "audit_probe_allowed",
  "source": "audit-probe-marker | security.cjs",
  "agent_id": "subagent-framework-auditor-<round>-<sha8>",
  "agent_name": "framework-auditor",
  "payload_sha1": "<sha1 of full command>",
  "payload_head": "<first 200 chars>",
  "calling_hook": "<guard filename>"
}
```

### §7.4 Campaign C status as of this document

Campaign C closed 2026-05-25 as **HALTED-AT-B5-R3 — STRUCTURAL
IMPROVEMENT DEMONSTRATED** (per `audit-trail-review/FINAL-CERTIFICATION-C.md`;
C5-critic R1 PASS-WITH-CHANGES on 2 minor citation defects).

- AC-4 working class-A: improved (W-A1 + W-A2 killed via per-hook P0).
- AC-4 heldout: deferred to R-AT-C-01 (corpus-spec alignment).
- AC-5b: requires R-AT-C-02 (axis-10.d worked-examples; master plan label "axis-13.d" reconciles to this location per design R2 §2.B note + design R2 §2 Change E).
- AC-6a NC fabricated=0: PASS.
- AC-6b NC count: closed via R-AT-C-04 — axis-13.e runtime-invocation-contract probe added to framework-auditor.md; round-checker.md TP-2 §6.b clauses (vii)+(viii) enforce per-guard probe minimum + discrepancy-emission gate; Wave-0 independent probe empirically surfaced 11 findings (1 P0, 4 P1, 4 P2, 2 P3) on the pristine framework via the methodology this R-item institutionalizes.
- AC-C1 (new): PASS (5/5 trials).
- AC-C2 (new): PASS (40/40 layer tests + live demo).

Future agents conforming to this standard operate against the
upgraded data + schema + consumer + carve-out layers from both
Campaign B and Campaign C.
