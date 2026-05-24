# Spec-Conformance Audit — PinScope PS-R15

> Agent: `spec-auditor` · STEP 1A of round N=15 · read-only
> North-Star: `pinscope/SPEC.md` v2.0.0 (FROZEN, hash `sha256:1779…7c7a45`)
> Machine input: `ac-results-R15.json` — 62 PASS · 7 UNAVAILABLE · 0 FAIL
> Independent suite run this round: 27 files, **257 tests, all pass**.

## Round summary

The machine reports zero `FAIL`, so STEP 1–4 produced **no AC findings** and
**no regressions** (all 62 previously-`CLOSED` ACs still `PASS`). But a tree
where `metric.open == 0` is not a converged product. The STEP 5 free
investigation — a 12-axis sweep of the whole spec against the code — found
that **the assembled `<PinScope/>` is hollow**. Only the inspection layer
(`PinBadges` + `InfoPanel`) is wired into the shipping root. `Rulers`,
`Crosshair`, `GridOverlay`, `TopBar`, `CommandBar`, `MeasurementTool`,
`StatePanel`, `VoidBadges`, the `useKeyboardShortcuts` hook and every manager
(`SelectionManager`, `SnapshotManager`, `RuntimePinObserver`, `ClaudeBridge`)
exist as files, pass their isolated AC tests, and are **never mounted or
invoked by the product**. Appendix A never asserts the §7.1 HUD assembly, so
the matrix sails past it: the loop's 90% figure is a **false convergence**.
11 off-matrix investigation findings follow (9 CONFIRMED, 2 SUSPECTED). This is
the 15th round; rounds 11–14 recorded NO_FINDINGS — this round did not
rubber-stamp them, it re-read the tree and the central gap was missed because
no AC names it.

---

## AC findings (STEP 1–4)

**None.** `ac-results-R15.json` reports 0 `FAIL`; there is no machine-flagged
gap to re-confirm, and no `CLOSED` AC regressed.

---

## Investigation findings (STEP 5) — grouped by severity

### P1

**F-15-01 · CONFIRMED · axis: Runtime isolation / Inspection+Measurement+Control layers / Phase DoD**
`<PinScope/>` mounts only `PinBadges` + `InfoPanel`. SPEC §7.1 requires the
root to portal-render the full HUD tree (PinBadges, Rulers, Crosshair,
GridOverlay, InfoPanel, TopBar, CommandBar). The remaining components, the
`useKeyboardShortcuts` hook and all managers are dead code at runtime — the
§16 P2 DoD ("4 grid modes render; rulers align; ≥95% shortcuts functional"),
P3 DoD ("operations via CommandBar") and P4 DoD ("measurement") are met only
by isolated tests, never by the product. This is the end-to-end break STEP 5
exists to catch.
*re_read:* `grep -rln 'Rulers|Crosshair|GridOverlay|TopBar|CommandBar|MeasurementTool|StatePanel|VoidBadges' pinscope/src/runtime/PinScope.tsx` → no matches; Read `pinscope/src/runtime/PinScope.tsx` (`PinScopeHud` body is `<PinBadges/>` + `<InfoPanel/>` only); `grep -rln 'useKeyboardShortcuts' pinscope/src` → only its own file; `grep -rln 'SelectionManager|SnapshotManager|RuntimePinObserver' pinscope/src` → each appears only in its own file.

### P2

**F-15-02 · CONFIRMED · axis: Integration surface / public API**
`PinScopeProps` declares only `enabled?` and `hudPosition?`; SPEC §7.1 also
specifies `defaultGridMode?` and `shortcutsEnabled?`.
*re_read:* Read `pinscope/src/runtime/PinScope.tsx` lines 9-14 — `interface PinScopeProps { enabled?: boolean; hudPosition?: 'left' | 'right'; }`.

**F-15-03 · CONFIRMED · axis: Runtime isolation (§7.1 HUD-hidden state)**
No HUD-hidden branch and no `FloatingToggle` component. SPEC §7.1: when the
HUD is hidden, `<PinScope/>` renders only a `FloatingToggle`.
*re_read:* `grep -rln 'FloatingToggle' pinscope/src` → no matches; Read `pinscope/src/runtime/PinScope.tsx` — `PinScopeHud` has no visibility state.

