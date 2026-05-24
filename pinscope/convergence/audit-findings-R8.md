# PinScope Audit — PS-R8

> **Round:** PS-R8 · **North-Star:** `pinscope/SPEC.md` v2.0.0 · **Date:** 2026-05-21
> **Method:** re-audit — diff Appendix-A ACs against `pinscope/` after PS-R7.

## Reality baseline (post PS-R7)
51 CLOSED, 3 BLOCKED, 15 OPEN (74%). 213 tests green. The §8 control
components (TopBar, CommandBar, StatePanel, SelectionManager), keyboard
shortcuts, and touch handling are unimplemented.

## Carry-forward verification (AP-006)
PS-R1–R7 closures re-confirmed: `npm test` green (213), typecheck clean.

## Findings — Cluster C control surface

| Finding | ACs | Sev | Gap (re-read check) |
|---------|-----|-----|---------------------|
| F-8-01 | AC-041 | P1 | `managers/SelectionManager.ts` absent |
| F-8-02 | AC-037 | P2 | `components/TopBar.tsx` absent |
| F-8-03 | AC-038 | P1 | `components/CommandBar.tsx` absent |
| F-8-04 | AC-040 | P2 | `components/StatePanel.tsx` absent |
| F-8-05 | AC-043 | P2 | `hooks/useKeyboardShortcuts.ts` absent |
| F-8-06 | AC-064 | P2 | touch tap/long-press + compact-viewport logic absent |

## PS-R8 scope
Build the control surface. All six properties are RTL / happy-dom verifiable
(URL-hash selection, field rendering + pin count, keyboard focus/blur, the
`[data-state-override]` attribute, the shortcut table, the long-press clock).

**Expected closures:** AC-037, AC-038, AC-040, AC-041, AC-043, AC-064 (6) →
57/69 ≈ 83%.
