# Audit Findings — PS-R16 (spec-auditor, STEP 1A)

**Round:** 16 · **Generated:** 2026-05-22 · **Auditor:** spec-auditor (context-isolated)
**Inputs:** SPEC.md (FROZEN v2.0.0) · ac-matrix.json · ac-results-R16.json
(62 PASS / 7 UNAVAILABLE / 0 FAIL) · env-capabilities.json (browser=false,
apex_install=false) · VERIFY-R15.md (4 carry-over mutation-survivor findings).

---

## STEP 1–4 — re-confirmation & regression scan

- **STEP 1–2 (re-confirm FAILs):** `ac-results-R16.json` reports **0 FAIL**.
  There is no machine-flagged gap to re-confirm; the `findings` array is empty.
- **STEP 3 (environment limits):** 7 ACs are `UNAVAILABLE` — AC-023, AC-030,
  AC-061, AC-063, AC-082, AC-083, AC-106. All need a browser engine or an
  `~/.claude/` APEX install absent in this environment. Recorded as **BLOCKED**,
  never OPEN. No remediation is proposed for them.
- **STEP 4 (regression scan):** all 62 ACs the loop recorded `CLOSED` still
  report `PASS` in `ac-results-R16.json`. **0 regressions.**

A clean machine sheet is the floor, not the verdict. STEP 5 is below.

---

## STEP 5 — Free investigation (off-matrix gap hunt)

The R15 remediation re-assembled the §7.1 `<PinScope/>` HUD root and hardened
individual components. Re-reading the code end-to-end, the **component
assembly is real but the end-to-end behavioral flows are not** — several §8
subsystems are unit-tested in isolation (so their ACs pass) yet never wired
into the live HUD. The matrix cannot see this because each AC's `verify:`
exercises the primitive directly.

### P1 — normative behavior missing

**F-16-01 · CommandBar→operation pipeline is unwired (§10 Flow C)**
`PinScope.tsx` renders `<CommandBar />` with **no `onSubmit` prop**. A command
typed into the live HUD only appends to in-memory history; it is never parsed,
built into an Operation, or copied to the clipboard. `parseCommand` and
`buildOperation` are referenced by tests only; `ClaudeBridge` is instantiated
nowhere outside its own file. AC-053 passes solely because
`claude-bridge.test.ts` calls the three primitives directly.
> `re_read`: `grep -rn 'onSubmit' src/runtime/PinScope.tsx` → import + comment
> only, no `onSubmit` passed; `grep -rln 'parseCommand' src` → only
> `operation-parser.ts`; `grep -rn 'ClaudeBridge' src` → `ClaudeBridge.ts:18`
> only.

### P2 — secondary behavior / dormant mechanisms

**F-16-02 · Snapshot creation flow is unwired (§10 Flow D, §8.5)**
`EndpointSnapshotStore` and `SnapshotManager` are instantiated nowhere in the
runtime. `PinScope.tsx` registers no `snapshot` shortcut handler (Shift+S is
defined in the shortcut table but unbound), and `TopBar.tsx` renders no
snapshot button. The dev-server `/__pinscope/snapshot` route and the
`EndpointSnapshotStore` both exist and pass unit tests, but no live trigger
reaches them — a user cannot create a snapshot from the HUD.
> `re_read`: `grep -rn 'EndpointSnapshotStore' src` → declaration only;
> `grep -n 'snapshot' src/runtime/PinScope.tsx` → no matches; `TopBar.tsx`
> has no `snapshot` field; `PinScope.tsx:65-78` registers no `snapshot` handler.

**F-16-03 · MeasurementTool never rendered (§8.7, §16 P4 DoD)**
`PinScopeHud` holds a `measuring` state toggled by Shift+M and passes it to
`<Crosshair measuring=.../>`, but **never renders `<MeasurementTool/>`**. The
component file exists and is imported nowhere in the root. The `measuring`
toggle currently only suppresses the Crosshair; the two-click measurement
overlay can never appear.
> `re_read`: `grep -rn 'MeasurementTool' src/runtime/PinScope.tsx` → no matches;
> `grep -c 'measuring' src/runtime/PinScope.tsx` → 2 (state + Crosshair prop).

**F-16-04 · Selection flow + StatePanel unwired (§10 Flow B, §8.8)**
`SelectionManager` is instantiated nowhere outside its own file; no
`useSelectedElement` hook exists (the §5 file structure lists one). `PinScope.tsx`
wires only hover into `InfoPanel` and renders no `StatePanel`. `InfoPanel` has
no lock / click-outside / Esc handling. AC-041 passes off `SelectionManager`
unit tests, not the live click→select→hash→lock flow.
> `re_read`: `grep -rn 'SelectionManager' src` → declaration only;
> `ls src/runtime/hooks` → no `useSelectedElement.ts`;
> `grep -rn 'StatePanel' src/runtime/PinScope.tsx` → no matches.

