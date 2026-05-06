# APEX Hook Classification

**Purpose:** Catalog every file in `framework/hooks/` by trigger type, so a
developer can answer "how does this hook fire?" without cross-referencing
`framework/settings.json` and 44 command `.md` files.

**Total files:** 35 — 23 functional `.sh` hooks + 8 library `.sh` files
(`_`-prefixed) + 1 Python helper + 3 CommonJS guards (R5-003: `prompt-guard.cjs`,
`workflow-guard.cjs`, `security.cjs`). Category totals below sum to 35.

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

## Auto-PreToolUse (6)

| File | Matcher | Purpose |
|---|---|---|
| `destructive-guard.sh` | `Bash` | v7 hardened destructive command blocker — normalized matching, chained-command splitting. Exit 2 on rm -rf, force pushes, etc. |
| `prompt-guard.sh` | `Write\|Edit\|Agent` | Prompt-injection detection (instruction override, role hijacking, hidden HTML, zero-width chars). Exit 2 on match. **Dual-runtime (R5-003):** `.cjs` preferred, `.sh` shim falls back to native Bash when node absent. Settings.json invocation is runtime-aware (`if command -v node ... node prompt-guard.cjs; else bash prompt-guard.sh; fi`). |
| `path-guard.sh` | `Write\|Edit` | Path traversal and sensitive-file protection (.env, credentials, .git/*, parent-dir escapes). Exit 2 on match. |
| `pre-task-snapshot.sh` | `Bash` | Git stash snapshot before task execution — enables per-task rollback. |
| `quarantine-guard.sh` | `Read\|Bash` | Agent-aware file access control. When `APEX_ACTIVE_AGENT=auditor`, restrict reads to test files and `.apex/` state. Microsecond pass-through otherwise. |
| `workflow-guard.sh` | `Read` | Workflow-recipe injection scanner (post-R-006 auto-wiring). Self-filters non-workflow paths. Also invoked explicitly by `/apex:workflow`. **Dual-runtime (R5-003):** `.cjs` preferred, `.sh` shim falls back to native Bash when node absent. |

Source: `framework/settings.json` entries under `.hooks.PreToolUse[]` (each entry has `matcher` and a nested `hooks:[{"type":"command", ...}]` array per Claude Code's native schema).

---

## Auto-PostToolUse (5)

| File | Matcher | Purpose |
|---|---|---|
| `post-write.sh` | `Write\|Edit` | Secret detection on written source files (BLOCKING — exit 2 on high-confidence match). |
| `schema-drift.sh` | `Write\|Edit` | Validates `.apex/` JSON state files against expected schemas after every write. |
| `ast-kb-check.sh` | `Write\|Edit` | AST/KB hallucination gate — import validation. Advisory (exit 1, not 2). |
| `phantom-check.sh` | `Write` | Blocks phase advancement when SUMMARY.md contains uncertainty language (e.g., "should work", "might pass"). |
| `circuit-breaker.sh` | `Bash` | v7 total tool-call cap + enhanced loop detection. Interrupts runaway sessions. |

Source: `framework/settings.json` entries under `.hooks.PostToolUse[]` (each entry has `matcher` and a nested `hooks:[{"type":"command", ...}]` array per Claude Code's native schema).

---

## Command-Invoked / Event-Triggered (13)

Hooks that fire via explicit invocation from command `.md` files, from other
hooks, or from Claude Code lifecycle events.

**Auto-wired via `settings.json` (post-R4-007 + R5-004):** `state-rebuild.sh`
(SessionStart, conditional — fires before verify-learnings when STATE.json
missing), `verify-learnings.sh` (SessionStart), `pre-compact.sh` (PreCompact),
`subagent-stop.sh` (SubagentStop). The remaining 9 are command-invoked only —
not in `settings.json`.

| File | Invoked by | Purpose |
|---|---|---|
| `phase-tag.sh` | `/apex:next`, `/apex:ship` | Creates git tag for completed phase; updates DORA metrics in STATE.json (cumulative avg post-R-002, cross-platform date parsing post-R-005). |
| `verify-learnings.sh` | `/apex:next`, SessionStart event (auto-wired R4-007) | v7 tiered enforcement + decay-class-aware staleness; SessionStart emits HOT/WARM counts. |
| `cross-phase-audit.sh` | `/apex:validate-phase`, `/apex:next` | Runs all prior-phase tests to catch regressions before advancing. |
| `mutation-gate.sh` | `/apex:next` (after critic PASS on verify_level C/D) | Mutation-testing gate. |
| `ci-scan.sh` | CI pipeline / manual | Supply-chain vector scanner. Not auto-wired by design — CI invocation only. |
| `context-monitor.sh` | `/apex:next`, `/apex:status`, `/apex:pause`, `/apex:resume` | Real-token counting from STATE.json; compact at 50–60%, rotate at 70%. |
| `session-log.sh` | Many commands and hooks | APEX Session Guardian — appends events to `.apex/SESSION-LOG.md`. Shared logging primitive. |
| `generate-task-map.sh` | `/apex:next` | Generates task map using jq + git. |
| `tdad-index.sh` | `/apex:next` (after architect) | Builds code-test dependency graph for TDAD impact analysis. |
| `tdad-impact.py` | `tdad-index.sh`, `/apex:next` | Python helper — given changed files, find impacted tests via `.apex/TEST_MAP.txt`. |
| `pre-compact.sh` | PreCompact event (auto-wired R4-007, Claude Code runtime) | v7 observation-masking tracking; 50% cost reduction at neutral/positive quality. Backs up state to `.apex/backups/`. |
| `subagent-stop.sh` | SubagentStop event (auto-wired R4-007, Claude Code runtime) | Subagent lifecycle cleanup; reads agent_name from stdin JSON. |
| `state-rebuild.sh` | SessionStart event (auto-wired R5-004, conditional) + `/apex:recover`, `/apex:resume` | Reconstructs `.apex/STATE.json` from `event-log.jsonl` + phase summaries. Fast-path exits 0 when STATE.json exists; fires only when the file is missing. Spec anchor: "State derives from disk." |

**Note:** Grep across `framework/commands/apex/` returns 51 invocation sites
across 15 command files — `/apex:next` alone invokes 34 of these. See the
command `.md` files for exact invocation points.

---

## Library — Sourced (8)

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
| `prompt-guard.cjs` | Auto-PreToolUse (Write\|Edit\|Agent) — invoked by settings.json runtime-aware command, or by `prompt-guard.sh` shim when node is on PATH | Prompt-injection detection. Behavior-identical to `prompt-guard.sh`; exit 2 on match. |
| `workflow-guard.cjs` | Auto-PreToolUse (Read) — invoked by settings.json runtime-aware command, or by `workflow-guard.sh` shim when node is on PATH | Workflow-recipe injection scanner. Self-filters non-`apex-workflows/` paths. Behavior-identical to `workflow-guard.sh`; exit 2 on match. |
| `security.cjs` | Library — required by `prompt-guard.cjs` and `workflow-guard.cjs`; never invoked directly | Node counterpart of `_security-common.sh`: `normalize`, `hasZeroWidthChars`, `matchPromptInjection`, `matchWorkflowInjection`, `emitBlock`, `readStdinSync`, `parseHookStdin`. Loads canonical pattern set from `framework/test-fixtures/security-patterns.json`. |

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
| Auto-PreToolUse | 6 |
| Auto-PostToolUse | 5 |
| Command-Invoked / Event-Triggered | 13 |
| Library — Sourced | 8 |
| CommonJS — Node-runtime guards (R5-003) | 3 |
| **Total** | **35** |

Verify with: `ls framework/hooks/ | wc -l` → **35**.

**Delta from R-003 original acceptance criterion:** plan document referenced
"28 files" based on a pre-Wave-1 count. Wave 1 R-005 added `_date-parse.sh`
(29). Wave 3 R5-023 added `_dream-cycle-emit.sh` (30). Wave 3 R5-004 added
`state-rebuild.sh` (31). Wave 4 R5-002 added `_state-sqlite.sh` (32). Wave 5
R5-003 added three CommonJS guards `prompt-guard.cjs`, `workflow-guard.cjs`,
`security.cjs` (35). All files accounted for in the tables above.

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
