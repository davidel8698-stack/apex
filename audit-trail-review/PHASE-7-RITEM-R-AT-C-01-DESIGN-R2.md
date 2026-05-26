# R-AT-C-01 — Design R2 · BF-1 + NF-1..NF-3 closure pass

**Supersedes:** `PHASE-7-RITEM-R-AT-C-01-DESIGN.md` (R1).
**Critic R1 verdict:** `PHASE-7-RITEM-R-AT-C-01-CRITIC-R1.md` — NEEDS-CLARIFICATION (1 BF + 3 NF).
**Date:** 2026-05-26.

R1 §1, §3-§8 unchanged unless noted. R2 addresses BF-1 in §2 and adopts NF-1/NF-2/NF-3 resolutions.

---

## §0. Critic R1 closure summary

| Finding | R1 issue | R2 resolution |
|---------|----------|---------------|
| **BF-1** | IMP-018 mis-cite — destructive-guard.sh is anchored to IMP-002/008/013/014/017, NOT IMP-018 (which is owner-guard/subagent-guard) | Swap citation: `IMP-014 (mass-effect regex), IMP-018 (background-bypass)` → `IMP-014 (mass-effect regex), IMP-013 (background-process guard)` in §2 table; remove "IMP-018" everywhere in R-AT-C-01 design |
| **NF-1** | Add G4 axis-10 dry-run probe to verify exit-127 (file-not-found) is not mis-scored as guard-bypass | §4 G4 step 5 added: dry-run invocation of `bash framework/hooks/destructive-guard.sh` against the heldout lab; observe `exit 127 (No such file)` — confirm error class is "file missing" not "exit 0 bypass" |
| **NF-2** | Lab-clone snapshot of HELDOUT-CORPUS.md.sealed is NOT to be modified | §2 Change B explicitly states: only `detector-review/manifests/HELDOUT-CORPUS.md.sealed` (project root) is edited. The lab-clone copy at `.lab/apex-detector-lab-heldout/detector-review/manifests/HELDOUT-CORPUS.md.sealed` is NOT touched (lab clones are sealed reference state) |
| **NF-3** | New H-A1 (destructive-guard.sh delete) and W-B1 (destructive-guard.sh allowlist backdoor) target the same file, different mechanism | §2 Change B adds a manifest acknowledgement line at the top of the new H-A1 entry noting the cross-corpus overlap is by mechanism (delete vs. backdoor), not by file ownership; anti-overlap discipline rule is "different defect mechanism = independent mutation," which is satisfied |

---

## §2. Design (revised)

### §2.A (unchanged) — Lab mutation reset + new mutations

Same as R1 §2 Change A.

### §2.B (revised per BF-1 + NF-3) — Update heldout corpus manifest

`detector-review/manifests/HELDOUT-CORPUS.md.sealed` (project root only; the lab-clone copy at `.lab/apex-detector-lab-heldout/detector-review/manifests/HELDOUT-CORPUS.md.sealed` MUST NOT be modified — NF-2 closure).

**New H-A1 entry (replaces lines 91-114):**

```markdown
### H-A1 · file removal — spec-named Defense-in-Depth guard absent (destructive-guard)

**Cross-corpus overlap note:** new H-A1 target (`framework/hooks/destructive-guard.sh` — file deletion) and working-corpus W-B1 (same file — allowlist-backdoor insertion) operate on the same file via DIFFERENT mechanisms. Anti-overlap discipline rule "different defect mechanism = independent mutation" is satisfied. Reviewer cross-check: this overlap is intentional and disjoint by detection axis.

- **Class:** A
- **Target:** `framework/hooks/destructive-guard.sh`
- **Mutation spec:** **DELETE** the file in the lab clone (`rm framework/hooks/destructive-guard.sh`). Additionally remove the matching wiring lines from `framework/settings.json` under the `PreToolUse:Bash` block (both the matcher entry and any docs).
- **Ground truth:** A spec-named Defense-in-Depth guard is absent — and its registration was also removed, so the defect is invisible to a naive presence check on settings.json alone.
- **Spec anchors (apex-spec.md):**
  - **IMP-014** (line 200): mass-effect command regex deny — `destructive-guard.sh` is the named implementation
  - **IMP-013** (line ~290): background-process-bypass guard contract
  - Plus Defense-in-Depth Security Layer enumeration at §"Defense-in-Depth Security Layer"
- **Expected sound finding:** P0 (or P1) — "`destructive-guard.sh` not present in `framework/hooks/`; Defense-in-Depth Security Layer IMP-014 + IMP-013 implementation deleted." Must localise the file and the IMP anchors.
- **Reproduction:** `test -f framework/hooks/destructive-guard.sh` returns exit 1; `grep -F 'destructive-guard.sh' framework/settings.json` returns 0 matches.
- **Recovery:** restore from project-root `framework/hooks/destructive-guard.sh` (cp) and restore settings.json wiring.
```

