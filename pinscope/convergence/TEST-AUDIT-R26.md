# PinScope Test-Quality Audit -- R26

Status: complete
Round: 26
Verdict: FAIL
Generated: 2026-05-27
Scope: 32 vitest files (pinscope/tests/) + 7 convergence engine .mjs files (pinscope/convergence/lib/test/).

---

## Quarantine compliance

- PinScope-mode invocation (PS-R26 convergence loop, sanctioned per CLAUDE.md as a standalone extension outside the APEX framework pipeline). The dispatcher preflight contract (APEX_ACTIVE_AGENT=auditor) does not apply to PS-mode; PinScope rounds have their own loop machinery under pinscope/convergence/.
- Read scope: ONLY test files under pinscope/tests/ and pinscope/convergence/lib/test/ plus the matrix manifest pinscope/convergence/ac-matrix.json.
- No reads under pinscope/src/. No source code consulted; every assertion below is derived from test source alone.
- Write scope: this file only.

## Inputs ingested

- pinscope/convergence/audit-findings-R26.json -- F-26-01 (P1, markCrossOriginFrames duplicate-overlay leak), F-26-02 (P3 hollow plugin), F-26-03 (P3 stale doc-comments).
- pinscope/convergence/narrative-scan-R26.json -- NC-12-06 flipped to uncovered_unsatisfied (the R24 false-PASS).
- vitest run: 381 PASS / 32 files.
- ac-verify R26: 62 PASS / 6 UNAVAILABLE / 1 MANUAL / 0 FAILs.
- R25 baseline: COMPREHENSIVE-TEST-QUALITY-AUDIT-R25.md (13-point taxonomy carried forward).

---

## Headline

**1 FAIL-class finding** -- AC-061 / NC-12-06 confirmed independently from test source as a **single-call coverage of multi-call invariants** false-PASS. The other ~96 percent of the corpus is clean against the R25 bar.

---

## Per-AC findings (FAIL-class)

### AC-061 / NC-12-06 -- single-call coverage of multi-call invariants

- **File:** `pinscope/tests/unit/runtime/iframe-overlay.test.ts` (entire describe block at lines 28-124, 8 it cases)
- **False-PASS class:** Class 4 -- single-call coverage of multi-call invariants.
- **Evidence (test source alone):** every test in the file invokes `markCrossOriginFrames(document)` exactly ONCE -- at file lines 33, 66, 84, 95, 105, and 117. The 4th test (lines 52-76) goes furthest: it asserts `expect(overlays.length).toBe(2)` after appending two cross-origin frames -- but a duplicate-overlay leak only manifests on the SECOND invocation of the helper on the same document (the helper appends without first deleting prior overlays). Searched the entire file for any second call to `markCrossOriginFrames` within a single test: zero occurrences. The 4th test name ("marks ..., returns the count, and appends one overlay each") suggests idempotency coverage, but the assertion only locks the post-first-call count, not the post-second-call count.
- **Why this is a false-PASS for AC-061:** the per-round audit-findings-R26.json F-26-01 record describes a production duplicate-overlay leak on re-invocation. ac-verify reports AC-061 as PASS because the file has 8 tests all tagged AC-061 and they all pass -- but the test corpus is structurally incapable of catching the defect. R24 logged this as a satisfied narrative claim; R26 flipped NC-12-06 to uncovered_unsatisfied.
- **Proposed strengthening:** add a 9th test, name suggestion "is idempotent under repeated invocation (AC-061)" -- appendChild a single cross-origin frame, call `markCrossOriginFrames(document)` TWICE on the same document, then assert `document.querySelectorAll(\"[data-pinscope-iframe-overlay]\").length` is still 1 (not 2). Optional 10th test: appendChild two cross-origin frames, call once, remove one frame, call again, assert overlay count tracks live cross-origin frame count (kills the leak AND a stale-overlay variant). Both share the existing `makeCrossOrigin(frame, \"throw\")` helper. Estimated +20 LoC. Mutation gate: in production, the patch is `removeExistingOverlays(document); for (frame of frames) { ... }` at the top of `markCrossOriginFrames`; removing that line returns the new tests RED.

---

## Per-file sweep table

Legend: CLEAN = substantive multi-assertion coverage. FAIL = at least one false-PASS class confirmed.

Total: 39 files swept (32 vitest + 7 mjs). 38 CLEAN. 1 FAIL.

