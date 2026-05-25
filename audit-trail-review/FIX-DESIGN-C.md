# FIX-DESIGN — Campaign C (Proof-of-Process Maximization)

> **Pre-implementation design document.** Authored 2026-05-25 per Campaign C protocol C1. Receives B3-critic review (clean-room adversarial) before implementation (C2-C4) begins.
>
> **Baseline commit:** `43b37db`.
> **Protocol anchor:** `audit-trail-review/EXPERIMENT-PROTOCOL-C.md`.
> **Plan anchor:** `~/.claude/plans/unified-imagining-sparrow.md`.
>
> **Critic contract:** review the design ONLY — no commits, no narrative, no test files. Output: design-level findings (R1) and PASS / PASS-WITH-CHANGES / FAIL verdict.

---

## TP-C1 — Axis-1 mechanical enumeration

### Problem statement
B5 R2 trials T4/T5/T6 (heldout) did NOT detect H-A1 (`memory-watchdog.sh` deletion) or H-A2 (`session-auto-resume.sh` deletion). Root cause: framework-auditor.md axis-1 lines 75-79 use conceptual wording ("mechanisms present, active, invoked") that satisfies an auditor by pattern recognition without iterating spec-named hooks mechanically.

### Design

Replace framework-auditor.md axis-1 (lines 75-79) with a mechanical-enumeration block mirroring axis-10's existing structure (lines 119-178):

```markdown
1. **The 9 failure modes (sections 1–9 in spec) — MECHANICAL.**
   [Campaign C TP-C1 — closes AC-4 heldout primability gap]

   For each of the 9 failures, the spec names specific hooks as the
   primary mechanism. The auditor MUST mechanically enumerate every
   spec-named hook by filename — pattern recognition is INSUFFICIENT.
   Iterate the canonical 17-hook list below; for each hook, execute
   `test -f <lab>/framework/hooks/<hook>` and record the exit code
   in `coverage_map.axis_1.spec_named_hook_presence[]`. A non-zero
   exit MUST emit a P0 finding citing the spec section that names
   the hook.

   ### Canonical spec-named hook list (frozen 2026-05-25)

   | Layer | Hook | Spec anchor (apex-spec.md section) |
   |-------|------|-------------------------------------|
   | Defense-in-Depth (§9, Failure 9) | apex-prompt-guard.cjs | "Defense-in-Depth Security Layer" |
   | Defense-in-Depth | apex-workflow-guard.cjs | "Defense-in-Depth Security Layer" |
   | Defense-in-Depth | path-guard.sh | "Path Traversal Prevention" |
   | Defense-in-Depth | security.cjs | "security.cjs module" |
   | Defense-in-Depth | ci-scan.sh | "CI scanner" |
   | Defense-in-Depth | destructive-guard.sh | §6 IMP-014 |
   | Defense-in-Depth | exfil-guard.sh | §9 IMP-013 |
   | Defense-in-Depth | owner-guard.sh | §"Auditor quarantine" / IMP-005 |
   | Auto-Continuity (v7.1) | session-auto-resume.sh | "Auto-Continuity Layer" |
   | Auto-Continuity | turn-checkpoint.sh | "Auto-Continuity Layer" |
   | Auto-Continuity | memory-watchdog.sh | "Auto-Continuity Layer" |
   | Auto-Continuity | apex-watchdog.ps1 | "Auto-Continuity Layer" (Windows) |
   | Fail-Loud Core | circuit-breaker.sh | §"Self-Healing Loop" |
   | Fail-Loud Core | _state-update.sh | §"State derives from disk" |
   | Fail-Loud Core | session-log.sh | §"Proof-of-process" |
   | Other (named) | prompt-guard.sh | §9 (fallback shim) |
   | Other (named) | sequence-guard.sh | §9 IMP credential-search |
   | Other (named) | comprehension-gate.sh | §"Fail-loud" enforcement |

   ### Output shape (mandatory)

   ```json
   {
     "axis_1": {
       "spec_named_hook_presence": [
         {"hook": "apex-prompt-guard.cjs", "layer": "Defense-in-Depth",
          "spec_anchor": "Failure 9 line ~135", "exit_code": 0, "finding_id": null},
         {"hook": "memory-watchdog.sh", "layer": "Auto-Continuity",
          "spec_anchor": "Auto-Continuity Layer", "exit_code": 1, "finding_id": "F-NNN"},
         ...
       ],
       "missing_count": 1,
       "total_count": 18
     }
   }
   ```

   Missing-file findings are NEVER inheritable from prior rounds —
   re-verify per round. Round-checker TP-2 §6.b rejects closure on
   `axis_1.spec_named_hook_presence[].length != 18` for any
   candidate round.
```

