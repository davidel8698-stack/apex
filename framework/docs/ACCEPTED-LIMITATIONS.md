# APEX Accepted Limitations & Pending Dispositions

**Purpose.** This file is the canonical on-disk registry for APEX
limitations that have been explicitly dispositioned (accepted_limitation,
pending\_human, pending_implementation, wontfix, or under_investigation —
literal forms below, in entry `**Disposition:**` lines, are the
authoritative greppable tokens). Closure reports
(`ROUND-R{N}-CLOSURE.md`) cross-link to this file rather than restating
disposition state. Entries are removed (or marked closed) when a future
round's R-item re-opens them. Spec anchor: "State derives from disk."

**How to read.** Each entry uses a stable header pattern
(`### LIM-NNN: <one-line title>`) and a stable field set (Disposition /
Spec anchor / Reason / Criterion to re-open / Source dispositioning round
/ Owner). Auditors can enumerate every open disposition with
`grep '^### LIM-' framework/docs/ACCEPTED-LIMITATIONS.md`.

**How to add.** When a future audit finds a structural limitation that
must be deferred (not fixed in the current round), add a `LIM-NNN` entry
here in the round's remediation step rather than burying the disposition
in the closure report. The closure report references this file.

---

### LIM-001: IMP-031 thinking-token tracking in circuit-breaker.sh

- **Disposition:** `pending_human`
- **Spec anchor:** "IMP-031 mandates that `framework/hooks/circuit-breaker.sh` track thinking-tokens per tool call and escalate when a single call exceeds 20k thinking tokens or the rolling 5-call sum exceeds 50k." (`apex-spec.md` IMP-031 anchor; Mythos section 5.6.1.)
- **Reason:** The spec requires per-tool-call thinking-token accumulation in `STATE.circuit_breaker.thinking_token_window`, but the Claude Code runtime emits no thinking-token counts to the framework's view of `tool_response`. Without a runtime signal there is nothing to accumulate. Two paths forward exist: (a) the platform exposes thinking-token counts in `tool_response.usage.thinking_tokens` (or an equivalent slot), at which point a writer-side hook becomes trivial; or (b) the user accepts a STATE-side proxy design (heuristic estimator based on `tool_input` length, response length, and verbosity flags) — placeholder R-ID `R-631T`. Until one of the two lands, the spec's MUST cannot be satisfied without inventing data that the runtime does not provide. The audit chain has confirmed this carry-forward unchanged across R15 → R16 → R17.
- **Criterion to re-open:** Either (a) `tool_response.usage.thinking_tokens` (or platform-equivalent) appears in the PostToolUse envelope on a representative test call, OR (b) the user accepts a STATE-side proxy design and approves an R-item to author the estimator. This LIM closes when either path lands.
- **Source dispositioning round:** `ROUND-R15-CLOSURE.md` seed A; carried unchanged through R16 (Seed A) and R17 (Seed A).
- **Owner:** waiting on user decision (proxy design vs runtime feature request).

### LIM-002: R-632C runtime-cost measurement unrun

- **Disposition:** `pending_implementation`
- **Spec anchor:** IMP-032 critic risk-proportional review depth — `framework/agents/critic.md` adds three review dimensions on C-class and D-class tasks (deeper test coverage scrutiny, scope-creep detection, evidence-quality grading). The critic.md rollback-trigger language states "if delta > 30%, redesign."
- **Reason:** R16-632C landed the three additional review dimensions on C/D tasks, but no measurement has been recorded against a representative baseline. Without a baseline the 30% rollback-trigger cannot fire — it would have nothing to compare against. The R17 audit cannot perform a representative run from a read-only audit pass; the measurement requires running a C-class or D-class task end-to-end and recording the critic-pass duration delta vs the pre-R-632C critic logic. Planned remediation: `framework/scripts/measure-critic-cost.sh` (not authored in R17).
- **Criterion to re-open:** One published measurement against a representative C-class or D-class task, with delta vs the pre-R-632C baseline recorded in this file. LIM-002 closes when the measurement lands; this entry is replaced by a numeric baseline + delta line. Suggested measurement protocol: run three C/D tasks pre-revert (rollback critic.md to its pre-R-632C state), record critic-pass wall-clock + token cost; restore the R-632C critic.md; re-run the same three tasks; compute delta; document.
- **Source dispositioning round:** `ROUND-R16-CLOSURE.md` NF-W16-003; carried into R17 audit Seed (not replanned for R17 substance).
- **Owner:** R18 or later — first round willing to run the representative measurement.

### LIM-003: test-critic-scope-creep.sh dedicated regression absent

- **Disposition:** `pending_implementation`
- **Spec anchor:** IMP-022 — `framework/agents/critic.md` Pre-STEP scope-creep detection prose (R16-622C landed the prose; sibling tests + greps currently provide partial acceptance coverage).
- **Reason:** The critic Pre-STEP scope-creep detection prose is in place, but acceptance currently relies on greps against `critic.md` plus sibling tests that exercise scope-creep behavior indirectly. No dedicated regression test (`framework/tests/test-critic-scope-creep.sh`) exists with fixtures matching the IMP-022 Pre-STEP worked examples. The audit explicitly confirmed in R16 NF-W10-02 (and again in R17 seed J) that the structural anchor is intact — only the dedicated regression file is missing.
- **Criterion to re-open:** `framework/tests/test-critic-scope-creep.sh` lands with fixtures matching the IMP-022 Pre-STEP worked examples (positive case: scope creep detected; negative case: scope creep NOT spuriously detected on legitimate scope expansion documented in DECISIONS.md). LIM-003 closes when the test file lands and is wired into `framework/tests/run-all.sh`.
- **Source dispositioning round:** `ROUND-R16-CLOSURE.md` NF-W10-02; confirmed in R17 audit seed J.
- **Owner:** R18 or later — first round willing to author the dedicated regression.

---

## Removed / closed limitations

(none yet — this file was authored in R17-646 as the canonical registry).
Future rounds: when a LIM closes, move its block here with a one-line
`Closed in: ROUND-R{N}-CLOSURE.md` annotation so the audit trail is preserved.