| File (relative to pinscope/) | ACs touched | Status | Notes |
|---|---|---|---|
| tests/unit/ast-transformer.test.ts | AC-002/003/004/005/011/012/080 | CLEAN | 56-fixture it.each + opt-out trio with mutation gate |
| tests/unit/claude-bridge.test.ts | AC-053 | CLEAN | clipboard payload + 1000-entry cap, both asserted |
| tests/unit/deployment.test.ts | AC-090/091/092 | CLEAN | exports map + dynamic-import via node subprocess + frozen-input mutation guard |
| tests/unit/edge-utils.test.ts | AC-062/065 | CLEAN | SVG ctm + throttle + heavy-page threshold |
| tests/unit/long-press.test.ts | AC-064 | CLEAN | tap vs long-press + compact-viewport |
| tests/unit/operation-builder.test.ts | AC-052 | CLEAN | 10-sample it.each schema validator |
| tests/unit/operation-parser.test.ts | AC-050/081 | CLEAN | 38-input grammar coverage, valid+invalid |
| tests/unit/operation-perf.test.ts | AC-054/072 | CLEAN | parse <4ms, suggest <50ms |
| tests/unit/pin-map.test.ts | AC-006/007/008 | CLEAN | monotonicity invariants incl. soft-delete-no-reuse mutation gate |
| tests/unit/pin-map-schema.test.ts | AC-006 | CLEAN | hand-rolled validator + missing-field + wrong-type rejection cases |
| tests/unit/plugin.test.ts | AC-001/009/013 | CLEAN | plugin shape + transform gating + dev-server snapshot+history routes |
| tests/unit/production-stripper.test.ts | AC-009 | CLEAN | 4 strip cases incl. attribute-preservation |
| tests/unit/property-shortcuts.test.ts | AC-051 | CLEAN | source-driven it.each with resolves-to-different-CSS mutation guard |
| tests/unit/roundtrip.test.ts | AC-107 | CLEAN | derives completeness predicate independently from the demo + explicit negative case |
| tests/unit/runtime/components.test.tsx | AC-021/022 | CLEAN | kill-switch dual + portal-identity dual |
| tests/unit/runtime/controls.test.tsx | AC-035/037/038/040/053 | CLEAN | TopBar live-state wiring + StatePanel stylesheet scan + CommandBar local-only history disjunct + R-25-10 parse-failure cases |
| tests/unit/runtime/edge-cases.test.ts | AC-025/060 | CLEAN | observer assign + nested children + shadow-host marking |
| tests/unit/runtime/element-walker.test.ts | AC-026/027 | CLEAN | utility-level findPinnedAncestor + escapeHud null-input cases |
| tests/unit/runtime/flow-wiring.test.tsx | (untagged) | CLEAN | flow B/C/D wiring + unhandled-rejection guard (no swallow) |
| tests/unit/runtime/history-persist-ownership.test.tsx | (untagged) | CLEAN | F-18-01 duplicate-row regression |
| **tests/unit/runtime/iframe-overlay.test.ts** | **AC-061** | **FAIL** | **see Per-AC findings above** |
| tests/unit/runtime/infopanel.test.tsx | AC-031/032/033 | CLEAN | section render + localStorage persistence + SSR-undefined guard with mutation gate |
| tests/unit/runtime/overlays.test.tsx | AC-024/034/035/036/039 | CLEAN | multi-scale rulers + crosshair HUD filter + grid cycle + measure math + badge important via getPropertyPriority |
| tests/unit/runtime/perf.test.tsx | AC-070/071 | CLEAN | median-of-3 mount-time + relative-3x per-frame baseline |
| tests/unit/runtime/pinscope-assembly.test.tsx | (untagged) | CLEAN | seven-component mount + shortcutsEnabled gate + production guard |
| tests/unit/runtime/pinscope.test.tsx | AC-020/021/022/024/025/070 | CLEAN | multi-tag void integration + nested e_r assignment + heavy-page throttle proxy via elementFromPoint instrumentation |
| tests/unit/runtime/public-api.test.ts | AC-091 | CLEAN | documented-surface set-equality + explicit no-undocumented-export guard |
| tests/unit/runtime/selection.test.tsx | AC-041 | CLEAN | URL-hash mirror + select-command-locks-InfoPanel (F-17-01 regression) |
| tests/unit/runtime/shortcuts.test.tsx | AC-043 | CLEAN | EXPLICIT hardcoded table parallels SHORTCUTS for tautology-killing positive AND negative shift assertions |
| tests/unit/runtime/snapshot.test.tsx | AC-042/075 | CLEAN | schema validator + endpoint POST + non-ok rejection (no swallow) + 200-element perf |
| tests/unit/runtime/useHoveredElement.test.tsx | AC-026/027 | CLEAN | empty-data-pin discriminator + 5 nearest-ancestor cases + 3 HUD-filter cases |
| tests/unit/screenshot.test.ts | AC-076 | CLEAN | lazy-import behavioral test via factory-evaluation flag; mocks external html2canvas, not the SUT |
| convergence/lib/test/ac-eval.test.mjs | engine | CLEAN | parseVitestReport+Playwright + envAvailable + evalCriterion across all verify.kind variants |
| convergence/lib/test/loop-logic.test.mjs | engine | CLEAN | recomputeMetric + applyResults including HARNESS_ERROR no-record + breaker trip+auto-reset + provenance ledger drop-on-regress |
| convergence/lib/test/meta.test.mjs | engine | CLEAN | engine isolation guard |
| convergence/lib/test/mutate.test.mjs | engine | CLEAN | mutation primitives incl. word-boundary trueish non-mutation |
| convergence/lib/test/render.test.mjs | engine | CLEAN | renderStatus header + blocked-listing + narrative-coverage section |
| convergence/lib/test/schema.test.mjs | engine | CLEAN | validateLoop+Matrix+Results across positive + multiple negative shapes |
| convergence/lib/test/spec-hash.test.mjs | engine | CLEAN | hash determinism + drift + firstRun branches |

