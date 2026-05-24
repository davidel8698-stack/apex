# Round Closure — PS-R20

**Closed:** 2026-05-24
**ps-verifier verdict:** **PARTIAL** (see `VERIFY-R20.md`)
**Phase cursor:** advancing `verify → idle`

## Round summary

PS-R20 was a **reconcile-and-close** round: the wave plan
(`REMEDIATION-PLAN-R20.md` + `WAVES-R20.md`) was authored on 2026-05-22 but
the wave commits for R-20-01/02/03 landed outside the state machine on
2026-05-24 (commit `98841a4`), leaving `loop.json.phase = schedule` with no
on-disk wave-result, verify, or closure artifacts. The resuming
orchestrator re-entered at `wave`, confirmed R-20-01/02/03 satisfy each
R-item's pre-written DoD, executed the two still-open R-items (R-20-04
investigation-only, R-20-05 two CommandBar tests), drove STEP 6
verification, and is closing here.

## R-item outcomes (all 5 closed against DoD)

| R-ID | Closure | Files | Wave |
|---|---|---|---|
| **R-20-01** | CLOSED — VoidBadges mounted into visible-HUD `createPortal` tree (DoD test green; mutation-killed 5/5) | `src/runtime/PinScope.tsx` | W1 (commit `98841a4`) |
| **R-20-02** | CLOSED — `RuntimePinObserver` lifecycle `useEffect` start/stop (queueMicrotask deferral preserves AC-070 budget; DoD test green) | `src/runtime/PinScope.tsx` | W2 (commit `98841a4`) |
| **R-20-03** | CLOSED — §8.11 Shift+P / Shift+C wired end-to-end via `pinsVisible`/`crosshairEnabled` cells (real-HUD §8.11 functional ratio 11/13 → 13/13; mutation-killed 5/5 on `Crosshair.tsx`). **Minor scheduler-noted scope shift**: visibility gate placed at parent (`{pinsVisible && <PinBadges/>}`) instead of a `visible` prop on `PinBadges.tsx`. Functional equivalence; `PinBadges.tsx` byte-for-byte unchanged. | `src/runtime/PinScope.tsx`, `src/runtime/components/Crosshair.tsx` | W3 (commit `98841a4`) |
| **R-20-04** | CLOSED as `### Resolution` (no code change). STEP-1 verdict confirmed: §10-E is non-normative prose; no Appendix-A AC requires `request_type:'annotation'` or a screenshot/annotation modal. `grep -rn 'annotation' src/runtime/` → 1 hit (`operation.annotation = topic`, NOT `request_type`). | none | W1 (in-loop) |
| **R-20-05** | CLOSED — two CommandBar Enter-path tests added (`snapshot foo`, `measure e_2 to e_3`) exercising the `measure`/`snapshot` arms of `isLocalOnlyCommand`'s disjunction; `CommandBar.tsx` byte-for-byte unchanged; the R18 `or-to-and` mutant on L49 is now killed by behavioral coverage. | `tests/unit/runtime/controls.test.tsx` (+51) | W1 (in-loop) |

## Metric (persisted state)

`loop.json` (unchanged by this closure, because `record-round` rejected the
fresh ac-verify with **MONOTONICITY VIOLATION — closed 60 < previous 62**;
see "Carry-forward" below):

| field | value |
|---|---|
| `round` | 20 |
| `loop_status` | `CONVERGED` (provisional — see PARTIAL verdict) |
| `metric.closed` | 62 |
| `metric.open` | 0 |
| `metric.blocked` | 7 |
| `metric.manual_pending` | 0 |
| `metric.total` | 69 |
| `metric.pct` | 90 |

**Fresh ac-verify (this session)** records: **60 PASS · 2 FAIL · 6
UNAVAILABLE · 1 MANUAL** — i.e. 2 ACs that were previously `CLOSED` no
longer machine-verify on this host. Per STEP 5 of the ps-verifier
contract, "a `CLOSED` AC now failing is a regression" — these are reported
under "Carry-forward to R21" below and route to the R21 input set. The
verifier's investigation shows **neither failure is an implementation
regression**:

