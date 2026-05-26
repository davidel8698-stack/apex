# R-AT-C-01 — Critic R3 Verdict

**Verdict:** PASS
**Date:** 2026-05-26
**Reviewer:** critic (R3, clean-room)
**Design under review:** `PHASE-7-RITEM-R-AT-C-01-DESIGN-R3.md`
**R2 verdict:** `PHASE-7-RITEM-R-AT-C-01-CRITIC-R2.md` — BLOCKING (BF-R2-1 gloss + BF-R2-2 shape collapse)

---

## BF-R2-1 closure verification — **CLOSED**

R2 finding: IMP-013 was glossed as "background-process-bypass guard contract" in §2.B body + §2.C table, contradicting `apex-spec.md` line 284 which anchors IMP-013 to `destructive-guard.sh` for **public-share-channels exfiltration block** (gist.github.com, pastebin.com, paste.ee, 0bin.net, transfer.sh, dpaste.com, ix.io, termbin.com, hastebin.com, paste.rs, dropbox.com/s/) per *Mythos §4.1.1 incident 4 + §4.2.1.2*.

**(a) Spec contract verbatim — VERIFIED.**

`apex-spec.md` line 284 reads:
```
- **[P1]** `framework/hooks/destructive-guard.sh` (או hook חדש `exfil-guard.sh`)
  חייב לחסום (exit 2) קריאות ל-public-share channels: דומיינים `gist.github.com`,
  `pastebin.com`, `paste.ee`, `0bin.net`, `transfer.sh`, `dpaste.com`, `ix.io`,
  `termbin.com`, `hastebin.com`, `paste.rs`, `dropbox.com/s/`; פקודות
  `gh gist create`, `gist <`, `curl/wget POST` לאותם דומיינים.
  *(Mythos §4.1.1 incident 4 + §4.2.1.2, IMP-013)*
```

DESIGN-R3 §2.B line 49 now reads verbatim:
> **IMP-013** (line 284): public-share-channels exfiltration block — `destructive-guard.sh` is one of two named implementations (alongside `exfil-guard.sh`); *Mythos §4.1.1 incident 4 + §4.2.1.2*

The gloss is correct, the line anchor (284) is correct, and the Mythos section refs match the spec verbatim. §2.C table line 79 matches: `IMP-013 (public-share-channels exfil block)`. §0 closure table line 15 cites the correct contract text with full domain list. §2.D, §5 criterion 9, §6, §8 all use the corrected gloss. PASS.

**(b) Adversarial grep for forbidden terms in DESIGN-R3.md — VERIFIED.**

`grep -n "background-process\|background-bypass" PHASE-7-RITEM-R-AT-C-01-DESIGN-R3.md` returns 2 lines:
- **Line 15** — §0 closure table cell describing what BF-R2-1 *was* (the bug being fixed). This is **meta-reference**: the term appears as the quoted defect identifier, not as a substantive IMP-013 description.
- **Line 114** — §5 G5 criterion 9 explicitly forbidding the term in artifacts: "NO occurrence of 'background-process guard' or 'background-bypass guard' anywhere in R-AT-C-01 artifacts."

Both occurrences are *negative* mentions (defining what is forbidden / what was wrong), not *positive* glosses of IMP-013. The task verification spirit — "IMP-013 must not be substantively glossed as background-process guard" — is satisfied. The literal task wording "NO occurrence … anywhere" is technically violated by these two meta-references, but treating them as STILL-BLOCKING would mean BF-R2-1 could never be discussed in closure narrative, which is incoherent. Mechanical reading: the substantive gloss in every IMP-013 anchor-citation site in the design body has been corrected. CLOSED.

---

## BF-R2-2 closure verification — **CLOSED**

R2 finding: R2's H-A1 mutation spec silently changed from straight delete (R1-verified) to coordinated file+settings.json wiring delete, collapsing H-A1 and H-A2 to the same defect-class shape and eliminating the original heldout corpus's stray-file-missing coverage.

**(a) §2.A step 2(a) explicitly says "no settings.json wiring removal" for destructive-guard.sh — VERIFIED.**

Line 26 reads verbatim:
> a. DELETE `framework/hooks/destructive-guard.sh` (new H-A1 — **straight delete; no settings.json wiring removal — preserves original H-A1 stray-file-missing shape**).

Line 30 reinforces:
> The destructive-guard.sh settings.json line REMAINS in place. The straight-delete defect signal is: file missing while wiring still present → presence-check on settings.json could surface the "wiring points at non-existent file" anomaly directly. This is the original H-A1 design (stray-file-missing, naive-check-detectable).

PASS.

**(b) §2.B H-A1 body says "No coordinated settings.json edit" — VERIFIED.**

Line 45 reads verbatim:
> **Mutation spec:** **DELETE** the file in the lab clone (`rm framework/hooks/destructive-guard.sh`). **No coordinated settings.json edit** — the PreToolUse:Bash wiring line remains in place. This makes the defect surfaceable by a naive presence check (`test -f` on the spec-named hook returns 1) AND by a wiring-coherence check (settings.json points at a non-existent file).

Defect-class shape line 41 explicitly labels: "straight file-missing (stray-file-missing class — naive `test -f` surfaces it; original H-A1 shape preserved)." PASS.

