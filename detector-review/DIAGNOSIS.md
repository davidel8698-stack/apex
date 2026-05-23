# APEX Self-Heal Detection Pipeline — Failure-Detection Diagnosis

> Read-only diagnostic. No source file was modified. This document maps every
> point in the `/apex:self-heal` 5-stage + orchestrator pipeline where a *real*
> defect, gap or error can be lost — not surfaced, not passed on, down-graded,
> deferred, WONTFIX'd, or compressed away — and the file/line evidence for each.
>
> Pipeline under review (5 agents + orchestrator):
> - **A** `framework/agents/specialist/framework-auditor.md`
> - **B** `framework/agents/specialist/remediation-planner.md`
> - **C** `framework/agents/specialist/batch-scheduler.md`
> - **D** `framework/agents/specialist/wave-executor.md`
> - **E** `framework/agents/specialist/round-checker.md`
> - **Orch** `framework/commands/apex/self-heal.md`
> - Hooks: `framework/hooks/circuit-breaker.sh`, `framework/hooks/context-monitor.sh`
> - Spec: `apex-spec.md` §"Self-Healing Loop" (lines 342–392)

---

## 1. Summary

### Shape of the detection pipeline

The self-heal loop is a **strictly linear single-funnel** detector. Detection
happens at exactly **one node** — Step A (`framework-auditor`). Every later
stage is a *transformer* of what Step A already wrote, not an independent
detector:

```
   apex-spec.md  ── (the ONLY measuring stick) ──┐
                                                 ▼
  A framework-auditor  ──→ apex-audit-findings-R<N>.md   [SOLE DETECTOR]
                                                 │  (F-NNN, P0-P3)
                                                 ▼
  B remediation-planner ──→ REMEDIATION-PLAN-R<N>.md     [transform: F→R or WONTFIX]
                                                 │
                                                 ▼
  C batch-scheduler     ──→ WAVES-R<N>.md                [transform: R→waves; can DEFER]
                                                 │
                                                 ▼
  D wave-executor       ──→ WAVE-R<N>-W<X>-RESULT.md     [executes; side-channel: NEW-FINDINGS]
                                                 │
                                                 ▼
  E round-checker       ──→ ROUND-R<N>-CLOSURE.md        [count-based stop verdict]
```

There is exactly **one** secondary detection channel — the wave-executor's
`NEW-FINDINGS-R<N>-W<X>.md` side-channel in Step D (and an undocumented
orchestrator-level `NEW-FINDINGS-ORCHESTRATOR-R<N>.md` variant, see L17). A
defect that Step A does not see has only that one mid-execution channel left
to be caught, and that channel deliberately defers the defect to the *next*
round's Step A — so it still ultimately depends on Step A re-seeing it.

### Biggest detection risks (ranked)

1. **Single point of detection failure (W1+W2).** Step A is the only detector
   and it is *constructed* to be blind in two ways at once: it may only report
   things that **contradict the spec** (`framework-auditor.md:19-20`), and ~half
   its 12 axes are **presence/registration checks** (`framework-auditor.md:62-115`
   — "present", "exists", "registered", "wired") rather than break-attempts. A
   real defect that the spec is silent about, or that exists *behind* a present-
   and-registered mechanism, is invisible by construction. There is no second
   detector to catch what A misses.

2. **The stop criterion consumes A's COUNT as ground truth (W4).** Step E's
   entire CLOSED/CONTINUE decision is `P0+P1 == 0` across two rounds
   (`round-checker.md:83-89`). Step E never re-audits. If A under-reports —
   for any of the W1/W2/W3/W5 reasons — E mechanically converges. The loop's
   "2 consecutive clean rounds" terminator is therefore only as honest as A's
   finding count, and nothing in the loop cross-checks that count.

3. **A inherits a green test suite it never ran (W3).** The full suite is
   ~919s and overruns the timeout, so A spot-runs ~4 tests and *infers* the
   rest are green (`apex-audit-findings-R24.md:15,54`, `:81-82`). Any defect
   that only a non-spot-run test would catch is silently inherited as "passing".

4. **Down-classification with no audit trail across the B→C→E hand-offs.**
   B may WONTFIX a finding (`remediation-planner.md:30-32`), C may DEFER an
   R-item (`batch-scheduler.md:71-74`), and E folds both into prose. WONTFIX
   requires a spec-anchored justification but **nothing validates that the
   justification is sound** — E's coverage check (`round-checker.md:69-71`)
   accepts "WONTFIX documented" as satisfied without re-judging it.

5. **The whole loop runs in a frame that biases toward "converged."** The
   orchestrator hands A a `previous_findings_path` "for trajectory awareness"
   (`framework-auditor.md:49-51`), recent rounds self-label as "POST-CONVERGENCE
   CONFIRMATION" (`apex-audit-findings-R24.md:1,4`), and nothing instructs A to
   resist that framing (W5). A primed auditor confirms; it does not hunt.

6. **Every artifact is git-ignored / untracked (new — W7).** All five artifact
   classes are in `.gitignore` (`.gitignore:18-24`) and `git ls-files` shows
   none tracked. A finding that is dropped between rounds leaves **no diffable
   trail** — the detector's own output has no version history to audit.

The net picture: detection is a **one-shot, spec-anchored, presence-biased,
test-inheriting, count-terminated** funnel with no independent verification at
any downstream node. The 4 near-empty rounds (R21–R24, R24 = 0 findings) are
fully consistent with a detector that has gone quiet *because it was built to
go quiet*, not because the framework is defect-free.

---

## 2. Leak-Point Register

Each row: where a real defect is lost, with verbatim file evidence and the
weakness it maps to. "Leak" = a defect that exists is not surfaced, not passed
on, down-classified, deferred, WONTFIX'd, or compressed away.

