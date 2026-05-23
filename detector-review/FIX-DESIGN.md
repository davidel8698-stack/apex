# FIX-DESIGN — Detector Hardening Edits (Phase 4)

> Phase 4 of the detector-sensitivity campaign. **Input:** `ROOT-CAUSE.md`
> (8 confirmed root causes + 1 spec change) and `BASELINE.md` (Phase-2
> measurements). **Output:** the character-precise edits Phase 5 will
> apply. Every anchor below was re-read from live source at HEAD before
> writing this design — no anchor was carried over from `ROOT-CAUSE.md`
> without re-verification, per the resume contract.
>
> Baseline commit: `8ac2a858423c490d58bd22fba742c51bf0c7021a`.
> Live source files re-read (line counts per `wc -l`, no trailing-line
> convention adjustment):
> `framework/agents/specialist/framework-auditor.md` (202 lines),
> `framework/agents/specialist/round-checker.md` (192 lines),
> `framework/commands/apex/self-heal.md` (401 lines),
> `apex-spec.md` §"Self-Healing Loop" (line 348 anchor).
>
> Edit shape: pure prose / agent-definition edits + 1 spec sentence.
> Zero new files. No new hooks, schemas, agents, or tests. The fix
> raises the floor on existing detection capability proven by R203 —
> it does not add new detection capability.
>
> ## ⚠ IMPLEMENTER CONTRACT — ANCHOR BY TEXT, NOT LINE NUMBER
>
> All line numbers below are **baseline-relative at commit `8ac2a85`**.
> Edits are applied sequentially (one commit per CR in `framework-
> auditor.md` and `round-checker.md`); line numbers shift after each
> commit. Therefore: the implementer **MUST** anchor every edit on the
> verbatim text in the "Old:" block (or the explicit insert-point
> sentence), never on the line number alone. Line numbers exist only
> to help the reader find the region; the "Old:" / "New:" string pair
> is the binding contract. Two CRs that share a file have their
> regions disjoint at baseline (verified in Phase-4 critic review),
> so text-anchored sequential application is collision-free.

## Coverage matrix — one row per CR, zero orphans

| CR | Symptom from BASELINE.md | Target file | Anchor (re-verified) | Edit type | Acceptance test (Phase 6) | §9 threshold lifted |
|----|--------------------------|-------------|----------------------|-----------|---------------------------|---------------------|
| CR-01 | R201/R202 missed W-B1/B2/B3 — no bypass attempted | `framework/agents/specialist/framework-auditor.md` | end of axis 12 block (line 115); section header line 52 | INSERT new Axis 13 + rename section header | W-B1, W-B2, W-B3 reliably killed (≥2/3 trials) + tool-call count floor raised (no trial < 130 calls) | Class B+C+D working ≥7/8; held-out ≥4/5 |
| CR-02 | R201/R202 didn't run `run-all.sh` → W-D1/D2 survived | `framework/agents/specialist/framework-auditor.md` | end of TERMINATION CRITERION (line 172) | INSERT "Test-suite evidence rule" sub-section before the WRITE-FIRST CONTRACT | W-D1, W-D2 reliably killed; every trial's coverage map records either a real `run-all.sh` line or an explicit BLIND SPOT | Class D component of B+C+D ≥7/8 |
| CR-03 | R206 primed: 17 → 4 findings (76% depth loss) | `framework/agents/specialist/framework-auditor.md` | end of CORE PRINCIPLES section (line 37 — after "Do not filter early" paragraph) | INSERT new "Anti-priming" principle | W-F3 re-run: `\|neutral_count − primed_count\| ≤ 1` AND no severity downgrade | Negative control 0 fabricated; preserves regression criterion |
| CR-04 | F-204-013 — R23 fabricated "6 hits" → R24 ratified | `framework/agents/specialist/round-checker.md` | start of PROCESS (line 66) and stop-criterion block (lines 83-89) | INSERT new PROCESS step 6 ("Audit-credibility spot-check") + ADD 4th conjunct to step 5 | W-F2 re-run shows closure CONTINUE not CLOSED when an orphan P1 exists; a constructed "auditor cleared X but X is broken" scenario flips closure verdict | Independent review (`critic` PASS on final state); traceability |
| CR-05 | NEW-FINDINGS-ORCHESTRATOR-R20.md silently dropped (L17) | `framework/commands/apex/self-heal.md` + `framework/agents/specialist/round-checker.md` | self-heal.md lines 295-297 collection glob; round-checker.md INPUT lines 20-21 | EDIT collection glob to include both filename patterns + EDIT INPUT contract | W-F2 re-run: orphan `NEW-FINDINGS-ORCHESTRATOR-R<N>.md` now appears in closure inputs and counts toward stop criterion | Class F (4/4 probes pass) |
| CR-06 | W-E1, W-E2 unsurfaced on shallow audits (R201/R202) | `framework/agents/specialist/framework-auditor.md` | end of REPORT FORMAT block (after line 154 "Contradictions within spec itself") + WHAT IS FORBIDDEN block (line 156) | INSERT new advisory class definition + format block, ADJUST forbidden-list to exempt advisory class from spec-anchor rule | Class E (W-E1, W-E2 working + H-E1 held-out): ≥3/4 reliably handled as `SPEC-GAP-CANDIDATE` | Class E ≥3/4 |
| CR-07 | R24 historical priming pattern reproducible via orchestrator | `framework/commands/apex/self-heal.md` | Step A AUDIT_CONTEXT block (lines 175-185) | INSERT explicit "no priming" prohibition immediately after the block | A constructed self-heal run with an injected framing string in AUDIT_CONTEXT is rejected by the auditor (or flagged in coverage map) | Pairs with CR-03 for W-F3 pass |
| CR-08 | R24 mapped to "stable" while framework had 13 live defects | `framework/agents/specialist/round-checker.md` | overall-posture mapping block (lines 124-130) | ADD new posture rung `clean-pending-spot-check` + add disambiguation rule | A constructed closure where audit ran 0 adversarial probes maps to `clean-pending-spot-check`, not `stable` | Cosmetic — pairs with CR-04 to surface blind audits |
| CR-spec | `apex-spec.md:348` says "12-axis audit" but Axis 13 is now mandatory | `apex-spec.md` line 348 | "performs a 12-axis audit against this" | EDIT 12 → 13 + append one sentence on Axis 13 | Spec quote in any future audit matches the agent definition | Traceability (single source of truth maintained) |

