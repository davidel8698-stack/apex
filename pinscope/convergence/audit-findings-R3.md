# PinScope Audit — PS-R3

> **Round:** PS-R3 · **North-Star:** `pinscope/SPEC.md` v2.0.0 · **Date:** 2026-05-21
> **Method:** re-audit — diff Appendix-A ACs against `pinscope/` after PS-R2.

## Reality baseline (post PS-R2)
26 ACs CLOSED (38%). Build module + runtime foundation complete, 100 tests
green. `src/runtime/parsers/` and `src/runtime/managers/` do not exist.
*Re-read:* `ls pinscope/src/runtime/parsers` → No such file or directory.

## Carry-forward verification (AP-006)
PS-R1+R2 closures re-confirmed: `npm test` green (100), `npm run typecheck`
clean. No regression.

## F-3-ENV — Environment constraint finding (P1, process)
The Playwright browser binary cannot be provisioned in this environment:
`npx playwright install chromium` → `403 'Host not in allowlist'` for
`cdn.playwright.dev`; no system browser on PATH. **Consequence:** the ~19 ACs
whose `verify:` is Playwright (AC-023, 024, 030–041, 043, 063, 064, 082, 083)
cannot be verified here. The loop will:
1. still **build** their implementations and **author** the Playwright specs
   (real deliverables for a browser-capable CI),
2. mark such ACs `BLOCKED` (not `CLOSED`) in `STATUS.md` once built+authored —
   never claimed from a weak proxy,
3. converge every **headless-verifiable** AC (unit / RTL / happy-dom / node /
   `vite build` / `size-limit`).
Full convergence (`zero OPEN P0–P2`) is therefore **not reachable in this
environment**; the achievable maximum is ~50/69. The terminal closure will
enumerate the `BLOCKED` set and what unblocks it (a browser-capable CI).

## Findings — Cluster D (Operation Protocol), all headless-verifiable

| Finding | ACs | Sev | Gap (re-read check) |
|---------|-----|-----|---------------------|
| F-3-01 | AC-050, AC-081 | P0 | `src/runtime/parsers/operation-parser.ts` absent |
| F-3-02 | AC-051 | P1 | shortcut-property resolution absent |
| F-3-03 | AC-052 | P0 | `operation-builder.ts` absent — no §9.3 Operation object |
| F-3-04 | AC-053 | P1 | `managers/HistoryManager.ts` + `ClaudeBridge.ts` absent |
| F-3-05 | AC-054 | P2 | command autocomplete absent |
| F-3-06 | AC-072 | P1 | operation-parse performance unmeasured |

## PS-R3 scope
Build the Operation Protocol logic (§11 grammar parser, §9.3 builder, shortcut
resolution, autocomplete, history + clipboard bridge). All six findings are
**headless-verifiable** (unit / perf / node integration).

**Expected closures:** AC-050, AC-051, AC-052, AC-053, AC-054, AC-072, AC-081
(7 ACs) → 33/69 ≈ 48%. The CommandBar *component* (AC-038, Playwright) is not
built this round — only the protocol logic beneath it.
