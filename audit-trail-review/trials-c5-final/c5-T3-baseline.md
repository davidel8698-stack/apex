# Trial C5-T3 baseline (apex-detector-lab-baseline) — INDEPENDENT THIRD RE-PASS

## Lab provenance
- `repo_root`: `C:\Users\דודאלמועלם\OneDrive - Tiva 13 Engineers\שולחן העבודה\APEX\.lab\apex-detector-lab-baseline`
- `spec_path`: `apex-spec.md` (595 lines)
- `git HEAD`: `8ac2a858423c490d58bd22fba742c51bf0c7021a` (R-023-001 set-and-forget design intent)
- `round_tag`: `C5-T3-baseline` (Wave 4 trial 3 of 3 — final independent re-pass closing AC-4-R3)
- Working tree state: `framework/apex-workflows/` mass-deletion staged (31 files staged-D); on-disk content moved to `framework/apex-workflows-DISABLED/`. `apex-prompt-guard.cjs` and `apex-workflow-guard.cjs` are staged-D in working tree (`git status` confirms).
- Marker prefix used on all Bash probes: `__APEX_AUDIT_PROBE__`
- Test-suite OBSERVED via `/tmp/apex-t3-baseline-copy/` clone to escape OneDrive I/O latency.
- Note: probe payload literals containing IMP-003 instruction-override and role-hijack strings are redacted in this report as `<OVERRIDE_PAYLOAD>` and `<ROLE_HIJACK_PAYLOAD>` to avoid triggering the local prompt-guard on file-write. Actual probes used the standard IMP-003 free-text payloads; exit codes recorded below are from the literal payloads.

## Executive summary

Third independent baseline pass. Mechanical enumeration of spec-named hooks against `framework/hooks/*.{sh,cjs,js,py}` re-confirms the two Class-A deletion mutants (W-A1 = `apex-prompt-guard.cjs`, W-A2 = `apex-workflow-guard.cjs`) as per-hook P0 findings. Live adversarial probes re-reproduce the stdin-vs-argv runtime-contract gap on `prompt-guard.sh`'s bash fallback (F-003), the IMP-018 pattern-subset gap on `subagent-guard.sh` (F-004), the `_state_update` silent-return-0 on jq failure (F-007), and the apex-workflows library mass-deletion (F-006). Test suite OBSERVED: `passed:70 failed:2 skipped:0 errored:0` over 14m 14s. The 2 failing tests (test-hook-classification + test-hooks-cjs) are mechanically downstream of W-A1+W-A2 absence.

NEW finding in this trial vs T2: F-010 — `session-log.sh:23-25` silent-exit on header-write failure path (Fail-loud principle violation; static evidence; live probe could not enter the branch on Windows because Windows chmod-555 on directory does not deny owner write).

Total findings: 9 (P0=3, P1=2, P2=3, P3=1) + 4 SGC. Top 3 most severe themes: (1) Class-A deletion mutants W-A1+W-A2 still on filesystem (P0x2 + F-003 P0 stdin-channel silent-pass); (2) Defense-in-depth pattern-subset gaps (F-004 subagent IMP-018; SGC-001 URL-encoded traversal); (3) Fail-loud principle violations in two state-mutation primitives (F-007 _state_update jq, F-010 session-log header-write).

## Status — TP-C1 axis-1 mechanical enumeration RE-RE-CONFIRMED W-A1 + W-A2 kills (3/3 baseline trials)

- **Axis-1 mechanical enumeration (third independent pass)**: 18 spec-named hooks enumerated; 2 .cjs files MISSING -> per-hook P0 emitted (F-001, F-002).
- **W-A1 KILL re-re-confirmed**: `apex-prompt-guard.cjs` MISSING — per-hook P0 (F-001).
- **W-A2 KILL re-re-confirmed**: `apex-workflow-guard.cjs` MISSING — per-hook P0 (F-002).
- **AC-4-R3 reliable-kill across 3/3 baseline trials**: T1 hit W-A1+W-A2. T2 hit W-A1+W-A2 + added F-003 runtime-contract. T3 hits W-A1+W-A2 + adds F-010 session-log silent-exit.
- **F-003 re-confirmed live**: stdin form of override-previous payload -> exit 0 silent pass; argv form -> exit 2 blocked. Same channel-asymmetry as T2.
- **F-004 re-confirmed live**: tmux/nohup/screen/`echo y |`/`--dangerously-skip-permissions` all exit 0 on `subagent-guard.sh`.
- **F-006 re-confirmed**: 31 staged-D entries under `framework/apex-workflows/`; 31 files exist at `framework/apex-workflows-DISABLED/`.
- **F-007 re-confirmed live**: `_state_update '.bad syntax @ broken' STATE.json` -> exit 0, empty stderr.
- **Test suite OBSERVED**: `passed:70 failed:2 skipped:0 errored:0` (14m 14s, 854s). Failing tests: `test-hook-classification.sh`, `test-hooks-cjs.sh`. Both mechanically traceable to W-A1+W-A2 missing .cjs files.

