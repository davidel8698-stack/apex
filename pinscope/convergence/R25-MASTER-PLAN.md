# R25 Master Plan — Full F7 Matrix-Rigor Sweep (Option Y)

**Round:** 25
**Strategy:** Option Y (aggressive, ~2 days) — full F7 sweep
**Goal:** Eliminate all 22 WEAK/TRIVIAL ACs in the matrix; close AC-024/025
isolation→integration gap; land R-24-04 polish. After R25, the matrix
itself becomes a rigorous verifier — no more `min_tests: 1` rubber-stamps.

**Authority:** User pre-approved in R23 plan-mode AND R24 closure response.
Matrix edits require user sign-off via `R25-MATRIX-PROPOSED-DIFF.md`
review (see that doc).

## Round summary

R25 has **26 R-items** across **7 waves**. The waves are grouped by file-
ownership (one-owner-per-wave rule) and by execution risk (matrix edits
are gated on user approval, so they happen in a dedicated wave).

| Wave | R-items | Type | Estimated effort |
|---|---|---|---|
| W1 | R-25-01..04 | Add tests for AC-006/026/027/041 (P1 priority) | 2 hours |
| W2 | R-25-05..08 | Add tests for AC-004/007/013/021/022 (P2 cluster) | 2 hours |
| W3 | R-25-09..12 | Add tests for AC-051/053/080/091 (test-rich ACs) | 1.5 hours |
| W4 | R-25-13..14 | AC-024 + AC-025 integration tests (Category B) | 30 min |
| W5 | R-25-15..16 | AC-053 fold + AC-001 dedup (Category C polish) | 30 min |
| W6 | R-25-17..20 | Content-validation scripts for AC-100/102/103/104/105 | 2 hours |
| W7 | R-25-21..26 | **MATRIX BUMP wave** — apply approved `ac-matrix.json` diff; deferred-Playwright stubs for AC-030/036/070 strict | 1 hour + user review |

**Total wall-time estimate:** ~9 hours work + user review time. Spread across
2 sessions if needed.

---

## Category A — F7 sweep R-items (R-25-01..20)

### R-25-01 — AC-006 PinMap schema validation (P1)

**Linked AC:** AC-006 P1 P1 — ".pinmap.json validates against the §9.1 schema"
**Current verify:** `vitest-tag min_tests: 1` (any test grepping `AC-006` tag)
**Current test:** Per audit, the single AC-006 test is shared fixture coverage
in ast-transformer.test.ts; does NOT directly validate the schema.

**Strengthen plan:**
- Add `pinscope/tests/unit/pin-map-schema.test.ts` (new file) with 3 distinct
  describe cases tagged AC-006:
  1. `valid PinMap roundtrips through JSON` — write+read happy path.
  2. `missing required field rejects with clear error` — omit `version` or
     `next_id`, assert validator catches.
  3. `wrong field types reject` — `next_id: "string"` instead of number.
- Use `ajv` if available, or hand-roll a tiny schema validator (~30 lines).

**Matrix bump:** `min_tests: 1 → 3` for AC-006.

**DoD:** all 3 new tests pass; AC-006 verdict stays PASS post-matrix-bump;
mutation gate: corrupt the schema validator (always return true) → 1+ of
the 3 tests goes RED.

### R-25-02 — AC-026 hover detection coverage (P1)

**Linked AC:** AC-026 P1 P1 — "`useHoveredElement` returns the nearest `[data-pin]` ancestor of the element under the cursor"
**Current verify:** `vitest-tag min_tests: 1` (likely 1 RTL mock case)

**Strengthen plan:**
- Extend `pinscope/tests/unit/runtime/useHoveredElement.test.tsx` (created in
  R-24-02) with 4 new cases tagged AC-026:
  1. Simple element under cursor with `data-pin`.
  2. Nested element — cursor inside child, ancestor has `data-pin`.
  3. Dynamic element added at runtime (mounts after observer started).
  4. Cursor over HUD element — ignored per AC-027.
  5. No `[data-pin]` ancestor — returns null.

**Matrix bump:** `min_tests: 1 → 5` for AC-026.

**DoD:** 5 cases pass; mutation gate: change `findPinnedAncestor` to return
`null` always → 4 of 5 tests RED.