---

## Test-suite hygiene

- No skip-marker abuse. Zero it.skip, it.todo, describe.skip, or it.fails calls in any of the 39 files.
- vi.mock usage is bounded. The only top-level vi.mock() call is in screenshot for the external html2canvas library (legitimate -- the SUT is captureScreenshot, which is exercised real; the mock measures the lazy-import contract via a moduleState.evaluated factory flag). All other vi.spyOn / vi.stubGlobal calls observe rather than replace the SUT.
- Mutation gates are documented. Nearly every R25-added case carries an inline comment naming the specific mutation it kills (e.g., kills the || -> && mutant on useHoveredElement, kills any tag-filter narrowing in VOID_TAGS). The R25 mutation-gate discipline is preserved post-R25.
- Threshold strategy is honest. AC-070 uses median-of-3 with documented rationale; AC-071 uses relative 3x baseline rather than the spec absolute 8ms (with explicit production-vs-test-env reasoning). The R25 AC-070 flake carve-out is NOT silently broadened.
- Empty-vs-absent discrimination. AC-061 (the FAIL above) aside, assertions routinely distinguish absent from present-but-empty -- a vacuous-true class killed at the assertion level.
- Cross-file consistency. AC-006 is locked from two angles -- happy-path round-trip in pin-map AND the hand-rolled validator in pin-map-schema. AC-024 is locked from isolation (overlays line 199) AND integration (pinscope line 69, 3-tag count) -- a refactor breaking one path is caught by the other.

---

## Cross-reference to round inputs

- F-26-01 (P1) -- re-confirmed as AC-061 false-PASS. Remediation is a one-line second invocation in a new case in iframe-overlay. Production fix to markCrossOriginFrames (deduplicate before append) is out of audit scope; the audit only proves the gap.
- F-26-02 (P3 hollow plugin) -- not visible from the audited corpus alone. The plugin and deployment files exercise the plugin lifecycle; vitest is GREEN, so F-26-02 likely concerns a non-tested adjacency. Out of audit read scope.
- F-26-03 (P3 stale doc-comments) -- doc-comment audit, not test-quality. Out of scope.
- NC-12-06 -- the narrative-coverage flip is the same finding as AC-061 above; both resolved by the proposed new case in iframe-overlay.

---

## Verdict

FAIL -- one false-PASS family confirmed (AC-061 / NC-12-06 idempotency gap). The missing case is for a P1-severity production defect already independently confirmed by the audit-findings-R26 input. Per the contract: FAIL = at least one false-PASS found. Remediation is a single new case (about 20 LoC); R27 should re-run this audit after the case is added to confirm CLEAN.

## Summary

39 files swept (32 vitest + 7 convergence engine). 38 CLEAN against the R25 false-PASS taxonomy. One FAIL: iframe-overlay (8 cases, all AC-061-tagged) calls markCrossOriginFrames exactly once per case, structurally incapable of catching the duplicate-overlay leak defect that requires a second invocation to surface -- single-call coverage of a multi-call invariant. Hygiene otherwise excellent: no skip abuse, mutation-gate comments preserved post-R25, vi.mock only used for external deps, threshold strategies honestly documented. Remediation: add one idempotency case (about 20 LoC) calling the helper twice on the same document and asserting overlay count stays at 1.
