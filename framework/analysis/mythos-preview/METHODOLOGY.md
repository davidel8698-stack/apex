# Mythos IMP Analysis Methodology

> **Authority document.** All ecosystem-aware analysis of Mythos IMPs (improvement
> proposals derived from the Mythos Preview System Card) MUST follow this
> methodology. No IMP enters an implementation schedule without passing the
> Ready-for-Scheduling Gate defined below.

---

## Why this exists

The original analysis in [`APEX-IMPROVEMENTS.md`](APEX-IMPROVEMENTS.md) produced
76 IMPs with a "tunnel-vision" template: each IMP listed only `files-affected`
and `proposed-change`. That template ignores ecosystem ripple effects.

APEX is a multi-component system: 11 agents, 49 hooks, 45 commands, 7 JSON
schemas, 62 tests. A change to one component touches others. Applying 76 fixes
without ecosystem analysis would fracture the harmony between components.

**This methodology forces every IMP to answer 10 ecosystem questions before it
qualifies for implementation.** The questions are identical to those already
defined in [`framework/agents/specialist/remediation-planner.md`](../../agents/specialist/remediation-planner.md)
lines 84-95 (which was built for internal audit findings). We reuse them
verbatim for Mythos IMPs — no new agent, no parallel methodology.

---

## Authority chain

- **Source of truth for the 10 questions:** `framework/agents/specialist/remediation-planner.md`, section "Ecosystem analysis — 10 mandatory questions".
- **Source of truth for IMP catalog:** [`APEX-IMPROVEMENTS.md`](APEX-IMPROVEMENTS.md) — immutable.
- **Source of truth for IMP status:** [`IMP-INDEX.md`](IMP-INDEX.md) — updated as IMPs are analyzed.
- **Source of truth for ecosystem ripple:** [`ECOSYSTEM-IMPACT.md`](ECOSYSTEM-IMPACT.md) — one row per analyzed IMP.
- **Per-IMP analysis files:** `imps/IMP-NNN.md` — created only when an IMP is analyzed.

---

## The 10 mandatory questions

Every per-IMP file MUST answer all ten, in this order, in Hebrew or English
(consistent within the document). Skipping a question disqualifies the IMP.

1. **מטרת הרחיב** / Purpose of the component — What role does the component
   that this IMP touches play in APEX?
2. **למה דווקא כאן** / Why here (architectural justification) — Why is the
   component located where it is and not elsewhere?
3. **מה לא תקין כרגע** / Current malfunction — Stated as fact, not
   interpretation. Quote evidence from Mythos.
4. **שורש הבעיה** / Root cause — Design flaw / missing enforcement / silent
   fallback / human factors / etc.
5. **המצב האידיאלי לפי הספק** / Ideal state per spec — What does
   [`apex-spec.md`](../../../apex-spec.md) (or Mythos as external authority) say
   the behavior should be?
6. **הדרך הנכונה לתיקון** / Correct fix approach — One or two sentences. The
   *minimal* correct fix, not the *complete* one.
7. **רכיבים מושפעים downstream** / Downstream components affected — Full list
   of files/modules/commands. Include test files that will need updates.
8. **שינויים חיוניים לפני התיקון** / Pre-fix changes required elsewhere —
   Ordered list. What MUST happen before this fix lands, to integrate
   harmoniously?
9. **אזורי do-not-touch** / Do-not-touch zones — List of files/areas that must
   not be touched + the reason for each, in prose. No line-range citations
   (per [`REMEDIATION-STYLE.md`](../../docs/REMEDIATION-STYLE.md)).
10. **תובנות לא צפויות** / Non-obvious insights — Hidden constraints, warnings,
    or counter-intuitive consequences to know before starting.

---

## Per-IMP file template

Save as `imps/IMP-NNN.md`. Copy this template verbatim.

````markdown
# IMP-NNN — <title>

**Priority:** P0 / P1 / P2 / P3
**Cluster:** critic / destructive-guard / executor / hooks-state / agents / schemas / commands / other
**Source anchor:** Mythos §X.X, page YYY — "<verbatim quote from PDF>"
**Source quote verified:** YES (re-fetched from `_sections/section-WN.md` on YYYY-MM-DD)
**Linked lessons:** L-XXX-YY, L-XXX-ZZ (from CROSS-REF.md)
**Spec impact:** none / amendment-required / new-section

## Ecosystem analysis — 10 שאלות חובה

1. **מטרת הרחיב:** ...
2. **למה דווקא כאן (הצדקה ארכיטקטונית):** ...
3. **מה לא תקין כרגע (עובדה, לא פרשנות):** ...
4. **שורש הבעיה:** ...
5. **המצב האידיאלי לפי הספק:** ...
6. **הדרך הנכונה לתיקון (משפט-שניים):** ...
7. **רכיבים מושפעים downstream:**
   - ...
   - ...