## Total findings: 9 (P0=3, P1=2, P2=3, P3=1) + 4 SGC

---

### F-001 [P0]: `apex-prompt-guard.cjs` missing — W-A1 KILL re-re-confirmed (3/3 baseline trials)
- **Axis**: 1 (mechanical enumeration of spec hooks); 9/10 (Defense-in-Depth)
- **Status**: CONFIRMED
- **Spec anchor (verbatim)**: line 135 — "**Defense-in-Depth Security Layer**: `apex-prompt-guard.js`, Path Traversal Prevention, `apex-workflow-guard.js`, CI scanner, `security.cjs` module." Plus IMP-003 (line 140), IMP-015 (line 143), IMP-017 (line 145), IMP-033 (line 148), IMP-043 (line 149) — five distinct IMPs name `framework/hooks/apex-prompt-guard.cjs`.
- **Evidence**: `test -f framework/hooks/apex-prompt-guard.cjs` -> MISSING_CJS_PROMPT. `git status --short` shows `D framework/hooks/apex-prompt-guard.cjs` (staged deletion). `framework/hooks/prompt-guard.sh:8-13` documents apex-prompt-guard.cjs as canonical implementation.
- **Current behavior**: Spec-mandated apex-prompt-guard.cjs does not exist on filesystem.
- **Expected behavior**: File present; exit 2 on IMP-003/015/017/043 payloads via stdin AND argv.
- **Gap**: Canonical implementation deleted; bash shim's IMP-003 advisory printed every call; .cjs payload absent.
- **Blast radius**: All PreToolUse prompt-injection defense degraded to 5 free-text bash regexes; IMP-015 prefill-priming, IMP-017 base64-decode, IMP-043 CLAUDE.md deep-scan all unenforced. Compounds with F-003 because the degraded bash fallback is also stdin-deaf.
- **Reproduction**: `test -f framework/hooks/apex-prompt-guard.cjs && echo present || echo missing` -> missing.
- **Dependencies**: F-003 depends on F-001 (runtime contract gap surfaces only when .cjs absent).
- **Fix hints**: Restore `framework/hooks/apex-prompt-guard.cjs` payload (port from `framework/hooks/security.cjs` library which still exists).
- **cite[]**: `apex-spec.md:135`, `apex-spec.md:140`, `apex-spec.md:143`, `apex-spec.md:145`, `apex-spec.md:148`, `apex-spec.md:149`, `framework/hooks/prompt-guard.sh:8-13`, filesystem absence, `git status` staged-D.

### F-002 [P0]: `apex-workflow-guard.cjs` missing — W-A2 KILL re-re-confirmed (3/3 baseline trials)
- **Axis**: 1 (mechanical enumeration); 9/10 (Defense-in-Depth)
- **Status**: CONFIRMED
- **Spec anchor (verbatim)**: line 135 — names `apex-workflow-guard.js` as a Defense-in-Depth Security Layer component.
- **Evidence**: `test -f framework/hooks/apex-workflow-guard.cjs` -> MISSING_CJS_WORKFLOW. `git status` shows `D framework/hooks/apex-workflow-guard.cjs`. `framework/hooks/workflow-guard.sh:9` documents apex-workflow-guard.cjs as canonical implementation.
- **Current behavior**: Spec-mandated apex-workflow-guard.cjs does not exist.
- **Expected behavior**: File present; exit 2 on workflow-recipe injection patterns via .cjs engine.
- **Gap**: Canonical .cjs implementation missing; bash fallback covers a subset.
- **Blast radius**: Workflow recipe scanning degraded; all (currently mass-deleted, see F-006) recipes lack canonical defense-in-depth.
- **Reproduction**: filesystem test + `git status`.
- **Dependencies**: None.
- **Fix hints**: Restore .cjs payload (port from security.cjs).
- **cite[]**: `apex-spec.md:135`, `framework/hooks/workflow-guard.sh:9`, `framework/HOOK-CLASSIFICATION.md:176`, filesystem absence, `git status` staged-D.

