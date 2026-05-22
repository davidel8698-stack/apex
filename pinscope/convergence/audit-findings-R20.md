# PinScope Audit — Round PS-R20

**Generated:** 2026-05-22T14:30:00Z
**Spec:** `pinscope/SPEC.md` v2.0.0 (FROZEN) · **Matrix:** `ac-results-R20.json` (62 PASS / 7 UNAVAILABLE / 0 FAIL)
**Verdict:** matrix-converged, but **STEP 5 free investigation found 3 CONFIRMED off-matrix defects** —
a false convergence: well-built mechanisms that pass their ACs in isolation but are never wired into the shipped `<PinScope/>` HUD.

---

## STEP 1 — Re-confirm machine verdicts

`ac-results-R20.json` carries **no `FAIL`** — nothing to re-confirm as a gap. The machine verdicts
were instead independently reproduced on the env-capable checks:

- `npm test` → 30 files / **303 tests pass**
- `npm run typecheck` → exit 0
- `npm run build` → exit 0
- `npm run size` → **8.3 KB** with deps, minified+brotlied (limit 80 KB) → exit 0
- `examples/vite-react` production build rebuilt → `grep -rc 'data-pin|PinScope|pinscope' dist` → **0** in both `index.html` and the emitted JS chunk

All machine `PASS` verdicts independently reproduced. No false `PASS` at the artifact level.

## STEP 4 — Regression scan

Every previously-`CLOSED` AC still shows `PASS` in `ac-results-R20.json`. Diffed verdict-for-verdict
against `ac-results-R19.json` — **identical** (62 PASS, same 7 UNAVAILABLE). **Zero regressions.**

---

## Investigation findings (STEP 5 — off-matrix)

### P2 — CONFIRMED

#### F-20-01 · Void-element badge overlay is a dormant mechanism
`VoidBadges.tsx` fully implements the §7.2 JS-overlay badge path for `img/input/br/hr/area/embed`,
and **AC-024 PASSES** — but only because `overlays.test.tsx:203` renders `<VoidBadges/>` directly.
The shipped HUD in `PinScope.tsx` (lines 287-306) renders 10 components and **`VoidBadges` is not one
of them**. `PinBadges` is the CSS-`::before` path only, and `::before` does not render on void
elements — so in the real `<PinScope/>`, `<img>`/`<input>` get **no badge at all**.

> `re_read`: `grep -nE '<(PinBadges|VoidBadges|…)' src/runtime/PinScope.tsx` → VoidBadges absent from
> the 10-component tree. `grep -rn 'VoidBadges' src/` → only its own definition. `PinBadges.tsx:8-9`
> self-documents: *"The JS-overlay path for void elements … is deferred (SPEC §7.2, AC-024)."*

#### F-20-02 · Runtime pin observer is never started
`RuntimePinObserver.ts` fully implements the §12 MutationObserver that assigns `e_r{N}` ids to
dynamically-added DOM nodes, and **AC-025 PASSES** — but only because `edge-cases.test.ts` constructs
`new RuntimePinObserver()` and calls `.start()` directly. **`PinScope.tsx` never imports, constructs,
or starts it** — the file has zero `useEffect`. In the running HUD, dynamic content gets no `e_r{N}`
ids and is not inspectable.

> `re_read`: `grep -rn 'RuntimePinObserver' src/` → only its own definition.
> `grep -n 'useEffect|RuntimePinObserver|.start(' src/runtime/PinScope.tsx` → **no matches**.

#### F-20-03 · `Shift+P` and `Shift+C` shortcut ids are dead
`useKeyboardShortcuts.ts` defines `toggle-pins` (Shift+P) and `crosshair` (Shift+C) in the SHORTCUTS
table. `PinScope.tsx:258-273` wires handlers for only **9 of 13** ids; `command`/`escape` are
serviced by `CommandBar`. But `toggle-pins` and `crosshair` have **no handler anywhere**: `PinBadges`
exposes no visibility prop, `Crosshair` accepts only `measuring`/`hudHidden` (no on/off toggle).
Pressing Shift+P or Shift+C in the real HUD does nothing. **AC-043 PASSES** only because
`shortcuts.test.tsx` feeds synthetic handlers for all 13 ids and asserts dispatch of those fakes — it
never touches `PinScope.tsx`'s wiring. Real-HUD ratio = **11/13 = 0.846 < 0.95**, below the §16
P2-DoD "≥95% shortcuts functional" threshold.

> `re_read`: `grep -rn 'toggle-pins|crosshairEnabled|showCrosshair' src/` → only the table entries,
> zero consumer. `grep -n 'Crosshair' src/runtime/PinScope.tsx:291` → `<Crosshair measuring=… hudHidden=… />`
> (no toggle prop). `PinScope.tsx:258-273` handler object lists exactly 9 ids.

### P3 — SUSPECTED

