# R-AT-C-01 — Design (G1) · heldout corpus realignment

**Closes:** AC-4 heldout (Class-A 2/2 reliable-kill, currently 0/2).
**Spec anchor:** `apex-spec.md` IMP-014 (destructive-guard mass-effect) + IMP-016 (sequence-guard credential search) + `EXPERIMENT-PROTOCOL.md` §9 Class-A threshold.
**R-item source:** `PHASE-7-MASTER-PLAN.md` §5 R-AT-C-01.
**Date:** 2026-05-26.

---

## §1. Root cause (G0 evidence — confirmed)

C5-T4 trial (`audit-trail-review/trials-c5/c5-heldout-t1.md`) says: "memory-watchdog.sh (H-A1 mutant) and session-auto-resume.sh (H-A2 mutant) are NOT in the older spec's enumeration."

**Empirically reproduced:**

```
grep -oE 'framework/hooks/[a-zA-Z_-]+\.(sh|cjs|ps1)' \
  .lab/apex-detector-lab-heldout/apex-spec.md | sort -u
```

Returns 17 hooks. Neither `memory-watchdog.sh` nor `session-auto-resume.sh` appears — even though both names DO appear in the heldout spec at lines 414 / 416 of the Auto-Continuity Layer table. **Reason:** the spec's table format uses bare backticked filenames (`` `memory-watchdog.sh` ``) without the `framework/hooks/` prefix. The auditor's extraction grep requires the full prefix.

This is a corpus-vs-extraction-grep alignment defect. The mutations target hooks the auditor's enumeration can never see.

Per master plan §5: "Re-author H-A1, H-A2 to target hooks PRESENT in the lab's older apex-spec.md."

## §2. Design

### Candidate target selection

Constraints:
1. MUST be in the heldout extracted_set (17 hooks) so axis-1 mechanical enumeration surfaces the deletion.
2. MUST NOT overlap with working corpus W-A1 (`apex-prompt-guard.cjs`) / W-A2 (`apex-workflow-guard.cjs`).
3. MUST be heavily spec-named (multiple IMP anchors) so the defect class "spec-named hook deleted" is unambiguously load-bearing.
4. SHOULD match the original H-A1/H-A2 defect-class shape (one straightforward file deletion + one coordinated file+settings deletion).

**Chosen:**

| ID | Target | Spec anchors | Rationale |
|----|--------|--------------|-----------|
| **H-A1 (new)** | `framework/hooks/destructive-guard.sh` | IMP-014 (mass-effect regex), IMP-018 (background-bypass) | Heavily spec-named (≥5 spec mentions); straight file deletion |
| **H-A2 (new)** | `framework/hooks/sequence-guard.sh` + matching `framework/settings.json` PreToolUse:Bash wiring removal | IMP-016 (credential-search sequence) | Heavily spec-named; tests "both-files-coordinated" deletion (matches original H-A2 defect-class shape) |

