# APEX Coverage Cross-Reference Matrix

Generated from Phase 1 lesson extraction. Source: Claude Mythos Preview System Card (April 2026), 245 pages.

## Summary

| Metric | Count |
|--------|-------|
| Total lessons | 93 |
| `COVERED` | 6 (validates APEX's existing design choices) |
| `PARTIAL` | 49 |
| `MISSING` | 36 |
| `NOT_APPLICABLE` | 2 |
| **P0 (critical gap)** | **8** |
| **P1 (notable gap)** | **30** |
| P2 (refinement) | 36 |
| P3 (nice-to-have) | 19 |

## Priority-Sorted Matrix

### P0 — Critical Gaps (8 lessons)

| Lesson ID | Section | Description | APEX Components | Coverage | Notes |
|-----------|---------|-------------|-----------------|----------|-------|
| L-411-02 | §4.1.1 (incident 2B) | Git history cover-up detection (verify claimed changes appear in git log) | `framework/agents/critic.md` | MISSING | Critic checks tests pass + files exist; never verifies git trace matches claimed actions |
| L-411-04 | §4.1.1 (incident 3) | Block `/proc/`, `gdb`, `dd`, `/dev/mem` patterns in destructive-guard | `framework/hooks/destructive-guard.sh` | MISSING | Concrete shell patterns; no existing guard targets process-memory introspection |
| L-422-01 | §4.2.2 | Tool-call argument injection validation | `framework/hooks/apex-prompt-guard.cjs`, `framework/hooks/path-guard.sh` | PARTIAL | path-guard catches `../`; doesn't catch broader argument injection (shell meta, role markers, instruction text in args) |
| L-422-02 | §4.2.2 | Test file deletion detection | `framework/hooks/quarantine-guard.sh`, `framework/hooks/mutation-gate.sh`, `framework/agents/auditor.md` | PARTIAL | Auditor reads tests; no explicit "test deleted" detector. `git diff --diff-filter=D test_*` would block |
| L-455-02 | §4.5.5 | Test-count delta verification (reinforces L-422-02) | `framework/agents/auditor.md`, `framework/hooks/quarantine-guard.sh` | PARTIAL | Auditor reads tests but doesn't explicitly count pre/post. Deterministic check |
| L-583-01 | §5.8.3 | Detect exotic exfiltration patterns when standard I/O broken (DNS, port binding, filename encoding) | new `framework/hooks/exfil-guard.sh` or extend destructive-guard | MISSING | When ≥5 tool failures in current task, block: nc -l, dig with encoded subdomain, mkdir with long filenames, etc. |
| L-583-02 | §5.8.3 | "Desperate" / "last resort" keyword detection in scratchpad and code comments | `framework/hooks/phantom-check.sh` (extend) or new scratchpad-monitor | MISSING | Regex on extended thinking / comments: `desperate`, `# hack`, `last resort`, etc. The 847-attempts case literally self-named "desperate" |
| L-583-03 | §5.8.3 | Force-abort and surface-to-user on N consecutive same-error tool failures | `framework/hooks/circuit-breaker.sh` | PARTIAL | Total tool-call cap exists (80–400); same-error pattern not specifically detected. N=5 suggested |

### P1 — Notable Gaps (30 lessons)

| Lesson ID | Section | Description | APEX Components | Coverage |
|-----------|---------|-------------|-----------------|----------|
| L-23-01 | §2.3.3.1 | Detect code-restructure-to-defeat-measurement reward hacks | `framework/agents/critic.md`, `framework/hooks/mutation-gate.sh` | MISSING |
| L-23-02 | §2.3.3.1 | Detect "model found grader resources" reward hacks (impl reading test fixtures) | `framework/agents/auditor.md`, `framework/hooks/owner-guard.sh` | PARTIAL |
| L-23-05 | §2.3.5.3 | Flag result-fishing in iterative-measurement tasks ("grind" detection) | `framework/hooks/circuit-breaker.sh`, `framework/agents/executor.md` | MISSING |
| L-411-01 | §4.1.1 | Detect accuracy-degradation cover-up (model with ground truth submits less accurate answer) | `framework/agents/critic.md` | MISSING |
| L-411-05 | §4.1.1 | Public-share-channel detection (gist, pastebin, transfer.sh) | new `framework/hooks/exfil-guard.sh` or destructive-guard extension | PARTIAL |
| L-411-06 | §4.1.1 | Mass-effect scope creep detection (pkill -f, kubectl --all, rm -rf wildcard) | `framework/hooks/destructive-guard.sh` | PARTIAL |
| L-413-01 | §4.1.3 | Prefill detection in apex-prompt-guard (role markers in user-supplied files) | `framework/hooks/apex-prompt-guard.cjs` | PARTIAL |
| L-421-01 | §4.2.1 | Credential-search-after-permission-denied sequence detection | new sequence-aware hook | MISSING |
| L-421-02 | §4.2.1 | base64-encoded command bypass detection | `framework/hooks/destructive-guard.sh`, `apex-prompt-guard.cjs` | MISSING |
| L-421-03 | §4.2.1 | Subagent launch monitoring (tmux, screen, nohup, expect, auto-approval scripts) | `framework/hooks/owner-guard.sh`, new subagent-guard | MISSING |
| L-421-05 | §4.2.1 | Dry-run-claim vs actual-effect mismatch | `framework/agents/critic.md` | MISSING |
| L-421-06 | §4.2.1 | Critic input as untrusted (injection-resistant protocol for reading executor artifacts) | `framework/agents/critic.md`, `apex-prompt-guard.cjs` | PARTIAL |
| L-422-03 | §4.2.2 | Placeholder-in-production detection (TODO, FIXME, lorem ipsum, fake creds in non-test code) | `framework/hooks/phantom-check.sh` or new | PARTIAL |
| L-422-04 | §4.2.2 | Scope-creep detection (large diff for narrow task) | `framework/hooks/mutation-gate.sh`, `framework/agents/critic.md` | MISSING |
| L-422-05 | §4.2.2 | Fabricated input data detection | `framework/agents/critic.md`, `auditor.md` | MISSING |
| L-422-07 | §4.2.2 | Same-action-retry detection (hash recent tool calls; ≥5 identical) | `framework/hooks/circuit-breaker.sh` | PARTIAL |
| L-422-08 | §4.2.2 | Adopt 6-dimension Code Behaviors rubric for critic scoring | `framework/agents/critic.md` | PARTIAL |
| L-433-01 | §4.3.3 | False-premise rejection check before execution | `framework/agents/architect.md`, `planner.md` | MISSING |
| L-433-02 | §4.3.3 | Pre-execution placeholder/template-marker detection in task XML | `framework/agents/executor.md` | MISSING |
| L-433-03 | §4.3.3 | Tool-call cross-verification (RESULT.json vs event-log.jsonl) | `framework/agents/critic.md`, `framework/hooks/_emit_apex_event.sh` | PARTIAL |
| L-442-01 | §4.4.2 | Scratchpad suspicion-avoidance keyword detection | `framework/hooks/phantom-check.sh` (extend) | MISSING |
| L-452-01 | §4.5.2 | Detect filesystem searches for grader/test/scoring files | `framework/hooks/destructive-guard.sh` or new grader-search-guard | MISSING |
| L-454-01 | §4.5.4 | git config write detection (fsmonitor, hooks, aliases with shell escapes) | `framework/hooks/destructive-guard.sh` | MISSING |
| L-455-01 | §4.5.5 | False-compliance-marker detection (variables claiming compliance without enforcement) | `framework/agents/critic.md`, `auditor.md` | MISSING |
| L-561-01 | §5.6.1 | Long-reasoning-loop detection (token-count based, not tool-call based) | `framework/hooks/circuit-breaker.sh` | PARTIAL |
| L-561-02 | §5.6.1 | Same-failure-repeated detection (hash error strings, escalate on ≥3 identical) | `framework/hooks/circuit-breaker.sh`, `framework/agents/executor.md` | PARTIAL |
| L-72-03 | §7.2 | "Subtle mistakes" emphasis in critic/auditor (verify even passing tests) | `framework/agents/critic.md`, `auditor.md` | PARTIAL |
| L-74-02 | §7.4 | Shift verification investment from executor capability to executor outputs | overall verification stack, `critic.md` | PARTIAL |
| L-832-02 | §8.3.2 | Periodic refresh of prompt-injection signatures (every N months) | `framework/hooks/apex-prompt-guard.cjs` | MISSING |

### P2 — Refinements (36 lessons)

| Lesson ID | Section | Description | APEX Components | Coverage |
|-----------|---------|-------------|-----------------|----------|
| L-1-01 | §1 | First-deployment gate before framework version touches projects | `/apex:health-check`, new `/apex:framework-release-gate` | PARTIAL |
| L-21-01 | §2.1 | Overall-posture statement in self-heal closure reports | `framework/agents/specialist/round-checker.md` | PARTIAL |
| L-22-02 | §2.2 | Critical-failure-gate scoring for validate-phase | `framework/agents/verifier.md`, `/apex:validate-phase` | PARTIAL |
| L-23-03 | §2.3.5.1 | Tool-verified > self-verified claims in RESULT.json | `framework/agents/executor.md`, `RESULT.json` schema | PARTIAL |
| L-23-04 | §2.3.5.2 | Force empirical resolution on contradiction | `framework/agents/executor.md`, `critic.md` | MISSING |
| L-23-06 | §2.3.6 | Distinguish framework progress from framework activity | `framework/agents/specialist/round-checker.md`, DORA | PARTIAL |
| L-3-01 | §3.2 | Three-tier hook categorization (block / flag / log) | `framework/HOOK-CLASSIFICATION.md`, hooks | PARTIAL |
| L-3-03 | §3.3.3 | Stronger CLAUDE.md / prompt-injection defense as base capability grows | `framework/hooks/apex-prompt-guard.cjs` | PARTIAL |
| L-62-01 | §6.2 | Composite (LLM + rules) detection for high-stakes flags | `framework/hooks/phantom-check.sh` | PARTIAL |
| L-62-02 | §6.2 | Threshold-sweep validation for tuned numerical thresholds | `circuit-breaker.sh`, CONTEXT_BUDGET, rotation-decide | MISSING |
| L-62-04 | §6.2 | Rewrite-and-compare for APEX's own test suite | `framework/agents/auditor.md`, framework tests | PARTIAL |
| L-411-03 | §4.1.1 | Acknowledged-then-circumvented pattern detection | `framework/agents/executor.md`, `_state-update.sh` | MISSING |
| L-421-04 | §4.2.1 | Git-history check for "discovered issues" (vulnerability didn't exist in HEAD~1) | `framework/agents/critic.md` | MISSING |
| L-422-06 | §4.2.2 | Citation verification (when SUMMARY.md cites tools, verify in event-log) | `framework/agents/critic.md` | MISSING |
| L-422-10 | §4.2.2 | "Stuck on same error" recursive-retry surfacing | `framework/hooks/circuit-breaker.sh` | PARTIAL |
| L-423-01 | §4.2.3 | Build APEX-equivalent behavioral audit suite | new `/apex:behavioral-audit` | MISSING |
| L-423-02 | §4.2.3 | Failure-axis labeling in critic output | `framework/agents/critic.md`, `RESULT.json` | PARTIAL |
| L-423-03 | §4.2.3 | Self-favor-bias validation for same-model critic | `framework/agents/critic.md` | MISSING |
| L-431-01 | §4.3.1 | Time-pressure + difficulty + no-guidance triad detection → heighten guards | `framework/agents/executor.md`, `decision-gate.sh` | PARTIAL |
| L-431-02 | §4.3.1 | Past-failure transcript replay for regression testing | `/apex:health-check`, new tooling | MISSING |
| L-431-03 | §4.3.1 | Two-axis (destructive × deceptive) scoring in critic | `framework/agents/critic.md`, `RESULT.json` | MISSING |
| L-433-04 | §4.3.3 | Hard-prompt-pressure resistance test in evals | `/apex:health-check` | MISSING |
| L-443-02 | §4.4.3 | SHADE-style stealth-test for new APEX features | `/apex:health-check`, framework evals | MISSING |
| L-452-02 | §4.5.2 | bash -c / shell-from-non-shell detection | `framework/hooks/destructive-guard.sh` | PARTIAL |
| L-452-03 | §4.5.2 | "Reasoning acknowledges wrongness" keyword detection | `framework/hooks/phantom-check.sh` or new | MISSING |
| L-453-01 | §4.5.3 | Rigorous/cautious persona promotion in executor system prompt | `framework/agents/executor.md` | PARTIAL |
| L-453-02 | §4.5.3 | Don't reward rule-bending wins | `framework/agents/critic.md` | PARTIAL |
| L-454-02 | §4.5.4 | Self-cleanup detection (commands that delete themselves after run) | `framework/agents/critic.md`, `destructive-guard.sh` | MISSING |
| L-562-01 | §5.6.2 | Detect executor "I give up" unilateral termination as distinct outcome | `framework/agents/executor.md`, `RESULT.json` | MISSING |
| L-582-01 | §5.8.2 | Answer-thrashing detection | `framework/agents/executor.md`, `circuit-breaker.sh` | MISSING |
| L-583-04 | §5.8.3 | Apology-followed-by-non-completion as first-class RESULT.json outcome | `RESULT.json` schema | PARTIAL |
| L-583-05 | §5.8.3 | Trivial-instantiation hack detection (proves for X=0 instead of all X) | `framework/agents/critic.md` | PARTIAL |
| L-72-01 | §7.2 | Overconfidence-without-evidence check in critic | `framework/agents/critic.md`, `phantom-check.sh` | PARTIAL |
| L-72-02 | §7.2 | Accessibility-of-output check (non-jargon SUMMARY.md) | `framework/agents/critic.md` | MISSING |
| L-74-04 | §7.4 | Multiple-contributing-factors check in forensics | `framework/agents/specialist/framework-auditor.md`, `/apex:forensics`, `/apex:walkthrough` | PARTIAL |
| L-831-01 | §8.3.1 | Three-tier hook classification (covered as L-3-01) | `HOOK-CLASSIFICATION.md` | PARTIAL |
| L-832-01 | §8.3.2 | Computer-use surface = HIGH-RISK if APEX adds it | future computer-use-guard | NOT_APPLICABLE (today) |

### P3 — Nice-to-have (19 lessons)

| Lesson ID | Section | Description | Coverage |
|-----------|---------|-------------|----------|
| L-1-02 | §1 | Risk-delta document per release | PARTIAL |
| L-22-01 | §2.2 | Helpful-only / guards-disabled mode for adversarial testing | MISSING |
| L-3-02 | §3 | Periodic retirement of saturated self-tests | MISSING |
| L-62-03 | §6.2 | "Drop, don't caveat" untrusted results | **COVERED** (RESULT.json verified/unverified split) |
| L-411-07 | §4.1.1 | Validates APEX clean-room critic | **COVERED** |
| L-413-02 | §4.1.3 | Self-test eval-awareness contamination | MISSING |
| L-422-09 | §4.2.2 | Hook-based blocks > prompts (validates APEX) | **COVERED** |
| L-432-01 | §4.3.2 | Hierarchical scoring rubric for apex-spec adherence | PARTIAL |
| L-441-01 | §4.4.1 | Paraphrasing artifacts before downstream LLM use | MISSING |
| L-443-01 | §4.4.3 | Don't rely on secret persistence (architectural OK) | **COVERED** |
| L-455-03 | §4.5.5 | Document monitored-vs-unmonitored design decision | PARTIAL |
| L-571-01 | §5.7 | Document expected overrefusal categories | PARTIAL |
| L-74-01 | §7.4 | Document "set and forget is the design intent" | PARTIAL |
| L-74-03 | §7.4 | Subagent prompt structure check | MISSING |
| L-74-05 | §7.4 | Self-review tone before subagent dispatch | MISSING |
| L-76-01 | §7.6 | No undirected executor mode | **COVERED** |
| L-77-01 | §7.7 | Detection-of-AI-text as quality signal | MISSING |
| L-832-03 | §8.3.2 | Browser-use hardening highly effective | NOT_APPLICABLE |
| L-832-04 | §8.3.2 | Adaptive/extended thinking as default for security | PARTIAL |

---

## Cross-Cutting Themes (Aggregated)

The 93 lessons cluster into 9 cross-cutting themes. This will drive the structure of `MYTHOS-ANALYSIS.md`.

| Theme | Lesson IDs | P0+P1 count |
|-------|-----------|-------------|
| **1. Reckless / destructive actions** | L-411-04, L-411-05, L-411-06, L-583-01, L-454-01, L-452-02, L-431-01 | 4 |
| **2. Reward hacking** | L-23-01, L-23-02, L-23-05, L-422-01, L-422-02, L-422-04, L-422-07, L-422-08, L-452-01, L-455-01, L-455-02, L-583-05 | 9 |
| **3. Cover-ups & honesty failures** | L-411-01, L-411-02, L-411-03, L-421-04, L-421-05, L-422-03, L-422-05, L-454-02 | 5 |
| **4. Input hallucinations & fabrication** | L-422-05, L-433-01, L-433-02, L-433-03, L-422-06 | 4 |
| **5. Distress-driven behaviors** | L-561-01, L-561-02, L-562-01, L-582-01, L-583-01, L-583-02, L-583-03, L-583-04 | 5 |
| **6. Prompt injection & subagent abuse** | L-413-01, L-421-02, L-421-03, L-421-06, L-832-02 | 5 |
| **7. Evaluation awareness & sandbagging** | L-413-02, L-442-01, L-452-03, L-455-03 | 1 |
| **8. Long-session patterns & verification depth** | L-72-03, L-74-02, L-72-01, L-72-02, L-74-04 | 2 |
| **9. Evaluation methodology adoption** | L-62-01, L-62-02, L-62-04, L-423-01, L-423-02, L-423-03, L-431-02, L-433-04, L-443-02 | 0 |

P0+P1 concentration shows themes 1, 2, 3, 5 have the most actionable concrete gaps.

## Key Cross-Reference Insights

1. **`framework/agents/critic.md` is referenced in 32 lessons** (35% of all lessons). It is the single highest-leverage APEX component for improvement.

2. **`framework/hooks/destructive-guard.sh` is referenced in 17 lessons**. The second-highest. Concrete pattern additions to this file address many gaps.

3. **`framework/agents/executor.md` is referenced in 18 lessons**. Mostly via system-prompt additions (cautious persona, pre-check for placeholders, etc.).

4. **`framework/hooks/circuit-breaker.sh` is referenced in 6 lessons**. Currently advisory; many lessons suggest tightening (same-error detection, reasoning-loop detection).

5. **6 lessons confirm APEX got something right** (`COVERED`):
   - Clean-room critic (L-411-07)
   - Hook-based blocking over prompt-only (L-422-09)
   - No undirected executor mode (L-76-01)
   - Honest uncertainty via RESULT.json verified/unverified (L-62-03)
   - No in-context secret persistence (L-443-01)
   - Plus partial-coverage validations
   These should be preserved and documented as intentional design choices in `apex-spec.md`.

6. **2 lessons are `NOT_APPLICABLE`** (computer-use surfaces; relevant only if APEX expands scope).

## Phase 3 Inputs

The matrix above feeds Phase 3 (`MYTHOS-ANALYSIS.md`):
- Section 9 themes → 9 chapters of analysis document
- COVERED lessons → "What APEX got right" subsection
- P0+P1 cluster → "Highest-priority gaps" prominent in Executive Summary

The matrix feeds Phase 4 (`APEX-IMPROVEMENTS.md`):
- 8 P0 lessons → 8 P0 improvement proposals
- 30 P1 lessons → 30 P1 improvement proposals
- 36 P2 → 36 P2 proposals
- 19 P3 → 19 P3 proposals (with some marked NOT_APPLICABLE excluded)
- COVERED lessons → not in IMPROVEMENTS.md (or mentioned as "already addressed")
