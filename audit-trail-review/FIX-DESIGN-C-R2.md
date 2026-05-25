# FIX-DESIGN-C — Round 2 (post B3-critic R1 PASS-WITH-CHANGES)

> **R1 verdict:** PASS-WITH-CHANGES — 4 BLOCKING (CR-C-01, CR-C-02, CR-C-05, CR-C-07) + 6 MAJOR + 4 MINOR. Re-submission required for the BLOCKERS + critical MAJORs (CR-C-03, CR-C-06, CR-C-11, CR-C-12, CR-C-14, CR-C-15). MINORs CR-C-04 / CR-C-08 / CR-C-09 folded in as bonus.
>
> **Baseline pin:** `43b37db`. **Protocol anchor:** `EXPERIMENT-PROTOCOL-C.md`. **R1 review:** `FIX-DESIGN-C-CRITIC-R1.md`.

---

## §0. Changelog (R1 → R2)

| Change | Closes | Severity |
|--------|--------|----------|
| Hook list locked at **15 spec-literal hooks**; dropped 3 principle-only entries | CR-C-01 | BLOCKING |
| AC-C1 threshold re-bound from "17 rows" → "15 rows exactly" in EXPERIMENT-PROTOCOL-C §3 update | CR-C-01 | BLOCKING |
| Per-hook finding emission required; round-checker REJECTS rollup escapes via pairing predicate | CR-C-02, CR-C-03 | BLOCKING/MAJOR |
| Marker protocol upgraded to **per-invocation HMAC nonce**: pre-subagent-start.sh writes `audit_probe_nonce` into registry; auditor reads own nonce; guard verifies | CR-C-05, CR-C-10 | BLOCKING |
| **Target hooks corrected**: `destructive-guard.sh`, `exfil-guard.sh`, `sequence-guard.sh` (PLUS `prompt-guard.sh` for Node-less fallback). Dropped `apex-workflow-guard.cjs` from scope (wrong tool surface). Factor logic moves to shared shell helper `_audit-probe-marker.sh` | CR-C-07, CR-C-06 | BLOCKING/MAJOR |
| Axis-1 entries gain `tool_call_event_ts` field (mirrors axis-10 integrity) | CR-C-04 | MINOR |
| `audit_probe_allowed` event gains `payload_sha1` | CR-C-08 | MINOR |
| Event-log write fails loudly to stderr (no silent catch) | CR-C-09 | MINOR |
| TP-C3 trigger gate explicit: evaluated after T7 of C5 completes; re-runs T7 only on miss | CR-C-11 | MAJOR |
| Test rows extended: C-1..C-6 (cover new_string, stopped status, etc.) | CR-C-12 | MAJOR |
| Axis-13 instruction extended with mutation-class-specific probe construction (regex, case-folding, silent-failure classes) | CR-C-14 | MAJOR |
| AC-6b escalation ladder gains Path C: §14 amendment recommendation if TP-C2+TP-C3 both miss | CR-C-15 | MAJOR |

---

## §1. TP-C1 — Axis-1 mechanical enumeration (R2)

### Closes: CR-C-01, CR-C-02, CR-C-03, CR-C-04 (MINOR)

### Final canonical list — **15 spec-literal hooks**

Three principle-only rows from R1 (`comprehension-gate.sh`, `_state-update.sh`, `session-log.sh`) DROPPED. They remain probed under axis-12 (30+ core principles) but do not block axis-1 enumeration. The remaining 15 are each verbatim-cited in `apex-spec.md`:

| Layer | Hook | Spec anchor (verbatim phrase in apex-spec.md) |
|-------|------|--------------------------------------------|
| Defense-in-Depth (§9 Failure 9 line 136) | apex-prompt-guard.cjs | "`apex-prompt-guard.js`" — extension equivalence per WORKING-CORPUS scorer rubric L02 |
| Defense-in-Depth | apex-workflow-guard.cjs | "`apex-workflow-guard.js`" — same |
| Defense-in-Depth | path-guard.sh | "Path Traversal Prevention" — file-name verbatim in HOOK-CLASSIFICATION |
| Defense-in-Depth | security.cjs | "`security.cjs` module" |
| Defense-in-Depth | ci-scan.sh | "CI scanner" — verbatim filename in HOOK-CLASSIFICATION |
| Defense-in-Depth (§6 IMP-014) | destructive-guard.sh | "destructive-guard" verbatim |
| Defense-in-Depth (§9 IMP-013) | exfil-guard.sh | "exfil-guard" verbatim |
| Defense-in-Depth (§9 IMP-005) | owner-guard.sh | "owner-guard" verbatim |
| Defense-in-Depth (fallback shim) | prompt-guard.sh | shim path cited in `apex-prompt-guard.cjs` header |
| Defense-in-Depth (§9 sequence) | sequence-guard.sh | "sequence-guard" verbatim |
| Auto-Continuity (v7.1 lines 434-437) | session-auto-resume.sh | verbatim |
| Auto-Continuity | turn-checkpoint.sh | verbatim |
| Auto-Continuity | memory-watchdog.sh | verbatim |
| Auto-Continuity | apex-watchdog.ps1 | verbatim (Windows) |
| Self-Healing core | circuit-breaker.sh | verbatim §"Self-Healing Loop" |

**"Spec-named" definition (per CR-C-01.3):** apex-spec.md verbatim ONLY. Campaign B's institutionalized B6 hooks (pre-subagent-start.sh, subagent-stop.sh, tool-event-logger.sh) are NOT in axis-1 — they live under axis-11 (proof-of-process) as documented in B5-AC-SCORING-R2.md.

### Updated axis-1 instruction block (replaces lines 75-79 of framework-auditor.md)

```markdown
1. **The 9 failure modes (sections 1–9 in spec) — MECHANICAL.**
   [Campaign C TP-C1 — closes AC-4 heldout primability gap]

   For each of the 9 failures, the spec names specific hooks. The
   auditor MUST mechanically enumerate every hook in the canonical
   15-hook list below. Pattern recognition is INSUFFICIENT.

   ### Procedure (per round, never inheritable)

   For each hook in the table:
   a. Execute `test -f <lab>/framework/hooks/<hook>` via a Bash
      tool_call (do NOT cache or batch — one tool_call per hook so
      each row has its own `tool_call_event_ts`).
   b. Record the exit code in `coverage_map.axis_1.spec_named_hook_presence[]`
      with shape: `{hook, layer, spec_anchor, exit_code,
      tool_call_event_ts, finding_id}`.
   c. If `exit_code != 0`, the auditor MUST emit a dedicated P0
      finding F-NNN with the hook's filename in `cite[]`. ONE rolled-up
      "baseline absent" finding does NOT discharge this duty —
      round-checker REJECTS closure on any
      `spec_named_hook_presence[i].exit_code != 0` lacking a matching
      F-NNN whose `cite[]` contains `framework/hooks/<hook>`.

   ### Canonical 15-hook list (frozen 2026-05-25)

   [table above]

   ### Output shape (mandatory)

   ```json
   {
     "axis_1": {
       "spec_named_hook_presence": [
         {"hook": "apex-prompt-guard.cjs", "layer": "Defense-in-Depth",
          "spec_anchor": "Failure 9 line 136", "exit_code": 0,
          "tool_call_event_ts": "2026-05-25T...", "finding_id": null},
         {"hook": "memory-watchdog.sh", "layer": "Auto-Continuity",
          "spec_anchor": "Auto-Continuity Layer line 435", "exit_code": 1,
          "tool_call_event_ts": "2026-05-25T...", "finding_id": "F-NNN"}
       ],
       "missing_count": 1,
       "total_count": 15
     }
   }
   ```

   Round-checker invariant (TP-2 §6.b extension):
   - `total_count == 15` strictly.
   - Every `exit_code != 0` row paired with a finding whose `cite[]`
     contains the hook's filename. Otherwise REJECT closure.
```

### Updated AC-C1 (EXPERIMENT-PROTOCOL-C §3 amendment)

> **AC-C1 — Mechanical enumeration coverage.** Every C-suffixed trial's `coverage_map.axis_1.spec_named_hook_presence[]` MUST contain **exactly 15 rows** (one per spec-literal hook in the frozen canonical list). Every row MUST carry `tool_call_event_ts` matching a real `tool_call` event in `.apex/event-log.jsonl` whose `tool_input.command` matches `test -f <lab>/framework/hooks/<hook>`. Every row with `exit_code != 0` MUST have a matching dedicated finding. Round-checker REJECTS on any violation.