**Coverage check:** every CR-NN in `ROOT-CAUSE.md` is a row. Every row
maps to ≥1 BASELINE.md symptom and ≥1 §9 threshold. Zero orphan rows.
Zero unaddressed symptoms.

---

## CR-01 · Add mandatory Axis 13 — Adversarial Falsification

### Target

`framework/agents/specialist/framework-auditor.md`

### Anchor A (rename section header at line 52)

**Old:**
```
## TWELVE INVESTIGATION AXES
```

**New:**
```
## THIRTEEN INVESTIGATION AXES
```

### Anchor B (insert after line 115, i.e. after the existing axis 12)

The current file ends axis 12 at line 115 with `it, or is it a
declaration only?"`. **Insert immediately after that line, before the
blank line that precedes `## REPORT FORMAT — MANDATORY, NOT A SUGGESTION`
on line 117.** Inserted text (verbatim, including the blank line that
separates it from axis 12 and the blank line that precedes the next
section header):

```

13. **Adversarial falsification — attempt the bypass, observe the
    result.** Reading guards is not enough. This axis has **two
    procedural sub-passes**, both required.

    **13.a · Guard-bypass sub-pass.** For every security / integrity
    hook the spec names (axis 10 list at minimum: `destructive-guard`,
    `exfil-guard`, `owner-guard`, `apex-prompt-guard.cjs`,
    `apex-workflow-guard.cjs`, plus any other spec-anchored guard you
    encountered in the read-pass), construct a crafted payload that the
    hook's contract says it MUST refuse, invoke the hook against that
    payload (`echo '<payload>' | bash framework/hooks/<hook>.sh`),
    record the observed exit code in the coverage map, and compare to
    the contract-required exit code. A discrepancy is a finding
    regardless of whether the file "looks right." Apply the same
    protocol to any non-guard mechanism whose spec contract is
    "block/refuse on pattern X": surface the smallest payload that
    should trigger refusal, run it, record exit code and stderr
    presence/absence.

    **13.b · Silent-failure sub-pass — Fail-loud falsification.** For
    every error-handling code path the spec or agent definition
    declares "MUST fail loudly" (i.e. emit a stderr diagnostic AND
    return non-zero on the failure branch — including but not limited
    to: state-update jq failures, hook-pipeline write failures,
    circuit-breaker CHECK-3 recurring-error announcement, session-log
    header-write failure, any block in any hook that the spec's core
    principle "Fail-loud, never fail-silent" governs), construct the
    smallest input that drives the path into its failure branch (a
    deliberately malformed jq expression, an unwritable target path, a
    payload whose canonicalised hash already appears in
    `STATE.recent_error_hashes`, etc.), invoke the hook against that
    input, and record BOTH the observed exit code AND whether stderr
    contains the contract's declared diagnostic. A silent-failure
    branch — exit 0 with empty stderr where the contract requires loud
    failure — is a finding regardless of whether the file "looks
    right." The minimum probe set is: one fail-loud branch per hook
    listed in axis 10, plus `framework/hooks/_state-update.sh`,
    `framework/hooks/circuit-breaker.sh`, `framework/hooks/session-
    log.sh` (the three baseline anchors of the spec's Fail-loud
    principle). A hook with declared fail-loud branches and zero
    attempted falsification probes recorded is an incomplete audit,
    not a clean one.

    Both sub-passes are **procedural, not analytical**. Every covered
    hook must appear in the coverage map's axis-13 row with counts
    `bypass_attempts=<n>` and `silent_failure_probes=<m>` and a payload
    summary per attempt. A row with both counts at 0 is an incomplete
    audit. A row with non-zero counts and zero anomalies recorded is a
    valid clean-audit signal — the depth floor has been met.

```

### Acceptance test (Phase 6)

After install, the Phase-6 baseline corpus re-run must:
- (a) reliably kill **W-B1, W-B2, W-B3** in ≥2 of 3 trials with the
  finding text containing an exit-code observation from a constructed
  payload (sub-pass 13.a), not only the textual presence of the magic
  literal in the file; held-out **H-B1, H-B2** must hit the same ≥2/3
  bar.
