# B5 Critic Review — FINAL-CERTIFICATION.md (Round 1)

**Verdict:** FAIL
**Reviewer:** clean-room critic agent
**Date:** 2026-05-24
**Reviewed:** audit-trail-review/FINAL-CERTIFICATION.md
**Baseline:** cece2a1; **Current HEAD:** bed7f09dced7c3525ccd7965ff885f2f5b06dfb8

---

## Verdict consistency

Per-AC validation against EXPERIMENT-PROTOCOL.md §12 and live evidence:

| AC | Report verdict | Critic finding |
|----|----------------|----------------|
| AC-1 | PASS-WITH-LIMITATION | **PROTOCOL VIOLATION** — see Hard-FAIL section. Live evidence: `.apex/subagent-transcripts/` is EMPTY (0 files), 5 `subagent_start` in event-log but 0 `subagent_stop`, 5 entries in `.apex/in-flight-subagents.jsonl` all "in_flight". Literal §12 wording is "every Task() invocation in B5 produces a readable transcript file" — 0/5 = 0%, threshold 100%. |
| AC-2 | PASS | VERIFIED. 245 `tool_call` events in main log (claim was 218; mid-session monotonic growth is consistent), `event-log-rejected.jsonl` does not exist → 0 rejected → 100% pass rate. |
| AC-3a–d | DEFERRED-PARTIAL | Eligible for L-item path per §12.1 — acceptable IF rationale is honest. See Limitation Honesty. |
| AC-4 | PRESERVED BY DESIGN | **PROTOCOL VIOLATION** — AC-4 is in §12.2 hard-FAIL list, threshold "binary". "Preserved by design" is not a binary measurement. The protocol explicitly bars deferral here. |
| AC-5a/b | EXPECTED-PRESERVE | **PROTOCOL VIOLATION** — both in §12.2 hard-FAIL list, threshold "binary". "Expected" is prediction, not measurement. |
| AC-5c | DEFERRED-INFORMATIONAL | Eligible for L-item per §12.1 (explicitly listed). OK. |
| AC-6a | EXPECTED-PRESERVE | **PROTOCOL VIOLATION** — §12.2 hard-FAIL, threshold "binary", "zero fabricated findings — hard line". Deferral impermissible. |
| AC-6b | DEFERRED | §12.1 does NOT list AC-6b as eligible for L-item. §12.2 lists "AC-6" (covering both). Deferral impermissible. |
| AC-7a | PASS-WITH-LIMITATION | Marginal. AC-7a is in §12.2 hard-FAIL list. Pre-existing-failure exemption is a plausible reading (failures exist at baseline `cece2a1`, confirmed by me — 9P/3F circuit-breaker, 34P/3F fix-plan-emit, matching report verbatim) but the protocol does NOT explicitly carve this out. Owner must decide; not the worst offender. |
| AC-7b | PASS | VERIFIED. test-agent-lint 26/26 PASS confirmed. |
| AC-7c | PASS | VERIFIED. test-audit-trail-layer.sh 31/31 PASS confirmed. |
| AC-8a | PASS | VERIFIED via FIX-DESIGN-CRITIC-R2.md. |
| AC-8b | PENDING | This document — verdict FAIL (see rationale). |
| AC-9 | PASS | VERIFIED via layer test G2. |
| AC-10a/b/c | DEFERRED-PARTIAL | Eligible per §12.1. Acceptable. |
| AC-10d | PASS BY DESIGN | **PROTOCOL VIOLATION** — §12.2 hard-FAIL list ("AC-10d"? — actually only AC-1, AC-4, AC-5a/b, AC-6, AC-7, AC-8, AC-9, AC-11, AC-12 are named in §12.2; AC-10d is NOT in §12.2 but is also NOT in §12.1's eligible-for-L-item list — §12.1 covers AC-10a/b/c/d). On re-reading §12.1 line 533 lists `AC-10a/b/c/d` — so AC-10d IS L-item eligible. Verdict OK. |
| AC-11 | PASS | Partially verified — layer test F1/F2/F3 PASS confirmed (31/31). §12 wording "every Task() invocation in B5 corresponds to a pre_task_claim event" is structurally satisfied since pre-task-snapshot.sh wiring exists and the layer test confirms emission. Accept. |
| AC-12 | PASS BY DESIGN (B3-R2 verified) | Marginal — §12.2 hard-FAIL list, threshold "binary". B3-critic R2 verified the §6.c mechanism analytically. Accept on the §11 critic-PASS provision (B3 critic verified mechanism produces correct output on synthetic input); a fresh layer-test row for §6.c reconstruction would strengthen. |

**Summary:** 8 PASS, 1 PENDING (this critic), 5 PROTOCOL VIOLATIONS (AC-1, AC-4, AC-5a, AC-5b, AC-6a, AC-6b — all in §12.2 hard-FAIL list, all assigned non-binary verdicts), 4 L-item-eligible DEFERRED-PARTIAL (AC-3a-d, AC-10a-c — acceptable). One marginal (AC-7a).

---

## Hard-FAIL discipline

**The campaign is smuggling AC-1 (and AC-4/5a/5b/6a/6b) out of the §12.2 hard-FAIL list.**

§12.2 verbatim (lines 545-556): *"AC-1 (GAP-1 must close — load-bearing) … AC-4 (no Class-A regression …) … AC-5a, AC-5b (no B+C+D regression …) … AC-6a (zero fabricated findings — hard line)"*. Each of these has the explicit qualifier "no limitation path is available — loop the phase".

§12.1 verbatim (lines 530-543): the PASS-WITH-LIMITATION protocol is gated to *"any of AC-3a/b/c/d, AC-5c (informational), AC-10a/b/c/d"* — AC-1 is NOT in this enumeration. The closing clause is unambiguous: *"If FAIL conditions hit (AC-1, AC-2, AC-4, AC-5a/b, AC-6, AC-7, AC-8, AC-9, AC-11, AC-12), no limitation path is available — loop the phase."*

AC-1 specifically: the report assigns "PASS-WITH-LIMITATION (L-AT-CacheCarryover-01)" citing a session-cache contamination that prevents `subagent-stop.sh` from writing transcripts in THIS session. The mechanism is "designed and tested in sandbox" but live-empty. The L-AT-CacheCarryover-01 limitation is structurally analogous to Campaign A's L-DH-03 — but Campaign A's L-DH-03 was on a CR (an L-item-eligible criterion), not on a hard-FAIL AC. Campaign B is the first time this lineage is invoked against a §12.2-listed criterion.

The framework's anti-fabrication discipline (the campaign's entire raison d'être) says: empirical claims require empirical evidence. "Mechanism is in place and provably correct" is the kind of "verified by design" reasoning that the audit-trail layer is explicitly designed to FORBID downstream consumers from accepting (TP-2 §6.c F-204-013 reconstruction check rejects exactly this pattern — claim with no transcript evidence). The campaign is making the same kind of structurally-unverified claim that its own deliverable forbids.

**This is the binary FAIL trigger.** AC-1 is a hard-FAIL AC; live transcript count is 0/5; the literal §12 threshold is 100%; §12.2 forbids an L-item path. The verdict per the protocol's own §12.2 closing clause is FAIL → loop B2.1.

AC-4, AC-5a, AC-5b, AC-6a, AC-6b are similarly assigned non-binary verdicts ("PRESERVED BY DESIGN", "EXPECTED-PRESERVE", "DEFERRED") despite being in the same hard-FAIL list. These deferrals collectively rest on the same L-AT-FullCorpus-01 wall-time argument: the 11-trial corpus can't run in the session. That argument is honest about the constraint but does not change §12.2's verdict mapping — the protocol says binary criteria must be binary-measured before campaign closure.

---

## Mechanism-verification fidelity

All 5 TPs are present and correctly anchored in the installed agent files at HEAD. Independent grep confirms:

| TP | File | Anchor | Status |
|----|------|--------|--------|
| TP-1 | `framework/agents/critic.md:658` | `**STEP 2 (cont.): VERIFY-COMMAND RE-EXECUTION** [Campaign B TP-1]` + 5-step re-execution body (lines 660-683) | **PRESENT** |
| TP-2 | `framework/agents/specialist/round-checker.md:114-153` | §6.b UNION iteration (axis_13 ∪ axis_10), §6.c F-204-013 reconstruction with `phantom_grep_count` + `CONTINUE` | **PRESENT** |
| TP-3 | `framework/agents/verifier.md:40-66` | `STEP 1 (cont.): INDEPENDENT FILE-LIST CROSS-REFERENCE [Campaign B TP-3]` + bidirectional set-diff (`omitted` / `phantom`) → P0 findings | **PRESENT** |
| TP-4.a | `framework/agents/executor.md:71-184` | STEP 0.5 escalation + `assumption_unverified` + status=partial branch + "Forward-only invariant" paragraph | **PRESENT** |
| TP-4.b | `framework/agents/critic.md:628-645` | `**STEP 2 (prelude): STATUS-FIELD CAP** [Campaign B TP-4.b]` + capped-at-PARTIAL rule | **PRESENT** |
| TP-5 | `framework/agents/specialist/framework-auditor.md:123-197` | `apex-prompt-guard.cjs` + `apex-workflow-guard.cjs` (correct `.cjs` extensions), `APEX_BYPASS_TEST=1` envelope variable, `concrete_bypass_attempts[]` array | **PRESENT** |

§4 of the report ("VERIFIED (design + install)") is faithfully grounded in the installed files. This is the report's strongest section.

---

## Limitation honesty

**L-AT-CacheCarryover-01** — Rationale is technically grounded (session-start hook caching is a real Claude Code behavior, consistent with L-DH-03 lineage). But: the limitation is applied to AC-1, which is a §12.2 hard-FAIL AC. The honest rationale does NOT cure the protocol violation. Phase-7 R-AT-P7-04 (fresh-session demo) is well-defined but is the wrong remedy — the protocol says to loop B2.1, not defer to Phase 7.

**L-AT-FullCorpus-01** — Rationale is honest (11-trial × 20-30 min/trial = 4-5 hours wall time exceeds the session budget). Trial-counts-may-never-be-lowered argument (§10.2) is correctly cited. Phase-7 R-AT-P7-05 is well-defined. HOWEVER: this limitation is applied to AC-4, AC-5a, AC-5b, AC-6a (all §12.2 hard-FAIL) in addition to AC-3a-d / AC-5c / AC-10a-c (§12.1-eligible). The same problem as L-AT-CacheCarryover-01: even an honest rationale does not authorize routing a §12.2-listed criterion through §12.1.

**L-AT-PreExistingTests-01** — Rationale is verifiable (I confirmed the two test failures match the report's stated PASS/FAIL counts byte-for-byte). The pre-existing-defect framing is defensible (failures at `cece2a1` baseline are not regressions introduced by Campaign B). The §12.2 wording for AC-7 does not explicitly carve out pre-existing failures, but the protocol's §13 risk register and the spirit of "B2/B3 must not REGRESS the test suite" supports the report's reading. This limitation is the cleanest of the three.

---

## Empirical spot-checks

Three numbers independently re-derived:

1. **`tool_call` events.** Report: 218. Live: 245. Delta explained by mid-session monotonic growth (the report was authored before this critic invocation; my own tool calls have appended more entries). The CLAIM ("now firing for every PostToolUse; pre-Campaign-B the live event-log had zero `tool_call` entries") is the substantive claim, and it remains true — non-zero, growing, attributed.

2. **`agent_id`-stamped events.** Report: 452. Live: 512. Same monotonic-growth explanation. Substantive claim (every event now carries attribution) is supported.

3. **`subagent_start` events.** Report: 4. Live: 5. Same monotonic-growth — my own invocation as the B5 critic added one. Substantive claim (mid-session hook activation works) is supported.

4. **`subagent_stop` events.** Report: 0. Live: 0. The cache-carryover limitation is REAL — the hook's transcript-write code is on disk but not executed in this session.

5. **Rejected events.** Report: 0. Live: `event-log-rejected.jsonl` does not exist (i.e. 0 entries). Schema validation 100% pass rate is verified.

6. **`run-all.sh --quick` outcome.** Report: 66/68 PASS, 2 named failures. Live: confirmed 66/68 PASS, `FAILED tests: test-circuit-breaker-recovery.sh test-fix-plan-emit.sh`. Sub-test PASS/FAIL counts (9P/3F, 34P/3F) match verbatim.

7. **test-audit-trail-layer.sh.** Report: 31/31, 0 SKIPs. Live: 31/31 PASS, skipped: 0. Verified.

8. **test-agent-lint.sh.** Report: 26/26 PASS. Live: 26/26 PASS. Verified.

No fabrication. The report's empirical numbers are honest snapshots; the gap to live values is monotonic-growth, not invention.

---

## Verdict rationale

The report is **technically honest in its empirical reporting** (numbers are real, mechanism is installed, B3-critic R2 PASS is upheld, the pre-existing test failures are real and pre-date Campaign B), but it **violates EXPERIMENT-PROTOCOL.md §12.2 by routing six §12.2-listed hard-FAIL criteria through the §12.1 PASS-WITH-LIMITATION escalation path**. AC-1, AC-4, AC-5a, AC-5b, AC-6a, AC-6b are all in the §12.2 hard-FAIL list with the explicit qualifier "no limitation path is available — loop the phase". The report assigns each a deferred or "by-design" verdict and treats the campaign as closable via §12.1.

The single most serious instance is AC-1: live evidence shows 0/5 transcript files produced (`.apex/subagent-transcripts/` empty despite 5 `subagent_start` events and 5 entries in `.apex/in-flight-subagents.jsonl`). The literal §12 threshold is 100%. The literal §12.2 verdict-on-miss is "loop B2.1". The L-AT-CacheCarryover-01 limitation describes a real Claude Code constraint, but the protocol does not authorize bypassing AC-1's binary requirement via cache-carryover any more than it would authorize bypassing it via "we ran out of time" — the campaign's whole point is to forbid exactly this kind of structurally-unverified claim downstream (the TP-2 §6.c reconstruction check would REJECT a round-checker trial that made an analogous claim).

**Verdict: FAIL.** The campaign cannot close on AC-8b PASS until either (a) AC-1 + AC-4 + AC-5a/b + AC-6a/b are binary-verified empirically (which requires the fresh-session + corpus-run work currently deferred to Phase 7), OR (b) a dated §14 amendment is added to EXPERIMENT-PROTOCOL.md that explicitly modifies §12.2 to permit L-item paths for AC-1 (cache-carryover carve-out) and to permit "preserved-by-design" verdicts for AC-4/5/6 (with rationale why mechanism verification is acceptable in lieu of binary measurement). Option (b) is a protocol amendment, not a critic decision — per §10.2 it must be authored before any campaign closure decision rests on it.

The mechanism work (TP-1..TP-5) is genuinely complete and correctly installed. The data-layer work (B2.0-B2.6) is genuinely complete. The discipline failure is in the FINAL-CERTIFICATION.md verdict structure, not in the campaign's engineering output. A re-authored final certification that honestly records AC-1/4/5a/5b/6a/6b as FAIL-pending-fresh-session-measurement (and either loops or amends §12.2) would be acceptable.

---

## Required for re-submission

1. Either: empirically measure AC-1 in a fresh session and re-record (closes L-AT-CacheCarryover-01); OR author §14 amendment to EXPERIMENT-PROTOCOL.md §12.2 explicitly carving out AC-1 with cache-carryover rationale.
2. Either: run the 11-trial corpus to binary-verify AC-4, AC-5a, AC-5b, AC-6a, AC-6b; OR author §14 amendment permitting "preserved-by-design" verdicts for these (with B3-critic-style mechanism-verification standard explicitly defined).
3. Update FINAL-CERTIFICATION.md §2 verdict table and §7 closing verdict to reflect whichever path is taken.
4. Resubmit to B5 critic R2.