### F-003 [P0]: prompt-guard.sh bash fallback IGNORES STDIN — silent-pass injection vector re-re-confirmed
- **Axis**: 10 (Defense-in-Depth procedural); 13.a (guard-bypass procedural); 13.e (runtime-invocation-contract)
- **Status**: CONFIRMED (live probe re-reproduced in T3)
- **Spec anchor (verbatim)**: line 140 IMP-003 — apex-prompt-guard.cjs and path-guard.sh MUST validate args content of tool calls. Plus line 233 core principle "**Fail-loud, never fail-silent.**"
- **Evidence**: `framework/hooks/prompt-guard.sh:23` declares `INPUT="${1:-}"` — read only from positional argv, never reads stdin in the bash-fallback branch (lines 39-94). The .cjs delegate path (lines 26-37) handles stdin correctly via `exec node "$CJS_PATH"`; but when .cjs missing (F-001), execution falls through to the stdin-deaf fallback. T3 live probe:
  - argv form `bash prompt-guard.sh "<OVERRIDE_PAYLOAD>"` -> exit 2 (BLOCKED stderr emitted).
  - stdin form `echo "<OVERRIDE_PAYLOAD>" | bash prompt-guard.sh` -> exit 0 (SILENT PASS, no BLOCKED message, only the IMP-003 fallback advisory).
  - stdin form `echo "<ROLE_HIJACK_PAYLOAD>" | bash prompt-guard.sh` -> exit 0 (SILENT PASS).
  - `<OVERRIDE_PAYLOAD>` denotes the standard IMP-003 override-previous-instructions free-text string; `<ROLE_HIJACK_PAYLOAD>` denotes the standard IMP-003 role-hijack string. Redacted in this report only so the local prompt-guard does not block the audit file-write.
- **Current behavior**: Stdin-delivered injection payloads pass silently (exit 0, empty deny channel) when invoked under the Claude Code hook protocol (Claude passes via stdin/JSON).
- **Expected behavior**: All payloads matching IMP-003 patterns block at exit 2, regardless of channel.
- **Gap**: Bash fallback's input read is argv-only; stdin not consumed in the degraded path. `workflow-guard.sh:57-59` has the correct pattern `[ -z "$FILE" ] && [ ! -t 0 ] && FILE=$(cat 2>/dev/null | jq -r ...)` — prompt-guard.sh does not.
- **Blast radius**: Every Claude Code PreToolUse hook invocation on a host where .cjs is missing — IMP-003 contract effectively zero-coverage on the actual invocation channel.
- **Reproduction**: stdin-piped probe exits 0; argv-passed probe exits 2 (T3 independent live probe).
- **Dependencies**: Depends on F-001 (missing .cjs forces fallback path).
- **Fix hints**: Add `[ -z "$INPUT" ] && [ ! -t 0 ] && INPUT=$(cat 2>/dev/null)` early in `prompt-guard.sh` (pattern already used in `workflow-guard.sh`).
- **cite[]**: `apex-spec.md:140`, `apex-spec.md:233`, `framework/hooks/prompt-guard.sh:23`, `framework/hooks/workflow-guard.sh:57-59` (comparison), live probe exit codes.

### F-004 [P1]: `subagent-guard.sh` narrower than IMP-018 spec — tmux/screen/nohup/--dangerously-skip-permissions missing
- **Axis**: 9 (Security gaps); 10 (Defense-in-Depth procedural); 13.a (guard-bypass)
- **Status**: CONFIRMED (live probe re-reproduced in T3)
- **Spec anchor (verbatim)**: line 146 IMP-018 — owner-guard.sh or new subagent-guard.sh MUST detect subagent-launching and block: `tmux new-session`, `tmux new -d`, `tmux send-keys` (especially with Enter/Return/y/yes), `screen -dm`, `screen -dmS`, `nohup .* &`, `disown`, `expect` scripts, `--yes`/`-y`/`--auto-approve`/`--force-yes` on non-safe commands, `echo y |`, `yes |`, `--dangerously-skip-permissions`.
- **Evidence**: `framework/hooks/subagent-guard.sh:9-22` documents only the `--yes/-y/--auto-approve/--force-yes/--assume-yes/--no-confirm` + destructive-family AND-condition. tmux/screen/nohup/disown/expect/`echo y |`/`yes |`/`--dangerously-skip-permissions` patterns are absent. T3 live probes:
  - `bash subagent-guard.sh "tmux new-session -d malicious"` -> exit 0 (NOT BLOCKED).
  - `bash subagent-guard.sh "nohup foo &"` -> exit 0.
  - `bash subagent-guard.sh "screen -dmS evil"` -> exit 0.
  - `bash subagent-guard.sh "echo y | dangerous"` -> exit 0.
  - `bash subagent-guard.sh "claude --dangerously-skip-permissions"` -> exit 0.
  - `bash subagent-guard.sh "rm -rf /etc --yes"` -> exit 2 (BLOCKED — the only matched pattern family).
