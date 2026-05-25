# R25 — Proposed `ac-matrix.json` Diff (USER REVIEW REQUIRED)

**Authority:** /ps-heal GUARD — "the loop never auto-edits the matrix."
**Purpose:** This document lists EVERY proposed edit to `ac-matrix.json`
in R25, with rationale. The user reviews and signs off **before** W7
applies the diff in a single atomic commit.

**Format:** JSON Patch-style (RFC 6902) operations with rationale.

## Summary

| Edits | Type | Count |
|---|---|---|
| `min_tests` bumps | `replace` | 14 |
| `verify.kind: grep → command` | `replace` | 5 |
| `min_count` removals (replaced by content-validation) | `remove` | 5 |
| Total operations | — | **~24** |

**No AC removals. No SPEC hash changes.** All edits preserve the AC identity
+ severity + phase; only the verify recipe strengthens.

---

## Operations

### Group A — `min_tests` bumps (14 edits)

For each AC below, the operation is:
```json
{ "op": "replace", "path": "/criteria/[idx]/verify/min_tests", "value": <new> }
```

| AC | from | to | Rationale |
|---|---|---|---|
| AC-006 | 1 | 3 | R-25-01: schema validation needs valid + missing-field + wrong-type cases |
| AC-026 | 1 | 5 | R-25-02: simple + nested + dynamic + HUD-filter + no-pin cases |
| AC-027 | 1 | 3 | R-25-03: direct + nested HUD + adjacent-app cases |
| AC-041 | 1 | 2 | R-25-04: jsdom set-hash + restore-from-seed (Playwright stub deferred) |
| AC-004 | 1 | 3 | R-25-05: data-pin-ignore + excludeTags + sanity |
| AC-007 | 1 | 3 | R-25-06: reuse + new + soft-delete |
| AC-013 | 1 | 4 | R-25-07: 4 combinations of filePattern × excludePattern |
| AC-021 | 1 | 2 | R-25-08: enabled:false + production NODE_ENV |
| AC-022 | 1 | 2 | R-25-08: portal target + z-index ordering |
| AC-051 | 1 | 32 | R-25-09: all 32 SHORTCUT_PROPERTIES (it.each over the constant) |
| AC-053 | 1 | 3 | R-25-10: existing + 2 new (parse-failure paths) |
| AC-080 | 50 | 66 | R-25-11: align to actual test count (no new tests; matrix correction) |
| AC-091 | 1 | 4 | R-25-12: align to 4 new tests added in R-23-03 (matrix correction) |
| AC-024 | 1 | 2 | R-25-13: isolation + integration (R20+R25 both required) |
| AC-025 | 1 | 2 | R-25-14: isolation + integration |
| AC-070 | 1 | 3 | R-25-04 (carry): median-of-3 needs min_tests 3 to reflect the 3 samples (already coded as 3 sample reads in 1 it() — bump is documentation alignment) |

### Group B — `verify.kind: grep → command` (5 edits)

For each AC, replace the entire verify object:

#### AC-100
**from:**
```json
{
  "kind": "grep",
  "pattern": "^## (Conventions|Anti-Patterns|Common Patterns|Testing|Common Gotchas)",
  "paths": ["framework/apex-skills/pinscope.md"],
  "min_count": 5
}
```
**to:**
```json
{
  "kind": "command",
  "cmd": "node pinscope/scripts/validate-apex-skill.mjs framework/apex-skills/pinscope.md",
  "expect_exit": 0
}
```
**Rationale (R-25-17):** grep only checks section headers exist; says
nothing about whether each section has substantive content. New script
parses markdown, requires ≥3 sentences per section.

#### AC-102
**from:**
```json
{
  "kind": "grep",
  "pattern": "PINSCOPE INSTRUMENTATION",
  "paths": ["framework/commands/apex/ui-phase.md"],
  "min_count": 1
}
```
**to:**
```json
{
  "kind": "command",
  "cmd": "node pinscope/scripts/simulate-apex-ui-phase.mjs",
  "expect_exit": 0
}
```
**Rationale (R-25-18):** keyword grep passes on commented-out
placeholders. New script simulates the scaffold step end-to-end against
a tmp project and asserts the expected plugin import + `<PinScope/>`
mount appear in the output.

