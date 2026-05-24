# PinScope Remediation Plan — PS-R1

> Authored per `framework/docs/REMEDIATION-STYLE.md`: content anchors, not line
> numbers; five mandatory sections per R-item.
> **Round scope:** build-time module (Cluster A) + verify APEX integration
> (Cluster H). Source of findings: `audit-findings-R1.md`.

---

## Remediation R-101 — Type definitions

**Linked finding:** F-1-01..F-1-07 (shared dependency)
**Severity:** P0
**Spec anchor:** "Data Schemas" (SPEC.md §9) and "types/ operation.ts,
snapshot.ts, pin-map.ts, element-info.ts" (SPEC.md §5).

### Ecosystem analysis
Every plugin file imports shared types. Types must land first (write-serial
root). The build module only needs the `PinMap` shape (§9.1) and the
`PinScopeOptions` interface (§6.1); `operation.ts` / `snapshot.ts` /
`element-info.ts` are stubbed now and filled by later rounds.

### Execution plan
**Files to create:** `pinscope/src/types/pin-map.ts`,
`pinscope/src/types/index.ts`, plus stub `operation.ts`, `snapshot.ts`,
`element-info.ts` (type placeholders re-exported from `index.ts`).
**Files to modify:** none.
**Files that MUST remain untouched:** `pinscope/SPEC.md` (frozen).
**Order of operations:** `pin-map.ts` → stubs → `index.ts` barrel.
**Rollback trigger:** `tsc --noEmit` fails on the types directory alone.

### Acceptance criteria
- [ ] `pinscope/src/types/pin-map.ts` exports `PinMapData`, `PinMapEntry`
  matching SPEC §9.1.
- [ ] `tsc --noEmit` passes for `src/types/`.

### Dependencies
None. Wave 1 root.

### Risk assessment
Low. Pure type declarations, no runtime.

---

## Remediation R-102 — Stable ID generator + PinMap

**Linked finding:** F-1-03, F-1-04
**Severity:** P0
**Spec anchor:** "Stable ID strategy" (SPEC.md §6.4), "PinMap manager"
(SPEC.md §6.3), AC-005/AC-006/AC-007/AC-008.

### Ecosystem analysis
`stable-id-generator.ts` computes `file:line:column` keys; `pin-map.ts` owns
`.pinmap.json` load/save and `getOrAssign`. Resolution I-2 from SPEC §18
requires a `reconcile(seenKeys)` method that marks unseen entries
`deleted:true` — this is new vs. the v1.0 code sample and MUST be implemented.

### Execution plan
**Files to create:** `pinscope/src/plugin/stable-id-generator.ts`,
`pinscope/src/plugin/pin-map.ts`.
**Files to modify:** none.
**Files that MUST remain untouched:** `src/types/*` (owned by R-101).
**Order of operations:** `stable-id-generator.ts` → `pin-map.ts`.
**Rollback trigger:** PinMap unit tests fail or IDs are reused.

### Acceptance criteria
- [ ] `getOrAssign` returns monotonically increasing `e_N`; never reuses an ID.
- [ ] `reconcile(seenKeys)` sets `deleted:true` on unseen entries (AC-008).
- [ ] `save()` writes JSON validating against SPEC §9.1 (AC-006).

### Dependencies
R-101 (types).

### Risk assessment
Medium. ID stability is P0 — covered by AC-005/AC-007 tests.

---

## Remediation R-103 — AST transformer

**Linked finding:** F-1-02, F-1-06
**Severity:** P0
**Spec anchor:** "AST transformer" (SPEC.md §6.2), AC-002/003/004/005/011/012.

### Ecosystem analysis
`transformJSX` parses with `@babel/parser` (`jsx`, `typescript`,
`decorators-legacy`), traverses `JSXOpeningElement`, and injects `data-pin`.
Must skip `excludeTags`, existing `data-pin`, and `data-pin-ignore`. Must emit
a source map. `getElementName` handles the three JSX name node kinds.

### Execution plan
**Files to create:** `pinscope/src/plugin/ast-transformer.ts`.
**Files to modify:** none.
**Files that MUST remain untouched:** `pin-map.ts` (R-102 owns it; transformer
only imports it).
**Order of operations:** `getElementName` + `hasAttribute` helpers →
`transformJSX`.
**Rollback trigger:** transformer suite (<50 passing pairs) or no source map.

### Acceptance criteria
- [ ] `data-pin="e_N"` injected on eligible `<button>` (AC-002).
- [ ] `Fragment`/`Suspense` and `data-pin-ignore` elements skipped (AC-003/004).
- [ ] identical `file:line:col` → identical ID across two runs (AC-005).
- [ ] `result.map` is defined (AC-011).

