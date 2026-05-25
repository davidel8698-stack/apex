# FIX-DESIGN-C — B3-critic R4 (clean-room adversarial design review)


> **Scope (clean-room):** audit-trail-review/FIX-DESIGN-C-R4.md + binding inputs (EXPERIMENT-PROTOCOL-C.md section 10 R4-updated, live framework/hooks/subagent-stop.sh lines 175-186, live framework/hooks/pre-subagent-start.sh lines 140-148, live apex-spec.md, live framework/hooks/ directory listing). R3 review (FIX-DESIGN-C-CRITIC-R3.md) consulted as the closure rubric only.

> **Review surface this round:** ONLY the 4 R3-NEW findings + the section 1.5 NEW mechanism. R1+R2+R3 17 prior findings are CLOSED — not re-litigated.

> **Date:** 2026-05-25. **Baseline pin in design:** 43b37db.
> **Verdict:** **PASS-WITH-CHANGES** — 4 R3 findings closed cleanly; 2 MINOR R4-NEW defects in section 1.5 + 1 advisory note about regex breadth.

---

## section 0. R3-delta closure scorecard

| R3 finding | Sev. | Claimed R4 resolution | Verify outcome | New finding |
|------------|------|-----------------------|----------------|-------------|
| CR-C-R3-01 | BLOCKING | EXPERIMENT-PROTOCOL-C.md section 10 already edited to dynamic-extraction | CLOSED — verified section 10 lines 156-165 now contain dynamic grep + R3 update banner | — |
| CR-C-R3-02 | MAJOR | Round-checker bound to independently re-run grep; auditor claim is advisory | CLOSED — section 2 lines 80-110 explicitly bind round-checker to RC_EXTRACTED=grep; set-difference vs auditor enumerated set is the gate | — |
| CR-C-R3-03 | MAJOR | Shell parser hardened with colon-presence + non-empty-rest + defensive nonce!=agent_id checks | CLOSED — section 3 lines 132-149 add 3 guards; traced both edge cases by hand and parser now rejects | — |
| CR-C-R3-04 | MAJOR | Race-safety proof corrected; bounded-residual semantics; R-AT-P7-12 reserved | CLOSED — section 4 lines 191-204 correctly name the orphaned-inode lost-append hazard; fail-closed; sub-50ms residual is plausible | — |
| section 1.5 NEW | — | Forward-reference classification to avoid false-P0 flood on Phase-12 hooks | CLOSED-WITH-DEFECT — see CR-C-R4-01, CR-C-R4-02 | CR-C-R4-01, CR-C-R4-02 |

Net: all 4 R3-NEW findings cleanly closed. The section 1.5 addition (raised by R3 as a follow-up analysis) introduces 2 MINOR defects related to round-checker trust + factual prose inaccuracy. Neither defect blocks C2 implementation; both can be tightened in C3 round-checker spec or C2 implementer notes.

---

## section 1. CR-C-R3-01 — Protocol section 10 dynamic-extraction (RESOLVED)

**Verification.** Read EXPERIMENT-PROTOCOL-C.md section 10 (lines 156-165):
- Line 159 now reads: spec_named_hook_presence with one row per spec-literal hook extracted DYNAMICALLY at round time via the AC-C1 grep (expected count 19-25 depending on spec version; verified 19 at C0 freeze on baseline 43b37db).
- Line 163 now reads: Round-checker rejects any trial whose spec_named_hook_presence is a strict subset of the runtime-extracted set, OR whose probes claim execution but lack matching audit_probe_allowed events with the correct payload_sha1.
- Line 165 adds the R3-update banner: replaced hardcoded 17 rows with dynamic-extraction gate to match section 3 AC-C1.

**No conflicting 17-rows or fewer-than-17-entries language remains.** Section 3 (AC-C1) and section 10 now use the same dynamic-grep formulation. The internal-inconsistency defect flagged by CR-C-R3-01 is fully closed.

**Independently verified:** ran the AC-C1 grep against the live spec on 43b37db -> 19 hooks exactly. Matches R4 verified-19 claim.

---

## section 2. CR-C-R3-02 — Round-checker independence (RESOLVED)

**Verification.** R4 section 2 lines 80-110 explicitly bind the round-checker:

1. Lines 93-96: round-checker computes its own RC_EXTRACTED via independent grep.
2. Lines 99-101: set-difference RC_EXTRACTED minus auditor_enumerated is the canonical gate — non-empty triggers REJECT with reason auditor missed N spec-named hooks.
3. Lines 102-103: reverse difference is advisory (auditor may report extras).
4. Line 104: The round-checker grep is the AUTHORITY; the auditor claimed extracted_set_size is advisory.