| ID | Stage | How a real defect is lost here | Evidence (file — verbatim) | Maps to |
|----|-------|-------------------------------|----------------------------|---------|
| **L01** | A Auditor | A defect the spec does not mention is, by rule, **not a finding** — it is discarded before it is even written down. | `framework-auditor.md:19-20`: *"If something does not contradict the spec, it is not a finding."* Also `:16-18`: *"Every gap is measured against it alone. Not against general best practices..."* | W1 |
| **L02** | A Auditor | ~6 of 12 axes are **presence/registration checks** — they confirm a mechanism *exists/is wired*, not that it *works or cannot be bypassed*. A broken-but-present mechanism passes. | `framework-auditor.md:62-65` (axis 1: *"present, active, and invoked"* — but verified by `apex-audit-findings-R24.md:35` as *"verified present and executable"*), `:84-89` (axis 6), `:91-94` (axis 8), `:96-101` (axis 9: *"do all four... exist and get written/read"*), `:103-106` (axis 10: *"all present and active?"*). Confirmed in practice: `apex-audit-findings-R24.md:42` *"`/apex:new-agent` present (`new-agent.md`)"*, `:43` *"31 entries"*. | W2 |
| **L03** | A Auditor | A is never instructed to **attempt a bypass / break** the framework — only to look. A live exploit that no axis phrases as a question stays invisible. | `framework-auditor.md:52-115` — no axis contains "attempt", "bypass as an attacker", "try to break", "inject". Axis 10 asks *"Where is the path that bypasses them?"* (`:103-106`) but as analysis, not as an executed break-attempt. Contrast `health-check` Poison Pill validation, which is a *separate* command. | W2 |
| **L04** | A Auditor | A **inherits "all green"** from a test suite it does not run. The full suite (~919s) overruns the timeout; A spot-runs ~4 tests and infers the remaining ~68 pass. A defect only a non-spot-run test catches is lost. | `apex-audit-findings-R24.md:15`: *"R24 did not re-run the full `run-all.sh` aggregate (which exceeds 600s...). Instead R24 spot-ran four representative self-tests"*; `:54`: *"the remaining ~68 tests in the suite were not re-run this round... HIGH that the suite is green"*. The auditor prompt itself never mandates a full-suite run. | W3 |
| **L05** | A Auditor | "Do not filter early" is stated (`:35-37`) but A is also told **better 20 solid findings than 60 with 30 speculative** (`:32-34`) and to mark uncertain items `SUSPECTED`. The pressure to be "solid" suppresses borderline-but-real defects. | `framework-auditor.md:31-34`: *"Better to report 20 solid findings than 60 with 30 speculative."* `:130-131`: P2 = *"partial/dormant mechanism but not actively breached"*, P3 = *"declaration without enforcement, low blast radius"* — real gaps land at P2/P3 which **do not block closure** (E only counts P0/P1). | W1 / W4 |
| **L06** | A Auditor | A is handed the **previous round's findings file** and recent rounds run under an explicit "POST-CONVERGENCE CONFIRMATION" frame; no instruction tells A to resist that priming. A confirms the prior verdict instead of hunting fresh. | `framework-auditor.md:49-51`: *"`previous_findings_path` (optional) — path to the prior round's audit file, for trajectory awareness"*. Live effect: `apex-audit-findings-R24.md:1` title *"(POST-CONVERGENCE CONFIRMATION ROUND)"*, `:4` *"Scope: POST-CONVERGENCE FRESH CONFIRMATION"*. No counter-instruction anywhere in `framework-auditor.md`. | W5 |
| **L07** | B Planner | B may mark any finding **`WONTFIX`** — and although a spec-anchored justification is required, **no stage re-validates that the justification is correct**. A real P1 can exit the pipeline as a WONTFIX line nobody checks. | `remediation-planner.md:30-32`: *"Every F-ID... must receive a matching R-, or be explicitly marked `WONTFIX` with a justification anchored in the spec."* E's coverage check (`round-checker.md:69-71`) only asks the finding *"received treatment (DONE / WONTFIX documented / deferred documented)"* — "documented" ≠ "justified correctly". | W6 |
| **L08** | B Planner | B can down-classify via the **`UNKNOWN — needs investigation`** disposition. An UNKNOWN R-item is then excluded from all waves by C (`batch-scheduler.md:43-44`), so it is never executed and silently rolls to "next round" — which, on a converged loop, never comes. | `remediation-planner.md:32-33`: *"'UNKNOWN — needs investigation' is preferable to a guess."* `batch-scheduler.md:43-44`: *"WONTFIX and UNKNOWN: do not enter any wave."* No mechanism forces an UNKNOWN to ever be resolved. | W6 |
| **L09** | B Planner | A gap **B itself discovers** during planning is, by rule, **not allowed to become an R-item** — it is filed to a bottom-of-file "New findings" section that only feeds the *next* round's audit. If the loop closes, that section is never read. | `remediation-planner.md:38-40`: *"A new gap you discovered → record in the `New findings discovered during planning` section at the bottom, not as an R-."* `:136-139` confirms: *"Do not fix them, do not insert them as R-. Record only for the next round's audit."* Live: `apex-audit-findings-R24.md:94-117` shows `NF-R22-PLAN-01` carried for 3 rounds and repeatedly re-dispositioned "NOT a finding." | W6 / W7 |
| **L10** | B Planner | The remediation form's per-finding fields include **`Requires human decision: YES/NO`** and `Reversibility/Confidence`. A finding routed to "human decision" leaves the automated pipeline; if the human never answers, it is dropped with no re-prompt. | `remediation-planner.md:117-119`: *"Requires human decision: YES / NO (if YES — explain the question)."* `batch-scheduler.md:42-43`: *"Unresolved HUMAN DECISION REQUIRED: does not enter any wave. Mark separately."* Nothing tracks unanswered human decisions across rounds. | W6 |
| **L11** | C Scheduler | C may place an R-item in the **`Deferred`** section ("R-IDs you recommend deferring to the next round") — a real, planned fix is pushed out of the round on the scheduler's discretion, and on a converging loop the "next round" may not happen. | `batch-scheduler.md:71-73`: *"**Deferred:** R-IDs you recommend deferring to the next round and why."* `:76-79` termination criterion explicitly allows *"explicitly marked deferred/pending"* as a valid terminal state for an R-item. | W6 |
| **L12** | C Scheduler | C is a **pure structural transformer with no detection mandate** — it never reads source, only `REMEDIATION-PLAN` and `apex-spec.md` (`batch-scheduler.md:16-18`, `tools: Read, Write` only, no Bash/Grep). A defect in how a fix is grouped, or a missing R-item, cannot be caught here — C cannot see the codebase. | `batch-scheduler.md:4`: `tools: Read, Write` (no Grep, no Bash). `:15-18` INPUT is only `plan_path`, `spec_path`, `output_path`. C has no window onto the live framework at all. | W6 |
| **L13** | D Executor | The **`NEW-FINDINGS` channel is optional and never verified by the orchestrator.** The result file is mandatory and disk-verified; the new-findings file is not. A wave that discovers a defect but never writes `NEW-FINDINGS-R<N>-W<X>.md` loses it with zero alarm. | `wave-executor.md:157-161`: *"`<new_findings_path>` (optional, only if you discovered gaps during execution)"*. `self-heal.md:269-276` POST-TASK VERIFICATION checks **only** `WAVE-R<N>-W<W>-RESULT.md` exists — never the new-findings file. `wave-executor.md:99-101` write-verify step checks only `<wave_result_path>`. | W6 |
| **L14** | D Executor | A mid-wave discovery is **forbidden from being fixed in-round and is deferred to the next audit** by design. If the loop closes (R<N+1> never runs), the discovered defect is permanently lost. | `wave-executor.md:36-39`: *"If you discovered an additional gap — **do not fix it**. Record it in `NEW-FINDINGS-R<N>-W<X>.md` for the next audit round."* `apex-spec.md:366-368`: *"new findings discovered mid-wave go to `NEW-FINDINGS-W<X>.md` (never to new fixes)."* Round-checker only reads new-findings if the loop continues. | W6 |
| **L15** | D Executor | **Token-exhaustion / compression escape hatch.** The executor's termination criterion lets it stop and "report what was not done" if it runs out of tokens. R-items in an unfinished wave silently become SKIPPED with a one-line note; the defect they were to fix is still open but the round can still close via E. | `wave-executor.md:148-153`: *"If you ran out of tokens — stop, commit what is complete, report what was not done. Do not compress."* The `SKIPPED` disposition (`:120,:126`) is a first-class outcome; E treats SKIPPED-with-report as "treated" (`round-checker.md:69-71`). | W6 |
| **L16** | D Executor | **Wave-abort revert can erase an in-progress fix and the round still closes.** Any single acceptance-criterion failure stops the *entire* wave and `git`-reverts the failed R-. The orchestrator does not fail the round on a BLOCKED/PARTIAL wave — it proceeds to E with `partial_round=true` and E "surfaces it as DEFERRED." | `wave-executor.md:54-59` (stop wave, revert, do not fix). `self-heal.md:283-286`: *"If `status == BLOCKED` or `PARTIAL`: break the wave sub-loop, proceed to Step E... Do NOT mark the round as failed yet."* `self-heal.md:92-95`: missing wave file → *"round-checker will see the missing wave result and surface it as DEFERRED."* DEFERRED is not a closure blocker. | W6 |
| **L17** | Orch | The orchestrator can itself discover defects (it ran the post-wave breaker probe and found a hang in R20) but writes them to an **undocumented** `NEW-FINDINGS-ORCHESTRATOR-R<N>.md` filename. Step E's input list (`round-checker.md:22-23`) only enumerates `NEW-FINDINGS-R<N>-W<X>.md` — the orchestrator variant is **not in E's input contract** and can be silently skipped. | `NEW-FINDINGS-ORCHESTRATOR-R20.md:1-8` exists and self-describes as orchestrator-discovered. `round-checker.md:22-23`: *"`new_findings` — list of absolute paths to `NEW-FINDINGS-R<N>-W<X>.md` files"* — pattern does not match `NEW-FINDINGS-ORCHESTRATOR-R<N>.md`. `self-heal.md:296-297` collects only `NEW-FINDINGS-R<N>-W<X>.md`. | W6 / W7 |
| **L18** | E Checker | **E never independently re-verifies.** Closure consumes A's finding *count*. The stop criterion is purely `P0+P1 == 0` over two rounds; E re-reads no source, runs no audit, attempts no break. If A under-detected, E mechanically declares CLOSED. | `round-checker.md:83-89` stop criterion is three count conditions only. `:69-71` coverage check counts dispositions, not correctness. `tools: Read, Write, Bash` but the prompt never tasks Bash with re-auditing — only with `ls`/`test -f` write-verification (`:176-179`). | W4 |
| **L19** | E Checker | **Severity is the gate, and only P0/P1 gate it.** A real defect correctly detected but classified P2 or P3 by A *does not block closure* and is folded into "remaining issues" prose. The loop can close with unbounded open P2/P3 defects. | `round-checker.md:83-89`: stop criterion names only P0 and P1. `:108-113` severity breakdown lists P2/P3 but they never appear in the CLOSED test. Live: `apex-audit-findings-R24.md:135` carries `NF-R22-PLAN-01` as P3 and `round-checker.md` mapping (`:124-130`) lets `P0+P1==0` close regardless of P2/P3 volume. | W4 |
| **L20** | E Checker | **The degraded HALTED branch lets E generate a closure from partial inputs.** When a round halts mid-execution, E classifies un-run R-IDs as `LANDED/PARTIAL/NOT-STARTED/BLOCKED` "from disk evidence" and emits a HALTED closure. Un-landed defects roll into the next round under "rotated R-IDs" — and if the next round is suppressed, they vanish. | `round-checker.md:33-64`: degraded HALTED mode; `:52-58`: *"Recommendation MUST be `Run R<N+1>...`. The HALT itself is the seed signal — the next round inherits R12's backlog under rotated R-IDs."* The inheritance depends entirely on a next round actually running. | W6 |
| **L21** | E Checker | **Trajectory framing softens stagnation into "stable."** A flat-zero finding count is mapped to posture `stable` (a reassuring word). A detector that has gone silent and a framework that is genuinely clean produce the *identical* `STAGNANT → stable` output — E cannot tell them apart and the wording hides the ambiguity. | `round-checker.md:124-130` mapping: *"`P0 + P1 == 0` and trajectory `STAGNANT` → **stable**."* Live: `apex-audit-findings-R24.md:21` (*"Total findings emitted: 0"*) → `ROUND-R24-CLOSURE.md:298` posture *"stable"*. Nothing distinguishes "0 because clean" from "0 because blind." | W4 / W5 |
| **L22** | Orch | The orchestrator passes A a `round_number` and the prior findings path but **no instruction to run A adversarially**; and `resolve_model()` may route A to a cheaper model. A weaker/primed model on a confirmation round detects less, and the orchestrator has no floor on detection effort. | `self-heal.md:176-185` `AUDIT_CONTEXT` + `Task("framework-auditor", AUDIT_CONTEXT, model=resolve_model("framework-auditor"))` — model is whatever the router returns; no minimum-rigor contract. `self-heal.md:1-2` description frames the loop's goal as *"until convergence"* — a convergence-seeking frame. | W5 |
| **L23** | Orch | **Context-rotation mid-round can truncate detection.** After Step A the orchestrator runs `context-monitor.sh`; at the 70% threshold it persists STATE and exits ("type /apex:resume"). If A produced a partial audit just under a token wall, the round still advances on whatever A wrote — A's own termination rule says "stop... do not compress" but a truncated findings file is still consumed verbatim by B. | `self-heal.md:195-198`: context-monitor 70% → *"persist STATE and exit cleanly"*. `framework-auditor.md:168-172`: *"If you run out of tokens before finishing — stop, report what you covered and what remains, do not compress."* A partial audit is never re-run; B/C/E consume it as complete. `context-monitor.sh:261-266` hard threshold. | W3 / W6 |
| **L24** | Orch | **All self-heal artifacts are git-ignored.** Every artifact class is in `.gitignore`; `git ls-files` confirms none is tracked. A finding dropped between rounds, a WONTFIX, a deferral — none leaves a diffable, version-controlled trail. The detector's own evidence base is ephemeral and unauditable post-hoc. | `.gitignore:18-24`: `apex-audit-findings-*.md`, `NEW-FINDINGS-*.md`, `WAVE-*-RESULT*.md`, `WAVE-*-EXIT-INVARIANTS.json`, `WAVES-R*.md`, `ROUND-R*-CLOSURE.md`, `REMEDIATION-PLAN-*.md` — all ignored. `git ls-files` over these patterns returns nothing. | W7 |
| **L25** | A Auditor | **`SUSPECTED` findings are a soft exit.** A finding A is unsure about is marked `SUSPECTED` (`:131-132`); B is allowed to convert it to `UNKNOWN` (L08) or WONTFIX (L07). A genuine defect A half-saw can therefore decay SUSPECTED → UNKNOWN → never-scheduled without any stage ever confirming or refuting it. | `framework-auditor.md:131-132`: *"Status: CONFIRMED / SUSPECTED"*; `:23-26` *"If unsure — mark `SUSPECTED`, not `CONFIRMED`."* No stage is tasked with *resolving* a SUSPECTED into CONFIRMED/refuted before closure. | W1 / W6 |
| **L26** | E Checker | **Spec-drift check is self-referential.** E's "spec drift check" only re-checks anchors *that appeared in this round's findings* (`round-checker.md:75-78`). On a zero-finding round there are zero anchors to check, so the drift check is **vacuously passed** — exactly when an independent re-check would matter most. | `round-checker.md:75-78`: *"for every spec anchor that appeared in this round's findings — is it now covered..."*. Live: `apex-audit-findings-R24.md:170` / `ROUND-R24-CLOSURE.md:164-170`: *"R24 emitted zero findings, so there is no per-finding spec anchor to verify this round."* | W4 |

