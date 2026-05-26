# AC-6B Independent Probe — Findings

**Auditor:** fresh probe, no prior-audit context loaded.
**Working tree:** `HEAD`, branch `main`. Single uncommitted artifact (`pinscope/package-lock.json`) untouched during the probe.
**Date:** 2026-05-26.

---

## Methodology used

Two complementary attack surfaces were probed:

1. **Behavioural probe (Axis-13 style):** every spec-named guard hook
   was invoked twice — once via the legacy positional-argv contract that
   the test suite exercises, once via the Claude Code stdin-envelope
   contract that `framework/settings.json` actually wires (every entry
   is of the form `bash ~/.claude/hooks/<name>.sh` with no positional
   args — Claude Code pipes `tool_input` as JSON on stdin). Wherever
   the two exit codes diverge, the hook silently bypasses under the
   real runtime invocation pattern.

2. **Test-suite probe:** `bash framework/tests/run-all.sh` was run end
   to end. Three suites fail (`test-circuit-breaker-recovery.sh`,
   `test-fix-plan-emit.sh`, `test-hook-classification.sh`). Per-suite
   diagnostics were captured and traced to either drift between the
   declared contract and the actual file-system state, or to
   implementation-vs-test contract drift.

3. **Cross-contract probe:** the three-way drift between (a) the spec
   anchor's `MUST` statements, (b) the JSON schemas under
   `framework/schemas/`, and (c) the hook/agent files that consume
   them.

Specific search techniques used:
- `Grep` for `COMMAND="${1:-}"` and `FILE="${1:-}"` patterns to enumerate
  hooks that read only positional argv. 11 hooks matched.
- Crafted `echo '{"tool_input":{"command":"..."}}' | bash <hook>.sh`
  payloads against five different attack families (rm -rf, force push,
  SQL drop, auto-yes destructive, encoded bypass) and observed exit
  codes — all returned 0 under the runtime envelope while returning 2
  under argv.
- `jq` on `framework/schemas/RESULT.schema.json` `.required` array
  vs. the `REQUIRED_KEYS` literals inside `schema-drift.sh`.
- Spec-vs-impl diff: `grep -oE "/apex:[a-z-]+" apex-spec.md | sort -u`
  vs. `ls framework/commands/apex/` to surface commands named in the
  spec but absent on disk.
- `ls framework/hooks/ | wc -l` vs. the **Category Totals** cell in
  `HOOK-CLASSIFICATION.md`.

---

## Total observations

- **Anchored findings: 11**
- P0: 1 (catastrophic guard-set bypass)
- P1: 4 (schema/spec/impl drift in guarded code paths)
- P2: 4 (cross-contract drift, missing commands, doc-vs-fs drift)
- P3: 2 (forward-reference stragglers, missing spec deliverables)

**Confidence:**
- Hooks plane: **HIGH** — reproduced bypasses with concrete payloads.
- Schemas plane: **HIGH** — direct `jq` diffs.
- Spec/agent plane: **MEDIUM** — `MUST` anchors checked but full
  exhaustive sweep not performed.
- Tests plane: **HIGH** — failures reproduced verbatim.

---

## Findings list

### F-001 [P0]: Eight spec-named guards bypass silently under the actual Claude Code stdin envelope

- **Files:**
  - `framework/hooks/destructive-guard.sh:25` (`COMMAND="${1:-}"`)
  - `framework/hooks/prompt-guard.sh:32` (Bash-fallback path, `INPUT="${1:-}"`, no stdin parse on the fallback branch)
  - `framework/hooks/path-guard.sh:16` (`FILEPATH="${1:-}"`)
  - `framework/hooks/quarantine-guard.sh:28` (`INPUT="${1:-}"`)
  - `framework/hooks/sequence-guard.sh:38-41` (`COMMAND="${1:-}"; [ -z "$COMMAND" ] && exit 0`)
  - `framework/hooks/exfil-guard.sh:37,46-48` (`COMMAND="${1:-}"; [ -z … ] && exit 0`)
  - `framework/hooks/subagent-guard.sh:31-35` (`COMMAND="${1:-}"; [ -z … ] && exit 0`)
  - `framework/hooks/grader-search-guard.sh:33-36` (`COMMAND="${1:-}"; [ -z … ] && exit 0`)
