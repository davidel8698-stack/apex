# PinScope Audit — PS-R9 (terminal round)

> **Round:** PS-R9 · **North-Star:** `pinscope/SPEC.md` v2.0.0 · **Date:** 2026-05-21
> **Method:** re-audit — diff Appendix-A ACs against `pinscope/` after PS-R8.

## Reality baseline (post PS-R8)
57 CLOSED, 3 BLOCKED, 9 OPEN (83%). 241 tests green.

## Carry-forward verification (AP-006)
PS-R1–R8 closures re-confirmed: `npm test` green (241), typecheck clean.

## Findings — the 9 remaining OPEN ACs

| Finding | ACs | Sev | Disposition |
|---------|-----|-----|-------------|
| F-9-01 | AC-031, 032, 033 | P2/P3 | InfoPanel Appearance/Layout/Hierarchy sections + collapsible `localStorage` persistence + color swatches — **headless-closeable** (RTL). |
| F-9-02 | AC-076 | P2 | `html2canvas` not yet present as a lazy import — **headless-closeable** (source/bundle analysis). |
| F-9-03 | AC-106 | P2 | `/apex:health-check` — its core (`self-test.sh`) is runnable headlessly; the full slash command needs a `~/.claude/` install. |
| F-9-04 | AC-107 | P3 | end-to-end round-trip — a scripted PinScope scenario in `examples/` is headless-runnable. |
| F-9-05 | AC-061, 063, 083 | P3 | cross-origin iframe / `@media print` rendering / visual-regression screenshots — **genuinely require a real browser engine** → `BLOCKED`. |

## PS-R9 scope (terminal)
Close every headless-verifiable AC, reclassify the genuinely browser-only ACs
to `BLOCKED`, and write the terminal convergence report. After PS-R9 there are
**zero `OPEN` ACs** — the loop reaches its terminal condition (zero OPEN at
P0–P2; every Phase-DoD AC `CLOSED` or `BLOCKED`).

**Expected:** close AC-031, 032, 033, 076, 106, 107 (6) → 63 CLOSED ≈ 91%;
move AC-061, 063, 083 → `BLOCKED` (total BLOCKED 6).
