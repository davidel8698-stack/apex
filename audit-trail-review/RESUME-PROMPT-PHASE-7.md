# RESUME PROMPT — Phase 7 Main Session

> **For the next Claude Code session.** The owner opens a new clean session and pastes the first-prompt below. Everything you need is referenced from this document.

═══════════════════════════════════════════════════════════════════════
ENTRY STATE — 2026-05-25 (read this FIRST)
═══════════════════════════════════════════════════════════════════════

Phase 7 closes ALL open items from Campaigns A + B + C. 8 R-items + 1 empirical probe + 1 corpus re-run + 1 final closure.

**Owner's binding directives:**
- **No partial closure.** Every campaign must close PASS (not HALTED, not PASS-WITH-LIMITATION).
- **Strict QA standards.** Every R-item closure goes through 6-stage QA gate (G0-G5; see `PHASE-7-MASTER-PLAN.md` §1).
- **Quality solutions.** Deep research before design; design before implementation; critic review before close.
- **Empirical evidence at every gate.** No claims without verification.

═══════════════════════════════════════════════════════════════════════
THE 8 R-ITEMS (priority sequence)
═══════════════════════════════════════════════════════════════════════

**Wave 0 (DO FIRST — needs owner action):**
- R-AT-C-04 — AC-6b empirical probe via fresh independent agent. See `audit-trail-review/AC-6B-INDEPENDENT-PROBE-PROMPT.md`. Owner runs this in a SEPARATE Claude Code session and saves results to `audit-trail-review/AC-6B-INDEPENDENT-PROBE-FINDINGS.md`.

**Wave 1 — Campaign C closure (after Wave 0 results):**
- R-AT-C-02 — axis-13.d worked examples + round-checker enforcement (closes AC-5b)
- R-AT-C-01 — heldout corpus realignment (closes AC-4 heldout)
- R-AT-C-04 closure — based on Wave 0 outcome

**Wave 2 — Campaign A closure:**
- R-DH-P7-01 — Axis 13.c source-literal carve-out scan (closes L-DH-01)
- R-DH-P7-02 — Raise self-heal Step A budget 400→800 (closes L-DH-02)
- R-DH-P7-03 — test-subagent-cache.sh + fresh-session doc (closes L-DH-03)

**Wave 3 — Campaign B closure:**
- R-AT-P7-06 — Fix test-circuit-breaker-recovery.sh 3-FAIL + test-fix-plan-emit.sh 3-FAIL

**Wave 4 — Empirical re-validation:**
- R-AT-C-03 — verify truncation patch in fresh-session re-launch
- Full 11-trial corpus C5 re-run with ALL fixes installed
- C5-critic R2 final approval
- B5-critic R3 Gate B5 close

**Wave 5 — Trilogy closure:**
- Update FINAL-CERTIFICATION.md (A) + FINAL-CERTIFICATION.md (B) + FINAL-CERTIFICATION-C.md
- Tag commit `gate-b5-trilogy-passed`
- Memory file updates (all 3 campaigns marked CLOSED-PASS)

═══════════════════════════════════════════════════════════════════════
NON-NEGOTIABLE EXECUTION STANDARD (binding for every R-item)
═══════════════════════════════════════════════════════════════════════

For each R-item:

1. **G0 — Research:** Read existing spec + related code. Identify ROOT CAUSE, not symptom. Write 1-paragraph root-cause summary.
2. **G1 — Design:** Write a design document. Reference apex-spec.md anchors. Include blast-radius matrix.
3. **G2 — Critic R1:** Spawn `critic` agent in clean-room mode. Block on BLOCKING findings until R2 PASS.
4. **G3 — Implementation:** Atomic commits per file. Sync install copy (`~/.claude/`) from source.
5. **G4 — Test layer:** Empirical evidence (layer test OR live trial OR re-grep). 40/40 baseline; new tests for new mechanisms.
6. **G5 — Critic R2:** PASS verdict on the closed artifact. If FAIL → return to G1.

**No R-item closes without G5 PASS. No exceptions.**

═══════════════════════════════════════════════════════════════════════
HANDOFF PROTOCOL
═══════════════════════════════════════════════════════════════════════

If circuit-breaker fires OR context budget runs low mid-Phase-7:
1. Update `audit-trail-review/PHASE-7-STATE.md` with current R-item + G-gate progress
2. Commit checkpoint
3. Owner opens fresh session; reads PHASE-7-STATE.md; resumes from named gate

If a particular R-item proves intractable (e.g., R-AT-C-01 reveals deeper corpus design issue):
1. Document the discovery in `audit-trail-review/PHASE-7-DISCOVERY-NN.md`
2. Pause that R-item; continue to next R-item in wave
3. Resume the paused item after the wave completes (sometimes adjacent R-items inform the blocker)

═══════════════════════════════════════════════════════════════════════
ARTIFACT INDEX
═══════════════════════════════════════════════════════════════════════

**Read at session start:**
- `audit-trail-review/PHASE-7-MASTER-PLAN.md` — full Phase-7 plan
- `audit-trail-review/FINAL-CERTIFICATION.md` (Campaign B) — L-AT items
- `audit-trail-review/FINAL-CERTIFICATION-C.md` (Campaign C) — R-AT-C items
- `detector-review/FINAL-CERTIFICATION.md` (Campaign A) — L-DH items
- `audit-trail-review/EXPERIMENT-PROTOCOL-C.md` — binding AC thresholds

**Read per R-item (in G0):**
- Per the design notes in PHASE-7-MASTER-PLAN.md §5

**Write per R-item:**
- `audit-trail-review/PHASE-7-RITEM-<id>-DESIGN.md` (G1 output)
- `audit-trail-review/PHASE-7-RITEM-<id>-CRITIC-R1.md` (G2 verdict)
- `audit-trail-review/PHASE-7-RITEM-<id>-CRITIC-R2.md` (G5 verdict)
- Atomic commit per G3
- Layer test rows per G4

**Final wave:**
- `audit-trail-review/trials-c5-final/c5-*.md` (Wave 4 corpus re-run)
- `audit-trail-review/PHASE-7-FINAL-CERTIFICATION.md` (consolidated trilogy closure)

═══════════════════════════════════════════════════════════════════════
תתחיל.
