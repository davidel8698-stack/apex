# APEX Hook Classification

**Purpose:** Catalog every file in `framework/hooks/` by trigger type, so a
developer can answer "how does this hook fire?" without cross-referencing
`framework/settings.json` and 44 command `.md` files.

**Total files:** state-derived — verify with
`ls framework/hooks/ | wc -l` (the file-system count is the authority).
At the time of writing this section the count is 46, comprising 28
functional `.sh` hooks (R5-013 added `owner-guard.sh`; R5-016 added
`decision-gate.sh`; v7.1 added `memory-watchdog.sh`,
`turn-checkpoint.sh`, `session-auto-resume.sh`) + 13 library `.sh`
files (`_`-prefixed; R5-014 added `_fix-plan-emit.sh`; R6-017 added
`_adapter-detect.sh`; v7.1 added `_require-platform-detect.sh`) + 1
Python helper + 3 CommonJS guards (R5-003: `apex-prompt-guard.cjs`,
`apex-workflow-guard.cjs`, `security.cjs`; R6-014 prefixed the two
ported guards with `apex-` to match the spec literal naming). Category
totals below sum to the verified count. The CI assertion in
`framework/tests/test-hook-classification.sh` (R7-011) re-derives the
count on every run and FAILs on doc/filesystem drift, so future
additions cannot silently outpace this paragraph.

**Spec anchor:** `apex-spec.md` — "Hook system — 24+ hooks" and
"Fail-loud, never fail-silent."

---

## Trigger Types

| Type | How it fires | Config source |
|---|---|---|
| **Auto-PreToolUse** | Claude Code runtime fires before a matching tool call | `framework/settings.json` entries under `.hooks.PreToolUse[]` |
| **Auto-PostToolUse** | Claude Code runtime fires after a matching tool call | `framework/settings.json` entries under `.hooks.PostToolUse[]` |
| **Command-Invoked / Event-Triggered** | Explicit `bash ~/.claude/hooks/<name>.sh ...` from a command `.md`, another hook, or a Claude Code event (SubagentStop, PreCompact, SessionStart) | Command `.md` files or Claude Code event wiring |
| **Library — Sourced** | Never invoked directly; sourced via `source "$(dirname "$0")/<name>.sh"` by other hooks | `_`-prefix convention |

---

## Auto-PreToolUse (7)