- (b) reliably kill **W-C1, W-C2, W-C3** in ≥2 of 3 trials with the
  finding text containing an exit-code AND stderr-presence observation
  from a fail-loud falsification probe (sub-pass 13.b) — not only a
  textual reading of the modified branch. Held-out **H-C1, H-C2** must
  hit the same ≥2/3 bar.
- (c) every trial's coverage map records `axis_13: {bypass_attempts=
  <≥5>, silent_failure_probes=<≥3>}` across the spec-named hooks.

Trials whose coverage map records 0 in either count fail this CR's
acceptance independent of whether they happen to catch the mutants by
other means. CR-01 is the **primary** source of Class C kill rate (not
CR-02) — Class C mutants are silent-failure regressions, and 13.b
targets them directly. CR-02 (test-suite observation) is a secondary
catch path for Class C only when `run-all.sh` happens to exercise the
silent branch; the primary defense is the 13.b adversarial probe.

### §9 effect

Lifts Class B+C+D working ≥7/8 and held-out ≥4/5 — the C component is
carried by sub-pass 13.b, the B component by sub-pass 13.a. CR-01 +
CR-02 together close the structural gap behind the R201/R202 shallow-
audit failure mode; CR-01's two sub-passes are the load-bearing
defense for Class B and Class C respectively.

---

## CR-02 · Add Test-suite evidence rule (must run or BLIND SPOT)

### Target

`framework/agents/specialist/framework-auditor.md`

### Anchor (insert after line 172)

The current `## TERMINATION CRITERION` block ends at the sentence
`finishing — stop, report what you covered and what remains, *do not
compress*.` (the sentence spans lines 171-172; `*do not` is on line
171 and `compress*.` on line 172). **Insert a new sub-section
immediately after the closing `compress*.` line and before the blank
line that precedes `## WRITE-FIRST CONTRACT — NON-NEGOTIABLE` on line
174.** Inserted text:

```

## TEST-SUITE EVIDENCE RULE — NEVER INHERIT, ALWAYS OBSERVE

Tests are evidence. You may not assert anything about the test suite's
state by inheritance from prior rounds, prior commit messages, or
auditor-history. Choose exactly one of these two paths per round:

1. **OBSERVED.** Run `bash framework/tests/run-all.sh` to completion in
   the lab (copy to a non-OneDrive location first if the in-tree run is
   slow). Quote the literal trailing summary line (`passed:<n> failed:<n>
   skipped:<n> errored:<n>`) verbatim in your coverage map under "Test
   suite". A `failed` or `errored` count > 0 is a finding regardless of
   what the test names suggest.
2. **BLIND SPOT.** If you cannot run `run-all.sh` to completion in this
   round (timeout, environment, tool budget), explicitly record under
   coverage-map "Test suite" the literal line `BLIND SPOT — test suite
   not observed this round; suite state is unverified`, and write a
   finding `Test-suite observation deferred` at severity P3. Inheritance
   from a prior round's claim of "green" is **forbidden**.

This is not advisory. An audit that records neither (1) nor (2) is
incomplete. The orchestrator and round-checker treat the absence of a
"Test suite" line in the coverage map identically to a non-zero failure
count.

```

### Acceptance test (Phase 6)

Every Phase-6 detector trial must have a "Test suite" coverage-map line
matching path (1) or path (2) — verified by `grep -E '^\| 13 |Test
suite' detector-review/trials/phase6-trial-*.md`. W-D1 and W-D2 must be
reliably killed (≥2/3 trials each), since path (1) exercises both files
and path (2) is itself a finding that prevents a clean close.

### §9 effect

Lifts the D component of working B+C+D ≥7/8 and held-out ≥4/5. Closes
the test-inheritance leak documented in `apex-audit-findings-R24.md:54`.

---

## CR-03 · Add Anti-priming clause to CORE PRINCIPLES

### Target

`framework/agents/specialist/framework-auditor.md`

### Anchor (insert after line 37 — end of "Do not filter early" paragraph)

The current `## CORE PRINCIPLES` block contains four numbered/bold
paragraphs. The last one is **Do not filter early** ending at line 37
with `... not to decide what matters.`. **Insert a fifth principle
immediately after line 37, before the blank line that precedes `## INPUT`
on line 39.** Inserted text:

```

**Anti-priming — framing is noise.** The orchestrator's framing of this
round (round number, the existence or content of
`previous_findings_path`, the name of the round in the prompt, any
human-readable label like "post-convergence", "confirmation",
"validation", "quiet round", "stable") is not evidence. A clean prior
round is **not** evidence this round is clean. A label like
"post-convergence confirmation" is **not** a license to lower scrutiny;
it is a signal to look harder, because the only way the loop closes is
for one round to detect what the previous round missed. If
`previous_findings_path` references findings — read it for trajectory
context only, then deliberately hunt as though you had never seen it.
The depth of your audit (number of files read, number of guards
adversarially probed, whether you ran the test suite) must not vary
with framing. If you notice yourself "trusting" the prior round, that
is the signal to spend extra tool budget on the area the prior round
emphasised was clean.

```

### Acceptance test (Phase 6)

Re-run the W-F3 framing pair (neutral vs primed) on the fixed detector.
Pass criterion: `|neutral_total_findings − primed_total_findings| ≤ 1`
AND probe defect (W-A1) killed in both AND no severity downgrade between
conditions. Phase-2 baseline was 17 vs 4 (76% reduction); the fix must
collapse that gap to ≤ 1 finding.