#### F-20-04 · `request_type:'annotation'` / §10-E flow unimplemented
§9.3 lists `'annotation'` as a valid `request_type`; §10-E describes a select→modal(screenshot+note)→
annotation-Operation flow. `operation-builder.ts` only ever emits `'operation'` (L52) and
`'diagnostic'` (L93). `captureScreenshot` (`screenshot.ts`) is a working but **uncalled** unit — no
src/ caller, no screenshot/annotation modal component. **Recorded P3/SUSPECTED**: §10-E is
non-normative prose, no AC requires emitting an `annotation` request_type, and AC-076 (the only
screenshot AC) verifies solely the html2canvas dynamic-import property — which holds. Handed to the
planner to decide AC-worthiness vs. genuine v2.0 out-of-scope.

> `re_read`: `grep -rn 'annotation|request_type|captureScreenshot' src/runtime/` → request_type only
> 'operation'/'diagnostic'; `captureScreenshot` defined, no caller. No `*Modal*` under `components/`.

#### F-20-05 · CommandBar local-only coverage margin (carried from F-19-01)
`CommandBar.tsx:46-53` `isLocalOnlyCommand` is **correct** — a valid `snapshot` / `measure e_N to e_M`
returns true. But `controls.test.tsx` submits only `select e_1` and the invalid-grammar
`measure e_2 e_3` (caught → `catch` branch), so the `measure`/`snapshot` disjuncts of L49 stay
unexercised and the R18 `or-to-and` mutant survives. A benign coverage margin, **not** a behavioral
gap; carried unchanged from R19 F-19-01. Planner may close with a valid `snapshot`/`measure … to …`
CommandBar Enter test.

> `re_read`: `grep -n 'RE_MEASURE' operation-parser.ts:45` → `/^measure\s+(e_\d+)\s+to\s+(e_\d+)$/i`
> confirms `measure e_2 e_3` does not parse. Carried verbatim from `audit-findings-R19.json`.

---

## BLOCKED (environment-limited — not findings)

| AC | Sev | Reason |
|----|-----|--------|
| AC-023 | P0 | `browser` unavailable — Playwright `::before` content read needs a browser engine. |
| AC-030 | P1 | `browser` unavailable — Playwright InfoPanel hover assertion. |
| AC-061 | P3 | manual / `browser` — cross-origin iframe needs two real origins. |
| AC-063 | P3 | manual / `browser` — `@media print` rendering needs a print engine. |
| AC-082 | P1 | manual / `browser` — Playwright integration suite, no browser binary. |
| AC-083 | P3 | manual / `browser` — visual-regression screenshots. |
| AC-106 | P2 | `apex-install` unavailable — `/apex:health-check` needs APEX synced to `~/.claude/`. |

Closeable only on a browser/apex-capable CI. Never `OPEN`.

---

## Coverage ledger

**Axes swept (12/12):** Build pipeline · Pin-ID stability · Production-zero (dist rebuilt+grepped=0) ·
Runtime isolation · **Inspection layer — DEFICIT F-20-01** · Measurement layer · **Operation protocol —
DEFICIT F-20-03 + margin F-20-05** · Data schemas (F-20-04) · **Edge cases — DEFICIT F-20-02** ·
Performance budgets (size 8.3 KB) · Integration surface · Phase DoD.

**Sections reviewed:** §3–§18, Appendix A (69 ACs), Appendix B.

**Blind-spot note:** Next.js `withPinScope` / `PinScopeWebpackPlugin` still do not inject `data-pin`
(carry "later round" comments) — **not a finding**: §18 I-1 scopes them P4/P5 and AC-092 requires
only importability + valid config objects (PASS). Consistent with R19.

---

## Round summary

The R20 matrix is green (62 PASS / 7 UNAVAILABLE / 0 FAIL) and STEP 1/STEP 4 confirm it: every
machine `PASS` was independently reproduced and zero `CLOSED` ACs regressed. But the STEP 5 free
investigation surfaced the precise failure mode the auditor exists to catch — **a false
convergence**. Three spec-named mechanisms — the void-element badge overlay (§7.2, F-20-01), the
runtime pin MutationObserver (§12, F-20-02), and the `Shift+P`/`Shift+C` shortcuts (§8.11, F-20-03) —
are fully and correctly implemented as units, pass their ACs, yet are **never wired into the shipped
`<PinScope/>` HUD**: AC-024/025/043 verify the unit in isolation (direct render / direct construction
/ synthetic-handler dispatch), so the missing end-to-end integration is invisible to the matrix.
F-20-03 additionally puts the real-HUD shortcut ratio at 0.846, under the §16 P2-DoD ≥95% bar. Two
P3/SUSPECTED items (the unimplemented §10-E annotation flow, and the carried CommandBar coverage
margin) are handed to the planner without blocking. **The loop should not be declared converged while
F-20-01..03 (P2) stand open** — they are matrix-invisible but real, ship-visible defects.
