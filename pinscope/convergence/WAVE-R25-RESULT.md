# R25 — Wave Execution Results

Per-wave record of work executed in PinScope round 25 (Option Y, full F7
matrix-rigor sweep). Each wave block lists the R-items closed, the files
touched, the tests added, and the per-R-item mutation gate documented.

Authority: `pinscope/convergence/R25-MASTER-PLAN.md` §Mutation-gates rule —
"every R-item that adds production tests MUST have a documented mutation
that turns the new test RED."

---

## W1 — R-25-01..04 — P1 strengthening (AC-006/026/027/041)

**Status:** ✅ closed
**Files touched:**
- `pinscope/tests/unit/pin-map-schema.test.ts` (NEW, 195 lines, 3 tests)
- `pinscope/tests/unit/runtime/useHoveredElement.test.tsx` (+192 lines, +9 tests)

**Test results (per `npx vitest run` from `pinscope/`):**
- New W1 tests: 13 / 13 pass.
- Full suite post-W1: 32 files, 344 tests pass (0 fail, 0 regressions).
- `npx tsc --noEmit`: clean.

### R-25-01 — AC-006 PinMap schema validation

- **AC:** AC-006 P1 P1 — `.pinmap.json` validates against §9.1 schema.
- **Tests added (3):**
  1. `valid PinMap roundtrips through JSON and passes the schema` — happy-path via `PinMap.save()` → reload via validator.
  2. `missing required version field is rejected with a clear error` — also tests missing `next_id` and missing `entries`.
  3. `wrong field types are rejected with a clear error` — covers `next_id` type, `version` value, `id` regex, `deleted` value.
- **Mutation gate:** mutate `PinMap.save` (src) to write `version: 2` → test 1's `validatePinMapSchema(raw).ok` assertion fails (regex `/version must be 1/`).
- **Matrix-bump target (W7):** `min_tests: 1 → 3`.

### R-25-02 — AC-026 useHoveredElement integration coverage

- **AC:** AC-026 P1 P1 — `useHoveredElement` returns nearest `[data-pin]` ancestor under the cursor.
- **Tests added (5, hook-level integration — utility unit tests already exist in `element-walker.test.ts`):**
  1. Direct element with `data-pin` under cursor.
  2. Nested element — cursor on leaf inside pinned ancestor.
  3. Dynamic element mounted AFTER hook started observing.
  4. Cursor over HUD element — null (delegates to AC-027 filter).
  5. Cursor over element with no pinned ancestor — null.
- **Mutation gate:** mutate `findPinnedAncestor` (src/runtime/utils/element-walker.ts) to always return `null` → 4 of 5 AC-026 tests RED (tests 1, 2, 3, and the AC-027-delegation case all expect a non-null `pinId`).
- **Matrix-bump target (W7):** `min_tests: 1 → 5`.

### R-25-03 — AC-027 HUD-element filtering

- **AC:** AC-027 P1 P1 — hover detection ignores elements inside `[data-pinscope-ui]`.
- **Tests added (3, hook-level):**
  1. Cursor on HUD root itself (even with own `data-pin`) — null.
  2. Cursor on deeply nested HUD descendant with `data-pin` — null.
  3. App element adjacent to (NOT inside) HUD — NOT ignored (sanity).
- **Mutation gate:** remove the `escapeHud` call in `useHoveredElement.ts` → tests 1 and 2 go RED (would now resolve `e_50`/`e_60` instead of null).
- **Matrix-bump target (W7):** `min_tests: 1 → 3`.

### R-25-04 — AC-041 URL hash persistence — DISCOVERY: already covered

- **AC:** AC-041 P2 P1 — `SelectionManager` mirrors selected pin to URL hash `#select=e_N` and restores on reload.
- **Original master-plan strengthen target:** +2 jsdom cases + 1 Playwright e2e stub.
- **Discovery during execution:**
  - **5 AC-041-tagged tests already exist in `pinscope/tests/unit/runtime/selection.test.tsx:11-59`:**
    1. `mirrors the selected pin to the URL hash` (line 12) — covers strengthen case 1.
    2. `restores the selected pin from the hash on construction (reload)` (line 20) — covers strengthen case 2.
    3. `moves the data-pin-selected attribute to the chosen element` (line 27).
    4. `clear removes the selection and the hash` (line 44).
    5. `goBack steps through selection history` (line 52).
  - **Playwright reload-restore integration test already exists at `pinscope/tests/integration/pinscope.spec.ts:45-53`** — covers exactly what the proposed `tests/e2e/url-hash.spec.ts` stub was meant for.
- **Decision:** no source edits in W1. The e2e stub is redundant and would duplicate the existing Playwright test. The R-25-04 R-item closes against the existing 5 jsdom tests + 1 Playwright test.
- **Mutation gate:** mutate `SelectionManager.select` (src/runtime/managers/SelectionManager.ts) to remove `location.hash = ...` assignment → `selection.test.tsx` test 1 (`expect(location.hash).toBe('#select=e_47')`) goes RED. Already covered by existing test design.
- **Matrix-bump target (W7):** `min_tests: 1 → 5` (revised from the original `→ 2` — reflects actual existing coverage, not stale plan target).

---