### §9 effect

Pairs with CR-07. Stabilises depth across framing variants. Indirectly
preserves the regression criterion (`run-all.sh failed:0`) by removing
the "I'll trust prior round, so I'll skip running tests" pathway.

---

## CR-04 · Round-checker — independent audit-credibility spot-check + 4th conjunct

### Target

`framework/agents/specialist/round-checker.md`

### Anchor A (insert new step 6 before TERMINATION at line 90 — i.e. after the existing step 5 stop criterion)

The current `## PROCESS` block ends at line 90 with `Otherwise — round
R<N+1> is required.` (the close of step 5). **Insert a new numbered
step 6 immediately after line 90, before the blank line that precedes
`## OUTPUT FORMAT` on line 92.** Inserted text:

```

6. **Audit-credibility spot-check.** Before declaring CLOSED on any
   `P0+P1==0` round, independently re-verify a small sample of the
   auditor's compliance claims. Pick exactly **3** items from the
   audit's coverage map that the auditor marked compliant — prefer (a)
   any security guard (`destructive-guard`, `exfil-guard`, `owner-guard`,
   `apex-prompt-guard.cjs`, `apex-workflow-guard.cjs`), and (b) any
   self-heal-loop file the auditor itself reads (`framework/agents/
   specialist/framework-auditor.md`, `round-checker.md`,
   `framework/commands/apex/self-heal.md`). For each pick: re-run the
   minimal observation that would confirm the claim (one `grep`, one
   `test -f`, or one hook invocation against a contract-violating
   payload). If any re-check contradicts the auditor's claim, the round
   does **not** close; record the discrepancy as a P1 finding under
   "Audit-credibility regression" in this closure report, set `Status:
   CONTINUE TO R<N+1>`, and seed the next round on the disputed area.
   Document each spot-check in a short table inside the closure report
   under `## Spot-check results` with columns `claim | re-check command
   | observed | verdict`. The spot-check must be performed on every
   `P0+P1==0` round — it is the load-bearing defense against the
   F-204-013 audit-honesty regression (R23 fabricated counts → R24
   ratified). **Spot-check tool failure rule:** if a spot-check command
   itself errors (tool unavailable, file-system timeout, jq missing,
   permission denied on the re-check) so the observation cannot be
   completed, treat the spot-check as `FAILED` for posture purposes
   (CR-08 maps the round to `clean-pending-spot-check`, not
   `stable`/`improving`) — **never** as "skipped" or implicitly
   "passed." Record the error verbatim under the verdict column and
   set `Status: CONTINUE TO R<N+1>` with the spot-check tooling issue
   as a seed.

```

### Anchor B (edit step 5 stop criterion to add 4th conjunct)

The current step 5 block, lines 83-90:

**Old:**
```
5. **Stop criterion:** declare the loop closed if **all three** of the
   following hold:
   - Round R<N> produced 0 P0 findings AND 0 P1 findings, *and*
   - Round R<N-1> produced 0 P0 findings AND 0 P1 findings (two
     consecutive clean rounds), *and*
   - There are no open NEW-FINDINGS of P0/P1 severity.

   Otherwise — round R<N+1> is required.
```

**New:**
```
5. **Stop criterion:** declare the loop closed if **all four** of the
   following hold:
   - Round R<N> produced 0 P0 findings AND 0 P1 findings, *and*
   - Round R<N-1> produced 0 P0 findings AND 0 P1 findings (two
     consecutive clean rounds), *and*
   - There are no open NEW-FINDINGS of P0/P1 severity, *and*
   - Round R<N>'s audit coverage map shows (a) every axis investigated
     with at least one piece of recorded evidence, (b) Axis 13
     Adversarial Falsification exercised on every spec-named guard with
     a recorded exit code per attempted bypass, and (c) the test suite
     either OBSERVED (literal `passed:/failed:/skipped:/errored:` line
     quoted) or recorded as BLIND SPOT per the auditor's Test-suite
     evidence rule. A "two clean rounds" close means "two *deep* clean
     rounds." A round where axis 13 records 0 attempted bypasses, or
     where the test suite is silently inherited, is structurally
     ineligible to close the loop regardless of P0/P1 count.

   Otherwise — round R<N+1> is required.
```

### Acceptance test (Phase 6)

Construct one synthetic closure scenario where the audit input claims
"all guards compliant" but a re-check of `apex-prompt-guard.cjs`
reveals it is in fact absent. The fixed round-checker must produce
`Status: CONTINUE TO R<N+1>` with a "Spot-check results" table and a P1
under "Audit-credibility regression". Additionally, the W-F2 re-run
(orphan-finding) plus this scenario together must demonstrate the loop
cannot close on a blind audit even if P0/P1 count is 0.

### §9 effect

Independent review criterion. CR-04 is the cross-check that prevents
F-204-013 from happening again; CR-01 + CR-02 raise the audit's
ground-truth quality, CR-04 verifies the auditor actually did the work.

---

## CR-05 · Filename-contract — collect orphan `NEW-FINDINGS-ORCHESTRATOR` files

### Target A

`framework/commands/apex/self-heal.md`

### Anchor A (edit collection text on lines 295-297)

The current Step E collection paragraph (lines 295-297):