**Trace of the underreport attack.** Auditor reports extracted_set_size=N=narrow AND enumerated_set_size=N=narrow (matched, internally consistent). Round-checker:
1. Re-runs grep -> gets the full 19 set.
2. Computes RC_EXTRACTED minus auditor_enumerated -> non-empty.
3. REJECTs closure with the missing-hook list.

The auditor cannot game the gate by reporting matched-narrow numbers — the round-checker independent grep catches the under-enumeration. **CR-C-R3-02 cleanly closed.**

One nit: R4 section 2 says round-checker MUST re-run grep against the SAME apex-spec.md the auditor used but does not explicitly bind it to cite the spec SHA at round-time. If the auditor ran against an outdated lab clone spec, the round-checker should detect that by comparing its CURRENT-checkout grep vs the auditor claimed grep input. R3 section 1 did already say cite-SHA-at-round-time — verify this language survives into the C3 round-checker spec implementation. **Advisory only, no finding.**

---

## section 3. CR-C-R3-03 — Shell parser hardening (RESOLVED)

**Hand-trace of the two edge cases (verified via live bash execution):**

**Edge 1:** cmd = __APEX_AUDIT_PROBE__:abc123 (no second colon)
- after_prefix = abc123
- case match (asterisk-colon-asterisk) is FALSE -> return 1. **REJECT.** Parity with node parser restored.

**Edge 2:** cmd = __APEX_AUDIT_PROBE__:abc123: (trailing colon, empty agent_id)
- after_prefix = abc123:
- Colon-check passes (asterisk-colon-asterisk matches abc123:)
- nonce = abc123, rest = empty (after-hash-asterisk-colon strips through first colon)
- case match (question-asterisk) is FALSE -> return 1. **REJECT.**

Both edge cases independently verified. The 3-layer guard (colon-presence -> non-empty-rest -> nonce/agent_id non-empty + nonce!=agent_id) is sound. The change from hash-nonce-colon (no-op when nonce-pattern does not match) to hash-asterisk-colon (always strips through first colon) is a positive defensive improvement.

**Defensive nonce==agent_id guard analysis.** Nonce is 16 hex chars; agent_id is subagent-framework-auditor-round-sha8 (38+ chars with hyphens, mixed charset). The two strings can NEVER coincide in production (length alone differs, char set differs). The guard is safe — no legitimate (nonce, agent_id) pair will ever be rejected by this clause. **CR-C-R3-03 cleanly closed.**

C-8 test row added (line 162-166) to enforce parity going forward. Good.

---

## section 4. CR-C-R3-04 — Race-safety proof correctness (RESOLVED)

**Verification of each claim in R4 section 4:**

Read-side guarantee. Guard read sees pre-mv OR post-mv file, never torn. CORRECT.

Linux fd semantics: read opens fd against inode REG at open(2) time.

Fd holds inode even if concurrent mv swaps directory entry.
Read is atomic-per-fd.

Verified against pre-subagent-start.sh line 148 (>> REG = O_APPEND on the
directory-resolved inode) and subagent-stop.sh lines 178-185 (mv TMP_REG REG =
atomic-rename in same filesystem).

**Write-side hazard.** Concurrent append during subagent-stop rewrite window
lands on the orphaned inode and is silently lost.
New auditor has NO entry. F2 fails (agent_id not in registry).
Fail-closed -> CORRECT. Known JSONL race pattern.
Fail-closed framing (probes blocked rather than mis-attributed) is right default.

**Bounded-residual sub-50ms.** jq -c on a small JSONL file (tens-to-hundreds
of lines) typically runs in 5-15ms; mv is sub-1ms (single inode swap in same fs).
Total window 5-20ms in practice; sub-50ms is a conservative upper bound that
holds across pathological spikes. **Plausible.**

**R-AT-P7-12 reservation.** R4 section 4 line 204 explicitly reserves the
strict-append-only redesign for Phase 7. Right scope boundary — Campaign C is
closing the 3 hard-FAIL ACs, not the race-window architecture.
**CR-C-R3-04 cleanly closed.**

The replacement R3 section 2 paragraph (R4 section 4 line 210) is well-formed
and correctly documents the residual hazard.

---

## section 5. NEW R4 defects (section 1.5 forward-reference classification)

### CR-C-R4-01 — MINOR. Round-checker pairing rule does NOT explicitly bind
round-checker to RE-VERIFY the cite entry is a real apex-spec.md line.

R4 section 1.5 line 73 says: If matching finding has forward_reference:true flag
AND cite contains BOTH the hook AND a spec line containing forward-reference
prose -> PASS pairing as advisory.

