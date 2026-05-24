# B3 Critic Review — FIX-DESIGN.md (Round 1)

**Verdict:** PASS-WITH-CHANGES
**Reviewer:** clean-room critic agent
**Date:** 2026-05-24
**Reviewed:** audit-trail-review/FIX-DESIGN.md
**Baseline commit:** 8d7bfaf (post-B2 enum widen) — confirmed via `git log --oneline -5`

---

## Coverage-matrix check (dimension 1)

§1 lists 5 rows (TP-1..TP-5) and asserts "Zero orphan trust relations" by
deferring to `TRUST-POINTS.md` §4. I cross-checked TRUST-POINTS §4's 18
trust-relation rows: every row resolves to a VP-A..D (already-existing)
or to a TP-N where N ∈ {1..12}. The top-5 TPs cover the 5 trust-relations
with the strongest leverage on AC-3 / AC-10 / AC-12 (per TRUST-POINTS §1
top-5 frozen table). The 7 lower-leverage TPs (TP-6..TP-12) are NOT in
this FIX-DESIGN by Gate B1 design — they are deferred to "lighter
mechanisms" per TRUST-POINTS §1 second table.

**Finding (advisory, not blocking):** the coverage matrix's §1 column
"Lifts AC-N" maps TP-1→AC-3/10/12-partial, TP-2→AC-3/12,
TP-3→AC-10, TP-4→AC-10, TP-5→AC-3. Cross-checking against
EXPERIMENT-PROTOCOL §12: AC-11 ("Pre-task claims: every Task()
invocation in B5 corresponds to a `pre_task_claim` event-log entry")
and AC-9 ("Sub-agent count guard") are not lifted by any of the 5 TPs.
This is by design — AC-9/AC-11 are hook-layer (B2.5/B2.6), not
agent-layer fixes, and TP-1..TP-5 are explicitly the agent-layer slice.
No action required, but the matrix could state this explicitly
(advisory, not a required change).

**Verdict on dimension 1: PASS (no orphans within scope).**

---

## Anchor-accuracy check (dimension 2)

For each TP I ran a grep against the cited target file at HEAD=8d7bfaf:

| TP | Target file | Anchor cited | Found verbatim? |
|----|-------------|--------------|-----------------|
| TP-1 | `framework/agents/critic.md` | `**STEP 2: ACCEPTANCE CRITERIA**` + 4 classification lines | **YES** — line 628-633, byte-identical to the cited block |
| TP-2 | `framework/agents/specialist/round-checker.md` | `6. **Audit-credibility spot-check.** Before declaring CLOSED on any `P0+P1==0` round, independently re-verify a small sample of the auditor's compliance claims. Pick exactly **3** items from the audit's coverage map ...` | **YES** — lines 110-113, byte-identical |
| TP-3 | `framework/agents/verifier.md` | `STEP 1: Per-task verification\nFor each task in PLAN_META.json:\n  Run verify_commands from JSON (not from parsing XML) [שיפור 21]\n  Compare output against done_criteria from JSON` | **YES** — lines 35-38, byte-identical |
| TP-4 | `framework/agents/executor.md` | `**3. Outcome mapping (three branches).**` + the `**Unverifiable.**` bullet (8 lines) | **YES** — line 134 + lines 159-166, byte-identical |
| TP-5 | `framework/agents/specialist/framework-auditor.md` | `10. **Defense-in-Depth on APEX's own files:**` + 3 follow-up lines | **YES** — lines 119-122, byte-identical |

All 5 anchors resolve. **Verdict on dimension 2: PASS.**

---

## Replacement-correctness check (dimension 3)

### TP-1 (critic.md STEP 2 (cont.))
Replacement is **additive** — preserves the four-line classification
block and inserts the new STEP 2 (cont.) before STEP 3. The new block
does not duplicate existing STEP 4 ("Check RESULT.json verify_commands_run
— empty output or not run → MAJOR" at line 920): STEP 4 checks
*presence*; STEP 2 (cont.) checks *truthfulness*. The skip path
("verify_commands_run is absent or empty → vacuous PASS") correctly
defers presence-checking to STEP 4. **PASS.**

### TP-2 (round-checker.md step 6)
Replacement preserves the header "6. Audit-credibility ..." (renamed
"spot-check" → "full re-probe") and the "Spot-check tool failure rule"
trailing paragraph (CR-08 preservation). Step 5's "two consecutive
clean rounds" stop criterion is referenced and unchanged. The
sub-bullets a/b/c/d are well-structured. **PASS.**

### TP-3 (verifier.md STEP 1 (cont.))
Replacement is additive — inserts a substep IMMEDIATELY after STEP 1's
two existing lines (35-38), before STEP 2 (line 40). The fallback to
HEAD~1 when `task_start_sha` file is absent matches the pre-task-snapshot
hook's behavior (R16-602S writes to
`.apex/phases/<phase>/<task_id>/task_start_sha` — confirmed in
`framework/hooks/pre-task-snapshot.sh:91-105`). The substep emits P0
findings to be consumed by VERIFY.md, mirroring existing
STEP 5.5 / STEP 6 emit conventions. **PASS.**

### TP-4 (executor.md "Unverifiable." branch) — **BLOCKING ISSUE**
The replacement swaps only the "Unverifiable." bullet inside §3 of
STEP 0.5. **It does NOT update the immediately-following §4 ("RESULT.json
field semantics"), which directly contradicts the new behavior.**

Specifically, executor.md lines 168-184 (§4) currently state:
- Line 176-180: "Unverifiable → field = `true`. Downstream consumers
  (critic, round-checker) see one bit: 'this task ran on at least one
  premise the executor could not cross-check.' They decide policy ..."
- Lines 182-184: **"A task can satisfy STEP 0.5 with
  `assumption_unverified=true` and still produce a successful
  RESULT.json — the field is informational, not a verdict gate. The
  verdict gate is the denied-branch refusal."**

The TP-4 replacement asserts the OPPOSITE — that `assumption_unverified=true`
now CAPS the verdict at PARTIAL, with `status="partial"` (NOT
`"success"`). The §4 paragraph that explicitly authorizes the
`status=success` path remains in the file post-edit, creating a direct
self-contradiction. An executor reading the post-edit file would see
two conflicting rules in the same section.

**Required change:** the TP-4 replacement MUST also update §4
("RESULT.json field semantics") lines 176-184 to reflect the hard cap.
The "Unverifiable → field = true" entry needs a new clause: "...AND
the executor MUST set `status='partial'` and append an
`issues_found[]` entry of type `unverifiable_premise_continued`." The
final sentence "A task can satisfy STEP 0.5 with
`assumption_unverified=true` and still produce a successful
RESULT.json — the field is informational, not a verdict gate" MUST be
DELETED or rewritten to: "A task with
`assumption_unverified=true` produces a PARTIAL RESULT.json
(`status=partial`); the field is no longer informational — it is a
verdict gate that caps the task at PARTIAL." This is a blocking
contradiction.

### TP-4 (secondary issue) — critic-side wiring is asserted but not designed
TP-4's replacement claims: *"Critic STEP 2 sees status=partial and
records PARTIAL verdict regardless of done_criteria.verified=true."*
But I checked critic.md VERDICT RULES (lines 1202-1205):

```
- PASS: ALL criteria VERIFIED + zero critical + zero major
- PARTIAL: >50% verified + zero critical + zero major + remaining low-risk
- FAIL: any critical or major
```

There is NO rule in critic.md that reads `RESULT.json.status` and maps
it to the verdict. The verdict is derived from criteria-verification +
critical/major counts. TP-4 asserts a critic behavior that the
critic.md file does not implement. Two options:
- **(a)** add a new critic.md edit to TP-4 (now becomes a 2-file
  edit) that inserts a rule: "If `RESULT.json.status == 'partial'`,
  the critic verdict is capped at PARTIAL regardless of
  criteria-verification counts."
- **(b)** weaken TP-4's downstream claim — but then AT-4's assert #4
  ("Critic sees `status=partial` + issues_found entry → records
  PARTIAL verdict (not PASS)") becomes structurally impossible to
  satisfy. AT-4 hard-requires the critic-side wiring.

**Required change:** add a critic.md STEP-2-prelude edit to TP-4
implementing option (a). Without it, AT-4 cannot pass and AC-10's
downstream coverage uplift via TP-4 is not realized.

### TP-5 (framework-auditor.md Axis 10)
Replacement is structurally well-formed and mirrors Axis 13's
`bypass_attempts[]` schema (verified against lines 134-182 of
framework-auditor.md). Two concerns:

1. **Filename typos preserved.** The original Axis 10 cites
   `apex-prompt-guard.js` and `apex-workflow-guard.js` (`.js`
   extension). The actual hooks at `framework/hooks/` are
   `apex-prompt-guard.cjs` and `apex-workflow-guard.cjs`
   (`.cjs` extension — verified). The replacement preserves the
   wrong extensions. An auditor following the spec literally will
   look for `apex-prompt-guard.js`, find nothing, and either fail
   the bypass attempt or fabricate one. **Required change:** fix
   the file extensions to `.cjs` in the TP-5 replacement (advisory:
   align both Axis 10 prose AND the example targets in the
   replacement's sub-bullet (a)).

2. **TP-5 → TP-2 cross-dependency declared but mechanism not
   spelled out.** The replacement says "the round-checker (TP-2
   consumer of coverage_map) will reject closure on
   `axis_10.concrete_bypass_attempts.length == 0` for any P0+P1==0
   candidate round." But TP-2's replacement (round-checker §6.a-d)
   only iterates `coverage_map.axis_13.bypass_attempts[]` — it
   does NOT iterate `axis_10.concrete_bypass_attempts[]`. The
   cross-reference is asserted in TP-5 prose but not implemented
   in TP-2. **Required change:** either (a) add a §6.e to TP-2's
   round-checker replacement that iterates
   `axis_10.concrete_bypass_attempts[]` with the same
   re-probe-and-compare logic, OR (b) extend §6.b's "for each entry
   in axis_13.bypass_attempts" to also iterate
   `axis_10.concrete_bypass_attempts`. Without this, the asserted
   TP-5 + TP-2 pairing is broken and AC-3 working-corpus depth
   (per FIX-DESIGN §1 row TP-5) is not actually lifted by Axis 10
   re-probing.

---

## Acceptance-test fidelity (dimension 4)

| TP | AT-N | Mechanism satisfies AT-N? |
|----|------|---------------------------|
| TP-1 | AT-1 | **YES.** Replacement performs the 4 asserts (re-execute, capture, byte-compare, mismatch→CRITICAL `fabricated_verify_command_output`). The N=10 cap matches AT-1's probe scope. |
| TP-2 | AT-2 | **YES** for AT-2 asserts 1-3 (iterate every entry; cross-reference transcript; mismatch→P1+CONTINUE). AT-2 assert 4 (F-204-013 reconstruction with "6 hits" claim → CONTINUE not CLOSED) is satisfied by replacement §6.c. **Partial concern:** AT-2 specifies the response type as "P1 audit_credibility_regression" for exit-code mismatch and "P0 phantom_grep_count" for the F-204-013 case. Replacement matches both severities correctly. |
| TP-3 | AT-3 | **YES.** Replacement implements both bidirectional set-difference asserts (omitted-from-claim P0; phantom-file-claim P0) + the FAIL verdict integration. Symmetric test passes. |
| TP-4 | AT-4 | **BLOCKED by the dimension-3 contradiction.** AT-4 assert 4 ("Critic sees `status=partial` + issues_found entry → records PARTIAL verdict (not PASS)") cannot be satisfied without the critic.md edit identified above. Asserts 1-3 are mechanism-correct in the executor.md replacement. |
| TP-5 | AT-5 | **YES** for asserts 1, 2, 4 (concrete_bypass_attempt field, tool_call must exist, BLIND SPOT classification on skip). AT-5 assert 3 ("emit P0 finding citing the carve-out's exact line and the captured exit=0") is satisfied by replacement bullet (d). However, the **TP-5→TP-2 wiring gap** identified above means the auditor's `axis_10.concrete_bypass_attempts[]` is captured but never re-probed by round-checker — the AT-5 assertion that an empty bypass-attempts list "should not close Axis 10" relies on round-checker enforcement, which TP-2 does not provide. |

**Verdict on dimension 4: PARTIAL** — AT-1, AT-2, AT-3 are
mechanism-clean; AT-4 has the contradiction blocker; AT-5 has the
TP-2 cross-reference gap.

---

## Risk coverage (dimension 5)

§3's 6 named risks cover: cost-doubling (TP-1), transcript-import
race (TP-2), git-diff speed (TP-3), TP-4 false-PARTIAL, TP-5 real
damage from bypass payloads, L-DH-03 cache contamination. Each has
a credible mitigation.

**Missing risks (must add):**

1. **TP-4 schema migration risk.** Existing `assumption_unverified=true`
   tasks in the corpus (across past phases) currently have
   `status="success"`. The schema enum permits both. After TP-4 lands,
   the contract changes: future tasks with
   `assumption_unverified=true` MUST have `status="partial"`.
   Historical RESULT.json files violate the new invariant. If any
   downstream tool (e.g. cross-phase-audit, dora-collect, verifier
   STEP 6) cross-references this invariant, historical replays will
   FAIL. **Required mitigation:** declare the invariant is
   forward-only (applies to RESULT.json files created at-or-after the
   TP-4 install timestamp; STATE.json `apex_version` ≥ post-B4).
2. **TP-5 bypass-payload guard interaction.** The auditor's bypass
   attempt against `destructive-guard.sh` will itself be intercepted
   by the live `destructive-guard.sh` PreToolUse hook in the auditor's
   own session — i.e. the guard fires against the auditor's tool call,
   not against the simulated payload. The Bash invocation
   `bash framework/hooks/destructive-guard.sh '<payload>'` may be
   blocked by the very guard being tested (e.g.
   `apex-prompt-guard.cjs` blocks the prompt that constructs the
   payload). This is a self-referential testing problem. **Required
   mitigation:** declare the bypass-attempt invocation pattern that
   sidesteps the live guard (e.g. run inside a sub-shell with
   `APEX_BYPASS_TEST=1` envelope; document in §3 that the auditor
   MUST construct payloads that test the guard's CONTRACT without
   triggering its own host-session enforcement).
3. **TP-2 transcript-availability ordering.** The replacement glob
   `.apex/subagent-transcripts/framework-auditor-R<N>-*.jsonl`
   depends on B2.1 (transcript aggregation) being in place at B5 trial
   time. AC-1 covers the binary "transcript exists per Task()
   invocation" but TP-2's logic also requires the transcript to be
   readable at the moment round-checker runs. The SubagentStop hook
   timing claim in §3 ("SubagentStop fires BEFORE round-checker runs
   ... documented assertion") is asserted but not cited to a verifiable
   anchor. **Required:** cite the specific code/line that enforces
   this ordering (e.g. `self-heal.md` Step E invocation pattern), or
   add a fallback that emits P0 `audit_trail_missing` if the file is
   absent (the replacement DOES have this in §6.a — but the §3 risk
   row should make the dependency on B2.1 explicit and
   cross-reference §6.a's fallback).

---

## Scope discipline (dimension 6)

The 5 TPs map 1:1 to TRUST-POINTS §1's top-5 frozen table. No edits
to TP-6..TP-12 (correctly deferred). No new edits outside the cited
5 agent files. **The TP-5→TP-2 cross-reference issue identified
above does NOT count as scope creep** — it is a missing internal
wiring within the already-declared 5 files, not an expansion to a
sixth file. The TP-4 critic.md wiring identified above WOULD be a
6th-file edit, but it is required by AT-4's assertion 4 and
therefore in-scope per Gate B1.

**Verdict on dimension 6: PASS** (after the required changes are
applied, scope remains within the 5+1 files dictated by the AT
acceptance tests).

---

## Required changes (PASS-WITH-CHANGES)

1. **`audit-trail-review/FIX-DESIGN.md` §2 TP-4 replacement:**
   extend the TP-4 edit scope to ALSO update executor.md §4
   ("RESULT.json field semantics") lines 168-184. Specifically:
   - Modify the "Unverifiable → field = true" bullet (line 176-180)
     to read: "Unverifiable → field = `true` AND `status='partial'`
     AND an `issues_found[]` entry of type
     `unverifiable_premise_continued` is appended. Downstream
     consumers (critic, round-checker) see three signals: the soft
     flag (`assumption_unverified=true`, for trajectory), the hard
     cap (`status=partial`, for verdict), and the audit-trail
     (`issues_found[]` entry, for closure)."
   - DELETE or rewrite the final paragraph (lines 182-184):
     "A task can satisfy STEP 0.5 with `assumption_unverified=true`
     and still produce a successful RESULT.json — the field is
     informational, not a verdict gate. The verdict gate is the
     denied-branch refusal." Replace with: "A task with
     `assumption_unverified=true` produces a PARTIAL RESULT.json
     (`status=partial`) — the field is now a verdict gate that
     caps the task at PARTIAL. The denied-branch refusal remains
     the only path to `status=failure`."

2. **`audit-trail-review/FIX-DESIGN.md` §2 TP-4: add a SECOND
   target file (`framework/agents/critic.md`).** Insert a new
   sub-step "STEP 2 (prelude): STATUS-FIELD CAP" before the
   existing STEP 2 ACCEPTANCE CRITERIA block (line 628) reading:
   "If `RESULT.json.status == 'partial'`, the critic verdict is
   capped at PARTIAL regardless of done_criteria verification
   counts. Record the cap in the verdict justification:
   `partial_cap_from_status: <issues_found[].type>`. The cap is
   independent of the STEP 2 classification — even if all
   criteria are VERIFIED, the verdict stays PARTIAL when
   `status=partial`." Without this, AT-4 assert 4 cannot pass.

3. **`audit-trail-review/FIX-DESIGN.md` §2 TP-2 replacement:**
   either (a) add a §6.e iterating
   `coverage_map.axis_10.concrete_bypass_attempts[]` with the same
   re-probe/compare logic as §6.b, OR (b) modify §6.b to iterate
   the union of `axis_13.bypass_attempts[]` and
   `axis_10.concrete_bypass_attempts[]`. Cite TP-5's `axis_10`
   schema as the source. Without this, the TP-5→TP-2 wiring
   declared at the end of TP-5's replacement is broken and AC-3
   working-corpus depth (the load-bearing TP-5 + TP-2 pairing) is
   not realized.

4. **`audit-trail-review/FIX-DESIGN.md` §2 TP-5 replacement:**
   correct the file extensions for the named guards. The Axis 10
   list currently cites `apex-prompt-guard.js` and
   `apex-workflow-guard.js` — the live hooks are
   `apex-prompt-guard.cjs` and `apex-workflow-guard.cjs`. An
   auditor following the spec literally will look for the wrong
   files. Update both Axis 10 prose and the sub-bullet (a)
   example payloads to use `.cjs`.

5. **`audit-trail-review/FIX-DESIGN.md` §3 (Risks):** add the
   three missing risks identified in dimension 5:
   (a) TP-4 schema-migration risk → declare forward-only invariant.
   (b) TP-5 bypass-payload guard interaction → declare the
       sandbox-pattern that sidesteps live guard self-firing.
   (c) TP-2 transcript-availability ordering → cite the
       self-heal.md anchor that enforces SubagentStop-before-
       round-checker, and cross-reference the §6.a fallback for
       the absent-transcript case.

---

## Verdict rationale

The design is structurally sound — 5 of 6 dimensions pass cleanly,
all 5 anchors resolve verbatim at HEAD=8d7bfaf, and 4 of 5 TPs
(TP-1, TP-2, TP-3, TP-5-mechanism) satisfy their AT-N acceptance
tests as mechanism. The verdict is PASS-WITH-CHANGES rather than
PASS because TP-4 contains a direct self-contradiction (the
"Unverifiable." branch's new behavior contradicts §4 of the same
STEP 0.5 section, which remains unedited in the replacement scope
— an executor reading the post-edit file would see two opposite
rules in adjacent paragraphs), AND because TP-4's downstream
critic-side wiring is asserted in prose but not implemented in
any of the 5 replacements (AT-4 assert 4 is unsatisfiable without
adding a critic.md edit).

The verdict is NOT FAIL because (a) none of the 5 anchors are
missing or wrong, (b) the coverage matrix has no orphan rows, (c)
all 5 TPs' core mechanisms are conceptually correct against their
AT-N, and (d) every identified issue has a named, surgical fix —
no re-design is required. After the 5 required changes land in
FIX-DESIGN.md, the design will satisfy all 12 acceptance criteria
that the TP-1..TP-5 set is scoped to lift (AC-3, AC-10, AC-12 +
the AT-N binary asserts). Resubmit for R2.