| File | Matcher | Purpose |
|---|---|---|
| `destructive-guard.sh` | `Bash` | v7 hardened destructive command blocker — normalized matching, chained-command splitting. Exit 2 on rm -rf, force pushes, etc. |
| `prompt-guard.sh` | `Write\|Edit\|Agent` | Prompt-injection detection (instruction override, role hijacking, hidden HTML, zero-width chars). Exit 2 on match. **Dual-runtime (R5-003):** `.cjs` preferred, `.sh` shim falls back to native Bash when node absent. Settings.json invocation is runtime-aware (`if command -v node ... node apex-prompt-guard.cjs; else bash prompt-guard.sh; fi`). R6-014 prefixed the .cjs payload with `apex-`; the .sh shim name is preserved per the R5-003 + R6-014 preservation contract. |
| `path-guard.sh` | `Write\|Edit` | Path traversal and sensitive-file protection (.env, credentials, .git/*, parent-dir escapes). Exit 2 on match. |
| `owner-guard.sh` | `Write\|Edit` | One-file-one-owner enforcement (R5-013). Reads `APEX_CURRENT_TASK_ID` + `.apex/phases/<phase>/WAVE_MAP.json`; blocks writes to paths outside the active task's `owns_files`. Fast-path exit 0 when `APEX_CURRENT_TASK_ID` is unset (manual edits never gated). Advisory mode by default (exit 1) per the human-decision flag in REMEDIATION-PLAN-R5.md §R5-013; set `APEX_OWNER_GUARD_BLOCKING=1` to upgrade to exit 2. Spec anchors: "One-file-one-owner עם git worktree isolation" + "Read-parallel, write-serial עם Vertical Slices Enforcement." |
| `pre-task-snapshot.sh` | `Bash` | Git stash snapshot before task execution — enables per-task rollback. |
| `quarantine-guard.sh` | `Read\|Bash` | Agent-aware file access control. When `APEX_ACTIVE_AGENT=auditor`, restrict reads to test files and `.apex/` state. Microsecond pass-through otherwise. |
| `workflow-guard.sh` | `Read` | Workflow-recipe injection scanner (post-R-006 auto-wiring). Self-filters non-workflow paths. Also invoked explicitly by `/apex:workflow`. **Dual-runtime (R5-003):** `.cjs` preferred, `.sh` shim falls back to native Bash when node absent. |

Source: `framework/settings.json` entries under `.hooks.PreToolUse[]` (each entry has `matcher` and a nested `hooks:[{"type":"command", ...}]` array per Claude Code's native schema).

---

## Auto-PostToolUse (9)

| File | Matcher | Purpose |
|---|---|---|
| `post-write.sh` | `Write\|Edit` | Secret detection on written source files (BLOCKING — exit 2 on high-confidence match). |
| `schema-drift.sh` | `Write\|Edit` | Validates `.apex/` JSON state files against expected schemas after every write. |
| `ast-kb-check.sh` | `Write\|Edit` | AST/KB hallucination gate — import validation. Advisory (exit 1, not 2). Rationale: dynamic-import resolution produces high false-positives; signal consumed by critic.md, which makes the actual block decision. |
| `phantom-check.sh` | `Write` | Blocks phase advancement when SUMMARY.md contains uncertainty language (e.g., "should work", "might pass"). |
| `circuit-breaker.sh` | `Bash` | v7 total tool-call cap + enhanced loop detection. Interrupts runaway sessions. |
| `ci-scan.sh` | `Write\|Edit` | Supply-chain vector scanner for `.github/workflows/*.yml` (R5-010). Self-filtered: parses Claude Code hook stdin payload, exits 0 fast when the touched path is outside `.github/workflows/`. Exit 2 on detected vectors (unpinned actions, secret exposure, write-all permissions, unsafe `pull_request_target`). Also retains command-invoked usage. |
| `tdad-index.sh` | `Write\|Edit` | Builds code-test dependency graph for TDAD impact analysis (R5-011). **Auto-wired:** SessionStart (rebuild on session start) + Auto-PostToolUse Write\|Edit (rebuild after source-file edits). Debounced via freshness guard: when `.apex/TEST_MAP.txt` is newer than every source file, exits 0 fast. Also retains command-invoked usage from `/apex:next` (after architect). Index-building logic unchanged — only the freshness guard is new. |
| `memory-watchdog.sh` | `Bash` | v7.1 Auto-Continuity Layer C — pre-OOM in-process Bun/Claude Code memory sampler. Throttled internally by `memory_sample_interval_seconds` (default 30s). Always exit 0; fail-loud-and-skip on platform issues. Side effects: updates `.apex/STATE.json` (`session.memory.*`), appends `memory_sample` events to `.apex/event-log.jsonl`, creates `.apex/AUTO_PAUSE_REQUEST.flag` when `consecutive_over_threshold` reaches the debounce limit. Auto-pause is *consumed* by `/apex:next` Step F.4 — this hook only requests it. |
| `turn-checkpoint.sh` | `Bash` and `Write\|Edit` | v7.1 Auto-Continuity Layer B — fine-grained turn-level checkpoints for `/apex:recover` option 6. Throttled by `turn_checkpoint_interval` (default: every 5 tool calls). Must run AFTER `circuit-breaker.sh` so `total_tool_calls_this_task` is fresh. Always exit 0. Side effects: atomic temp+mv replace of `.apex/TURN_CHECKPOINT.json`, mirrors to `.apex/STATE.json` `.turn_checkpoint`, appends `turn_checkpoint_set` event to event-log. |

Source: `framework/settings.json` entries under `.hooks.PostToolUse[]` (each entry has `matcher` and a nested `hooks:[{"type":"command", ...}]` array per Claude Code's native schema).

---

## Command-Invoked / Event-Triggered (15)

Hooks that fire via explicit invocation from command `.md` files, from other
hooks, or from Claude Code lifecycle events.

**Auto-wired via `settings.json` (post-R4-007 + R5-004 + R5-011 + v7.1):**
`state-rebuild.sh` (SessionStart, conditional — fires before verify-learnings
when STATE.json missing), `verify-learnings.sh` (SessionStart), `pre-compact.sh`
(PreCompact), `subagent-stop.sh` (SubagentStop), `tdad-index.sh` (SessionStart
+ PostToolUse Write|Edit, debounced via freshness guard, R5-011),
`cross-phase-audit.sh` (SubagentStop, gated to `agent_name=executor`,
R5-011), `session-auto-resume.sh` (SessionStart, v7.1 — runs after
state-rebuild, before verify-learnings). The remaining 6 are command-invoked
only — not in `settings.json`.
(R5-010: `ci-scan.sh` was promoted from this section to **Auto-PostToolUse** —
see the row above. R5-011: `tdad-index.sh` and `cross-phase-audit.sh` are
listed in BOTH the Auto-PostToolUse table above and in this section, because
they retain command-invoked call sites in `/apex:next` and `/apex:validate-phase`
in addition to the new auto-wirings.)

| File | Invoked by | Purpose |
|---|---|---|
| `phase-tag.sh` | `/apex:next`, `/apex:ship` | Creates git tag for completed phase; updates DORA metrics in STATE.json (cumulative avg post-R-002, cross-platform date parsing post-R-005). |
| `verify-learnings.sh` | `/apex:next`, SessionStart event (auto-wired R4-007) | v7 tiered enforcement + decay-class-aware staleness; SessionStart emits HOT/WARM counts. |
| `cross-phase-audit.sh` | `/apex:validate-phase`, `/apex:next`, SubagentStop event (auto-wired R5-011, executor only) | Runs all prior-phase tests to catch regressions before advancing. R5-011: also fires automatically on SubagentStop when `agent_name=executor` (signals phase progression). Other agents pass through. Replay logic unchanged. |
| `mutation-gate.sh` | `/apex:next` (after critic PASS on verify_level C/D) | Mutation-testing gate. |
| `context-monitor.sh` | `/apex:next`, `/apex:status`, `/apex:pause`, `/apex:resume` | Real-token counting from STATE.json; compact at 50–60%, rotate at 70%. |
| `session-log.sh` | Many commands and hooks | APEX Session Guardian — appends events to `.apex/SESSION-LOG.md`. Shared logging primitive. |
| `generate-task-map.sh` | `/apex:next` | Generates task map using jq + git. |
| `tdad-index.sh` | `/apex:next` (after architect), SessionStart event (auto-wired R5-011), PostToolUse Write\|Edit (auto-wired R5-011, debounced) | Builds code-test dependency graph for TDAD impact analysis. R5-011: also fires automatically on SessionStart and on Write\|Edit; freshness guard short-circuits when `.apex/TEST_MAP.txt` is newer than every source file. Builder logic unchanged — only the guard is new. |
| `tdad-impact.py` | `tdad-index.sh`, `/apex:next` | Python helper — given changed files, find impacted tests via `.apex/TEST_MAP.txt`. |
| `pre-compact.sh` | PreCompact event (auto-wired R4-007, Claude Code runtime) | v7 observation-masking tracking; 50% cost reduction at neutral/positive quality. Backs up state to `.apex/backups/`. |
| `subagent-stop.sh` | SubagentStop event (auto-wired R4-007, Claude Code runtime) | Subagent lifecycle cleanup; reads agent_name from stdin JSON. |
| `state-rebuild.sh` | SessionStart event (auto-wired R5-004, conditional) + `/apex:recover`, `/apex:resume` | Reconstructs `.apex/STATE.json` from `event-log.jsonl` + phase summaries. Fast-path exits 0 when STATE.json exists; fires only when the file is missing. Spec anchor: "State derives from disk." |
| `agent-lint.sh` | `/apex:new-agent` (post-scaffold validation, R5-021) | Validates that a generated module under `framework/modules/<name>/` conforms to the manifest schema (R5-001) and the agent prompt conventions (frontmatter complete: name/description/tools; required sections: Role, Domain Invariants, Named Failure Prohibitions, Output Contract; no registry collision). On failure, writes a `FIX_PLAN.md` listing every issue with concrete fix steps and exits 2; on success, exits 0. |
| `decision-gate.sh` | `/apex:next` (top of cycle, R5-016) | User-visible 60/90-minute decision gate. Reads `STATE.session.started_at` + `STATE.session.last_time_gate` + `STATE.complexity_level`. Fires when elapsed >= 60 min AND cadence interval has elapsed since last gate (90/75/60 min by complexity 1-2/3/4+). On fire: writes `.apex/FIX_PLAN.md` with three options (continue / /apex:pause / /apex:resume), updates `STATE.session.last_time_gate` (debounce), and exits 1. On non-fire: exits 0 silently. Spec anchor: "Decision gates פר 60-90 דקות." |
| `session-auto-resume.sh` | SessionStart event (auto-wired v7.1, after `state-rebuild.sh`, before `verify-learnings.sh`) | v7.1 Auto-Continuity Layer A — detects when the previous session was auto-paused or has a fresh turn-checkpoint, and writes `.apex/SESSION_BOOT.md` + emits a stdout banner instructing Claude to invoke `/apex:resume` in the new session. Closes the auto-pause→auto-resume cycle without manual intervention. Always exit 0; no-op if `.apex/STATE.json` missing or session not auto_paused. Side effects: replaces `.apex/SESSION_BOOT.md`, appends `session_auto_resumed` event to event-log. |

**Note:** Grep across `framework/commands/apex/` returns 51 invocation sites
across 15 command files — `/apex:next` alone invokes 34 of these. See the
command `.md` files for exact invocation points.

---

## Library — Sourced (13)

Files prefixed with `_` — utility libraries sourced by other hooks.
**Never invoked directly.**

| File | Provides | Sourced by |
|---|---|---|
| `_require-jq.sh` | `require_jq` — fails hook with a fix message if jq missing | Most JSON-manipulating hooks |
| `_require-git.sh` | `require_git` — fails hook if git unavailable | Git-using hooks |
| `_security-common.sh` | `_sec_normalize`, `_sec_pattern_match`, `_sec_block` — shared security primitives | All 5 guard hooks (prompt/path/workflow/destructive/quarantine) |
| `_state-read.sh` | Point-in-time STATE.json snapshot for consistent reads within one invocation | Hooks that read STATE multiple times |
| `_state-update.sh` | Atomic STATE.json update with error handling | Hooks that mutate STATE |
| `_date-parse.sh` | `parse_epoch` — portable date→epoch (GNU → BSD → Python3 → Python2) | `phase-tag.sh`, `verify-learnings.sh` (post-R-005) |
| `_dream-cycle-emit.sh` | `start \| complete \| fail` phases for memory-synthesis dream-cycle wraps; emits structured START/COMPLETE/FAIL JSONL with a correlation id (R5-023) | `/apex:next` (two invocation sites) |
| `_state-sqlite.sh` | `_state_sqlite_mirror`, `_state_sqlite_status` — opt-in SQLite mirror over STATE.json + event-log.jsonl when `APEX_SQLITE_MIRROR=1` and `sqlite3` CLI present (R5-002). Fail-loud-and-skip when CLI absent. | `_state-update.sh` (conditional) |
| `_agent-dispatch.sh` | `apex_dispatch_enter <agent>` / `apex_dispatch_exit` — sets/unsets `APEX_ACTIVE_AGENT` so the quarantine guard fires structurally on every auditor invocation, regardless of which command invoked it (R5-009). Also exposes `enter` / `exit` subcommands for non-sourcing callers. | `/apex:next` (auditor dispatch site); future agent-quarantined call sites |
| `_learnings-emit.sh` | `emit_learning <event_type> <phase> <summary>` — appends a structured WARM-section entry (Evidence count + Decay + Verified date + event metadata) to `~/.claude/apex-learnings.md`. Format chosen so verify-learnings.sh continues to parse the file. Bootstraps the file with a minimal section header if missing. Powers the Living Evidence Counter writer side (R5-019). | `phase-tag.sh` (success branch), `phantom-check.sh` (FAIL branch), `framework/agents/critic.md` (FAIL branch), `framework/modules/apex-test-architect/agent.md` (veto branches) |
| `_fix-plan-emit.sh` | `emit_fix_plan [--also-write-recovery-menu] <source> <reason> <context> [<cmd -- desc>...]` — writes structured `.apex/FIX_PLAN.md` with sections Reason / Context / Recommended commands / How to undo. Generalizes R5-005's RECOVERY_MENU.md prototype (R5-014). Best-effort: failure to write does not mask the caller's exit-2. The `--also-write-recovery-menu` flag mirrors the file at `.apex/RECOVERY_MENU.md` for circuit-breaker.sh's W1 backward-compat contract. Spec anchor: "Failure produces a fix plan, never a 'go debug it'." | `path-guard.sh`, `destructive-guard.sh`, `workflow-guard.sh` (shim), `quarantine-guard.sh`, `schema-drift.sh`, `phantom-check.sh`, `post-write.sh`, `circuit-breaker.sh` |
| `_adapter-detect.sh` | `apex_adapter_active` (and CLI subcommand `active`) — returns the active APEX adapter name. Detection priority: `.apex/adapter` sidecar → `APEX_ADAPTER` env → `CURSOR_*` env heuristic → default `claude-code`. Powers the runtime adapter-honesty banner (R6-017). Spec anchors: "Multi-platform from day one." + "Honestly Scoped, Not Universally Promised." | `framework/commands/apex/start.md` (ADAPTER HONESTY BANNER block), `framework/commands/apex/onboard.md` (ADAPTER HONESTY BANNER block) |
| `_require-platform-detect.sh` | `detect_apex_platform` (sets `APEX_PLATFORM=windows\|macos\|linux\|unknown`) + `sample_bun_memory_mb` (echoes `<rss_mb> <commit_mb>` for the ancestor Bun/Claude Code process; always exits 0 with `0 0` + stderr warning on failure). v7.1 cross-platform memory sampling helpers. Fail-soft contract: never block, throttle is the caller's job. | `memory-watchdog.sh` |

---

## CommonJS — Node-runtime guards (3, R5-003)

Spec anchor: "Defense-in-Depth Security Layer: `apex-prompt-guard.js`, Path
Traversal Prevention, `apex-workflow-guard.js`, CI scanner, `security.cjs`
module." The two guards spec'd as `.js` and the `security.cjs` module ship as
CommonJS Node-runtime files. They run with zero npm dependencies (Node stdlib
only). Detection patterns load from `framework/test-fixtures/security-patterns.json`
— single source of truth shared with the `.sh` siblings, so the two runtimes
cannot drift.

| File | Trigger | Purpose |
|---|---|---|
| `apex-prompt-guard.cjs` | Auto-PreToolUse (Write\|Edit\|Agent) — invoked by settings.json runtime-aware command, or by `prompt-guard.sh` shim when node is on PATH | Prompt-injection detection. Behavior-identical to `prompt-guard.sh`; exit 2 on match. R6-014 renamed `prompt-guard.cjs` → `apex-prompt-guard.cjs` to match the spec literal `apex-` prefix. |
| `apex-workflow-guard.cjs` | Auto-PreToolUse (Read) — invoked by settings.json runtime-aware command, or by `workflow-guard.sh` shim when node is on PATH | Workflow-recipe injection scanner. Self-filters non-`apex-workflows/` paths. Behavior-identical to `workflow-guard.sh`; exit 2 on match. R6-014 renamed `workflow-guard.cjs` → `apex-workflow-guard.cjs` to match the spec literal `apex-` prefix. |
| `security.cjs` | Library — required by `apex-prompt-guard.cjs` and `apex-workflow-guard.cjs`; never invoked directly | Node counterpart of `_security-common.sh`: `normalize`, `hasZeroWidthChars`, `matchPromptInjection`, `matchWorkflowInjection`, `emitBlock`, `readStdinSync`, `parseHookStdin`. Loads canonical pattern set from `framework/test-fixtures/security-patterns.json`. |

**Runtime-aware dispatch.** `framework/settings.json` PreToolUse entries for
the two ported guards use a shell conditional: `if command -v node ... && [ -f
~/.claude/hooks/<name>.cjs ]; then node <name>.cjs; else bash <name>.sh; fi`.
The `.sh` shims at the same names also auto-delegate to the `.cjs` when node
is present — so command-invoked sites (e.g. `/apex:workflow`) and the
auto-wired settings.json path both hit the canonical `.cjs` engine when
available, and both fall back to the preserved Bash logic when not.

---

## Category Totals

| Category | Count |
|---|---|
| Auto-PreToolUse | 7 |
| Auto-PostToolUse | 9 |
| Command-Invoked / Event-Triggered | 15 |
| Library — Sourced | 13 |
| CommonJS — Node-runtime guards (R5-003) | 3 |
| **Total** | **46** (R5-011: `tdad-index.sh` and `cross-phase-audit.sh` are dual-listed in Auto-PostToolUse / SubagentStop AND Command-Invoked; not double-counted in the total. R5-014: `_fix-plan-emit.sh` added to Library — Sourced. R5-013: `owner-guard.sh` added to Auto-PreToolUse. R5-016: `decision-gate.sh` added to Command-Invoked. R6-017: `_adapter-detect.sh` added to Library — Sourced. v7.1 added Auto-Continuity Layer: `memory-watchdog.sh` and `turn-checkpoint.sh` to Auto-PostToolUse, `session-auto-resume.sh` to Command-Invoked / SessionStart, `_require-platform-detect.sh` to Library — Sourced.) |

Verify with: `ls framework/hooks/ | wc -l` (the file-system count is the
authority; the **46** figure above must equal what `wc -l` returns and is
re-asserted on every CI run by `framework/tests/test-hook-classification.sh`,
R7-011).

**Delta from R-003 original acceptance criterion:** plan document referenced
"28 files" based on a pre-Wave-1 count. Wave 1 R-005 added `_date-parse.sh`
(29). Wave 3 R5-023 added `_dream-cycle-emit.sh` (30). Wave 3 R5-004 added
`state-rebuild.sh` (31). Wave 4 R5-002 added `_state-sqlite.sh` (32). Wave 5
R5-003 added three CommonJS guards `apex-prompt-guard.cjs`,
`apex-workflow-guard.cjs`, `security.cjs` (35; R6-014 added the `apex-`
prefix to the two ported guards — count unchanged). Wave 6 R5-009 added `_agent-dispatch.sh` (36). Wave 6
R5-019 added `_learnings-emit.sh` (37). Wave 6 R5-021 added `agent-lint.sh`
(38). Wave 7 R5-014 added `_fix-plan-emit.sh` (39). Wave 8 R5-013 added
`owner-guard.sh` (40). Wave 8 R5-016 added `decision-gate.sh` (41).
R6 W6 R6-017 added `_adapter-detect.sh` (42). v7.1 (2026-05) added the
Auto-Continuity Layer: `memory-watchdog.sh` (Layer C, 43),
`turn-checkpoint.sh` (Layer B, 44), `session-auto-resume.sh` (Layer A,
45), and the helper library `_require-platform-detect.sh` (46). All
files accounted for
in the tables above.

---

## Cross-References

- `framework/settings.json` — authoritative source for auto-wired entries.
- `framework/security-policy.md` — deeper map of the 6 security mechanisms
  against the 5 guard hooks + `_security-common.sh`.
- `apex-spec.md` — Failure 9 (Defense-in-Depth), capabilities ("24+ hooks").
- `framework/adapters/adapter-contract.md` (R5-025) — multi-platform context.
  Hooks listed above are Claude-Code-canonical. Alternative-platform
  adapters (e.g. `framework/adapters/cursor/`) may declare
  `hook_protocol.supported = "none"` and defer the entire hook plane.

---

## Module-contributed hooks

**Count for R5: zero.** Per R5-001, the module ecosystem (`framework/modules/<name>/`) has the structural shape to advertise hook contributions via each module's `manifest.json` (`hooks[]` array, with `name`, `trigger`, optional `matcher`). For the R5 round, no module ships any hook of its own — every hook still lives directly under `framework/hooks/`. The live tree at `~/.claude/hooks/` remains flat: modules contribute, they do not host. As modules promote from `stub` to `active` and start contributing hooks, those entries get rolled into the category tables above (so a future reader does not have to inspect every manifest to answer "how does this hook fire?").

**Verification:** `jq -r '.hooks | length' framework/modules/*/manifest.json` should return only zeros for R5.

---

## How to add a new hook

1. Create `framework/hooks/<name>.sh` (or `_<name>.sh` for library).
2. Choose the trigger:
   - For Claude Code auto-wiring — add a `PreToolUse` / `PostToolUse` entry
     to `framework/settings.json` with the narrowest possible matcher.
   - For command-invocation — call `bash ~/.claude/hooks/<name>.sh ...` from
     the relevant command `.md`.
3. Add a row to the correct category table above.
4. Update `framework/security-policy.md` if the hook is security-related.
5. Add a test case in `framework/tests/test-hooks-security.sh` or
   `framework/tests/test-wiring.sh`.
