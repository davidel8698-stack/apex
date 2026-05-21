# PinScope Remediation Plan — PS-R5

> Per `framework/docs/REMEDIATION-STYLE.md`. Scope: example app, Snapshot
> system, Playwright suite. Source of findings: `audit-findings-R5.md`.

---

## Remediation R-501 — `examples/vite-react`

**Linked finding:** F-5-01
**Severity:** P0
**Spec anchor:** "File Structure / examples" (SPEC §5), resolution I-1, AC-010.

### Ecosystem analysis
A real Vite + React app using the `pinscope()` plugin and a **dev-only**
import of `<PinScope/>` (`import.meta.env.DEV` guard) so a production build
tree-shakes PinScope to nothing. `vite.config.ts` aliases `pinscope/runtime`
to the built `dist/`. Proves AC-010 (and AC-074 at artifact level).

### Execution plan
**Files to create:** `examples/vite-react/{package.json,index.html,
vite.config.ts,src/main.tsx,src/App.tsx}`.
**Order:** package.json → vite.config → App → main → index.html.
**Rollback trigger:** `vite build` fails, or `grep` finds a PinScope token
in the example's `dist/`.

### Acceptance criteria
- [ ] `vite build` succeeds; `grep -rc` for `data-pin`/`PinScope`/`pinscope`
  over the example `dist/` returns 0 (AC-010, AC-074).

### Dependencies
Built `pinscope/dist/` (PS-R4; `pretest` keeps it fresh).

### Risk assessment
Medium. Example build integration — alias resolution, esbuild JSX.

---

## Remediation R-502 — Snapshot system

**Linked finding:** F-5-02, F-5-03
**Severity:** P2
**Spec anchor:** "SnapshotManager" (SPEC §8.10), "Snapshot schema" (§9.2),
AC-042/AC-075.

### Ecosystem analysis
`createSnapshot()` walks every `[data-pin]`, extracts rect + tracked computed
styles + hierarchy into a §9.2 `Snapshot`. `SnapshotManager` persists via an
injected `SnapshotStore` (`runtime/` stays `node:fs`-free).

### Execution plan
**Files to create:** `src/runtime/managers/SnapshotManager.ts`.
**Order:** `createSnapshot` → `SnapshotManager` + `MemorySnapshotStore`.
**Rollback trigger:** Snapshot fails §9.2 schema validation, or 200-element
capture exceeds 500 ms.

### Acceptance criteria
- [ ] `createSnapshot()` returns a §9.2-conformant object (AC-042).
- [ ] 200-element capture < 500 ms (AC-075).

### Dependencies
None.

### Risk assessment
Low. happy-dom provides `querySelectorAll` / `getComputedStyle`.

---

## Remediation R-503 — Playwright integration suite (CI deliverable)

**Linked finding:** F-5-04
**Severity:** P1
**Spec anchor:** "Testing Strategy / Integration" (SPEC §14), AC-082.

### Ecosystem analysis
Author the §14 Playwright checklist against `examples/vite-react`. The suite
is a real CI deliverable; it **cannot run here** (`cdn.playwright.dev` not
allowlisted). AC-082 therefore moves to `BLOCKED`, not `CLOSED`.

### Execution plan
**Files to create:** `playwright.config.ts`,
`tests/integration/pinscope.spec.ts`.
**Rollback trigger:** none runnable here — verified by a browser-capable CI.

### Acceptance criteria
- [ ] Suite authored covering the §14 checklist → AC-082 `BLOCKED` (honest;
  not claimed `CLOSED`).

### Dependencies
R-501.

### Risk assessment
Low (authoring only).

---

## Remediation R-504 — Tests + verification

**Linked finding:** F-5-01..F-5-03
**Severity:** P1
**Spec anchor:** SPEC §14.

### Execution plan
**Files to create:** `tests/unit/runtime/snapshot.test.tsx`.
**Verification:** `npm run build` → `cd examples/vite-react && npx vite build`
→ `grep -rc` the example `dist/` → `npx vitest run`.
**Rollback trigger:** any check fails or a PS-R1–R4 test regresses.
**Circuit breaker:** no green verification after 3 attempts → halt.

### Acceptance criteria
- [ ] AC-010, AC-042, AC-074, AC-075 verified; 188 prior tests still green.

### Dependencies
R-501, R-502.

### Risk assessment
Medium.