Both targets verified present in heldout extracted_set (the auditor's grep returns them as `framework/hooks/destructive-guard.sh` and `framework/hooks/sequence-guard.sh`).

### Changes

**Change A — Lab mutation reset + new mutations.**

1. Restore in `.lab/apex-detector-lab-heldout/`:
   - `framework/hooks/memory-watchdog.sh` (copy from project root `framework/hooks/memory-watchdog.sh`)
   - `framework/hooks/session-auto-resume.sh` (copy from project root)
   - Restore `bash ~/.claude/hooks/session-auto-resume.sh` line in `framework/settings.json` under SessionStart (insertion point depends on existing structure; replicate by reading parent project's settings.json layout).

2. Apply new mutations in `.lab/apex-detector-lab-heldout/`:
   - DELETE `framework/hooks/destructive-guard.sh` (new H-A1).
   - DELETE `framework/hooks/sequence-guard.sh` (new H-A2).
   - REMOVE `framework/hooks/sequence-guard.sh` line from heldout `framework/settings.json` PreToolUse:Bash block (coordinated removal — preserves the "both-files-coordinated" defect class of original H-A2).

3. Commit the lab state in the heldout lab's own git history (lab is a separate git repo; commit message documents the H-A1/H-A2 realignment).

**Change B — Update heldout corpus manifest.**

`detector-review/manifests/HELDOUT-CORPUS.md.sealed`:

- REPLACE the H-A1 entry (lines 91-114) with new H-A1 description: target = `framework/hooks/destructive-guard.sh`; spec anchor = IMP-014 + IMP-018; expected sound finding = P0 axis-1 mechanical enumeration P0 emission citing `destructive-guard.sh`.
- REPLACE the H-A2 entry (lines 116-150) with new H-A2 description: target = `framework/hooks/sequence-guard.sh` + settings.json wiring; spec anchor = IMP-016; expected sound finding = P0 axis-1 mechanical enumeration emission AND axis-cross-reference finding for missing settings entry.

Add a **Phase-7 Re-authorization Note** block at the top of the file documenting the change with date, R-item ID, and rationale. The "sealed" semantics are preserved by versioning: the original H-A1/H-A2 history is archived in the file's git log.

**Change C — Master plan + FINAL-CERTIFICATION updates (audit-trail).**

- `audit-trail-review/FINAL-CERTIFICATION-C.md` §3 L-AT-C-01: append a closure-note line documenting that R-AT-C-01 was closed via corpus realignment per this design.
- `audit-trail-review/PHASE-7-MASTER-PLAN.md` §5 R-AT-C-01: append closure status.

### What this does NOT change

- The auditor's extraction grep (`grep -oE 'framework/hooks/[a-zA-Z_-]+\.(sh|cjs|ps1)'`) remains as-is. R-AT-C-01 is corpus realignment, not auditor fix.
- The working corpus is untouched.
- The heldout extracted_set (17 hooks) is unchanged.
- The pristine framework files (project root `framework/hooks/destructive-guard.sh`, etc.) are untouched.

## §3. Blast radius

| File | Touched? | Lines | Consumers |
|------|---------:|------:|-----------|
| `.lab/apex-detector-lab-heldout/framework/hooks/memory-watchdog.sh` | RESTORED (new in lab) | ~30 lines (copy from parent) | Lab auditor; reverts H-A1 |
| `.lab/apex-detector-lab-heldout/framework/hooks/session-auto-resume.sh` | RESTORED (new in lab) | ~50 lines | Lab auditor; reverts H-A2 |
| `.lab/apex-detector-lab-heldout/framework/settings.json` | MODIFIED (×2 sections — restore SessionStart line + remove sequence-guard PreToolUse line) | ~4 net | Heldout lab runtime |
| `.lab/apex-detector-lab-heldout/framework/hooks/destructive-guard.sh` | DELETED | full file removed | New H-A1 mutation |
| `.lab/apex-detector-lab-heldout/framework/hooks/sequence-guard.sh` | DELETED | full file removed | New H-A2 mutation |
| `detector-review/manifests/HELDOUT-CORPUS.md.sealed` | MODIFIED (H-A1 + H-A2 manifest replacement + Phase-7 re-auth note) | ~80 lines changed | Future heldout trials |
| `audit-trail-review/FINAL-CERTIFICATION-C.md` §3 | MODIFIED (closure note) | +3 lines | Phase-7 closure tracking |
| `audit-trail-review/PHASE-7-MASTER-PLAN.md` §5 R-AT-C-01 | MODIFIED (closure status) | +3 lines | Phase-7 closure tracking |

**Per-consumer assessment:**

1. **Heldout lab auditor in Wave-4 re-run** — sees destructive-guard.sh + sequence-guard.sh missing via axis-1 mechanical enumeration. Both surface as per-hook P0 emissions (TP-C1 mechanism).
2. **Working corpus trials** — unaffected (no shared files).
3. **C5-T1..T10 historical trials** — remain valid evidence; R-AT-C-01 only affects FUTURE heldout trials.

## §4. Validation strategy (G4)

Empirical validation requires a heldout-lab trial. Per master plan, the Wave-4 collective re-run handles this. R-AT-C-01's G4 in isolation is:

1. **File-state validation:** `test -f` confirms restored hooks present; `test ! -f` confirms new mutation targets absent.
2. **Settings.json validation:** `grep -c session-auto-resume.sh` returns ≥1 (restored); `grep -c sequence-guard.sh` returns 0 (removed).
3. **Auditor extraction grep validation:** running the canonical extraction grep against the heldout spec returns ≥17 hooks INCLUDING `destructive-guard.sh` and `sequence-guard.sh`.
4. **Mechanical enumeration sanity check:** for each of the 17 hooks in extracted_set, `test -f .lab/apex-detector-lab-heldout/framework/hooks/<hook>` returns 0 EXCEPT for destructive-guard.sh (exit 1, P0 candidate) and sequence-guard.sh (exit 1, P0 candidate).

These four checks are mechanical (shell + grep + test). No agent invocation needed at G4.

## §5. G5 PASS criteria

Critic R2 PASS requires:
1. ✅ G4 validation 1-4 all PASS.
2. ✅ HELDOUT-CORPUS.md.sealed Phase-7 re-auth note present + new H-A1/H-A2 manifests reference IMP-014/018 (H-A1) and IMP-016 (H-A2).
3. ✅ Original H-A1/H-A2 manifest content preserved in git history (commit log + git blame on the file).
4. ✅ FINAL-CERTIFICATION-C.md §3 + PHASE-7-MASTER-PLAN.md §5 closure notes landed.
5. ✅ No collateral changes to working-corpus manifests, pristine framework files, or auditor agent files.

## §6. Implementation plan (G3 — single commit set)

5 atomic file operations + 1 commit:

1. Restore `memory-watchdog.sh` and `session-auto-resume.sh` in heldout lab (cp from project root).
2. Restore `session-auto-resume.sh` SessionStart line in heldout `settings.json` (insert at correct position).
3. Delete `destructive-guard.sh` and `sequence-guard.sh` in heldout lab.
4. Remove `sequence-guard.sh` PreToolUse:Bash line from heldout `settings.json`.
5. Update `detector-review/manifests/HELDOUT-CORPUS.md.sealed` H-A1/H-A2 entries + re-auth note.
6. Append closure notes to `FINAL-CERTIFICATION-C.md` §3 and `PHASE-7-MASTER-PLAN.md` §5.

Single commit: "R-AT-C-01: heldout corpus realignment (H-A1/H-A2 → destructive/sequence-guard)". Heldout lab gets its own commit in the lab's git history.

## §7. Out-of-scope

- Working corpus realignment (not needed).
- Auditor extraction grep fix (deferred to a future R-item if owner authorizes; out of R-AT-C-01 scope).
- Empirical heldout-lab T4/T5/T6 re-run — Wave-4 collective gate.

## §8. Decision summary

**Strategy:** corpus realignment per master plan §5. Two file deletions in heldout lab + settings.json wiring update + manifest re-author. Single commit.

**Blast radius:** 8 files (2 restored, 3 modified in lab, 2 deleted in lab, 1 manifest, 2 audit-trail). Minimal scope.

**Next gate:** G2 — critic R1.
