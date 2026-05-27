# R-P8-B G2+G5 CRITIC (combined) — SGC-001 spec closure

## Overall verdict: PASS

The 13-line insertion at `apex-spec.md:303-313` fulfills the plan's
required content (5 numbered points), is grep-discoverable on all three
required anchors, contradicts nothing in the existing hook-list block,
and uses the established IMP-V8 anchor convention with a globally
unique identifier (`IMP-V8-P8-001`). Bilingual style matches the
surrounding paragraphs verbatim. The hook list (10 broken + 5
grandfathered) maps 1-to-1 to T7-NC.md F-001..F-010 and to the
plan's "Scope decisions ratified by owner" grandfathered set. The
behavior-not-implementation invariant is explicit ("the contract
mandates observable behavior; helper recommended but not mandatory").
No BLOCKING items; no NITs that justify a re-spin.

---

## Per-criterion findings (1-7)

### Criterion 1: Grep-discoverability — PASS

- `grep "Hook input-extraction" apex-spec.md` → hit at line 303
  (section heading).
- `grep "F-001" apex-spec.md` → hit at lines 305 (cross-ref), 309
  (defect class label), 313 (family enumeration).
- `grep "_hook-input.sh" apex-spec.md` → hit at lines 305 (SSoT
  declaration), 311 (behavior-not-implementation clause).

All three anchor terms each return the new section. Discoverability
satisfied.

### Criterion 2: 5-point content coverage — PASS

| Plan point | Spec location | Coverage |
|---|---|---|
| (1) Contract argv→stdin/jq→empty | Line 305 | "priority הקנוני: argv → stdin/jq → empty" — verbatim |
| (2) Fallback order rationale | Line 307 | "27 callsites… 9 hooks distinct… production wiring… fail-safe-to-0" — all three tiers justified |
| (3) Discrepancy ban + dual gates | Line 309 | "defect class F-001 … dead code… round-checker TP-2 §6.b clause (x) ב-audit time … lint-hook-input.sh ב-commit time" — both gates named |
| (4) Helper SSoT framing | Lines 305 + 311 | "helper SSoT הקנוני… private extractors מותרים לתאימות לאחור" + ".cjs hooks פטורים… לא פטורים מה-contract" |
| (5) Cross-references | Line 305 | "axis-13.e anchor: framework/agents/specialist/framework-auditor.md; round-checker.md TP-2 §6.b clauses (vii)+(viii)+(x)" — both axis-13.e AND clauses (vii)/(viii)/(x) named |

All 5 plan-mandated points present. Minor observation (non-blocking):
the plan said clauses "(vii)+(viii)+(x)" — spec correctly omits (ix)
because (ix) is already an existing clause per
calm-cuddling-corbato.md:310 and (x) is the new audit gate
introduced by R-P8-D.

### Criterion 3: Behavior-not-implementation — PASS

Line 311 explicitly: "ה-contract הזה מחייב התנהגות תצפיתית
(`argv_exit == stdin_exit` for matched payload); ה-helper
`_hook-input.sh` מומלץ כ-canonical implementation אבל אינו mandatory
— hooks ב-`.cjs` שקוראים stdin native, או hooks בעתיד עם
input-extraction shape ייחודית, פטורים מהשימוש ב-helper אך לא פטורים
מה-contract."

Observable invariant (`argv_exit == stdin_exit`) is testable and
implementation-agnostic. Spec flexibility for future Node-only hooks
preserved. This is a textbook contract-first specification.

### Criterion 4: Contradiction-freeness — PASS

Searched lines 80-300 region for any P0/P1 hook entry that prescribes
`${1:-}`-only input extraction:

- Lines 85, 86 (circuit-breaker.sh) — describes deny-detection
  semantics ("hash 200 chars of error message"), not input extraction.
  No contradiction.
- Lines 180, 199, 200, 214, 281, 284, 287, 294 (destructive-guard,
  exfil-guard mentions) — all describe deny-patterns/exit codes; none
  prescribe positional argv as the input source. No contradiction.
- Line 287 (apex-prompt-guard.cjs) — already a .cjs hook; the new
  section explicitly carves out `.cjs` from helper-mandate at line 311.
  No contradiction.

The new section adds a structural P0 requirement that is orthogonal to
every existing hook-list entry. Zero contradictions detected.

### Criterion 5: IMP anchor convention — PASS

Format inspected against precedents:

- New anchor: `*(IMP-V8-P8-001)*` (line 313)
- Precedent 1: `*(self-derived, IMP-V8-CB2)*` (line 86) — same italic
  parenthetical pattern, same `IMP-V8-` prefix.
- Precedent 2: `*(Master §11 P2-2; ...; IMP-DR-021)*` (line 301) — same
  italic parenthetical pattern with semicolon-separated cross-refs.

The new section's parent reference at line 305 also matches the
multi-token precedent:
`*(F-001 family closure; Phase 8 R-P8-A + R-P8-C; axis-13.e anchor: ...; SGC-001 spec gap closed)*`
— mirrors line 301's structure exactly.

**Uniqueness:** `grep "IMP-V8-P8-001"` returns exactly 1 match
(apex-spec.md:313). No collision with existing `IMP-V8-CB2`,
`IMP-DR-*`, or `IMP-0NN` anchors. Globally unique.

### Criterion 6: 15-hooks list accuracy — PASS

**10 broken hooks** (line 313) vs T7-NC.md F-001..F-010:

| F-id | T7-NC.md hook | Spec line 313 | Match |
|---|---|---|---|
| F-001 | destructive-guard | destructive-guard | yes |
| F-002 | exfil-guard | exfil-guard | yes |
| F-003 | path-guard | path-guard | yes |
| F-004 | quarantine-guard | quarantine-guard | yes |
| F-005 | sequence-guard | sequence-guard | yes |
| F-006 | subagent-guard | subagent-guard | yes |
| F-007 | grader-search-guard | grader-search-guard | yes |
| F-008 | post-write | post-write | yes |
| F-009 | ast-kb-check | ast-kb-check | yes |
| F-010 | schema-drift | schema-drift | yes |

**5 grandfathered hooks** (line 313) vs calm-cuddling-corbato.md:26
(owner-ratified scope):

| Plan-named | Spec line 313 | Filesystem confirmed |
|---|---|---|
| owner-guard | owner-guard | `ls` PASS |
| ci-scan | ci-scan | `ls` PASS |
| test-deletion-guard | test-deletion-guard | `ls` PASS |
| pre-task-snapshot | pre-task-snapshot | `ls` PASS |
| workflow-guard | workflow-guard | `ls` PASS |

10 + 5 = 15. Arithmetic correct. All 15 files exist on disk.

### Criterion 7: Bilingual style parity — PASS

Spot-check of 3 adjacent lines for style consistency:

- **Line 297** (immediately above the new block, P3 IMP-082):
  Hebrew lead-in + English technical phrase "adaptive thinking as
  security default" + Hebrew justification + English code references.
- **Line 301** (the line before the new section, IMP-DR-021):
  Hebrew lead-in + 5-element English list `(a)..(e)` + English code
  identifiers + Hebrew connective tissue + `*(...)*` italic anchor.
- **Line 305** (new section main paragraph):
  Hebrew lead-in + English `argv → stdin/jq → empty` + Hebrew
  ("הוא ה-SSoT הקנוני") + English file paths + `*(...)*` italic anchor.

Style is indistinguishable from surrounding paragraphs. The new
section reads as if written by the same author as lines 296-301.
Parity confirmed.

---

## Confidence + rationale

**Confidence: 0.97** — every grep, every file existence check, every
cross-reference traceable from spec ↔ plan ↔ T7-NC.md ↔ filesystem
matched. The one residual uncertainty (0.03 reserved):
`framework/scripts/lint-hook-input.sh` is referenced at line 309 but
does not yet exist on disk — this is correct per plan (R-P8-E in
Wave 4) and is a deliberate forward-reference, but a reader landing
on this section before Phase 8 closure could be momentarily confused.
This is acceptable forward-binding semantics (the spec describes the
end-state contract; implementation completion is the
verification-gate's job) and matches how IMP-V8-CB2 and IMP-DR-021
forward-reference future hooks. Not a defect.

**Verdict: PASS.** Spec closure SGC-001 is structurally complete,
discoverable, contradiction-free, behaviorally specified, and ready
to anchor downstream R-P8-C/D/E work.
