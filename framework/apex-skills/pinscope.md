# PinScope Patterns for APEX

PinScope is a dev-only visual debug layer. It pins every DOM element with a
stable `data-pin` id (`e_47`), shows numeric properties on hover, and emits
structured `Operation` JSON so a non-technical user can communicate exact UI
changes. Use it to close the design feedback loop with certainty instead of
guessing from prose descriptions.

## Conventions
- Install dev-only: the Vite plugin `pinscope/vite` (or `pinscope/next`) injects
  `data-pin`; mount `<PinScope />` once at the app root.
- A Pin id (`e_N`) is stable across builds — refer to elements by Pin id, never
  by a brittle CSS selector, when reading user feedback.
- The PinMap (`.pinmap.json`) is the source of truth for id <-> source-location.
- An `Operation` (schema in `pinscope/SPEC.md` sec.9.3) names a `pin`, a
  `request_type`, and either `operations[]` (set / increment / add-class ...) or
  an `annotation`. Apply it as a concrete code edit at the pinned source location.

## Anti-Patterns — NEVER
- Never ship PinScope to production — it is dev-only; the plugin strips every
  `data-pin` attribute and zero bytes of PinScope reach the production bundle.
- Never hand-edit `.pinmap.json` — the build plugin owns it; ids are never reused.
- Never resolve an Operation by guessing the element — map `pin` -> source
  location via the PinMap, then edit that exact JSX node.
- Never treat a runtime `e_r{N}` id as stable — only build-time `e_N` ids persist.

## Common Patterns
```
// Reading a user Operation -> code edit
// Operation: { pin:"e_47", operations:[{property:"padding-y",operation:"set",value:"12px"}] }
// 1. PinMap entry for e_47 resolves to src/components/Cta.tsx:14
// 2. Edit that <button>: set vertical padding to 12px
```

## Testing
- Verify production builds contain zero `data-pin` / `PinScope` strings.
- After applying an Operation, confirm the rendered element's computed style
  matches the requested value — a Snapshot diff is the falsifiable check.

## Common Gotchas
- Moving an element in source = new Pin id (intentional; prevents stale refs).
- A file rename breaks Pin ids until the content-hash fallback ships (future).
- Void elements (img, input) carry a JS-overlay badge, not a CSS `::before`.
- PinScope reserves `z-index: 2147483647`; do not exceed it in application CSS.