**Old:**
```
  Collect all wave-result paths and new-findings paths from this round:
  `$REPO_ROOT/WAVE-R<N>-W<X>-RESULT.md` for X from 1 to last completed,
  `$REPO_ROOT/NEW-FINDINGS-R<N>-W<X>.md` where they exist.
```

**New:**
```
  Collect all wave-result paths and new-findings paths from this round:
  `$REPO_ROOT/WAVE-R<N>-W<X>-RESULT.md` for X from 1 to last completed,
  `$REPO_ROOT/NEW-FINDINGS-R<N>-W<X>.md` where they exist, **and**
  `$REPO_ROOT/NEW-FINDINGS-ORCHESTRATOR-R<N>.md` if it exists
  (orchestrator-discovered findings outside the wave-executor's scope —
  e.g. issues spotted during plan-write, schedule, or closure that
  warrant inheritance into R<N+1>'s audit seed). Additionally, list any
  file at repo root matching the glob `NEW-FINDINGS-*-R<N>*.md` that is
  NOT in either list, and pass that orphan list to round-checker as
  `orphan_new_findings`. An orphan file is a contract violation, not a
  reason to skip the file.
```

### Anchor B (edit `CLOSER_CONTEXT` block on lines 299-311)

The current `CLOSER_CONTEXT` block (lines 299-311) lists `new_findings:
[list of NEW-FINDINGS-R<N>-W<X>.md paths]` on line 305. **Edit only
that one line:**

**Old:**
```
    new_findings: [list of NEW-FINDINGS-R<N>-W<X>.md paths],
```

**New:**
```
    new_findings: [list of NEW-FINDINGS-R<N>-W<X>.md paths
                   plus NEW-FINDINGS-ORCHESTRATOR-R<N>.md if it exists],
    orphan_new_findings: [list of NEW-FINDINGS-*-R<N>*.md files at repo
                          root not in new_findings],
```

### Target B

`framework/agents/specialist/round-checker.md`

### Anchor C (edit INPUT block — line 20-21)

The current INPUT line 20-21 reads:
```
- `new_findings` — list of absolute paths to
  `NEW-FINDINGS-R<N>-W<X>.md` files (if any).
```

**Edit to:**
```
- `new_findings` — list of absolute paths to
  `NEW-FINDINGS-R<N>-W<X>.md` files (if any), plus
  `NEW-FINDINGS-ORCHESTRATOR-R<N>.md` if the orchestrator discovered any
  finding outside the wave-executor's scope.
- `orphan_new_findings` (optional) — list of `NEW-FINDINGS-*-R<N>*.md`
  files at repo root that did NOT match either expected filename
  pattern. Treat each orphan as an open P1 against this round's stop
  criterion AND record a P1 finding under "Filename-contract
  regression" in the closure report. Orphan files are inputs to the
  closure decision regardless of their content.
```

### Acceptance test (Phase 6)

Re-run W-F2 against the fixed orchestrator + round-checker. Pass
criterion: closure references `NEW-FINDINGS-ORCHESTRATOR-R99.md` content
AND counts the P1 toward the stop criterion AND emits status `CONTINUE
TO R100`. Additionally, place a file named
`NEW-FINDINGS-ROGUE-R99-W5.md` at repo root (an unexpected pattern) and
verify it appears in `orphan_new_findings` and triggers the
"Filename-contract regression" P1.

### §9 effect

Class F probe pass. Closes the L17 silent-omission documented at
HEAD by `NEW-FINDINGS-ORCHESTRATOR-R20.md` (the live file unprocessed
since R20).

---

## CR-06 · Add `SPEC-GAP-CANDIDATE` advisory class

### Target

`framework/agents/specialist/framework-auditor.md`

### Anchor A (insert after line 154 — end of "Contradictions within spec itself")

The current `## REPORT FORMAT` block ends at line 154 with `If you
found that the spec contradicts itself — report separately. Do not
resolve, only mark.`. **Insert a new top-of-report section spec
immediately after that line, before the blank line that precedes `##
WHAT IS FORBIDDEN` on line 156.** Inserted text:

```
- **SPEC-GAP-CANDIDATES (advisory, uncounted)** — see SPEC-GAP-CANDIDATE
  section below. These are observations that would be legitimate
  findings *if* the spec were extended to cover them, but for which no
  current spec anchor exists. They are advisory only, are not counted
  in P0/P1/P2/P3, and do not affect the round's stop criterion. They
  are surfaced so the framework owner can decide whether the spec
  should be extended. Common examples (non-exhaustive): credential-
  shaped literals in tracked source even when commented; unused
  destructive helper functions ("dead-code footguns") whose effect, if
  reached, would mutate critical state; placeholder values left in
  release files; non-spec-anchored regressions in behavioural rigor
  that nonetheless feel wrong. The spec-anchor rule (above) keeps the
  P0–P3 count disciplined; this class is the relief valve so the
  audit's mouth is not glued shut on real but un-anchored observations.

### `SPEC-GAP-CANDIDATE` format

Place a separate `## SPEC-GAP-CANDIDATES` section AFTER the regular
findings list, with this format per entry — and never with a P0/P1/P2/P3
severity:

```
## SGC-<NNN>: <short title>
**File / location:** <path:line> or <area>
**Observation:** <what is wrong in 1-2 sentences, evidence-grounded>
**Why it is not a P0-P3 finding:** <which spec section is silent on it>
**Suggested spec language (non-binding):** <one short sentence that
  would close the gap if the owner chose to extend the spec>
```