- **AC-090 — env-host bug.** `tests/unit/deployment.test.ts > 'dynamically
  imports each built entry point'` fails because Vitest+Vite's
  `loadAndTransform` cannot URL-decode the percent-encoded Hebrew chars in
  the repo path (`%D7%93%D7%95%D7%93%D7%90%D7%9C%D7%9E%D7%95%D7%A2%D7%9C%D7%9D`).
  `dist/index.js` exists and is correct; the other 9 AC-090 sub-cases in
  `deployment.test.ts` PASS; subpaths under `dist/runtime/` and
  `dist/plugin/` load fine. The failure is **host-bound**, not code-bound.

- **AC-104 — matrix-stale path.** `ac-matrix.json`'s AC-104 verify recipe
  greps for `pinscope` in `framework/agents/architect.md` (still present —
  1 hit) AND `framework/agents/specialist/frontend.md` (the file does not
  exist on disk). Commit `6942038` (2026-05-06) `git mv`'d `frontend.md`
  to `framework/modules/apex-frontend/agent.md`; the new file already
  contains the pinscope mention (`agent.md:12`). The SPEC AC-104 intent
  ("grep for pinscope in architect.md/frontend.md skill-selection logic")
  IS satisfied at the new path; the matrix witness is stale. Per
  `/ps-heal` GUARD "the loop never auto-edits the matrix" — matrix
  authorship is a user-approved change, not an in-loop fix.

The third non-PASS, **AC-106**, is `MANUAL_PENDING` (not regression —
status change). The `apex-install` env capability is now `true` (preflight
this session). The verifier may not close `manual`-kind ACs by proxy.
Closing requires `loop-state.mjs manual-attest AC-106 pass "<evidence>"`
after `/apex:health-check` runs to completion against a synced
`~/.claude/`. **`~/.claude/apex-skills/pinscope.md` is currently missing**
(framework/apex-skills/pinscope.md exists but was never synced) — so
`/apex:health-check` would surface the gap, and no honest `pass` attest
is available this session.

## Narrative coverage

Pointer: `narrative-scan-R20.md` (full claim ledger).

| field | value |
|---|---|
| `total_claims` | 52 |
| `covered` | 33 |
| `uncovered` | 19 |
| `uncovered_satisfied` | 19 (all uncovered claims are non-normative or aggregate-statistic prose with code-satisfied evidence) |
| **`uncovered_unsatisfied`** | **0** |
| `candidate_acs` | 19 (proposals for the loop owner; SPEC bump required) |
| `strengthen_proposals` | 6 |

No `blocking_findings` from the narrative scan. Convergence on the
**narrative-coverage axis is clean** — every observable claim in §1–§17
either has an AC or is non-normative/aggregate prose with code evidence.

## Trajectory

**STAGNANT-WITH-VERIFIER-DRIFT.** The metric ledger is unchanged from
R10–R20 (closed=62 throughout — see `metric_history`). R20's R-items closed
on disk, but the recorded metric does not advance because the only items
"open" at round-entry were investigation-class findings whose closure is a
`### Resolution` (R-20-04) or a coverage-margin test (R-20-05) — neither
flips an AC verdict. The 2 new FAILs are verifier/env drift (matrix path
stale; Hebrew-path host bug), not code drift. Classification: not
IMPROVING (no metric gain), not DIVERGING (no genuine code regression),
not STAGNANT (verifier drift surfaced), so **STAGNANT-WITH-VERIFIER-DRIFT**
— a sub-class of STAGNANT requiring matrix/env attention, not code work.

## Circuit-breaker status

- `loop_status`: `CONVERGED` (persisted) / `PARTIAL` (this round's
  verifier verdict). The persisted CONVERGED is provisional pending the
  R21 cleanup.