### Dependencies
R-101, R-102.

### Risk assessment
Medium. Babel API surface; mitigated by the ≥50-pair suite (R-106).

---

## Remediation R-104 — Production stripper

**Linked finding:** F-1-05
**Severity:** P0
**Spec anchor:** "Production Stripper" (SPEC.md §6.1 `transformIndexHtml`),
AC-009.

### Execution plan
**Files to create:** `pinscope/src/plugin/production-stripper.ts`.
**Order of operations:** single `stripPins(html)` function removing
`/\sdata-pin="[^"]*"/g`.
**Rollback trigger:** AC-009 unit test fails.

### Acceptance criteria
- [ ] `stripPins` removes every `data-pin="…"` from an HTML string (AC-009).

### Dependencies
None (string-only). Can run in Wave 2.

### Risk assessment
Low.

---

## Remediation R-105 — Plugin entry

**Linked finding:** F-1-01, F-1-06
**Severity:** P0
**Spec anchor:** "Plugin entry" (SPEC.md §6.1), AC-001/AC-013.

### Ecosystem analysis
`pinscope()` returns a Vite `Plugin` with `name:'vite-plugin-pinscope'`,
`enforce:'pre'`, and the `buildStart`/`transform`/`buildEnd`/
`transformIndexHtml` hooks. `transform` gates on `enabled`, `filePattern`,
`excludePattern`. Also create `src/index.ts` re-exporting `pinscope`.

### Execution plan
**Files to create:** `pinscope/src/plugin/index.ts`, `pinscope/src/index.ts`.
**Files that MUST remain untouched:** the other plugin files (this only wires
them together).
**Order of operations:** options defaults → plugin object → `src/index.ts`.
**Rollback trigger:** AC-001 shape test fails.

### Acceptance criteria
- [ ] `pinscope()` returns `{name:'vite-plugin-pinscope', enforce:'pre', …}`
  (AC-001).
- [ ] `transform` returns `null` for non-matching / excluded files (AC-013).
- [ ] `src/index.ts` re-exports `pinscope` (partial AC-091).

### Dependencies
R-102, R-103, R-104.

### Risk assessment
Low–medium. Vite Plugin typing; `vite` is a devDependency.

---

## Remediation R-106 — Test suite + Vitest config

**Linked finding:** F-1-07
**Severity:** P1
**Spec anchor:** "Testing Strategy" (SPEC.md §14), AC-080/AC-084.

### Ecosystem analysis
Vitest config + unit tests. The AST transformer suite needs **≥50** input/
output pairs (AC-080) — generated as a fixture table covering JSX, TSX,
fragments, void elements, member-expression tags, existing-attr cases.

### Execution plan
**Files to create:** `pinscope/vitest.config.ts`,
`pinscope/tests/unit/ast-transformer.test.ts`,
`pinscope/tests/unit/pin-map.test.ts`,
`pinscope/tests/unit/production-stripper.test.ts`,
`pinscope/tests/unit/plugin.test.ts`,
`pinscope/tests/unit/fixtures/transformer-cases.ts`.
**Order of operations:** config → fixtures → per-module test files.
**Rollback trigger:** `npm test` non-zero exit or transformer pairs < 50.

### Acceptance criteria
- [ ] `npm test` exits 0; transformer suite asserts ≥50 pairs (AC-080).
- [ ] `npm run typecheck` (`tsc --noEmit`, strict) exits 0 (AC-084).

### Dependencies
R-101..R-105.

### Risk assessment
Medium. `npm install` must succeed (registry confirmed reachable, PONG 122ms).

---

## Remediation R-107 — Verify APEX integration (Cluster H)

**Linked finding:** F-1-08
**Severity:** P1
**Spec anchor:** "APEX Integration End-State" (SPEC.md §17), AC-100..105.

### Ecosystem analysis
Stage 1 already implemented these. R-107 is verification only — run each AC's
`verify:` check against the framework files committed in `241fd2a`.

### Execution plan
**Files to modify / create:** none — verification only.
**Order of operations:** run the grep/`test -f`/dry-run checks of AC-100..105.
**Rollback trigger:** any check fails → re-open as an implementation finding.

### Acceptance criteria
- [ ] AC-100: `framework/apex-skills/pinscope.md` present, 5 skill headings.
- [ ] AC-101: `sync-to-claude.sh --dry-run` lists `pinscope.md`.
- [ ] AC-102/103: scaffold/ingest steps present in `ui-phase.md`/`ui-review.md`.
- [ ] AC-104: `pinscope` referenced in `architect.md`/`frontend.md`.
- [ ] AC-105: `PinScope` registered in `apex-spec.md`.

### Dependencies
None.

### Risk assessment
Low. Pure verification.
