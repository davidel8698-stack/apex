# Remediation Planning Style Guide

Authoring standard for `REMEDIATION-PLAN-R{N}.md` and `WAVES-R{N}.md`. Derived from a drift incident in R2: `REMEDIATION-PLAN-R2.md §R-007` referenced `next.md:312` and `316-338`, but by the time the fix reached execution those lines had shifted because Wave 1 concurrent edits moved the file. Raw `file:line` anchors are not stable across multi-wave execution. This doc records the rule that replaces them.

---

## Rule: Content-addressable anchors, not line numbers

When pointing to a location in the codebase from a plan document:

- **DO** use content anchors the reader can `grep` for:
  - Section headers: `## MODEL ROUTING HELPER`
  - Function / variable / identifier names: `resolve_model(`, `_state_update`
  - Unique phrases from the file: `"Mission Briefing (Section 10-B variant"`
  - Structural landmarks: `## TWO-TIER METHODOLOGY CHECK`
- **DO NOT** reference raw line numbers (`next.md:312`, `phase-tag.sh:48-52`) in plan bodies.

Line numbers are acceptable in two places only:
1. **Audit findings** (`apex-audit-findings-R{N}.md`) — frozen snapshots of a commit, never edited mid-execution.
2. **Execution log / commit messages** — post-hoc, tied to the concrete ref that was actually edited.

---

## Rule: File + anchor, not file + line

Instead of:
> **Files to modify:** `phase-tag.sh` (lines 48-52)

Write:
> **Files to modify:** `phase-tag.sh` — jq pipeline computing `lead_time_avg` inside the `DORA METRICS` block.

The executor grep-finds the anchor; the fix lands in the right place whether the block moved by 3 lines or 30.

---

## Rule: Preservation list uses patterns, not ranges

Instead of:
> **Do not touch:** `next.md:135-153`

Write:
> **Do not touch:** the gate behavior after the time-gate threshold fires (the block starting `STATE.session.last_time_gate = now` and ending with the three user options). Only the threshold comparison `If ELAPSED_MINUTES >=` may change.

The preservation contract survives unrelated Wave shifts in the same file.

---

## Rule: Conflict matrix uses files, not ranges

The R2 conflict matrix already does this correctly — it names files, not regions. Keep it that way. Intra-file serialization inside a wave is documented via anchor names in each R-item's "Order of operations."

---

## Rule: State-derived counts, not literal numbers

Instead of:
> "28 hook files in `framework/hooks/`"

Write:
> "All hook files currently in `framework/hooks/` (source-of-truth count: `ls framework/hooks/ | wc -l`)"

If a literal count appears in a plan, it must also appear in a test that re-validates the count at execution time. The R2 drift (28 vs 29) happened because the count was asserted in prose but not in code.

---

## Rule: Three-places contract for hook trigger changes

Any remediation that changes how a hook is triggered (explicit → auto-wired, or vice versa, or matcher change) must touch **all three** of:

1. The hook file itself — `# Hook type:` header comment.
2. `framework/settings.json` — the wiring entry.
3. `framework/HOOK-CLASSIFICATION.md` — the classification table.

Omitting any one produces drift (R2 omitted #1 for workflow-guard; R3 caught it).

---

## Rule: Sync-strategy review

Any remediation that adds a new hook, agent, or top-level `framework/` file must verify that `framework/scripts/sync-to-claude.sh` will actually deliver it to `~/.claude/`. If not, the remediation must include a sync-strategy update.

---

## Document structure (copy-paste skeleton)

```
## Remediation R-NNN

**Linked finding:** F-XXX (R{N}-F-YYY)
**Severity:** P{0..3}
**Spec anchor:** "exact phrase from apex-spec.md"

### Ecosystem analysis
1-10 questions (see R2 template).

### Execution plan
**Files to modify:** `<path>` — <content anchor>
**Files to create:** <path>
**Files that MUST remain untouched:** <path> — <preservation contract in prose>
**Order of operations:** named steps referencing content anchors.
**Rollback trigger:** observable condition.

### Acceptance criteria
- [ ] grep-verifiable predicates, not line-number checks.

### Dependencies
### Risk assessment
```

All five sections are mandatory. An R-item missing any section is rejected by the batch scheduler.

---

## Why this matters

The R{N} → R{N+1} audit loop is only healthy if remediation plans survive their own execution window. Raw line numbers age within hours; content anchors age on the order of file rewrites. The convergence trend in the audit is sensitive to how reliably fixes land where they were planned to land. This style guide is the mechanism that keeps that reliability high.
