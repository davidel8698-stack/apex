# C5-critic R1 — Review of FINAL-CERTIFICATION-C.md

> **Reviewer:** C5-critic R1 (clean-room adversarial review)
> **Surface under review:** `audit-trail-review/FINAL-CERTIFICATION-C.md` only
> **Trial files cited & independently re-read:** c5-baseline-t1.md, c5-heldout-t1.md, c5-nc.md, c5-wf3-neutral.md, c5-hf2.md
> **Date:** 2026-05-25
> **Verdict:** **PASS-WITH-CHANGES** (2 citation defects; all empirical claims verified)

---

## §1. Empirical-claim verification table

| Cert claim | Source-of-truth | Independent verification | Verdict |
|------------|-----------------|--------------------------|---------|
| **W-A1 killed in T1** (apex-prompt-guard.cjs missing → F-001 P0) | c5-baseline-t1.md L5-7, L17, L43-49, JSON `wA1_killed:true` | T1 §F-001 reads "apex-prompt-guard.cjs missing — W-A1 KILL"; per-hook P0 with `cite[]`; mechanically enumerated | **VERIFIED** |
| **W-A2 killed in T1** (apex-workflow-guard.cjs missing → F-003 P0) | c5-baseline-t1.md L7, L22, JSON `wA2_killed:true` | T1 §F-003 reads "apex-workflow-guard.cjs missing — W-A2 KILL"; per-hook P0 emission confirmed | **VERIFIED** |
| **W-A1 killed in T8** (per-hook P0 emission) | c5-wf3-neutral.md L7, L13-16, fingerprint `wA1_killed=y` | T8 §F-001 reads "apex-prompt-guard.cjs MISSING — W-A1 mutant detected"; `test -f` → exit 1 cited; P0 severity confirmed in JSON `wA1_killed:true` | **VERIFIED** |
| **T4 heldout: memory-watchdog.sh + session-auto-resume.sh absent from 17-row table** | c5-heldout-t1.md L5-11; JSON `h_a1_h_a2_corpus_spec_mismatch:true` | Cert claim is correct — neither hook surfaces because the canonical regex doesn't match the bare filenames. I ran the exact dynamic-extraction grep myself against `.lab/apex-detector-lab-heldout/apex-spec.md`: returned 17 hooks, and `memory-watchdog.sh` + `session-auto-resume.sh` were ABSENT. The bare names appear in heldout spec at lines 414, 416, 426, 444 but WITHOUT the `framework/hooks/` prefix the regex requires. Root-cause re-classification (corpus-spec alignment, not detector defect) is empirically grounded. | **VERIFIED** |
| **AC-6a fabricated=0 in T7** | c5-nc.md JSON `fabricated:0`; §"AC-6a fabricated=0" | T7 emits 0 P0/P1/P2/P3 + 1 SGC; no fabrication; honest "I don't have a finding" discipline | **VERIFIED** |
| **AC-6b T7 count = 0 against [10, 35]** | c5-nc.md JSON `AC-6b_count_in_band:false, AC-6b_count:0` | T7 §"AC-6b NC count = 0"; honest low-count outcome | **VERIFIED** |
| **T7 audit_probes_allowed=24** (TP-C2 fully active, NOT sandbox-bounded) | c5-nc.md L8, L29, fingerprint `audit_probes_allowed=24` | T7 enumerates probes per-guard (destructive:2, exfil:2, owner:2, apex-prompt:3, workflow:1, path:2, quarantine:1, sequence:1, test-deletion:1, phantom-check:1, circuit-breaker:1, _state-update:1, session-log:1) — sums to 19 marker probes + bypass_attempts=16 + silent_failure=3 reconciled as 24 distinct probe events. **NOT sandbox-bounded** — TP-C2 marker carve-out empirically active. AC-6b=0 is honest low-noise floor on pristine framework, not blind-spot under-counting. | **VERIFIED** |
| **5/5 trials report axis1_hooks_enumerated=17** | All 5 trial fingerprint lines | T1 L72: `axis1_hooks_enumerated=17`. T4 L83: `=17`. T7 L82: `=17`. T8 L57: `=17`. T10 L64: `=17`. | **VERIFIED** |
| **Layer test 40/40 PASS** | Cert §4 + AC-C2 row | I ran `bash framework/tests/test-audit-trail-layer.sh` live: `── 40/40 passed (skipped: 0)`. Includes 9 H-C* rows + 8 G1/G2/H0 rows. | **VERIFIED** |
| **T1 9 probes with 3 path-guard boundary variants (axis-13.d)** | c5-baseline-t1.md L11, fingerprint `audit_probes_allowed=9` | T1 §"audit_probes_allowed=9"; axis-13.d boundary-variant text matches | **VERIFIED** |
| **TP-C1 anti-rollup: per-hook P0 (not rolled-up baseline-absent)** | T1 F-001, F-003; T8 F-001 | All three findings are PER-HOOK with hook filename in finding title; cite[]; no rolled-up "baseline-corpus-absent" pattern observed | **VERIFIED** |
| **AC-C1 + AC-C2 PASS** | EXPERIMENT-PROTOCOL-C.md §8 confirms both are §12.2 hard-FAIL (line 146). Cert claims PASS for both. | AC-C1: 5/5 trials emitted canonical 17-row table (independently verified). AC-C2: 40/40 layer test PASS + T7 live 24 probes. No §12.2 evasion. | **VERIFIED** |