`SPEC-GAP-CANDIDATE` entries are NOT findings. They do NOT contribute
to `findings=<count>` in your final summary line. The summary line's
`P0`/`P1`/`P2`/`P3` counts exclude them entirely. Report SGC counts
separately on a new final-line suffix: `sgc=<n>`.
```

### Anchor B (edit `## WHAT IS FORBIDDEN` block at line 156 — add carve-out)

The current `## WHAT IS FORBIDDEN` block (lines 156-166) lists five
forbidden behaviours. **Edit the second bullet (line 160-161) only to
add a one-sentence carve-out for SGCs.** The current second bullet:

**Old:**
```
- **Forbidden to report stylistic gaps, speculative optimizations, or
  "it could have been nicer".** Only contradictions to the spec.
```

**New:**
```
- **Forbidden to report stylistic gaps, speculative optimizations, or
  "it could have been nicer".** Only contradictions to the spec. The
  one carve-out is `SPEC-GAP-CANDIDATE` entries — evidence-grounded
  observations of a security / correctness / hygiene defect for which
  no current spec anchor exists. SGC entries follow the format above,
  are advisory-only, and never count as P0-P3.
```

### Anchor C (edit summary final-line in OUTPUT section at line 202)

The current OUTPUT section ends at line 202 with the summary-line
template:

**Old:**
```
Final line of your message back to the orchestrator:
`AUDIT_COMPLETE: <output_path> | findings=<count> | P0=<n> P1=<n> P2=<n> P3=<n>`
```

**New:**
```
Final line of your message back to the orchestrator:
`AUDIT_COMPLETE: <output_path> | findings=<count> | P0=<n> P1=<n> P2=<n> P3=<n> | sgc=<n>`
(where `<count>` is the sum of P0-P3 only; `sgc` is reported
separately and never feeds into P0/P1 stop-criterion arithmetic.)
```

### Acceptance test (Phase 6)

W-E1 and W-E2 (working corpus) plus H-E1 (held-out) — **≥3/4 surfaced
as `SGC-<NNN>` entries** in the report and reflected in the new
`sgc=<n>` suffix on the summary line. Tighter discrimination rule
(closes Phase-4 critic Finding 3): for each Class-E mutant, **the
auditor's P0 + P1 + P2 + P3 counts of that mutant must be 0** AND its
SGC representation must be present in ≥2/3 trials. A half-broken fix
that "classifies E as P3" (preserving spec-anchor discipline by leaving
the SGC channel inert) fails this CR because the P2/P3 row for the
mutant would be non-zero. Negative control (clean lab, fixed detector)
must still produce 0 P0/P1 false positives **and** SGC entries on the
NC trial must be evidence-grounded (each SGC names a real file and a
real observation) — not stylistic.

### §9 effect

Lifts Class E ≥3/4 threshold. CR-06 preserves the spec-anchor
discipline (the historical rule that kept counts honest) while opening
the advisory channel that R203 had to improvise informally.

---

## CR-07 · Forbid orchestrator framing in `AUDIT_CONTEXT`

### Target

`framework/commands/apex/self-heal.md`

### Anchor (insert after the AUDIT_CONTEXT block — line 185)

The current Step A AUDIT_CONTEXT code block closes on line 185 (the
` ``` ` fence); the last line of the block's body is line 184
(`model=resolve_model("framework-auditor"))`). **Insert a new
prohibition paragraph immediately after the closing fence on line 185,
before the blank line that precedes `**POST-TASK VERIFICATION**` on
line 187.** Inserted text:

```

  **No priming, no framing.** `AUDIT_CONTEXT` is the COMPLETE set of
  inputs passed to the auditor. The orchestrator does **not** append
  free-form framing about convergence, confirmation, quiet rounds,
  stability, or the previous round's verdict to either the
  `AUDIT_CONTEXT` block or the task prompt. The only trajectory channel
  is `previous_findings_path`, which carries data only (a file path),
  and the auditor's `Anti-priming` principle is the load-bearing
  defense. If a future change to this step ever adds a field whose
  value is a sentence about how the auditor should feel about the
  round — that change is a regression of CR-07 and must be reverted.

```

### Acceptance test (Phase 6)

Two-pronged acceptance — closes Phase-4 critic Finding 4 (CR-07 was
otherwise preventive-only and non-self-discriminating):

- **Preventive (passive):** `grep -nE 'POST-CONVERGENCE|confirmation
  round|convergence holds|quiet round|stable round' framework/commands/
  apex/self-heal.md` returns 0 matches AND a new positive grep `grep
  -nE 'No priming, no framing|AUDIT_CONTEXT is the COMPLETE set'
  framework/commands/apex/self-heal.md` returns ≥1 match. This
  confirms the prohibition language is present in the installed
  command body.
- **Active (constructed-injection):** construct a synthetic test
  invocation `bash framework/tests/test-self-heal-no-framing.sh` (one-
  off scratch test, NOT committed) that simulates a self-heal Step A
  with an injected framing string prepended to the AUDIT_CONTEXT
  block, runs the auditor through the fixed self-heal command, and
  asserts: (a) the auditor's output coverage map records the prohibited
  framing under "Anti-priming triggered" OR (b) the orchestrator strips
  the framing before passing it. **Either** outcome satisfies the
  active test; **neither** outcome (auditor silently accepts and
  lowers depth) fails the test. This is the active discriminator that
  separates "CR-07 applied" from "CR-07 not applied."

Functionally, CR-03's W-F3 acceptance test (|Δfindings| ≤ 1) provides
the end-to-end behavioural confirmation that CR-07 + CR-03 together
work as intended.

### §9 effect

Pairs with CR-03 on the W-F3 pass criterion. Closes the structural
half of W5 (CR-03 closes the cognitive half).

---

## CR-08 · Round-checker — add `clean-pending-spot-check` posture rung

### Target

`framework/agents/specialist/round-checker.md`

### Anchor (edit the overall-posture mapping block on lines 124-130)

The current overall-posture mapping (lines 124-130):

**Old:**
```
Mapping (R16-637 / IMP-037 — plain-language UX for non-technical users):

