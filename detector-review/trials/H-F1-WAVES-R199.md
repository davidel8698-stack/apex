# Wave Schedule — Round R199

**Source plan:** `detector-review/manifests/H-F1-input-plan.md`
**Spec anchor:** `apex-spec.md`
**R-IDs scheduled:** R-200, R-201, R-202, R-203, R-204 (5 of 5)
**Conflict matrix:** empty (per source plan)
**HUMAN DECISION REQUIRED items:** none
**WONTFIX / UNKNOWN items:** none

---

## Wave 1

**R-IDs:** [R-200, R-201, R-202, R-203, R-204]

**Rationale for grouping:**
All 5 approved R-items are fully ready (none require human decision; none
are WONTFIX/UNKNOWN), each carries high confidence and high reversibility,
and the source plan declares an **empty conflict matrix** across the entire
set. Each R-item touches a distinct file, has zero or near-zero blast
radius confined to its own file's surface, and is independently testable.
The wave contains exactly 5 R-IDs — within the 5–8-per-wave invariant —
so splitting them across multiple waves would only add latency without
buying any safety. R-203 is P0 but its declared blast radius is *narrow*
(restoration of a single deny line in `path-guard.sh`, with the main path
unchanged) and its reversibility is HIGH (single one-line revert); it
therefore does **not** meet the "P0 with high blast radius gets its own
wave" carve-out from split rule 1 and belongs in the same wave as the
other independent items.

**Independence proof:**
- File-level disjointness (no two R-items touch the same file):
  - R-200 -> a hypothetical README (doc-only)
  - R-201 -> one hook file (stderr prose only)
  - R-202 -> a *different* hook file (additive stderr diagnostic in an
    existing else branch; success path untouched)
  - R-203 -> `framework/hooks/path-guard.sh` (one-line deny restoration)
  - R-204 -> `framework/settings.json` (`_comment` key insertion)
- Conflict matrix from the source plan: empty — no pairwise conflicts
  across R-200..R-204.
- DAG edges among wave members: none. No R-item in this set produces an
  artifact, symbol, or file mutation consumed by another R-item in the
  set.
- Mutation-type disjointness: doc / stderr-prose / stderr-additive /
  deny-line-restore / settings-comment — five distinct surfaces.

**Estimated scope:**
- Files touched: 5 (one per R-item, all distinct).
- Modules impacted: docs (R-200), hooks (R-201, R-202, R-203),
  framework settings (R-204).
- Total edits: 5 single-Edit operations.

### Verification gate

- **Test suite:** full repo test suite (every `test-*.sh` under
  `framework/tests/`, including slow-tagged tests so the path-guard
  coverage is exercised end-to-end).
- **Smoke test:**
  - Invoke each touched hook in its nominal mode and confirm no
    regression on the success path.
  - Run the path-guard crafted-payload probe for R-203 and confirm exit
    code 2 with the block message.
  - Validate `framework/settings.json` parses cleanly with `jq .` after
    R-204.
- **Spec anchors re-checked:**
  - R-200 — `apex-spec.md` line 8 (doc-style principle).
  - R-201 — `apex-spec.md` "no jargon" core principle.
  - R-202 — `apex-spec.md` Fail-loud principle (~line 233).
  - R-203 — `apex-spec.md` defense-in-depth axis-10 (guard-hook anchor).
  - R-204 — `apex-spec.md` proof-of-process principle.
- **Regression check:**
  - Doc grep for the corrected R-200 string.
  - stderr grep for the new R-201 message.
  - stderr grep for the new R-202 diagnostic on the failure branch
    only; success-branch stderr unchanged.
  - Path-guard deny coverage diff before/after R-203: only the restored
    token's coverage changes; no other deny patterns added or removed.
  - `jq .` parse on `framework/settings.json` after R-204; deep-equal
    on all non-`_comment` keys before/after.

**Abort conditions:**
- Any pre-existing test transitions from PASS to FAIL on any touched
  module.
- R-203 crafted-payload probe fails to return exit 2 after the edit.
- `framework/settings.json` fails `jq .` parsing after R-204.
- Any hook's success path emits new stderr it did not emit before (for
  R-201/R-202).
- Any R-item's acceptance test from the source plan fails.
- On abort: revert the failing R-item's single Edit (all five are
  one-Edit, one-line, trivially reversible), retain the passing
  R-items, and escalate the failing R-ID to the next round's audit.

**Pre-requisites:**
- Approved `REMEDIATION-PLAN-R199.md` (the H-F1 input plan) present at
  the declared `plan_path`.
- `apex-spec.md` present at the declared `spec_path`.
- Clean working tree (or at minimum: no uncommitted edits to any of
  the 5 target files) before the wave starts.
- No prior wave required — this is Wave 1 of Round R199.

---

## Execution order

**Wave 1 only.**

Justification: the entire approved R-set (5 items) is mutually
independent (empty conflict matrix, disjoint files, no DAG edges) and
fits within the 5–8-per-wave invariant. No topological ordering across
waves is needed because there is exactly one wave. Within the wave, the
executor may apply the 5 Edits in any order; a recommended order
(lowest-risk first, P0 last so the full suite runs against it under
maximal context) is:

1. R-200 (P3, doc-only)
2. R-204 (P2, settings.json comment)
3. R-201 (P2, hook stderr prose)
4. R-202 (P1, hook stderr additive)
5. R-203 (P0, path-guard deny-line restore)

This ordering is advisory; the independence proof above guarantees that
any permutation is safe.

## Pending human decisions

None. The source plan declares "Requires human decision: NO" for all 5
R-items (R-200, R-201, R-202, R-203, R-204).

## Deferred

None. All 5 approved R-items are scheduled into Wave 1. No R-item is
deferred to a future round.

Rationale for the empty Deferred section: deferral under split rule 1
requires either (a) HUMAN DECISION REQUIRED status, (b) WONTFIX /
UNKNOWN status, (c) intra-wave conflict that cannot be resolved by
splitting, or (d) a P0 with **high** blast radius that would warrant
solo isolation *and* whose isolation does not fit the current wave
budget. None of these apply: every R-item is fully ready, the conflict
matrix is empty, and R-203's blast radius is explicitly narrow
("path-guard's deny coverage for the restored token; main path
unchanged") with HIGH reversibility. Parking R-203 in Deferred would
violate the termination criterion ("Every approved R- is placed in a
wave or explicitly marked deferred/pending") without a legitimate
deferral cause.
