# APEX Hook Classification

**Purpose:** Catalog every file in `framework/hooks/` by trigger type, so a
developer can answer "how does this hook fire?" without cross-referencing
`framework/settings.json` and 44 command `.md` files.

**Total files:** state-derived — the file-system count is the
authority. The count is N where
`N = ls framework/hooks/ | wc -l`; the Category Totals table below
re-derives the same value, and the CI assertion in
`framework/tests/test-hook-classification.sh` (R7-011) re-runs the
derivation on every push, FAILing on doc/filesystem drift so future
additions cannot silently outpace this paragraph. The composition is
state-derived from the table rows below: functional `.sh` hooks (R5-013
added `owner-guard.sh`; R5-016 added `decision-gate.sh`; v7.1 added
`memory-watchdog.sh`, `turn-checkpoint.sh`, `session-auto-resume.sh`) +
library `.sh` files (`_`-prefixed; R5-014 added `_fix-plan-emit.sh`;
R6-017 added `_adapter-detect.sh`; v7.1 added
`_require-platform-detect.sh`; R12-001 added `_tokens-update.sh`) + 1
Python helper + 3 CommonJS guards (R5-003: `apex-prompt-guard.cjs`,
`apex-workflow-guard.cjs`, `security.cjs`; R6-014 prefixed the two
ported guards with `apex-` to match the spec literal naming). R13-001
removed every literal count from this paragraph so future hook
additions only require adding a row to the appropriate category table
and bumping the Category Totals cells — the prose no longer carries a
drift-prone literal.

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

## Auto-PreToolUse (13)

