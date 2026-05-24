# Campaign B — Universal Tool-Call Audit-Trail Layer

> Follow-on / cross-cutting engineering campaign that generalises
> Campaign A's central lesson. **Sequenced AFTER Campaign A Gate 7
> closes.** Reuses Campaign A's mutation corpus + critic-review pattern
> + pre-registration discipline.
>
> This file is the **in-repo canonical plan** for Campaign B. The
> master `~/.claude/plans/noble-hopping-hamming.md` is local-only;
> this file is the GitHub-visible source of truth and the entry point
> for any new session that resumes after Campaign A closes.

---

## B-1. Why Campaign B exists

Campaign A taught us a sharp lesson: **the round-checker accepted the
auditor's *count* as ground truth**, with no independent claim
verification. That single trust-relation is the structural root of the
F-204-013 audit-honesty regression (R23 fabricated "6 hits" for
IMP-039; R24 ratified). Campaign A's fix (CR-04 spot-check) closes the
**specific** auditor↔round-checker channel.

**But the same trust pattern is everywhere in APEX, not only the
self-heal loop.** Phase-B-α exploration mapped **12 trust points + 13
verify points** across the agent definitions. Five trust points are
high-leverage. Three observations crystallise the campaign mandate:

1. **The infrastructure is already strong.**
   `framework/hooks/tool-event-logger.sh` is registered as
   `PostToolUse` with matcher `*` — **every tool call in a session is
   captured** into `.apex/event-log.jsonl` with full `tool_input`,
   `tool_response`, `is_error`. The data layer exists.

2. **One agent already uses it correctly.**
   `critic.md` STEP 1.6 / 1.7 (R-619 data-value cross-reference + tool
   call corpus check) reads the event-log, builds a CORPUS of every
   tool input + response, and FAILs the executor with
   `phantom_data_value` when a cited value is absent from the corpus.
   This is the pattern.

3. **The pattern is not generalised.** Of 12 trust points, only 4 are
   verified via the audit trail (all in critic.md). The remaining 8 —
   including the highest-leverage ones (round-checker, verifier,
   framework-auditor Axis 10, executor STEP 0.5 unverifiable premise) —
   accept claims by reasoning, not by tool-trail cross-reference.

**Worse, there are 7 infrastructure gaps in the data layer itself**,
the biggest being: **sub-agent transcripts do not aggregate back to
the parent project.** When the self-heal orchestrator spawns
`framework-auditor` via Task(), the sub-agent's tool-call trace is
written to its own project's `.apex/event-log.jsonl` under
`~/.claude/projects/<sub-project>/`. The parent's round-checker has NO
mechanism to read it. The only thing flowing back is the final result
message. **This is why F-204-013 was undetectable in the live loop** —
the proof against R23's "6 hits" lay in R23's own sub-agent
transcript, which R24's round-checker had no way to reach.

Campaign B closes both: the data-layer gaps AND the consumer-layer
gaps.

---

## B-2. Phase-B-α exploration findings (foundation)

### Data layer — 7 infrastructure gaps

| ID | Gap | Severity | Today |
|----|-----|----------|-------|
| GAP-1 | Sub-agent transcripts inaccessible to parent | **CRITICAL** | Only `SubagentStop` payload (token counts, final status) reaches parent |
| GAP-2 | No cross-session aggregation | high | Each context-rotation creates a new project; old logs unreachable |
| GAP-3 | No schema validation on event-log JSONL | high | Ad-hoc emission; field variance across event types |
| GAP-4 | No rotation / retention policy | medium | `.apex/event-log.jsonl` grows unbounded |
| GAP-5 | Sub-agent stop hook trusts `tool_calls_count` without reading transcript | high | Cannot detect sub-agent that *claimed* tool calls but did none |
| GAP-6 | Hashing partial (Bash only; Write/Edit/Read/Agent unhashed) | medium | Asymmetric observability — non-Bash calls don't enter recurring-error/result-fishing detection |
| GAP-7 | No pre-task claim capture | medium | Claims are written post-hoc with no separate "expected" baseline |

### Consumer layer — 5 highest-leverage trust points (top of 12 mapped)