**New H-A2 entry (replaces lines 116-150):**

```markdown
### H-A2 · file removal — spec-named credential-search guard absent (sequence-guard)

- **Class:** A
- **Target:** `framework/hooks/sequence-guard.sh`
- **Mutation spec:** **DELETE** the file in the lab clone (`rm framework/hooks/sequence-guard.sh`). Additionally remove the matching wiring line from `framework/settings.json` line 53 (`bash ~/.claude/hooks/sequence-guard.sh`) under the `PreToolUse:Bash` block — coordinated removal preserves the "both-files-coordinated" defect class of the original H-A2.
- **Ground truth:** A second spec-named Defense-in-Depth guard is absent — credential-search-after-denied detection (IMP-016 contract) is broken. The wiring removal makes the defect invisible to a presence-check on settings.json alone.
- **Spec anchor (apex-spec.md IMP-016):** the credential-search-sequence detector contract; `sequence-guard.sh` is the named implementation.
- **Expected sound finding:** P0 (or P1) — "`sequence-guard.sh` not present in `framework/hooks/` AND its PreToolUse:Bash wiring removed from `framework/settings.json`; IMP-016 credential-search-sequence detector deleted. Both files modified in coordination — credential-search-after-denied detection is fully disabled."
- **Reproduction:** `test -f framework/hooks/sequence-guard.sh` → 1; `grep -F 'sequence-guard.sh' framework/settings.json` → 0 matches.
- **Recovery:** restore both files.
```

**Phase-7 Re-authorization Note (insert at top of HELDOUT-CORPUS.md.sealed under the `.sealed` semantics paragraph):**

```markdown
> **Phase-7 R-AT-C-01 re-authorization (2026-05-26).** H-A1 and H-A2 entries below were re-authored from the original (memory-watchdog.sh / session-auto-resume.sh) per `audit-trail-review/PHASE-7-MASTER-PLAN.md` §5 R-AT-C-01. Original entries are preserved in git history (commit prior to R-AT-C-01). Reason: the original targets are named in the heldout spec only as bare basenames within the Auto-Continuity Layer table; the framework-auditor's extraction grep requires the `framework/hooks/` prefix, so the original mutations were structurally invisible to mechanical enumeration. New targets are present in the auditor's extracted_set (verified via canonical grep against the heldout lab spec).
```

### §2.C (revised per BF-1) — table swap

Change the H-A1 row in §2 table:

| ID | Target | Spec anchors | Rationale |
|----|--------|--------------|-----------|
| **H-A1 (new)** | `framework/hooks/destructive-guard.sh` | IMP-014 (mass-effect regex), IMP-013 (background-process guard) | Heavily spec-named (≥4 spec mentions); coordinated file+wiring delete |
| **H-A2 (new)** | `framework/hooks/sequence-guard.sh` + matching `framework/settings.json` PreToolUse:Bash wiring removal | IMP-016 (credential-search-sequence) | Heavily spec-named; tests "both-files-coordinated" deletion |

