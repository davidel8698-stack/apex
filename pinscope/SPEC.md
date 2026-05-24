# PinScope — North-Star Specification

> **north_star_version:** 2.0.0
> **status:** FROZEN — source of truth for the PS-R{N} convergence loop
> **frozen:** 2026-05-21 (user-approved)
> **base:** PinScope Technical Specification v1.0 (user-supplied)
> **role:** Single source of truth. The PinScope `PS-R{N}` self-healing
> convergence loop audits the `pinscope/` reality tree against this document.
> **freeze rule:** Once `status: FROZEN`, this file changes only by an explicit,
> user-approved version bump (`north_star_version`). The loop must never chase a
> moving target.

---

## 0. How to read this document

1. **Sections 1–17** are the *design narrative* — what PinScope must be.
2. **Appendix A — Acceptance Criteria Ledger** is the *machine-checkable
   contract*. Every capability in §1–§17 maps to one or more `AC-###` rows.
   Each row is **falsifiable**: it names a concrete check (test / grep / build
   output / measured number / Playwright assertion) that returns pass or fail.
3. The convergence loop works **only** off Appendix A. Prose in §1–§17 that is
   not reduced to an `AC-###` is non-normative context. If a behavior matters,
   it must have an AC.
4. **Status vocabulary** for each AC: `OPEN` (gap exists) / `CLOSED` (verified
   passing) / `BACKLOG` (P3, deferred by user). Convergence = zero `OPEN` at
   P0–P2 **and** every Phase-DoD AC `CLOSED`.

---

## 1. Mission & Problem Statement

**Mission:** A visual debug layer that wraps web applications during
development and lets non-technical users communicate UI changes to AI agents
with total certainty — without requiring professional vocabulary.