---

## §2. TP-C2 — Marker + per-invocation HMAC nonce (R2)

### Closes: CR-C-05, CR-C-06, CR-C-07, CR-C-08 (MINOR), CR-C-09 (MINOR), CR-C-10 (closed by CR-C-05)

### Two-factor → THREE-factor protocol

**Marker literal:** `__APEX_AUDIT_PROBE__` (unchanged).
**New:** per-invocation HMAC nonce (closes the "any framework-auditor in flight" widening).

### Modified files (R2 — CORRECTED scope per CR-C-07)

| File | Layer | Change | Notes |
|------|-------|--------|-------|
| `framework/hooks/pre-subagent-start.sh` | producer | Generate per-invocation nonce when agent_name=framework-auditor; write `audit_probe_nonce` field into in-flight registry entry | ~10 LOC |
| `framework/hooks/_audit-probe-marker.sh` | NEW shared helper | Function `apex_check_audit_probe(envelope_json)` → returns 0 if marker+nonce+agent match | ~40 LOC, sourced by all 4 guards |
| `framework/hooks/destructive-guard.sh` | consumer | Source helper; FIRST check before pattern matching | ~5 LOC added |
| `framework/hooks/exfil-guard.sh` | consumer | Same | ~5 LOC |
| `framework/hooks/sequence-guard.sh` | consumer | Same | ~5 LOC |
| `framework/hooks/prompt-guard.sh` | consumer (Node-less fallback) | Same | ~5 LOC |
| `framework/hooks/apex-prompt-guard.cjs` | consumer (Node path) | New function `checkAuditProbeMarker()`; FIRST check | ~50 LOC |
| `framework/hooks/security.cjs` | shared library | Add `auditProbe.check()` export; mirrors shell helper | ~30 LOC |
| `framework/test-fixtures/security-patterns.json` | manifest | Add `audit_probe_marker` key with `literal`, `valid_for_agents` | ~6 LOC |
| `framework/agents/specialist/framework-auditor.md` | producer-instruction | Axis-10 (lines 119-178) updated: instruct auditor to read own nonce from registry and emit `__APEX_AUDIT_PROBE__:<nonce> ...` | ~15 LOC modified |

### Three-factor logic

| Factor | Check | Defends against |
|--------|-------|-----------------|
| F1: marker prefix | `command.startsWith("__APEX_AUDIT_PROBE__:")` | accidental allowance on natural commands |
| F2: registry has framework-auditor in_flight | `agent_name == "framework-auditor"` in any in_flight entry | non-auditor invocation |
| F3: nonce match | parse `<nonce>` after `:`; find matching in_flight entry with `audit_probe_nonce == <nonce>` | concurrent-auditor cross-talk; sibling-agent emission; indirect-injection (CR-C-10); host parent emission |

**False-allow vectors closed:**
- Sibling agent emits marker → F3 fails (no matching nonce).
- Concurrent auditor Wave 1 (5 framework-auditors) → each has unique nonce; only the auditor whose nonce was emitted passes F3.
- Indirect prompt-injection via CLAUDE.md → injected payload has no valid nonce → F3 fails.
- Host parent session emits marker → F3 fails.

**Acceptable trust-widening:**
- Auditor spawns sub-Task() → sub-Task's most-recent in_flight may mask the auditor. F3 mitigates: auditor uses ITS nonce (stored in registry), not sub-Task's. CR-C-05.2 closed.

### `_audit-probe-marker.sh` (shared shell helper)