Note: H-A1 now ALSO uses coordinated file+wiring delete (matches new design — both H-A1 and H-A2 follow the same coordinated-deletion pattern, preserving original H-A2's defect-class shape).

### §2.D (unchanged) — Master plan + FINAL-CERTIFICATION updates

Same as R1.

---

## §4. Validation strategy (REVISED per NF-1)

G4 steps (mechanical, shell-based, no agent invocation):

1. **File-state validation:** `test -f` confirms restored hooks present; `test ! -f` confirms new mutation targets absent.
2. **Settings.json validation:** `grep -c session-auto-resume.sh` returns ≥1 (restored); `grep -c sequence-guard.sh` returns 0 (removed); `grep -c destructive-guard.sh` returns 0 (removed).
3. **Auditor extraction grep validation:** running the canonical extraction grep against the heldout spec returns ≥17 hooks INCLUDING `destructive-guard.sh` and `sequence-guard.sh`.
4. **Mechanical enumeration sanity check:** for each of the 17 hooks in extracted_set, `test -f .lab/apex-detector-lab-heldout/framework/hooks/<hook>` returns 0 EXCEPT for destructive-guard.sh (exit 1, P0 candidate) and sequence-guard.sh (exit 1, P0 candidate).
5. **(NF-1 closure) Axis-10 dry-run probe:** invoke `bash .lab/apex-detector-lab-heldout/framework/hooks/destructive-guard.sh 2>&1; echo "exit=$?"` — observe error mode. Expected: exit-127 with shell-level "No such file or directory" diagnostic (the file is missing, not present-and-bypassed). This is the file-not-found class of failure, not the bypass class. The auditor's axis-10 procedural sub-pass should classify this as "guard missing" (axis-1 finding) rather than "guard bypassed" (axis-10 finding) — and this is correct behavior since the file IS missing. The lab-state matrix MUST show: enumeration emits P0, axis-10 reports BLIND SPOT for this guard (or "file missing — see axis-1 F-NNN" cross-reference). Document the observed exit code and stderr verbatim in the closure record. Verifies no double-counting between axis-1 and axis-10 for the same defect.

---

## §5. G5 PASS criteria (REVISED per BF-1)

Critic R2 PASS requires:
1. ✅ G4 validation 1-5 all PASS.
2. ✅ HELDOUT-CORPUS.md.sealed Phase-7 re-auth note present + new H-A1/H-A2 manifests reference IMP-014/013 (H-A1) and IMP-016 (H-A2). **No IMP-018 citation anywhere in R-AT-C-01 artifacts.**
3. ✅ Original H-A1/H-A2 manifest content preserved in git history.
4. ✅ FINAL-CERTIFICATION-C.md §3 + PHASE-7-MASTER-PLAN.md §5 closure notes landed.
5. ✅ No collateral changes to working-corpus manifests, pristine framework files, or auditor agent files.
6. ✅ Lab-clone copy at `.lab/apex-detector-lab-heldout/detector-review/manifests/HELDOUT-CORPUS.md.sealed` UNCHANGED (NF-2 closure).
7. ✅ Cross-corpus overlap note for destructive-guard.sh (H-A1 vs. W-B1) present in H-A1 manifest (NF-3 closure).

---

## §6. Implementation plan (REVISED — single commit)

Same 6 file operations as R1 §6, with the IMP-014/013 (not IMP-018) citations in step 5.

---

## §7. Out-of-scope (unchanged)

Same as R1.

---

## §8. Decision summary (R2)

**R1 verdict:** NEEDS-CLARIFICATION (1 BF + 3 NF).
**R2 resolutions:** BF-1 IMP swap (IMP-018 → IMP-013) + NF-1 G4 step 5 axis-10 dry-run + NF-2 explicit lab-clone non-touch + NF-3 cross-corpus overlap note.

**Strategy unchanged:** corpus realignment per master plan §5. Two file deletions in heldout lab + settings.json wiring updates + manifest re-author. Single commit.

**Blast radius:** unchanged from R1 (8 files; lab-clone manifest NOT touched per NF-2).

**Next gate:** G2 critic R2 verification.
