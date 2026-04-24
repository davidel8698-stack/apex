# Round R2 Closure Report

**Status:** CONTINUE TO R3

---

## Coverage

- Total F-IDs in R2: 11
- Fixed (DONE): 10  (R-001, R-002, R-003, R-004, R-005, R-006, R-007, R-008, R-009, R-010)
- WONTFIX: 0
- Deferred: 1  (R-011 — spec amendment vs SQLite+FTS5 implementation — pending human direction)
- Reverted and unresolved: 0

All R1 findings (28) had documented disposition in the R2 audit: 19 RESOLVED, 4 PARTIAL (rolled into R2-F-001/002/003/007), 2 STILL OPEN (rolled into R2-F-010/011), 3 RECLASSIFIED (SC-002, SC-003, ROADMAP).

## Severity breakdown of remaining issues

- P0: 0
- P1: 0
- P2: 3   (R-011 deferred; NEW-F-W2-002/W3-004 circuit-breaker noise; NEW-F-W2-003 sync-to-claude settings.json gap)
- P3: 7   (NEW-F-W2-001, NEW-F-W2-004, NEW-F-W3-001, NEW-F-W3-002, NEW-F-W3-003, /apex:todo mkdir suspicion, _date-parse.sh Python dependency)

## Spec anchors still uncovered

- "State management hybrid: Markdown + SQLite+FTS5" — implementation uses JSONL+jq. R-011 deferred pending human decision (amend spec vs. build SQLite).
- "PEP 420 namespace" — SC-003 reclassified as N/A (APEX is markdown/bash, not Python) but the text is still present in the spec.

## New findings for R3 (deduplicated)

1. NEW-F-W2-001 (P3) — `framework/tests/test-wiring.sh:15` loops `micro` instead of `fast` after the rename; C-4 fails persistently.
2. NEW-F-W2-002 = NEW-F-W3-004 (P2) — `framework/hooks/circuit-breaker.sh` emits "blocking error / No stderr output" on every Bash call. Violates "Fail-loud, never fail-silent".
3. NEW-F-W2-003 (P2) — `framework/scripts/sync-to-claude.sh` excludes `settings.json`. New hook wirings (e.g., R-006 workflow-guard) do not reach user installs without manual merge. Defeats Defense-in-Depth in deployed state.
4. NEW-F-W2-004 (P3) — R-007 remediation plan line refs (`next.md:312`, `316-338`) target a pre-Wave-1 snapshot. Process signal: use content-addressable anchors, not raw line numbers.
5. NEW-F-W3-001 (P3) — `framework/hooks/workflow-guard.sh:4` header still says "Hook type: Explicit invocation by /apex:workflow (NOT auto-fired)" after R-006 auto-wired it in settings.json.
6. NEW-F-W3-002 (P3) — REMEDIATION-PLAN-R2.md §R-003 says "28 files"; current count is 29 (R-005 added `_date-parse.sh`). Cosmetic.
7. NEW-F-W3-003 (P3) — `resolve_model()` in `next.md:163` is pseudocode interpreted by the AI, not executable. No automated test can validate routing changes.
8. (carried from REMEDIATION-PLAN-R2 "New findings during planning") /apex:todo may share R-008's missing `mkdir -p` gap; never investigated.
9. (carried from REMEDIATION-PLAN-R2) `_date-parse.sh` Python fallback creates a soft Windows dependency; no onboarding check confirms Python is in PATH.
10. SC-003 spec-text cleanup — remove or mark-as-N/A the "PEP 420 namespace" line in `apex-spec.md`.

## Trajectory

- R1 P0+P1 count: 12  (4 P0 + ~8 P1 at R1 audit time)
- R2 P0+P1 count: 2   (0 P0 + 2 P1 — R2-F-004 test-architect tools, R2-F-005 cross-platform date; both fixed in Wave 1)
- Convergence trend: IMPROVING

P0 eliminated entirely (4 → 0). P1 reduced ~75% (8 → 2) and all fixed in the same round. Remaining issues are documentation gaps, deployment plumbing, and one deferred spec direction.

## Recommendation

- [ ] Declare loop closed
- [x] Run R3 with seed audit focused on:
  - **Hook wiring deployment path** — NEW-F-W2-003 + NEW-F-W3-001 indicate the `framework/ → ~/.claude/` bridge is fragile; audit `sync-to-claude.sh`, settings merge strategy, and all stale "Hook type:" comments in hooks touched by R2.
  - **`circuit-breaker.sh`** — NEW-F-W2-002/W3-004; one of only two P2 non-deferred issues, and it's actively polluting operator experience.
  - **Defensive mkdir across all commands** — generalize R-008; audit every command that writes under `.apex/` to confirm target directory is ensured.
  - **Test/code drift** — NEW-F-W2-001 + NEW-F-W3-002 point to test suites and plan artifacts lagging rename/add commits. Sweep `framework/tests/` for stale path refs.
  - **`apex-spec.md` amendment decision (R-011)** — requires human direction before remediation. Flag as blocker at audit time so it isn't silently re-deferred.
  - **Windows runtime preflight** — `_date-parse.sh` Python dependency; any other hook that silently degrades on Windows.
  - **`/apex:todo` mkdir parity** — close the suspicion flagged in REMEDIATION-PLAN-R2.
- [ ] Escalate to human — only for R-011 direction, not for the loop as a whole

Stop criterion requires two consecutive rounds with 0 P0 **and** 0 P1. R2 produced 2 P1 findings, so R2 is not a clean round. Earliest possible closure is after R4 (R3 must be clean, then R4 must also be clean). Trajectory is strongly improving; no contradictions or divergence observed.