**F-16-08 · CommandBar→fetch persistence seam un-asserted (VERIFY-R15 #4)**
`CommandBar.persistHistory` POSTs to `/__pinscope/history` behind
`if (typeof fetch !== 'function') return;`. No test stubs `fetch` or asserts
the POST fires — mutation M2 (`!==`→`===`) survives, meaning a flip that
silently disables all history persistence is invisible to the suite. This
compounds F-16-01: the only live persistence the CommandBar performs is itself
untested at the network seam.
> `re_read`: `grep -rn 'persistHistory|fetch' tests/unit/runtime/controls.test.tsx`
> → no matches; CommandBar tests spy only on `history.append`.

### P3 — coverage gaps (VERIFY-R15 carry-overs)

**F-16-05 · `/__pinscope/snapshot` response `ok` flag un-asserted (VERIFY-R15 #1)**
`handleSnapshotRequest` answers `{ ok: true, id }`; the route test asserts
status 200 + on-disk file content, never the body `ok` flag. Mutation M3
(`true`→`false`) survives. The file write is genuinely asserted, so the DoD
holds — this is a coverage gap, not a behavior break.
> `re_read`: `index.ts:65` `res.end(JSON.stringify({ ok: true, id }))`;
> `plugin.test.ts:112-148` `postThrough()` resolves only `{ status }`.

**F-16-06 · `/__pinscope/history` response `ok` flag un-asserted (VERIFY-R15 #2)**
`handleHistoryRequest` answers `{ ok: true, count }`; the route tests assert
status + on-disk history.json + the 1000-cap, never the body `ok` flag.
Mutation M5 (`true`→`false`) survives. Coverage gap only.
> `re_read`: `index.ts:111` `res.end(JSON.stringify({ ok: true, count }))`;
> `plugin.test.ts:182-231` reads `history.json` from disk, never the HTTP body.

**F-16-07 · `mkdirSync` recursion branch never exercised (VERIFY-R15 #3)**
Both route handlers call `fs.mkdirSync(dir, { recursive: true })`. Every route
test uses a single-level `fs.mkdtempSync` temp root, so the recursive
multi-level branch is never hit — mutation M4 (`true`→`false`) survives because
`recursive:false` still succeeds when the parent already exists.
> `re_read`: `index.ts:61,103` `fs.mkdirSync(dir, { recursive: true })`;
> `plugin.test.ts:113,183,206` roots are one-level `os.tmpdir()` mkdtemps.

---

## BLOCKED ACs (7) — environment-limited, not findings

| AC | Sev | Why blocked |
|----|-----|-------------|
| AC-023 | P0 | browser env unavailable (Playwright `::before` content) |
| AC-030 | P1 | browser env unavailable (Playwright InfoPanel hover) |
| AC-061 | P3 | manual — cross-origin iframe needs two real origins |
| AC-063 | P3 | manual — `@media print` needs a browser print engine |
| AC-082 | P1 | manual — Playwright integration suite, no browser binary |
| AC-083 | P3 | manual — visual-regression screenshots need a browser |
| AC-106 | P2 | apex-install env unavailable — `/apex:health-check` |

These are closeable only on a capable CI; no remediation is proposed.

---

## Coverage ledger

**Axes swept (12/12):** build-pipeline · pin-id-stability · production-zero ·
runtime-isolation · inspection-layer · measurement-layer · operation-protocol ·
data-schemas · edge-cases · performance-budgets · integration-surface · phase-DoD.

**Spec sections reviewed:** §6.1–6.4 · §7.1–7.3 · §8.1–8.11 · §9.1–9.4 ·
§10 flows A–E · §11 · §12 · §13 · §15 · §16 Phase DoD · VERIFY-R15 carry-overs.

**Blind spots this round:** browser-dependent runtime behavior (badge `::before`
rendering, Playwright hover/print/visual) could not be exercised here and is
recorded BLOCKED; the static code review of the relevant components found no
additional gap, but their *rendered* behavior remains unverified until a
browser CI runs.

---

## Round summary

R16 carries a clean machine sheet — 62 PASS, 0 FAIL, 0 regressions — but the
free investigation finds the R15 remediation **assembled the §7.1 component
tree without wiring its behavioral flows**. The HUD mounts all seven §7.1
components, yet four §8/§10 subsystems are dormant: the CommandBar never feeds
the operation pipeline (§10-C, **P1**), snapshot creation has no live trigger
(§10-D / §8.5), `MeasurementTool` is never rendered (§8.7), and the
selection/StatePanel flow (§10-B / §8.8) is unwired. Each is unit-tested in
isolation, which is exactly why every AC passes — the matrix verifies
primitives, not the seams between them, so `metric.open == 0` is a **false
convergence**. Three P3 coverage gaps and one P2 seam-coverage gap carried over
from VERIFY-R15 are all re-confirmed. The loop must not converge with the open
P1; the planner should wire the four dormant flows into `<PinScope/>` and add
end-to-end tests that exercise the CommandBar→clipboard, Shift+S→snapshot-file,
Shift+M→MeasurementTool, and click→select→hash seams.
