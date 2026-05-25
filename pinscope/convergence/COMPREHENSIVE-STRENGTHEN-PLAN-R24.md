# Comprehensive Strengthen Plan (for R25 execution) — PS-R24

**Authored:** 2026-05-25
**Scope:** All remaining test-rigor + AC-matrix-rigor items deferred from R23 + R24 to R25.
**Authority:** R25 execution requires user approval — most items require `ac-matrix.json` edits, which the loop never auto-applies.

## Executive summary

Three categories of strengthening, in priority order:

| Category | Items | Severity | Effort | Convergence impact |
|---|---|---|---|---|
| **A — Matrix-rigor sweep (F7)** | 24 ACs WEAK/TRIVIAL | 8 P0/P1 + 16 P2/P3 | LARGE (~2 days) | Expected: 63 closed → 56-60 closed (rigor-aware drop), then back to 63+ after fixes |
| **B — Polish (AC-024/025 strengthen)** | 2 AC verify recipes upgrade isolation → integration | P2 | MEDIUM (~half day) | No metric movement; rigor improvement |
| **C — Polish (deferred from R24 audit)** | AC-053 fold, AC-001 dedup | LOW | SMALL (~hour) | No metric movement; code organization |

User-approved Strategy A (R23 plan-mode answer) was: "חיזוק חלקי, רק P0/P1" — focus on the 8 P0/P1 in Category A. R25 should start there.

---

## Category A — Matrix-rigor sweep (F7, 24 ACs)

These ACs have verify recipes that are surface-level (presence checks, `min_tests:1`, grep-only) rather than behavioral. R23's deep investigation classified them as WEAK or TRIVIAL.

### A.1 — P0 / P1 items (the user's chosen scope: "חלקי P0/P1")

| AC | Phase | Sev | Current verify | Proposed strengthening |
|---|---|---|---|---|
| **AC-006** | P1 | P1 | `vitest-tag min_tests:1` | Bump `min_tests:3` + write 3 distinct PinMap schema cases (valid, missing fields, wrong types). Add explicit `ajv validate` against a JSON schema. |
| **AC-026** | P1 | P1 | `vitest-tag min_tests:1` (mocked DOM) | Bump `min_tests:5` to cover: simple element, nested elements, HUD-filtering, dynamic mid-frame element, no-pin-found edge. |
| **AC-027** | P1 | P1 | `vitest-tag min_tests:1` | Bump `min_tests:3` for HUD-element-filtering across multiple HUD element types. |
| **AC-041** | P2 | P1 | `vitest-tag min_tests:1` (jsdom) | Add a Playwright integration test asserting actual `window.location.hash` persistence across a real reload cycle. Move to `env: browser` `kind: vitest-tag` once Playwright CI exists. |
| **AC-070** | P1 | P1 | `vitest-tag min_tests:1` | Already R-24-03 median-of-3. Bump `min_tests:1 → 3` to formalize the median-of-3 in matrix. |
| **AC-073** | P1 | P0 | (R-23-01 closed) | Document the dual-budget assertion + the script's contract in matrix `note` field. |
| **AC-100/102/103/104/105** | P5 | P1/P2 | `grep min_count: 1-2` | Replace keyword grep with content-validation: parse the markdown, assert sections exist with substantive content (e.g., ≥3 sentences). Move from `kind: grep` to `kind: command` invoking a validation script. |

### A.2 — P2 / P3 items (deferred per user "P0/P1 חלקי" scope)

| AC | Phase | Sev | Current | Proposed (when ready) |
|---|---|---|---|---|
| AC-004 | P1 | P2 | `vitest-tag min_tests:1` | Bump to 3; cover excludeTags + data-pin-ignore distinct branches. |
| AC-007 | P1 | P2 | `vitest-tag min_tests:1` | PinMap monotonicity over multiple operations. |
| AC-013 | P1 | P2 | `vitest-tag min_tests:1` | filePattern + excludePattern combinations (4 cases). |
| AC-021 | P1 | P2 | `vitest-tag min_tests:1` | `enabled={false}` + production NODE_ENV (2 cases). |
| AC-022 | P1 | P2 | `vitest-tag min_tests:1` | Portal target verification + Z-index ordering. |
| AC-030 | P1 | P3 | `vitest-tag min_tests:1` (browser-blocked) | Playwright env when available. |
| AC-036 | P1 | P3 | `vitest-tag min_tests:1` (browser-blocked) | Playwright env. |
| AC-051 | P3 | P2 | `vitest-tag min_tests:1` | Property-shortcut coverage across all 32 styles. |
| AC-053 | P3 | P2 | `vitest-tag min_tests:1` | Already polished in R-24-04 audit (AC-053 fold). |
| AC-080 | P1 | P3 | `vitest-tag min_tests:50` | Already strong; consider `min_tests:75`. |
| AC-091 | P3 | P3 | `vitest-tag min_tests:1` | Already R-23-03 strengthened. |

### A.3 — Implementation plan for Category A

**R25 wave structure (proposed):**
- **W1 — Test additions** — write the new `it()` blocks for AC-006/026/027/070 (Node-env, can run today). Each AC gets 3-5 new substantive tests.
- **W2 — Matrix edits** — update `ac-matrix.json` verify recipes per the table above. User approves the patch file before merge.
- **W3 — Content-validation scripts** — write `scripts/validate-skill-docs.mjs` (or similar) for AC-100/102/103/104/105 to replace keyword grep.
- **W4 — Playwright stubs** — mark AC-030/036/041/061/063/082/083 as `env: browser` with a single source-of-truth Playwright test runner (CI integration is its own milestone).