**Current state:** A user requesting a UI change describes it in words ("the
button is big", "move that"). This creates referential ambiguity and costs
5–10 communication rounds per change.

**Target state:** The user points at an element carrying a visual label, sees
its numeric properties, and sends a structured operation. Rounds drop to 1–2.

**Success metric:** 95% of UI requests resolved in ≤2 communication rounds.

---

## 2. Glossary

| Term | Definition |
|---|---|
| Pin | A unique, stable identifier (`e_N`) bound to a DOM element |
| Pin ID | The string in the form `e_47` |
| PinMap | Persistence file mapping source location → Pin ID |
| Operation | A structured change request targeted at a Pin |
| Snapshot | A full numeric description of page state at a moment |
| HUD | Heads-Up Display — the entire overlay UI |
| Sandbox Mode | Dev environment with all overlays active |
| Production Mode | Clean build, all PinScope code removed |
| North-Star | This document — the frozen ideal state |
| AC | Acceptance Criterion — one falsifiable row in Appendix A |
| PS-R{N} | PinScope convergence round N (own series, distinct from APEX `R{N}`) |
| Gap | A capability in the North-Star not yet satisfied by `pinscope/` reality |

---

## 3. System Architecture

```
USER APPLICATION CODE  (React + Vite | Next.js | other)
        │  build-time
        ▼
BUILD MODULE (Vite/Webpack plugin)
  ├─ AST Transformer (injects data-pin)
  ├─ PinMap Manager (persistence)
  ├─ Environment Gate (dev/prod toggle)
  └─ Production Stripper
        │  runtime (dev only)
        ▼
RUNTIME MODULE (React components)
  ├─ <PinScope/>  (root, portal-rendered)
  ├─ Inspection Layer  (PinBadges, InfoPanel, HoverDetector)
  ├─ Measurement Layer (Rulers, Crosshair, GridOverlay, MeasurementTool)
  ├─ Control Layer     (TopBar, CommandBar, KeyboardShortcuts)
  ├─ State Layer       (StateOverride, SelectionManager, SnapshotManager)
  └─ Operation Layer   (OperationParser, OperationBuilder, ClaudeBridge)
```

---

## 4. Technical Stack

| Layer | Technology | Rationale |
|---|---|---|
| Build plugin | Vite Plugin API | Standard, framework-agnostic |
| AST parsing | `@babel/parser` + `traverse` + `generator` | Industry standard |
| UI framework | React 18+ | Hooks API, most common |
| Rendering | `createPortal` to `document.body` | Avoids host style conflicts |
| Styling | Inline `<style>` + style props | Zero CSS dependency on host |
| State | React hooks (no Redux/Zustand) | Minimal footprint |
| PinMap storage | JSON file in project root | Simple, git-trackable |
| Snapshot storage | JSON files in `.pinscope/` | Local-first |
| Clipboard | `navigator.clipboard` API | Universal |
| Screenshots | `html2canvas` (fallback: native) | No server dependency |

**Bundle budget (dev build):** < 80 KB minified, < 25 KB gzipped.
**Bundle budget (prod build):** exactly 0 bytes of PinScope.

---

## 5. File Structure

```
pinscope/
├── package.json
├── tsconfig.json
├── SPEC.md                          ← THIS document (North-Star)
├── README.md
├── LICENSE
├── convergence/                     ← PS-R{N} loop artifacts (git-tracked)
│   ├── STATUS.md                    ← live convergence dashboard
│   ├── audit-findings-R{N}.md
│   ├── REMEDIATION-PLAN-R{N}.md
│   ├── WAVES-R{N}.md
│   ├── WAVE-{N}-RESULT.md
│   └── ROUND-R{N}-CLOSURE.md
├── src/
│   ├── plugin/        index.ts, ast-transformer.ts, pin-map.ts,
│   │                  production-stripper.ts, stable-id-generator.ts
│   ├── runtime/
│   │   ├── PinScope.tsx
│   │   ├── components/  PinBadges, InfoPanel, Rulers, Crosshair,
│   │   │                GridOverlay, TopBar, CommandBar, MeasurementTool,
│   │   │                StatePanel
│   │   ├── hooks/       useHoveredElement, useSelectedElement,
│   │   │                useKeyboardShortcuts, useElementInfo,
│   │   │                useViewportSize, useStateOverride
│   │   ├── managers/    SelectionManager, SnapshotManager, HistoryManager,
│   │   │                ClaudeBridge
│   │   ├── parsers/     operation-parser.ts, operation-builder.ts
│   │   ├── utils/       element-walker, selector-generator, style-formatter,
│   │   │                color-utils, rect-math
│   │   ├── styles/      badges.css.ts, panels.css.ts, overlays.css.ts
│   │   └── constants.ts
│   ├── types/         operation.ts, snapshot.ts, pin-map.ts, element-info.ts
│   └── index.ts                     ← public API
├── examples/          vite-react/, nextjs-app/
└── tests/             unit/, integration/, visual/
```

---

## 6. Build-Time Module

### 6.1 Plugin entry — `src/plugin/index.ts`

Exports `pinscope(options?: PinScopeOptions): Plugin`.

```typescript
export interface PinScopeOptions {
  enabled?: boolean;        // default: process.env.NODE_ENV !== 'production'
  filePattern?: RegExp;     // default: /\.(jsx|tsx)$/
  excludePattern?: RegExp;  // default: /node_modules|\.test\./
  pinMapPath?: string;      // default: '.pinmap.json'
  stripInProduction?: boolean; // default: true
  excludeTags?: string[];   // default: ['Fragment', 'Suspense']
}
```

Plugin object: `name: 'vite-plugin-pinscope'`, `enforce: 'pre'`. Hooks:
`buildStart` → `pinMap.load()`; `transform` → gate on enabled/filePattern/
excludePattern then `transformJSX`; `buildEnd` → `pinMap.save()`;
`transformIndexHtml` → strip `data-pin` from prod HTML when disabled.

### 6.2 AST transformer — `src/plugin/ast-transformer.ts`

`transformJSX(code, filePath, pinMap, opts)` parses with `@babel/parser`
(plugins: `jsx`, `typescript`, `decorators-legacy`), traverses
`JSXOpeningElement`, and for each element that (a) is not in `excludeTags`,
(b) has no `data-pin`, (c) has no `data-pin-ignore`, (d) has a source `loc` —
computes `stableKey = file:line:column`, calls `pinMap.getOrAssign`, and
pushes a `data-pin` JSX attribute. Emits code + source map.

### 6.3 PinMap manager — `src/plugin/pin-map.ts`

`class PinMap` with `load()`, `save()` (dirty-gated), `getOrAssign(key, tag)`,
`migrate()`. Data shape: see §9.1. `getOrAssign` returns the existing ID for a
known key (refreshing `last_seen`, clearing `deleted`), else allocates
`e_${next_id++}`.

### 6.4 Stable ID strategy

- Key = `${filepath}:${line}:${column}`. Source of truth = `.pinmap.json`.
- New element → new ID (counter increments). Removed element → entry marked
  `deleted: true`, ID **never reused**. Moved element → new key → new ID
  (intentional; prevents stale references). File rename → breaks IDs
  (content-hash fallback is Phase 2).

---

## 7. Runtime Module

### 7.1 Root component — `src/runtime/PinScope.tsx`

`<PinScope/>` props: `enabled?`, `hudPosition?: 'right'|'left'`,
`defaultGridMode?`, `shortcutsEnabled?`. Returns `null` when
`NODE_ENV==='production'` or `enabled===false`. Otherwise portal-renders the
HUD tree (`PinBadges`, `Rulers`, `Crosshair`, `GridOverlay`, `InfoPanel`,
`TopBar`, `CommandBar`) into `document.body` under a `data-pinscope-ui="root"`
wrapper. When HUD hidden, renders only a `FloatingToggle`.

### 7.2 Pin badge strategy

CSS-only path for most elements (`[data-pin]::before { content: attr(data-pin) }`,
blue badge, red on hover, green when `[data-pin-selected]`, `z-index`
`2147483645`–`2147483647`). JS-overlay path for void elements; a
MutationObserver detects new void elements at runtime. HUD elements are exempt.

### 7.3 Hover detection — `src/runtime/hooks/useHoveredElement.ts`

`mousemove` (passive) throttled through `requestAnimationFrame`;
`document.elementFromPoint` then walk out of any `[data-pinscope-ui]` and up to
the nearest `[data-pin]` ancestor. Returns `{ element, pinId, rect } | null`.

---

## 8. Component Specifications

- **8.1 InfoPanel** — `position:fixed; right:16px; top:56px; width:320px`.
  Collapsible sections: Dimensions, Spacing, Typography, Appearance, Layout,
  Hierarchy. Real-time on hover; click-outside locks selection; Esc unlocks.
  Collapsed state persists to `localStorage`. Color values show a swatch.
  Empty values render `—`, not `0px`. Long shadows truncate with tooltip.
- **8.2 Rulers** — horizontal (top) + vertical (left), 24px, ticks at
  10/50/100/200 px, monospace labels, corner shows live mouse coords.
- **8.3 Crosshair** — full-width/height 1px lines at mouse position; disabled
  over HUD, in measurement mode, or when HUD hidden.
- **8.4 GridOverlay** — 4 modes: pixel (8px), baseline (4px), column (12-col),
  spacing-scale visualizer. Toggle order off→pixel→baseline→column→spacing→off.
  Implemented via SVG `<pattern>`.
- **8.5 TopBar** — `fixed; top:0; height:32px`. Viewport selector, grid-mode
  selector, state-override selector, fullscreen toggle, mode badge, pin count,
  snapshot button, settings.
- **8.6 CommandBar** — `fixed; bottom:0; height:40px` (expands to 120px on
  focus). Operation syntax (§11). Autocomplete for pins/properties/values.
  `Cmd+K`/`/` focus, history nav, Tab autocomplete, Enter send, Esc blur.
  History persisted to `.pinscope/history.json` (last 1000).
- **8.7 MeasurementTool** — `M` key. Two-click measurement; renders dashed
  line, Δx/Δy/diagonal/gap labels; smart alignment + on-scale hints; Alt-hover
  shows all sibling distances.
- **8.8 StatePanel** — forces global state via `[data-state-override]` on
  `<html>`; auto-generates override rules by scanning host stylesheets for
  `:hover`/`:focus`/`:active`; `useDevState` hook for non-CSS states.
- **8.9 SelectionManager** — `selectedPin`, `isLocked`, `selectionHistory`.
  `select`/`hover`/`unlock`/`clear`/`goBack`. Selection mirrored to URL hash
  `#select=e_47`.
- **8.10 SnapshotManager** — `createSnapshot(name?)` walks all `[data-pin]`,
  extracts 32 computed-style properties + rect + hierarchy, writes
  `.pinscope/snapshots/s_*.json`.
- **8.11 Keyboard shortcuts** — full table per v1.0 (`Cmd+K`, `Shift+G/0-4/H/
  P/M/S/C`, `Esc`, `Alt+Hover`).

---

## 9. Data Schemas

### 9.1 PinMap — `.pinmap.json`
```typescript
interface PinMap {
  version: 1;
  next_id: number;
  entries: Record<string /*stable_key*/, {
    id: string; tag: string; created: string; last_seen: string;
    deleted?: boolean;
  }>;
}
```

### 9.2 Snapshot — `.pinscope/snapshots/s_{timestamp}.json`
`{ version:'1.0', id, name?, created, viewport, url, user_agent,
device_pixel_ratio, elements: Record<pin_id, ElementSnapshot>, summary }`.
`ElementSnapshot = { tag, classes, attributes, text_content?, rect,
computed_styles, parent_pin?, children_pins, visible, in_viewport }`.

### 9.3 Operation — clipboard / Claude payload
`{ version:'1.0', pin, context, current_styles, request_type:
'operation'|'annotation'|'diagnostic', operations?, annotation?, signal?,
meta }`. `operations[]` items: `{ property, operation:
'set'|'increment'|'decrement'|'remove'|'add-class'|'remove-class', value?,
delta? }`.

### 9.4 History — `.pinscope/history.json`
`{ version:'1.0', entries: Array<{ timestamp, raw_input, parsed, result:
'sent'|'applied'|'failed'|'reverted', error? }> }`.

---

## 10. Behavioral Flows

- **A. Hover inspection** — `mousemove` → rAF throttle → `elementFromPoint` →
  walk to `[data-pin]` → `getComputedStyle` + `getBoundingClientRect` → update
  InfoPanel. Budget < 8 ms/frame.
- **B. Selection** — click → `SelectionManager.select` → `data-pin-selected`
  attribute moved → URL hash updated → InfoPanel locks.
- **C. Operation via CommandBar** — parse → validate (pin exists, property
  settable, value typed) → build Operation → clipboard + history → toast.
- **D. Snapshot creation** — `Shift+S` → walk all pins → build Snapshot →
  persist via dev-server endpoint `/__pinscope/snapshot` → toast. Budget
  < 500 ms for 200 elements.
- **E. Send to Claude (annotation)** — select → modal (screenshot + context +
  note) → Operation with `request_type:'annotation'` → clipboard → history.

---

## 11. Operation Protocol

Grammar: `Target "." Property Operator Value` | `Target Operator Class` |
`"select" Target` | `"measure" Target "to" Target` | `"snapshot" [Name]` |
`"?" [Topic]`. `Target = /e_\d+/`. Operators: `→` set, `+→` increment, `-→`
decrement, `+=` add-class, `-=` remove-class.

Shortcut properties: `padding-y/x`, `margin-y/x`, `bg`, `fg`, `radius`,
`weight`, `size`, `shadow` (resolve to their CSS equivalents).

---

## 12. Edge Cases

Dynamic content (MutationObserver assigns `e_r{N}` runtime IDs); Shadow DOM
(mark `data-pin-shadow`, limited inspection); iframes (same-origin inject,
cross-origin outline only); SVG (`getBBox` + `getCTM`); print mode
(`@media print` hides HUD); z-index conflicts (PinScope reserves
`2147483647`); hostile CSS (PinScope styles use `!important`); mobile/touch
(tap=select, long-press=lock, HUD collapsible < 768px); many elements
(throttle to 30fps > 500 elements, skip badges < 16×16, `data-pin-ignore`
opt-out); color-on-color (brightness sampling swaps badge color).

---

## 13. Performance Requirements

| Operation | Budget | Critical |
|---|---|---|
| Initial PinScope mount | < 50 ms | Yes |
| Hover → InfoPanel update | < 8 ms | Yes |
| Selection update | < 16 ms | Yes |
| Grid mode switch | < 32 ms | No |
| Snapshot creation (200 el) | < 500 ms | No |
| Operation parse | < 4 ms | Yes |
| Bundle size (dev) | < 80 KB min / < 25 KB gz | Yes |
| Bundle size (prod) | 0 bytes | Critical |

---

## 14. Testing Strategy

- **Unit (Vitest + RTL):** AST transformer (≥50 input/output pairs), PinMap,
  operation parser (≥30 grammar variants), element walker, hooks.
- **Integration (Playwright):** drop into a fresh app, verify pins, hover,
  selection lock, command bar, operation→clipboard, snapshot file, prod build
  cleanliness.
- **Visual regression:** HUD across Chrome/Firefox/Safari, 4 viewports, light/
  dark, with/without host CSS framework.
- **Performance:** hover throughput at 60fps with 1000 pins; snapshot time
  linear; bundle size tracked by `size-limit` (CI fails over budget).

---

## 15. Deployment & Integration

npm package `pinscope`. Vite: `pinscope/vite`. Next.js: `withPinScope` from
`pinscope/next` + `<PinScope/>` from `pinscope/runtime`. Webpack:
`PinScopeWebpackPlugin` from `pinscope/webpack`. Public API exports:
`pinscope`, `withPinScope`, `PinScope`, `useDevState`, and types
`PinScopeOptions`, `Operation`, `Snapshot`, `ElementSnapshot`.

---

## 16. Phase Plan with Definition of Done

| Phase | Goal | DoD (each → AC in Appendix A) |
|---|---|---|
| **P1 Foundation** | Pin injection + basic InfoPanel | Drop into example app → badges on all elements; hover shows width/height/padding/font; prod build has no `data-pin`; dev bundle < 30 KB |
| **P2 Visual Tools** | Full visual surface | 4 grid modes render; rulers align at any viewport; selection persists via URL hash; ≥95% shortcuts functional |
| **P3 Operations** | Structured Claude comms | 10 operations → correct clipboard JSON; JSON conforms to §9.3; history saved; autocomplete < 50 ms |
| **P4 Advanced** | Production-ready | Measurement correct; snapshot 200 el < 500 ms; Chrome/Firefox/Safari; mobile long-press locks |
| **P5 APEX Integration** | PinScope ↔ APEX loop | See §17 |

---

## 17. APEX Integration End-State  *(NEW — north-star addition)*

The integrated ideal: **every project APEX builds, develops, or designs ships
with PinScope instrumentation, and APEX agents consume PinScope output as a
first-class feedback channel.**

1. **`apex-skill: pinscope`** — `framework/apex-skills/pinscope.md` teaches
   APEX agents the Pin / Operation / Snapshot model, the `data-pin`
   convention, install steps, and how to parse an Operation JSON into concrete
   code edits.
2. **`/apex:ui-phase` scaffolds PinScope** — any UI phase installs the
   PinScope plugin + `<PinScope/>` into the target project automatically, so
   the delivered app is instrumented out of the box.
3. **`/apex:ui-review` consumes PinScope** — the 6-pillar review can ingest a
   PinScope Snapshot and Operations as evidence.
4. **`stack_skills` auto-includes `pinscope`** — architect / frontend-
   specialist add `pinscope` to `STATE.json.stack_skills` for any frontend
   project.
5. **Registered in `apex-spec.md`** — PinScope is a sanctioned APEX extension
   module, so its presence does not violate the "do not add beyond spec" build
   rule.
6. **Round-trip:** user points at a pinned element → PinScope emits an
   Operation → APEX executor applies it → `/apex:ui-review` verifies → average
   communication rounds per UI change < 2.

---

## 18. Resolved Inconsistencies from v1.0  *(NEW)*

| # | v1.0 issue | Resolution in this North-Star |
|---|---|---|
| I-1 | P1 DoD says "drop into Next.js" but the only build plugin is Vite | P1 targets the **Vite** plugin + `examples/vite-react`. The Next.js wrapper (`withPinScope`) and `examples/nextjs-app` are **P4/P5**. ACs scoped accordingly. |
| I-2 | §6.3 `PinMap.getOrAssign` never sets `deleted:true`, but §6.4 requires it | A separate `PinMap.reconcile(seenKeys)` pass at `buildEnd` marks unseen entries `deleted:true`. New AC covers it. |
| I-3 | `vite-vue/` example listed under File Structure but Vue is "Future" | Vue support is explicitly **out of scope** for North-Star v2.0; `examples/vite-vue/` removed from §5. Tracked as a future version bump. |
| I-4 | `html2canvas` is a runtime dep but §4 claims "no server dependency" / dev-bundle budget | `html2canvas` is **lazy-imported** only when a screenshot is requested, so it does not count against the < 80 KB initial dev bundle. AC verifies dynamic import. |
| I-5 | `Cmd+Z` undo and `Alt+Click` multi-select marked "Future" in §8.11 | Confirmed **out of scope** for v2.0; not given ACs. |

---

# Appendix A — Acceptance Criteria Ledger

Format per row: **AC-ID** · phase · severity-if-missing · category ·
description — **verify:** falsifiable check.

All `status` values start `OPEN` and are tracked in
`convergence/STATUS.md`, not here (this file is frozen).

### A.1 Build-Time Module

- **AC-001** · P1 · P0 · build — `pinscope/vite` exports `pinscope()` returning
  a Vite plugin object with `name === 'vite-plugin-pinscope'` and
  `enforce === 'pre'`. **verify:** unit test imports and asserts shape.
- **AC-002** · P1 · P0 · build — `transformJSX` injects a `data-pin="e_N"`
  attribute on each eligible `JSXOpeningElement`. **verify:** unit test on a
  `.tsx` fixture asserts `/data-pin="e_\d+"/` present on a `<button>`.
- **AC-003** · P1 · P2 · build — elements whose tag is in `excludeTags`
  (`Fragment`, `Suspense`) receive no `data-pin`. **verify:** unit fixture with
  `<Fragment>` → assert no `data-pin` on it.
- **AC-004** · P1 · P1 · build — an element already carrying `data-pin` or
  carrying `data-pin-ignore` is left untouched. **verify:** two unit fixtures.
- **AC-005** · P1 · P0 · build — identical `file:line:column` yields the same
  `e_N` across two consecutive transforms. **verify:** run `transformJSX`
  twice on the same fixture, diff the injected IDs → identical.
- **AC-006** · P1 · P1 · build — `.pinmap.json` validates against the §9.1
  schema (`version:1`, numeric `next_id`, `entries` map). **verify:** JSON
  schema validation in a unit test.
- **AC-007** · P1 · P1 · build — `PinMap.getOrAssign` increments `next_id` for
  new keys and never returns a previously issued ID. **verify:** unit test
  asserts monotonic IDs and no collisions across 100 assigns.
- **AC-008** · P1 · P2 · build — `PinMap.reconcile(seenKeys)` (resolution I-2)
  marks entries whose key was not seen this build with `deleted:true` without
  reusing the ID. **verify:** unit test removes a key, asserts `deleted:true`.
- **AC-009** · P1 · P0 · build — `transformIndexHtml` removes every
  `data-pin="…"` from HTML when the plugin is disabled. **verify:** unit test
  on an HTML string.
- **AC-010** · P1 · P0 · build — a production build of `examples/vite-react`
  contains zero occurrences of `data-pin`, `PinScope`, or `pinscope` in
  emitted JS/HTML/CSS. **verify:** `grep -rc` over `dist/` returns 0.
- **AC-011** · P1 · P2 · build — `transformJSX` returns a non-null source map.
  **verify:** unit test asserts `result.map` is defined.
- **AC-012** · P1 · P2 · build — `getElementName` correctly resolves
  `JSXIdentifier`, `JSXMemberExpression`, and `JSXNamespacedName`. **verify:**
  three unit tests.
- **AC-013** · P1 · P1 · build — the plugin honours `filePattern` and
  `excludePattern` (a `.test.tsx` file is skipped). **verify:** unit test.

### A.2 Runtime — Core

- **AC-020** · P1 · P0 · runtime — `<PinScope/>` renders `null` when
  `process.env.NODE_ENV === 'production'`. **verify:** RTL test under prod env.
- **AC-021** · P1 · P1 · runtime — `<PinScope/>` renders `null` when
  `enabled={false}`. **verify:** RTL test.
- **AC-022** · P1 · P1 · runtime — the HUD is portal-rendered into
  `document.body` under `[data-pinscope-ui="root"]`. **verify:** RTL test
  queries `document.body`.
- **AC-023** · P1 · P0 · runtime — every `[data-pin]` element shows a badge
  whose text equals its `data-pin` value (CSS `::before`). **verify:**
  Playwright reads `::before` `content` for a sample of 5 pins.
- **AC-024** · P4 · P2 · runtime — void elements (`img`, `input`, `br`) receive
  a JS-overlay badge positioned over them. **verify:** Playwright asserts an
  overlay div with matching pin id over an `<img>`.
- **AC-025** · P4 · P2 · runtime — a MutationObserver assigns `e_r{N}` IDs to
  elements added at runtime. **verify:** integration test injects a node, polls
  for `data-pin` starting `e_r`.
- **AC-026** · P1 · P1 · runtime — `useHoveredElement` returns the nearest
  `[data-pin]` ancestor of the element under the cursor. **verify:** unit test
  with a nested DOM, simulated `mousemove`.
- **AC-027** · P1 · P1 · runtime — hover detection ignores elements inside
  `[data-pinscope-ui]`. **verify:** unit test hovering the HUD → `null`.

### A.3 Runtime — Components

- **AC-030** · P1 · P1 · runtime — InfoPanel renders Dimensions, Spacing, and
  Typography sections with values from `getComputedStyle`/`getBoundingClientRect`.
  **verify:** Playwright hovers a `<button>` and asserts width/height/padding/
  font-size text.
- **AC-031** · P2 · P2 · runtime — InfoPanel renders Appearance, Layout, and
  Hierarchy sections. **verify:** Playwright asserts section presence + a value.
- **AC-032** · P2 · P2 · runtime — InfoPanel sections are collapsible and the
  collapsed state survives reload via `localStorage`. **verify:** Playwright
  collapses a section, reloads, asserts still collapsed.
- **AC-033** · P2 · P3 · runtime — color values in InfoPanel render a swatch;
  empty values render `—`. **verify:** Playwright DOM assertion.
- **AC-034** · P2 · P1 · runtime — horizontal + vertical Rulers render with
  ticks at 100px intervals labelled in monospace. **verify:** Playwright counts
  tick labels for a 1440px viewport.
- **AC-035** · P2 · P2 · runtime — Crosshair lines track the mouse and hide
  when the cursor is over the HUD. **verify:** Playwright moves mouse, asserts
  line position then absence over HUD.
- **AC-036** · P2 · P1 · runtime — GridOverlay supports all 4 modes and the
  toggle order off→pixel→baseline→column→spacing→off. **verify:** Playwright
  cycles `Shift+G` 5 times, asserts each mode's SVG pattern.
- **AC-037** · P2 · P2 · runtime — TopBar shows viewport size, grid mode,
  state override, and live pin count. **verify:** Playwright asserts the four
  fields; pin count equals `document.querySelectorAll('[data-pin]').length`.
- **AC-038** · P3 · P1 · runtime — CommandBar focuses on `Cmd/Ctrl+K` and `/`,
  navigates history with arrows, and blurs on `Esc`. **verify:** Playwright
  keyboard test.
- **AC-039** · P4 · P2 · runtime — MeasurementTool (`M`) renders Δx/Δy/
  diagonal/gap between two clicked elements. **verify:** Playwright clicks two
  fixtures, asserts the four numeric labels match computed rects.
- **AC-040** · P2 · P2 · runtime — StateOverride forces `:hover`/`:focus`/
  `:active` globally via `[data-state-override]` on `<html>`. **verify:**
  Playwright sets override, asserts a host hover rule is applied without a real
  hover.
- **AC-041** · P2 · P1 · runtime — SelectionManager mirrors the selected pin to
  the URL hash `#select=e_N` and restores it on reload. **verify:** Playwright
  selects, reloads, asserts the same pin locked.
- **AC-042** · P4 · P2 · runtime — `SnapshotManager.createSnapshot` writes a
  file matching §9.2 to `.pinscope/snapshots/`. **verify:** integration test
  triggers a snapshot, validates the JSON against the schema.
- **AC-043** · P2 · P2 · runtime — ≥95% of the §8.11 keyboard shortcuts perform
  their action. **verify:** Playwright exercises each shortcut; pass ratio ≥0.95.

### A.4 Operation Protocol

- **AC-050** · P3 · P0 · runtime — the operation parser accepts all grammar
  forms in §11 and rejects malformed input with a typed error. **verify:** ≥30
  unit cases (valid + invalid).
- **AC-051** · P3 · P1 · runtime — shortcut properties (`padding-y`, `bg`,
  `radius`, …) resolve to their CSS equivalents. **verify:** unit test per
  shortcut in §11.
- **AC-052** · P3 · P0 · runtime — a parsed operation produces an `Operation`
  object conforming to the §9.3 schema. **verify:** schema validation on 10
  sample operations.
- **AC-053** · P3 · P1 · runtime — sending an operation copies the JSON to the
  clipboard and appends an entry to `.pinscope/history.json`. **verify:**
  integration test reads clipboard + history file.
- **AC-054** · P3 · P2 · runtime — CommandBar autocomplete for pins and
  properties responds in < 50 ms. **verify:** perf test measures keypress→
  suggestion latency.

### A.5 Edge Cases

- **AC-060** · P4 · P2 · runtime — Shadow DOM hosts are marked
  `data-pin-shadow` and InfoPanel reports limited inspection. **verify:**
  integration test with a shadow root.
- **AC-061** · P4 · P3 · runtime — cross-origin iframes render an outline +
  label only (no injection). **verify:** integration test.
- **AC-062** · P4 · P3 · runtime — SVG child elements use `getBBox`+`getCTM`
  for correct viewport-space rects. **verify:** unit test on an SVG fixture.
- **AC-063** · P4 · P3 · runtime — `@media print` hides the HUD and badges.
  **verify:** Playwright print-emulation screenshot diff.
- **AC-064** · P4 · P2 · runtime — touch: tap selects, long-press (500ms)
  locks; HUD collapses below 768px. **verify:** Playwright touch emulation.
- **AC-065** · P4 · P2 · perf — with > 500 pinned elements, `mousemove`
  handling throttles to 30fps and badges < 16×16px are skipped. **verify:**
  perf test on a 600-element fixture.

### A.6 Performance

- **AC-070** · P1 · P1 · perf — initial `<PinScope/>` mount < 50 ms. **verify:**
  `performance.measure` in an integration test.
- **AC-071** · P1 · P0 · perf — hover→InfoPanel update < 8 ms/frame. **verify:**
  perf test measures the rAF callback duration.
- **AC-072** · P3 · P1 · perf — operation parse < 4 ms. **verify:** benchmark.
- **AC-073** · P1 · P0 · perf — dev bundle < 80 KB minified / < 25 KB gzipped;
  P1 sub-budget < 30 KB. **verify:** `size-limit` in CI.
- **AC-074** · P1 · P0 · perf — prod bundle adds 0 bytes of PinScope (covered by
  AC-010 at artifact level; this AC asserts the `size-limit` prod entry = 0).
  **verify:** `size-limit` prod config.
- **AC-075** · P4 · P2 · perf — snapshot of a 200-element page < 500 ms.
  **verify:** perf test.
- **AC-076** · P4 · P2 · perf — `html2canvas` is dynamically imported only on
  screenshot request (resolution I-4). **verify:** assert `html2canvas` absent
  from the initial chunk in `size-limit`/bundle analysis.

### A.7 Testing & Tooling

- **AC-080** · P1 · P1 · test — `npm test` runs Vitest green with the AST
  transformer suite ≥ 50 input/output pairs. **verify:** CI test count + exit 0.
- **AC-081** · P3 · P1 · test — operation-parser suite has ≥ 30 cases.
  **verify:** CI test count.
- **AC-082** · P2 · P1 · test — Playwright integration suite drops PinScope
  into `examples/vite-react` and passes the §14 checklist. **verify:** CI.
- **AC-083** · P4 · P3 · test — visual-regression suite runs across the §14
  matrix. **verify:** CI artifact diff.
- **AC-084** · P1 · P2 · build — `tsc --noEmit` passes with `strict: true`.
  **verify:** CI typecheck.

### A.8 Deployment

- **AC-090** · P3 · P1 · integration — `package.json` exposes the export map
  `pinscope/vite`, `pinscope/runtime`, `pinscope/next`, `pinscope/webpack`.
  **verify:** unit test resolves each subpath.
- **AC-091** · P1 · P1 · integration — `src/index.ts` re-exports `pinscope`,
  `PinScope`, `useDevState`, and the four public types. **verify:** type-level
  + runtime import test.
- **AC-092** · P4 · P2 · integration — `withPinScope` (Next.js) and
  `PinScopeWebpackPlugin` are importable and return valid config objects.
  **verify:** unit tests.

### A.9 APEX Integration  *(Phase P5 — see §17)*

- **AC-100** · P5 · P1 · integration — `framework/apex-skills/pinscope.md`
  exists and follows the apex-skill format (Conventions / Anti-Patterns /
  Patterns / Testing / Gotchas headings). **verify:** `grep` for the five
  headings; file present.
- **AC-101** · P5 · P1 · integration — `framework/scripts/sync-to-claude.sh`
  delivers `pinscope.md` to `~/.claude/apex-skills/`. **verify:**
  `sync-to-claude.sh --dry-run` output lists the file.
- **AC-102** · P5 · P1 · integration — `/apex:ui-phase` contains a step that
  scaffolds PinScope (plugin + `<PinScope/>`) into the target project.
  **verify:** `grep` for the PinScope scaffold step in `ui-phase.md`.
- **AC-103** · P5 · P2 · integration — `/apex:ui-review` contains a step that
  ingests a PinScope Snapshot/Operation as review evidence. **verify:** `grep`
  in `ui-review.md`.
- **AC-104** · P5 · P2 · integration — architect / frontend-specialist add
  `pinscope` to `STATE.json.stack_skills` for frontend projects. **verify:**
  `grep` for `pinscope` in `architect.md`/`frontend.md` skill-selection logic.
- **AC-105** · P5 · P1 · integration — `apex-spec.md` registers PinScope in the
  extension/module model. **verify:** `grep` for `PinScope` in `apex-spec.md`.
- **AC-106** · P5 · P2 · integration — `/apex:health-check` passes with the new
  skill and command edits in place. **verify:** run `/apex:health-check`.
- **AC-107** · P5 · P3 · integration — an end-to-end design session
  (`/apex:ui-phase` → PinScope Operation → executor applies → `/apex:ui-review`)
  resolves a UI change in ≤ 2 communication rounds. **verify:** scripted
  scenario in `examples/`, round count asserted.

---

# Appendix B — Convergence Loop Contract (PS-R{N})

The PinScope self-healing loop reuses APEX's proven `R{N}` methodology with an
independent round counter (`PS-R1`, `PS-R2`, …).

**Per-round procedure:**
1. **Audit** — the `auditor` agent diffs every Appendix-A AC against the
   `pinscope/` reality tree → `convergence/audit-findings-R{N}.md`. Each
   finding: `F-{N}-{seq}`, AC reference, severity, current state, and a
   **re-read verification step** (guards against APEX learning AP-006 "The
   Unchecked Audit").
2. **Remediate** — `convergence/REMEDIATION-PLAN-R{N}.md`, authored per
   `framework/docs/REMEDIATION-STYLE.md` (content anchors, not line numbers;
   5 mandatory sections per R-item).
3. **Wave** — `convergence/WAVES-R{N}.md`: dependency-ordered,
   write-serial-safe (one file = one owner per wave); build module before
   runtime; runtime before APEX integration.
4. **Execute** — APEX pipeline (`executor` + `frontend-specialist`); each wave
   emits `convergence/WAVE-{N}-RESULT.md`.
5. **Verify** — `verifier` + `critic` re-run the `verify:` check of every AC
   the wave claimed to close. A claim without a passing check stays `OPEN`.
6. **Close** — `convergence/ROUND-R{N}-CLOSURE.md`: closed, still-open,
   convergence metric.

**Convergence metric:** `closed_AC / total_AC`, recorded each round in
`convergence/STATUS.md`; must be **monotonically non-decreasing**.

**Convergence condition (loop terminates):** zero `OPEN` findings at severity
P0–P2 **and** every Phase-DoD AC `CLOSED`. P3 findings may be moved to
`BACKLOG` by explicit user decision.

**Circuit breaker (halt + escalate to user):** a finding that survives 3
consecutive rounds with no status change, OR a wave that fails verification 3
times — triggers a stop using `framework/hooks/circuit-breaker.sh` semantics.