This phrasing IMPLIES the round-checker checks the cite entries, but does not
explicitly bind it to:
1. Read the cited spec lines from apex-spec.md at round-time.
2. Verify the cited line content actually contains FR-prose (not just claims to).

**Attack vector.** A lazy/careless auditor could pass:
- forward_reference:true
- cite=[destructive-guard.sh, synthetic-forward-reference-line-by-auditor]

A literal string-scan over cite[1] for the literal text forward-reference passes
trivially. The auditor has bypassed P0 emission without proof.

**Required for R5 OR for the round-checker C3 spec:** explicitly add:
Round-checker MUST extract the cite spec-line content by line number and
re-verify it appears verbatim in lab/apex-spec.md AND that the verbatim content
contains FR-prose per the same regex used by the auditor. Cite entries that are
not present in apex-spec.md verbatim -> REJECT pairing as fabricated.

**Severity:** MINOR. Same defect class as CR-C-R3-02 (auditor self-attestation
gap) applied to the new section 1.5 mechanism. The fix is identical in shape —
bind round-checker to independent verification — and is a 1-paragraph addition.
Does NOT block C2.

---

### CR-C-R4-02 — MINOR. Section 1 paragraph at line 50 incorrectly identifies
4 hooks as spec-named-but-future; live filesystem shows 2 of them
(dora-collect.sh, decision-gate.sh) ALREADY EXIST.

R4 section 1 line 50 claims: this list includes 4 hooks that DO NOT YET EXIST in
framework/hooks/ (dora-collect.sh, first-hour-telemetry.sh, phase-compaction.sh,
decision-gate.sh — verified in Phase 12 forward-references per apex-spec.md
Phase-12-M16.1-deliverables section).

**Live filesystem check** (directly listing framework/hooks/):
- dora-collect.sh -> EXISTS on disk
- first-hour-telemetry.sh -> MISSING (correctly forward-reference; FR-prose in spec)
- phase-compaction.sh -> MISSING
- decision-gate.sh -> EXISTS on disk

So R4 section 1 enumeration is factually wrong on 2 of 4 hooks.

Of the 19 hooks extracted, only 2 are actually missing (first-hour-telemetry.sh, phase-compaction.sh).
Of those 2, only first-hour-telemetry.sh has FR-prose in its spec context.
phase-compaction.sh spec citation at apex-spec.md line 112 mentions phase boundaries / IMP-DR-008 but NO forward-reference / Phase-12 phrase within +/-2 lines (verified via grep).

Practical impact on section 1.5 mechanism. When C5 trials run:
- dora-collect.sh exists -> axis-1 emits exit_code=0 -> no P0/P3 needed.
- decision-gate.sh exists -> axis-1 emits exit_code=0 -> no P0/P3 needed.
- first-hour-telemetry.sh missing + FR-prose present -> section 1.5 P3 (correct).
- phase-compaction.sh missing + NO FR-prose -> section 1.5 emits P0 (correct; the spec OWES this hook).

So the section 1.5 mechanism actually works correctly — only phase-compaction.sh is a genuine P0 risk in the current spec/repo state. R4 prose-claim that all 4 are forward-references is the documentation defect; the mechanism itself is fine.

Severity: MINOR. Documentation accuracy issue, no behavioral defect. Does NOT block C2.

---

### Advisory note on section 1.5 regex over-breadth (NO FINDING)

The regex forward.reference|phase.12|deliverable|planned uses dot (regex any-char), which is intentional but also accidentally permissive (phaseX12, phase_12).
The words deliverable and planned are common English; they could trigger false-P3 classification if future spec edits add either word near a real-but-broken hook citation.

Tested against current spec: ran the regex against spec contexts of 3 fully-implemented hooks (destructive-guard.sh, phantom-check.sh, quarantine-guard.sh). None falsely match.
The regex is safe AGAINST THE CURRENT SPEC, but fragile for future evolution.
Advisory only — no finding.

---

## section 6. Cross-design coherence (R4)

### AC-4 / AC-C1 closure path
Sound. CR-C-R3-01 (protocol section 10 update) closed; CR-C-R3-02 (round-checker independence) closed. The dynamic-extraction gate is now independently enforceable by the round-checker.
CR-C-R4-01 raises the same defect class for section 1.5 but does not invalidate the AC-C1 enforcement (which is grep-based, not citation-based).

### AC-5b / AC-C2 closure path
Sound. CR-C-R3-03 closes parser parity. The trust-matrix claim (only the auditor whose nonce was emitted passes F3) holds.
The 3-guard hardening (colon-check, rest-non-empty, nonce!=agent_id) is defensive without false-rejecting legitimate inputs.

### Race-safety bounded residual
Documented. R4 section 4 correctly identifies the orphaned-inode lost-append as a fail-closed window; R-AT-P7-12 reserved. No additional Campaign-C action needed.