- `breaker_log`: empty.
- `stalled-finding` check: no R20 finding has survived 3 rounds (these are
  all new this round).
- `wave-fails` check: 0 (waves passed their gates).
- `diverging` check: 0 (OPEN P0/P1 count did not grow; the 2 new FAILs are
  matrix/env, not code).

Breaker NOT tripped.

## Carry-forward to R21 (inputs)

Five items routed forward; none is a code defect:

1. **AC-104 stale matrix path** — `convergence/ac-matrix.json` AC-104
   recipe still points at `framework/agents/specialist/frontend.md`
   (moved on 2026-05-06). R21 should update the matrix path or widen the
   recipe. User approval required for matrix edits.

2. **AC-090 Vitest+Vite Hebrew-path dynamic-import bug** — host
   environment cannot URL-decode the cwd. Options for R21: (a) re-classify
   the failing sub-case as `BLOCKED` env=`unicode-safe-path`; (b) rewrite
   `tests/unit/deployment.test.ts`'s dynamic-import case to spawn a
   separate node process bypassing Vite's loader; (c) move the project
   out of a Hebrew-named directory (out-of-loop).

3. **AC-106 MANUAL_PENDING + framework-sync-gap** — `~/.claude/apex-skills/`
   is missing `pinscope.md`; `~/.claude/commands/ps-heal.md` is missing.
   Both exist in `framework/`. The PinScope SPEC's APEX-integration phase
   (§17) requires these to land in the user-level install for AC-106 to
   attest. R21 should add a sync-step R-item OR document the build path
   in `framework/scripts/sync-to-claude.sh` to ensure `apex-skills/`
   under `framework/` ships to `~/.claude/`.

4. **Provisional CONVERGED flag** — `loop.json.loop_status = CONVERGED`
   does not reflect the PARTIAL verdict. R21's record-round (after the
   AC-104 matrix fix and AC-090 reclassification) will recompute the metric
   and either restore true convergence or correctly mark `IN_PROGRESS`.

5. **Wave-execution-outside-loop doctrine gap** — this round's R-20-01/02/03
   landed via a manual commit (`98841a4`) bypassing `ps-wave-executor`
   spawn / `WAVE-R{N}-RESULT.md` write-as-you-go / wave-snapshot capture.
   The orchestrator's resume path reconciled it, but a doctrine entry for
   `/ps-heal` should make the "out-of-loop wave commit" reconciliation
   procedure first-class (see commit `fcf0afd` /ps-heal doctrines
   backlog). Non-blocking; tracked.

## Provenance

- Audit findings: `audit-findings-R20.{md,json}`
- Narrative scan: `narrative-scan-R20.{md,json}` (coverage 33/52; 0
  `uncovered_unsatisfied`)
- Test-quality audit: `TEST-AUDIT-R20.md` (verdict PASS; no false PASS)
- Remediation plan: `REMEDIATION-PLAN-R20.md` (5 R-items; ACCEPTED)
- Wave map: `WAVES-R20.md` (3 waves; ACCEPTED)
- Wave result: `WAVE-R20-RESULT.md` (5 R-items closed against DoD)
- Mutation report: `mutation-R20.json` (10 mutants · 10 killed · 0 survived)
- AC verify (final): `ac-results-R20.json` (60 PASS · 2 FAIL · 6
  UNAVAILABLE · 1 MANUAL)
- Verifier report: `VERIFY-R20.md` (verdict PARTIAL; rejected 0;
  regressions 2)
- Commits (round window `91eb6f0..HEAD`): `a776b95`, `fcf0afd`, `28a94d0`,
  `98841a4` (the R-20-01/02/03 wave), `7aaa6ce`, `a12a7c3`. Plus the
  pending working-tree commit (this closure + `WAVE-R20-RESULT.md` +
  `VERIFY-R20.md` + `mutation-R20.json` + `ac-results-R20.json` +
  `controls.test.tsx` R-20-05 additions + `loop-events.jsonl`).