8. **שינויים חיוניים לפני התיקון:**
   1. ...
   2. ...
9. **אזורי do-not-touch:**
   - **`path/to/file`** — reason in prose
   - ...
10. **תובנות לא צפויות / אילוצים נסתרים:** ...

## Execution plan

- **Files to modify:** [exact path + content anchor for each]
- **Files to create:** [exact paths]
- **Files that MUST remain untouched:** [paths + preservation contract in prose]
- **Order of operations:**
  1. ...
  2. ...
- **Rollback trigger:** <measurable condition that mandates revert>

## Acceptance criteria (falsifiable, observable)

- [ ] Criterion 1: <observable, binary pass/fail, grep-verifiable>
- [ ] Criterion 2: ...
- [ ] Regression check: <which existing tests must still pass>
- [ ] Spec re-check: <how to verify the gap is now covered>

## Dependencies

- **Blocks:** [IMP-IDs that must finish before this one]
- **Blocked by:** [IMP-IDs that this one blocks]
- **Conflicts with:** [IMP-IDs touching the same files — write conflict]

## Risk assessment

- **Blast radius:** low / medium / high
- **Reversibility:** trivial / moderate / difficult
- **Confidence in fix approach:** high / medium / low
- **Requires human decision:** YES / NO (if YES — explain the question)
````

---

## Ready-for-Scheduling Gate

An IMP is **not eligible** to enter an implementation queue (`status: scheduled`
in `IMP-INDEX.md`) until ALL of these conditions hold:

1. All 10 questions are answered substantively in `imps/IMP-NNN.md`. Empty
   bullets or `TBD` placeholders disqualify.
2. `Source quote verified: YES` — the Mythos quote has been re-fetched from
   `_sections/section-WN.md` (or, if available, from the original PDF). Do not
   trust the original APEX-IMPROVEMENTS.md citation alone.
3. A complete row exists in `ECOSYSTEM-IMPACT.md` matching the IMP's answers
   to questions 7, 8, 9, and the conflicts list.
4. Every prerequisite in question 8 either (a) has already been implemented,
   or (b) is itself an analyzed IMP listed in `Blocks` of the dependency
   section.
5. Every conflict in `Conflicts with` has a resolution plan (serialization
   order or merger).
6. `Confidence in fix approach ≠ low`, AND `Requires human decision = NO`.
   If either fails, the IMP is parked at `status: needs-human-decision`.

Until the gate passes, the IMP stays at `status: analyzed` in
`IMP-INDEX.md` — never `scheduled`.

---

## Status lifecycle (for `IMP-INDEX.md`)

- `pending` — not yet analyzed. Default state for all 76 IMPs.
- `analyzing` — analysis in progress (someone is writing `imps/IMP-NNN.md`).
- `analyzed` — all 10 questions answered, awaiting gate check.
- `needs-human-decision` — gate fails on confidence or human-decision flag.
- `blocked` — gate fails on unresolved prerequisites/conflicts.
- `scheduled` — gate passed, queued for implementation.
- `in-progress` — implementation underway.
- `done` — implemented, verified, merged.
- `wontfix` — analyzed and explicitly rejected (record reason in the IMP file).

---

## Processing order (cluster-first, P0-within-cluster)

Do **not** process all 76 IMPs at once. Do **not** process by priority alone.
Process by ecosystem cluster:

1. **critic-cluster** — IMPs whose primary affected file is `framework/agents/critic.md`. Densest cluster (35% of lessons).
2. **destructive-guard-cluster** — `framework/hooks/destructive-guard.sh`.
3. **executor-cluster** — `framework/agents/executor.md` + `RESULT.schema.json`.
4. **hooks-state-cluster** — `state-rebuild.sh`, `_tokens-update.sh`, `context-monitor.sh`, `STATE.schema.json`.
5. **remaining clusters** — by descending IMP density.

Within a cluster: P0 first, then P1, then P2/P3 if the IMPs still seem
worthwhile after the cluster ecosystem picture is clear.

**Rationale:** Processing P0-first across all 8 P0s would force re-analysis of
`critic.md`'s ecosystem four times (4 of 8 P0s touch critic). Cluster-first
analyzes each component's ecosystem once.

---

## What this methodology explicitly does NOT do

- Does NOT modify [`APEX-IMPROVEMENTS.md`](APEX-IMPROVEMENTS.md). The catalog is
  the immutable historical record.
- Does NOT create a new agent. Reuses
  [`framework/agents/specialist/remediation-planner.md`](../../agents/specialist/remediation-planner.md).
- Does NOT introduce a new JSON schema. Markdown per IMP is sufficient.
- Does NOT promise that every IMP will be implemented. Some will be
  `wontfix` after analysis reveals the cost outweighs the benefit.
- Does NOT begin implementation before the first full cluster is analyzed and
  its partial DAG is validated.