- `P0 + P1 == 0` and trajectory `IMPROVING` → **improving**.
- `P0 + P1 == 0` and trajectory `STAGNANT` → **stable**.
- `P0 + P1 > 0` OR trajectory `DIVERGING` OR a non-trivial cluster of
  new outcomes `gave_up` / `apology_no_completion` / `answer_thrashing`
  (R-606 outcome enum) → **degrading**.
```

**New:**
```
Mapping (R16-637 / IMP-037 — plain-language UX for non-technical users):

- `P0 + P1 == 0` AND trajectory `IMPROVING` AND audit-credibility
  spot-check (step 6) PASSED AND audit coverage map records ≥1
  adversarial-axis attempt per spec-named guard AND test-suite line
  records OBSERVED → **improving**.
- `P0 + P1 == 0` AND trajectory `STAGNANT` AND the same three
  audit-quality conditions above → **stable**.
- `P0 + P1 == 0` AND any of: spot-check skipped or failed, OR
  adversarial axis records 0 attempts, OR test-suite line records
  BLIND SPOT or is missing → **clean-pending-spot-check** (the audit
  did not surface findings, but it also did not exercise the depth
  needed to distinguish a clean framework from a blind audit; the
  loop does NOT close at this posture — round R<N+1> is required).
- `P0 + P1 > 0` OR trajectory `DIVERGING` OR a non-trivial cluster of
  new outcomes `gave_up` / `apology_no_completion` / `answer_thrashing`
  (R-606 outcome enum) → **degrading**.
```

### Acceptance test (Phase 6)

Construct a closure scenario where audit reports `P0+P1=0` but the
coverage map shows 0 adversarial-axis attempts. The fixed round-checker
must map posture to `clean-pending-spot-check`, **not** `stable`, AND
emit `Status: CONTINUE TO R<N+1>`. This is the cosmetic-but-load-
bearing tell that prevents the R24 "stable" mislabel from recurring.

### §9 effect

Cosmetic surface, structural impact. Pairs with CR-04: spot-check
detects the substance of a blind audit; CR-08 ensures the verdict word
shown to the non-technical owner ("stable" vs "clean-pending-spot-
check") never lies on the audit's behalf.

---

## CR-spec · Update `apex-spec.md:348` to declare 13 axes

### Target

`apex-spec.md`

### Anchor (edit lines 348-352 — Self-Healing Loop step 1)

Owner approval **granted in the resume message** for: (a) the axis
count change 12 → 13, and (b) the one-sentence Axis 13 description
below.

**Old:**
```
1. **`framework-auditor`** — performs a 12-axis audit against this
   spec, producing `apex-audit-findings-R<N>.md` at repo root with
   F-NNN findings classified P0–P3, status CONFIRMED/SUSPECTED, and
   spec-anchor citations. The agent's only measuring stick is this
   spec; nothing else.
```

**New:**
```
1. **`framework-auditor`** — performs a 13-axis audit against this
   spec, producing `apex-audit-findings-R<N>.md` at repo root with
   F-NNN findings classified P0–P3, status CONFIRMED/SUSPECTED, and
   spec-anchor citations. The agent's only measuring stick is this
   spec; nothing else. Axis 13 (Adversarial Falsification) requires
   the auditor to attempt a contract-violating payload against every
   spec-named guard and record the observed exit code — reading is
   evidence about declarations, running is evidence about behaviour.
