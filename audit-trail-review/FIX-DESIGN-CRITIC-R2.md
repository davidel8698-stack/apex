# B3 Critic Review — FIX-DESIGN.md (Round 2)

**Verdict:** PASS
**Reviewer:** clean-room critic agent (continuation of R1)
**Date:** 2026-05-24
**Reviewed:** audit-trail-review/FIX-DESIGN.md (revised post-R1)
**Baseline commit:** 8d7bfaf

---

## R1 finding closure verification

### R1.1 — TP-4 §4 contradiction
**Status:** CLOSED
**Evidence:** FIX-DESIGN.md §2 TP-4.a now contains a SECOND sub-section
("TP-4.a (cont.) — executor.md §4 'RESULT.json field semantics'
rewrite", lines 293-363). The anchor cites the verbatim original §4
paragraph including the offending sentence "A task can satisfy STEP
0.5 with `assumption_unverified=true` and still produce a successful
RESULT.json — the field is informational, not a verdict gate". The
replacement (lines 325-363) explicitly inverts the rule: "A task with
`assumption_unverified=true` produces a PARTIAL RESULT.json
(`status=partial`) — the field is now a verdict gate that caps the
task at PARTIAL" and "The `success` value is reachable only on the
Confirmed branch". The full-paragraph swap (not insert) ensures the
contradicting prose is REMOVED, not just shadowed by adjacent new
prose. The R1.1 self-contradiction is structurally eliminated.

### R1.2 — TP-4 missing critic edit
**Status:** CLOSED
**Evidence:** FIX-DESIGN.md §2 now contains TP-4.b (lines 365-414):
"critic.md STEP 2 status-cap prelude". The anchor (lines 376-382)
cites critic.md's STEP 2 ACCEPTANCE CRITERIA block verbatim; the
replacement inserts a NEW prelude IMMEDIATELY BEFORE that header
(lines 388-414) that reads "If `RESULT.json.status == 'partial'`,
the critic verdict is **capped at PARTIAL** regardless of
done_criteria verification counts and regardless of STEP 2 (cont.)
verify-command re-execution outcomes." The cap rules (only
downgrades; severe verdicts win) are spelled out. The §1 coverage
matrix TP-4 row is also updated to list `framework/agents/critic.md`
as a second target file. AT-4 assert 4 is now structurally
satisfiable: executor sets status=partial → critic prelude reads
status and caps verdict → PARTIAL emitted.

