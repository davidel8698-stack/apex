# Audit Findings — PS-R17 (spec-auditor, STEP 1A)

**Round:** 17 · **Generated:** 2026-05-22T12:42:00Z
**North-Star:** `pinscope/SPEC.md` v2.0.0 (FROZEN)
**Machine verdicts (`ac-results-R17.json`):** 62 PASS · 7 UNAVAILABLE · 0 FAIL

This is a convergence-confirmation round. R15 mounted the §7.1 HUD tree; R16
wired the §10 flow seams. The STEP 5 12-axis free investigation ran in full
against the re-read `pinscope/src/` tree — it is **not** an empty rubber-stamp.
It surfaced **3 off-matrix findings** (1 CONFIRMED, 2 SUSPECTED). The loop must
**not** declare convergence this round: there is an open P2.

---

## STEP 1–4 — AC re-confirmation, environment limits, regression scan

- **STEP 1–2 (re-confirm machine FAILs):** `ac-results-R17.json` records **0
  FAIL**. There is no machine `FAIL` to re-confirm; no AC finding is emitted.
- **STEP 3 (environment limits):** 7 ACs are `UNAVAILABLE` — all recorded as
  `BLOCKED`, never `OPEN`. See the BLOCKED ledger below.
- **STEP 4 (regression scan):** every AC the loop previously recorded `CLOSED`
  (62 of them, per `loop.json` `metric.closed=62`) shows `PASS` in
  `ac-results-R17.json`. **Zero regressions.** The 7 non-closed ACs are the
  `UNAVAILABLE`/`BLOCKED` set — environment-gated, not regressed.

---

## STEP 5 — Free investigation (off-matrix gap hunt)

### P2 findings

#### F-17-01 — `select e_N` command never locks the InfoPanel — CONFIRMED

**Axis 7 (operation protocol) / 11 (integration surface) · §10-B, §11, §8.1, §8.9**

`PinScopeHud` holds **two independent `SelectionManager` instances**:
`useSelectedElement.ts:37` (the hook's private `managerRef`) and
`PinScope.tsx:137` (`command.selection`). The §11 `select e_N` CommandBar
command (`PinScope.tsx:166-169`) calls `command.selection.select(parsed.pin)`
on the second manager. The InfoPanel's locked `selected` state
(`PinScope.tsx:129`, rendered `:240` as `hovered={selected ?? hovered}`) is
sourced **only** from the `useSelectedElement` manager. The two never
communicate; `command.selection` is written by exactly one site and read by
nothing.

A click on a `[data-pin]` element correctly locks the InfoPanel; the `select
e_N` command does not — it moves the `data-pin-selected` attribute and updates
the URL hash (side effects internal to the orphan manager) but never updates the
`selected` React state. One of the two normative §10-B selection-lock triggers
is hollow. No AC names this path (AC-041 = hash mirror + reload-restore only;
AC-038 = CommandBar focus/history/blur), so STEP 1–4 cannot see it.

> `re_read`: `grep -rn 'command\.selection|new SelectionManager' src` →
> `PinScope.tsx:137` `selection: new SelectionManager()`, `PinScope.tsx:167`
> `command.selection.select(parsed.pin)` (the **only** `command.selection`
> usage), `useSelectedElement.ts:37` `managerRef.current = new
> SelectionManager()` (separate instance). `grep -rn 'useSelectedElement|selected
> ??' src/runtime/PinScope.tsx` → L129, L240 — InfoPanel reads `selected` only
> from the hook's manager.

#### F-17-02 — §10-D snapshot persist failure is silently swallowed — SUSPECTED

**Axis 6 (measurement/snapshot) / 9 (edge cases) · §10-D**

`PinScope.tsx` `onSnapshot` (L143-148) calls `command.snapshots.capture(name)`.
`SnapshotManager.capture` → `EndpointSnapshotStore.write` fires the
`/__pinscope/snapshot` POST synchronously and stores the promise in `pending`.
The flow-D wiring never calls `store.flush()`, so a `SnapshotPersistError`
(network error or non-OK dev-server response, thrown inside
`EndpointSnapshotStore.post`) becomes an **unhandled promise rejection** —
silently swallowed.

`EndpointSnapshotStore`'s own docstring states `flush()` exists "so callers (and
tests) can observe a failed persist instead of a silently swallowed one" — the
contract expects the caller to observe it. Flow C (operation send) on the same
file correctly `.catch()`es the `ClaudeBridge` promise with a documented "never
swallow" comment; flow D does not. The snapshot is still built; only the persist
**failure signal** is lost, and §10-D's "→ toast" never fires.

> `re_read`: `grep -n 'flush' src/runtime/PinScope.tsx` → no match.
> `grep -rn '\.flush(' src tests` → only `tests/unit/runtime/snapshot.test.tsx:83,103`.
> `sed -n '143,148p' src/runtime/PinScope.tsx` shows `onSnapshot` calling
> `capture()` with no `.catch`/no `flush`, vs `sed -n '191,197p'` showing flow C
> `void command.bridge.send(...).catch((err) => console.warn(...))`.

### P3 findings

#### F-17-03 — TopBar state field hardcoded to `null` — SUSPECTED

**Axis 5 (inspection layer) / 12 (phase DoD) · §8.5**

