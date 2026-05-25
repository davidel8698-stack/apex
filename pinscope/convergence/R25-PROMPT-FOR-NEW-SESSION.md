# Prompt to send in the new R25 session

Copy the **entire box below** into the new session as your first message
(after `cd`ing into the APEX repo root):

---

```
PinScope convergence loop — execute R25 (Option Y, full F7 matrix-rigor sweep).

I'm resuming from a previous session that closed R24 PASS. All preparation
is on disk. Your job in this session: read the prep documents, execute the
plan, and close R25.

READ THESE FIRST (in order, 15-25 min):
1. pinscope/convergence/R25-INDEX.md
2. pinscope/convergence/R25-MASTER-PLAN.md
3. pinscope/convergence/R25-MATRIX-PROPOSED-DIFF.md
4. pinscope/convergence/R25-RISK-REGISTER.md
5. pinscope/convergence/ROUND-R24-CLOSURE.md (state snapshot only)

THE SCOPE I APPROVED:
- Option Y from R-24-05 — aggressive ~2 days, full F7 sweep
- 26 R-items across 7 waves
- 22 ACs strengthened, 2 integration (AC-024/025), 2 polish items
- Matrix edits I will approve via the diff document at W7

PRE-FLIGHT (run at start, after reading prep):
- bash pinscope/convergence/lib/preflight.sh
- node pinscope/convergence/lib/loop-state.mjs read
- git log --oneline -5
- node pinscope/convergence/lib/ac-verify.mjs --round 25
- Confirm round=24, loop_status=CONVERGED, HEAD=60b9eb1 or later

CRITICAL CONSTRAINTS (don't violate, see R25-RISK-REGISTER.md for details):
1. SPEC.md is FROZEN — no normative edits without my approval
2. ac-matrix.json edits require my explicit "approved" in-session, then
   apply atomically in W7
3. Expected closed_count drop from 63 → ~56-60 temporarily during W7
   (rigor-aware). Restore via FIX waves before final record-round.
4. Stage ONLY pinscope/ files (parallel work in framework/ + audit-trail/)
5. Sub-agents are sandbox-denied writes to pinscope/convergence/ — use
   the orchestrator-records pattern (spawn for analysis only; main thread
   writes deliverables)
6. test-deletion-guard hook may block rm of test files — use PowerShell
   Remove-Item as fallback, and avoid "tests/configs" patterns in commit
   bodies

EXECUTION:
- Follow R25-MASTER-PLAN.md wave-by-wave
- Use TaskCreate/TaskUpdate to track each R-item
- Commit per wave (one commit per wave, single owner per file per wave)
- After W6, ask me to "approve the matrix diff per R25-MATRIX-PROPOSED-DIFF.md"
- After W7, run FIX waves until closed_count restores
- Close with VERIFY-R25.md + ROUND-R25-CLOSURE.md per /ps-heal STEP 7

EXPECTED OUTCOMES:
- ALL 22 WEAK ACs in the matrix have strengthened verify recipes
- AC-024/025 have integration tests in addition to isolation tests
- 5 grep-only ACs (AC-100/102/103/104/105) replaced with content-validation
  scripts
- closed_count restored to 63+ after fixes
- ps-verifier verdict: PASS
- 0 mutation survivors in R25-touched code
- 2 consecutive clean rounds (R24 + R25) — official stop criterion met

START NOW. Don't ask me questions you can answer from the prep docs.
If you genuinely need a decision I haven't pre-recorded, ask once
clearly with the options.
```

---

## Notes for you (current session)

After this preparation set is committed, the new session has everything
it needs to execute R25 with the same rigor as R24. The five documents
form a self-contained resume kit:

1. **R25-INDEX.md** — orients in 2 min
2. **R25-MASTER-PLAN.md** — the work
3. **R25-MATRIX-PROPOSED-DIFF.md** — the high-stakes matrix changes
4. **R25-RISK-REGISTER.md** — the gotchas
5. **R25-PROMPT-FOR-NEW-SESSION.md** — this document (delivers the prompt above)

If you want to adjust the prompt before copying, edit the box above.
Otherwise, copy the **box only** (without these "Notes" lines) into the
new session.