**F-15-04 · CONFIRMED · axis: Edge cases / runtime isolation (§12 hostile CSS, z-index)**
Only `[data-pinscope-ui] { outline: none !important; }` uses `!important`. The
badge `::before` rules (background, z-index 2147483645/6/7, content, padding)
carry none, so hostile / higher-specificity host CSS can override the badge —
violating §12 "hostile CSS (PinScope styles use `!important`)".
*re_read:* Read `pinscope/src/runtime/styles/badges.css.ts` — single `!important` hit on the outline rule; all `[data-pin]::before` declarations unqualified.

**F-15-05 · CONFIRMED · axis: Measurement layer (§8.2 Rulers)**
`Rulers.tsx` emits one uniform tick `interval` (default 100) and renders no
corner element. SPEC §8.2 requires ticks at 10/50/100/200 px and a corner with
live mouse coords. AC-034 checks only the 100px ticks.
*re_read:* Read `pinscope/src/runtime/components/Rulers.tsx` — `ticks(extent, interval)` loops one interval; no multi-scale logic; no corner-coords element in the tree.

**F-15-06 · CONFIRMED · axis: Measurement layer (§8.3 Crosshair)**
`Crosshair.tsx` hides only over `[data-pinscope-ui]`. SPEC §8.3 requires it
also disabled in measurement mode and when the HUD is hidden.
*re_read:* Read `pinscope/src/runtime/components/Crosshair.tsx` — `onMove` only checks `target.closest('[data-pinscope-ui]')`; no measurement-mode / HUD-visibility guard.

**F-15-07 · CONFIRMED · axis: Operation protocol / Control layer (§8.6 CommandBar)**
`CommandBar.tsx` is a fixed 40px bar with no focus expand-to-120px, no `Tab`
autocomplete branch (and no use of `parsers/autocomplete.ts`), and its history
is a per-mount `useRef` never persisted to `.pinscope/history.json` —
`HistoryManager` (MAX_ENTRIES=1000) exists but `CommandBar` never wires to it.
SPEC §8.6 requires all three.
*re_read:* Read `pinscope/src/runtime/components/CommandBar.tsx` — `style.height` constant 40; `onInputKey` has no `Tab` case; `history` is `useRef<string[]>([])`; `grep -rln 'history.json' pinscope/src` → no matches.

**F-15-08 · CONFIRMED · axis: State layer (§8.8 StatePanel)**
`StatePanel.tsx` `applyStateOverride` only toggles `<html data-state-override>`.
SPEC §8.8 requires it to auto-generate override rules by scanning host
stylesheets for `:hover`/`:focus`/`:active`. No `styleSheets`/`cssRules` scan
exists, so the panel does nothing unless host CSS happens to key off the
attribute. AC-040 checks only the attribute path.
*re_read:* Read `pinscope/src/runtime/components/StatePanel.tsx`; `grep -rln 'styleSheets|cssRules' pinscope/src/runtime` → no matches.

**F-15-09 · CONFIRMED · axis: Behavioral flows / data persistence (§10-D, §8.10 Snapshot)**
`SnapshotManager` writes through an injectable store; the only store is
`MemorySnapshotStore` (in-memory). SPEC §8.10 says it "writes
`.pinscope/snapshots/s_*.json`" and §10 flow D says snapshots persist via the
dev-server endpoint `/__pinscope/snapshot`. Neither exists; a real snapshot is
never written to disk. AC-042 passes against an in-memory test store.
*re_read:* Read `pinscope/src/runtime/managers/SnapshotManager.ts` — only `MemorySnapshotStore` implements `SnapshotStore`; `grep -rln '__pinscope' pinscope/src` → no matches.

### P3

**F-15-10 · SUSPECTED · axis: Integration surface / public API (§15)**
`src/index.ts` does not re-export `withPinScope`, though SPEC §15 lists it
among "Public API exports". It is reachable via the `pinscope/next` subpath
(AC-090) and AC-091's own text omits it, so this may be intentional
subpath-only scoping — handed to the planner to confirm intent.
*re_read:* `grep -n 'withPinScope' pinscope/src/index.ts` → no matches; `package.json` `exports` has `./next` → `dist/plugin/next.js`.

