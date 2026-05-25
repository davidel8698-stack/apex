# PinScope — Test Quality Audit, Round 23

**Auditor:** test-quality auditor (PinScope convergence-loop mode)
**Round:** 23
**Verdict:** **PASS** — 0/5 vacuous-confirmed (Plan-mode `Explore` agent
flagged 5 suspects; on skeptical re-review, **none gate a green AC**).

> **Note on file authorship.** The R23 test-quality auditor sub-agent was
> launched with read-only tools (per the orchestrator's adversarial-audit
> brief). The auditor delivered the verdict and 5 suspect-test rulings
> inline, and the orchestrator's main thread is recording them to disk
> verbatim. Provenance: agent `a3d54b449b3c62a7a`, completed
> 2026-05-25.

## Verdict summary

| Metric | Value |
|---|---|
| Verdict | **PASS** |
| Vacuous-confirmed (out of 5 plan-mode suspects) | **0 / 5** |
| Spot-checked tests | 5 suspects + 6 R20-R21 DoD blocks |
| Mutation watchlist (carry-forward from R22) | 2 (unchanged) |

R22's PASS stands. Zero false-PASS undermines any green AC. The 2 "PARTIAL"
findings below are quality-improvement opportunities, not gating blockers.

## 5 plan-mode suspect rulings

### #1 — `plugin.test.ts` L23-32 / AC-001 (plugin shape)

**Ruling:** PARTIAL.

The 4 `expect(p.buildStart).toBeDefined()` checks ARE presence-only. A
stub plugin `{ buildStart: () => {}, transform: () => {}, ... }` would
pass these. But:

- AC-001's claim is literally "plugin shape" — not "plugin behaves
  correctly."
- `transform` behavior is covered by **AC-013** (same file, L35-65)
  with substantive assertions.
- `transformIndexHtml` behavior is covered by **AC-009** (L303-313).
- `buildStart` / `buildEnd` are pure Vite lifecycle hooks that are not
  invoked anywhere in the test tree — there is no observable behavior
  to assert beyond presence.

**Net:** quality-improvement opportunity (combine AC-001 + AC-013 +
AC-009 into one comprehensive describe block), **not a false-PASS** that
gates a green AC.

### #2 — `deployment.test.ts` L16-19 / AC-090 (export map)

**Ruling:** CONFIRMED-OK-AFTER-CONTEXT.

The `.toBeDefined()` loop is strictly redundant: the sibling
`it.each(subpaths)` at L22-29 reads `pkg.exports[sp]` as a path argument
to `path.join(root, target)`. If `target` were `undefined`, `path.join`
would throw `TypeError` **before** reaching `fs.existsSync`.

This is belt-and-suspenders noise, not vacuous. AC-090 is backed by the
dynamic-import subprocess test (the one R21 cleanup fixed for the
Hebrew-path bug) which actually loads each module.

### #3 — `controls.test.tsx` L67-89 / AC-037 (TopBar ↔ StatePanel)

**Ruling:** CONFIRMED-OK-AFTER-CONTEXT (actually SUBSTANTIVE).

The plan-mode hypothesis ("TopBar that hardcoded `'hover'` would pass")
**FAILS** under skeptical re-read:

- L81 (PRE-click): `expect(stateField()).toContain('none')` — would FAIL
  if TopBar hardcoded `'hover'`.
- L87 (POST-click): `expect(stateField()).toContain('hover')` — passes.
- L88 (POST-click): `expect(stateField()).not.toContain('none')` —
  passes.

The pre/post pairing is the discriminator that kills the hardcoded-string
mutant. Bidirectional, mutation-resistant.

### #4 — `controls.test.tsx` L225-251 / AC-053 (HistoryManager append)

**Ruling:** PARTIAL.

The plan-mode hypothesis ("entry with only `raw_input` would pass") is
correct in isolation: this single `it` only asserts `entry.raw_input` and
call count. BUT the adjacent R-20-05 disjunct tests in the same describe
block (L253-276 and L278-302) DO assert:
- `entry?.parsed === null`
- `entry?.result === 'applied'`

And the R-18-01 ownership test (L318-367) round-trips the full
persistence shape through the dev-server route.

**Net:** AC-053 verdict is backed across the describe block. The
isolated L225-251 `it` is loose, but the AC is not at risk. Recommend
symmetry-tightening to fold the parsed/result asserts into L225-251.