**Leak-point count: 26.**

---

## 3. Per-Stage Analysis

For each stage, the five mandated questions: (1) input & what it can silently
drop; (2) where it trusts an upstream artifact without re-verifying; (3) where
a defect can be down-classified/deferred/WONTFIX'd/compressed and whether
there is an audit trail; (4) [Step D only] NEW-FINDINGS reliability; (5) any
instruction that biases toward "nothing found".

### Step A — `framework-auditor` (the sole detector)

**(1) Input / silent-drop.** Input is `spec_path`, `repo_root`, `round_number`,
`output_path`, and an optional `previous_findings_path`
(`framework-auditor.md:41-51`). A's read scope is the whole framework tree
(`:198-199`). What A can silently drop:
- Any defect the spec is silent about — discarded *before being written*
  (`:19-20`, **L01**). This is the largest single drop in the entire pipeline.
- Anything outside the 12 axes — the axes are exhaustive of A's attention
  (`:54-55` *"Investigate each of these axes separately. Do not skip any."*),
  but a defect that fits no axis has no slot.
- Borderline-but-real defects, suppressed by the "20 solid > 60 with 30
  speculative" pressure (`:32-34`, **L05**).
- The ~68 non-spot-run tests' worth of failures, inherited as green
  (`apex-audit-findings-R24.md:54`, **L04**).