### R-25-03 — AC-027 HUD-element filtering (P1)

**Linked AC:** AC-027 P1 P1 — "hover detection ignores elements inside `[data-pinscope-ui]`"

**Strengthen plan:**
- Add 3 cases to `useHoveredElement.test.tsx`:
  1. Direct HUD element — ignored.
  2. Nested HUD element (`[data-pinscope-ui] > * > target`) — ignored.
  3. App element adjacent to HUD — NOT ignored (sanity).

**Matrix bump:** `min_tests: 1 → 3`.

**DoD:** 3 cases pass; mutation: remove the `escapeHud` call → tests RED.

### R-25-04 — AC-041 URL hash persistence (P1)

**Linked AC:** AC-041 P2 P1 — "`SelectionManager` mirrors the selected pin to URL hash `#select=e_N` and restores on reload"
**Current verify:** `vitest-tag min_tests: 1` (jsdom; partial)

**Strengthen plan:**
- 2 jsdom cases (best-effort under happy-dom):
  1. Set selection → `window.location.hash === '#select=e_N'`.
  2. Pre-seed hash → on mount, selection is restored.
- Mark a Playwright stub for real-browser reload (env: browser, DEFERRED to
  Playwright CI milestone — not blocking R25 close).

**Matrix bump:** `min_tests: 1 → 2`.

**DoD:** 2 cases pass; Playwright stub created in `pinscope/tests/e2e/`
(directory may be new).

### R-25-05 — AC-004 excludeTags + data-pin-ignore (P2)

**Linked AC:** AC-004 P1 P2 — "excludeTags / data-pin-ignore honored"

**Strengthen plan:**
- 3 cases in `pinscope/tests/unit/ast-transformer.test.ts`:
  1. Element with `data-pin-ignore` — NOT instrumented.
  2. Tag in excludeTags config — NOT instrumented.
  3. Sibling without exclude — instrumented (sanity).

**Matrix bump:** `min_tests: 1 → 3`.

**DoD:** 3 cases pass; mutation: drop the exclude check → all 3 RED.

### R-25-06 — AC-007 PinMap.getOrAssign monotonicity (P2)

**Strengthen plan:**
- 3 cases: same key reuses ID; new key gets next ID; deletion is a soft
  delete (ID never reused).

**Matrix bump:** `min_tests: 1 → 3`.

### R-25-07 — AC-013 filePattern/excludePattern gating (P2)

**Strengthen plan:**
- 4 cases covering all 4 combinations of (filePattern matches y/n) × (excludePattern matches y/n).

**Matrix bump:** `min_tests: 1 → 4`.

### R-25-08 — AC-021 + AC-022 (P2)

**Linked ACs:** AC-021 (`enabled={false}` returns null) + AC-022 (portal under `data-pinscope-ui="root"`).

**Strengthen plan:** 2 cases each (4 total). Already partly covered in components.test.tsx; add explicit AC-021 tag.

### R-25-09 — AC-051 property shortcuts (P2)

**Linked AC:** AC-051 P3 P2 — "32 property shortcuts work via `e_N.{prop} → {value}`".

**Strengthen plan:** parameterized `it.each` over all 32 SHORTCUT_PROPERTIES; each must produce a valid operation. (Replaces the current min_tests:1 with min_tests:32.)

**Matrix bump:** `min_tests: 1 → 32`.

### R-25-10 — AC-053 HistoryManager append (P2)

**Linked AC:** AC-053 P3 P2 — "CommandBar appends recall-supporting entry for local-only commands; `parsed: null`; `result: 'applied'`".

**Strengthen plan:** R-24-04 polish — fold the parsed/result asserts into the first AC-053 it(). Then add 2 more cases for the failure-on-parse path.

**Matrix bump:** `min_tests: 1 → 3`.

### R-25-11 — AC-080 AST transformer coverage (already strong)

**Note:** AC-080 currently has `min_tests: 50`. Bump to `min_tests: 66` to
match the actual 66 cases in ast-transformer.test.ts. No new tests needed;
just matrix alignment.

### R-25-12 — AC-091 plugin shape (already strong post-R23)

**Note:** AC-091 was strengthened in R-23-03. Matrix bump: `min_tests: 1 → 4`
to match the 4 new tests added in R-23-03.

