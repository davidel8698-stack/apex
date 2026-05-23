# EXPERIMENT PROTOCOL — Self-Heal Detector Sensitivity Study

> **STATUS: FROZEN** — pre-registered 2026-05-23, before any measurement.
> Baseline commit: `8ac2a858423c490d58bd22fba742c51bf0c7021a` (branch `main`).
> No section below may be changed after the first measurement except via
> a dated entry in §12 Amendment Log.

---

## 1. Purpose

Measure, with evidence, the failure-detection sensitivity of the APEX
`/apex:self-heal` loop — specifically: **when a real defect exists in the
framework, what is the probability the loop detects it, and where does an
undetected defect get lost?**

The study runs twice: once against the **current** detector (Phase 2,
baseline) and once against the **fixed** detector (Phase 6,
re-certification). The fix is accepted only if it raises measured
sensitivity past the pre-registered thresholds in §9 on data it was not
designed against (§6 held-out corpus).

This protocol is *pre-registered*: taxonomy, corpus sizes, scoring rules
and pass thresholds are fixed here, before any mutant is injected, so
results cannot be rationalised after the fact.

## 2. Environment

- **Scratch lab:** `C:\temp\apex-detector-lab` — a full `robocopy /E`
  clone of the repo (including `.git`), on a non-OneDrive-synced disk so
  `framework/tests/run-all.sh` can complete without the sync/timeout
  penalty. The real repo is never mutated.
- **Per run, a fresh clone** of the lab is used so mutations from one
  condition never leak into another. Clones are named
  `apex-detector-lab-<purpose>` (e.g. `-baseline`, `-heldout`, `-clean`).
- All study artifacts live under `detector-review/` in the real repo:
  `EXPERIMENT-PROTOCOL.md`, `DIAGNOSIS.md`, `BASELINE.md`,
  `ROOT-CAUSE.md`, `FIX-DESIGN.md`, `FINAL-CERTIFICATION.md`,
  `manifests/`, `trials/`.

## 3. Agent roles & information barriers (blind 3-agent protocol)

Three roles, each a **separate agent invocation with no shared context**.
The barrier between Injector and Detector is the load-bearing control.

| Role | Agent | Receives | MUST NOT receive |
|------|-------|----------|------------------|
| **Injector** | general-purpose | the master mutant manifest (§6); a fresh lab clone | — |
| **Detector** | `framework-auditor` (the live registered agent — the real thing the self-heal loop runs) | ONLY a standard, neutral `AUDIT_CONTEXT` pointing at the mutated lab | the manifest; the words "mutant"/"experiment"/"seeded"; any hint defects were planted; any priming about convergence |
| **Scorer** | general-purpose | the master manifest + the Detector's findings file(s) | — |

- The **orchestrator** holds the master manifest and authors the mutant
  specs. It never reveals them to the Detector.
- The Detector prompt is exactly a normal audit request — identical in
  shape to what a real `/apex:self-heal` Step A passes. No experiment
  framing. This is what makes the measurement valid.
- Injector, Detector and Scorer for a given trial share nothing.

## 4. Detector invocation (held identical baseline vs fixed)

The Detector is the `framework-auditor` agent. The **only** variable
between the baseline study (Phase 2) and the re-certification study
(Phase 6) is the content of the auditor definition
(`framework/agents/specialist/framework-auditor.md` and the round-checker
where relevant). Everything else — corpus, lab, prompt shape, trial
count, scorer, rubric — is held constant.

`AUDIT_CONTEXT` passed to the Detector each trial:
```
repo_root   = <the mutated lab clone>
spec_path   = <lab clone>/apex-spec.md
round_number = <trial tag, neutral>
output_path = detector-review/trials/<study>-<trial>.md
previous_findings_path = null   (no trajectory priming)
```
The Phase-5 fix must be installed to the live agent path before the
Phase-6 Detector runs (install mechanism confirmed in Phase 1); if no
clean install path exists, the documented fallback is to drive the
Detector with the auditor definition file verbatim as its prompt — the
same fallback applied identically to the baseline so the comparison
stays controlled. The chosen method is recorded in §12 before Phase 2.

## 5. Defect taxonomy (FROZEN)

Six classes. Classes A–E are code mutations injected into the lab and are
detectable by an audit. Class F is a post-detection pipeline defect,
tested by a separate probe (§10.3), not by the auditor mutation run.

| Class | Defect type | Blind spot probed | Detectable by |
|-------|-------------|-------------------|---------------|
| A | **Spec-conformance violation** (positive control) | baseline competence | auditor |
| B | **Guard bypass / behavioural** | W2 (presence-not-behaviour) | auditor |
| C | **Silent failure / swallowed error** | W2 / W3 | auditor |
| D | **Vacuous / disabled test** | W3 (inherited green) | auditor |
| E | **Spec-silent design defect** | W1 (spec-anchored only) | auditor (advisory only) |
| F | **Pipeline-propagation defect** | W4 / W6 | propagation probe |