### R1.3 — TP-5→TP-2 axis_10 wiring gap
**Status:** CLOSED
**Evidence:** FIX-DESIGN.md §2 TP-2 §6.b (lines 129-148) now iterates
the **UNION** of `coverage_map.axis_13.bypass_attempts[]` and
`coverage_map.axis_10.concrete_bypass_attempts[]`, with the
`{axis ∈ {10, 13}}` field added to the emitted P1 finding. The same
re-probe/compare logic (transcript lookup → exit-code comparison →
mismatch emits P1 `audit_credibility_regression`) applies to both
arrays. Additionally, §6.b adds an empty-axis_10 P1 guard
(`axis_10_blind_spot` + posture `clean-pending-spot-check`) so a
candidate round with zero axis_10 entries cannot close. The §1
coverage matrix TP-2 row is updated to declare the union iteration
explicitly. The cross-reference TP-5 declares ("Round-checker TP-2
§6.b iterates this array — wiring is closed") now matches reality.

### R1.4 — TP-5 filename typos
**Status:** CLOSED
**Evidence:** Live hooks verified by `ls framework/hooks/`:
`apex-prompt-guard.cjs` and `apex-workflow-guard.cjs` (`.cjs`, not
`.js`). FIX-DESIGN.md grep shows: lines 433-434 are inside the
PRE-edit anchor (showing the file's current wrong text — necessary
for the anchor to be greppable), lines 440 is the critic-finding
citation note acknowledging the typo, and lines 449-450 + 478 are
the NEW REPLACEMENT text using `.cjs` correctly. The replacement
prose ("`apex-prompt-guard.cjs`, Path Traversal Prevention,
`apex-workflow-guard.cjs`") and the sub-bullet (a) example
(`apex-prompt-guard.cjs: envelope with...`) both use correct
extensions. R1.4 closed.

### R1.5 — §3 missing 3 risks
**Status:** CLOSED (all 3 sub-items)

- **R1.5.a (TP-4 schema migration / forward-only invariant):**
  CLOSED. §3 row (line 530) declares the forward-only invariant
  with explicit gating on `STATE.json apex_version ≥ post-B4` and
  reserves Phase-7 R-AT-P7-03 for retroactive policy. Additionally
  TP-4.a §4 replacement (lines 355-362) contains a dedicated
  "**Forward-only invariant**" paragraph so the rule is normative
  in the agent file itself, not only in the risk table.

- **R1.5.b (TP-5 guard self-firing):** CLOSED. §3 row (line 531)
  mandates the `APEX_BYPASS_TEST=1` envelope variable pattern and
  notes guards "SHOULD honor this carve-out (B4 install step adds
  the env-var check to each named guard if absent)". TP-5 sub-bullet
  (b) (lines 482-490) operationalizes the pattern in the agent file:
  `(env APEX_BYPASS_TEST=1 bash <hook.sh>) <<<'<envelope>'`. The
  risk and its mitigation are wired through both §3 and the TP-5
  replacement.

- **R1.5.c (TP-2 transcript-ordering anchor):** CLOSED. §3 row
  (line 532) cites `framework/commands/apex/self-heal.md` Step E
  as the orchestration contract that enforces SubagentStop-before-
  round-checker. I verified the anchor: self-heal.md line 307
  ("### Step E — Closure check") and lines 339-340 (the
  `Task("round-checker", CLOSER_CONTEXT, ...)` invocation in
  Step E) exist at the cited path. The fallback for the
  absent-transcript case (P0 `audit_trail_missing` + CONTINUE) is
  cited and corroborated by TP-2 §6.a (lines 122-127).

---

## Newly-introduced issues (only if any)

**None blocking.** One advisory nit only:

- **Minor markdown formatting at FIX-DESIGN.md line 144.** The
  sub-bullet beginning "**Empty axis_10 with no entries on a
  P0+P1==0 candidate round" opens a bold marker (`**`) but the
  closing `**` is missing before "round". The intent is clear from
  context (it's a TP-2 §6.b sub-clause), and a renderer will simply
  treat the bold as un-closed for the rest of the bullet. This is
  cosmetic and does not affect any anchor-based diff/grep operation
  in B4 install — the bullet's substantive content
  (`axis_10_blind_spot` P1 + `clean-pending-spot-check` posture) is
  unambiguous. The author may fix in passing during B4 commit
  preparation; not blocking for B4 install per the R2 stricture
  ("nit the author can fix in R3" — but more efficient to fix
  inline during B4 staging).

No new contradictions, no new anchor-misses, no new orphan trust
relations, no scope expansion beyond the R1-required additions
(executor.md §4 paragraph swap + critic.md STEP 2 prelude — both
already authorized by R1.1/R1.2).

---

## Verdict rationale

All 5 R1 required-change items are CLOSED with verifiable evidence in
the revised FIX-DESIGN.md: the TP-4 self-contradiction is eliminated
via full §4 paragraph swap (R1.1); the critic-side wiring is added as
TP-4.b STEP 2 prelude with the §1 matrix updated to declare critic.md
as a second target file (R1.2); TP-2 §6.b now iterates the
axis_13 ∪ axis_10 union so the TP-5 cross-reference is honored
(R1.3); the live-hook `.cjs` extensions replace the typo'd `.js`
throughout the new replacement prose (R1.4); §3 carries all 3
previously-missing risks (schema migration / guard self-firing /
transcript ordering) with concrete mitigations cross-referenced into
the TP replacements themselves (R1.5). The one observed nit
(unclosed bold marker on FIX-DESIGN.md line 144) is cosmetic, does
not affect any anchor or installer behavior, and per the R2
gatekeeping stricture should not block B4. Verdict: **PASS** —
Campaign B may proceed to B4.