```bash
#!/bin/bash
# Sourced by destructive-guard.sh, exfil-guard.sh, sequence-guard.sh, prompt-guard.sh.
# Frozen contract: returns 0 if envelope's tool_input.command begins with the
# audit probe marker AND nonce matches an in-flight framework-auditor entry.
# Emits audit_probe_allowed event; fails loudly on event-log write error.

apex_check_audit_probe() {
  local envelope_json="$1"
  local marker="__APEX_AUDIT_PROBE__:"
  local registry=".apex/in-flight-subagents.jsonl"

  command -v jq >/dev/null 2>&1 || return 1  # no jq → defer to default block path

  local cmd
  cmd=$(printf '%s' "$envelope_json" | jq -r '.tool_input.command // .tool_input.new_string // empty' 2>/dev/null)
  [ -z "$cmd" ] && return 1
  case "$cmd" in
    "${marker}"*) ;;
    *) return 1 ;;
  esac

  # Extract nonce (chars between marker-end and first space)
  local rest="${cmd#$marker}"
  local nonce="${rest%% *}"
  [ -z "$nonce" ] && return 1

  # Find matching registry entry: framework-auditor + in_flight + nonce matches
  [ -f "$registry" ] || return 1
  local match
  match=$(jq -c --arg nonce "$nonce" \
    'select(.status=="in_flight" and .agent_name=="framework-auditor" and .audit_probe_nonce==$nonce)' \
    "$registry" 2>/dev/null | tail -n 1)
  [ -z "$match" ] && return 1

  local agent_id payload_sha1
  agent_id=$(printf '%s' "$match" | jq -r '.agent_id')
  payload_sha1=$(printf '%s' "$cmd" | sha1sum | awk '{print $1}')

  # Emit audit_probe_allowed event — fail LOUDLY on write error (no silent catch)
  local evt
  evt=$(jq -nc \
    --arg ts "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    --arg agent_id "$agent_id" \
    --arg payload_sha1 "$payload_sha1" \
    --arg payload_head "${cmd:0:200}" \
    --arg hook "${BASH_SOURCE[1]##*/}" \
    '{schema_version:"1", ts:$ts, type:"audit_probe_allowed", source:"audit-probe-marker", agent_id:$agent_id, agent_name:"framework-auditor", payload_sha1:$payload_sha1, payload_head:$payload_head, calling_hook:$hook}')
  if ! printf '%s\n' "$evt" >> .apex/event-log.jsonl 2>>/tmp/audit-probe-marker-errors; then
    printf '[apex-audit-probe-marker] event-log write failed (envelope ts=%s)\n' "$(date -u)" >&2
  fi

  return 0  # allow
}
```

### Consumer-hook insertion pattern (per CR-C-07)

Each of `destructive-guard.sh`, `exfil-guard.sh`, `sequence-guard.sh`, `prompt-guard.sh` adds at top of `main()` block:

```bash
# shellcheck disable=SC1091
source "$(dirname "$0")/_audit-probe-marker.sh"
INPUT=$(cat)
if apex_check_audit_probe "$INPUT"; then
  exit 0
fi
# Existing logic continues with INPUT...
```

### `apex-prompt-guard.cjs` — Node parallel (revised per CR-C-09)

```javascript
function checkAuditProbeMarker(toolInput, patterns) {
  const marker = patterns?.audit_probe_marker?.literal + ':';
  if (!marker) return false;

  const cmd = toolInput?.command || toolInput?.new_string || '';
  if (!cmd.startsWith(marker)) return false;

  const rest = cmd.slice(marker.length);
  const nonce = rest.split(' ')[0];
  if (!nonce) return false;

  const fs = require('fs');
  const path = '.apex/in-flight-subagents.jsonl';
  if (!fs.existsSync(path)) return false;

  let match = null;
  try {
    for (const line of fs.readFileSync(path, 'utf8').trim().split('\n')) {
      try {
        const e = JSON.parse(line);
        if (e.status === 'in_flight'
            && e.agent_name === 'framework-auditor'
            && e.audit_probe_nonce === nonce) {
          match = e;  // keep iterating; last-match wins for race-safety
        }
      } catch {}
    }
  } catch { return false; }

  if (!match) return false;

  // Three factors satisfied. Emit fail-loud event.
  const crypto = require('crypto');
  const payload_sha1 = crypto.createHash('sha1').update(cmd).digest('hex');
  const evt = {
    schema_version: '1',
    ts: new Date().toISOString(),
    type: 'audit_probe_allowed',
    source: 'apex-prompt-guard',
    agent_id: match.agent_id,
    agent_name: 'framework-auditor',
    payload_sha1,
    payload_head: cmd.slice(0, 200),
    calling_hook: 'apex-prompt-guard.cjs'
  };
  try {
    fs.appendFileSync('.apex/event-log.jsonl', JSON.stringify(evt) + '\n');
  } catch (e) {
    process.stderr.write(`[apex-prompt-guard] audit_probe_allowed event write failed: ${e.message}\n`);
  }
  return true;
}
```

