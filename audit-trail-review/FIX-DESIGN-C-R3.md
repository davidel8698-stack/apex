# FIX-DESIGN-C — Round 3 (post B3-critic R2 PASS-WITH-CHANGES)

> **R2 verdict:** PASS-WITH-CHANGES — 14 of 15 R1 findings cleanly closed; 3 NEW R2 findings: CR-C-R2-01 (BLOCKING, list-completeness), CR-C-R2-02 (MAJOR, fallback agent_id contradiction), CR-C-R2-03 (MAJOR, extractor field-list mismatch). MINORs CR-C-R2-04 / CR-C-R2-05 folded in.
>
> **Baseline pin:** `43b37db`. **Protocol anchor:** `EXPERIMENT-PROTOCOL-C.md`. **Inherits:** all 14 R1-closed findings from R2; only the 3 R2 deltas are restated here.

---

## §0. Changelog (R2 → R3)

| Change | Closes | Severity |
|--------|--------|----------|
| **AC-C1 re-architected: dynamic extraction, not fixed count.** Round-checker greps apex-spec.md AT ROUND TIME for every `framework/hooks/<name>.<ext>` reference; auditor MUST enumerate every extracted hook. No magic-number brittleness; self-heals as spec evolves. | CR-C-R2-01 | BLOCKING |
| **Marker extended to `__APEX_AUDIT_PROBE__:<nonce>:<agent_id>`.** Self-identifying — the marker itself carries the agent_id, eliminating the registry-fallback ambiguity in Wave 1 with 5 concurrent auditors. | CR-C-R2-02 | MAJOR |
| **Extractor field-list aligned across shell + node helpers** to `content / new_string / prompt / command / description` (mirrors live apex-prompt-guard.cjs lines 54-61). Coverage hole for Write/Edit `content` / `prompt` field probes closed. | CR-C-R2-03 | MAJOR |
| Append-only race-safety claim documented with one-line proof | CR-C-R2-04 | MINOR |
| Empty-nonce silent regression on hosts without openssl/sha1sum → fails-loud to stderr | CR-C-R2-05 | MINOR |

---

## §1. AC-C1 — Dynamic spec-extraction (R3, supersedes R2 §1)

### Closes: CR-C-R2-01

### The fundamental shift
R2's "exactly 15" / "exactly 17" / "exactly N" gate is mechanically brittle: apex-spec.md is itself a living document; new IMPs land regularly and add hook references. Locking the count at any specific value creates a synthetic AC-C1 miss every time a new hook is added between protocol-C0 freeze and C5 measurement. **The right gate is "enumerate everything that's spec-named at round time," not "enumerate exactly N."**

### Updated AC-C1 (replaces EXPERIMENT-PROTOCOL-C §3 AC-C1)

> **AC-C1 — Mechanical enumeration completeness.** Every C-suffixed trial's `coverage_map.axis_1.spec_named_hook_presence[]` MUST contain one entry per spec-literal hook referenced in `apex-spec.md`. The "spec-literal hook set" is extracted dynamically at round time via:
> ```bash
> grep -oE 'framework/hooks/[a-zA-Z_-]+\.(sh|cjs|ps1)' apex-spec.md | sort -u
> ```
> Every row MUST carry `tool_call_event_ts` matching a real `tool_call` event whose `tool_input.command` matches `test -f <lab>/framework/hooks/<hook>`. Every row with `exit_code != 0` MUST have a matching dedicated finding whose `cite[]` contains the hook's filename. **Round-checker REJECTS closure** if the auditor's enumeration is a strict subset of the extracted set, OR if any `exit_code != 0` row lacks its paired finding.
>
> **Threshold:** binary (set-equality + pairing predicate).
> **§12.2 hard-FAIL.** No L-item path.

### Auditor instruction (replaces R2 §1 canonical-list table)