`PinScope.tsx` renders `<TopBar ... stateOverride={null} />` (L244) — the prop
is a hardcoded constant. TopBar's `data-field="state"` span always renders
`state: none`, even after `StatePanel`'s `applyStateOverride` has forced a
global state onto `<html data-state-override>`. `StatePanel` (the actual §8.8
selector) is rendered as a separate sibling (L247) and is not lifted into
`PinScopeHud` state. AC-037 passes because the field is present and `StatePanel`
is the live selector — but the TopBar readout never reflects the real override.
Cosmetic staleness, not a behavioral break.

> `re_read`: `grep -n 'stateOverride={null}' src/runtime/PinScope.tsx` → L244.
> `TopBar.tsx` renders `state: {stateOverride ?? 'none'}` — receives a constant
> null; no `StatePanel` state is lifted to `PinScopeHud`.

---

## Carry-over investigated — `useSelectedElement.ts` (VERIFY-R16, 4 mutants)

**Verdict: BENIGN coverage margin — not an off-matrix finding.**

The Esc-unlock path (`useSelectedElement.ts` L65-72) is **present and correct**:
the `onKey` handler checks `e.key === 'Escape'`, then runs `manager.unlock()` +
`manager.clear()` + `setSelected(null)`. Clearing the React `selected` state
makes `InfoPanel` (`hovered={selected ?? hovered}`) fall back to live hover —
exactly §8.1 "Esc unlocks". `SelectionManager.clear()` (`SelectionManager.ts:43-48`)
itself sets `locked=false` and clears the attribute + hash; the preceding
`unlock()` is harmless redundancy. Mutant **M5** survives only because no test
fires an `Escape` keydown at `document` while a pin is selected
(`controls.test.tsx:145` fires Escape at the CommandBar input — a different
input-blur handler). **M4** is a provably-equivalent mutant: `pinId` is null
whenever `pinned` is null, so `&&` and `||` behave identically for all reachable
inputs. **M1/M2** are SSR-branch margin (`typeof document` is never `undefined`
under jsdom). No dead path, no swallowed failure — consistent with the
VERIFY-R16 adjudication.

> `re_read`: read `useSelectedElement.ts` L65-72 + L17-22 against
> `SelectionManager.ts:39-48`; `grep -rln 'Escape' tests/` → `controls.test.tsx`
> only (L137/L145 = CommandBar input blur).

---

## BLOCKED ledger (environment-gated — never `OPEN`)

| AC | Phase | Sev | Reason | Unblocks on |
|---|---|---|---|---|
| AC-023 | P1 | P0 | `browser` env unavailable — Playwright `::before` content read | browser-capable CI |
| AC-030 | P1 | P1 | `browser` env unavailable — Playwright hover/InfoPanel assert | browser-capable CI |
| AC-061 | P4 | P3 | `browser` env unavailable — cross-origin iframe (manual) | browser-capable CI |
| AC-063 | P4 | P3 | `browser` env unavailable — `@media print` engine (manual) | browser-capable CI |
| AC-082 | P2 | P1 | `browser` env unavailable — Playwright integration suite (manual) | browser-capable CI |
| AC-083 | P4 | P3 | `browser` env unavailable — visual-regression screenshots (manual) | browser-capable CI |
| AC-106 | P5 | P2 | `apex-install` env unavailable — `/apex:health-check` needs `~/.claude/` (manual) | APEX-installed CI |

These 7 are `UNAVAILABLE` in `ac-results-R17.json` and match `loop.json`'s
`blocked` set. They are closeable only on a capable CI — no remediation is
proposed for them.

---

## Coverage ledger

**Axes swept (12/12):** 1 build-pipeline · 2 pin-id-stability · 3
production-zero · 4 runtime-isolation · 5 inspection-layer · 6
measurement-snapshot · 7 operation-protocol · 8 data-schemas · 9 edge-cases · 10
performance-budgets · 11 integration-surface · 12 phase-DoD.

**Spec sections reviewed:** §6, §7, §8 (§8.1–§8.11), §9, §10 (flows A–E), §11,
§12, §13, §14, §15, §16, §17; Appendix A (69 ACs); Appendix B.

**Blind spots this round:** the 6 browser-gated ACs (AC-023/030/061/063/082/083)
and 1 apex-install-gated AC (AC-106) cannot be exercised here — visual rendering,
real hover/print, and the live `/apex:health-check` remain unverified end-to-end
in this environment.

---

## Round summary

The STEP 5 12-axis sweep ran in full against the re-read `pinscope/src/` tree
and did **not** converge to an empty audit. R16's flow-seam wiring is mostly
correct, but the investigation found that the §10-B selection-lock has only one
of its two normative triggers actually connected: a click locks the InfoPanel,
but the §11 `select e_N` CommandBar command writes an **orphan**
`SelectionManager` whose state no component reads (**F-17-01, CONFIRMED, P2**).
Two further off-matrix issues were recorded for the planner: the §10-D snapshot
persist failure path is silently swallowed because the flow never `flush()`es
the `EndpointSnapshotStore` (**F-17-02, SUSPECTED, P2**), and the TopBar's state
field is hardcoded to `null` so it never reflects the live `StatePanel` override
(**F-17-03, SUSPECTED, P3**). Zero machine `FAIL`s, zero regressions across all
62 `CLOSED` ACs. The carry-over `useSelectedElement.ts` 4-mutant observation was
investigated directly and adjudicated a benign coverage margin. **The loop must
not converge this round — F-17-01 is an open P2.**
