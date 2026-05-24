# PinScope Remediation Plan — PS-R3

> Per `framework/docs/REMEDIATION-STYLE.md`. Scope: Operation Protocol
> (Cluster D). Source of findings: `audit-findings-R3.md`.

---

## Remediation R-301 — Operation parser + shortcut resolution

**Linked finding:** F-3-01, F-3-02
**Severity:** P0
**Spec anchor:** "Operation Protocol" (SPEC §11), AC-050/AC-051/AC-081.

### Ecosystem analysis
`operation-parser.ts` tokenises the §11 grammar into a discriminated
`ParsedCommand` union and throws a typed `OperationParseError` on malformed
input. `property-shortcuts.ts` resolves `padding-y`, `bg`, `radius`, … to CSS
property names. Pure functions — no DOM, fully unit-testable.

### Execution plan
**Files to create:** `src/runtime/parsers/operation-parser.ts`,
`src/runtime/parsers/property-shortcuts.ts`.
**Files that MUST remain untouched:** `src/types/operation.ts` (the parser
imports `OperationKind` from it).
**Order of operations:** `property-shortcuts.ts` → `operation-parser.ts`.
**Rollback trigger:** parser suite < 30 cases or any grammar form unparsed.

### Acceptance criteria
- [ ] All six §11 grammar forms parse; malformed input throws
  `OperationParseError` (AC-050).
- [ ] Each shortcut property resolves to its CSS equivalent (AC-051).
- [ ] Parser suite ≥ 30 cases (AC-081).

### Dependencies
None — Wave 1 root.

### Risk assessment
Low. Pure string processing.

---

## Remediation R-302 — Operation builder

**Linked finding:** F-3-03
**Severity:** P0
**Spec anchor:** "Operation" schema (SPEC §9.3), AC-052.

### Ecosystem analysis
`operation-builder.ts` turns a `ParsedCommand` (operation / class / query
kinds) plus an element `BuildContext` into an `Operation` object conforming to
§9.3. `select` / `measure` / `snapshot` are local actions, not Claude
payloads — the builder rejects them with a typed error.

### Execution plan
**Files to create:** `src/runtime/parsers/operation-builder.ts`.
**Order of operations:** `BuildContext` type → `buildOperation`.
**Rollback trigger:** schema validation fails on the 10 samples.

### Acceptance criteria
- [ ] `buildOperation` output validates against the §9.3 schema for operation,
  class, and query commands (AC-052).

### Dependencies
R-301.

### Risk assessment
Low.

---

## Remediation R-303 — History + Claude bridge

**Linked finding:** F-3-04
**Severity:** P1
**Spec anchor:** "History" schema (SPEC §9.4), "CommandBar" (SPEC §8.6),
behavioural flow C, AC-053.

### Ecosystem analysis
`HistoryManager` is storage-agnostic (injected `HistoryStore`; `runtime/` stays
free of `node:fs`). `ClaudeBridge.send` copies the Operation JSON to the
clipboard and appends a §9.4 history entry. The AC-053 integration test injects
a file-backed store and a mock clipboard, then asserts both.

### Execution plan
**Files to create:** `src/runtime/managers/HistoryManager.ts`,
`src/runtime/managers/ClaudeBridge.ts`.
**Order of operations:** `HistoryManager` → `ClaudeBridge`.
**Rollback trigger:** AC-053 integration test fails.

### Acceptance criteria
- [ ] `ClaudeBridge.send` writes the JSON to the clipboard and appends a
  history entry capped at 1000 (AC-053).

### Dependencies
R-302.

### Risk assessment
Low–medium. Clipboard is injected, not the real `navigator.clipboard`.

---

## Remediation R-304 — Autocomplete + verification

**Linked finding:** F-3-05, F-3-06
**Severity:** P2
**Spec anchor:** "CommandBar autocomplete" (SPEC §8.6), AC-054/AC-072.

### Ecosystem analysis
`autocomplete.ts` suggests pins/properties for a partial command. Plus the
verification suites — parser perf (AC-072, < 4 ms) and autocomplete perf
(AC-054, < 50 ms).

### Execution plan
**Files to create:** `src/runtime/parsers/autocomplete.ts`,
`tests/unit/operation-parser.test.ts`, `tests/unit/property-shortcuts.test.ts`,
`tests/unit/operation-builder.test.ts`, `tests/unit/operation-perf.test.ts`,
`tests/unit/claude-bridge.test.ts`.
**Rollback trigger:** `npm test` non-zero, or any PS-R1/R2 test regresses.
**Circuit breaker:** no green `npm test` after 3 attempts → halt.

### Acceptance criteria
- [ ] Autocomplete returns pin/property suggestions (AC-054 logic).
- [ ] Parse < 4 ms (AC-072); autocomplete < 50 ms (AC-054).
- [ ] All 100 PS-R1/R2 tests still green.

### Dependencies
R-301, R-302, R-303.

### Risk assessment
Low.
