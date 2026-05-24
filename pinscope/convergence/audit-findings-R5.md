# PinScope Audit — PS-R5

> **Round:** PS-R5 · **North-Star:** `pinscope/SPEC.md` v2.0.0 · **Date:** 2026-05-21
> **Method:** re-audit — diff Appendix-A ACs against `pinscope/` after PS-R4.

## Reality baseline (post PS-R4)
38 ACs CLOSED (55%). 188 tests green. No `examples/`; no `SnapshotManager`;
no Playwright integration suite.
*Re-read:* `ls pinscope/examples` → No such file or directory.

## Carry-forward verification (AP-006)
PS-R1–R4 closures re-confirmed: `npm test` green (188), typecheck clean,
`size-limit` 1.21 kB.

## Findings

| Finding | ACs | Sev | Gap (re-read check) |
|---------|-----|-----|---------------------|
| F-5-01 | AC-010, AC-074 | P0 | no `examples/vite-react/` — prod-build cleanliness unproven |
| F-5-02 | AC-042 | P2 | `managers/SnapshotManager.ts` absent — no §9.2 Snapshot |
| F-5-03 | AC-075 | P2 | snapshot performance (200 elements) unmeasured |
| F-5-04 | AC-082 | P1 | no Playwright integration suite |

## PS-R5 scope + verification reality
Build `examples/vite-react` (a real Vite + React app instrumented with
PinScope), the Snapshot system, and author the Playwright integration suite.

- **Closeable headless:** AC-010 (`vite build` of the example → `grep` `dist/`),
  AC-074 (prod overhead = 0, proven at the artifact level — the SPEC's own
  AC-074 note says it is "covered by AC-010 at artifact level"), AC-042 +
  AC-075 (Snapshot — happy-dom integration / perf).
- **BLOCKED:** AC-082 — the Playwright integration suite is *authored* this
  round as a CI deliverable, but Playwright cannot execute here
  (`cdn.playwright.dev` not allowlisted). Moves to `BLOCKED`.

**Expected closures:** AC-010, AC-042, AC-074, AC-075 (4) → 42/69 ≈ 61%.
**Expected BLOCKED:** AC-082 (1).