Mutant realism rule: every mutant must be modelled on a defect class that
has actually occurred in APEX history (audit rounds R5–R21) or is a
plausible real regression. No artificially obvious mutants.

## 6. Corpus design (FROZEN)

### 6.1 Working corpus — used in Phase 2 and re-tested in Phase 6

Auditor-detectable mutants (Classes A–E): **13**

| ID | Class | Count |
|----|-------|-------|
| W-A1, W-A2, W-A3 | A | 3 |
| W-B1, W-B2, W-B3 | B | 3 |
| W-C1, W-C2, W-C3 | C | 3 |
| W-D1, W-D2 | D | 2 |
| W-E1, W-E2 | E | 2 |

Pipeline probes (Class F): **2** — W-F1, W-F2.
**Working corpus total: 15 defects.**

### 6.2 Held-out corpus — used ONLY in Phase 6 (anti-overfitting)

Authored at the same time as the working corpus and sealed; the fix in
Phases 3–5 is designed against the working corpus only. The held-out set
is the decisive generalisation test.

Auditor-detectable mutants (Classes A–E): **8**

| ID | Class | Count |
|----|-------|-------|
| H-A1, H-A2 | A | 2 |
| H-B1, H-B2 | B | 2 |
| H-C1, H-C2 | C | 2 |
| H-D1 | D | 1 |
| H-E1 | E | 1 |

Pipeline probes (Class F): **2** — H-F1, H-F2.
**Held-out corpus total: 10 defects.**

Each mutant is specified in `detector-review/manifests/` with: ID, class,
exact target file, exact change, the ground-truth defect description, and
the spec anchor it violates (Classes A–D) or the design expectation it
breaks (Class E). Manifests are written before Phase 2 and not shown to
any Detector.

## 7. Trial design

- **N = 3 trials** per measured condition (a condition = one corpus ×
  one detector version). N may be raised before a study starts, never
  lowered, never lowered mid-study.
- Each trial is an independent Detector invocation (fresh agent) against
  the *same* mutated lab clone, writing to its own output path.
- Conditions: Phase 2 = {working corpus × baseline detector} +
  {clean lab × baseline detector} (negative control).
  Phase 6 = {working corpus × fixed} + {held-out corpus × fixed} +
  {clean lab × fixed}.

## 8. Scoring rubric (FROZEN)

The Scorer matches each Detector finding against the master manifest.

- **KILLED (per trial):** the findings report contains a finding that
  (a) localises the correct target file and (b) correctly describes the
  defect mechanism. Exact line numbers need not match; naming the right
  file + right mechanism suffices.
- **SURVIVED (per trial):** no finding localises the mutant.
- **PARTIAL (per trial):** a finding gestures at the right file/area but
  misidentifies the mechanism or contradicts the ground truth. Recorded
  separately; **counts as SURVIVED** for all pass/fail thresholds
  (conservative).
- **FALSE POSITIVE:** a finding that corresponds to no injected mutant.
  Before counting, the Scorer checks it is not a genuine pre-existing
  defect (a genuine catch is reported as a bonus finding, not an FP).
- **Reliable kill (per mutant):** KILLED in **≥ 2 of 3** trials.
- **Class kill rate:** fraction of that class's mutants reliably killed.
- **Raw per-trial kill rate** is also reported alongside, for spread.
- **Class E special case:** a Class-E mutant is "handled" if surfaced as
  a `SPEC-GAP-CANDIDATE` advisory entry (it is not expected to be a
  counted P0–P3 finding). Reliable-handle = ≥ 2 of 3 trials.

## 9. Pre-registered success thresholds (FROZEN)

The **fixed** detector (Phase 6) is accepted only if ALL hold:

| Criterion | Threshold |
|-----------|-----------|
| Class A, working corpus | 3 / 3 reliably killed |
| Class A, held-out corpus | 2 / 2 reliably killed |
| Class A regression | fixed kill count ≥ baseline kill count |
| Classes B+C+D, working corpus (8 mutants) | ≥ 7 / 8 reliably killed (target 90%) |
| Classes B+C+D, held-out corpus (5 mutants) | ≥ 4 / 5 reliably killed (target 80%) |
| Class E (4 mutants total, working+held-out) | ≥ 3 / 4 reliably handled as `SPEC-GAP-CANDIDATE` |
| Class F (4 probes total) | 4 / 4 pass |
| Negative control (baseline AND fixed) | 0 false positives |
| Regression | `run-all.sh` → `failed:0`; `test-agent-lint.sh`, `test-command-structure.sh`, `test-docs.sh`, `test-wiring.sh` green |
| Independent review | `critic` PASS on `FIX-DESIGN.md` and on the final state |
| Traceability | every Phase-3 root cause = "verified closed" in the coverage matrix |