**Expected metric trajectory:**
- Start of R25: 63 closed
- Mid-R25 (after test additions but BEFORE matrix bump): 63 closed (new tests pass; old recipe still PASS)
- After matrix bump: 60-62 closed temporarily (some ACs may FAIL the stricter recipe — exactly the false-PASSes the sweep is catching)
- After fixes: 63+ closed (genuinely-passing ACs)

Per user's R23 plan-mode answer: "להוסיף rigor-delta כמטריקה נפרדת". Document the `closed_delta_by_rigor` metric in `loop.json` so the temporary drop is recognized as rigor-improvement, not regression.

---

## Category B — AC-024 / AC-025 strengthen to integration

**Current state:**
- **AC-024** (VoidBadges JS-overlay) — `vitest-tag` test renders `<VoidBadges/>` in isolation. After R-20-01 wired VoidBadges into `PinScopeHud`, the test never exercises the integrated path.
- **AC-025** (RuntimePinObserver) — `vitest-tag` test instantiates `new RuntimePinObserver()` directly. After R-20-02 wired the observer into `PinScopeHud`'s useEffect, the test never exercises the live lifecycle.

**The risk:** if PinScope.tsx silently drops VoidBadges or stops calling RuntimePinObserver, the AC stays GREEN (because the isolation test still passes). This is the exact pattern that R20 broke for the first time.

**The fix:**
- AC-024 — add an integration test in `pinscope.test.tsx` (or extend the existing R-20-01 test) that renders `<PinScope/>`, mounts dynamic `<img>` element, asserts VoidBadges placed an overlay div via the integrated path.
- AC-025 — add an integration test that renders `<PinScope/>`, mounts a dynamic element, asserts `e_r{N}` runtime ID is assigned by the live observer (not the constructor unit test).

**Matrix change required:** None — the tests can be added under existing `vitest-tag` AC-024/AC-025. Optionally, bump `min_tests: 1 → 2` to require both the isolation test AND the integration test.

**Effort:** ~30 minutes (2 tests + matrix optional bump).

---

## Category C — R24 audit polish (LOW)

### C.1 — AC-053 fold

**Current:** `controls.test.tsx:225-251` tests `entry.raw_input` only. Sibling tests (L253-276 R-20-05-snapshot, L278-302 R-20-05-measure) test `entry.parsed === null` and `entry.result === 'applied'`.

**Proposed:** Fold the parsed + result asserts into the first `it()` block so all three fields are asserted per case symmetrically. The sibling tests become focused on the disjunct kinds (snapshot/measure) without re-asserting shape.

**Effort:** ~10 minutes.

### C.2 — AC-001 dedup

**Current:** `plugin.test.ts` has separate describes for AC-001 (plugin shape), AC-013 (transform), AC-009 (transformIndexHtml). The AC-001 block uses `toBeDefined()` while AC-013 + AC-009 have substantive behavior tests.

**Proposed:** Merge the three describes into one "pinscope() plugin (AC-001 + AC-013 + AC-009)". Rename the AC-001 `it()` blocks to `it('declares AC-001 plugin shape', ...)` etc., using `it.each` to preserve the tag-grep so the matrix still finds all three.

**Effort:** ~20 minutes. Pure code organization.

---

## Recommended R25 scope

**Option X (Conservative — recommended):**
- Category A.1 only (P0/P1 ACs, 7 items)
- Category B (AC-024/025 strengthen)
- Category C (polish, 30 minutes)
- **Effort:** ~half day
- **Outcome:** ~7-8 AC verify recipes strengthened + 2 integration tests + 2 polish fixes
- **Risk:** Low — Category A.1 is well-bounded; the new tests are pre-flighted before matrix bump

**Option Y (Aggressive — original "Game changer"):**
- Categories A (full 24 ACs) + B + C
- **Effort:** ~2 days
- **Outcome:** Full matrix-rigor sweep; "Game changer" rigor improvement
- **Risk:** Medium — Playwright CI integration for env=browser ACs is a separate milestone; A.2 items don't add much over A.1

**Option Z (Minimal — only what's safe today):**
- Category C only (polish, 30 minutes)
- Defer Categories A + B to R26+ when Playwright CI is in place
- **Effort:** 30 minutes
- **Outcome:** Test cleanup; no new convergence signal
- **Risk:** Zero

User chose Strategy A in R23 plan-mode answer ("חיזוק חלקי, רק P0/P1"). That maps to **Option X**.

---

## Open questions for the user (R25 trigger decisions)

1. **R25 strategy:** Option X / Y / Z?
2. **Matrix edit policy:** continue the orchestrator-records-pattern (matrix edits done by main thread under explicit user approval), OR build a new R-25-00 step that produces `proposed-matrix-diff.R25.json` for user review before any edit lands?
3. **Playwright CI setup:** the 6 BLOCKED env=browser ACs + the AC-071/030/036/041 production-accurate verification all need a real browser. Plan a separate CI milestone OR continue defer?
4. **rigor-delta metric:** add `closed_delta_by_rigor` field to `loop.json` schema? Or keep monotonicity strict and only allow rigor drops via explicit `--allow-rigor-regression` flag?

These four answers shape R25's scope. R24 leaves the door open for any combination.

---

## Done in R24 (already complete; do NOT re-do in R25)

- **R-24-01** — iframe-overlay wire-back (commit `d8f4ea1`) — closes NF-23-01
- **R-24-02** — 4 mutation survivors killed (commit `614249e`) — InfoPanel SSR-guard, useHoveredElement pin-guard, useKeyboardShortcuts grid-0/grid-3 tautology
- **R-24-03** — AC-070 median-of-3 (commit `614249e`)
- **R-24-04** — this audit + the COMPREHENSIVE-TEST-QUALITY-AUDIT-R24.md document
- **R-24-05** — this strengthen plan