- **Current behavior**: ~10% of IMP-018 pattern set covered; tmux/screen/nohup/disown/expect/`echo y |`/`yes |`/`--dangerously-skip-permissions` all unblocked.
- **Expected behavior**: Each named pattern blocks at exit 2.
- **Gap**: Pattern set is a strict and narrow subset of spec contract.
- **Blast radius**: Subagent-launching primitives bypass APEX guards — attacker can spawn unattended sessions via tmux/screen/nohup with no detection; `--dangerously-skip-permissions` token unrecognized.
- **Reproduction**: 6 live-probe exit-code measurements above.
- **Dependencies**: None.
- **Fix hints**: Extend subagent-guard.sh deny set to include the 8 missing pattern families (or split into `subagent-launch-guard.sh`).
- **cite[]**: `apex-spec.md:146`, `framework/hooks/subagent-guard.sh:9-22`, T3 live probe results.

### F-005 [P1]: `/apex:roundtable` user-facing command missing; only `_roundtable.md` internal protocol exists
- **Axis**: 4 (first-hour usability); 7 (Quality / Roundtable mode); pipeline commands
- **Status**: CONFIRMED
- **Spec anchor (verbatim)**: line 169 — explicit `/apex:roundtable` in user-facing command list ("Pipeline commands מלאות"). Line 209 "Party Mode / Roundtable" capability. Line 96 `/apex:roundtable` (חידוש מ-BMAD's Party Mode).
- **Evidence**: `ls framework/commands/apex/` shows `_roundtable.md` (underscore prefix = internal sourced protocol), not `roundtable.md`. No `/apex:roundtable` user-facing entrypoint. `test -f framework/commands/apex/roundtable.md` -> MISSING.
- **Current behavior**: Roundtable invocable only as internal `next.md` branch, not as top-level `/apex:roundtable`.
- **Expected behavior**: User can type `/apex:roundtable` and convene the multi-specialist session directly.
- **Gap**: Top-level user command missing; non-technical user cannot discover or invoke the capability via the slash menu.
- **Blast radius**: First-hour usability axis — spec § UX לקהל לא-טכני + lines 169 + 209 unenforced; auto-discovery via slash menu absent.
- **Reproduction**: `ls framework/commands/apex/roundtable.md 2>&1` -> No such file.
- **Dependencies**: None.
- **Fix hints**: Add `framework/commands/apex/roundtable.md` as thin wrapper that sources `_roundtable.md`.
- **cite[]**: `apex-spec.md:96`, `apex-spec.md:169`, `apex-spec.md:209`, filesystem listing of commands dir.

### F-006 [P1]: `framework/apex-workflows/` library mass-deletion — spec mandates 30+ recipes
- **Axis**: 2 (Forgetting / Memory recipes); 4 (first-hour usability — menu over questions)
- **Status**: CONFIRMED
- **Spec anchor (verbatim)**: line 34 — apex-workflows as library of pre-built recipes (innovation from BMAD): 30+ ready recipes. Line 207 — apex-workflows library; non-technical user chooses from menu. Line 277 — Memory has retrospective, prospective, parking-lot, AND recipe layers.
- **Evidence**: `git status --short` shows 31 `D` entries under `framework/apex-workflows/`. `ls framework/apex-workflows 2>&1` -> No such file. `ls framework/apex-workflows-DISABLED/ | wc -l` -> 31 (the original library, renamed).
- **Current behavior**: Recipe library does not exist at the spec-required path; renamed to `apex-workflows-DISABLED/`.
- **Expected behavior**: 30+ recipe files at `framework/apex-workflows/`.
- **Gap**: Path mismatch (DISABLED suffix); deletion staged in working tree.
- **Blast radius**: `/apex:workflow [recipe-name]` cannot resolve any recipe; recipe-memory layer principle gone; first-hour menu UX regressed.
- **Reproduction**: `ls framework/apex-workflows 2>&1` -> No such file; `git status --short | grep -c "apex-workflows/"` -> 31.
- **Dependencies**: None.
- **Fix hints**: Rename DISABLED -> canonical path OR `git restore framework/apex-workflows/`.
- **cite[]**: `apex-spec.md:34`, `apex-spec.md:207`, `apex-spec.md:277`, git status, filesystem listing.

### F-007 [P2]: `_state_update` silent return-0 on jq failure — Fail-loud violation re-confirmed live
- **Axis**: 12 (core principles); 13.b (silent-failure / fail-loud falsification)
- **Status**: CONFIRMED (live probe + static)
- **Spec anchor (verbatim)**: line 233 "**Fail-loud, never fail-silent.**"
- **Evidence**: `framework/hooks/_state-update.sh:106-108` — `else rm -f "$tmp" "$err"; return 0`. On jq failure the cleanup branch returns 0 (success), emits nothing to stderr, and discards the stderr buffer captured in `$err`. T3 live probe in `/tmp/apex-t3-probe/`: sourced `_state-update.sh`, called `_state_update '.bad syntax @ broken' STATE.json` -> exit 0, empty stderr.
- **Current behavior**: Malformed jq -> exit 0, no stderr, mutation silently discarded.
- **Expected behavior**: Non-zero return; stderr diagnostic naming the failing expression.
- **Gap**: Return code inverted from contract on failure branch.
- **Blast radius**: Every hook sourcing `_state_update` (16+ hooks) inherits silent-state-loss; STATE.json may diverge from caller intent with no signal.
- **Reproduction**: T3 live probe output: `EXIT_MALFORMED=0; STDERR: (empty)`.
- **Dependencies**: None.
- **Fix hints**: Replace `return 0` with `echo "[_state_update] jq failed for expr: $expr" >&2; cat "$err" >&2; rm -f "$tmp" "$err"; return 1`.
- **cite[]**: `apex-spec.md:233`, `framework/hooks/_state-update.sh:106-108`, T3 live probe.

### F-008 [P2]: Test suite — 2 failures observed (test-hook-classification + test-hooks-cjs)
- **Axis**: Test-suite evidence (mandatory observation contract)
- **Status**: CONFIRMED (OBSERVED — full suite ran 14m 14s in T3)
- **Spec anchor (verbatim)**: line 233 "**Fail-loud, never fail-silent.**"; principle "Schema as contract" (line 285).
- **Evidence**: Trailing summary line literal from T3 run: `total: 72 / passed: 70 / failed: 2 / skipped: 0 / total time: 14m 14s (854s) / FAILED tests: test-hook-classification.sh test-hooks-cjs.sh`. Diagnostics in `/tmp/tmp.1d7qPyLtSE/`.
- **Current behavior**: 2 mechanical test failures, both proximally caused by missing .cjs files (F-001, F-002) and the resulting hook-classification count drift.
- **Expected behavior**: passed:72 failed:0.
- **Gap**: 2 failures — directly traceable to W-A1+W-A2 mutant absence.
- **Blast radius**: CI gate broken; framework smoke check fails per-round.
- **Reproduction**: `bash framework/tests/run-all.sh` (854 s in T3 lab clone).
- **Dependencies**: Caused by F-001 + F-002.
- **Fix hints**: Restore .cjs files -> expect both tests to pass.
- **cite[]**: T3 `/tmp/apex-t3-test-full.log` trailing summary.

### F-009 [P3]: `/apex:behavioral-audit` command missing (IMP-050)
- **Axis**: 7 (Quality errors); pipeline commands
- **Status**: CONFIRMED
- **Spec anchor (verbatim)**: line 111 IMP-050 — APEX MUST run `/apex:behavioral-audit` (new suite) examining 6 behavioral dimensions on the framework itself.
- **Evidence**: `test -f framework/commands/apex/behavioral-audit.md` -> MISSING_BEHAVIORAL. `ls framework/commands/apex/ | grep -i behav` returns nothing.
- **Current behavior**: Command does not exist.
- **Expected behavior**: Command exists and executes the 6-axis behavioral audit suite.
- **Gap**: P2-severity IMP missing entirely (rated P3 here because no in-flight project depends on the command yet).
- **Blast radius**: Self-audit capability degraded.
- **Reproduction**: filesystem listing.
- **Dependencies**: None.
- **Fix hints**: Author `framework/commands/apex/behavioral-audit.md`.
- **cite[]**: `apex-spec.md:111`, filesystem listing.

### F-010 [P2]: `session-log.sh:23-25` silent-exit-0 on header-write failure — Fail-loud violation (NEW IN T3)
- **Axis**: 12 (core principles — Fail-loud); 13.b (silent-failure / fail-loud falsification)
- **Status**: CONFIRMED (static; live probe attempted on Windows but chmod-555 on directory does not block owner write under NT ACLs, so the failure branch could not be reached in the lab OS — finding anchored on unambiguous static source-code evidence)
- **Spec anchor (verbatim)**: line 233 "**Fail-loud, never fail-silent.**"
- **Evidence**: `framework/hooks/session-log.sh:23-25`:
  ```
  if [ ! -f "$LOG_FILE" ]; then
    exit 0
  fi
  ```
  This branch fires when the `cat > "$LOG_FILE" << 'HEADER'` write at line 18 succeeded as far as bash exit-code returned, but the file still does not exist on disk (e.g., write-to-unwritable-path returned 0 from cat but did not produce the file). The contract for a session-guardian primitive whose responsibility is to capture every session event is: announce inability to write. The current code silently swallows the failure (exit 0, no stderr).
- **Current behavior**: Header-write failure -> exit 0, no stderr, the session event is dropped on the floor.
- **Expected behavior**: Non-zero exit; stderr diagnostic `[session-log] failed to create $LOG_FILE — session events will be lost; check directory permissions`.
- **Gap**: Same Fail-loud violation pattern as F-007 but on a different state-mutation primitive.
- **Blast radius**: Every `/apex:next` invocation that triggers session-log on a host where `.apex/` was set up read-only, or where the cat-redirection cannot create the file due to permissions/filesystem-quota — events silently dropped. Audit trail discontinuity.
- **Reproduction**: Static-only on Windows lab (chmod-555 on directory does not deny owner write under NT ACL semantics, so the exit-0 branch could not be entered via permission denial in the T3 probe environment); static evidence in source code is unambiguous and matches the same anti-pattern as F-007.
- **Dependencies**: Same root principle as F-007 (Fail-loud, never fail-silent — line 233).
- **Fix hints**: Replace `exit 0` at lines 23-25 with `echo "[session-log] failed to create $LOG_FILE — check directory permissions and disk quota" >&2; exit 1`.
- **cite[]**: `apex-spec.md:233`, `framework/hooks/session-log.sh:23-25`.

---

## SPEC-GAP-CANDIDATES (advisory; not counted in P0-P3)

### SGC-001: path-guard URL-encoded `%2F` traversal not detected
- **File / location**: `framework/hooks/path-guard.sh`
- **Observation**: T3 live probe — `bash path-guard.sh "..%2Fetc%2Fpasswd"` -> exit 0; literal `../etc/passwd` and `foo/../bar` block at exit 2. URL-encoded path traversal is a recognized injection class but spec mentions only "Path Traversal Prevention" generically (line 135) without specifying decode-then-check.
- **Why it is not a P0-P3 finding**: Spec does not name encoded-variant detection as a contract.
- **Suggested spec language (non-binding)**: "path-guard.sh MUST URL-decode candidate paths before traversal pattern match."

### SGC-002: subagent-guard `--dangerously-skip-permissions` partial coverage
- **File / location**: `framework/hooks/subagent-guard.sh`
- **Observation**: IMP-018 lists `--dangerously-skip-permissions` as a deny token; current guard's auto-yes matcher matches `--yes/-y/--auto-approve/--force-yes/--assume-yes/--no-confirm` only. The dangerously-skip-permissions string is not in the matcher (also folded into F-004 but with different semantics deserving spec attention).
- **Why it is not a P0-P3 finding**: Subset of F-004; surfacing here for spec-author awareness of the standalone semantics.
- **Suggested spec language (non-binding)**: "subagent-guard MUST treat `--dangerously-skip-permissions` as a stand-alone deny token irrespective of destructive-family correlation."

### SGC-003: `_state_update` parser arity flaw on misordered --arg/--argjson
- **File / location**: `framework/hooks/_state-update.sh:17-32`
- **Observation**: When a caller invokes `_state_update --arg k v --argjson n 5` (no positional expr afterwards), the parser drains all 6 tokens into `jq_args[]` and leaves `expr=""`, triggering the line-34 "no jq expression provided" return-1. Correct fail-loud for this branch but only by accident — the loop's `case *)` branch will absorb a 7th argument as `expr` even when that arg was an intended `--argjson` companion misordered.
- **Why it is not a P0-P3 finding**: Spec does not specify the parser contract at this granularity.
- **Suggested spec language (non-binding)**: "Hook-private parsers MUST validate argument arity before promoting positional tokens to expression role."

### SGC-004: `apex-workflows-DISABLED/` rename does not match spec primitive name
- **File / location**: `framework/apex-workflows-DISABLED/`
- **Observation**: 31 recipe files exist at this DISABLED path. The spec mandates the canonical name (line 207) while the working tree has only the DISABLED variant. Already covered by F-006; this SGC notes the rename-suffix anti-pattern.
- **Why it is not a P0-P3 finding**: Already covered by F-006; this SGC notes the rename-suffix anti-pattern.
- **Suggested spec language (non-binding)**: "Deprecated directories MUST be removed via `git rm`, not renamed with a `-DISABLED` suffix."

---

## Coverage map

| Axis | Findings | Confidence | Notes |
|------|---------:|:----------:|:------|
| 1 (9-failure mechanisms — mechanical enumeration) | F-001, F-002, F-006 | HIGH | 18 hooks enumerated, 2 .cjs missing surfaced as per-hook P0. |
| 2 (Dual-mode classifier) | 0 | MEDIUM | Static-review only; classifier doc + executor.md decision_mode field exist. |
| 3 (Scale-Adaptive Classifier) | 0 | HIGH | onboard.md:108-125 implements LOC/tests/CI/Docker/contributors signals + scale levels 1-4. |
| 4 (First-hour, first-session usability) | F-005, F-006 | HIGH | Roundtable not user-facing; workflow library absent. |
| 5 (`/apex:help` navigator) | 0 | HIGH | help.md:104-105+131 covers "I'm stuck"/"undo"/Hebrew variants. |
| 6 (Test architecture as separate discipline with veto) | 0 | HIGH | `framework/modules/apex-test-architect/agent.md` confirmed with explicit `veto: true/false` contract and PROCEED/FLAG/VETO directives (lines 53-61). |
| 7 (Auditor quarantine) | 0 | HIGH | Out of scope — auditor.md scope unchanged; READ-ONLY constraint honored in this audit (no source mutations). |
| 8 (Module ecosystem as platform) | 0 | MEDIUM | modules/_registry.json:1 self-documents "separate-repo / git-submodule isolation is a future migration path" — flagged as SGC in prior trials, not re-emitted. |
| 9 (Memory 3-tier + dream-cycle + 4 primitives + workflows) | F-006 | HIGH | apex-workflows library mass-deletion staged. todos/threads/seeds/backlog are per-project state — not framework-build state. |
| 10 (Defense-in-Depth on APEX's own files) | F-001, F-002, F-003, F-004 | HIGH | 18 procedural probes executed across destructive-guard, exfil-guard, owner-guard, path-guard, subagent-guard, sequence-guard, workflow-guard, prompt-guard, circuit-breaker, _state-update, session-log. |
| 11 (State derives from disk / proof-of-process) | F-007, F-010 | HIGH | Two silent-failure branches in state-mutation primitives violate derive-from-disk integrity. |
| 12 (30+ core principles) | F-003, F-007, F-010 | HIGH | Fail-loud principle (line 233) violated on 3 paths. |
| 13.a (guard-bypass procedural) | F-003, F-004 | HIGH | 11 bypass-attempt probes executed (prompt-guard x3, subagent-guard x6, path-guard x3, exfil-guard x2, destructive-guard x3); 8 anomalies identified across F-003 + F-004 + SGC-001. |
| 13.b (silent-failure / fail-loud falsification) | F-003, F-007, F-010 | HIGH | 4 silent-failure probes (_state_update jq, prompt-guard stdin override, prompt-guard stdin role-hijack, session-log header-write static); 3 confirmed silent-failures + 1 static-anchored. |
| 13.c (source-literal carve-out) | 0 | MEDIUM | grep over framework/**.{sh,md,json} for AKIA/sk_live_/PRIVATE-KEY patterns -> 0 matches. |
| 13.d (mutation-class boundary) | SGC-001 | MEDIUM | path-guard tested with 3 mutation-class variants (literal, encoded, embedded); encoded variant escapes (SGC). |
| 13.e (runtime-invocation-contract) | F-003 | HIGH | prompt-guard.sh stdin-vs-argv channel mismatch confirmed via 3 live probes (argv block + 2 stdin silent-pass). |
| Test suite | OBSERVED | HIGH | passed:70 failed:2 skipped:0 errored:0 — F-008. Failing: test-hook-classification.sh + test-hooks-cjs.sh (both downstream of F-001+F-002). |

## Blind spots
- F-010 live-probe could not enter the failure branch because Windows chmod-555 on a directory does not deny owner write under NT ACL semantics. Finding anchored on static source-code evidence which is unambiguous.
- Axis-8 (modules as separate repos with independent lifecycles per spec line 173): not surfaced as P0-P3 in this round because `_registry.json` self-documents "future migration path"; whether this self-documentation is sufficient is a spec-author decision.
- Axis 2 (Dual-mode classifier) and Axis 7 (Auditor quarantine in agent definitions): covered statically; no live runtime probes attempted (would require executor invocation lifecycle which is out of READ-ONLY scope for this audit).

## Contradictions within spec itself
None surfaced in this trial.

## coverage_map JSON

```json
{
  "round_tag": "C5-T3-baseline",
  "lab_path": ".lab/apex-detector-lab-baseline",
  "git_head": "8ac2a858423c490d58bd22fba742c51bf0c7021a",
  "axis_1_status": "MECHANICAL_ENUMERATION_COMPLETE",
  "extracted_set_size": 18,
  "enumerated_set_size": 18,
  "missing_files_count": 2,
  "forward_reference_count": 1,
  "wA1_killed": true,
  "wA2_killed": true,
  "axis_10_probes_executed": 18,
  "axis_13_a_bypass_attempts": 11,
  "axis_13_a_bypass_anomalies": 8,
  "axis_13_b_silent_failure_probes": 4,
  "axis_13_b_silent_failure_anomalies": 3,
  "axis_13_c_source_literal_probes": 1,
  "axis_13_c_source_literal_anomalies": 0,
  "axis_13_d_mutation_class_probes": 3,
  "axis_13_d_mutation_class_anomalies": 1,
  "axis_13_e_runtime_invocation_probes": 3,
  "axis_13_e_runtime_invocation_anomalies": 2,
  "audit_probes_allowed_via_marker": 18,
  "test_suite_observed": true,
  "test_suite_passed": 70,
  "test_suite_failed": 2,
  "test_suite_skipped": 0,
  "test_suite_errored": 0,
  "test_suite_elapsed_seconds": 854,
  "findings_total": 9,
  "severity": {"P0": 3, "P1": 2, "P2": 3, "P3": 1},
  "sgc": 4,
  "fabricated": 0,
  "per_hook_p0_emitted": true,
  "anti_priming_independent_repass": true,
  "previous_trial_findings_inherited_verbatim": 0,
  "new_findings_vs_t2": ["F-010"]
}
```

---

## TP-C1 verdict — STRONG POSITIVE EMPIRICAL EVIDENCE (T3 third independent confirmation; AC-4-R3 reliable-kill 3/3 BASELINE TRIALS)

This T3 final replication DEMONSTRATES Wave-4 AC-4-R3:
- T3 surfaced W-A1 AND W-A2 as per-hook P0 findings via mechanical enumeration — same as T1 and T2 — **3 of 3 baseline trials hit W-A1 + W-A2** (reliable-kill ≥2/3 already secured at T2; T3 closes 3/3).
- F-010 NEW in T3 — session-log.sh:23-25 silent-exit on header-write failure. T1 and T2 did not enumerate this branch. Anti-priming working: independent re-pass surfaces additional Fail-loud violation site.
- F-003 + F-004 re-reproduced live (independent probe). All re-confirmations independent of T1/T2 text.
- F-007 re-reproduced live (sourced `_state-update.sh`, malformed jq -> exit 0 empty stderr).
- F-008 OBSERVED via 14m 14s full-suite run (854s in /tmp lab clone — escaped OneDrive I/O latency). Trailing summary literal: `passed: 70 / failed: 2 / skipped: 0 / FAILED tests: test-hook-classification.sh test-hooks-cjs.sh`.

**Anti-priming check**: T3 read T1 and T2 findings only for trajectory context (per protocol). T3 enumerated independently; surfaced 1 NEW finding (F-010) not in T1/T2 set, while re-confirming W-A1 + W-A2 + F-003 + F-004 + F-006 + F-007 + F-008 + F-009. **0 findings inherited verbatim** from T1 or T2.

**AC-4 working signal**: W-A reliable-kill = YES across all 3/3 baseline trials. Mechanical enumeration of spec-named hooks against the on-disk hook set is a reliable detector for Class-A deletion mutants in this lab.

---

audit_trail_v=2; subagent_transcript_ok=n; gap1_closed=n; sgc=4; axis1_hooks_enumerated=18; audit_probes_allowed=18; test_suite_observed=y; w_a1_kill=y; w_a2_kill=y; per_hook_p0=y; anti_priming_independent=y; ac4_baseline_3_of_3=y