### R-25-13 — AC-024 VoidBadges integration (Category B)

**Strengthen plan:** Add integration test in `pinscope.test.tsx` (or extend
existing R-20-01 block): render `<PinScope/>`, append a `<img>` dynamic
element, assert `[data-void-badge]` overlay div appears via the integrated
path. The existing isolation test stays — both must pass.

**Matrix bump:** `min_tests: 1 → 2`.

### R-25-14 — AC-025 RuntimePinObserver integration (Category B)

**Strengthen plan:** Same pattern — integration test using the live observer
inside `<PinScope/>` to assign `e_r{N}` to dynamic elements.

**Matrix bump:** `min_tests: 1 → 2`.

### R-25-15 — AC-053 fold (Category C, R-24-04 polish)

**Strengthen plan:** Combine the 3 entry-shape assertions (raw_input,
parsed, result) into the first AC-053 it() block in controls.test.tsx.

**Matrix bump:** None.

### R-25-16 — AC-001 dedup (Category C, R-24-04 polish)

**Strengthen plan:** Merge AC-001 + AC-013 + AC-009 plugin describes into
one. Pure code organization.

**Matrix bump:** None.

### R-25-17 — AC-100 apex-skill format content validation

**Linked AC:** AC-100 P5 P1 — "`framework/apex-skills/pinscope.md` follows apex-skill format"
**Current verify:** `grep -E '^## (Conventions|Anti-Patterns|...)'` min_count: 5

**Strengthen plan:**
- Write `pinscope/scripts/validate-apex-skill.mjs` — parse `pinscope.md`,
  assert each section has ≥3 sentences of content (not stubs).
- Convert matrix verify from `grep` to `command` invoking the new script.

**Matrix bump:** kind grep → kind command. Script exits 0/1.

### R-25-18 — AC-102 ui-phase PinScope scaffolding

**Linked AC:** AC-102 P5 P1 — "`/apex:ui-phase` scaffolds PinScope into target project"
**Current verify:** `grep "PINSCOPE INSTRUMENTATION"` min_count: 1

**Strengthen plan:**
- Write `pinscope/scripts/simulate-apex-ui-phase.mjs` — runs the scaffolding
  step against a tmp project, asserts plugin import + `<PinScope/>` mount
  appear in the result.
- Convert matrix verify from `grep` to `command`.

**Matrix bump:** kind grep → kind command.

### R-25-19 — AC-103 ui-review Snapshot consumption

**Strengthen plan:** Same approach — simulate `/apex:ui-review`, assert it
consumes Snapshot artifact correctly.

### R-25-20 — AC-104 + AC-105 (apex-spec + architect.md mentions)

**Strengthen plan:**
- For AC-104: convert grep `pinscope` to `command` invoking a script that
  asserts both `framework/agents/architect.md` AND
  `framework/modules/apex-frontend/agent.md` reference the PinScope skill
  selection logic by name (e.g., grep for `apex-skills/pinscope` not just
  `pinscope`).
- For AC-105: convert grep `PinScope` to `command` asserting `apex-spec.md`
  has a PinScope section header (not just any mention).

---

## Wave Schedule

### W1 — Top-priority P1 strengthening (R-25-01..04)
- Files: `tests/unit/pin-map-schema.test.ts` (NEW), `tests/unit/runtime/useHoveredElement.test.tsx` (+9 tests for AC-026/027), `tests/unit/runtime/selection.test.tsx` (+2 for AC-041), `tests/e2e/url-hash.spec.ts` (NEW, Playwright stub).
- One-owner check: 4 disjoint files. No collision.
- Gate: typecheck exit 0; new tests green; old tests green.

### W2 — P2 cluster strengthening (R-25-05..08)
- Files: `tests/unit/ast-transformer.test.ts` (+3+4 = +7 cases), `tests/unit/pin-map.test.ts` (+3), `tests/unit/runtime/components.test.tsx` (+4 for AC-021/022).
- One-owner check: 3 disjoint files.
- Gate: same.

### W3 — Test-rich ACs (R-25-09..12)
- Files: `tests/unit/property-shortcuts.test.ts` (+32 it.each for AC-051), `tests/unit/runtime/controls.test.tsx` (+2 for AC-053 failure-on-parse), no source changes for AC-080/091 (matrix-only).
- One-owner check: 2 disjoint files.
- Gate: same.