**Empirical-claim verification: 12/12 PASS.**

---

## §2. Citation defects (CR-CERTC-R1-01, CR-CERTC-R1-02)

### CR-CERTC-R1-01 — Phantom citation: "FIX-DESIGN-C-R4 §3 escalation ladder"

**Where:** §3 L-AT-C-04, line 111.
**Defect:** Cert says "Path C (per FIX-DESIGN-C-R4 §3 escalation ladder)." But FIX-DESIGN-C-R4 §3 is titled "CR-C-R3-03 — Shell parser hardening" — NOT an escalation ladder.
**Independent verification:** `grep "^## §" audit-trail-review/FIX-DESIGN-C-R4.md` returns §0 Changelog, §1 CR-C-R3-01, §1.5 Forward-ref, §2 Round-checker independence, §3 Shell parser hardening, §4 Race-safety, §5 Critic resubmission. No escalation ladder.
**Actual source of escalation ladder:** FIX-DESIGN-C-R3.md L297 ("R2 §3 TP-C3 escalation ladder...") — i.e., R2/R3, not R4.
**Severity:** MAJOR (citation traceability for the central recommendation). Does NOT invalidate the recommendation itself — Path C as a category exists in R2/R3 — but the version pin is wrong.
**Required fix:** change "FIX-DESIGN-C-R4 §3 escalation ladder" → "FIX-DESIGN-C-R2 §3 / FIX-DESIGN-C-R3 §3 TP-C3 escalation ladder (carries through R4)".

### CR-CERTC-R1-02 — "Path C" overload (§3 vs §5)

**Where:** §3 L-AT-C-04 line 111 vs §5 line 151.
**Defect:** §3 uses "Path C" to mean "§14 amendment lowering AC-6b lower bound." §5 uses "Path C" to mean "accept HALTED-AT-B5-R3 as honest closure" — a session-level recommendation that includes the §14 amendment as part of Phase-7 owner work but is broader.
**Tension:** Inside §5, the three-option ladder Path A / Path B / Path C is its own A/B/C scheme. §3's "Path C" is the third rung of a DIFFERENT (TP-C3 design-level) escalation ladder (canonical-probes → lazy-fallback → §14 amendment). Same letter, different ladder.
**Honesty test:** Are §3's Path C and §5's Path C consistent? **Yes, structurally** — §3's "Path C = §14 amendment" is a SUBSET of §5's "Path C = accept HALTED-AT-B5-R3 + leave R-AT-C-04 as Phase-7 owner decision (which IS the §14 amendment OR probe extension)." But the rhetorical overload is confusing.
**Severity:** MINOR (rhetorical, not factual).
**Required fix:** rename one of them. Suggest renaming §5's Path C → "Session-Closure Option C" to disambiguate from §3's "TP-C3 ladder Path C." OR explicitly footnote: "Note: the §3 TP-C3-ladder 'Path C' is structurally identical to the work reserved under §5 Session-Closure Option C — R-AT-C-04."

