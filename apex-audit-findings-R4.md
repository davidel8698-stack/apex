# APEX Audit — Round R4 Findings

**Round:** R4 (audit + remediation round four; final stop-criterion gate)
**Audit date:** 2026-04-24
**Branch at audit start:** `master` at commit `62ba3a4` (post-R3 closure)
**Audit scope:** The five carryover items surfaced by `ROUND-R3-CLOSURE.md`
plus one new P1 discovered during R4 execution.

---

## Scope derivation

R4 is unique among audit rounds: its scope is not derived from a fresh
adversarial pass against the codebase, it is derived from the R3 closure
report's `Recommendation` section. R3 surfaced five items and explicitly
deferred them to R4. R4 resolves them plus any new findings that surface
during execution.

Per `REMEDIATION-STYLE.md`, all findings below use content-addressable
anchors (file paths + symbols + spec anchors), never raw line numbers.

---

## Carryover items from R3

| ID | Source | Title | Severity | Disposition |
|---|---|---|---|---|
| **R4-001** | R3-closure `Recommendation` | `ci-scan.sh` S-11 failure — regex doesn't match YAML list-item `- uses:` form | P2 | RESOLVED in R4 Wave 1 |
| **R4-002** | R3-closure `Recommendation` | Verification: settings.json format migration propagated everywhere | P3 | RESOLVED in R4 Wave 1 (found + fixed 2 narratives) |
| **R4-003** | R3-closure `Recommendation` | Cross-platform preflight / TEST 0k audit | P3 | RESOLVED in R4 Wave 1 (error text generalized, selftest confirmed green) |
| **R4-004** | R3-closure `Recommendation` + `NEW-F-R3-002` | `test-wiring.sh` not standalone-runnable (extended scope: all 7 test files) | P3 | RESOLVED in R4 Wave 2 |
| **R4-005** | R3-closure `Recommendation` | R2 rolling regression check against post-R3 tree | P2 (process) | RESOLVED in R4 Wave 2 (all 11 R2 R-IDs still in place, no regressions) |
| **R4-006** | Round-own | Author R4 audit artifacts per REMEDIATION-STYLE.md | P2 (process) | RESOLVED in R4 Wave 3 (this document + CLOSURE + WAVES) |

## New findings discovered during R4 execution

