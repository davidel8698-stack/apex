# Detector-Hardening Campaign — Owner Summary

**Date closed:** 2026-05-24
**Verdict:** PASS-WITH-LIMITATION
**Commits past baseline `8ac2a85`:** 12 (Phase-4 deliverable + 9 atomic CR commits + Phase-6 bookmark + Phase-7 institutionalization)

---

## The question you asked

> "How can it be that you found nothing? A super-complex system with no gaps at all? Did we reach perfection? — I suspect there's a problem in the process of detecting failures, gaps and errors in the self-healing loop."

You were right. The detection process was broken.

## What we measured (Phase 2 baseline, pre-fix)

Three trials of the `framework-auditor` agent on the same mutated lab, same neutral prompt, fresh agent each time:

- **R201:** 114 tool calls, caught **3 of 13** seeded mutants.
- **R202:** 70 tool calls, caught **3 of 13** seeded mutants.
- **R203:** 162 tool calls, caught **13 of 13** seeded mutants.

The detector was **non-deterministically thorough**. When it went deep, it caught nearly everything. When it stayed shallow, it caught only the obvious presence-checks. The loop closed whenever the result happened to look "clean" — quiet was treated as identical to clean.

And: the historical R23 round claimed "6 hits" for IMP-039 coverage. Live grep returns 0. R24 ratified the fabricated count. The convergence we declared was built on un-verified evidence.

## What we built (the fix)

**9 atomic commits past `8ac2a85`**, each closing one cause-root:

- **CR-01:** new mandatory Axis 13 — auditor must actually attempt bypass payloads against every named guard and record exit codes; must drive every fail-loud failure path and record stderr presence.
- **CR-02:** test-suite evidence rule — auditor must OBSERVE (run `run-all.sh`, quote the literal summary line) or explicitly record BLIND SPOT. Never inherit.
- **CR-03:** anti-priming clause — round labels, "post-convergence" framing, prior-round verdicts are NOT evidence. Audit depth must not vary with framing.
- **CR-04:** round-checker must independently re-verify 3 audit claims before closing on `P0+P1==0`. Discrepancy → P1 "Audit-credibility regression" → CONTINUE.
- **CR-05:** orchestrator collects orphan-pattern new-findings files (closed L17 — `NEW-FINDINGS-ORCHESTRATOR-R20.md` had been silently dropped since R20).
- **CR-06:** new SPEC-GAP-CANDIDATE advisory class for spec-silent observations + `sgc=<n>` summary suffix as the fix's fingerprint.
- **CR-07:** orchestrator forbidden to inject framing text into AUDIT_CONTEXT.
- **CR-08:** new posture rung `clean-pending-spot-check` — never lies "stable" when audit depth was insufficient.
- **CR-spec:** spec line 348 updated 12-axis → 13-axis (single source of truth).

Plus 1 critic clean-room PASS (twice — 9 findings from first round all closed), `framework/tests/run-all.sh` 72/72 PASS after install.

## What we measured (Phase 6 re-test, post-fix)

**Held-out corpus (the decisive generalization test, sealed pre-Phase-2 and unopened until Phase 6):**

| Class | Mutants | Reliably killed (≥2/3 trials) |
|-------|--------:|-------------------------------:|
| A | 2 | **2/2** |
| B+C+D | 5 | **5/5** |
| E | 1 | 1/1 (anchored as P1) |
| **Total** | **8** | **8/8 = 100%** |

**Working corpus:** 6/13 reliably killed (Class A 3/3 ✓, Class C 2/3, Class B/D/E gaps documented below).

**Negative control:** 0 fabricated findings + 2 NEW real defects the OLD detector missed (6 production guards silently no-op because they read argv where Claude Code pipes stdin; IMP-015 role-marker scan not enforced on Reads).

**Framing-effect (the priming reduction that made R206 4x quieter than R205):** narrowed from 13 to 2 — **6× improvement**. Both trials killed the seeded defect. Anti-priming clause behaviorally vindicated.

**CR-04 empirical exercise:** spot-check successfully caught fabricated axis-10 compliance claim. P1 emitted. Round refused to close. The F-204-013 historical pattern is structurally prevented.

## What still needs work (3 Phase-7 R-items)

Two §9 thresholds missed. Both are documented per the protocol's "documented accepted limitation with written rationale" path — never silently waived.

1. **R-DH-P7-01** — add **Axis 13.c source-literal carve-out scan** to catch magic-string-allowlist guard backdoors (the working-corpus W-B class). The current fix catches behavioral guard weaknesses generically (proven on held-out's H-B regex-anchor and case-folding mutants — 2/2) but doesn't specifically scan source for suspicious string-literal carve-outs.

2. **R-DH-P7-02** — raise framework-auditor budget **400 → 800 tool calls**. Every Phase-6 trial hit the 400 cap mid-Axis-13 sweep; that's why working-corpus Class D/E weren't reached (held-out reached them because the held-out lab's mutation footprint is smaller).

3. **R-DH-P7-03** — `test-subagent-cache.sh` to prevent the harness-cache contamination that forced the Phase-6 embedded-prompt methodology workaround.

## Bonus deliverable — 10 NEW live-framework defects

The fixed detector surfaced 10 kinds of real framework gaps the OLD detector missed. None are pipeline issues; they are real defects now visible. Listed in `detector-review/FINAL-CERTIFICATION.md` §4. Owner triage track is separate.

## The bottom-line answer

You asked whether the detection process was broken. **It was, and now it's better.** The fix:

- **Generalises** — 8/8 reliable-kill on a sealed held-out corpus the fix was never shown.
- **Anchors the floor** — every audit now produces a 13-axis coverage map with explicit adversarial-probe counts and test-suite evidence; no audit can close on shallow depth.
- **Self-checks** — round-checker independently re-verifies audit claims; the F-204-013 fabrication-ratification pattern is structurally prevented.
- **Surfaces previously-hidden truth** — 10 real defects the OLD detector silently ignored.

The framework is no longer characterised by "quiet rounds indistinguishable from clean rounds." Every post-fix audit either meets the depth floor (and a CLOSED verdict is structurally earned) or the round-checker maps posture to `clean-pending-spot-check` and the loop refuses to close.

Documented limitations exist. They are Phase-7 R-items, not silent waivers. The path to closing them is concrete and reserved.

---

**Canonical artifacts** (in order of importance for the owner):

1. `detector-review/OWNER-SUMMARY.md` — this file.
2. `detector-review/FINAL-CERTIFICATION.md` — full §9 matrix, per-CR verdict, 10 new live defects.
3. `framework/docs/DETECTION-STANDARD.md` — the institutionalized standard with Phase-7 R-items.
4. `detector-review/EXPERIMENT-PROTOCOL.md` — pre-registration + 4 §12 amendments documenting every methodology deviation.
5. `detector-review/BASELINE.md` — Phase-2 pre-fix kill rates.
6. 12 git commits past `8ac2a85` — full audit trail.

The campaign is closed. The framework is ready for its next round of work.