### `pre-subagent-start.sh` — nonce generation (closes CR-C-05 F3 factor)

Insert before the registry-append block (line 144):

```bash
# Campaign C TP-C2: per-invocation HMAC nonce for framework-auditor.
# Nonce is 16-hex-char random; written into registry; auditor reads its own.
AUDIT_PROBE_NONCE=""
if [ "$AGENT_NAME" = "framework-auditor" ]; then
  if command -v openssl >/dev/null 2>&1; then
    AUDIT_PROBE_NONCE=$(openssl rand -hex 8)
  else
    # Fallback: timestamp + sha1 for non-openssl hosts
    AUDIT_PROBE_NONCE=$(printf '%s%s' "$NOW_ISO" "$RANDOM" | sha1sum | cut -c1-16)
  fi
fi

# Existing registry append, with new field:
jq -nc \
  --arg id "$AGENT_ID" --arg name "$AGENT_NAME" --arg parent "$PARENT_ID" \
  --arg round "$ROUND_TAG" --arg ts "$NOW_ISO" --arg summary "$SUMMARY" \
  --arg nonce "$AUDIT_PROBE_NONCE" \
  '{agent_id:$id, agent_name:$name, parent_agent_id:$parent, round_tag:$round, started_at:$ts, status:"in_flight", tool_input_summary:$summary, audit_probe_nonce:$nonce}' \
  >> "$REG" 2>/dev/null || true
```

### Auditor instruction (axis-10 update per CR-C-14)

Replaces framework-auditor.md axis-10 lines 160-170 (the `(env APEX_BYPASS_TEST=1 bash <hook>)` block):

```markdown
b. **Read your nonce.** Your `pre-subagent-start.sh` wrote a per-instance
   `audit_probe_nonce` into `.apex/in-flight-subagents.jsonl` keyed on
   your `agent_id`. Read it via:
   ```bash
   APEX_AUDIT_NONCE=$(jq -r --arg id "$YOUR_AGENT_ID" \
     'select(.agent_id==$id and .status=="in_flight") | .audit_probe_nonce' \
     .apex/in-flight-subagents.jsonl | tail -n 1)
   ```
   (Your agent_id is the one the round-checker passes to you in the
   AUDIT_CONTEXT block; if absent, scan registry for the most-recent
   in_flight entry with agent_name=framework-auditor.)

c. **Construct probe with marker + nonce.** Every Bash tool_call that
   invokes a host-protected guard MUST start with the three-factor
   marker:
   ```
   __APEX_AUDIT_PROBE__:<nonce> env APEX_BYPASS_TEST=1 bash framework/hooks/<guard> "<payload>"
   ```
   The marker prefix + nonce + your agent_name=framework-auditor in
   registry is the three-factor protocol that the host's prompt-guard
   / destructive-guard / exfil-guard / sequence-guard recognise as a
   legitimate audit probe — they exit 0 (allow) and emit an
   `audit_probe_allowed` event to `.apex/event-log.jsonl`. Without
   marker+nonce, your bypass payloads are blocked at host PreToolUse
   before reaching the guard under test.

d. **Mutation-class-specific probe construction** (closes Campaign C
   CR-C-14):
   - **Regex guards** (path-guard.sh deny patterns; prompt-guard.sh
     deny patterns): construct BOTH a canonical-match payload AND a
     boundary-condition payload (word-boundary, case-folding,
     zero-width whitespace) so a weakened regex surfaces.
   - **Silent-failure guards** (_state-update.sh jq-failure branch;
     session-log.sh unwritable-target branch): probe by passing
     malformed input + asserting non-zero exit AND non-empty stderr.
   - **Counter-swallow tests** (any +0 counter pattern): probe by
     forcing FAIL and asserting global PASS-count decreased.

e. **Capture exit code via the tool_call's response.** The
   `tool_call_event_ts` for each probe is the audit-trail anchor for
   round-checker re-verification.
```

---

## §3. TP-C3 — NC depth probe lazy fallback (R2)

### Closes: CR-C-11 (trigger gate), CR-C-15 (Path C bottom)

### Trigger evaluation procedure

