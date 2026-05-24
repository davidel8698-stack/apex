# PinScope Wave Map — PS-R1

> Dependency-ordered, write-serial-safe execution plan for PS-R1.
> **Rule:** one file = one owner per wave (no two R-items write the same file).
> Source: `REMEDIATION-PLAN-R1.md`.

## Wave order

| Wave | R-items | Rationale |
|------|---------|-----------|
| **W1** | R-101, R-107 | Type definitions (dependency root) + APEX-integration verification (independent, no files touched). |
| **W2** | R-102, R-103, R-104, R-105 | Build-module source. Disjoint file ownership — safe to treat as one wave. Internal order: R-102 → R-103 → R-104 → R-105 (each imports the prior). |
| **W3** | R-106 | Test suite + Vitest config + `npm install` + run tests/typecheck. Depends on all source. |

## File ownership matrix (no conflicts)

| File | Owner | Wave |
|------|-------|------|
| `src/types/pin-map.ts`, `src/types/index.ts`, `src/types/{operation,snapshot,element-info}.ts` | R-101 | W1 |
| `src/plugin/stable-id-generator.ts`, `src/plugin/pin-map.ts` | R-102 | W2 |
| `src/plugin/ast-transformer.ts` | R-103 | W2 |
| `src/plugin/production-stripper.ts` | R-104 | W2 |
| `src/plugin/index.ts`, `src/index.ts` | R-105 | W2 |
| `vitest.config.ts`, `tests/unit/**` | R-106 | W3 |
| _(no files)_ | R-107 | W1 |

No file appears under two owners → write-serial safe.

## Per-wave exit criteria

- **W1 done:** `tsc --noEmit` passes on `src/types/`; R-107 checks all pass
  (AC-100..105 verified).
- **W2 done:** all `src/plugin/*` + `src/index.ts` created; `tsc --noEmit`
  passes for `src/`.
- **W3 done:** `npm install` succeeds; `npm test` exits 0 with the AST
  transformer suite asserting ≥50 pairs; `npm run typecheck` exits 0.

## Verification (post-wave)

`verifier` + `critic` re-run the `verify:` check of every AC the round claims
to close. A claim without a passing check stays `OPEN` in `STATUS.md`.

## Circuit breaker

If W3 cannot reach a green `npm test` after 3 attempts, halt and escalate
(`circuit-breaker.sh` semantics) — do not mark the round converged.