```markdown
1. **The 9 failure modes (sections 1–9 in spec) — MECHANICAL ENUMERATION.**
   [Campaign C TP-C1 R3 — closes AC-4 + AC-C1]

   The "spec-named hooks" set is NOT a frozen list — it is whatever
   `apex-spec.md` references AT ROUND TIME. Extract the set:
   ```bash
   grep -oE 'framework/hooks/[a-zA-Z_-]+\.(sh|cjs|ps1)' \
     <lab>/apex-spec.md | sort -u
   ```
   This produces ~20-25 hook filenames depending on spec version.

   For EACH hook in the extracted set:
   a. Execute `test -f <lab>/framework/hooks/<hook>` via a separate
      Bash tool_call (one tool_call per hook — never batch).
   b. Record into `coverage_map.axis_1.spec_named_hook_presence[]`:
      `{hook, exit_code, tool_call_event_ts, finding_id}`.
   c. If `exit_code != 0` (file missing), emit a dedicated P0 finding
      F-NNN with that hook's filename in `cite[]`. ONE rolled-up
      "baseline absent" finding does NOT discharge per-hook duty.

   Round-checker REJECTS closure on either:
   - `extracted_set \ enumerated_set` non-empty (you missed a hook).
   - Any `exit_code != 0` row lacking paired finding (rollup escape).

   ### Output shape (mandatory)

   ```json
   {
     "axis_1": {
       "spec_named_hook_presence": [
         {"hook": "apex-prompt-guard.cjs", "exit_code": 0,
          "tool_call_event_ts": "2026-05-25T...", "finding_id": null},
         {"hook": "memory-watchdog.sh", "exit_code": 1,
          "tool_call_event_ts": "2026-05-25T...", "finding_id": "F-NNN"},
         ...
       ],
       "extracted_set_size": 22,
       "enumerated_set_size": 22,
       "missing_files_count": 1
     }
   }
   ```

   Missing-file findings are NEVER inheritable from prior rounds.
```

### Why dynamic-extraction is correct
- **Spec evolution-safe.** Any IMP added to apex-spec.md after C0 freeze is auto-covered by AC-C1.
- **No off-by-N risk.** Critic's R2 finding that "verbatim grep returns ≥20" is now self-resolving — the gate adapts.
- **The auditor still walks every hook mechanically.** That's the original AC-4 closure mechanism.
- **Round-checker has a single deterministic gate** (set-equality + pairing), not a magic-number compare.

---

## §2. Marker upgrade — self-identifying (R3, replaces R2 §2 marker)

### Closes: CR-C-R2-02

### The fundamental shift
R2 marker is `__APEX_AUDIT_PROBE__:<nonce>`. The auditor reads its own nonce from the registry; the guard verifies nonce against most-recent in-flight `framework-auditor`. With 5 concurrent auditors in Wave 1, "most-recent" is ambiguous. R2's axis-10 fallback ("scan registry for most-recent in_flight with agent_name=framework-auditor") contradicts the three-factor protocol.

**Fix:** Make the marker itself carry the agent_id. The marker becomes self-identifying: guard reads agent_id FROM the marker, then verifies via registry that (agent_id, nonce) pair is in-flight as framework-auditor. No ambiguity even with N concurrent auditors.

### New marker grammar

```
__APEX_AUDIT_PROBE__:<nonce>:<agent_id> <bash command>
```

Where:
- `<nonce>` — 16-hex-char per-invocation random, set by pre-subagent-start.sh
- `<agent_id>` — the synthesized framework-auditor agent_id (e.g. `subagent-framework-auditor-25-deadbeef`)

### Three-factor verification (revised)

| Factor | Check | Defends against |
|--------|-------|-----------------|
| F1: marker prefix | `command.startsWith("__APEX_AUDIT_PROBE__:")` | accidental allowance on natural commands |
| F2: agent_id resolves to framework-auditor in_flight | look up exact `agent_id` in registry; verify `agent_name=="framework-auditor"` AND `status=="in_flight"` | sibling-agent emission; host parent emission |
| F3: nonce matches that exact registry entry | extracted `nonce` equals `registry[agent_id].audit_probe_nonce` | indirect prompt-injection (CR-C-10); cross-talk between concurrent auditors (CR-C-05.1) |

**Concurrent-auditor case (Wave 1, 5 framework-auditors):** each auditor has unique (agent_id, nonce); each emits its own marker; guard looks up the exact agent_id from the marker — no "most-recent" ambiguity.

**Sub-Task() race (R2 CR-C-05.2):** auditor's nonce is still valid because the marker carries its agent_id directly; sub-Task in registry doesn't mask.

### Axis-10 instruction update (R3)