- **When:** AFTER T7 of C5 completes; BEFORE C6.
- **Predicate:** count of P0+P1+P2+P3 findings in T7 trial file.
  - `T7_count >= 10` → NO trigger; AC-6b PASS.
  - `T7_count < 10` → trigger TP-C3 extension.
- **Scope on trigger:** re-run T7 ONLY (not full corpus) with extended axis-4 + axis-12 prose installed. Cost ~30min wall; avoids 5h corpus rerun.

### Escalation ladder (Path A → B → C)

1. **Path A:** TP-C2 alone — measure T7. If `>= 10`: AC-6b PASS.
2. **Path B:** TP-C3 lazy activation (axis-4 walkthrough + axis-12 enumeration); re-run T7. If `>= 10`: AC-6b PASS.
3. **Path C (NEW per CR-C-15):** If Path B miss, recommend owner-authorized §14 amendment to relax AC-6b lower bound. Acknowledged structural reality: a fully-disciplined anti-fabrication auditor on a near-pristine framework MAY yield < 10. Decision is the owner's; this design does not auto-amend. Document in FINAL-CERTIFICATION-C §7 as L-AT-NCConservative-02 + R-AT-P7-11 update.

### TP-C3 prediction grounding (closes CR-C-11.2)

Specific drifts predicted to surface in T7 once axes 10+13 sandbox-unblocked:
1. Live framework's apex-prompt-guard.cjs `audit_probe_marker` key wiring (new attack surface introduced by Campaign C itself — observable by auditor's axis-10 probe).
2. Pre-existing R-AT-P7-06a/06b live defects (test-circuit-breaker-recovery.sh + test-fix-plan-emit.sh 3-FAIL — pre-existing per Campaign B FINAL-CERT §3).
3. The pre-Campaign-B install drift F-CB-001 family that Campaign B closed (audit would re-surface as historical drift documentation).