### Forward-reference handling
Mostly sound. Section 1.5 mechanism is structurally correct; the round-checker pairing rule discriminates between P0 (no FR prose nearby) and P3-advisory (FR prose present + cited).
The 2 MINOR defects (CR-C-R4-01 = round-checker fabrication trust, CR-C-R4-02 = factually wrong forward-ref enumeration in design prose) are tightenable in C3 round-checker spec and C2 implementer notes respectively.

### Coherence with section 12.2
Unchanged. AC-4, AC-5b, AC-6b, AC-C1, AC-C2 all section 12.2 hard-FAIL. No L-item path. Path C amendment ladder intact.

---

## section 7. Summary table

| Finding | Sev. | Round | Status | R5 required? |
|---|---|---|---|---|
| CR-C-R3-01 (BLOCKING) | — | R3 | CLOSED in R4 section 1 + protocol section 10 | No |
| CR-C-R3-02 (MAJOR) | — | R3 | CLOSED in R4 section 2 | No |
| CR-C-R3-03 (MAJOR) | — | R3 | CLOSED in R4 section 3 | No |
| CR-C-R3-04 (MAJOR escalated) | — | R3 | CLOSED in R4 section 4 | No |
| CR-C-R4-01 | MINOR | R4 | OPEN — round-checker fabrication trust on section 1.5 cite | No (tighten in C3 round-checker spec) |
| CR-C-R4-02 | MINOR | R4 | OPEN — R4 section 1 line 50 prose factually wrong on 2/4 hooks | No (correct in C2 implementer notes) |
| section 1.5 regex breadth | Advisory | R4 | OPEN — fragile for future spec edits but currently safe | No |

---

## section 8. Verdict

**PASS-WITH-CHANGES.**

All 4 R3-NEW findings (CR-C-R3-01 BLOCKING, CR-C-R3-02 MAJOR, CR-C-R3-03 MAJOR, CR-C-R3-04 MAJOR escalated) are cleanly closed by R4 sections 1-4:
- Protocol section 10 dynamic-extraction language matches section 3 AC-C1.
- Round-checker bound to independent grep; auditor self-report is advisory.
- Shell parser hardened with 3-layer guard; parity with node parser restored.
- Race-safety proof corrected; orphaned-inode lost-append fail-closed; R-AT-P7-12 reserved.

The new section 1.5 forward-reference classification is structurally correct: missing hooks with FR-prose in their spec context are routed to P3-advisory; missing hooks WITHOUT FR-prose remain P0. The mechanism prevents the 1-hook false-P0 (first-hour-telemetry.sh) and correctly preserves the 1-hook genuine-P0 (phase-compaction.sh).

Two MINOR defects in section 1.5:
- CR-C-R4-01: round-checker pairing rule does not explicitly bind round-checker to re-verify cite entries are verbatim from apex-spec.md. Same defect class as CR-C-R3-02; tightenable in C3 round-checker spec via a 1-paragraph addition.
- CR-C-R4-02: R4 section 1 line 50 prose claims 4 hooks are missing forward-references; live filesystem shows only 2 are missing (dora-collect.sh and decision-gate.sh actually exist). Documentation accuracy; mechanism is unaffected.

One advisory note: section 1.5 regex (forward.reference|phase.12|deliverable|planned) is over-broad on the words deliverable and planned. Currently safe against the spec but fragile for future edits.

**No BLOCKING findings. C2 implementation may proceed.** The 2 MINOR defects do not require an R5; they are tightenable in the downstream C3 round-checker spec and the C2 implementer notes. Per the review-surface brief: if PASS-WITH-CHANGES with only MINOR findings -> owner may choose to accept and proceed. This verdict qualifies for owner-accept.

**Re-submission path** (if owner elects to close R4-MINORs in design rather than deferring to C3): author FIX-DESIGN-C-R5.md with section 0 changelog addressing CR-C-R4-01 (explicit round-checker re-verify of cite verbatim) and CR-C-R4-02 (correct the 4-hook prose to 2-hook fact). Estimated R5 effort: under 30 minutes; R5 review would be tight (2-item delta).

**Recommendation:** owner-accept R4 as-is + carry CR-C-R4-01 forward to C3 round-checker spec implementation + carry CR-C-R4-02 forward as a 1-line C2 implementer note. The 4 R3 deltas are the substantive review items; both R4-NEW defects are advisory tightenings.

---

Authored 2026-05-25. Clean-room R4. No implementation written. No commits proposed. R4 review surface restricted to the 4 R3 deltas + section 1.5 NEW per the focused-verification brief. R1+R2+R3 17 prior findings remain CLOSED and were not re-litigated.