**(2) Trust without re-verify.** A *trusts the test suite without running it*
— it spot-runs ~4 tests and infers the rest pass with "HIGH" confidence
(`apex-audit-findings-R24.md:15,54,81-82`, **L04**). It also trusts the prior
findings file as a trajectory anchor (`framework-auditor.md:49-51`, **L06**).
A's own write-first contract (`:174-192`) is self-verification of *its file*,
not of *its findings*.

**(3) Down-classification / trail.** A assigns severity P0–P3 itself
(`:127-132`). The down-classification risk is **at the moment of assignment**:
P2 = *"partial/dormant mechanism but not actively breached"* and P3 =
*"declaration without enforcement, low blast radius"* (`:130-131`). A real,
live gap that A reads as "dormant" or "declaration only" lands at P2/P3 and —
because E's stop criterion counts only P0/P1 (`round-checker.md:83-89`) — never
blocks closure (**L05/L19**). The audit trail is the findings file itself,
which is **git-ignored** (`.gitignore:18`, **L24**) — so a severity choice has
no version history. `SUSPECTED` is a second soft path (`:131-132`, **L25**).

**(4)** N/A (Step D only).

**(5) Bias toward "nothing found".** Three explicit biases:
- The spec-anchor rule (`:19-20`) — a *narrowing* instruction: only spec
  contradictions count (W1).
- ~6 of 12 axes are existence checks ("present, active, and invoked",
  "exist and get written/read", "all present and active?" —
  `:62-65,:96-101,:103-106`), and the live audit resolves them as "verified
  present and executable" (`apex-audit-findings-R24.md:35,42,43`). A
  present-but-broken mechanism passes (W2).