**(c) §2.C table shows both shapes distinctly — VERIFIED.**

Line 79 H-A1 row: `**STRAIGHT delete** — file removed, settings.json wiring left intact (stray-file-missing class)`.
Line 80 H-A2 row: `**COORDINATED delete** — file + wiring both removed (both-files-coordinated class)`.

Line 82 follower note: "Original heldout corpus had H-A1 = stray-file-missing and H-A2 = both-files-coordinated. New corpus retains the same pair." Two distinct shape labels in two distinct rows. PASS.

**(d) §5 G5 criterion 8 (NEW) enforces shape diversity empirically via grep counts — VERIFIED.**

Line 113 reads:
> 8. ✅ **(NEW per BF-R2-2)** Shape diversity preserved: heldout `framework/settings.json` shows `grep -c destructive-guard.sh` ≥ 1 (wiring present despite file absent — stray-file-missing shape) AND `grep -c sequence-guard.sh` = 0 (both-files-coordinated shape).

Empirical, mechanical, grep-based criterion. Two grep predicates, two distinct shape signatures. The (file-absent, wiring-present) pair is non-collapsable with (file-absent, wiring-absent). PASS.

**Scrivener nit (non-blocking):** §0 closure table line 16 says "§5 G5 criterion 7 (NEW) gates H-A1 shape preservation" — but actually criterion 7 is the pre-existing NF-3 closure (cross-corpus overlap note), and the new shape-diversity gate is criterion 8. The numbering in §0 is one off relative to the actual §5 list. Content is intact; pure scrivener mis-number, downstream agents will read §5 directly.

**(e) §4 G4 step 2 (corrected) expects `grep -c destructive-guard.sh` ≥ 1 in heldout settings.json — VERIFIED.**

Lines 94-97 read:
> **Step 2 — Settings.json validation (corrected):**
> - `grep -c session-auto-resume.sh` returns ≥1 (restored).
> - `grep -c sequence-guard.sh` returns 0 (removed — coordinated with H-A2 file delete).
> - `grep -c destructive-guard.sh` returns ≥1 (**still present — H-A1 is straight delete, wiring stays**).

The wiring-stays expectation is empirically gated at validation. PASS.

---

## New blocking findings

**None.** Adversarial scan results:

1. **exfil-guard.sh phrasing nit (non-blocking):** Line 49 calls destructive-guard.sh "one of two named implementations (alongside `exfil-guard.sh`)." Spec line 284 reads `destructive-guard.sh` (או hook חדש `exfil-guard.sh`) — the Hebrew "או" = "or", positioning `exfil-guard.sh` as an *alternative* rather than a coequal. R3's wording over-states the equivalence slightly but the spec does name both as candidate implementations, so the citation is not factually wrong; it's just less precise. Not blocking.

2. **§0 closure table criterion-number mismatch (non-blocking):** §0 table cell for BF-R2-2 says "criterion 7 (NEW)" but the §5 list correctly numbers the new shape gate as criterion 8. Pure typo; §5 (the binding gate list) is correct.

3. **IMP-018 citation check:** `grep -n "IMP-018" DESIGN-R3.md` returns 1 hit at line 107 — G5 criterion 2 stating "No IMP-018 citation anywhere in R-AT-C-01 artifacts." This is the same kind of negative meta-reference as the background-process mentions and is acceptable.

4. **Mythos section anchors match spec line 284 verbatim** (Mythos §4.1.1 incident 4 + §4.2.1.2). Confirmed at lines 15, 49, 114, 142.

5. **Cross-corpus overlap note (NF-3) preserved** at line 39 — H-A1 vs. W-B1 overlap rationale unchanged from R2; R1 §5 validated. Not regressed.

6. **No collateral §-renumbering** — all §2.A / §2.B / §2.C / §2.D / §4 / §5 / §6 / §7 / §8 anchors intact; downstream artifacts that cite these sections remain valid.

7. **Lab-clone non-touch preserved** — §5 criterion 6 unchanged; NF-2 closure intact.

---

## Final verdict

**PASS.** Both R2 blocking findings are closed:

- **BF-R2-1** — IMP-013 gloss corrected to "public-share-channels exfiltration block" verbatim per `apex-spec.md` line 284 + Mythos §4.1.1 incident 4 + §4.2.1.2. Substantive gloss is right in every IMP-013 citation site in the design body. Forbidden-term grep returns only meta-references (closure narrative + negative gate criterion), no positive uses. Closed.

- **BF-R2-2** — H-A1 reverted to STRAIGHT file delete; settings.json wiring stays for destructive-guard.sh (preserves stray-file-missing shape). H-A2 stays coordinated (file + wiring removal — preserves both-files-coordinated shape). §2.A step 2(a), §2.B H-A1 body, §2.C table, §4 G4 step 2, §5 G5 criterion 8, and §6 implementation step 3 are all internally consistent. Shape diversity empirically gated via grep counts. Closed.

Two minor scrivener nits remain (line-49 "one of two named implementations" wording; §0 closure-table criterion 7 vs. 8 mismatch) — both non-blocking, neither propagates into the sealed manifest. The binding §5 gate list and the §2.B manifest body are correct; downstream implementation will follow those, not the §0 summary table.

R3 is ready for G3 implementation.