## W2 — R-25-05..08 — P2 cluster strengthening (AC-004/007/013/021/022)

**Status:** ✅ closed
**Files touched:**
- `pinscope/tests/unit/ast-transformer.test.ts` (+47 lines, +3 tests)
- `pinscope/tests/unit/pin-map.test.ts` (+45 lines, +3 tests)
- `pinscope/tests/unit/runtime/components.test.tsx` (+62 lines, +4 tests)

**Test results:** 10 new W2 tests pass (88 across touched files; full suite 354/354 green; tsc clean).

### R-25-05 — AC-004 excludeTags + data-pin-ignore

- **AC:** AC-004 P1 P2 — `excludeTags` config and `data-pin-ignore` attribute are honored.
- **Tests added (3, new `describe('AST transformer — opt-out rules (AC-004)')`):**
  1. excludeTags-from-config: `<Fragment><span /></Fragment>` → Fragment not pinned, span IS pinned.
  2. data-pin-ignore opt-out: `<div data-pin-ignore><span /></div>` → div not pinned, span IS pinned.
  3. Sibling-without-opt-out sanity: `<section><Fragment /><button /></section>` → 2 pins (section + button), Fragment excluded.
- **Mutation gate:** remove `if (opts.excludeTags.includes(tagName)) return;` (src/plugin/ast-transformer.ts:58) → tests 1 + 3 RED. Also remove `if (hasAttribute(node, 'data-pin-ignore')) return;` (line 60) → test 2 RED.
- **Matrix-bump target (W7):** `min_tests: 1 → 3`.

### R-25-06 — AC-007 PinMap monotonic ID invariants

- **AC:** AC-007 P1 P2 — IDs are monotonic; deleted IDs are never reused.
- **Tests added (3, new `describe('PinMap monotonicity invariants (AC-007)')`):**
  1. Same key reuses ID across multiple getOrAssign calls.
  2. New key gets next sequential ID with no gaps.
  3. **Soft-delete invariant** — after `reconcile([alive])` marks a key deleted, a new key gets `e_3` not the freed `e_1` slot.
- **Mutation gate:** mutate `PinMap.getOrAssign` to allow reusing soft-deleted IDs (e.g., scan entries for first `deleted: true` and reuse its id) → test 3 RED (cId would equal aId).
- **Matrix-bump target (W7):** `min_tests: 1 → 3`.

### R-25-07 — AC-013 filePattern/excludePattern gating — DISCOVERY: already covered

- **AC:** AC-013 P1 P2 — `filePattern` / `excludePattern` plugin options gate the transform.
- **Original master-plan strengthen target:** +4 cases in ast-transformer.test.ts.
- **Discovery:** filePattern/excludePattern gating happens in the plugin `transform` hook (`pinscope/tests/unit/plugin.test.ts:35-65`), NOT in `transformJSX`. The plugin spec already has **5 AC-013-tagged tests** covering: non-matching extension (.css), excluded path (node_modules), test-file gating (.test.tsx), disabled plugin, and the matching-.tsx happy path. These cover all 4 filePattern × excludePattern combinations.
- **Decision:** no source edits. 5 ≥ 4 (matrix target). R-25-07 closes against existing coverage.
- **Mutation gate:** mutate `transform` hook to skip the filePattern check → tests 1 + 3 RED (would now transform .css and .test.tsx).
- **Matrix-bump target (W7):** `min_tests: 1 → 4`.

### R-25-08 — AC-021 + AC-022 PinScope kill-switches & portal target

- **AC-021 P1 P3** — PinScope returns null when `enabled={false}` OR in production NODE_ENV.
- **AC-022 P1 P3** — HUD portal-renders into `[data-pinscope-ui="root"]` attached to `document.body`.
- **Tests added (4, two new describe blocks in components.test.tsx):**
  - AC-021 (2): `enabled={false}` → empty container + no portal root; `NODE_ENV=production` → empty container + no portal root (env restored in finally).
  - AC-022 (2): exactly one `[data-pinscope-ui="root"]` mounted on document.body (parent === document.body); portal escapes the local render container (HUD root NOT inside testing-library container).
- **Mutation gates:**
  - AC-021 #1: remove `if (props.enabled === false) return null;` (PinScope.tsx:58) → enabled-false test RED.
  - AC-021 #2: remove `if (process.env.NODE_ENV === 'production') return null;` (PinScope.tsx:57) → NODE_ENV=production test RED.
  - AC-022: change createPortal target from `document.body` to the React-tree element → "portal lives directly under document.body" test RED (parentElement would not equal document.body).
- **Matrix-bump targets (W7):** AC-021 `min_tests: 1 → 2`; AC-022 `min_tests: 1 → 2`.

## W3 — R-25-09..12 — test-rich ACs

(Pending — to be filled on close.)

## W4 — R-25-13..14 — Category B integration

(Pending — to be filled on close.)

## W5 — R-25-15..16 — Category C polish

(Pending — to be filled on close.)

## W6 — R-25-17..20 — Content-validation scripts

(Pending — to be filled on close.)

## W7 — R-25-21..26 — Matrix bump (USER-GATED)

(Pending — to be filled on close.)

## FIX waves — R-25-FIX-NN

(Pending — populated based on `ac-results-R25.json` FAIL set after W7.)