| File | Matcher | Purpose |
|---|---|---|
| `destructive-guard.sh` | `Bash` | v7 hardened destructive command blocker — normalized matching, chained-command splitting. Exit 2 on rm -rf, force pushes, etc. |
| `pre-subagent-start.sh` | `Agent\|Task` | Campaign B B2.1 (GAP-1 closure) — emits a `subagent_start` boundary event into `.apex/event-log.jsonl` AND appends a `{agent_id, agent_name, status:"in_flight"}` record to `.apex/in-flight-subagents.jsonl` so the universal `tool-event-logger.sh` PostToolUse hook can stamp child tool calls with the correct sub-agent attribution. Closes the structural root of F-204-013 (Campaign A CR-04 upgraded from spot-check to full coverage). Synthesizes `agent_id = subagent-<agent_name>-<round_tag>-<sha1_8>` per `audit-trail-review/EXPERIMENT-PROTOCOL.md` §6.1.1. Concurrent Task() invocations: single-sub-agent-at-a-time best-effort stamping (documented limitation, Phase-7 R-AT-P7-01). Exit 0 always — never blocks Task() dispatch. |
| `prompt-guard.sh` | `Write\|Edit\|Agent` | Prompt-injection detection (instruction override, role hijacking, hidden HTML, zero-width chars). Exit 2 on match. **Dual-runtime (R5-003):** `.cjs` preferred, `.sh` shim falls back to native Bash when node absent. Settings.json invocation is runtime-aware (`if command -v node ... node apex-prompt-guard.cjs; else bash prompt-guard.sh; fi`). R6-014 prefixed the .cjs payload with `apex-`; the .sh shim name is preserved per the R5-003 + R6-014 preservation contract. R17-644: Bash fallback emits a one-line stderr advisory when Node is absent, naming IMP-003 as the degraded capability. See `framework/docs/SECURITY-RUNTIME.md` §Node.js prerequisite for IMP-003. |
| `path-guard.sh` | `Write\|Edit` | Path traversal and sensitive-file protection (.env, credentials, .git/*, parent-dir escapes). Exit 2 on match. R17-642: arg-name dispatch (IMP-003 arg-content half) is fulfilled by `apex-prompt-guard.cjs`; path-guard.sh covers the path-prefix half only. See `framework/docs/SECURITY-RUNTIME.md` §IMP-003 arg-content enforcement coverage. |
| `owner-guard.sh` | `Write\|Edit` | One-file-one-owner enforcement (R5-013). Reads `APEX_CURRENT_TASK_ID` + `.apex/phases/<phase>/WAVE_MAP.json`; blocks writes to paths outside the active task's `owns_files`. Fast-path exit 0 when `APEX_CURRENT_TASK_ID` is unset (manual edits never gated). Advisory mode by default (exit 1) per the human-decision flag in REMEDIATION-PLAN-R5.md §R5-013; set `APEX_OWNER_GUARD_BLOCKING=1` to upgrade to exit 2. Spec anchors: "One-file-one-owner עם git worktree isolation" + "Read-parallel, write-serial עם Vertical Slices Enforcement." |
| `pre-task-snapshot.sh` | `Bash` | Git stash snapshot before task execution — enables per-task rollback. **R8-008 self-filter:** skips when the user's bash command starts with `git status\|log\|show\|diff\|stash` (read-only / stash-management — would clutter stash list). Matcher stays `Bash`; only the hook's internal logic narrows. Standalone CLI invocation (no stdin envelope) continues to fire the snapshot. |
| `quarantine-guard.sh` | `Read\|Bash` | Agent-aware file access control. When `APEX_ACTIVE_AGENT=auditor`, restrict reads to test files and `.apex/` state. Microsecond pass-through otherwise. |
| `test-deletion-guard.sh` | `Bash\|Write\|Edit` | R16-608 — blocks silent deletion of test files. Bash branch flags `rm`/`git rm` over `*.test.*` / `*.spec.*` / `tests/**` / `__tests__/**` / `test/**` paths. Write branch blocks shrinking an existing test file below 10% of its prior size when the file was non-trivial. Test-architect carve-out via `APEX_ACTIVE_AGENT=test-architect`. Exit 2 on detected deletion. Pairs with auditor.md count-delta check (R-608A). |
| `sequence-guard.sh` | `Bash` | R16-616 (F-616, IMP-016) — stateful PreToolUse credential-search detector. Reads `STATE.recent_denied_error_window` (FIFO max 5, populated by `_state-update.sh:_record_denied_error` on denied-class PostToolUse errors). When window non-empty, tightens deny set to block `find . -name "*token*"`, `grep -r api[_-]key`, `cat .env` / `~/.aws/credentials`, `env \| grep -i token`, `printenv` over the next 5 Bash calls. Carve-outs: `APEX_ACTIVE_AGENT=test-architect` and `.env.example/sample/template`. Exit 2 on match. |
| `grader-search-guard.sh` | `Bash` | R16-629 (F-629, IMP-029) — block reward-hacking via answer-key lookup. When the current task is not test-writing AND a `find` / `grep` / `rg` call contains answer-key / ground-truth / oracle / rubric / golden vocabulary, exit 2. Three-tier carve-out: `APEX_ACTIVE_AGENT=test-architect` (Wave 0 scan), `APEX_TASK_TYPE=test_writing` (explicit), `APEX_GRADER_SEARCH_GUARD=off` (emergency bypass). Pairs with auditor's adversarial perturbations (R-632A) for layered defense. |
| `subagent-guard.sh` | `Bash` | R16-618N (F-618, IMP-018) — stateful context-aware unattended-affirmation detector. Two-condition AND: (A) auto-yes flag present (`--yes` / `-y` standalone / `--auto-approve` / `--force-yes` / `--assume-yes` / `--no-confirm`) AND (B) command in destructive family (rm/rmdir/drop/delete/kill/shutdown/reboot/truncate/format/mkfs/wipe/reset/purge/`terraform destroy`/`kubectl delete`). Quote-aware chained-segment evaluation. Emergency bypass via `APEX_SUBAGENT_GUARD=off`. Pairs with destructive-guard.sh pure-pattern half (R-618D). Exit 2 on correlation match. |
| `exfil-guard.sh` | `Bash` | R16-610 (F-610, IMP-005) — stateful conditional elevated guards. Reads `STATE.tool_failure_count` (incremented by `_state-update.sh:_record_tool_failure` whenever a PostToolUse event reports `is_error=true`). Below threshold (<5) the hook is a no-op; at or above, an elevated deny set activates: DNS exfil via base64-looking subdomains (`dig <encoded>.<domain>`), non-standard port binds (`nc -l <high-port>`, `python -m http.server <high-port>`), base64-looking filename write targets, side-channel `/tmp/<encoded>` writes. Carve-outs: `APEX_EXFIL_GUARD=off`, `APEX_ACTIVE_AGENT=test-architect`. Exit 2 on match. |
| `workflow-guard.sh` | `Read` | Workflow-recipe injection scanner (post-R-006 auto-wiring). Self-filters non-workflow paths. Also invoked explicitly by `/apex:workflow`. **Dual-runtime (R5-003):** `.cjs` preferred, `.sh` shim falls back to native Bash when node absent. |

Source: `framework/settings.json` entries under `.hooks.PreToolUse[]` (each entry has `matcher` and a nested `hooks:[{"type":"command", ...}]` array per Claude Code's native schema).

---

## Auto-PostToolUse (11)

| File | Matcher | Purpose |
|---|---|---|
| `post-write.sh` | `Write\|Edit` | Secret detection on written source files (BLOCKING — exit 2 on high-confidence match). |
| `schema-drift.sh` | `Write\|Edit` | Validates `.apex/` JSON state files against expected schemas after every write. |
| `ast-kb-check.sh` | `Write\|Edit` | AST/KB hallucination gate — import validation. Advisory (exit 1, not 2). Rationale: dynamic-import resolution produces high false-positives; signal consumed by critic.md, which makes the actual block decision. |
| `phantom-check.sh` | `Write` | Blocks phase advancement when SUMMARY.md contains uncertainty language (e.g., "should work", "might pass"). R16-604 added the Mythos cheating vocabulary list (`desperate`, `cherry-pick`, `cover-up`, `# hack`, `XXX hack`, etc.) for self-incrimination detection. |
| `scratchpad-monitor.sh` | `Bash\|Write\|Edit` | R16-604 — Mythos cheating-vocabulary scan over extended-thinking artifact paths (`.apex/scratchpads/`, `.apex/thinking/`, `.apex/cot/`, or env `APEX_SCRATCHPAD_PATH`). Companion to `phantom-check.sh` (which scans SUMMARY.md). Exit 2 on detected self-incrimination tokens. Exit 0 silently when no artifact paths exist (platform may not expose CoT). |
| `circuit-breaker.sh` | `Bash` | v7 total tool-call cap + enhanced loop detection. Interrupts runaway sessions. R17-640: CHECK 3 also classifies denied-class errors (unauthorized/forbidden/403/401/denied/missing_token) and calls `_record_denied_error` to populate `STATE.recent_denied_error_window` for sequence-guard.sh's IMP-016 consumer. |
| `ci-scan.sh` | `Write\|Edit` | Supply-chain vector scanner for `.github/workflows/*.yml` (R5-010). Self-filtered: parses Claude Code hook stdin payload, exits 0 fast when the touched path is outside `.github/workflows/`. Exit 2 on detected vectors (unpinned actions, secret exposure, write-all permissions, unsafe `pull_request_target`). Also retains command-invoked usage. |
| `tdad-index.sh` | `Write\|Edit` | Builds code-test dependency graph for TDAD impact analysis (R5-011). **Auto-wired:** SessionStart (rebuild on session start) + Auto-PostToolUse Write\|Edit (rebuild after source-file edits). Debounced via freshness guard: when `.apex/TEST_MAP.txt` is newer than every source file, exits 0 fast. Also retains command-invoked usage from `/apex:next` (after architect). Index-building logic unchanged — only the freshness guard is new. |
| `memory-watchdog.sh` | `Bash` | v7.1 Auto-Continuity Layer C — pre-OOM in-process Bun/Claude Code memory sampler. Throttled internally by `memory_sample_interval_seconds` (default 30s). Always exit 0; fail-loud-and-skip on platform issues. Side effects: updates `.apex/STATE.json` (`session.memory.*`), appends `memory_sample` events to `.apex/event-log.jsonl`, creates `.apex/AUTO_PAUSE_REQUEST.flag` when `consecutive_over_threshold` reaches the debounce limit. Auto-pause is *consumed* by `/apex:next` Step F.4 — this hook only requests it. |
| `turn-checkpoint.sh` | `Bash` and `Write\|Edit` | v7.1 Auto-Continuity Layer B — fine-grained turn-level checkpoints for `/apex:recover` option 6. Throttled by `turn_checkpoint_interval` (default: every 5 tool calls). Must run AFTER `circuit-breaker.sh` so `total_tool_calls_this_task` is fresh. Always exit 0. Side effects: atomic temp+mv replace of `.apex/TURN_CHECKPOINT.json`, mirrors to `.apex/STATE.json` `.turn_checkpoint`, appends `turn_checkpoint_set` event to event-log. |
| `tool-event-logger.sh` | `*` | R17-641 (F-641, IMP-019/028/035): single producer for `tool_input` / `tool_response` event-log records; enables critic STEPs 1.6/1.7/4.5/4.6 CORPUS / CALL_CORPUS substring scan. Fires on every tool call via the `*` matcher. Reads PostToolUse stdin envelope, emits one JSONL record per call to `.apex/event-log.jsonl` via `_state-update.sh:_emit_apex_event` (logging-only — no STATE.json mutation). Fail-loud-and-skip on missing jq; silent no-op outside a git repo or with empty stdin. Cheap by design (one jq -c, one append, exit 0). |

Source: `framework/settings.json` entries under `.hooks.PostToolUse[]` (each entry has `matcher` and a nested `hooks:[{"type":"command", ...}]` array per Claude Code's native schema).

---

## Command-Invoked / Event-Triggered (22)

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
| `comprehension-gate.sh` | `/apex:next` (PASS path, phase boundary OR 60-min cadence) | M09 (Phase 12.05) risk-based generation-then-comprehension gate. Depth by task_class: A=0 (skipped), B=1 file, C/D=2 files + 1 integration point. Renders the R5 4-question protocol (What does this code do? / What invariant matters? / What could break? / How would you modify it?). Responses: explain (mandatory text), defer (auto-fires next boundary), skip (requires --force; logs cognitive_debt.skip event; STRUCTURALLY UNAVAILABLE for Track D). Exit codes: 0=pass (explain or defer), 1=skip-refused or Track-D-skip-attempt, 2=invocation error. |
| `pre-rotation-snapshot.sh` | `/apex:next` rotation dispatch (proactive_compact, warn_and_compact, hard_rotate) | M14 (Phase 12.08) atomic 4-artifact pre-rotation snapshot: (1) STATE.json fresh canonical write, (2) DECISIONS.md flush from `.apex/pending_decisions.json`, (3) git tag `apex/rotation/<TS>-<phase>`, (4) ROTATION-NOTE-<TS>.md with Done/Next/Issues sections. Safe-or-noop: any step failure aborts the rotation; ROTATION-NOTE failure after tag creation rolls back the tag. Tag retention: keep last 50. Exit codes: 0=4 artifacts written, 1=artifact failure, 2=invocation error. resume.md reads the most-recent ROTATION-NOTE preferentially over DECISIONS.md. |
| `background-digest-hook.sh` | `/apex:next` (soft-rotation trigger, 45-min cadence); `/apex:status` (on-demand `--digest`) | M10 (Phase 12.06) MINOR-event digest emitter. Reads `.apex/event-log.jsonl`, filters `severity == "MINOR"` since `STATE.severity.digest_state.last_digest_at`, groups by `(hook, what)`, emits top-5 most-frequent + total count. Updates `STATE.severity.digest_state.last_digest_at`. Exit codes: 0 = digest emitted (zero or more events), 1 = invocation error, 2 = jq required and absent. |
| `track-d-modal.sh` | `/apex:next` (STEP G when task_class=="D") | M08.1 (Phase 12.02) plain-language Hebrew/English modal for Track D events. Default Enter = `לא, עצור` (decline — safe). Rate-limited ≤1/30 min; excess batches to `.apex/pending_track_d.json`; digest mode after 3 modals/day. `is_irreversible_now=true` bypasses batching. Exit codes: 0=approved, 1=declined, 2=batched/digested, 3=invocation error (caller fails safe to Supervised). |
| `observation-mask.sh` | `pre-compact.sh` (invoked first; fall-through to `/compact` is the safety net) | R13-002 (F-302) — extractive observation masking. Reads the executor transcript (`APEX_TRANSCRIPT_PATH` env, fallback `.apex/event-log.jsonl`), identifies tool-result blocks older than `working_memory.masking_window_turns` (default 3), and replaces each with a single-line stub `[masked: <tool> at turn <N>, re-read from disk if needed]`. Updates `STATE.context.last_mask_at`; emits `observation.mask.fired` / `observation.mask.fallback` / `observation.mask.bypassed` / `observation.mask.stub` to event-log. Fail-safe: transcript missing → exit 0 (never blocks the pipeline). Idempotent on already-masked blocks. CRLF-safe (R7-009 contract). Bypass: `STATE.context.observation_masking_active = false`. |
| `dora-collect.sh` | `/apex:milestone-summary`, `/apex:ship` (Phase 12.12) | M18.1 DORA Measurement Engine. Extracts the DORA quartet (Deployment Frequency, Lead Time, Change Failure Rate, MTTR) from `git log` alone and writes `.apex/DORA.json` (schema v1, atomic via rename-temp). Configurable tag patterns via env (`APEX_DORA_DEPLOY_TAG_PATTERN` default `release/*`, `APEX_DORA_DEPLOY_TAG_PATTERN_ALT` default `deploy/*`); rolling window via `APEX_DORA_WINDOW_DAYS` (default 28). CFR uses the per-commit proxy (`per_commit_proxy`) — documented in `framework/docs/CLAIMS-MEASUREMENT.md` §"DORA measurement engine" with rejected alternatives. MTTR uses the `next_forward_tag_after_revert` heuristic; limitations documented. Exit codes: 0=DORA.json written, 1=no commits / git unavailable, 2=invocation error (no .apex/). |
| `quality-drift.sh` | `subagent-stop.sh` (after rolling-window append); `/apex:status` (`--detailed`); `_rotation-decide.sh` (consumer of `quality_drift` trigger) | M16 (Phase 12.09) quality-drift computation. Reads `STATE.quality.rolling_window_tasks` (FIFO max 10, populated by `subagent-stop.sh`) and `STATE.quality.baseline_window_tasks` (first-10 frozen baseline; resets on phase change + 5 tasks in new phase). Computes `drift_pct = ((current_avg - baseline_avg) / baseline_avg) * 100` over `confidence_score` (high=1.0, medium=0.5, low=0.0). Writes `STATE.quality.current_drift_pct`. If `abs(drift_pct) > alert_threshold_pct` (default 5) AND `tasks_completed > 20` → emits `quality_drift` event to `.apex/event-log.jsonl` (new rotation trigger registered in `_rotation-decide.sh`). Exit codes: 0=ok, 1=insufficient data (baseline <10), 2=invocation error (no .apex/). |

**Note:** Grep across `framework/commands/apex/` returns 51 invocation sites
across 15 command files — `/apex:next` alone invokes 34 of these. See the
command `.md` files for exact invocation points.

---

## Library — Sourced (17)

Files prefixed with `_` — utility libraries sourced by other hooks.
**Never invoked directly.**

| File | Provides | Sourced by |
|---|---|---|
| `_require-jq.sh` | `require_jq` — fails hook with a fix message if jq missing | Most JSON-manipulating hooks |
| `_require-git.sh` | `require_git` — fails hook if git unavailable | Git-using hooks |
| `_security-common.sh` | `_sec_normalize`, `_sec_pattern_match`, `_sec_block` — shared security primitives | All 5 guard hooks (prompt/path/workflow/destructive/quarantine) |
| `_state-read.sh` | Point-in-time STATE.json snapshot for consistent reads within one invocation | Hooks that read STATE multiple times |
| `_state-update.sh` | Atomic STATE.json update with error handling | Hooks that mutate STATE |
| `_tokens-update.sh` | `apex_tokens_update <agent> <in> <out> [cache_r] [cache_c]` — atomically increments `.tokens.*` fields in `.apex/STATE.json` using the rename-temp atomic-write pattern. Library exposing the narrow token-accumulation contract that runs on every SubagentStop event (R12-001). Writes `STATE.tokens.*` via rename-temp atomic-write pattern. | `subagent-stop.sh` (R12-001 partial landing; wired via `source "$(dirname "$0")/_tokens-update.sh"`) |
| `_date-parse.sh` | `parse_epoch` — portable date→epoch (GNU → BSD → Python3 → Python2) | `phase-tag.sh`, `verify-learnings.sh` (post-R-005) |
| `_dream-cycle-emit.sh` | `start \| complete \| fail` phases for memory-synthesis dream-cycle wraps; emits structured START/COMPLETE/FAIL JSONL with a correlation id (R5-023) | `/apex:next` (two invocation sites) |
| `_state-sqlite.sh` | `_state_sqlite_mirror`, `_state_sqlite_status` — opt-in SQLite mirror over STATE.json + event-log.jsonl when `APEX_SQLITE_MIRROR=1` and `sqlite3` CLI present (R5-002). Fail-loud-and-skip when CLI absent. | `_state-update.sh` (conditional) |
| `_agent-dispatch.sh` | `apex_dispatch_enter <agent>` / `apex_dispatch_exit` — sets/unsets `APEX_ACTIVE_AGENT` so the quarantine guard fires structurally on every auditor invocation, regardless of which command invoked it (R5-009). Also exposes `enter` / `exit` subcommands for non-sourcing callers. | `/apex:next` (auditor dispatch site); future agent-quarantined call sites |
| `_learnings-emit.sh` | `emit_learning <event_type> <phase> <summary>` — appends a structured WARM-section entry (Evidence count + Decay + Verified date + event metadata) to `~/.claude/apex-learnings.md`. Format chosen so verify-learnings.sh continues to parse the file. Bootstraps the file with a minimal section header if missing. Powers the Living Evidence Counter writer side (R5-019). | `phase-tag.sh` (success branch), `phantom-check.sh` (FAIL branch), `framework/agents/critic.md` (FAIL branch), `framework/modules/apex-test-architect/agent.md` (veto branches) |
| `_fix-plan-emit.sh` | `emit_fix_plan [--also-write-recovery-menu] <source> <reason> <context> [<cmd -- desc>...]` — writes structured `.apex/FIX_PLAN.md` with sections Reason / Context / Recommended commands / How to undo. Generalizes R5-005's RECOVERY_MENU.md prototype (R5-014). Best-effort: failure to write does not mask the caller's exit-2. The `--also-write-recovery-menu` flag mirrors the file at `.apex/RECOVERY_MENU.md` for circuit-breaker.sh's W1 backward-compat contract. Spec anchor: "Failure produces a fix plan, never a 'go debug it'." | `path-guard.sh`, `destructive-guard.sh`, `workflow-guard.sh` (shim), `quarantine-guard.sh`, `schema-drift.sh`, `phantom-check.sh`, `post-write.sh`, `circuit-breaker.sh` |
| `_adapter-detect.sh` | `apex_adapter_active` (and CLI subcommand `active`) — returns the active APEX adapter name. Detection priority: `.apex/adapter` sidecar → `APEX_ADAPTER` env → `CURSOR_*` env heuristic → default `claude-code`. Powers the runtime adapter-honesty banner (R6-017). Spec anchors: "Multi-platform from day one." + "Honestly Scoped, Not Universally Promised." | `framework/commands/apex/start.md` (ADAPTER HONESTY BANNER block), `framework/commands/apex/onboard.md` (ADAPTER HONESTY BANNER block) |
| `_require-platform-detect.sh` | `detect_apex_platform` (sets `APEX_PLATFORM=windows\|macos\|linux\|unknown`) + `sample_bun_memory_mb` (echoes `<rss_mb> <commit_mb>` for the ancestor Bun/Claude Code process; always exits 0 with `0 0` + stderr warning on failure). v7.1 cross-platform memory sampling helpers. Fail-soft contract: never block, throttle is the caller's job. | `memory-watchdog.sh` |
| `_rotation-decide.sh` | `apex_rotation_decide <state_file> <budget_file>` — returns one of `proactive_compact \| warn_and_compact \| hard_rotate \| noop` by reading `STATE.context.estimated_context_usage_pct` (post-R12-001) and iterating `CONTEXT_BUDGET.rotation_triggers[]` in priority order (array index = priority; first match wins). Supports trigger types `utilization_pct`, `phase_boundary`, `task_batch`, `time_minutes`, `recovery_density`; `pattern` is legacy-skipped; unknown types are skipped with an event-log line. **HALT-priority guard**: returns `noop` regardless of pressure when `STATE.session.drift_indicators.circuit_breaker_triggers > 0` or `STATE.circuit_breaker.triggered == true`. Fail-safe: missing inputs or jq absence → `noop`. R13-005 (F-305). | `/apex:next` Step F (CONTEXT OVERFLOW CHECK → rotation dispatch) |
| `_emit_apex_event.sh` | `apex_emit_event SEVERITY HOOK_NAME WHAT WHERE WHY [DEDUP_KEY] [NEXT_ACTIONS_JSON]` — M10 central event emitter (Phase 12.06). Routes by severity: CRITICAL → stdout + event-log + CRITICAL-budget tracker (4th-in-12h triggers follow-up MAJOR); MAJOR → event-log + /apex:status flag (silent); MINOR → event-log only (digest hook reaps). 5-min dedup window on `(hook, severity, dedup_key)`. Replaces the ad-hoc `echo "🚫 ..." >&2 ; exit 2` patterns across the 50 hooks; hook rewrite is a documented follow-up. See `framework/docs/SEVERITY-REGISTRY.md` for the per-hook classification table. | New hooks; future per-hook rewrites under Phase 12.06 follow-up |
| `_telemetry-emit.sh` | `apex_telemetry_emit <event> [counters_json]` — M16.1 (Phase 12.09) anonymized telemetry writer. Single writer to `.apex/telemetry.jsonl`. Dual opt-out (BOTH paths checked before any disk write): `APEX_TELEMETRY=off` env-var OR `.apex/telemetry-opt-out.flag` file → exit 0, no write. Anonymization: project identifier = `sha256(basename $PWD) \| head -c 8` with fallback chain sha256sum→shasum→openssl→sentinel `00000000` (defense-in-depth: never falls back to leaking basename); path-leak guard validates no `/` characters inside counters JSON. Local-only v0.1.x; explicitly ignores `APEX_TELEMETRY_REMOTE` (reserved for v1.0+ opt-in). Atomic append via `printf '%s\n' >> file` (POSIX-atomic for sub-PIPE_BUF writes). Bilingual privacy policy at `framework/docs/PRIVACY-POLICY.md`. Exit codes: 0=ok (write or opt-out), 2=invocation error (missing event arg, malformed counters_json). | `quality-drift.sh` (per-task quality metric); future hooks emitting opt-in counters under M16.1 |

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
| Auto-PreToolUse | 13 |
| Auto-PostToolUse | 11 |
| Command-Invoked / Event-Triggered | 22 |
| Library — Sourced | 17 |
| CommonJS — Node-runtime guards (R5-003) | 3 |
| **Total** | **65** (Campaign B B2.1 added `pre-subagent-start.sh` to Auto-PreToolUse — matcher `Agent|Task`, emits `subagent_start` boundary into `.apex/event-log.jsonl` and writes `.apex/in-flight-subagents.jsonl` so PostToolUse `tool-event-logger.sh` can stamp `agent_id` on child tool_call events. Structural closure of F-204-013 / GAP-1 — upgrades Campaign A CR-04 spot-check to full coverage. R17-641 added `tool-event-logger.sh` to Auto-PostToolUse — single matcher `*` producer for `tool_input`/`tool_response` event-log records; enables critic anti-phantom STEPs 1.6/1.7/4.5/4.6 substring scan. R16-610 added `exfil-guard.sh` to Auto-PreToolUse — stateful elevated-deny detector triggered by `STATE.tool_failure_count >= 5`. R16-618N added `subagent-guard.sh` to Auto-PreToolUse — stateful auto-yes-on-destructive-family detector pairing with destructive-guard.sh R-618D. R16-629 added `grader-search-guard.sh` to Auto-PreToolUse — blocks answer-key lookup outside test-writing tasks. R16-616 added `sequence-guard.sh` to Auto-PreToolUse — stateful credential-search-after-denied-error detector. R5-011: `tdad-index.sh` and `cross-phase-audit.sh` are dual-listed in Auto-PostToolUse / SubagentStop AND Command-Invoked; not double-counted in the total. R5-014: `_fix-plan-emit.sh` added to Library — Sourced. R5-013: `owner-guard.sh` added to Auto-PreToolUse. R5-016: `decision-gate.sh` added to Command-Invoked. R6-017: `_adapter-detect.sh` added to Library — Sourced. v7.1 added Auto-Continuity Layer: `memory-watchdog.sh` and `turn-checkpoint.sh` to Auto-PostToolUse, `session-auto-resume.sh` to Command-Invoked / SessionStart, `_require-platform-detect.sh` to Library — Sourced. R12-001 added `_tokens-update.sh` to Library — Sourced; R13-001 closed the doc/disk cardinality gap. R13-002 added `observation-mask.sh` to Command-Invoked / Event-Triggered, invoked by `pre-compact.sh` before the `/compact` fall-through. R13-005 added `_rotation-decide.sh` to Library — Sourced, sourced by `/apex:next` Step F as the rotation-decision control-flow gate consumer of `CONTEXT_BUDGET.rotation_triggers[]`. Phase 12.12 (M18.1) added `dora-collect.sh` to Command-Invoked / Event-Triggered, invoked by `/apex:milestone-summary` and `/apex:ship` to extract the DORA quartet from `git log` into `.apex/DORA.json`.) |

Verify with: `ls framework/hooks/ | wc -l` (the file-system count is the
authority; the **Total** cell above must equal what `wc -l` returns and is
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
45), and the helper library `_require-platform-detect.sh` (46). R12-001
added `_tokens-update.sh` (47) — the token-counter library sourced by
`subagent-stop.sh`. R13 corrective edit (R13-001): `_tokens-update.sh`
library added to filesystem by partial R12-001 landing; this row closes
the cardinality contract gap (R7-011) and the prose-count was
refactored to state-derived form so future hook additions cannot
silently outpace the paragraph. R13-002 added `observation-mask.sh`
(48) — the Stop+soft-rotation hook that runs before `pre-compact.sh`
fall-through to `/compact`, implementing the extractive masking design
spec'd in `apex-design-notes.md` and closing F-302 (three-places
contract: hook file + invocation in `pre-compact.sh` + this row).
R13-005 added `_rotation-decide.sh` (49) — the rotation-decision
control-flow gate library sourced by `/apex:next` Step F as a real
consumer of `CONTEXT_BUDGET.rotation_triggers[]`, replacing the
task-count proxy `tasks_since_last_rotation >= 4`. Returns one of
`proactive_compact | warn_and_compact | hard_rotate | noop` driven by
`STATE.context.estimated_context_usage_pct` (post-R12-001) plus
structured trigger types (`utilization_pct`, `phase_boundary`,
`task_batch`, `time_minutes`, `recovery_density`); HALT-priority guard
honors `circuit_breaker_triggers`. Closes F-305 (three-places contract:
hook file + invocation in `/apex:next` Step F + this row).
Phase 12.02 (M08.1) added `track-d-modal.sh` (50) — the plain-language
Hebrew/English Track D modal, invoked by `/apex:next` STEP G when
task_class=="D". Phase 12.06 (M10) added `_emit_apex_event.sh` (51,
library — central severity router with CRITICAL-budget tracker and
5-min dedup) and `background-digest-hook.sh` (52, command-invoked —
45-min MINOR digest reaper). See `framework/docs/SEVERITY-REGISTRY.md`
for the per-hook severity classification table and the documented
follow-up backlog for rewriting the 50 pre-existing hooks to emit
via the new library. Phase 12.05 (M09) added `comprehension-gate.sh`
(53, command-invoked — risk-based generation-then-comprehension gate;
task-class-driven depth A=0/B=1/C-D=2; replaces the v7 LOC-based gate
in next.md). Phase 12.08 (M14) added `pre-rotation-snapshot.sh` (54,
command-invoked — atomic 4-artifact rotation capture: STATE +
DECISIONS flush + git tag + ROTATION-NOTE; safe-or-noop on failure;
tag retention=50). resume.md reads the most-recent ROTATION-NOTE
preferentially over DECISIONS.md. Phase 12.12 (M18.1) added
`dora-collect.sh` (55, command-invoked — DORA quartet extractor;
writes `.apex/DORA.json` from `git log` alone; configurable tag
patterns). Phase 12.09 (M16 + M16.1) added `quality-drift.sh`
(56, command-invoked — rolling/baseline confidence-score drift
detector; emits `quality_drift` event consumed by
`_rotation-decide.sh`) and `_telemetry-emit.sh` (57, library —
single anonymized telemetry writer with dual opt-out checked
BEFORE any disk write; sha256(basename)[0:8] anonymization with
defense-in-depth fallback; local-only v0.1.x).
All files accounted for in the tables above.

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