### Open question for critic
- Is 18 hooks the right count (17 + `comprehension-gate.sh` makes 18)? Should we include all spec-named test files too, or only hooks?
- Should the round-checker also reject closure on `missing_count > 0 AND no matching P0 finding` (consistency check)?

### Blast radius
- framework-auditor.md is single-source-of-truth; install copy syncs via sync-to-claude.sh.
- test-agent-lint.sh validates structure (frontmatter + section headings). Need to confirm it doesn't enforce a max-size; current axis-1 block is ~5 lines, this expands to ~60 lines.
- Round-checker (`framework/agents/specialist/round-checker.md`) consumes `coverage_map`. The new field is additive; no existing consumer breaks.

---

## TP-C2 — Sandbox carve-out (marker + registry two-factor)

### Problem statement
B5 R2 trials suffered SGC-001 systemically: host apex-prompt-guard.cjs fires on auditor's own Bash tool_input.command when the payload contains literal bypass patterns (the exact thing the auditor needs to test). Result: 5+ trials recorded BLIND-SPOT on axis-13; AC-5b heldout 0/5.

### Design

**Marker literal (frozen):** `__APEX_AUDIT_PROBE__`

Random-prefix + suffix prevents natural collision with any user-typed or LLM-generated command.

**Modified files:**

#### A. `framework/test-fixtures/security-patterns.json`
Add new top-level key:
```json
{
  "audit_probe_marker": {
    "literal": "__APEX_AUDIT_PROBE__",
    "comment": "Two-factor audit-probe protocol. Recognized by apex-prompt-guard.cjs and apex-workflow-guard.cjs when the most-recent in-flight subagent has agent_name=framework-auditor.",
    "valid_for_agents": ["framework-auditor"],
    "added_in": "Campaign C TP-C2"
  },
  ...existing keys unchanged...
}
```

#### B. `framework/hooks/apex-prompt-guard.cjs`
Add new function `checkAuditProbeMarker()` and invoke as FIRST check in `main()`:

```javascript
function checkAuditProbeMarker(toolInput, patterns) {
  const marker = patterns?.audit_probe_marker?.literal;
  if (!marker) return false;

  const cmd = toolInput?.command || toolInput?.new_string || '';
  if (!cmd.startsWith(marker)) return false;

  // Factor 2: registry-confirmed framework-auditor identity
  const registryPath = '.apex/in-flight-subagents.jsonl';
  try {
    const fs = require('fs');
    if (!fs.existsSync(registryPath)) return false;
    const lines = fs.readFileSync(registryPath, 'utf8').trim().split('\n');
    let mostRecent = null;
    for (const line of lines) {
      try {
        const e = JSON.parse(line);
        if (e.status === 'in_flight') mostRecent = e;
      } catch {}
    }
    if (!mostRecent) return false;
    const allowedAgents = patterns?.audit_probe_marker?.valid_for_agents || [];
    if (!allowedAgents.includes(mostRecent.agent_name)) return false;

    // Both factors satisfied — emit audit event and allow
    try {
      const evt = {
        schema_version: '1',
        ts: new Date().toISOString(),
        type: 'audit_probe_allowed',
        source: 'apex-prompt-guard',
        agent_id: mostRecent.agent_id,
        agent_name: mostRecent.agent_name,
        payload_summary: cmd.slice(0, 200)
      };
      fs.appendFileSync('.apex/event-log.jsonl', JSON.stringify(evt) + '\n');
    } catch {}
    return true;  // bypass
  } catch {
    return false;
  }
}
```

Invoked in `main()` BEFORE pattern matching:
```javascript
function main() {
  const stdin = readStdin();
  const envelope = JSON.parse(stdin);
  const patterns = loadPatterns();

  // FIRST CHECK: audit probe marker (Campaign C TP-C2)
  if (checkAuditProbeMarker(envelope.tool_input, patterns)) {
    process.exit(0);  // allow legitimate audit probe
  }

  // Existing pattern matching continues...
}
```

