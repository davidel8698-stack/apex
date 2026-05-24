# RESUME PROMPT — Campaign B (Universal Tool-Call Audit-Trail Layer)

> **For the next Claude Code session.** The user (the framework owner, working from mobile) opens a new session in the APEX project and types: **"read detector-review/RESUME-PROMPT.md and continue end-to-end."** That's the entire user-input requirement. Everything you need is below.

═══════════════════════════════════════════════════════════════════════
CURRENT STATUS — 2026-05-24 (read this FIRST)
═══════════════════════════════════════════════════════════════════════

- **Campaign A — CLOSED, PASS-WITH-LIMITATION** as of 2026-05-24.
  Nine atomic commits past baseline `8ac2a85` (`3a78d9f`..`b80936c`).
  All 8 CRs + CR-spec applied to live `framework/`. Held-out 8/8
  reliably killed (decisive generalisation test passed in full).
  `framework/tests/run-all.sh` 72/72 PASS post-fix. Two §9 thresholds
  missed → documented as **L-DH-01** (magic-string carve-out subclass)
  and **L-DH-02** (auditor budget exhaustion) with Phase-7 R-items
  reserved (`R-DH-P7-01..03`). Negative control surfaced 10 NEW real
  live-framework defects → separate owner-triage track. **DO NOT
  re-run Campaign A.** Source-of-truth: `detector-review/FINAL-CERTIFICATION.md`
  + `framework/docs/DETECTION-STANDARD.md`.