### #5 — `roundtrip.test.ts` L63-69 / AC-107 (round-trip)

**Ruling:** CONFIRMED-OK-AFTER-CONTEXT.

L64 `expect(op.operations).toBeDefined()` IS redundant: L65
`.toHaveLength(1)` on `undefined` throws.

The substantive assertions are:
- L62 — `pin === 'e_47'`
- L63 — `request_type === 'operation'`
- L65 — `.toHaveLength(1)`
- L67 — `item.value ?? item.delta` defined (kills empty-item mutant
  `{ operations: [{}] }`)
- L68-L69 — 1-round predicate

Plus the negative branch at L81-93 (under-specified query) provides
red/green pairing.

## R20-R21 DoD re-check (second skeptical pass)

The 6 R20-R21 DoD describe blocks at `tests/unit/runtime/pinscope.test.tsx`
L33-616:

| Block | Coverage |
|---|---|
| R-20-01 — VoidBadges mount | SUBSTANTIVE (DOM landmark `[data-pinscope-void-badges]` + `[data-void-badge="e_9"]` assertions) |
| R-20-02 — RuntimePinObserver lifecycle | SUBSTANTIVE (mount/post-mount/post-unmount triad; disconnect-on-unmount asserted) |
| R-20-03 — Shift+P/C toggles | SUBSTANTIVE (bidirectional fire→fire assertions) |
| R-21-01 — touch + responsive collapse | SUBSTANTIVE (real TouchEvent dispatch + viewport-resize) |
| R-21-02 — Shadow-DOM + InfoPanel | SUBSTANTIVE (DOM landmark `[data-pin-shadow]` + InfoPanel `isShadowLimited` read) |
| R-21-03 — heavy-page degrade | SUBSTANTIVE (throttle frame count assertion + skipbadge stamping) |

All re-confirmed SUBSTANTIVE on skeptical second pass. Each uses
bidirectional/triadic assertions (before/after toggle, mount/post-mount/
post-unmount, positive/negative pairings) that rule out the obvious
constant-value mutants.

## Mutation watchlist (carry-forward from R22)

Both pre-R21 mutation survivors remain on watchlist:
- `InfoPanel.tsx:22` — SSR-guard (`localStorage === 'undefined'`)
- `useHoveredElement.ts:51` — pin-guard (`!pinned || !pinId`)

Re-confirmation: these are coverage margins on branches **no vitest-tag
AC asserts**. Promote to OPEN only if a future round expands the AC
surface to cover them.

## Impact on R23 scope

The R23 remediation plan included F-23-02 (strengthen AC-001 plugin
tests), F-23-03 (strengthen AC-091/092 wrapper tests), and F-23-04
(strengthen AC-037/053/107 vacuous tests). **Per this audit**:

- **F-23-02** (AC-001) — PARTIAL. AC-001 itself is not falsely-PASS, but
  the test surface could be deduplicated (AC-001 + AC-013 + AC-009 share
  scope). **Drop from R23**; record as polish for a future round.
- **F-23-03** (AC-091/092 wrapper tests) — still real (the audit didn't
  re-evaluate these specifically; the original plan-mode finding stands).
- **F-23-04** (AC-037/053/107 vacuous tests) — **mostly REFUTED**.
  AC-037 is SUBSTANTIVE. AC-107 is OK. Only AC-053 has a quality-improvement
  case (PARTIAL). **Drop from R23**; record AC-053 symmetry-tightening as
  polish.

**R23 scope reduces** from 6 R-items to **4**: F-23-01 (AC-073 KB
assertion), F-23-03 (AC-091/092 wrapper contracts), F-23-05 (dead
shortcuts), F-23-06 (dormant utility cleanup). This is the value of
adversarial audit — not every alarm fires correctly, and a rigorous
re-check protects against overcorrection.

## Notes

- The auditor sub-agent was launched with read-only tools by the
  orchestrator. The orchestrator wrote this file from the agent's
  inline verdict. The verdict reasoning is the auditor's verbatim;
  formatting is the orchestrator's.
- TEST-AUDIT-R22 conclusion remains valid for the ACs it covered;
  this audit re-evaluates the 5 plan-mode flags + R20-R21 DoD blocks.