- **Spec anchor:**
  - `apex-spec.md` **§7 Working Principles**: "Fail-loud, never fail-silent."
  - `apex-spec.md` IMP-002 / IMP-005 / IMP-008 / IMP-014 / IMP-015 / IMP-016 / IMP-017 / IMP-018 — each names one of the above guards as MUST-block on specific patterns.
  - `framework/settings.json` lines 9-86 — every PreToolUse entry invokes the hook with `bash ~/.claude/hooks/<name>.sh` (zero positional args; Claude Code hook protocol pipes `tool_input` JSON on stdin).
  - `framework/hooks/apex-prompt-guard.cjs:46-65` documents the runtime contract: "stdin JSON — Claude Code hook protocol."
- **Evidence:**
  Each of the eight `.sh` guards reads input only from `${1:-}`. The actual `settings.json` invocation passes no positional argument. The `.cjs` ports (`apex-prompt-guard.cjs`, `apex-workflow-guard.cjs`) and the `.sh` shim for workflow-guard (`framework/hooks/workflow-guard.sh:54-59`) and for owner-guard (`framework/hooks/owner-guard.sh:62-69`) DO parse stdin — establishing that stdin parsing is the contract; the listed eight guards omitted it.
- **Reproduction:**
  ```
  echo '{"tool_input":{"command":"rm -rf /"}}'        | bash framework/hooks/destructive-guard.sh  ; echo $?
  # → 0   (contract requires 2)
  echo '{"tool_input":{"command":"git push --force"}}'| bash framework/hooks/destructive-guard.sh  ; echo $?
  # → 0
  echo '{"tool_input":{"command":"DROP TABLE users"}}'| bash framework/hooks/destructive-guard.sh  ; echo $?
  # → 0
  echo '{"tool_input":{"command":"cat .env"}}'        | bash framework/hooks/sequence-guard.sh     ; echo $?
  # → 0
  echo '{"tool_input":{"command":"rm -rf / --yes"}}'  | bash framework/hooks/subagent-guard.sh     ; echo $?
  # → 0
  echo '{"tool_input":{"command":"find . -name expected_answer"}}' | bash framework/hooks/grader-search-guard.sh ; echo $?
  # → 0
  echo '{"tool_input":{"file_path":".env.production"}}' | bash framework/hooks/path-guard.sh       ; echo $?
  # → 0
  APEX_ACTIVE_AGENT=auditor bash -c 'echo "{\"tool_input\":{\"file_path\":\"src/secret.ts\"}}" | bash framework/hooks/quarantine-guard.sh'; echo $?
  # → 0   (auditor quarantine bypassed)

  # For contrast, the same payloads via the test-only positional contract:
  bash framework/hooks/destructive-guard.sh "rm -rf /"                ; echo $?  # → 2
  bash framework/hooks/subagent-guard.sh    "rm -rf / --yes"          ; echo $?  # → 2
  bash framework/hooks/grader-search-guard.sh "find . -name expected" ; echo $?  # → 2
  ```
  All eight hooks block via argv; all eight pass-through via the
  runtime envelope. The Defense-in-Depth Security Layer named in the
  spec is therefore inactive under the actual installation path.
- **Suggested fix (optional):**
  Each hook needs the `[ -z "$VAR" ] && [ ! -t 0 ]` stdin fallback used by
  `workflow-guard.sh:57-59` (or `owner-guard.sh:62-69`):
  ```
  COMMAND="${1:-}"
  if [ -z "$COMMAND" ] && [ ! -t 0 ]; then
    COMMAND=$(cat 2>/dev/null | jq -r '.tool_input.command // empty' 2>/dev/null || true)
  fi
  ```
  Note that the existing unit tests pass argv positionally — no test
  exercises the stdin contract for the eight failing guards. The audit
  Axis-13 protocol in `framework/agents/specialist/framework-auditor.md:325-369`
  explicitly mandates probing the actual runtime invocation; a Round-N
  framework-auditor that read only the test-suite would never have seen
  this.

---

### F-002 [P1]: `schema-drift.sh` enforces 13 RESULT.json required fields; `RESULT.schema.json` declares 19

- **Files:**
  - `framework/hooks/schema-drift.sh:29` (`REQUIRED_KEYS='[…13 keys…]'`)
  - `framework/schemas/RESULT.schema.json:8-28` (`required` array, 19 entries)
