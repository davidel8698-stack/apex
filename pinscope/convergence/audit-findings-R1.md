# PinScope Audit — PS-R1

> **Round:** PS-R1 (first convergence round)
> **North-Star:** `pinscope/SPEC.md` v2.0.0 (FROZEN)
> **Method:** diff every Appendix-A acceptance criterion against the
> `pinscope/` reality tree.
> **Date:** 2026-05-21
> **Auditor stance:** findings are hypotheses, not facts (APEX learning AP-006).

## Reality baseline

`pinscope/` currently contains only Stage 0 + Stage 1 scaffolding:
`SPEC.md`, `README.md`, `package.json`, `tsconfig.json`, `.gitignore`,
`convergence/STATUS.md`.

Re-read check:
- `ls pinscope/src` → **No such file or directory**
- `ls pinscope/tests` → **absent**
- `ls pinscope/examples` → **absent**

## Gap summary

All **69** acceptance criteria are `OPEN`. The package is at skeleton stage;
the convergence gap is ~100% of the implementation surface.

## Findings (grouped by module cluster)

### Cluster A — Build-time module (AC-001..013) — **PS-R1 SCOPE**
- **F-1-01** · AC-001 · P0 — `src/plugin/index.ts` absent; no `pinscope()`
  plugin factory. *re-read:* `test -f pinscope/src/plugin/index.ts` → absent.
- **F-1-02** · AC-002,003,004,005,011,012 · P0 — `src/plugin/ast-transformer.ts`
  absent; no JSX `data-pin` injection. *re-read:*
  `test -f pinscope/src/plugin/ast-transformer.ts` → absent.
- **F-1-03** · AC-006,007,008 · P1 — `src/plugin/pin-map.ts` absent; no PinMap
  persistence. *re-read:* `test -f pinscope/src/plugin/pin-map.ts` → absent.
- **F-1-04** · AC-005 · P0 — `src/plugin/stable-id-generator.ts` absent.
  *re-read:* `test -f pinscope/src/plugin/stable-id-generator.ts` → absent.
- **F-1-05** · AC-009 · P0 — `src/plugin/production-stripper.ts` absent; no
  prod `data-pin` strip. *re-read:* file absent.
- **F-1-06** · AC-013 · P1 — file-pattern / exclude-pattern gating unimplemented
  (lands inside F-1-01).
- **F-1-07** · AC-080,084 · P1 — no `tests/`, no Vitest config, no AST
  transformer suite (≥50 pairs required). *re-read:* `ls pinscope/tests` → absent.

### Cluster H — APEX integration (AC-100..107) — **PS-R1: VERIFY ONLY**
Implemented in Stage 1 (commit `241fd2a`). PS-R1 runs each `verify:` check and
closes those that pass:
- **F-1-08** · AC-100..105 · P1 — needs verification, not implementation.
  *re-read:* `test -f framework/apex-skills/pinscope.md` → present;
  `grep -l PinScope apex-spec.md` → present.
- AC-106 (`/apex:health-check`) and AC-107 (end-to-end session) require a live
  APEX run / example app — **deferred** to a later round.

### Deferred clusters (scheduled, not in PS-R1)
- **Cluster B** — Runtime core (AC-020..027) → PS-R2
- **Cluster C** — Components (AC-030..043) → PS-R3
- **Cluster D** — Operation protocol (AC-050..054) → PS-R3/R4
- **Cluster E** — Edge cases (AC-060..065) → PS-R4
- **Cluster F** — Performance (AC-070..076) → travels with each owning module
- **Cluster G** — Deployment / examples (AC-090..092, AC-010, AC-082, AC-083)
  → PS-R2+ (AC-010 needs `examples/vite-react`)

## PS-R1 scope decision

Per the SPEC dependency order ("build module before runtime"), PS-R1 closes
**Cluster A** (the build-time module — the dependency root of the whole
package) and **verifies Cluster H**. This is a self-contained, fully
unit-testable slice with no runtime/DOM dependency.

**Expected PS-R1 closures:** AC-001–009, AC-011–013, AC-080, AC-084 (≈15 ACs).
**Not closed by PS-R1:** AC-010 (needs an example app), all deferred clusters.

## Anti-pattern guard

Per AP-006 ("The Unchecked Audit"): each finding carries a re-read check. The
remediation executor MUST re-confirm the gap exists in current code before
acting — do not trust this audit blindly.