### W4 — Category B integration strengthen (R-25-13..14)
- Files: `tests/unit/runtime/pinscope.test.tsx` (+2 integration tests for AC-024/025).
- One-owner check: 1 file, 2 new tests.
- Gate: same.

### W5 — Category C polish (R-25-15..16)
- Files: `tests/unit/runtime/controls.test.tsx` (AC-053 fold), `tests/unit/plugin.test.ts` (AC-001/009/013 dedup).
- One-owner check: 2 disjoint files. Note: controls.test.tsx is also touched in W3 (for AC-053 failure cases) — serialize W3 first, then W5.
- Gate: same.

### W6 — Content-validation scripts (R-25-17..20)
- Files: `pinscope/scripts/validate-apex-skill.mjs`, `simulate-apex-ui-phase.mjs`, `simulate-apex-ui-review.mjs`, `validate-architect-mentions.mjs`, `validate-apex-spec-pinscope.mjs` (5 new scripts).
- One-owner check: 5 disjoint new files.
- Gate: each script exit 0 against current docs; mutation gate by replacing target docs with stubs.

### W7 — Matrix bump (R-25-21..26)
- Files: `pinscope/convergence/ac-matrix.json` (single edit applying all approved diff from `R25-MATRIX-PROPOSED-DIFF.md`).
- One-owner check: 1 file.
- Gate: user has reviewed `R25-MATRIX-PROPOSED-DIFF.md`; `node pinscope/convergence/lib/ac-verify.mjs --round 25` exits cleanly; `record-round` is allowed to record a rigor-aware closed_count drop with explicit `rigor_delta` annotation.

---

## Expected metric trajectory

| Checkpoint | closed | open | blocked | manual_pending | total | pct | Notes |
|---|---|---|---|---|---|---|---|
| R24 close (baseline) | 63 | 0 | 6 | 0 | 69 | 91% | All ACs PASS at current rigor |
| Mid-R25 (after W1-W6, before W7) | 63 | 0 | 6 | 0 | 69 | 91% | New tests added; old recipe still passing |
| **Post-W7 (matrix bump)** | **~56-60** | **~3-7** | **6** | **0** | **69** | **~84%** | **EXPECTED rigor-aware drop**; new strict recipes catch real gaps |
| End of R25 (fixes land) | 63+ | 0 | 6 | 0 | 69 | 91%+ | Fixes restore + may net positive |

**Critical:** the W7 drop is EXPECTED and SHOULD NOT trip the monotonicity
guard. Use the `rigor-delta` annotation pattern (see Risk Register §3).

## Mutation gates (per R-item)

Every R-item that adds production tests MUST have a documented mutation
that turns the new test RED. The mutation is recorded in
`WAVE-R25-RESULT.md` per wave block.

For matrix-only R-items (R-25-11/12) — no source mutation; the verify
recipe bump itself is the mutation gate (running ac-verify against the
strengthened recipe must surface a difference from running it against the
weak recipe).

For script-based R-items (R-25-17..20) — corrupt the target document in a
worktree, run the script, must exit 1.

## Definition of Done (round-level)

R25 closes PASS when ALL of:
1. All 26 R-items closed against their per-item DoD.
2. Matrix-diff applied AND user-signed-off.
3. Mutation kill rate ≥ 90% on touched files.
4. Zero regressions in R23+R24 closed ACs (other than expected rigor-drops).
5. `loop_status` recomputes to CONVERGED OR explicit `rigor_delta` annotation explaining transient drop.
6. New `COMPREHENSIVE-TEST-QUALITY-AUDIT-R25.md` confirms 0 new findings (i.e., the F7 sweep was exhaustive).

## Out of scope (DO NOT do in R25)

- **SPEC.md normative edits** — frozen v2.0.0. Only docs-only footnotes
  (already used in R-23-05).
- **Playwright CI setup** — separate milestone; R25 only writes stubs.
- **6 browser-env BLOCKED ACs** (023/030/061/063/082/083) — strengthen
  later when Playwright CI exists.
- **Re-running R23/R24 audits** — covered in `COMPREHENSIVE-TEST-QUALITY-AUDIT-R24.md`.
- **Editing `framework/`** — user owns that; pinscope-only scope.