- **Spec anchor:** `apex-spec.md` §"Schemas כחוזה אכיף. RESULT.json עם כל השדות." (line 347) and IMP-001 / IMP-025 / IMP-039.
- **Evidence:**
  `jq '.required' framework/schemas/RESULT.schema.json` returns 19 keys; the literal in `schema-drift.sh:29` lists 13. Missing from the PostToolUse enforcement hook: `task_start_sha`, `spec_sections_referenced`, `what_next_tasks_can_assume`, `verified_criteria`, `unverified_criteria`, `behavior_axes`. The fields are spec-required (IMP-001 explicitly demands `task_start_sha` in `RESULT.schema.json`; IMP-025 demands `behavior_axes`) but no PostToolUse hook will FAIL on their absence.
- **Reproduction:** `diff <(jq -r '.required[]' framework/schemas/RESULT.schema.json | sort) <(grep -oE '\"[a-z_]+\"' framework/hooks/schema-drift.sh | head -13 | tr -d '"' | sort)` — six missing on the drift side.
- **Suggested fix:** Lift the literal to a runtime read of `RESULT.schema.json.required` (or use `ajv` if jq-only is a hard constraint, fall back to `jq` enumeration of the schema's `.required[]`).

---

### F-003 [P2]: `HOOK-CLASSIFICATION.md` Category Totals claims 66; actual hook count is 67

- **File:** `framework/HOOK-CLASSIFICATION.md:200` ("**Total** | **66**")
- **Spec anchor:** Same doc, lines 7-13 — "the Category Totals table below re-derives the same value, and the CI assertion in `framework/tests/test-hook-classification.sh` (R7-011) re-runs the derivation on every push, FAILing on doc/filesystem drift so future additions cannot silently outpace this paragraph."
- **Evidence:** `ls framework/hooks/ | wc -l` returns 67. `test-hook-classification.sh` FAILS in the current run with the literal diagnostic `FAIL: Category Totals cell ('66') does not match file-system count (67)`. The contract self-described by the file is therefore in a failing state.
- **Reproduction:** `bash framework/tests/test-hook-classification.sh` → `Results: 5 passed, 3 failed`.
- **Suggested fix:** Identify the new hook (the diff between the table rows and the live `ls` listing) and add the corresponding row + bump the Total cell to 67.

---

### F-004 [P1]: `test-circuit-breaker-recovery.sh` asserts the v7 tool-call cap behaviour; circuit-breaker.sh now implements the v8 health-probe (IMP-V8-CB2)

- **Files:**
  - `framework/tests/test-circuit-breaker-recovery.sh:100-118` (asserts `EXIT_B == 2` on tool-call cap trip)
  - `framework/hooks/circuit-breaker.sh:172-226` (v8 behaviour: cap reached + health probe healthy → extend cap, exit 0)
- **Spec anchor:** `apex-spec.md` §1 IMP-V8-CB2 lines 85-86 — "CHECK 2 חייב לעבוד כ-health checkpoint תקופתי, לא כ-cap קשה. […] עבודה בריאה רצה כל עוד היא בריאה; ברגע שהיא נשברת — עצירה מיידית."
- **Evidence:** The test's Case B preloads `total_tool_calls_this_task=2, max_tool_calls_per_task=2` and expects exit 2. The hook's `STALE_DELTA=3` is not `>50`, no recurring error, no result-fishing — health probe HEALTHY → cap extended → exit 0. Three test assertions fail: `tool-call cap exits 2`, `tool-cap menu was written`, `stderr does not name RECOVERY_MENU.md`. The test was not updated when v8 (IMP-V8-CB2) landed.
- **Reproduction:** `bash framework/tests/test-circuit-breaker-recovery.sh` → "Results: 9 passed, 3 failed".
- **Suggested fix:** Either (a) update the test fixture to force health-probe FAIL via populated `recent_command_hashes[]` (>=5 identical), so the hook is exercised in its actual fire branch; or (b) restructure the test to assert both branches separately (healthy → exit 0, unhealthy → exit 2).

---

### F-005 [P1]: `test-fix-plan-emit.sh` circuit-breaker assertions duplicate F-004 — three more failing assertions trace to the same root

- **File:** `framework/tests/test-fix-plan-emit.sh` (last three assertions before "Results: PASS=34 FAIL=3").
- **Spec anchor:** Same IMP-V8-CB2 as F-004; plus R5-014 contract for `_fix-plan-emit.sh` (the contract is correct; the test invokes circuit-breaker on the wrong branch).
- **Evidence:** `bash framework/tests/test-fix-plan-emit.sh` ends with `FAIL: circuit-breaker exits 2 on tool-call cap`, `FAIL: circuit-breaker wrote FIX_PLAN.md (new path)`, `FAIL: circuit-breaker wrote RECOVERY_MENU.md (alias)`. The other 34 assertions pass.
- **Reproduction:** Same as F-004; same root cause.
- **Suggested fix:** Same as F-004 — when the cap-trip test fixture is upgraded to v8 contract in `test-circuit-breaker-recovery.sh`, mirror the change here.

---

### F-006 [P1]: `RESULT.schema.json` lacks the IMP-039 distinction the spec mandates (`tool_verified_criteria[]` vs `self_verified_criteria[]`)

- **Files:**
  - `framework/schemas/RESULT.schema.json:133-156` — only `verified_criteria[]` and `unverified_criteria[]` exist.
  - `framework/agents/executor.md` — `tool_verified` / `self_verified` strings not present (`Grep` returned no matches).
- **Spec anchor:** `apex-spec.md` IMP-039 (line 174 / §5 Hallucination):
  > "`framework/schemas/RESULT.schema.json` ו-`framework/agents/executor.md` חייבים להבחין בין `tool_verified_criteria[]` (אומת ע"י כלי חיצוני) ל-`self_verified_criteria[]` (סומן ע"י ה-executor עצמו); critic מתייחס ל-self-verified כ-untrusted by default."
- **Evidence:** Direct `Grep` over `framework/` returns zero hits for either string outside the spec file itself. The schema has a single un-typed `verified_criteria` array — no split, no per-criterion trust source.
- **Reproduction:** `grep -rn 'tool_verified_criteria\|self_verified_criteria' framework/ apex-spec.md` — only the spec file matches.
- **Suggested fix:** Either (a) implement IMP-039 (schema split + executor population + critic trust gating) or (b) move IMP-039 to a backlog item with a public status (the spec currently presents it as binding `חייבים`).

---

### F-007 [P2]: Spec-named `/apex:roundtable` and `/apex:behavioral-audit` commands do not exist; spec promises pipeline-level invocation

- **Files (missing):** `framework/commands/apex/roundtable.md`, `framework/commands/apex/behavioral-audit.md`
- **Spec anchors:**
  - `apex-spec.md:204` (§7 Quality): "**`/apex:roundtable`** (חידוש מ-BMAD's Party Mode): […]"
  - `apex-spec.md:315` (§Pipeline commands list): includes `/apex:roundtable` between `/apex:execute-phase` and `/apex:walkthrough` as a first-class pipeline command.
  - `apex-spec.md:219` IMP-050: "APEX חייב להריץ `/apex:behavioral-audit` (suite חדש) שבוחן 6 ממדים…"
- **Evidence:** `diff <(grep -oE '/apex:[a-z-]+' apex-spec.md | sort -u) <(ls framework/commands/apex/ | sed 's/\.md$//; s|^|/apex:|' | sort -u)` — `/apex:roundtable` and `/apex:behavioral-audit` appear only on the spec side. The implementation has `_roundtable.md` (underscore-prefixed, marked `Sourced by /apex:next`, not user-facing).
- **Reproduction:** `ls framework/commands/apex/ | grep -E '^(roundtable|behavioral-audit)\.md$'` → no output.
- **Suggested fix:** Either ship the user-facing commands (Rename `_roundtable.md` → `roundtable.md` and remove the "sourced-by" semantics, or wrap an entry-point `roundtable.md` that delegates), or amend the spec to use the internal `_roundtable` naming.

---

### F-008 [P2]: Spec annotation claims IMP-DR-005 is ADOPTED via `framework/hooks/handoff-sync.sh` + `STATE.json.handoff` field — neither exists

- **Files (missing):** `framework/hooks/handoff-sync.sh`, `framework/schemas/STATE.schema.json` `.properties.handoff`
- **Spec anchor:** `apex-spec.md:133`:
  > **Implementation status (2026-05-25):** ADOPTED via **Option (c) Hybrid Additive** — […] preserves all existing STATE.json fields untouched (zero blast radius on 118 readers) and ADDS a new top-level `handoff` field with the 5 sub-sections, populated by new hook `framework/hooks/handoff-sync.sh` that derives the narrative from existing state."
- **Evidence:**
  - `ls framework/hooks/handoff-sync.sh` → file not found.
  - `jq '.properties.handoff' framework/schemas/STATE.schema.json` → `null`.
  - `jq '.properties | keys' framework/schemas/STATE.schema.json` → no `handoff` key.
- **Reproduction:** Two commands above.
- **Suggested fix:** Either (a) ship the hook + schema field that the spec already claims as ADOPTED, or (b) downgrade the inline status note from ADOPTED to PLANNED. The current state is "spec claims done, code says no" — a falsifiable lie of the kind §5 IMP-001 was written to prevent.

---

### F-009 [P2]: Three PostToolUse Write|Edit hooks read only `$1`; Claude Code's Write|Edit envelope provides `file_path` on stdin

- **Files:**
  - `framework/hooks/post-write.sh:11` (`FILE="${1:-}"`)
  - `framework/hooks/ast-kb-check.sh:11` (`FILE="${1:-}"`)
  - `framework/hooks/schema-drift.sh:18` (`FILE="${1:-}"`)
- **Spec anchor:** `framework/settings.json:88-129` wires all three on PostToolUse `Write|Edit` matchers with `bash ~/.claude/hooks/<name>.sh` (no positional args). `apex-spec.md` §"Schema as contract. Schema sync as contract." (working principles) + IMP-021 (post-write hardcoded-secret block) + the Fail-loud principle.
- **Evidence:** Each hook contains no stdin parse. Repro:
  ```
  mkdir -p /tmp/probe && echo "const apikey='abc123longsecret'" > /tmp/probe/test.js
  echo '{"tool_input":{"file_path":"/tmp/probe/test.js"}}' | bash framework/hooks/post-write.sh ; echo $?
  # → 0   (contract requires 2 — hardcoded secret block)
  bash framework/hooks/post-write.sh /tmp/probe/test.js ; echo $?
  # → 2

  # schema-drift bypass on stdin:
  SB=$(mktemp -d); mkdir -p "$SB/.apex"; echo '{"invalid":' > "$SB/.apex/STATE.json"
  ( cd "$SB" && echo "{\"tool_input\":{\"file_path\":\"$SB/.apex/STATE.json\"}}" | bash <REPO>/framework/hooks/schema-drift.sh ) ; echo $?
  # → 0   (contract requires 2 — broken JSON)
  ```
- **Suggested fix:** Same one-line stdin fallback as F-001's suggested fix, but parsing `tool_input.file_path` instead of `tool_input.command`.

---

### F-010 [P3]: `apex-spec.md` references `framework/hooks/first-hour-telemetry.sh` as a forward-reference Phase 12 M16.1 sub-deliverable — file never shipped

- **Files (missing):** `framework/hooks/first-hour-telemetry.sh`
- **Spec anchor:** `apex-spec.md:744-746`:
  > Method: opt-in First-Hour-Telemetry event stream (`framework/hooks/first-hour-telemetry.sh`, forward-reference Phase 12 M16.1 sub-deliverable).
- **Evidence:** `find . -name first-hour-telemetry\*` → no matches. Phase 12 M16.1 already shipped `quality-drift.sh`, `_telemetry-emit.sh`, `dora-collect.sh` (all present); only `first-hour-telemetry.sh` is unmanifested. The "Claim — First-hour, first-session usability" honesty-contract paragraph references a measurement pipeline that does not exist.
- **Reproduction:** `find . -name 'first-hour-telemetry*'` returns nothing.
- **Suggested fix:** Either ship the hook or amend the "Method:" paragraph to point at an existing measurement path (e.g. derive the first-hour metric from `event-log.jsonl` filtering rather than naming a non-existent hook).

---

### F-011 [P3]: Two forward-reference banners reference paths that don't exist (`framework/PRIVACY-POLICY.md`)

- **Files referenced:** `framework/PRIVACY-POLICY.md` (×3 occurrences)
- **Actual path:** `framework/docs/PRIVACY-POLICY.md` (exists)
- **Spec anchor:** `apex-spec.md:735`, `:759`, `:784` — all three Honesty Contracts cite `framework/PRIVACY-POLICY.md` (forward-reference). The "forward-reference" banner suggests the file is yet to ship, but it shipped under a different path.
- **Evidence:** `find . -name PRIVACY-POLICY.md -not -path '*/.lab/*'` → only `framework/docs/PRIVACY-POLICY.md`. The three citations are out of date.
- **Reproduction:** `grep -n 'framework/PRIVACY-POLICY.md' apex-spec.md` → 3 hits.
- **Suggested fix:** Replace the three citations with `framework/docs/PRIVACY-POLICY.md` and drop the "forward-reference" qualifier (the file is live).

---

## Areas explicitly investigated with 0 findings

- `framework/agents/architect.md` — read top-to-bottom for procedural-vs-enforcement gaps; budget contract and READ-PARALLEL/WRITE-SERIAL clauses are anchored to test cases in `test-architect-budget.sh`. No untraced MUSTs.
- `framework/agents/auditor.md` PREFLIGHT contract (dispatch-contract verification, lines 32-58) — has a real enforcement layer in `_agent-dispatch.sh` and the `quarantine-guard.sh` carve-out (despite F-001 noting the runtime bypass, the contract structure itself is sound; the bypass is invocation-shape, not contract-shape).
- `framework/schemas/EVENT-LOG-ENTRY.schema.json` enum (48 entries) vs. the literal event-type strings emitted by hooks — every observed emission point produces a string that appears in the enum. No emit-vs-schema enum drift surfaced in the timebox.
- `framework/schemas/CONTEXT_BUDGET.schema.json`, `PLAN_META.schema.json`, `WAVE_MAP.schema.json`, `HEALTH_METRICS.schema.json` — only checked for obvious `additionalProperties` and `required` shapes; no drift visible at this depth.
- Test files — checked the broad shape and the failure modes. No vacuous `+0` patterns surfaced as load-bearing in the failed suites; the three failing suites all fail for legitimate contract reasons.

---

## Methodology lessons

If you found N findings: the techniques that surfaced them:

1. **Crafted a runtime-matching payload, not a unit-test payload.**
   The eight bypasses in F-001 were invisible to anyone who ran the
   in-repo unit tests, because every test passes the command as `$1`
   and asserts exit code. Once I crafted `echo '{"tool_input":...}'
   | bash <hook>.sh` to match the actual `settings.json` invocation,
   every guard fell over. **A shallow audit that read the hook source
   and trusted the test suite would have ratified the bypass as
   "documented and tested."** The `framework-auditor.md` Axis 13
   protocol explicitly demands this kind of behavioural probe; prior
   rounds appear to have skipped it.

2. **`jq` diff between schema `.required` and the hook literal that
   claims to enforce it.** F-002 fell out of one command — F-006 (the
   IMP-039 `tool_verified` distinction) fell out of `grep -rn` on the
   spec string. The lesson: when a spec says "schema X MUST contain
   Y," verify both halves of the conjunction. Many spec audits check
   "is the field declared anywhere?" and miss "is the field declared
   in the SCHEMA file the spec names?".

3. **Run the test suite end to end before reading any file.** Three
   failing suites at HEAD (F-003 / F-004 / F-005) are sitting in plain
   sight. A "0 findings" audit that did not run `run-all.sh` cannot
   have been an honest audit — these failures are surface-level and
   reproduce deterministically. The trajectory-of-evidence here is
   the most worrying meta-finding: the prior rounds either did not
   run the suite, or ran it and called the failures out-of-scope
   without recording them as P0/P1 in the audit findings. Either
   posture is a discipline gap.

4. **Compare the spec's `/apex:foo` invocations to the actual command
   files via `grep -oE | sort -u | comm`.** Two-second sweep that
   yielded F-007. Same shape works for hooks, agents, schemas — any
   contract where the spec names an artifact by name and the
   filesystem can be enumerated.

5. **`forward-reference` is a smell.** F-010 and F-011 surfaced by
   grepping for the literal phrase in the spec. Every forward-reference
   should have an `OWNER` and a `LANDS-BY-PHASE` tag; the three
   citations of `framework/PRIVACY-POLICY.md` are all "forward-
   reference" even though the file shipped — the tag was never
   retired. Stale forward-references are a common low-friction class
   of finding that lazy audits skip.

The bottom-line meta-insight: **the framework-auditor spec is
well-written; prior auditors appear to have followed the read-pass
half (Axis 1-12) and skipped the behavioural-falsification half
(Axis 13). That asymmetry is exactly what AC-6b is designed to
detect, and the answer is empirical: 11 findings, including one
catastrophic (F-001), against a "0 findings" baseline.**
