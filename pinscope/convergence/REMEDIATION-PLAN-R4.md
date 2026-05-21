# PinScope Remediation Plan — PS-R4

> Per `framework/docs/REMEDIATION-STYLE.md`. Scope: deployment surface +
> performance. Source of findings: `audit-findings-R4.md`.

---

## Remediation R-401 — Next.js + Webpack wrappers

**Linked finding:** F-4-01, F-4-02
**Severity:** P1
**Spec anchor:** "Deployment & Integration" (SPEC §15), AC-090/AC-092.

### Ecosystem analysis
`withPinScope` wraps a Next.js config (spreads it, composes any existing
`webpack` fn). `PinScopeWebpackPlugin` is a webpack plugin class with `apply`.
Both complete the `package.json` export map (`pinscope/next`,
`pinscope/webpack`); deep instrumentation is a later round — the AC only
requires importable, valid config objects.

### Execution plan
**Files to create:** `src/plugin/next.ts`, `src/plugin/webpack.ts`.
**Files that MUST remain untouched:** `src/plugin/index.ts` (these import
`PinScopeOptions` from it).
**Order of operations:** `next.ts` → `webpack.ts`.
**Rollback trigger:** `tsc --noEmit` fails.

### Acceptance criteria
- [ ] `withPinScope(config)` returns a config object preserving the input
  and exposing a `webpack` function (AC-092).
- [ ] `PinScopeWebpackPlugin` instances expose an `apply` method (AC-092).

### Dependencies
None — Wave 1 root.

### Risk assessment
Low. Thin wrappers, no framework runtime needed.

---

## Remediation R-402 — dist build + size-limit + verification

**Linked finding:** F-4-02, F-4-03, F-4-04, F-4-05
**Severity:** P0
**Spec anchor:** "Performance Requirements" (SPEC §13), AC-090/073/070/071.

### Ecosystem analysis
`npm run build` (`tsc`) emits `dist/`, making every export-map target real.
`size-limit` (+ `@size-limit/preset-small-lib`) measures the dev runtime
bundle against the < 80 KB budget (react/react-dom ignored as peers). Two
happy-dom perf tests measure `<PinScope/>` mount and the hover per-frame cost.

### Execution plan
**Files to modify:** `package.json` (add `size-limit` block + devDeps).
**Files to create:** `tests/unit/deployment.test.ts` (AC-090, AC-092),
`tests/unit/runtime/perf.test.tsx` (AC-070, AC-071).
**Order of operations:** add deps → `npm install` → `npm run build` →
`size-limit` config → tests.
**Rollback trigger:** `npm run build` non-zero, `size-limit` over budget, or
any PS-R1–R3 test regresses.
**Circuit breaker:** no green verification after 3 attempts → halt.

### Acceptance criteria
- [ ] `npm run build` emits `dist/`; every `exports` subpath resolves to an
  existing file and dynamically imports (AC-090).
- [ ] `npx size-limit` exits 0 under the 80 KB budget (AC-073).
- [ ] `<PinScope/>` mount < 50 ms (AC-070); hover per-frame work < 8 ms (AC-071).
- [ ] All 176 PS-R1–R3 tests still green.

### Dependencies
R-401.

### Risk assessment
Medium. `size-limit` install + `tsc` emit; registry reachable.