**F-15-11 · SUSPECTED · axis: Data schemas (§9.3 Operation)**
`buildOperation` always stores an operation magnitude in `OperationItem.value`,
including for increment/decrement; the §9.3 `delta?` field exists in the type
but is never populated. The schema permits `value?` for all kinds so AC-052
passes, but an APEX consumer cannot tell a delta from an absolute value. May be
an intentional simplification — flagged for planner review.
*re_read:* Read `pinscope/src/runtime/parsers/operation-builder.ts` lines 59-67 — the `kind === 'operation'` branch builds `{ property, operation, value }`; `grep -n 'delta' …/operation-builder.ts` → no matches.

---

## BLOCKED list (STEP 3 — environment limits, never findings)

| AC | Phase | Sev | Reason | Unblocks on |
|------|-------|-----|--------------|------------------------|
| AC-023 | P1 | P0 | browser | browser-capable CI |
| AC-030 | P1 | P1 | browser | browser-capable CI |
| AC-061 | P4 | P3 | browser | browser-capable CI |
| AC-063 | P4 | P3 | browser | browser-capable CI |
| AC-082 | P2 | P1 | browser | browser-capable CI |
| AC-083 | P4 | P3 | browser | browser-capable CI |
| AC-106 | P5 | P2 | apex-install | APEX-installed CI |

These 7 ACs have implementation + authored tests; their `verify:` needs an
absent environment (`browser=false`, `apex_install=false` per
`env-capabilities.json`). No PinScope code change closes them — a capable CI
does. They are recorded BLOCKED, never OPEN.

---

## Coverage ledger

**Axes swept this round (all 12):** 1 Build pipeline · 2 Pin-ID stability ·
3 Production-zero · 4 Runtime isolation · 5 Inspection layer · 6 Measurement
layer · 7 Operation protocol · 8 Data schemas · 9 Edge cases · 10 Performance
budgets · 11 Integration surface · 12 Phase DoD.

**Spec sections reviewed:** §3, §4, §6.1–6.4, §7.1–7.3, §8.1–8.11, §9.1–9.4,
§10 (flows A–E), §11, §12, §13, §15, §16, §17, Appendix A & B.

**Blind spots / not directly exercised this round:** runtime behaviors that
require a browser (badge `::before` rendering, Playwright integration suite,
print emulation, visual regression) were reviewed by source re-read only, not
executed — see the BLOCKED list. §13 performance budgets were taken from the
passing vitest perf tests, not re-measured. The 12 axes were each swept against
the code; no axis was skipped.

**Regression scan:** every `CLOSED` AC in `STATUS.md` cross-checked against
`ac-results-R15.json` — 62/62 still `PASS`, 0 regressed. Full vitest suite run
independently: 257/257 pass.

---

## One-paragraph round summary

PS-R15 finds **0 AC findings and 0 regressions** — the machine matrix is
genuinely green — but the STEP 5 free investigation surfaces **11 off-matrix
investigation findings (9 CONFIRMED, 2 SUSPECTED)** showing that the
`metric.open == 0` convergence is **false**. The shipping `<PinScope/>` root
wires in only the inspection layer; the measurement, control, state and
operation layers — fully built and individually test-passing — are never
mounted, so §7.1 and the §16 P2/P3/P4 Definition-of-Done are unmet in the
assembled product even though every Appendix-A AC passes. The dominant fix is
F-15-01 (assemble the HUD tree in `PinScope.tsx`); F-15-02…F-15-09 are
spec behaviors absent from the built components; F-15-10/F-15-11 are
lower-confidence schema/API ambiguities for planner review. These findings
independently corroborate the R14 narrative scan's 8 unsatisfied uncovered
claims, re-confirmed here with the auditor's own re-read checks. The loop
should **not** declare convergence until at minimum the P1 finding F-15-01 is
remediated and an AC is added to assert the §7.1 HUD assembly.