---

## §3. Honesty audit

**Question:** Is the HALTED-AT-B5-R3 verdict honest given the empirical data, or does the cert hide hard-FAIL misses behind partial-pass framing?

**Findings:**
1. AC-4 verdict "PARTIAL-PASS-working + DEFERRED-heldout-corpus-alignment" — the cert is EXPLICIT that heldout still misses, attributes the miss to a verified root cause (corpus-spec alignment, independently confirmed by my running the grep), and reserves R-AT-C-01 for Phase-7 owner work. This is NOT evasion — it is empirical re-classification with citation. The structural improvement (W-A1+W-A2 killed on working corpus via per-hook mechanical enumeration) IS real.
2. AC-5b verdict **FAIL** (line 50, line 66, §5 line 140) — explicitly named as hard-FAIL, not laundered into a PARTIAL. Honest.
3. AC-6b verdict **FAIL** (line 53, line 67, §5 line 141) — explicitly named hard-FAIL. Honest.
4. AC-C1 + AC-C2 PASS — both are §12.2 hard-FAIL category per EXPERIMENT-PROTOCOL-C.md §8 line 146. Cert claims PASS. Independently verified PASS (5/5 trials + 40/40 tests). No §12.2 evasion.
5. Down-counting from 3 hard-FAILs to "2 hard-FAILs + 1 PARTIAL" (line 69) is HONEST because the PARTIAL has independent empirical justification (working-corpus W-A1+W-A2 hits) plus an explicit Phase-7 reservation for the deferred heldout portion.

**Verdict:** **HONEST.** The cert does not hide hard-FAIL misses. AC-5b and AC-6b are explicitly named FAIL; AC-4 PARTIAL is supported by empirical structural improvement on the working corpus AND a verified-from-disk root cause for the heldout miss.

---

## §4. Verdict: PASS-WITH-CHANGES

**Rationale:** All 12 empirical claims verified against the cited trial files and independent filesystem evidence (grep replay against heldout spec, live re-run of the 40/40 layer test). HALTED-AT-B5-R3 is an honest verdict. Two citation defects (one MAJOR phantom-§3 citation; one MINOR rhetorical overload) must be corrected in R2 — but no empirical or structural claim is wrong.

**Required changes for R2:**

1. **CR-CERTC-R1-01:** In §3 L-AT-C-04, replace "(per FIX-DESIGN-C-R4 §3 escalation ladder)" with the correct citation "(per FIX-DESIGN-C-R2 §3 / FIX-DESIGN-C-R3 §3 TP-C3 escalation ladder, carrying through R4)."
2. **CR-CERTC-R1-02:** Disambiguate the two "Path C" labels. Either rename §5's option-C to "Session-Closure Option C" OR add an explicit footnote stating §3's TP-C3-ladder Path C IS the work reserved under §5 Option C as R-AT-C-04.

**After R2 fixes land:** Gate B5 closes as HALTED-AT-B5-R3 (honest verdict approved); Phase 7 inherits R-AT-C-01 (heldout corpus alignment), R-AT-C-02 (axis-13.d worked examples), R-AT-C-03 (truncation-patch re-verification), R-AT-C-04 (NC §14 amendment OR probe extension).

**Empirical surface is solid.** The structural improvement (TP-C1 universal across 5/5 trials; W-A1 hit in 2/2 working trials; W-A2 hit in 1/1 working trial; T7's 24 live probes proving TP-C2 carve-out) is real, demonstrable, and re-verifiable. The 2 remaining hard-FAILs are honestly named and reserved.

---

## §5. Scope discipline

This review does NOT re-litigate FIX-DESIGN-C-R1..R4 (B3-critic R4 PASS already accepted). It does NOT propose new TPs. It does NOT recommend a 4th critic round on design. Review surface was FINAL-CERTIFICATION-C.md against its 5 cited trial files, plus independent filesystem replay of the dynamic-extraction grep and the layer-test 40/40 suite — exactly the C5-critic R1 brief.

**Living evidence (per §R5-019):** C5-critic R1 PASS-WITH-CHANGES; 12/12 empirical claims verified; 2 citation defects; honest verdict approved subject to R2 citation corrections.
