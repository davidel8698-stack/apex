# R-DH-P7-03 — Design (G1) · subagent-cache test + fresh-session doc

**Closes:** L-DH-03 (Subagent-cache contamination methodology confound).
**Spec anchor:** `detector-review/FINAL-CERTIFICATION.md` §3 L-DH-03 + EXPERIMENT-PROTOCOL.md §12 amendment 2026-05-24.
**Date:** 2026-05-26.

---

## §1. Root cause (G0)

Per `detector-review/FINAL-CERTIFICATION.md` §3 L-DH-03:

> "The Claude Code harness caches subagent definitions at session start; the post-install `framework-auditor.md` was not picked up by the cache. Phase 6 trials used the `general-purpose` subagent with the fixed definition embedded as the prompt body... Phase 2 baseline trials used the cached subagent directly. The mechanism comparison thus carries a small residual confound."

Closure plan:
1. Add `framework/tests/test-subagent-cache.sh` — synthetic cache-poisoning / staleness probe.
2. Document in `framework/docs/SECURITY-RUNTIME.md` the fresh-session requirement for subagent cache invalidation.

The test can only verify **structural state** (file system: source vs. installed copy drift). The behavioral aspect (Claude Code harness session-cache invalidation) is host-side and cannot be exercised from a shell test. The test scope is therefore: "verify that the installed `~/.claude/agents/specialist/framework-auditor.md` matches the source `framework/agents/specialist/framework-auditor.md` byte-for-byte — drift means the install copy is stale, and a fresh session would expose the divergence."

## §2. Design (2 changes)

### Change A — `framework/tests/test-subagent-cache.sh` (NEW)

Synthetic staleness probe. Asserts:

1. **Existence:** both source and installed copies of framework-auditor.md exist.
2. **Byte-equality:** `diff -q framework/agents/specialist/framework-auditor.md ~/.claude/agents/specialist/framework-auditor.md` returns 0 (no drift).
3. **Cache-buster marker presence:** the source file contains a synced-via-Phase-7 fingerprint (e.g., a comment line `# CACHE-BUSTER: <hash>` near the YAML frontmatter that increments on any content change). If absent, no fingerprint enforcement; the byte-equality check suffices.
4. **Round-checker counterpart drift check:** same for `round-checker.md`.
5. **Other specialist agents drift check:** same for `data.md`, `frontend.md`, `integration.md`, `security.md`, `batch-scheduler.md`, `batch-verifier.md`, `memory-synthesis.md`, `remediation-planner.md`.

Test runs as part of `framework/tests/run-all.sh`.

**Tool budget:** test is bash + diff + ls. ~50 lines total.

### Change B — `framework/docs/SECURITY-RUNTIME.md` — append §"Subagent cache invalidation"

New section at end of SECURITY-RUNTIME.md (~30 lines):

```markdown
## Subagent cache invalidation — fresh-session requirement (R-DH-P7-03)

**The Claude Code harness caches subagent definitions at session
start.** When a subagent's `~/.claude/agents/<name>.md` file changes
mid-session (e.g., after a `/apex:self-heal` round that strengthens
`framework-auditor.md` and syncs the install copy), the running
session continues to use the OLD definition until session restart.

This was the confound documented in detector-review/FINAL-
CERTIFICATION.md §3 L-DH-03: Phase 6 trials had to use
`general-purpose` with the strengthened definition embedded as
prompt body (rather than `framework-auditor` directly) because the
session's cached definition was stale.

**Operating requirement.** Production self-heal invocations
(`/apex:self-heal`) should run in a FRESH Claude Code session
after any framework-auditor / round-checker / specialist-agent
file change. This includes:

- Any commit that touches `framework/agents/specialist/*.md`
- Any commit that touches `framework/agents/*.md`
- Any commit that adds/removes a specialist agent

Verification: `framework/tests/test-subagent-cache.sh` checks
source-vs-install byte-equality on every CI run; drift indicates
the install copy is stale and a fresh session would expose the
divergence. The test does NOT verify session-cache invalidation
(host-side behavior); it verifies that the on-disk install state
matches the source.

**Mitigation pattern for in-flight detection rounds.** If a
session must continue with a strengthened agent definition mid-
round, use the `general-purpose` subagent with the strengthened
definition embedded as the prompt body (matches the Campaign A
Phase-6 mitigation; documented in
`detector-review/EXPERIMENT-PROTOCOL.md` §12 amendment 2026-05-24).
```

### Out-of-scope

- Behavioral test of the Claude Code harness's session-cache invalidation logic (host-side; cannot be exercised from shell).
- A cache-buster fingerprint mechanism in the agent files themselves (could be added if owner authorizes; not required for L-DH-03 closure).

## §3. Blast radius

| File | Touched? | Lines | Consumers |
|------|---------:|------:|-----------|
| `framework/tests/test-subagent-cache.sh` | NEW | ~50 | run-all.sh CI run |
| `framework/docs/SECURITY-RUNTIME.md` | MODIFIED (append) | +30 | Operators reading SECURITY-RUNTIME |
| `detector-review/FINAL-CERTIFICATION.md` §7 R-item 3 | MODIFIED (closure note) | +3 | Phase-7 closure tracking |
| `audit-trail-review/PHASE-7-MASTER-PLAN.md` §5 R-DH-P7-03 | MODIFIED (closure note) | +3 | Phase-7 closure tracking |

4 files.

## §4. G4 validation

1. `bash framework/tests/test-subagent-cache.sh` returns exit 0 with at least 10 PASS assertions (9 agents × byte-equality check + 1 existence check).
2. `bash framework/tests/run-all.sh` includes the new test in its summary; total CI test count increases by 1.
3. SECURITY-RUNTIME.md contains the new §"Subagent cache invalidation" heading.

## §5. G5 PASS criteria

1. ✅ test-subagent-cache.sh exists, runs PASS in isolation.
2. ✅ test runs in run-all.sh (not skipped, not BLIND SPOT).
3. ✅ SECURITY-RUNTIME.md has the new section + fresh-session requirement prose.
4. ✅ Closure notes in detector-review FINAL-CERT + PHASE-7-MASTER-PLAN.
5. ✅ No regression in existing 55/55 audit-trail layer tests + no regression elsewhere.

## §6. Implementation plan (G3 — 1 commit)

Single commit:
1. NEW: `framework/tests/test-subagent-cache.sh` with byte-equality assertions.
2. APPEND: SECURITY-RUNTIME.md §"Subagent cache invalidation".
3. Closure notes appended.
4. Sync test to `~/.claude/tests/` and doc to `~/.claude/docs/`.

## §7. Decision summary

**Strategy:** structural-state test (source-vs-install byte-equality) + doc section on fresh-session requirement. Behavioral cache test deferred as host-side scope.

**Blast radius:** 4 files. Minimal.

**Next gate:** G2 critic R1.