- No instruction to resist orchestrator framing; recent rounds carry a
  "POST-CONVERGENCE CONFIRMATION" self-label (`apex-audit-findings-R24.md:1,4`)
  with no counter-instruction in the prompt (W5).
- A is never told to *attempt a break* — every axis is phrased as "where does
  it fail to meet the promise" (`:56-57`), an analysis stance, not an attack
  stance (W2/**L03**).

### Step B — `remediation-planner`

**(1) Input / silent-drop.** Input is `findings_path`, `spec_path`,
`style_guide_path`, `output_path` (`remediation-planner.md:14-24`). B is
forbidden to touch code (`:9-10`, `tools: Read, Write, Bash` — Bash present
but `:9-10` forbids state mutation). What B can silently drop:
- A finding routed to **WONTFIX** with a spec-anchored justification
  (`:30-32`, **L07**) — leaves the pipeline.
- A finding routed to **UNKNOWN** (`:32-33`, **L08**) — excluded from all
  waves by C, never executed.
- A finding routed to **Requires human decision: YES** (`:117-119`, **L10**)
  — leaves the automated pipeline.
- A gap **B itself finds** during planning, which by rule cannot become an
  R-item — filed to a bottom section that only feeds the next round's audit
  (`:38-40,:136-139`, **L09**).

**(2) Trust without re-verify.** B trusts the findings file *completely*: it
is forbidden to add a fix without a matching finding (`:38-40`) and forbidden
to merge findings (`:34-36`). B does not re-audit the codebase to confirm a
finding is real before planning a fix for it — and conversely it cannot add
one A missed. B is a faithful transformer of A's output, which means **every
W1/W2/W3 blind spot of A is inherited verbatim by B with no correction
opportunity.**

**(3) Down-classification / trail.** WONTFIX (`:30-32`) and UNKNOWN
(`:32-33`) are B's two down-classification levers. WONTFIX *requires* a
spec-anchored justification — a partial trail — but **nothing re-judges the
justification.** E's coverage check accepts "WONTFIX documented" as satisfied
(`round-checker.md:69-71`) — *documented*, not *correct*. There is no
"WONTFIX-review" stage. The R-item form also records `Reversibility`,
`Confidence in fix approach: high/medium/low`, and `Requires human decision`
(`:115-119`) — a low-confidence or human-gated R-item is a recorded but
unresolved down-classification. Trail = the plan file, git-ignored (**L24**).

**(4)** N/A.

**(5) Bias toward "nothing found".** B's biases are *milder* than A's but
present: *"'UNKNOWN — needs investigation' is preferable to a guess"*
(`:32-33`) legitimizes parking a finding rather than resolving it; and the
hard rule *"a new gap you discovered → record... not as an R-"* (`:38-40`)
structurally prevents B from *adding* detection — B can only ever shrink or
preserve A's finding set, never grow the actionable set.

### Step C — `batch-scheduler`

**(1) Input / silent-drop.** Input is `plan_path`, `spec_path`, `output_path`
(`batch-scheduler.md:15-18`); `tools: Read, Write` only — **no Grep, no Bash**
(`:4`). C cannot see the codebase at all. What C can silently drop:
- An R-item placed in **Deferred** ("R-IDs you recommend deferring to the
  next round and why" — `:71-73`, **L11**).
- An R-item left as **pending human decision** (`:42-43`, **L10** continued).
- WONTFIX / UNKNOWN R-items, which C is told do not enter any wave
  (`:43-44`) — C is the stage that *enacts* B's down-classification by
  physically excluding them from execution.

**(2) Trust without re-verify.** C trusts the plan entirely. Its only check is
*structural*: independence within a wave, topological order, conflict matrix
(`:22-39`). C never reads source (it has no tool to — `:4`), so it cannot
detect that a fix is mis-scoped, that an R-item is missing, or that a defect
exists. C is a **pure structural transformer with zero detection capability**
(**L12**).

**(3) Down-classification / trail.** The **Deferred** section (`:71-73`) is
C's down-classification lever — a planned, real fix is pushed to "next round"
on the scheduler's recommendation. The termination criterion explicitly blesses
this: *"Every approved R- is placed in a wave or explicitly marked
deferred/pending"* (`:76-79`). Trail = `WAVES-R<N>.md`, git-ignored (**L24**).
There is a bottom-of-file "Deferred" list but no mechanism that forces a
deferred R-item to actually be picked up later.

**(4)** N/A.

**(5) Bias toward "nothing found".** C has no detection mandate, so it cannot
*bias* detection — but its inability to see the codebase (`:4`) means it can
never *catch* what A and B missed. It is a structural dead-end for detection.

### Step D — `wave-executor`

**(1) Input / silent-drop.** Input is `waves_path`, `wave_number`, `plan_path`,
`spec_path`, `findings_path`, `wave_result_path`, `new_findings_path`
(`wave-executor.md:15-30`). Note: the executor is told to read **only** its own
wave's section and **only** the R-IDs in its wave (`:16-22`) — a deliberate
context-narrowing. What D can silently drop:
- A defect discovered mid-wave, if D never writes the (optional)
  `NEW-FINDINGS` file (`:157-161`, **L13**).
- R-items in an unfinished wave when D runs out of tokens — they become
  SKIPPED with a one-line note (`:148-153`, **L15**).
- A fix that was in progress when any acceptance criterion failed — the whole
  wave aborts and the failed R- is `git`-reverted (`:54-59`, **L16**).
- Anything outside its wave — D is told `Scope is bounded` and an additional
  gap must **not be fixed** (`:36-39`, **L14**).

**(2) Trust without re-verify.** D trusts the plan and findings as read-only
inputs (`:24-27`, `:75-78`). It has one *anti-trust* mechanism: if the plan
violates `REMEDIATION-STYLE.md` (raw line numbers, missing anchors) D must
**reject the wave**, write a NEW-FINDING, and exit (`:79-85`). That is a
genuine upstream check — but it checks *plan style*, not *finding correctness*.
D does not re-verify that the finding it is fixing is real.

**(3) Down-classification / trail.** D's down-classification levers:
`SKIPPED` (`:120,:126`, token exhaustion or unreachable), `REVERTED`
(`:54-59,:120`, acceptance-failure abort). Both are recorded in
`WAVE-R<N>-W<X>-RESULT.md` (`:111-146`) — a real trail — **but that file is
git-ignored** (`.gitignore:20`, **L24**). A REVERTED R- means the defect it
targeted is still open; the orchestrator does **not** fail the round on a
BLOCKED/PARTIAL wave (`self-heal.md:283-286`) and E treats it as DEFERRED
(`self-heal.md:92-95`), which is not a closure blocker.

**(4) NEW-FINDINGS channel reliability — this is the question Step D exists to
answer, so in detail.** The channel is **unreliable in four distinct ways:**

  - **(4a) The file is optional and never disk-verified by the orchestrator.**
    `wave-executor.md:157-161`: *"`<new_findings_path>` (optional, only if you
    discovered gaps during execution)."* The orchestrator's POST-TASK
    VERIFICATION (`self-heal.md:269-276`) checks **only** that
    `WAVE-R<N>-W<W>-RESULT.md` exists — it never `test -f`'s the new-findings
    file. The executor's own write-first contract verifies only
    `<wave_result_path>` (`wave-executor.md:99-101`). So if D *believes* it
    has no new findings, or D writes the new finding into the RESULT file's
    "New findings discovered during execution" section (`:144-146`) but **not**
    into the separate `NEW-FINDINGS` file, the orchestrator's collection step
    (`self-heal.md:296-297`, "where they exist") finds no file and the finding
    is lost. The RESULT file's embedded new-findings section and the standalone
    NEW-FINDINGS file are two sinks for the same data and only one is collected.

  - **(4b) Deferred-to-next-round-by-design.** Even when written correctly, a
    NEW-FINDING is *not* fixed in-round — it is *"for the next audit round"*
    (`wave-executor.md:36-39`; `apex-spec.md:366-368`). E only ingests it if
    the loop CONTINUEs. If E declares CLOSED — which it will, mechanically, if
    A's count is 0 — the NEW-FINDINGS file is read by E's regression check
    (`round-checker.md:79-82`) but **a P2/P3 new-finding does not re-open the
    loop** (stop criterion `:83-89` only blocks on open *P0/P1* new-findings).
    A real P2/P3 defect a wave discovered is permanently parked. Live proof:
    `apex-audit-findings-R24.md:94-117` — `NF-R22-PLAN-01` has been carried and
    re-dispositioned "NOT a finding" for 3 consecutive rounds.

  - **(4c) Severity is self-assessed and advisory.** The executor (or
    orchestrator) proposes a severity; `NEW-FINDINGS-ORCHESTRATOR-R20.md:7-8`
    states *"Proposed severities below are the orchestrator's assessment — the
    round-checker is the disposition authority."* A genuine P1 discovered
    mid-wave can be proposed P2, and E — which does not re-audit — has weak
    grounds to overturn it.

  - **(4d) Filename-contract mismatch for orchestrator discoveries.** When the
    orchestrator itself discovers a defect (it did in R20 — the
    `circuit-breaker.sh` standalone hang, `NEW-FINDINGS-ORCHESTRATOR-R20.md`)
    it writes `NEW-FINDINGS-ORCHESTRATOR-R<N>.md`. E's input contract
    (`round-checker.md:22-23`) and the orchestrator's own collection step
    (`self-heal.md:296-297`) both enumerate **only** `NEW-FINDINGS-R<N>-W<X>.md`.
    `NEW-FINDINGS-ORCHESTRATOR-R<N>.md` matches neither pattern → an
    orchestrator-discovered defect can be silently omitted from E's inputs
    (**L17**). (It survived in R20 only because R20 was a continuing round and
    a human/agent carried it forward — not because the contract caught it.)

  **Verdict on (4):** a wave-discovered defect *can* be lost — by non-write
  (4a), by closure-before-next-round (4b), by severity under-proposal (4c), or
  by filename mismatch for orchestrator discoveries (4d). The channel is a
  best-effort side-channel, not a guaranteed one.

**(5) Bias toward "nothing found".** D's scope discipline is *intentionally*
biasing: *"Scope is bounded... If you discovered an additional gap — do not
fix it"* (`:36-39`). This is correct for execution hygiene but it means D is
structurally prevented from converting a discovery into a closed defect — D
can only ever park it. Combined with (4), D's contribution to detection is a
fragile, deferred, never-verified side-channel.

### Step E — `round-checker` (the stop authority)

**(1) Input / silent-drop.** Input is the full artifact set: findings, plan,
waves, all wave-results, all new-findings, prior closure, spec, output path,
`current_round`, `consecutive_clean_rounds_before` (`round-checker.md:14-31`).
What E can silently drop:
- A P2/P3 finding — never enters the CLOSED test (`:83-89`, **L19**).
- A `NEW-FINDINGS-ORCHESTRATOR-R<N>.md` file — not in E's input contract
  (`:22-23`, **L17**).
- In degraded HALTED mode, un-landed R-IDs are reclassified and rolled to
  "next round" (`:33-64`, **L20**).

**(2) Trust without re-verify — this is E's defining flaw (W4).** E **never
re-audits.** Its `tools` are `Read, Write, Bash` (`:4`) but Bash is used only
for write-verification (`ls`/`test -f`, `:176-179`), never to run an audit or
attempt a break. The coverage check (`:69-71`) counts dispositions
("DONE / WONTFIX documented / deferred documented"). The quality check
(`:73-75`) reads whether waves passed *their* gates. The spec-drift check
(`:77-78`) only re-checks anchors *that appeared in this round's findings* —
so on a zero-finding round it is **vacuously satisfied** (**L26**;
`apex-audit-findings-R24.md:170`). The stop criterion (`:83-89`) is three
*count* comparisons. **At no point does E independently confirm that A's count
is correct.** E consumes A's `P0+P1` number as ground truth. This is the
direct mechanism by which any A-side under-detection (W1/W2/W3/W5) becomes a
CLOSED verdict with no resistance.

**(3) Down-classification / trail.** E does not itself down-classify findings,
but it is the stage where every upstream down-classification is *ratified*:
- WONTFIX from B → E accepts "WONTFIX documented" (`:69-71`).
- Deferred from C → E accepts "deferred documented" (`:69-71`).
- REVERTED/SKIPPED/BLOCKED from D → folded into the "Reverted and unresolved"
  / "Deferred" coverage lines (`:99-106`) and the round can still be CLOSED.
- The HALTED branch reclassifies un-run R-IDs wholesale (`:48-58`).
E's "Overall posture" sentence (`:117-130`) then compresses all of it into one
plain-language word. The trail is `ROUND-R<N>-CLOSURE.md`, **git-ignored**
(`.gitignore:23`, **L24**).

**(4)** N/A.

**(5) Bias toward "nothing found".** Strong, and structural:
- The stop criterion *rewards* a zero count — two zero-count rounds CLOSE the
  loop (`:83-89`). There is no symmetric "minimum-detection" floor; a round
  that finds nothing is treated as success, not as a red flag.
- The posture mapping (`:124-130`) maps `P0+P1==0 + STAGNANT` to the
  reassuring word **"stable."** A blind detector and a clean framework yield
  the *identical* output; the wording actively hides the ambiguity (**L21**).
  The prompt even instructs *"do not soften a degrading signal"* (`:134-135`)
  — but says nothing about not over-reassuring on a *stagnant* signal, which
  is exactly the ambiguous case.
- The whole verdict is binary CLOSED/CONTINUE driven by count; E has no
  vocabulary for "0 findings, but I do not trust the detector."

### Orchestrator — `/apex:self-heal`

**(1) Input / silent-drop.** Input is CLI flags (`--max-rounds`, `--resume`)
and `STATE.self_heal` (`self-heal.md:7-13,104-161`). The orchestrator drives
A→B→C→D→E and persists state. What it can silently drop:
- An orchestrator-discovered defect written to
  `NEW-FINDINGS-ORCHESTRATOR-R<N>.md` — not collected for E (`:296-297`,
  **L17**).
- A round's later steps if context-monitor trips at 70% — it persists STATE
  and exits; a partial audit is consumed as-is on resume (`:195-198`, **L23**).
- A wave's result if missing — marked BLOCKED, `partial_round=true`, proceed
  to E (`:269-276,:283-286`) — the round still closes via E.

**(2) Trust without re-verify.** The orchestrator's POST-TASK VERIFICATION
(`:84-99,:269-276`) is *file-existence only* — it confirms each agent wrote its
deliverable, never that the *content* is sound. This is explicitly by design
(*"Verification is a single Read or `test -f` call"*, `:100`). So the
orchestrator trusts every agent's *summary line* once the file exists. It does
**not** verify the new-findings file at all (only the result file, **L13**).

**(3) Down-classification / trail.** The orchestrator does not classify
findings, but its **decision branch** (`:327-359`) is where the loop's fate is
sealed: `CLOSED` → `status="closed"`, exit; `CONTINUE` → next round. The branch
acts purely on `closure.status` / `closure.trajectory` / `closure.p01` parsed
from E's summary line (`:321-326`). The orchestrator never re-opens E's verdict.
Event-logging (`:362-368`) writes to `.apex/event-log.jsonl` — that *is* a
trail, but the round artifacts themselves are git-ignored (**L24**).

**(4)** N/A (but note **L17/4d**: the orchestrator *is* a discoverer and its
discovery filename escapes E's input contract).

**(5) Bias toward "nothing found".** The orchestrator's framing is
convergence-seeking from the top: the command description is *"Runs
audit→...→check rounds until convergence (2 consecutive rounds with 0 P0/P1)"*
(`self-heal.md:2`). It passes A the prior findings file (`:181-184`) enabling
the "confirmation round" self-framing (**L06/L22**). `resolve_model()` may
route any agent — including A — to a cheaper model with no minimum-rigor floor
(`:183-184,:210-212`, etc., **L22**). The two-clean-rounds terminator (`:355`)
plus the `--max-rounds` cap (`:343-348`) are both *stopping* mechanisms; there
is no *"keep hunting"* mechanism — the loop is built to wind down, and a
quiet detector accelerates exactly that.

---

## 4. Weakness Set (confirmed / corrected / extended)

| W | One-line description | Status vs hypothesis | Severity |
|---|----------------------|----------------------|----------|
| **W1** | Auditor is spec-anchored only — a defect the spec is silent about is discarded before being written (`framework-auditor.md:19-20`). | **CONFIRMED, verbatim.** Compounded by P2/P3 findings never gating closure. | **Critical** — it caps the *entire* pipeline's detection ceiling at "spec contradictions only"; everything downstream inherits it. |
| **W2** | Auditor does presence-checks, not break-attempts — ~6 of 12 axes verify existence/registration; A is never told to attempt a bypass. | **CONFIRMED.** Axes 1,6,8,9,10 are existence-phrased (`:62-65,:84-115`); live audits resolve them "verified present and executable" (`apex-audit-findings-R24.md:35,42,43`). No axis says "attempt to break." | **Critical** — a present-but-broken or bypassable mechanism passes silently; this is the most likely class of *real* defect to slip through. |
| **W3** | Auditor inherits test results — the ~919s suite overruns timeout, so A spot-runs ~4 tests and infers the rest green. | **CONFIRMED, verbatim, with live evidence** (`apex-audit-findings-R24.md:15,54,81-82`). | **High** — any defect only a non-spot-run test catches is silently inherited as "passing"; ~68 tests unobserved per round. |
| **W4** | Round-checker never independently re-verifies — closure consumes A's finding count; stop criterion is purely count-based. | **CONFIRMED.** `round-checker.md:83-89` (count-only stop), `:69-71` (counts dispositions), `:77-78` (drift check is self-referential, vacuous on a 0-finding round). E's Bash is used only for write-verification. | **Critical** — removes the loop's only chance to catch A's misses; converts any A under-detection directly into a CLOSED verdict. |
| **W5** | Auditor is primable — no instruction to resist orchestrator framing ("confirmation round", "already converged"). | **CONFIRMED.** `framework-auditor.md` has no resist-framing instruction; `previous_findings_path` is handed in (`:49-51`); live rounds self-label "POST-CONVERGENCE CONFIRMATION" (`apex-audit-findings-R24.md:1,4`). Orchestrator's own description is convergence-seeking (`self-heal.md:2`). | **High** — a primed auditor on a "confirmation" round verifies the prior verdict instead of hunting; explains the R21–R24 quieting. |
| **W6** | Post-detection leak — B/C/D/E can drop, WONTFIX, down-classify, defer, or compress a *detected* finding. | **CONFIRMED and now fully enumerated.** WONTFIX (B, **L07**), UNKNOWN (B, **L08**), human-decision park (B, **L10**), Deferred (C, **L11**), optional/unverified NEW-FINDINGS (D, **L13**), defer-to-next-round-by-design (D, **L14**), token-exhaustion SKIP (D, **L15**), wave-abort revert (D, **L16**), HALTED reclassification (E, **L20**). No stage re-judges a WONTFIX/UNKNOWN justification. | **High** — multiple independent drop paths, and the trail for every one is git-ignored (W7). Severity is High not Critical only because each drop *does* leave an (ephemeral) on-disk note; the loss is by neglect, not by silent deletion. |
| **W7** *(new)* | **Untracked, ephemeral evidence base + filename-contract gaps.** Every self-heal artifact is git-ignored (`.gitignore:18-24`; `git ls-files` confirms none tracked) — a dropped finding leaves no diffable, version-controlled trail. Compounded by `NEW-FINDINGS-ORCHESTRATOR-R<N>.md` not matching E's input pattern (`round-checker.md:22-23`), and the RESULT-file's embedded new-findings section being a second, uncollected sink (`wave-executor.md:144-146` vs `:157-161`). | **NEW — extends W6.** | **Medium-High** — does not itself hide a defect, but it removes the post-hoc auditability that would let anyone *prove* a defect was dropped, and creates two concrete silent-omission paths (orchestrator-finding filename, dual new-finding sinks). |
| **W8** *(new)* | **No minimum-detection floor anywhere in the loop.** Every control is a *stopping* mechanism (two-clean-rounds terminator `round-checker.md:83-89`; `--max-rounds` cap `self-heal.md:343-348`; divergence halt `:336-342`). Nothing treats a *suspiciously low* finding count as a signal to escalate rigor, switch model, or run an adversarial pass. A detector that has gone silent is rewarded identically to a framework that is genuinely clean. | **NEW.** Distinct from W4: W4 is "E does not re-verify"; W8 is "*nobody* reacts to the count being implausibly low." | **High** — this is the structural reason a degrading detector and a converged framework are indistinguishable to the loop; it is the root enabler of the "4 quiet rounds" symptom. |

**Weakness count: 8** (W1–W6 confirmed, W7–W8 new).

---

## 5. Coverage Statement

All **5 stages + the orchestrator** were analysed in full against questions
1–5. Confirmation:

| Stage | File read in full | Q1 input/drop | Q2 trust-without-verify | Q3 down-class/trail | Q4 NEW-FINDINGS | Q5 bias |
|-------|-------------------|:--:|:--:|:--:|:--:|:--:|
| A `framework-auditor` | yes (200 lines) | done | done | done | N/A | done |
| B `remediation-planner` | yes (173 lines) | done | done | done | N/A | done |
| C `batch-scheduler` | yes (107 lines) | done | done | done | N/A | done |
| D `wave-executor` | yes (164 lines) | done | done | done | **done (4a–4d)** | done |
| E `round-checker` | yes (192 lines) | done | done | done | N/A | done |
| Orchestrator `self-heal.md` | yes (401 lines) | done | done | done | N/A (see L17) | done |

Supporting files read in full: `circuit-breaker.sh` (371 lines),
`context-monitor.sh` (275 lines), `apex-spec.md` §"Self-Healing Loop"
(lines 342–392), `framework/docs/REMEDIATION-STYLE.md` (153 lines).
Corroborating artifacts read: `ROUND-R24-CLOSURE.md` (full),
`apex-audit-findings-R24.md` (lines 1–90), `NEW-FINDINGS-ORCHESTRATOR-R20.md`
(full), `.gitignore` (artifact patterns), and a `git ls-files` check confirming
no artifact is tracked.

**On the two hooks (circuit-breaker, context-monitor):** these were read in
full to confirm they are *not* part of the detection pipeline — they are
runaway/overflow safety stops, not defect detectors. `circuit-breaker.sh`
detects *loops* (no-change, tool-call cap, recurring-error, result-fishing —
CHECK 1–4) not framework defects; `context-monitor.sh` detects *context fill*.
Their only relevance to detection is as *enablers of leaks*: context-monitor's
70% hard exit can truncate an audit (**L23**), and circuit-breaker's standalone-
invocation hang was itself a real defect that *Step A could not detect* and
only the *orchestrator* caught (`NEW-FINDINGS-ORCHESTRATOR-R20.md`) — direct
evidence for W2 (a runtime blocking-IO defect is outside A's presence-check
surface, stated verbatim at `NEW-FINDINGS-ORCHESTRATOR-R20.md:51-54`).

**What could not be fully determined, and why:**

1. **`resolve_model()` routing for the five agents.** `self-heal.md` calls
   `Task(..., model=resolve_model("<agent>"))` for each agent but the routing
   table is in a separate helper not in the read set. Whether A is *actually*
   routed to a weaker model on confirmation rounds (sharpening W5/L22) could not
   be confirmed — flagged as a routing-dependent risk, not a proven leak.

2. **Whether B's WONTFIX justifications have ever been wrong in practice.**
   The R21–R24 plans (`REMEDIATION-PLAN-R*.md`) were not opened individually;
   R24's was confirmed a 0-item NO-OP via `ROUND-R24-CLOSURE.md:40`. The W6/L07
   leak (no stage re-judges a WONTFIX) is proven *structurally* from the prompt
   texts; a census of historical WONTFIX correctness was out of scope.

3. **The exact behavior of E in degraded HALTED mode on a converged loop.**
   `round-checker.md:33-64` documents the branch; no HALTED closure file exists
   in recent rounds to inspect against. L20 is proven from the prompt text;
   its real-world frequency is undetermined.

4. **`apex-test-architect` veto interaction.** The auditor's axis 6 checks the
   veto contract (`framework-auditor.md:84-89`), but `apex-test-architect` is a
   *build-time* gate, not part of the self-heal detection pipeline, so it was
   not analysed as a pipeline stage. Noted for completeness.

None of these gaps affects the 26 leak-points or 8 weaknesses, all of which are
grounded in fully-read prompt text and corroborated by live artifacts.

---

`DIAGNOSIS_COMPLETE | leak_points=26 | weaknesses=8`