**Documented baseline prediction** (not a threshold — recorded now to
prove honesty later): Class A ≈ 3/3; Classes B/C/D ≈ 0–3 / 8; Class E
0 / 4 handled (the current auditor structurally cannot); Class F unknown.
A baseline that beats this prediction is itself a finding.

If any threshold is missed at Gate 6: either fix and re-run Phase 6, or
escalate to the owner as a documented accepted limitation with written
rationale. A threshold is never silently waived.

## 10. Measurement procedure

### 10.1 Phase 2 — baseline study
1. Orchestrator finalises the working + held-out manifests under
   `detector-review/manifests/` (held-out sealed, unused until Phase 6).
2. Clone the lab → `apex-detector-lab-baseline`.
3. **Injector** applies the 13 working A–E mutants; emits an injection
   log confirming each mutation is present (diff per mutant).
4. Orchestrator verifies the injection log against the manifest.
5. **Detector** (baseline `framework-auditor`) audits the mutated clone —
   **3 independent trials**, neutral prompt, separate output files.
6. Clone a *clean* lab → `apex-detector-lab-clean`; **Detector** audits it
   once = negative control.
7. **Scorer** produces the kill matrix (per mutant × per trial), class
   kill rates, FP count.
8. Run the Class-F propagation probes (§10.3).
9. Orchestrator writes `BASELINE.md`.

### 10.2 Phase 6 — re-certification study
Repeat 10.1 steps 2–9 with: the **fixed** detector; the working corpus
(same 13 mutants) AND the held-out corpus (8 fresh mutants); a fresh
negative control. Then run `run-all.sh` regression. Write
`FINAL-CERTIFICATION.md` with baseline-vs-fixed deltas.

### 10.3 Class-F pipeline-propagation probe
Not an auditor run. For each Class-F probe:
1. Hand `remediation-planner` a hand-authored audit-findings file
   containing a known set of findings (incl. the probe defect).