These give estimate 3-8 axis-10/13 findings; if axis-1 enumeration also surfaces 5+ minor hooks (e.g. `_audit-probe-marker.sh` is NEW, might not be in apex-spec yet — that's exactly the kind of self-referential drift the auditor should catch), total lands in [8, 15] band. Lower-bound-conservative.

---

## §4. TP-C4 — Test rows extended (R2)

### Closes: CR-C-12

Six rows in `framework/tests/test-audit-trail-layer.sh`:

| Row | Setup | Input | Expected | Equivalence class |
|-----|-------|-------|----------|-------------------|
| C-1 | Registry: framework-auditor + nonce=N1 in_flight | `__APEX_AUDIT_PROBE__:N1 rm -rf /tmp/x` → destructive-guard.sh | exit 0; audit_probe_allowed event emitted | three factors all true |
| C-2 | Registry: framework-auditor + nonce=N1 in_flight | `rm -rf /tmp/x` (no marker) | exit 2 (existing block) | factor F1 absent |
| C-3 | Registry: executor + nonce=N1 in_flight | `__APEX_AUDIT_PROBE__:N1 rm -rf /tmp/x` | exit 2 | factor F2 absent (non-auditor) |
| C-4 | Registry: framework-auditor + nonce=N1 in_flight | `__APEX_AUDIT_PROBE__:N1 echo hi` → Write tool, `new_string` field | exit 0 | new_string path tested per CR-C-12.1 |
| C-5 | Registry: framework-auditor + nonce=N1 STOPPED + framework-auditor + nonce=N2 IN_FLIGHT | `__APEX_AUDIT_PROBE__:N2 rm -rf /tmp/x` | exit 0 | F3 picks correct in_flight entry |
| C-6 | Registry: framework-auditor + nonce=N1 STOPPED (only entry) | `__APEX_AUDIT_PROBE__:N1 rm -rf /tmp/x` | exit 2 | F2 absent (no live framework-auditor) |
| C-7 (perf smoke) | Registry: 1000 entries (only last = framework-auditor + nonce=N1 in_flight) | C-1 payload | exit 0 in < 100ms | last-match wins; O(n) scan acceptable |

C-1..C-6 cover all equivalence classes. C-7 is perf safety-net (PreToolUse hook is hot path).

---

## §5. Cross-design coherence (R2) — closes CR-C-13, CR-C-14, CR-C-15

### AC-4 closure path
TP-C1 mechanical enumeration (15 hooks) → per-hook P0 emission required → round-checker pairs `exit_code != 0` with finding `cite[]` → H-A1 (memory-watchdog.sh missing in heldout) and H-A2 (session-auto-resume.sh missing) each get dedicated findings → AC-4 heldout 2/2 in ≥ 2 of 3 trials.

### AC-5b closure path (CR-C-14 closed)
TP-C2 marker + nonce + correct target hooks (destructive-guard.sh, exfil-guard.sh, sequence-guard.sh, prompt-guard.sh, apex-prompt-guard.cjs) → unblocks procedural axis-13 probes → axis-13 prose extended with **mutation-class-specific probe construction** (regex word-boundary, case-folding, silent-failure, counter-swallow classes) → auditor surfaces H-B1 (regex weakening), H-B2 (case-folding), H-C1 (silent on STATE), H-C2 (silent drop), H-D1 (+0 counter swallow). Combined: ≥ 5/5 reliable-kill across heldout trials.

### AC-6b closure path (CR-C-15 closed)
TP-C2 alone → re-measure T7 → if `>= 10` PASS; else TP-C3 lazy activation → re-measure → if `>= 10` PASS; else Path C §14 amendment recommendation in FINAL-CERTIFICATION-C.

### Coherence with §12.2
AC-4, AC-5b, AC-6b remain hard-FAIL. AC-C1, AC-C2 inherit §12.2 (no L-item path). The §14 Path C is owner-authorized — not an autonomous fix-loop bypass.

---

## §6. Audit-trail invariant (strengthened per CR-C-08)

The `audit_probe_allowed` event chain MUST satisfy, per round, for every probe attempted:
- `audit_probe_allowed.agent_id` resolves to a `subagent_start` event with `agent_name == "framework-auditor"` earlier in the same session.
- `audit_probe_allowed.payload_sha1` matches `sha1(tool_call.tool_input.command)` for the matching tool_call event.
- `audit_probe_allowed.calling_hook` names one of the 4 consumer hooks.
- No `audit_probe_allowed` event lacks all three pairs.

Round-checker TP-2 §6.b extension: enumerate every `tool_call` whose `tool_input.command` starts with the marker; verify each has a paired `audit_probe_allowed` with matching `payload_sha1` AND a matching `subagent_start.agent_id`. Any unpaired = REJECT closure.

---

## §7. Critic re-submission

B3-critic R2 — please verify each R1 finding is closed cleanly:

| R1 finding | R2 resolution | Verify how |
|------------|---------------|------------|
| CR-C-01 | Locked at 15; principle-only rows dropped; AC-C1 re-threshold | §1 list; updated EXPERIMENT-PROTOCOL-C §3 |
| CR-C-02 | Per-hook finding requirement + round-checker pairing | §1 procedure + invariant |
| CR-C-03 | Round-checker rule committed | §1 invariant block |
| CR-C-04 | tool_call_event_ts added to output shape | §1 output shape |
| CR-C-05 | Three-factor protocol with per-invocation nonce | §2 |
| CR-C-06 | prompt-guard.sh in scope; sources _audit-probe-marker.sh | §2 modified-files |
| CR-C-07 | apex-workflow-guard.cjs DROPPED; destructive-guard.sh + exfil-guard.sh + sequence-guard.sh + prompt-guard.sh + apex-prompt-guard.cjs IN | §2 modified-files |
| CR-C-08 | payload_sha1 in event | §2 helper + §6 |
| CR-C-09 | Fail-loud event-log stderr on write failure | §2 helper |
| CR-C-10 | Closed by CR-C-05 nonce factor | implicit |
| CR-C-11 | Trigger gate + re-run scope explicit | §3 |
| CR-C-12 | C-1..C-7 rows | §4 |
| CR-C-13 | AC-4 path coherent given CR-C-01 + CR-C-02 closed | §5 |
| CR-C-14 | Mutation-class-specific probe prose added to axis-13 | §2 axis-10 update + §5 |
| CR-C-15 | Path C §14 amendment ladder added | §3 |

Output: `audit-trail-review/FIX-DESIGN-C-CRITIC-R2.md` with verdict PASS / PASS-WITH-CHANGES / FAIL.

If PASS: proceed to C2 implementation per the modified-files list in §2.