```markdown
b. **Read your own nonce + agent_id.** Your `pre-subagent-start.sh`
   wrote a per-invocation `audit_probe_nonce` into
   `.apex/in-flight-subagents.jsonl` keyed on your `agent_id`. The
   orchestrator passes your `agent_id` to you in AUDIT_CONTEXT.
   Read your nonce:
   ```bash
   APEX_AUDIT_NONCE=$(jq -r --arg id "$YOUR_AGENT_ID" \
     'select(.agent_id==$id and .status=="in_flight") | .audit_probe_nonce' \
     .apex/in-flight-subagents.jsonl | tail -n 1)
   ```
   (If AUDIT_CONTEXT omits your agent_id, the orchestrator is using a
   degraded launch path; FAIL the trial honestly rather than guess
   your nonce from registry-time-of-last-write.)

c. **Construct probe with self-identifying marker.** Every Bash
   tool_call invoking a host-protected guard MUST start with:
   ```
   __APEX_AUDIT_PROBE__:<your-nonce>:<your-agent-id> env APEX_BYPASS_TEST=1 bash framework/hooks/<guard> "<payload>"
   ```
   The marker + your nonce + your agent_id is the three-factor
   protocol the host's guards recognize. Without all three, the
   probe is BLOCKED at host PreToolUse.
```

### Updated helper logic (shell + node — aligned per CR-C-R2-03)

```bash
# _audit-probe-marker.sh — R3
apex_check_audit_probe() {
  local envelope_json="$1"
  local marker_prefix="__APEX_AUDIT_PROBE__:"
  local registry=".apex/in-flight-subagents.jsonl"

  command -v jq >/dev/null 2>&1 || return 1

  # CR-C-R2-03 fix: extract from full field-list, mirrors apex-prompt-guard.cjs lines 54-61
  local cmd
  cmd=$(printf '%s' "$envelope_json" | jq -r '
    .tool_input.content //
    .tool_input.new_string //
    .tool_input.prompt //
    .tool_input.command //
    .tool_input.description //
    empty' 2>/dev/null)
  [ -z "$cmd" ] && return 1

  case "$cmd" in "${marker_prefix}"*) ;; *) return 1 ;; esac

  # Marker grammar: __APEX_AUDIT_PROBE__:<nonce>:<agent_id> <command>
  local after_prefix="${cmd#$marker_prefix}"
  local nonce="${after_prefix%%:*}"
  local rest="${after_prefix#$nonce:}"
  local agent_id="${rest%% *}"
  [ -z "$nonce" ] || [ -z "$agent_id" ] && return 1

  # F2 + F3: exact agent_id lookup + nonce match in same entry
  [ -f "$registry" ] || return 1
  local match
  match=$(jq -c --arg id "$agent_id" --arg nonce "$nonce" \
    'select(.agent_id==$id and .status=="in_flight" and .agent_name=="framework-auditor" and .audit_probe_nonce==$nonce)' \
    "$registry" 2>/dev/null | tail -n 1)
  [ -z "$match" ] && return 1

  # Emit audit_probe_allowed event — fail-loud per CR-C-09
  local payload_sha1
  payload_sha1=$(printf '%s' "$cmd" | sha1sum 2>/dev/null | awk '{print $1}')
  local evt
  evt=$(jq -nc \
    --arg ts "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    --arg agent_id "$agent_id" \
    --arg payload_sha1 "$payload_sha1" \
    --arg payload_head "${cmd:0:200}" \
    --arg hook "${BASH_SOURCE[1]##*/}" \
    '{schema_version:"1", ts:$ts, type:"audit_probe_allowed", source:"audit-probe-marker", agent_id:$agent_id, agent_name:"framework-auditor", payload_sha1:$payload_sha1, payload_head:$payload_head, calling_hook:$hook}')
  if ! printf '%s\n' "$evt" >> .apex/event-log.jsonl 2>>/tmp/audit-probe-marker-errors; then
    printf '[apex-audit-probe-marker] event-log write failed at %s\n' "$(date -u)" >&2
  fi

  return 0
}
```