2. Verify 100% of findings become R-items (none silently dropped /
   WONTFIX'd without rationale).
3. Hand `round-checker` a constructed round state with a known open
   item; verify the closure report honestly reflects it (does not
   rubber-stamp CLOSED).
Pass = the known defect propagates intact through plan + closure.

## 11. Threats to validity & mitigations

| Threat | Mitigation |
|--------|-----------|
| Mutants too obvious → inflated kill rate | §5 realism rule; mutants modelled on real R5–R21 findings; subtle variants required |
| Detector non-determinism | N=3 trials; reliable-kill = majority; raw spread reported |
| Fix overfits the working corpus | Sealed held-out corpus is the decisive Phase-6 test |
| Orchestrator knows the answers → leakage | Detector is fully blind; Injector & Scorer are separate agents |
| Scorer over-credits a vague finding | Rubric §8: localise file AND mechanism; PARTIAL counts as SURVIVED |
| Clean clone missing git history | `robocopy /E` includes `.git`; Phase 0 verifies the clone runs `run-all.sh` |

## 12. Amendment log

Any change to §1–§11 after the first measurement is recorded here with
date and rationale. Empty = protocol ran exactly as pre-registered.

- **2026-05-23 (pre-Phase-2 — methodology resolution, not a change).**
  §4 left two items to be resolved in Phase 1 before Phase 2 begins:
  - **Detector method.** The Detector is the `framework-auditor` subagent
    (Task tool, `subagent_type: framework-auditor`). The registered agent
    file is `~/.claude/agents/specialist/framework-auditor.md` and was
    confirmed byte-identical to the repo source
    `framework/agents/specialist/framework-auditor.md` at baseline. Phase
    5 therefore "installs" the fix by copying the edited source files
    (`framework-auditor.md`, `round-checker.md`) to
    `~/.claude/agents/specialist/`, then Phase 6 runs the same Task
    subagent on the now-fixed agent. Method is held identical baseline
    vs fixed; only the agent definition's bytes change.
  - **Held-out corpus blindness.** §6.2 said the orchestrator authors
    both corpora. To strengthen anti-leakage between fix design and
    held-out test, the held-out corpus is **delegated** to a separate
    agent invocation that authors `HELDOUT-CORPUS.md.sealed` from a
    class-and-count specification only. The orchestrator does not read
    the file's content during Phases 3–5; only the Phase-6 Scorer and
    Injector read it. Working corpus is still authored by the
    orchestrator (it is the basis for fix design and must be known).

- **2026-05-23 (pre-Phase-2-measurement — corpus extension, NOT a
  post-data change).** Phase-2 critic review of `WORKING-CORPUS.md`
  (`detector-review/manifests/WORKING-CORPUS-CRITIC.md`) identified
  that weakness **W5 (auditor primability)** had no probe in the
  pre-registered corpus. W5 is a prompt-framing phenomenon — hard to
  encode as a code mutation. The fix: a third Class-F probe (W-F3) is
  added pre-measurement that runs the Detector twice against the same
  defect — once with neutral framing, once with R24-style priming
  injected via `previous_findings_path` — and reports the kill-rate
  delta. This converts W5 from "structurally non-mutable" to
  "measurably observable" without altering the kill rubric for the
  other 15 mutants.
  - **Corpus impact:** working-corpus total 15 → 16; Class F count
    2 → 3. §6.1 frozen text unchanged (kept as authored for the
    record); the actual experiment runs against the extended corpus.
  - **Held-out impact:** none. W-F3 has no held-out counterpart. The
    held-out corpus stays at the pre-registered 10 (8 A–E + 2 F)
    because W-F3 is a methodology probe, not a generalisation test —
    its inputs (priming text, AUDIT_CONTEXT shape) are repeatable as
    a single fixed control experiment, not a class of defects to
    re-sample.
  - **Threshold impact:** §9 unchanged. W-F3 is reported in
    `BASELINE.md` and `FINAL-CERTIFICATION.md` as a measured
    framing-effect delta. No additional kill-rate threshold is
    pre-registered for W-F3 itself (it is a pass-or-fail design check,
    not a population statistic).
  - **Critic-review actionability fixes** to mutation specs (W-B1
    variable name, W-B2 insertion point, W-C2 re-anchor to CHECK-3,
    W-C3 re-anchor to lines 23-26 of session-log, W-D1 re-target to
    test-hooks-blocking.sh) were applied to `WORKING-CORPUS.md`
    before the Injector runs. These do not change the corpus shape
    or class counts — they make the pre-registered mutation specs
    actionable on the live source. The §6.1 distribution is
    unchanged.

- **2026-05-23 (post-injection, pre-valid-measurement — lab
  relocation, not a design change).** Phase-2 Detector trials at
  R101–R106 hit a sub-agent permission boundary: the project's
  `.claude/settings.local.json` allow-list scopes sub-agent Read/Grep/
  Bash/Write to the project tree (`Read(//c/Users/…/APEX/**)`) plus
  `/tmp`, and the original `§2` lab location `C:\temp\apex-detector-lab*`
  is OUTSIDE that scope. The six trials returned glob-only degraded
  reports (one even correctly catching W-A1 / W-A3 via filename
  inspection alone — interesting but not a valid baseline). Those
  trial files are discarded.
  - **Resolution:** the three lab clones (`apex-detector-lab`,
    `apex-detector-lab-baseline` — 13 A-E mutants applied,
    `apex-detector-lab-W-F3` — W-A1 only) were moved (rename-only,
    same drive, mutations preserved) from `C:\temp\` to
    `<project>/.lab/`. The new lab root is fully inside the
    project-tree allow-list; sub-agents can Read, Grep, Bash and
    Write normally against it. `.lab/` was added to `.gitignore`.
    `INJECTION-LOG-baseline.md` paths now logically refer to the new
    location; the injected diffs themselves are byte-identical.
  - **OneDrive side-effect:** `.lab/` is inside the OneDrive-synced
    project, so the lab files will queue for upload in the background.
    This is acceptable — `.lab/` is gitignored, large, and the sync
    is non-blocking. Phase 6 regression `run-all.sh` can re-clone to a
    non-synced location for the suite run if the OneDrive penalty
    matters there; the *audit* phase reads individual files, which
    OneDrive does not slow noticeably.
  - **Method / corpus / thresholds / scoring rubric:** all unchanged.
    The detector method, blind 3-agent protocol, trial count, corpus
    composition (incl. the W-F3 extension), and pre-registered §9
    thresholds are unaffected. Only the path on disk changed.
  - **Discarded trial files** (degraded — DO NOT score):
    `detector-review/trials/baseline-trial-1.md` (R101 inline only),
    R102 (inline), R103 (empty), R104 (inline), R105 (WRITE_FAILED),
    R106 (inline). The Scorer ignores any file that does not
    correspond to a clean trial run against `.lab/`.

## 13. Freeze declaration

This protocol is frozen as of 2026-05-23 against baseline commit
`8ac2a85`. Phases 2 and 6 execute it verbatim. Deviations require a §12
entry and are surfaced to the owner.