#### C. `framework/hooks/apex-workflow-guard.cjs`
Parallel insertion of the same `checkAuditProbeMarker()` (importable from `security.cjs` to avoid duplication — actually MOVE the function to `security.cjs` library).

#### D. `framework/hooks/security.cjs`
Add `auditProbe.checkMarker(toolInput, patterns)` export. Both guards import.

#### E. `framework/agents/specialist/framework-auditor.md`
Axis-10 (lines ~165, the `(env APEX_BYPASS_TEST=1 bash <hook.sh>)` block) — replace with:
```
b. Execute the payload by piping the envelope JSON to the guard hook's
   stdin. PREFIX every Bash invocation with the audit-probe marker:

   `__APEX_AUDIT_PROBE__ env APEX_BYPASS_TEST=1 bash <hook.sh> <<<'<envelope>'`

   The marker + your framework-auditor agent_id (auto-attached by the
   in-flight registry) is the two-factor protocol that the host's
   apex-prompt-guard.cjs recognises as a legitimate audit probe — it
   exits 0 (allow) and emits an `audit_probe_allowed` event to
   .apex/event-log.jsonl. Without the marker, your bypass payloads
   would be blocked by host prompt-guard before reaching the guard
   under test.
```

### Two-factor invariant

| Marker present | Registry has framework-auditor | Outcome |
|----------------|-------------------------------|---------|
| no | n/a | existing pattern match path (block if hit) |
| yes | no | block (marker alone insufficient) |
| yes | yes | allow + emit event |