#### AC-103
**from:**
```json
{
  "kind": "grep",
  "pattern": "PINSCOPE EVIDENCE",
  "paths": ["framework/commands/apex/ui-review.md"],
  "min_count": 1
}
```
**to:**
```json
{
  "kind": "command",
  "cmd": "node pinscope/scripts/simulate-apex-ui-review.mjs",
  "expect_exit": 0
}
```
**Rationale (R-25-19):** same pattern; assert Snapshot consumption logic
is invoked, not just that the keyword exists in the doc.

#### AC-104
**from:**
```json
{
  "kind": "grep",
  "pattern": "pinscope",
  "paths": ["framework/agents/architect.md", "framework/modules/apex-frontend/agent.md"],
  "min_count": 2
}
```
**to:**
```json
{
  "kind": "command",
  "cmd": "node pinscope/scripts/validate-architect-mentions.mjs",
  "expect_exit": 0
}
```
**Rationale (R-25-20a):** generic word grep passes on any mention. New
script asserts BOTH files reference `apex-skills/pinscope` (the
specific skill-selection logic, not just the word "pinscope" appearing
in an unrelated comment).

#### AC-105
**from:**
```json
{
  "kind": "grep",
  "pattern": "PinScope",
  "paths": ["apex-spec.md"],
  "min_count": 1
}
```
**to:**
```json
{
  "kind": "command",
  "cmd": "node pinscope/scripts/validate-apex-spec-pinscope.mjs",
  "expect_exit": 0
}
```
**Rationale (R-25-20b):** any mention passes; the new script asserts
`apex-spec.md` has a PinScope section header (`## PinScope` or similar),
not just an incidental mention.

### Group C — `note` field updates (optional, traceability)

Per /ps-heal hygiene: add a brief `note` to each strengthened AC
explaining the R25 bump source (e.g., `"note": "Strengthened in R25 from min_tests:1 — see R25-MASTER-PLAN.md §R-25-01."`).

This is purely informational; the matrix evaluator doesn't read `note`.

---

## User review checklist

Before applying this diff in W7:

- [ ] All 16 `min_tests` bumps are justified by an R-item with concrete tests added.
- [ ] All 5 `kind: grep → command` swaps have working scripts in `pinscope/scripts/`.
- [ ] No AC entry is silently removed.
- [ ] No SPEC.md changes (matrix `generated_from_hash` stays `sha256:82a942188fd264f9a8cbfa058ed1e6aa7c7ff22342110a3b13e706d691348810`).
- [ ] Expected rigor-delta drop in `closed_count` is acknowledged: 63 → expected ~56-60 transient, restored after fixes.

**To approve:** in the new R25 session, the user says "approved per R25-MATRIX-PROPOSED-DIFF.md". The new session then applies the diff in W7 in one atomic commit titled `feat(pinscope): R-25-XX W7 — apply matrix-rigor sweep diff (user-approved)`.

## Atomic application

W7 applies the entire diff in one commit (single `Edit` per group of
changes to one file). If the user requests partial application (e.g.,
skip Group B for now), the new session can split into sub-commits — but
the default is all-or-nothing for clarity.

---

## Post-application verification

After W7 commit:
1. `node pinscope/convergence/lib/ac-verify.mjs --round 25` — exits with new
   verdict distribution. Expected: some new FAIL entries surface
   (the strengthened recipes catch what was previously false-PASS).
2. `cat pinscope/convergence/ac-results-R25.json | jq '[.results | to_entries[] | select(.value.verdict == "FAIL")] | length'` — count new FAILs.
3. Each new FAIL becomes an R-item for the **fix** phase (R-25-FIX-NN) in
   subsequent waves. The expected count is 3-7 ACs flipping CLOSED→OPEN.
4. After fixes land, `record-round` should restore closed_count to 63+
   and the loop converges.