| # | Trust point | Claim type | Audit-trail fix |
|---|-------------|-----------|-----------------|
| TP-1 | `critic.md` STEP 2 | Executor's `done_criteria_checked[].verified=true` | Re-execute every `verify_command` in STEP 2; compare claimed output to fresh output byte-for-byte |
| TP-2 | `round-checker.md` spot-check | Auditor's `coverage_map` axis-13 entries | Re-probe **every** axis-13 bypass attempt (not 3 samples); cross-reference exit codes |
| TP-3 | `verifier.md` STEP 1 | Executor's `files_modified[]` list | Independent `git diff HEAD~1 --name-only`; reject executor's list if mismatch |
| TP-4 | `executor.md` STEP 0.5 unverifiable branch | Premise marked "unverifiable" allows task to proceed | Escalate to `status=partial` + add premise to `issues_found[]` |
| TP-5 | `framework-auditor.md` Axis 10 | "Where is the path that bypasses them?" answered by reasoning | Mandate procedural bypass falsification (mirror Axis 13's pattern) |

---

## B-3. Quality standard

Same non-negotiable rigor controls as Campaign A. All apply here:

- **Pre-registration.** Schema spec, success thresholds, blind protocol
  pieces, and the metrics for "audit-trail coverage" frozen in Phase
  B0 before any code lands.
- **Blindness where applicable.** Independent design agent →
  independent critic review → independent implementation reviewer.
- **Re-use over invent.** Existing `tool-event-logger.sh`, existing
  `.apex/event-log.jsonl`, existing `critic.md` STEP 1.6/1.7 pattern,
  existing `subagent-stop.sh` — these are the foundation. New files
  only where existing utilities cannot reach (the schema JSON, the
  sub-agent-transcript aggregator hook).
- **Mutation-corpus verification.** Campaign A's working corpus +
  sealed held-out corpus are the cross-cutting empirical test for
  Campaign B too. **Hypothesis: post-Campaign-B, even a shallow
  auditor trial (R201/R202 pattern) cannot close the loop because
  round-checker's upgraded cross-reference rejects it on missing
  transcript coverage.** Variance between shallow and deep trials
  collapses; this is Campaign B's signature measurable.
- **Hard quality gates.** Phases B0..B6 each with explicit gate
  criteria.

---

## B-4. Phase overview

| Phase | Objective | Primary deliverable | Gate |
|-------|-----------|---------------------|------|
| B0 | Pre-register methodology + schema + thresholds | `audit-trail-review/EXPERIMENT-PROTOCOL.md` | Protocol frozen; schema versioned; thresholds numeric |
| B1 | Lock the trust-point register (Phase-B-α deliverable) | `audit-trail-review/TRUST-POINTS.md` | All 12 trust points classified; top 5 leverage agreed |
| B2 | Data layer hardening (close GAP-1..GAP-7) | code edits to hooks + new schema file | Sub-agent transcripts accessible; schema-validated entries; rotation policy live |
| B3 | Consumer layer fix design + critic review | `audit-trail-review/FIX-DESIGN.md` | Coverage matrix complete; critic PASS |
| B4 | Implement consumer-layer edits | code edits to 5 agent files | Atomic commits per TP; lint clean |
| B5 | Re-certify on Campaign A's mutation corpus | `audit-trail-review/FINAL-CERTIFICATION.md` | Variance collapse threshold met; held-out re-test green |
| B6 | Institutionalize | docs + retained corpus + protocol | Owner sign-off |

Phases are sequential; B0 → B1 → B2 → B3 → B4 → B5 → B6.

---

## B-5. Phase detail

### Phase B0 — Methodology lock-in

Lock in:
- **Event-log schema v1** (the JSON Schema for entries; field types,
  required fields, version field for forward-compat).
- **Sub-agent transcript aggregation protocol** — *how* the child's
  event-log reaches the parent (symlink? copy on SubagentStop? a hook
  that writes a `SUBAGENT-TRACE-<agent-id>.jsonl` into the parent's
  `.apex/`?). Decide between approaches in Phase B0; freeze the
  decision before B2 implements.
- **"Audit-trail coverage" metric** — what fraction of an agent's
  claims are verifiable against the trail. Frozen formula.
- **Variance-collapse threshold** — Campaign A's R201/R202/R203
  showed variance 3/13 vs 3/13 vs 13/13. Pre-register: post-B5, three
  trials must produce ≥ X% identical kill matrices (X chosen now, not
  after data).
- **Negative control** — running the upgraded pipeline on the pristine
  framework must still produce ≤ N findings, with N matching Phase-A
  R204's count (~13) ± Y. Diff = real new defects exposed by the new
  layer; not regression noise.

Deliverable: `audit-trail-review/EXPERIMENT-PROTOCOL.md`, frozen.

### Phase B1 — Trust-point register

The Phase-B-α exploration (already done) produced 12 trust points + 5
top-leverage (table in §B-2 above).

Phase B1 formalises this into `audit-trail-review/TRUST-POINTS.md` —
the source-of-truth for what Phase B3 must close. Adds one column per
trust point: which audit-trail mechanism closes it.

**Gate B1:** every TP in the register has a proposed audit-trail
mechanism; the 5 top-leverage have detailed proposed mechanism +
acceptance test.

### Phase B2 — Data layer hardening (heaviest phase)

Close GAP-1..GAP-7. **GAP-1 is the load-bearing item — start there.**

**B2.1 — Sub-agent transcript aggregation (closes GAP-1).** Add to
`framework/hooks/subagent-stop.sh` (already runs on `SubagentStop`
event) the step: locate the child sub-agent's project at
`~/.claude/projects/<encoded-cwd>/.apex/event-log.jsonl`, **copy its
contents** into the parent's
`.apex/subagent-transcripts/<agent-id>-<round-tag>.jsonl` with a
header line
`{"type":"transcript_imported","source_project":<path>,"agent_id":<id>}`.

Why copy not symlink: symlinks break across OneDrive sync; copy is
robust. Tradeoff: storage cost. Mitigate via Phase B2.3 rotation.

**B2.2 — Schema enforcement (closes GAP-3).** New file
`framework/schemas/EVENT-LOG-ENTRY.schema.json` — JSON Schema with
`oneOf` for each event type. Modify `tool-event-logger.sh` and
`_state-update.sh` to **validate before appending**; on schema
failure, write to `.apex/event-log-rejected.jsonl` AND surface a
non-blocking warning to stderr. Backward-compat: schema v1 covers
existing types; new types must be added explicitly.

**B2.3 — Rotation / retention (closes GAP-4 + GAP-2).** When
`.apex/event-log.jsonl` exceeds 10 MB, rotate to
`.apex/event-log-<YYYY-MM-DD>.jsonl.gz` (compress on rotate). Keep
last 90 days. Add a tiny tool `framework/hooks/event-log-rotate.sh`
called by the `SessionStart` hook.

**B2.4 — Universal hashing (closes GAP-6).** Extend
`circuit-breaker.sh` ring buffers to hash Write/Edit/Read/Agent
calls, not only Bash. Same `recent_command_hashes` schema.
Result-fishing detection becomes symmetric across tool types.

**B2.5 — Pre-task claim capture (closes GAP-7).** Light: extend the
existing `pre-task-snapshot.sh` to also write a
`.apex/pre-task-claims/<task-id>.json` containing the agent's
*expected* deliverables (read from PLAN_META.json). At completion the
critic diffs expected vs delivered.

**B2.6 — Sub-agent hallucination guard (closes GAP-5).** Modify
`subagent-stop.sh` to require: the child's claimed
`tool_calls_count` must equal the line count of `tool_call`-typed
entries in the imported transcript ± 2 (small drift tolerance).
Mismatch → P0 finding emitted by the orchestrator.

**Gate B2:** every gap has an implemented + tested fix. Tests live in
`framework/tests/test-audit-trail-layer.sh` (new, ≤ 200 lines).

### Phase B3 — Consumer layer fix design + critic review

Author `audit-trail-review/FIX-DESIGN.md`. For each TP-1..TP-5:

- target file + exact anchor + replacement text
- the audit-trail mechanism that closes it
- the acceptance test
- the Phase-B5 effect (which threshold it lifts)

Coverage matrix at the top — one row per trust point.

Independent `critic` clean-room review. Iterate until PASS.

**Gate B3:** zero orphan rows; critic verdict PASS.

### Phase B4 — Implement consumer-layer edits

Apply the TP-1..TP-5 fixes. Atomic commit per TP. Files touched:

- `framework/agents/critic.md` — STEP 2 re-execution mandate
- `framework/agents/specialist/round-checker.md` — full coverage_map re-probe, not sample
- `framework/agents/verifier.md` — independent `git diff` STEP 1
- `framework/agents/executor.md` — STEP 0.5 escalation to PARTIAL
- `framework/agents/specialist/framework-auditor.md` — Axis 10
  procedural sub-pass

After Phase B4, run `framework/tests/run-all.sh --json` from `.lab/`.
Confirm `failed:0`, all four prose-sensitive tests green
(`test-agent-lint.sh`, `test-command-structure.sh`, `test-docs.sh`,
`test-wiring.sh`), plus the new `test-audit-trail-layer.sh`.

**Gate B4:** every commit maps to a coverage-matrix row; lint clean;
test suite green.

### Phase B5 — Re-certification on Campaign A's mutation corpus

The signature measurement of Campaign B is **variance collapse**.
Method:

1. Re-run the 3 baseline trials of Campaign A's WORKING corpus on the
   **post-Campaign-B** auditor + round-checker.
2. Compare each trial's kill matrix to the others.
3. Pre-registered threshold from B0: trial-to-trial agreement ≥ X%
   (and per-class B+C+D reliable-kill ≥ 7/8 working, ≥ 4/5 held-out
   — the Campaign A bar, maintained).
4. Also re-run the held-out corpus + negative control. Held-out ≥
   pre-reg; negative control 0 fabricated findings.

A round-checker that now **rejects** a shallow trial (because the
auditor's transcript doesn't show actual bypass attempts) is the
signature behaviour. Variance should collapse not because shallow
trials catch more, but because shallow trials no longer close the
loop — they get CONTINUE'd and re-tried until depth is reached.

**Independent critic** of
`audit-trail-review/FINAL-CERTIFICATION.md`.

**Gate B5:** all pre-registered thresholds met; critic PASS; if any
miss → loop back to B3 OR documented escalation.

### Phase B6 — Institutionalize

Same shape as Campaign A's Phase 7:

- Keep `audit-trail-review/` artifacts (protocol, trust-points,
  fix-design, certification) for re-runnability.
- Update `framework/docs/AUDIT-TRAIL-STANDARD.md` (new doc) describing
  the contract: every claim by every agent must be verifiable against
  the trail; how new agents should write their claims; how reviewers
  cross-reference.
- Update project memory with the new standard.

**Gate B6:** owner sign-off.

---

## B-6. Coverage matrix (target → fix → test)

| Target | Phase B | Mechanism | Acceptance test |
|--------|---------|-----------|-----------------|
| GAP-1 sub-agent transcripts inaccessible | B2.1 | `subagent-stop.sh` copies child's event-log into parent's `subagent-transcripts/` | a Task() invocation produces a transcript file readable post-hoc from the parent |
| GAP-2 cross-session aggregation | B2.3 | rotation creates dated archives; aggregation tool reads across | a multi-session task's audit trail reconstructable from the archives |
| GAP-3 no schema validation | B2.2 | `EVENT-LOG-ENTRY.schema.json` + emitter validation | malformed entry routed to `event-log-rejected.jsonl` not main log |
| GAP-4 no rotation | B2.3 | `event-log-rotate.sh` triggered at 10 MB | a > 10 MB log rotates on next SessionStart; old archive present, gzip'd |
| GAP-5 sub-agent hallucination guard | B2.6 | `subagent-stop.sh` cross-references claimed count vs imported transcript | a sub-agent that lies about tool call count → P0 finding emitted |
| GAP-6 partial hashing | B2.4 | ring buffer covers Write/Edit/Read/Agent too | result-fishing detection fires on repeated identical Reads |
| GAP-7 no pre-task claim capture | B2.5 | `pre-task-snapshot.sh` writes claims file | critic can diff expected vs delivered |
| TP-1 critic STEP 2 re-execution | B3+B4 | critic re-runs every `verify_command`, compares output | a fabricated verify_command output → CRITICAL fail |
| TP-2 round-checker full re-probe | B3+B4 | re-probe ALL axis-13 items, not sample | F-204-013 scenario reconstructable; recurrence blocked |
| TP-3 verifier independent git diff | B3+B4 | verifier runs `git diff HEAD~1` independently | executor's omitted-from-list file → caught by verifier |
| TP-4 executor STEP 0.5 escalation | B3+B4 | unverifiable premise → `status=partial` + `issues_found[]` | premise that fails grep but task proceeds → PARTIAL not PASS |
| TP-5 framework-auditor Axis 10 procedural | B3+B4 | mandate concrete bypass attempt (Axis-13 pattern) on each named guard | guard with subtle backdoor → caught in Axis 10 |

Zero orphan rows. Every gap + trust point has a fix and an
acceptance test.

---

## B-7. Critical files

| File | Role | Phase |
|------|------|-------|
| `framework/hooks/tool-event-logger.sh` | Validate against schema before append | B2.2 |
| `framework/hooks/subagent-stop.sh` | Import child transcript; verify count match | B2.1 + B2.6 |
| `framework/hooks/circuit-breaker.sh` | Universal hashing | B2.4 |
| `framework/hooks/pre-task-snapshot.sh` | Pre-task claims capture | B2.5 |
| `framework/hooks/event-log-rotate.sh` (NEW) | Rotation | B2.3 |
| `framework/schemas/EVENT-LOG-ENTRY.schema.json` (NEW) | Schema source | B2.2 |
| `framework/agents/critic.md` | STEP 2 re-execution | B3 + B4 |
| `framework/agents/specialist/round-checker.md` | Full coverage_map re-probe | B3 + B4 |
| `framework/agents/verifier.md` | Independent git diff STEP 1 | B3 + B4 |
| `framework/agents/executor.md` | STEP 0.5 escalation | B3 + B4 |
| `framework/agents/specialist/framework-auditor.md` | Axis 10 procedural | B3 + B4 |
| `framework/docs/AUDIT-TRAIL-STANDARD.md` (NEW) | Contract doc | B6 |
| `framework/tests/test-audit-trail-layer.sh` (NEW) | Layer tests | B2 |
| `audit-trail-review/*` (NEW dir) | Campaign artifacts | all |

**3 new files in `framework/`**, 1 new test, 1 new dir. Everything
else is additive prose. Per scope discipline.

---

## B-8. Pre-registered acceptance criteria (frozen in Phase B0)

The campaign **succeeds** only if ALL of the following hold:

- **GAP-1 closed:** for every Task() invocation in the post-B5
  self-heal pipeline, the parent project can read the sub-agent's
  full tool-call trace from `.apex/subagent-transcripts/`.
- **Schema validation:** ≥ 99% of new event-log entries pass schema.
- **Variance collapse:** 3 baseline trials on Campaign A's working
  corpus produce per-class kill-rate stddev ≤ 1 mutant (currently
  the stddev is ~6 — the 3/13 vs 13/13 spread).
- **Class-A control unchanged:** 3/3 reliably killed (no regression).
- **B+C+D combined:** working ≥ 7/8 + held-out ≥ 4/5 reliably killed
  (matches Campaign A's bar — Campaign B should not *lower* the bar).
- **Negative control:** the 13 real defects in the unmutated framework
  (per Phase-A R204) are still surfaced — and not artificially
  amplified.
- **No regression:** `run-all.sh` `failed:0`; the four prose-sensitive
  tests + the new `test-audit-trail-layer.sh` green.
- **Critic PASS** on `audit-trail-review/FIX-DESIGN.md` and on the
  final state.
- **Sub-agent count guard works:** a synthetic test in
  `test-audit-trail-layer.sh` injects a "lying" sub-agent (claims
  tool_calls_count > 0 but transcript empty) → orchestrator emits P0.

Threshold X for variance collapse and the exact "Y" tolerance for the
negative-control diff are **set in Phase B0 before any data**.

---

## B-9. Risk register

| Risk | Mitigation |
|------|-----------|
| Sub-agent project location varies across Claude Code versions | B0 reads current layout; B2.1 implementation tests against current version; documented brittleness with a re-discovery path |
| Schema enforcement breaks existing emitters | Schema is v1 + permissive `oneOf`; rejected entries go to a side-log not blocked; emitters fail-loud but non-blocking |
| Universal hashing produces too much noise | Hash policies tunable; only the first 200 chars of large payloads enter the buffer |
| Critic STEP 2 re-execution doubles cost | Cap at N criteria per task (sample with priority on D-level); document |
| Sub-agent transcript copy is large | Rotation policy keeps `.apex/subagent-transcripts/` bounded; old transcripts compressed |
| The audit-trail-import hook fires before child finishes writing | Hook waits on child's stop signal (already the case for SubagentStop); plus retry-once on empty source |
| Campaign B fixes Campaign A's CR-04 again (overlap) | Sequenced AFTER Campaign A Gate 7; Campaign B's TP-2 is an *upgrade* of CR-04 from sampling to full coverage |

---

## B-10. Relationship to Campaign A

Campaign A and Campaign B are **complementary, sequenced**:

| Aspect | Campaign A | Campaign B |
|--------|-----------|-----------|
| Scope | Self-heal detection process specifically | Universal audit-trail across the whole framework |
| Lever | Lock detection depth via instruction edits | Lock claim verification via audit-trail enforcement |
| Phases | A0..A7 | B0..B6 (sequenced after A7) |
| Mutation corpus | Authored fresh in A0; sealed held-out | **Re-uses A's corpus** — no new mutants authored |
| New files | None (additive prose only) | 3 — schema, rotate hook, layer test |
| Signature metric | Per-class reliable-kill rate | Trial-to-trial variance collapse |
| Owner-approved spec change | Axis count 12 → 13 (Campaign A) | A short additional paragraph (Campaign B) describing the audit-trail standard |

**Campaign A's CR-04 (round-checker spot-check)** is upgraded by
Campaign B's TP-2: sampling → full coverage. A user who runs Campaign
A only gets a *defended* detector; a user who runs both gets a
detector that **cannot regress to F-204-013-style fabrication**
because every claim is cross-referenced.

---

## B-11. Scope discipline

- **Re-use over invent.** Existing `tool-event-logger.sh` IS the
  foundation; we extend it, not replace it. Existing critic.md STEP
  1.6/1.7 is the model; we replicate it. Existing Campaign A
  mutation corpus is the test; we don't author new mutants.
- **Lean implementation.** 3 new files in `framework/`. Everything
  else additive prose. The rigor lives in the campaign discipline,
  not in framework bloat.
- **Does not** rewrite agent semantics — only adds verification steps.
- **Does not** introduce a new persistent service / daemon — all
  enforcement is hook-based + agent-instruction-based.
- **Cost honest:** Campaign B is heavier than Campaign A. The
  sub-agent transcript aggregation alone is non-trivial and brittle
  across Claude Code versions. Campaign A first; Campaign B builds
  on it. Phases B2 and B5 are the heavy compute parts (transcript
  copies + N=3 re-runs). Plan accordingly.

---

## B-12. End state

When Campaign B closes:

- Every Task() invocation in the framework produces a tool-call
  transcript that downstream agents can read post-hoc.
- Every high-leverage claim across the framework (5 trust points) is
  cross-referenced against that transcript before being accepted.
- The round-checker upgrade means **no shallow round can close the
  loop** — depth becomes a precondition for closure, enforced by
  evidence not promise.
- F-204-013-class fabrication is detectable at write-time (schema +
  sub-agent count guard) AND blockable at closure-time
  (round-checker full re-probe).
- The owner's question evolves a second time: from *"the detector
  kills 90% of defects, here is the evidence"* to *"every claim in
  every agent's output is verifiable against the audit trail; here
  is the trail, here is the verification."*

Audit-trail is the **structural** answer to the question "how do
you know the AI did what it said?" Campaign B installs the
structure.