- **Campaign B — NOT STARTED.** Plan: `detector-review/CAMPAIGN-B-PLAN.md`
  (this file's companion). **THIS is the next session's job.**

═══════════════════════════════════════════════════════════════════════
NON-NEGOTIABLE EXECUTION STANDARD FOR CAMPAIGN B
═══════════════════════════════════════════════════════════════════════

The owner has explicitly mandated **maximum professional rigor** for
this campaign: *"the highest quality, most rigorous, most meticulous
standards possible — no compromises."* Translate that to operational
discipline:

1. **Pre-registration is sacred.** Every schema, threshold, protocol
   choice, and metric is FROZEN in writing before the measurement
   that depends on it. Post-data changes require dated §12 amendment
   entries with rationale. No exceptions.

2. **Blind 3-agent protocol where the design calls for it.** Injector
   / Detector / Scorer are SEPARATE `Task()` invocations with no
   shared context. Critic clean-room reviews are mandatory at Phase
   B3 (fix design) and Phase B5 (final state). Verdict PASS required
   to advance.

3. **N ≥ 3 trials on every measurement.** Single-run conclusions are
   not permitted. Report spread, not just mean. Trial counts may be
   raised before a study starts, **never lowered** mid-study.

4. **Held-out generalization is the decisive test.** Phase B5 re-uses
   Campaign A's sealed held-out corpus + working corpus. Variance
   collapse (stddev ≤ 1 mutant per class across the 3 trials) is the
   signature metric — set the threshold in B0 BEFORE any data.

5. **Coverage-matrix discipline.** Every GAP-N + every TP-N maps to a
   fix maps to an acceptance test. Phase B3's `FIX-DESIGN.md` MUST
   contain this matrix with **zero orphan rows**. Critic verifies.

6. **Atomic commits with one-to-one traceability.** Phase B4: one
   commit per TP-N (or per coherent group), commit message names the
   specific TP-ID being closed. Reviewable per-commit; rollback-safe.

7. **Regression gates are hard stops.** After every code-landing
   phase (B2, B4): run `framework/tests/run-all.sh` from `.lab/` in
   background. Confirm `failed:0` AND the four prose-sensitive tests
   green (`test-agent-lint.sh`, `test-command-structure.sh`,
   `test-docs.sh`, `test-wiring.sh`) AND the new
   `test-audit-trail-layer.sh` green. Do not advance on regression.

8. **GAP-1 sub-agent transcript aggregation is load-bearing.** This
   is the structural answer to F-204-013. Its acceptance test must be
   DEMONSTRATED — invoke a real `Task()`, then read the imported
   transcript file from `.apex/subagent-transcripts/`. Don't claim it
   works; show it with file content cited.

9. **Honest limitation handling.** When a threshold is missed: either
   fix it (loop back to the appropriate phase) OR record an
   accepted-limitation entry with written rationale + reserved
   Phase-7 R-item (Campaign A's L-DH-01..03 + R-DH-P7-01..03 pattern).
   **Never silently waive.** Surfaced limitations are owner-visible.

10. **Re-use over invent.** The data layer is already strong
    (`framework/hooks/tool-event-logger.sh` PostToolUse universal;
    `critic.md` STEP 1.6/1.7 is the verification pattern). New files
    only where existing utilities cannot reach. Per scope discipline
    in CAMPAIGN-B-PLAN.md §B-11: **3 new files in `framework/`** —
    schema JSON, rotate hook, layer test. Everything else is additive
    prose to existing files.

═══════════════════════════════════════════════════════════════════════
THE STORY (kept for context; closed)
═══════════════════════════════════════════════════════════════════════

═══════════════════════════════════════════════════════════════════════
SETUP — verify before starting
═══════════════════════════════════════════════════════════════════════

1. **Bypass mode** is set at project level (`.claude/settings.local.json`
   contains `"defaultMode": "bypassPermissions"`). No approval prompts
   should appear. The owner is on mobile and is not watching for
   approve dialogs.

2. **Framework install on the container** — run as your FIRST action:
   ```
   bash framework/scripts/sync-to-claude.sh
   ```
   The phone container starts with an empty `~/.claude/`. `sync-to-claude.sh`
   installs the Campaign-A-fixed framework agents/hooks/commands to
   `~/.claude/` so that `Task(framework-auditor, ...)` etc. find the
   correct (post-Campaign-A) definitions.

3. **If a sub-agent hits a soft block** (a framework hook catches a
   literal "override-marker" phrase, or a sub-agent self-interprets a
   system-reminder as forbidding Write), that's a framework safety
   mechanism — not a permission issue. Apply the known workaround:
   capture the agent's inline content and write to disk yourself.

═══════════════════════════════════════════════════════════════════════
THE STORY — what triggered this campaign and why it matters
═══════════════════════════════════════════════════════════════════════

The framework owner (a non-programmer architect who built APEX) ran
`/apex:self-heal` for 24 rounds. R21, R22, R23, R24 all closed CLOSED
with 0 P0/P1 findings — the loop's two-consecutive-clean-rounds
terminator fired and the framework was tagged STABLE / CONVERGED.

The owner became suspicious. He asked (translated from Hebrew): *"How
can it be that you found nothing? A super-complex system with no gaps
at all? Did we reach perfection?"* Then sharpened: *"I suspect there
is some problem in the process of detecting failures, gaps and errors
in the self-healing loop. Focus on that."*

That instruction is the entire mandate. The subject is NOT the
framework's health — it is the framework's DETECTION PROCESS:
`framework-auditor` (Step A), `remediation-planner` (Step B),
`batch-scheduler` (Step C), `wave-executor` (Step D), `round-checker`
(Step E), and the `/apex:self-heal` orchestrator that drives them.

The owner asked for maximum rigor: *"a super-professional,
comprehensive, high-quality plan, built so that nothing gets missed,
where every axis of action is executed in the highest and strictest
quality standards."* Not a lean patch — a properly engineered
verification-and-fix campaign with pre-registration, blind
experimental protocol, N-trial measurement, held-out corpus,
traceability matrix, independent critic review, hard quality gates.

═══════════════════════════════════════════════════════════════════════
WHAT WAS EMPIRICALLY ESTABLISHED (Phases 0–3, already on disk)
═══════════════════════════════════════════════════════════════════════

The owner was right. The detection process IS broken. Four proofs:

1. **NON-DETERMINISTIC DEPTH.** Same mutated lab, same agent
   definition, same neutral prompt shape, three trials: R201
   (114 tool calls) caught 3/13 mutants. R202 (70 tool calls)
   caught 3/13. R203 (162 tool calls) caught 13/13. When the
   auditor goes deep, it catches almost everything; when shallow,
   only missing-file presence-checks. The loop closes whenever it
   lands shallow. By the protocol's reliable-kill criterion
   (≥2/3 trials), Class B/C/D/E mutants score 0/10.

2. **F-204-013 — HISTORICAL FABRICATION.** The negative-control
   auditor on the pristine framework surfaced a meta-finding
   accusing R23 of carrying false numerical coverage claims that
   R24 ratified ("R23 claimed '6 hits' for IMP-039 fields; live
   grep returns 0"). Historical convergence was partly built on
   un-verified evidence.

3. **PRIMING REDUCES DEPTH 76%.** R206 primed with the canonical
   "POST-CONVERGENCE CONFIRMATION ROUND — zero findings" bait via
   `previous_findings_path`: 4 findings. R205 same defect neutral
   framing: 17 findings. Both killed W-A1 — priming doesn't blind
   but lowers thoroughness dramatically. R24's self-label was
   exactly the priming pattern.

4. **L17 — ORPHAN-FILE SILENT MISS.** `self-heal.md` Step E's glob
   `NEW-FINDINGS-R<N>-W<X>.md` silently misses
   `NEW-FINDINGS-ORCHESTRATOR-R<N>.md`. The file
   `NEW-FINDINGS-ORCHESTRATOR-R20.md` exists at the repo root NOW,
   unprocessed by every closure since R20. W-F2 confirmed it.

Plus: the negative control found 13 real unfixed spec-conformance
gaps in the live framework (IMP-013 paste-domains incomplete,
IMP-039 schema split absent, IMP-045 / 046 / 050 / 052 / 054 / 056 / 057
mechanisms absent, IMP-067 / 068 critic checks absent, IMP-070
RISK-DELTA, IMP-071 / 072 / 073 health-check items, IMP-064 partial,
etc). Real gaps the recent R20-R24 rounds missed.

═══════════════════════════════════════════════════════════════════════
THE 7-PHASE CAMPAIGN — where we are
═══════════════════════════════════════════════════════════════════════

```
Phase 0  [DONE]  Methodology lock-in (pre-registration frozen)
Phase 1  [DONE]  Diagnose detection pipeline (26 leak points, W1–W8)
Phase 2  [DONE]  Mutation-test current detector (6 trials + W-F1 + W-F2)
Phase 3  [DONE]  Root-cause every survivor (8 CRs, exact source anchors)
Phase 4  [HERE]  Fix Design + critic review  ← RESUME HERE
Phase 5  [TODO]  Implement edits + install
Phase 6  [TODO]  Re-certify on working + held-out corpora
Phase 7  [TODO]  Institutionalize
```

═══════════════════════════════════════════════════════════════════════
STATE ON DISK — read in this order, in full
═══════════════════════════════════════════════════════════════════════

1. `detector-review/EXPERIMENT-PROTOCOL.md`
   Frozen pre-registration. §6 corpus, §8 scoring rubric, §9 Phase-6
   thresholds (the bar the fix must clear), §12 amendments (lab
   relocated from C:/temp to .lab/; W-F3 added post-pre-registration
   after critic flagged W5 coverage gap).

2. `detector-review/BASELINE.md`
   Phase-2 result. Full kill matrix per mutant × per trial. W1–W8
   verification (each weakness confirmed / refined / refuted by
   data). Framing-effect delta. F-204-013 evidence. Pre-registered
   baseline-prediction vs actual (matched).

3. `detector-review/ROOT-CAUSE.md`
   Phase-3 output. 8 CRs:
     CR-01 unconstrained depth
     CR-02 test-suite inheritance
     CR-03 no anti-priming
     CR-04 count-based stop + audit-honesty regression
     CR-05 filename-contract gap (L17)
     CR-06 no SPEC-GAP-CANDIDATE class
     CR-07 orchestrator framing injection
     CR-08 posture mislabel (clean-pending-spot-check rung needed)
     CR-spec apex-spec.md (axis count 12→13 + one sentence)
   Each with exact file:line anchor, 5-whys trace, fix direction.

4. `detector-review/manifests/WORKING-CORPUS.md` (+ `WORKING-CORPUS-CRITIC.md`)
   16 mutants: A=3 spec-conformance · B=3 guard-bypass · C=3 silent-
   failure · D=2 vacuous-test · E=2 spec-silent · F=3 pipeline
   probes (W-F1 planner, W-F2 orchestrator-glob, W-F3 framing).
   Critic verdict PASS-WITH-CHANGES; all I-issues applied.

5. `detector-review/manifests/HELDOUT-CORPUS.md.sealed`
   **DO NOT OPEN until Phase 6.** Anti-overfitting control. 8 fresh
   A–E mutants + 2 F probes. The decisive generalization test.

6. `detector-review/trials/` — 6 trial files + W-F1 + W-F2 +
   INJECTION-LOG (all baseline + negative-control + framing
   captured; sub-agent inline outputs preserved).

═══════════════════════════════════════════════════════════════════════
RESUME — run Phase 4 → 7 to completion, no stops
═══════════════════════════════════════════════════════════════════════

## PHASE B0 — Methodology lock-in (pre-registration) ← START HERE

This phase produces ZERO code changes. It produces ONE frozen document:
`audit-trail-review/EXPERIMENT-PROTOCOL.md`. **The campaign cannot
proceed past B0 until that document is frozen.**

Sub-deliverables, all in the protocol:

**B0.1 Event-log schema v1.** A JSON Schema (frozen) describing every
event type currently in `.apex/event-log.jsonl`: `state_mutation`,
`tool_call`, `memory_sample`, plus the new types Campaign B will add
(`transcript_imported`, `pre_task_claim`, `subagent_count_mismatch`,
etc.). Each event has required fields, types, version field for
forward-compat. Schema lives at `framework/schemas/EVENT-LOG-ENTRY.schema.json`
(implementation in B2; design in B0).

**B0.2 Sub-agent transcript aggregation protocol.** Decide WHERE the
child's event-log gets imported, WHEN (on `SubagentStop`), with WHAT
filename pattern, and how concurrent sub-agents are namespaced. The
CAMPAIGN-B-PLAN.md §B2.1 proposes COPY into
`.apex/subagent-transcripts/<agent-id>-<round-tag>.jsonl`. Verify the
proposal against the actual Claude Code project layout
(`~/.claude/projects/<encoded-cwd>/.apex/event-log.jsonl`) — read the
current `framework/hooks/subagent-stop.sh` source to ground the
mechanism. Freeze the exact decision.

**B0.3 Audit-trail coverage metric.** Define the precise formula:
"fraction of an agent's claims that are verifiable against the
trail." Operationalise — what counts as "a claim"? What counts as
"verifiable"? Pre-register: post-B5 fixed detector must achieve
audit-trail coverage ≥ X% on a representative trial. X is chosen now.

**B0.4 Variance-collapse threshold.** Campaign A's R201/R202/R203 ran
3/13, 3/13, 13/13 on the same lab → per-class kill-rate stddev ≈ 6.
Pre-register: post-B5, per-class stddev ≤ N across 3 trials on the
working corpus. N is chosen now, before any data. The CAMPAIGN-B-PLAN.md
§B-8 proposed N=1; verify or revise in B0.

**B0.5 Negative-control delta tolerance.** Campaign A R204 negative
control surfaced 13 live-framework defects. Post-B5 NC must produce
≤ 13 ± Y findings (Y chosen now). Diff > Y = real new defects
exposed by the new layer (good) or regression noise (bad). Pre-
register the disambiguation rule.

**B0.6 Trial design.** Reaffirm N=3 trials per measured condition.
Specify how concurrent trials are isolated (separate `.lab/` clones).
Specify the seed/randomness handling.

**B0.7 Blind protocol roles.** Define Injector / Detector / Scorer /
Critic responsibilities for each phase. Mirror Campaign A's pattern.

**B0.8 Acceptance criteria.** Crystallize §B-8 of CAMPAIGN-B-PLAN.md
into numeric, dated, frozen thresholds.

**Gate B0:** `audit-trail-review/EXPERIMENT-PROTOCOL.md` exists,
contains all 8 sub-deliverables, every threshold is a numeric value
(not "TBD"), and a `## §X. Freeze declaration` block at the end
states the date and the baseline commit.

## PHASE B1 — Trust-point register

Formalise the 12 trust points + 5 top-leverage from Phase-B-α into
`audit-trail-review/TRUST-POINTS.md`. The Phase-B-α exploration
already produced the raw data (see `CAMPAIGN-B-PLAN.md` §B-2). Phase
B1 adds the "fix mechanism" column for each TP and detailed
acceptance tests for the top-5.

**Gate B1:** every TP has a fix mechanism; top-5 have detailed
mechanism + acceptance test.

## PHASE B2 — Data layer hardening (close GAP-1..GAP-7)

The heaviest phase. **B2.1 — sub-agent transcript aggregation — is
the load-bearing item; start there.** Then B2.2..B2.6 close the
remaining gaps. Implementation details in `CAMPAIGN-B-PLAN.md` §B-5.

After each B2.N sub-fix lands: run the new
`framework/tests/test-audit-trail-layer.sh` and confirm the relevant
case passes. After ALL B2.N lands: full `run-all.sh --json` from
`.lab/`. Atomic commits.

**Gate B2:** every GAP-N has an implemented + tested fix; full suite
green; `.apex/subagent-transcripts/` directory works end-to-end
(demonstrated with a real `Task()` invocation).

## PHASE B3 — Consumer layer fix design + critic review

Author `audit-trail-review/FIX-DESIGN.md` for TP-1..TP-5. Coverage
matrix at the top — zero orphan rows. Critic clean-room review.
Iterate until PASS.

**Gate B3:** coverage matrix complete; critic PASS.

## PHASE B4 — Implement consumer-layer edits

Apply TP-1..TP-5 fixes atomically to:
- `framework/agents/critic.md` (TP-1)
- `framework/agents/specialist/round-checker.md` (TP-2)
- `framework/agents/verifier.md` (TP-3)
- `framework/agents/executor.md` (TP-4)
- `framework/agents/specialist/framework-auditor.md` (TP-5)

INSTALL: `cp` each edited source to `~/.claude/agents/specialist/`
and `~/.claude/agents/` respectively. One commit per TP.

Run `run-all.sh` + `test-audit-trail-layer.sh`. Both green.

**Gate B4:** every commit maps to a coverage-matrix row; lint clean;
suite green.

## PHASE B5 — Re-certification on Campaign A's mutation corpus

Re-run the 3 baseline trials on `.lab/apex-detector-lab-baseline`
(same 13 working mutants Campaign A used). Also: held-out 8 mutants;
negative control; W-F3 framing pair.

**Signature measurement: variance collapse.** Per-class kill-rate
stddev ≤ pre-registered threshold (from B0). The mechanism: the
upgraded round-checker REJECTS a shallow trial (its imported
transcript shows no real bypass attempts) → CONTINUE instead of
CLOSED. Shallow trials no longer close the loop.

Score against §B-8 thresholds. Critic review of final state.

Write `audit-trail-review/FINAL-CERTIFICATION.md` with before/after.

**Gate B5:** all thresholds met; critic PASS; if miss → loop to B3
OR documented accepted-limitation entry with R-item (mirror
Campaign A's L-DH-01..03 + R-DH-P7-01..03 pattern).

## PHASE B6 — Institutionalize

Write `framework/docs/AUDIT-TRAIL-STANDARD.md` — the contract for
every future agent + every future audit. Update project memory.
Keep `audit-trail-review/` artifacts for re-runnability.

Final one-screen summary to the owner: before/after variance, fixes
landed, threshold pass/fail, any reserved R-items, any new live-
framework defects surfaced.

**Gate B6:** owner sign-off.

═══════════════════════════════════════════════════════════════════════
WORKING ENVIRONMENT
═══════════════════════════════════════════════════════════════════════

- Repo: `C:/Users/דודאלמועלם/OneDrive - Tiva 13 Engineers/שולחן העבודה/APEX`
- Lab clones: `<repo>/.lab/` (NOT `C:/temp` — sub-agents are
  allow-listed only to project tree + `/tmp`)
- Baseline commit: `8ac2a858423c490d58bd22fba742c51bf0c7021a` (pinned)

═══════════════════════════════════════════════════════════════════════
KNOWN WORKAROUNDS — don't relearn the hard way
═══════════════════════════════════════════════════════════════════════

1. Sub-agent Write to `detector-review/trials/` is often denied by a
   system-reminder ("Do NOT Write report/summary/findings/analysis
   .md files"). Capture the agent's inline output and write to disk
   yourself — proven workaround.

2. Do NOT include the literal canonical prompt-override marker
   phrase verbatim in any file write — live `prompt-guard.sh`
   bash-fallback blocks it. Paraphrase ("canonical override-marker
   phrase") if you need to reference it.

3. Labs must stay under `<repo>/.lab/`. Don't move to `C:/temp` —
   sub-agents can't read there.

4. The framework-auditor's own circuit-breaker may fire at 400 tool
   calls on deep audits. Pause cleanly, persist state, don't push
   past — this is the framework's safety mechanism working as designed.

═══════════════════════════════════════════════════════════════════════
SAFETY
═══════════════════════════════════════════════════════════════════════

If the orchestrator-level circuit-breaker fires mid-campaign, pause
cleanly, persist state on disk, summarize, stop. Don't push past it.

═══════════════════════════════════════════════════════════════════════
KEY FACTS YOU'RE INHERITING
═══════════════════════════════════════════════════════════════════════

Phase-B-α exploration (run in the prior session) produced the raw map.
You can re-verify but do not need to re-execute:

- **Infrastructure is already strong.** `framework/hooks/tool-event-logger.sh`
  is `PostToolUse` matcher `*` (universal) — every tool call is captured
  to `.apex/event-log.jsonl` with full `tool_input` + `tool_response` +
  `is_error`. That's the data layer foundation.
- **One agent already uses it correctly.** `critic.md` STEP 1.6/1.7
  reads the event-log, builds a CORPUS of tool inputs+responses, and
  FAILs the executor with `phantom_data_value` when a cited value
  isn't in the corpus. **That's the pattern Campaign B generalises.**
- **7 data-layer gaps; GAP-1 is critical.** Sub-agent transcripts don't
  aggregate back to the parent project — child's `.apex/event-log.jsonl`
  lives in `~/.claude/projects/<sub-project>/`, parent never reads it.
  **This is the root mechanism of F-204-013** (R23's auditor ran as a
  sub-agent; its trace was inaccessible to R24's round-checker; the "6
  hits" claim was uncheckable). Phase B2.1 closes GAP-1.
- **5 high-leverage consumer-layer trust points:** critic STEP 2 (TP-1),
  round-checker full re-probe (TP-2 — upgrades Campaign A's CR-04 from
  sample to full coverage), verifier independent git diff (TP-3),
  executor STEP 0.5 escalation (TP-4), framework-auditor Axis 10
  procedural (TP-5).
- **3 new files in `framework/`** — schema JSON, event-log-rotate hook,
  test-audit-trail-layer.sh. Everything else is additive prose to
  existing files. **Rigor lives in the campaign, not in framework bloat.**
- **Owner pre-approval is granted IN THIS PROMPT** for the small
  `apex-spec.md` addition Campaign B requires (one paragraph describing
  the audit-trail standard). Proceed in Phase B6 without further
  confirmation.

═══════════════════════════════════════════════════════════════════════
ARTIFACTS YOU CONSULT — and the new directory you'll create
═══════════════════════════════════════════════════════════════════════

**Already on disk (Campaign A products):**
- `detector-review/CAMPAIGN-B-PLAN.md` — **the plan to execute.** Sections
  B-1 through B-12. Authoritative.
- `detector-review/BASELINE.md` — Campaign A's Phase-2 baseline. The
  3/13 ↔ 13/13 variance proof. The pattern Campaign B targets.
- `detector-review/ROOT-CAUSE.md` — Campaign A's 8 CRs (already
  closed). TP-2 of Campaign B is the upgrade of CR-04.
- `detector-review/FINAL-CERTIFICATION.md` — Campaign A's §9 outcomes.
  Read for context on what limits Campaign A left and what Campaign B
  must NOT regress.
- `detector-review/manifests/WORKING-CORPUS.md` + `HELDOUT-CORPUS.md.sealed`
  — Campaign A's mutation corpus. **Campaign B re-uses both.** Held-out
  was already opened in Campaign A's Phase 6; it stays the held-out
  set for B5.
- `framework/docs/DETECTION-STANDARD.md` — Campaign A's institutionalised
  standard. Campaign B builds on it.

**You create:**
- `audit-trail-review/EXPERIMENT-PROTOCOL.md` — frozen pre-registration
  (Phase B0).
- `audit-trail-review/TRUST-POINTS.md` — TP register (Phase B1).
- `audit-trail-review/FIX-DESIGN.md` — coverage matrix + per-TP design
  (Phase B3).
- `audit-trail-review/FINAL-CERTIFICATION.md` — before/after variance
  (Phase B5).
- `audit-trail-review/trials/*` — re-certification trial outputs
  (Phase B5).
- `framework/schemas/EVENT-LOG-ENTRY.schema.json` (Phase B2.2 — new).
- `framework/hooks/event-log-rotate.sh` (Phase B2.3 — new).
- `framework/tests/test-audit-trail-layer.sh` (Phase B2 — new).
- `framework/docs/AUDIT-TRAIL-STANDARD.md` (Phase B6 — new).

═══════════════════════════════════════════════════════════════════════
BEGIN
═══════════════════════════════════════════════════════════════════════

תתחיל **Phase B0** (pre-registration). Read `detector-review/CAMPAIGN-B-PLAN.md`
in full first, then the 6 inherited artifacts. Then author
`audit-trail-review/EXPERIMENT-PROTOCOL.md` with the 8 sub-deliverables
specified in the PHASE B0 section above. **Freeze it before any code
lands.** When Gate B0 is met, proceed to B1 → B2 → B3 → B4 → B5 → B6
end-to-end without stopping.

Bypass mode is on at project level (no approval prompts). The owner is
on mobile and is not watching the keyboard approve. **Quality first;
speed second; never silence a limitation. If a Gate cannot be honestly
met — document the L-N limitation + reserve an R-N item, mirror Campaign
A's pattern.** Just work.