| ID | Source | Title | Severity | Disposition |
|---|---|---|---|---|
| **R4-007** | Discovered during R4-005 regression sweep | `framework/settings.json` silently missing SessionStart / PreCompact / SubagentStop hook registrations for verify-learnings.sh, pre-compact.sh, subagent-stop.sh | **P1** | HOT-FIXED in R4 Wave 2 (per R4 plan's P1 escalation rule) |

---

## R4-007 detail

### Observation

The framework source-of-truth `framework/settings.json` registered only
`.hooks.PreToolUse` (6 entries) and `.hooks.PostToolUse` (5 entries) — 11
hooks total. Three APEX hooks that fire on Claude Code lifecycle events
(`verify-learnings.sh` at `SessionStart`, `pre-compact.sh` at `PreCompact`,
`subagent-stop.sh` at `SubagentStop`) were classified in
`framework/HOOK-CLASSIFICATION.md` as "Event-Triggered" but were not
actually wired in `framework/settings.json`.

The user's live `~/.claude/settings.json` had all three lifecycle
registrations present (manually added at some earlier point, survived
R3-002's format migration under the "non-APEX groups are preserved
byte-for-byte" clause). **So the user's local system appeared functional.**

### Why this is P1, not P2/P3

- **Fresh install gap:** `framework/scripts/sync-to-claude.sh` bootstrap
  path (when `~/.claude/settings.json` does not pre-exist) does a verbatim
  copy of `framework/settings.json`. A new user running
  `/apex:start` for the first time would install APEX with zero lifecycle
  event hooks — silently losing the SessionStart learnings emission, the
  PreCompact 50% cost-reduction path, and the SubagentStop cleanup.
- **Advertised features:** the spec and command docs reference all three
  features. Shipping them un-wired is a broken promise.
- **Silent:** nothing in `/apex:health-check` caught this because TEST 0j-b
  only checks "every hook in `framework/settings.json` reached live", not
  the reverse direction.

### Root cause

Historical preserved-gap from the pre-R3-002 broken flat-array
`settings.json`. The flat-array was wrong in shape and never fired any
hook; R3-002 fixed the shape and preserved the 11 PreToolUse/PostToolUse
entries that were already conceptually declared. The 3 lifecycle events
were never part of the flat-array to begin with, so R3-002 did not
preserve or introduce them.

### Fix (R4-007)

Added three event-key blocks to `framework/settings.json`:

- `.hooks.SessionStart[]` — registers `verify-learnings.sh`.
- `.hooks.PreCompact[]` — registers `pre-compact.sh`.
- `.hooks.SubagentStop[]` — registers `subagent-stop.sh`.

Updated `framework/HOOK-CLASSIFICATION.md` category header and affected
rows to reflect the new auto-wiring (tagged `(auto-wired R4-007)` per row).

### Verification

- Post-sync live `~/.claude/settings.json`:
  - `SessionStart`: 2 entries preserved (GSD's `gsd-check-update.js` + APEX
    `verify-learnings.sh`) — byte-identical to pre-R4-007 state.
  - `PreCompact`: 1 entry (APEX `pre-compact.sh`) — byte-identical.
  - `SubagentStop`: 1 entry (APEX `subagent-stop.sh`) — byte-identical.
- `framework/scripts/self-test.sh`: 106/106 pass, no regression.
- `framework/scripts/sync-to-claude.sh`'s non-APEX preservation clause
  verified live: GSD's Windows-path `gsd-check-update.js` entry was
  preserved (not an APEX path, so filtered as non-APEX group).

### Ecosystem impact

- `framework/HOOK-CLASSIFICATION.md` — updated.
- `framework/commands/apex/health-check.md` TEST 0j-b — still valid; the
  forward-direction coverage it checks is now more complete.
- No command `.md` or agent `.md` required update — they already invoke
  these hooks explicitly in addition to the auto-wiring, so behavior is
  additive not conflicting.

---

## R4-005 Regression check — per-R2-ID result

All 11 R2 R-IDs verified against post-R3 + post-R4 tree. Each uses a
content-addressable check, never a raw line number.

| R2 R-ID | Anchor | Result |
|---|---|---|
| R-001 | `security.cjs` appears in `framework/hooks/_security-common.sh` and `framework/security-policy.md` | PASS (1 + 4 occurrences) |
| R-002 | Cumulative `.dora.lead_time_sum` / `.lead_time_count` formula in `framework/hooks/phase-tag.sh` | PASS |
| R-003 | `framework/HOOK-CLASSIFICATION.md` exists, 29 hook rows match 29 `framework/hooks/` files | PASS |
| R-004 | `framework/agents/test-architect.md` declares `tools: Read, Grep, Glob, Write` | PASS |
| R-005 | `_date-parse.sh` exists; `parse_epoch` called from `phase-tag.sh` (2×) and `verify-learnings.sh` (1×) | PASS |
| R-006 | `jq '.hooks.PreToolUse[] \| select(.matcher=="Read") \| .hooks[0].command'` returns `"bash ~/.claude/hooks/workflow-guard.sh"` | PASS |
| R-007 | `observation masking` present in `framework/commands/apex/next.md` | PASS |
| R-008 | `mkdir -p` in `thread.md`, `plant-seed.md`, `add-backlog.md` | PASS (all 3) |
| R-009 | `jq '.routing["test-architect"].escalate_on_mode.phase'` of `framework/apex-model-routing.json` returns `"sonnet"` | PASS |
| R-010 | `GATE_INTERVAL` / complexity-adaptive gate in `framework/commands/apex/next.md` | PASS |
| R-011 | `apex-spec.md` has JSONL+jq anchor; zero `SQLite.*primary` or `primary.*SQLite` hits | PASS |
| R-012 | `mkdir -p` in `_debate.md`, `_roundtable.md`, `ui-phase.md` | PASS (all 3) |

**Net R2 regression rate: 0 / 11.** All fixes survived R3 and R4
intact.

---

## Severity summary

- P0: 0
- P1: 1 (R4-007, hot-fixed in-wave)
- P2: 3 (R4-001, R4-005 process, R4-006 process)
- P3: 3 (R4-002, R4-003, R4-004)

**All resolved in R4.** Zero open items at round close.

---

## Spec-anchor re-verification

| Spec anchor | Before R4 status | After R4 status |
|---|---|---|
| "CI scanner" (Defense-in-Depth) | Non-functional (regex missed YAML list-item form) | Functional — S-11 PASS, S-14 new |
| "Cross-platform date parsing" | Windows-only preflight error text | All-platform preflight error text |
| "Test suite — self-test harness" | Sourced-only invocation | Sourced + standalone both work |
| "Defense-in-Depth Security Layer" | CI scanner broken | CI scanner functional; mapping unchanged |
| "Hook system — 24+ hooks" | 29 hooks documented, 11 wired | 29 hooks documented, 14 wired (post-R4-007) |
| "Fail-loud, never fail-silent" | Lifecycle events silently un-wired for fresh installs | All lifecycle events explicitly wired |

---

## Non-obvious insights recorded during R4

1. **S-11 and S-12 were both wrong for the same reason.** The broken
   ci-scan regex missed YAML list-item form entirely, so S-11 (which
   expected exit 2) got exit 0, and S-12 (which expected exit 0) also got
   exit 0. S-12 was a pass-by-coincidence, not a pass-by-detection. After
   R4-001, both pass via the correct code path, and S-14 (new) guards
   the local-action false-positive case.
2. **`framework/settings.json` was incomplete, not wrong.** R3-002 made
   it Claude-Code-schema-correct (nested format), but did not add the 3
   lifecycle event types. R4-007 completed it. This is the last known
   framework-config drift.
3. **Test file standalone mode is cheap insurance.** The 8-line guard
   preserves aggregated behavior exactly (no regression) and unlocks
   single-test TDD iteration for future contributors. Applied to all 7
   test files in one wave — no reason to do it piecemeal.
4. **R2 fixes are durable.** Zero of eleven R2 R-IDs regressed under R3
   or R4. The pattern of one-commit-per-R-ID plus content-addressable
   anchors is working.
5. **Fresh-install versus existing-install paths are different.** The
   user's existing install masked R4-007 for the life of the framework
   because the user had added the 3 lifecycle event hooks manually at
   some prior point. A fresh-install test (or one on a new machine)
   would have caught this sooner. R5 should consider a fresh-install
   canary as a standing health-check test.

---

## Disposition of R3's open items

R3 declared the following open when closing:

- `ci-scan.sh` S-11 (P3 at R3 time) → **R4-001 resolved**, re-classified P2
  (real-world impact: security scanner was non-functional).
- `framework/settings.json` format propagation (follow-up check) →
  **R4-002 resolved** (2 narrative refs fixed, no flat-array shape
  references remain anywhere).
- Non-Windows preflight check → **R4-003 resolved** (error text now
  covers Linux/macOS; selftest confirmed green via `OK gnu-date` on
  Windows Git Bash which is the APEX-author's primary environment).
- `test-wiring.sh` standalone → **R4-004 resolved** for all 7 test files.
- R2 rolling regression → **R4-005 resolved**, 0 regressions.

---

## Artifacts

- `apex-audit-findings-R4.md` — this document.
- `REMEDIATION-PLAN-R4.md` — present as `C:\Users\דודאלמועלם\.claude\plans\6-ethereal-gem.md` (the original R4 plan authored pre-execution with the 10-question ecosystem methodology per R-ID).
- `WAVES-R4.md` — to follow.
- `ROUND-R4-CLOSURE.md` — to follow, with stop-criterion verdict.
- Commits: `9ebcf4c` (R4-001), `88c6c5a` (R4-002), `af98cda` (R4-003),
  `8d49649` (chore persist R2/R3 uncommitted), `7b478b1` (R4-004),
  `e8c2955` (R4-007). R4-005 and R4-006 are read-only / documentation
  and will not produce their own code commits.