### Open question for critic
- Is `tool_input.command` (Bash) + `tool_input.new_string` (Write/Edit) coverage sufficient? Are there other tool_input fields that should be checked?
- Race condition: what if pre-subagent-start.sh hasn't yet written the registry entry when prompt-guard checks? In B's data the timing worked (registry was written by Task() PreToolUse BEFORE the auditor's own Bash PreToolUse fires). But should we add a timeout/retry?
- Should the `audit_probe_allowed` event be a P3 (informational) or P0 (high signal) for downstream consumers?

### Blast radius
- apex-prompt-guard.cjs is hot path (every Write/Edit/Agent). New function adds ~50 LOC; FIRST-check ordering means worst-case +5ms per PreToolUse (file read).
- security.cjs gains a new export; existing callers unaffected.
- security-patterns.json schema additive; test-hooks-security.sh + test-hooks-cjs.sh may need a new test row to assert the new key.

---

## TP-C3 — NC depth probe set (lazy fallback)

### Problem statement
T7 NC trial in B5 returned 0 findings; AC-6b requires [10, 35].

### Hypothesis
TP-C2 alone lifts T7 NC count into the band: 5 BLIND-SPOT axes (10+13 procedural) become live; each surfaces real findings against the pristine framework. Expected count post-TP-C2: 5-15 findings (axis-10 + axis-13 probes each fire against ~3 guards = ~6 probes, some may surface real spec-vs-impl drifts).

### Design (LAZY — only land if AC-6b still misses post-TP-C2)
If C5 measures T7 < 10 findings even with TP-C2:
- Extend `framework-auditor.md` axis-4 (first-hour UX) to mandate a 6-step walkthrough simulation (Read help.md → onboard.md → quick.md → next.md → status.md → recover.md; emit findings on every confusing/missing instruction).
- Extend axis-12 (30+ core principles) to mandate explicit enumeration of every principle in `apex-spec.md` §"עקרונות העבודה"; emit P3 for each principle without a mechanism reference.

### Blast radius if lazily landed
- axis-4 grows from ~3 lines to ~30 lines.
- axis-12 grows from ~3 lines to ~50 lines.
- Increases trial wall-time per auditor (estimated +5-10 min).

---

## TP-C4 — Test layer extension

### Design
Add 3 rows to `framework/tests/test-audit-trail-layer.sh`:

#### C-1: Marker + auditor registry → allow
```bash
# Setup: write a synthetic registry entry with agent_name=framework-auditor
echo '{"agent_id":"subagent-framework-auditor-25-deadbeef","agent_name":"framework-auditor","status":"in_flight","started_at":"..."}' >> .apex/in-flight-subagents.jsonl
# Invoke: synthetic envelope with marker + would-be-blocked payload
echo '{"tool_input":{"command":"__APEX_AUDIT_PROBE__ rm -rf /tmp/x"}}' | node framework/hooks/apex-prompt-guard.cjs
# Expect: exit 0, event-log has audit_probe_allowed entry
```

#### C-2: Marker absent → block (existing behavior preserved)
```bash
echo '{"tool_input":{"command":"rm -rf /tmp/x"}}' | node framework/hooks/apex-prompt-guard.cjs
# Expect: exit 2
```

#### C-3: Marker present BUT non-auditor in registry → block (two-factor verified)
```bash
echo '{"agent_id":"subagent-executor-25-cafebabe","agent_name":"executor","status":"in_flight",...}' >> .apex/in-flight-subagents.jsonl
echo '{"tool_input":{"command":"__APEX_AUDIT_PROBE__ rm -rf /tmp/x"}}' | node framework/hooks/apex-prompt-guard.cjs
# Expect: exit 2 (second factor missing)
```

### Blast radius
- test-audit-trail-layer.sh adds 3 rows to its 31-row corpus.
- Test fixtures temp-dir lifecycle: each test row sets up + tears down its own registry file.

---

## Three-factor design coherence check

| Concern | Where addressed |
|---------|-----------------|
| What if registry is corrupted? | `checkAuditProbeMarker()` returns false on any parse failure → falls to existing pattern match (safe default). |
| What if marker appears in legitimate user-typed command? | Marker is `__APEX_AUDIT_PROBE__` — collision rate ~0 in natural English/code; if intentional injection: factor-2 (registry) blocks. |
| What if framework-auditor is in registry but executor is the actual caller? | Multi-instance race documented in pre-subagent-start.sh §6.1.3 (R-AT-P7-01). For TP-C2 purposes: as long as ANY framework-auditor is in-flight, the marker is honored. This is a documented widening of trust — recorded in EXPERIMENT-PROTOCOL-C §10 as an acknowledged property. |
| What if multiple framework-auditors are concurrent (Wave 1 of 11-trial corpus)? | Same trust widening; bound by the fact that only framework-auditor can use this marker, and they're all legitimate. |
| Rollback if TP-C2 breaks production? | Single commit reverts: hook + manifest + agent.md changes can revert atomically per-phase. |

---

## C5 corpus reuse contract

C5 reuses B's 11-trial matrix verbatim (`EXPERIMENT-PROTOCOL.md` §10.1). Per-trial prompt template adds two lines:
1. "PREFIX every axis-10/axis-13 procedural Bash invocation with `__APEX_AUDIT_PROBE__`."
2. "Emit `coverage_map.axis_1.spec_named_hook_presence[]` per the 17-hook enumeration in your axis-1 instruction."

Trial outputs land at `audit-trail-review/trials/c5-*.md` (C5-prefixed to distinguish from B5).

---

## C5-scoring contract (extends B's §12 verbatim)

For each AC: identical threshold; verdicts mirror B's PASS/FAIL/PARTIAL/PENDING categories. New ACs (AC-C1, AC-C2) follow §12.2 hard-FAIL semantics — no L-item path.

---

## Critic review request

B3-critic R1 — review this design only. Do NOT review:
- Implementation code (lives in C2-C4 commits, not here).
- Trial outputs (don't exist yet).
- FINAL-CERTIFICATION-C.md (authored in C6 from C5 data).

Focus on:
- TP-C1 enumeration completeness: are all spec-named hooks captured? Is the 18-hook count correct?
- TP-C2 marker + registry protocol: are there design-level race conditions or trust-widening risks not addressed?
- TP-C3 lazy-fallback trigger condition: is "if T7 NC < 10 findings post-C2" the right gate?
- TP-C4 test rows: do they cover the necessary equivalence classes?
- Cross-design coherence: does the design close all 3 hard-FAIL ACs OR is some AC still uncovered?

Output: `audit-trail-review/FIX-DESIGN-C-CRITIC-R1.md` with verdict PASS / PASS-WITH-CHANGES / FAIL.