```javascript
// apex-prompt-guard.cjs — R3 (CR-C-R2-03 field-list alignment)
function checkAuditProbeMarker(toolInput, patterns) {
  const markerPrefix = '__APEX_AUDIT_PROBE__:';

  // Mirror live extractor (apex-prompt-guard.cjs lines 54-61)
  const cmd = toolInput?.content
           ?? toolInput?.new_string
           ?? toolInput?.prompt
           ?? toolInput?.command
           ?? toolInput?.description
           ?? '';
  if (typeof cmd !== 'string' || !cmd.startsWith(markerPrefix)) return false;

  const afterPrefix = cmd.slice(markerPrefix.length);
  const [nonce, rest] = afterPrefix.split(/:(.+)/, 2);
  if (!rest) return false;
  const [agentId] = rest.split(/\s+/, 1);
  if (!nonce || !agentId) return false;

  const fs = require('fs');
  const path = '.apex/in-flight-subagents.jsonl';
  if (!fs.existsSync(path)) return false;

  let match = null;
  for (const line of fs.readFileSync(path, 'utf8').trim().split('\n')) {
    try {
      const e = JSON.parse(line);
      if (e.status === 'in_flight'
          && e.agent_id === agentId
          && e.agent_name === 'framework-auditor'
          && e.audit_probe_nonce === nonce) {
        match = e;
      }
    } catch {}
  }
  if (!match) return false;

  const crypto = require('crypto');
  const payload_sha1 = crypto.createHash('sha1').update(cmd).digest('hex');
  const evt = {
    schema_version: '1',
    ts: new Date().toISOString(),
    type: 'audit_probe_allowed',
    source: 'apex-prompt-guard',
    agent_id: agentId,
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

### Append-only race-safety proof (CR-C-R2-04 closed)

`.apex/in-flight-subagents.jsonl` is append-only by contract: `pre-subagent-start.sh` line 144 uses `>> "$REG"` (no truncation, no rotation). `subagent-stop.sh` mutates the file via `jq -c ... | mv $TMP $REG` to flip status — but only flips field values; never deletes lines. The `tail -n 1` of a jq filter (last-match-wins iteration) is therefore safe under concurrent appends because the final correct entry exists in the file and earlier mutations only flipped status — a stale "in_flight" hit on a now-stopped entry is impossible because the flip is atomic-rename.

### Empty-nonce loud-fail (CR-C-R2-05 closed)

`pre-subagent-start.sh` nonce-generation:
```bash
if [ "$AGENT_NAME" = "framework-auditor" ]; then
  if command -v openssl >/dev/null 2>&1; then
    AUDIT_PROBE_NONCE=$(openssl rand -hex 8)
  else
    AUDIT_PROBE_NONCE=$(printf '%s%s' "$NOW_ISO" "$RANDOM" | sha1sum 2>/dev/null | cut -c1-16)
  fi
  if [ -z "$AUDIT_PROBE_NONCE" ]; then
    printf '[pre-subagent-start] CRITICAL: failed to generate audit_probe_nonce for framework-auditor agent_id=%s — guards will block all axis-10/13 probes from this auditor.\n' "$AGENT_ID" >&2
    # Continue without nonce — the auditor's probes will fail-closed, which is the correct safety default.
  fi
fi
```

---

## §3-§7 (unchanged from R2)

R2 §3 (TP-C3 escalation ladder), §4 (test rows C-1..C-7), §5 (cross-design coherence), §6 (audit-trail invariant), §7 (critic resubmission) — all stand verbatim, modulo:
- Test row prompt examples updated to use the 3-factor marker `__APEX_AUDIT_PROBE__:<nonce>:<agent_id>` instead of R2's 2-factor form.
- C-7 perf-smoke row checks new agent_id lookup is also O(n) acceptable.

---

## §8. Critic resubmission

B3-critic R3 — please verify the 3 R2 deltas are closed cleanly:

| R2 finding | R3 resolution | Verify how |
|------------|---------------|------------|
| CR-C-R2-01 | AC-C1 dynamic-extraction; round-checker uses runtime grep against apex-spec.md | §1 auditor instruction + updated AC-C1 |
| CR-C-R2-02 | Self-identifying marker `__APEX_AUDIT_PROBE__:<nonce>:<agent_id>`; F2 binds to exact agent_id, not "most recent" | §2 grammar + helper logic |
| CR-C-R2-03 | Both helpers extract from `content / new_string / prompt / command / description` (mirrors live apex-prompt-guard.cjs) | §2 helper code (both shell + node) |
| CR-C-R2-04 | Append-only race-safety proof | §2 proof paragraph |
| CR-C-R2-05 | Empty-nonce loud-fail to stderr | §2 pre-subagent-start.sh patch |

14 R1-closed findings stand verbatim; R3 review surface is just these 5.

Output: `audit-trail-review/FIX-DESIGN-C-CRITIC-R3.md` with verdict PASS / PASS-WITH-CHANGES / FAIL.

If PASS → C2 implementation begins.