```

### Acceptance test (Phase 6)

`grep -n '13-axis audit' apex-spec.md` returns line 348. `grep -n
'12-axis audit' apex-spec.md` returns 0 matches. The agent definition
header (`framework-auditor.md:3`) is updated by Phase 5 to match — see
Phase-5 install checklist.

### §9 effect

Traceability — single source of truth between `apex-spec.md` and the
agent definition. Prevents future audits from citing the old "12-axis"
language and creating a contradiction in the spec they audit against.

---

## Implementation order for Phase 5

Edits are independent in source terms (no shared anchors collide), but
**commit them in CR-NN order** so the diff history is readable.
Per-CR install matrix:

| CR | Source file edited | Install command | Atomic commit message |
|----|-------------------|-----------------|-----------------------|
| CR-01 | `framework/agents/specialist/framework-auditor.md` | `cp -f framework/agents/specialist/framework-auditor.md ~/.claude/agents/specialist/framework-auditor.md` | `fix(self-heal): CR-01 mandate Axis 13 Adversarial Falsification on every spec-named guard` |
| CR-02 | same file (additional anchor) | same | `fix(self-heal): CR-02 add Test-suite evidence rule — never inherit, always observe` |
| CR-03 | same file (additional anchor) | same | `fix(self-heal): CR-03 add Anti-priming clause to CORE PRINCIPLES` |
| CR-04 | `framework/agents/specialist/round-checker.md` | `cp -f framework/agents/specialist/round-checker.md ~/.claude/agents/specialist/round-checker.md` | `fix(self-heal): CR-04 add audit-credibility spot-check + 4th conjunct to stop criterion` |
| CR-05 | `framework/commands/apex/self-heal.md` AND `framework/agents/specialist/round-checker.md` | `cp -f framework/commands/apex/self-heal.md ~/.claude/commands/apex/self-heal.md` AND same round-checker install | `fix(self-heal): CR-05 collect NEW-FINDINGS-ORCHESTRATOR-R<N>.md + orphan-file contract` |
| CR-06 | `framework/agents/specialist/framework-auditor.md` | same auditor install | `fix(self-heal): CR-06 add SPEC-GAP-CANDIDATE advisory class (uncounted)` |
| CR-07 | `framework/commands/apex/self-heal.md` | same self-heal install | `fix(self-heal): CR-07 forbid orchestrator framing in AUDIT_CONTEXT` |
| CR-08 | `framework/agents/specialist/round-checker.md` | same round-checker install | `fix(self-heal): CR-08 add clean-pending-spot-check posture rung` |
| CR-spec | `apex-spec.md` | (spec is repo-root, no install) | `docs(spec): update Self-Healing Loop step 1 — 12-axis → 13-axis` |

Also Phase 5 updates the agent-definition headers' `description:` field
for `framework-auditor` (line 3) from `12-axis investigation` to
`13-axis investigation` — same byte change, paired into the CR-01
commit so the description matches the section title.

**Scorer SGC-awareness note (closes Phase-4 critic Finding 5).** CR-06
adds a new `sgc=<n>` suffix to the `AUDIT_COMPLETE: ...` summary line.
The Phase-6 Scorer (an orchestrator-internal step, not an installed
file) must (a) split SGC entries from P0-P3 findings when reading the
trial report, (b) treat SGC entries as informational — never feed
them into the P0+P1 stop arithmetic — and (c) report SGC counts on a
separate line of the per-trial kill matrix. The 8 existing trial
fixtures under `detector-review/trials/` carry no `sgc=` suffix and
remain valid baseline reference; Phase-6 trial files will carry it.
The Scorer's `sgc`-awareness is a Phase-6 instruction, not a Phase-5
edit.

After all commits, **re-install all three files** (auditor, round-
checker, self-heal) to `~/.claude/...` in one final cp burst, then run
`framework/tests/run-all.sh` from `.lab/` and confirm `failed:0` plus
the four prose-sensitive tests stay green (`test-agent-lint.sh`,
`test-command-structure.sh`, `test-docs.sh`, `test-wiring.sh`).

## Phase 4 close — coverage summary

| ROOT-CAUSE.md CR | Addressed by this FIX-DESIGN.md CR | Anchor verified against live source | Acceptance test pre-registered |
|------------------|-----------------------------------|------------------------------------|--------------------------------|
| CR-01 | CR-01 | line 52, 115 | W-B1/B2/B3 reliably killed + adversarial coverage map entries |
| CR-02 | CR-02 | line 172 | W-D1/D2 reliably killed + "Test suite" coverage line present |
| CR-03 | CR-03 | line 37 | W-F3 \|Δfindings\| ≤ 1, both kill probe |
| CR-04 | CR-04 | line 66, 83-90 | Spot-check table present; constructed false-claim closure flips to CONTINUE |
| CR-05 | CR-05 | self-heal.md 295-297; round-checker.md 20-21 | W-F2 re-run: orchestrator file ingested, orphan-pattern flagged |
| CR-06 | CR-06 | line 154, 156, 202 | W-E1/E2/H-E1 ≥3/4 as SGC; new `sgc=<n>` final-line suffix |
| CR-07 | CR-07 | self-heal.md 175-185 | W-F3 pass + grep returns 0 framing strings in command body |
| CR-08 | CR-08 | round-checker.md 124-130 | Constructed blind-audit closure maps to `clean-pending-spot-check` |
| CR-spec | CR-spec | apex-spec.md:348 | 13-axis grep matches; no 12-axis remains |
| (none) | W-F1 (planner pass at baseline, §9 Class F 4/4) | `framework/agents/specialist/remediation-planner.md` | NOT addressed — preserved by no-touch; Phase 6 re-runs W-F1 as a regression check on the planner |
| (none) | Class A 3/3 working + 2/2 held-out, no regression (§9 row) | `framework/agents/specialist/framework-auditor.md` | NOT directly addressed — preserved by no-edit to axes 1-12; Phase 6 verifies baseline kills are not regressed and surfaces a new Class-A finding if any CR-01..CR-08 edit accidentally weakens axes 1-12 |

**Zero orphan symptoms.** Every BASELINE.md symptom traces to a CR
above; every CR has a pre-registered Phase-6 acceptance test mapped to
an `EXPERIMENT-PROTOCOL.md` §9 threshold. The two `(none)` rows close
Phase-4 critic Finding 8 — preservation by no-touch is documented
explicitly so a reader auditing coverage does not assume omission.

Phase 4 deliverable ready for critic clean-room review.
