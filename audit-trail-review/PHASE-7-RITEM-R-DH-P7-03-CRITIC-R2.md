# R-DH-P7-03 — Critic R2 Verdict
**Verdict:** PASS
**Date:** 2026-05-26
**Reviewer:** clean-room critic R2
**Design under review:** `PHASE-7-RITEM-R-DH-P7-03-DESIGN-R2.md`
**Prior verdict:** R1 BLOCKING (`PHASE-7-RITEM-R-DH-P7-03-CRITIC-R1.md`) — 3 BFs (B-1 inventory wrong, B-2 core agents omitted, B-3 vacuous via sync).

---

## §0. Scope of R2 review

R2 changes only §2 Change A (the test) and §3/§5 (blast radius + PASS criteria). R1 §1, §4-§7 (criteria 1, 4, 6, 7) carry forward unchanged. R2 review focuses on whether the three BFs are closed by the proposed test rewrite.

---

## §1. BF closure verification

### BF-1 — Agent inventory completeness

**Required:** test must enumerate the agent surface by parsing sync-to-claude.sh's own delivery declarations (R10-001 pattern) rather than a hand-curated list.

**R2 §2 Change A approach:** two `find` loops mirroring sync-to-claude.sh's two delivery paths:
- **Loop 1** (lines 79-95): `find "$FRAMEWORK_ROOT/agents" -type f -name '*.md'`, dst computed as `$CLAUDE_ROOT/${rel}` where `rel="${src#$FRAMEWORK_ROOT/}"`. This is the operational inverse of `copy_tree "$FRAMEWORK_ROOT/agents" "$CLAUDE_ROOT/agents"` (sync-to-claude.sh:418).
- **Loop 2** (lines 98-118): `find "$FRAMEWORK_ROOT/modules" -mindepth 1 -maxdepth 1 -type d`, then `case "$mod_name" in _*) continue ;; esac`, then `[ -f "$agent_src" ] || continue`, then `short_name="${mod_name#apex-}"` and `dst="$CLAUDE_ROOT/agents/specialist/${short_name}.md"`. This is a faithful operational mirror of `copy_modules_specialists()` (sync-to-claude.sh:94-115).

**Filesystem ground-truth verification (this critic run):**
- `find framework/agents/ -type f -name '*.md'` returns 18 files: 12 at top level (architect, auditor, critic, executor, narrative-auditor, planner, ps-remediation-planner, ps-scheduler, ps-verifier, ps-wave-executor, spec-auditor, verifier) + 6 under specialist/ (batch-scheduler, batch-verifier, framework-auditor, remediation-planner, round-checker, wave-executor). Loop 1 will assert all 18.
- `find framework/modules/ -mindepth 1 -maxdepth 1 -type d` returns 11 dirs. The `_*` case skip filters `_schema` (1 dir). The `[ -f agent.md ] || continue` filter removes the 4 stub modules (apex-builder, apex-core, apex-fintech, apex-healthcare) that have no agent.md. Loop 2 iterates exactly the 6 active modules: apex-data, apex-frontend, apex-integration, apex-memory-synthesis, apex-security, apex-test-architect — strip `apex-` → dst at `$CLAUDE_ROOT/agents/specialist/{data,frontend,integration,memory-synthesis,security,test-architect}.md`.
- The two loops together assert 18 + 6 = 24 install destinations — every cached agent the L-DH-03 mechanism could affect.

**Specifically resolves the R1 complaints:**
- `data/frontend/integration/security/memory-synthesis` are now sourced from `framework/modules/apex-*/agent.md` (loop 2), not the wrong `framework/agents/specialist/` path the R1 design referenced.
- `wave-executor.md` is included via loop 1 (it lives at `framework/agents/specialist/wave-executor.md`).
- `test-architect.md` is included via loop 2 (it has source `framework/modules/apex-test-architect/agent.md` and is delivered as `specialist/test-architect.md`).

**BF-1: CLOSED.**

### BF-2 — Core agents drift check

**Required:** test must cover core agents under `framework/agents/*.md` (executor, critic, verifier, architect, planner, auditor, narrative-auditor, spec-auditor, and the 4 ps-* agents).

**R2 closure:** Loop 1 (`find "$FRAMEWORK_ROOT/agents" -type f -name '*.md'`) is unrestricted — it descends into specialist/ AND captures all top-level .md files. Each of the 12 named core agents is matched. The dst path computed (`$CLAUDE_ROOT/agents/${rel}` with rel like `executor.md`) is exactly the path `copy_tree "$FRAMEWORK_ROOT/agents"` writes.

**Verified by direct enumeration:** the find result above shows all 12 core agents the R1 critic named are present in the source tree and will be iterated by loop 1. No bypass, no exclusion.

**BF-2: CLOSED.**

### BF-3 — Vacuous-via-sync (mtime axis)

**Required:** add an mtime signal that survives the IMP-036 first-deployment gate path (sync-then-test in same CI run).

**R2 closure:** line 90 — `if [ "$src" -nt "$dst" ]; then nope "...mtime FAIL..."; continue`.

**Mtime semantics walkthrough (per critic prompt):**

