# PinScope Audit — PS-R2

> **Round:** PS-R2 · **North-Star:** `pinscope/SPEC.md` v2.0.0 · **Date:** 2026-05-21
> **Method:** re-audit — diff Appendix-A ACs against `pinscope/` after PS-R1.

## Reality baseline (post PS-R1)
Build-time module complete and tested — 20 ACs CLOSED (29%). `src/runtime/`
does not exist. *Re-read:* `ls pinscope/src/runtime` → No such file or directory.

## Carry-forward verification (AP-006 — no unchecked claims)
PS-R1's CLOSED ACs were re-confirmed: `npm test` green (86 tests),
`npm run typecheck` clean. No regression. The 20 closures stand.

## Findings — Cluster B (runtime core) + AC-030, AC-091

| Finding | ACs | Sev | Gap (re-read check) |
|---------|-----|-----|---------------------|
| F-2-01 | AC-020,021,022 | P0 | `src/runtime/PinScope.tsx` absent |
| F-2-02 | AC-023 | P0 | `src/runtime/components/PinBadges.tsx` absent |
| F-2-03 | AC-026,027 | P1 | `useHoveredElement` + `element-walker` absent |
| F-2-04 | AC-030 | P1 | `src/runtime/components/InfoPanel.tsx` absent |
| F-2-05 | AC-091 | P1 | `src/index.ts` does not export `PinScope` / `useDevState` |

## PS-R2 scope + verification reality

PS-R2 builds the **runtime foundation**: the `<PinScope/>` root, `PinBadges`,
`useHoveredElement` (+ an extracted `element-walker`), `InfoPanel`
(Dimensions / Spacing / Typography), `useDevState`, and supporting hooks/styles.

**Honest verification constraint.** AC-023 and AC-030 carry **Playwright**
`verify:` methods (real CSS `::before` rendering, real computed-style hover).
Playwright + a browser binary are not provisioned this round, so:

- **Closeable in PS-R2** (unit / React Testing Library / happy-dom):
  AC-020, AC-021, AC-022, AC-026, AC-027, AC-091.
- **Built but NOT closed** — AC-023, AC-030. The components are implemented
  and unit-tested for render logic, but their defined `verify:` (Playwright)
  has not run. They stay `OPEN` — the loop never claims an AC without its own
  passing check.

AC-024, AC-025 (P4) and the remainder of Cluster C are out of PS-R2 scope.

## Expected closures
AC-020, AC-021, AC-022, AC-026, AC-027, AC-091 (6 ACs) → 26/69 ≈ 38%.