| Scenario | src.mtime | dst.mtime | `src -nt dst` | Test verdict | Correct? |
|----------|-----------|-----------|---------------|--------------|----------|
| A: source edited (T=100), sync ran later (T=200), test (T=300) | 100 | 200 | FALSE | PASS | YES — no drift |
| B: sync ran (T=100), source edited later (T=200), test (T=300) | 200 | 100 | TRUE  | FAIL | YES — staleness caught |
| C: source and dest exactly equal mtime (cp -p / atomic same-clock-tick) | 100 | 100 | FALSE | PASS | YES — acceptable |

**Cp behavior confirmation:** `copy_file` (sync-to-claude.sh:64) calls `cp "$src" "$dst"` without `-p`. Default `cp` stamps dst with the **current time**, which is strictly later than src.mtime in any practical post-sync state. So Scenario A is the normal post-sync state and PASSes correctly; Scenario B is the exact L-DH-03 drift signal the test is meant to catch (someone edited source mid-session after sync, but install copy and subagent-cache are now stale).

**IMP-036 CI path interaction:** when sync runs at T=k and test runs at T=k+epsilon, dst was written by `cp` at T=k (post-sync clock), so dst.mtime > src.mtime (which is whatever pre-existing source mtime, ≤k). Therefore `src -nt dst` is FALSE → PASS, BUT this is now non-vacuous because the byte-equality and mtime axes together encode "no drift exists in either dimension at the moment of test." A subsequent edit to source between sync and the next test run would flip the mtime axis. The vacuous-trivial-equality failure mode R1 identified is structurally addressed.

**BF-3: CLOSED.**

---

## §2. Adversarial probes

**Probe X1 — `_*` private hook helpers at agent level.** Filesystem check: `find framework/agents -mindepth 1 -maxdepth 1 -type d` returns only `specialist/`. No `_internal/` or `_helpers/` directories exist; no `_*.md` files at agent level. The case-skip pattern in loop 2 covers the only `_*` entity in scope (`framework/modules/_schema`). **No exposure.**

**Probe X2 — `find … -name '*.md'` matches backup `.md.bak`?** `fnmatch` glob `*.md` requires the name to END in `.md`. `something.md.bak` does NOT match `*.md` (it matches `*.bak`). Filesystem check: no `.md.bak` files currently exist under `framework/agents/`. Future backup files would NOT be picked up. **No exposure.**

**Probe X3 — Loop 1 catches `framework/agents/specialist/wave-executor.md` AND loop 2's iteration of any apex-wave-executor module produces specialist/wave-executor.md → double-count or conflict?** Filesystem check: there is no `framework/modules/apex-wave-executor/` directory. The 6 modules with agent.md produce 6 destinations (data, frontend, integration, memory-synthesis, security, test-architect) — none collide with the 6 source files under `framework/agents/specialist/` (batch-scheduler, batch-verifier, framework-auditor, remediation-planner, round-checker, wave-executor). The two loops cover disjoint destinations. No double-count.

**Probe X4 — Pre-flight SKIP false positive.** Line 66 — `if [ ! -d "$CLAUDE_ROOT/agents" ]; then skip ...; exit 0`. Honors the first-run-before-sync scenario R1 N-3 raised. Acceptable.

**Probe X5 — `set -u` interaction with empty PASS/FAIL counters.** All counters initialized at lines 56-58. Loops use `IFS= read -r` with redirected stdin from `find`. No unset-var risk.

**Probe X6 — Stale modules with stale orphans in install tree.** If `framework/modules/apex-x/agent.md` is deleted but `$CLAUDE_ROOT/agents/specialist/x.md` lingers, the test does not flag it (test enumerates source-side, not destination-side). This is a **gap of a different class** — orphan detection is not in scope for L-DH-03 (which concerns drift between live source and cache). Out of scope for this R-item; non-blocking.

---

## §3. Other criteria (carry-forward from R1)

R1 §1, §4, §6, §7 verdicts (criteria 1, 4, 6, 7) carry forward — R2 does not alter those surfaces. R1 N-1 (mtime axis) is now implemented as part of BF-3 closure. R1 N-2 (topic-shift note in SECURITY-RUNTIME.md) and N-3 (pre-flight SKIP) remain — N-3 is implemented at line 66; N-2 is a non-blocking suggestion the implementer can fold into Change B prose.

---

## §4. Final verdict

**PASS.**

All three R1 blocking findings are structurally closed by the R2 test rewrite:
- B-1 closed by the two-loop dynamic enumeration mirroring sync-to-claude.sh's delivery declarations (loop 1 = copy_tree inverse; loop 2 = copy_modules_specialists inverse), verified against filesystem ground truth (18 + 6 = 24 destinations covered).
- B-2 closed by loop 1 being unrestricted under `framework/agents/`, catching all 12 named core agents.
- B-3 closed by the `[ src -nt dst ]` mtime axis. Walked through Scenarios A/B/C; all three give correct verdicts. cp(1) default-mtime semantics confirmed compatible.

Adversarial probes X1-X5 pass; X6 identifies an orphan-detection gap that is out of scope for L-DH-03 and not raised by R1 — explicitly non-blocking.

Outstanding non-blocking items: N-2 (one-line topic-shift note at the head of the new SECURITY-RUNTIME.md section) and N-5 (assertion-count strengthening in §5 G5). Both are quality-of-life polish, not gates. Implementer may fold them in at G3 without re-review.

**Ready for G3 implementation.**
