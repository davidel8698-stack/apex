# FIX-DESIGN-C — Round 4 (post B3-critic R3 PASS-WITH-CHANGES)

> **R3 verdict:** PASS-WITH-CHANGES — 3 of 5 R2 deltas cleanly closed; 4 new R3 findings: CR-C-R3-01 (BLOCKING, §10 hardcoded "17"), CR-C-R3-02 (MAJOR, round-checker independence), CR-C-R3-03 (MAJOR, shell parser asymmetry), CR-C-R3-04 (MAJOR escalated, race-safety proof factually wrong).
>
> **Baseline pin:** `43b37db`. **Empirical hook count at C0 freeze:** **19 hooks** (verified via grep — see §1.5). **R3 review:** `FIX-DESIGN-C-CRITIC-R3.md`.

---

## §0. Changelog (R3 → R4)

| Change | Closes | Severity |
|--------|--------|----------|
| EXPERIMENT-PROTOCOL-C §10 dynamic-extraction language replaces "17 rows" hardcode (already landed via Edit) | CR-C-R3-01 | BLOCKING |
| Round-checker explicitly bound to re-grep apex-spec.md independently of auditor's claim | CR-C-R3-02 | MAJOR |
| Shell parser hardened: explicit colon-presence check before agent_id extraction | CR-C-R3-03 | MAJOR |
| Race-safety proof corrected: bounded-residual semantics + R-AT-P7-12 reserved for full fix | CR-C-R3-04 | MAJOR escalated |

---

## §1. CR-C-R3-01 — Protocol-C §10 dynamic-extraction (RESOLVED)

Edit already applied to `audit-trail-review/EXPERIMENT-PROTOCOL-C.md` §10 — replaced "17 rows" with the dynamic-extraction language matching §3 AC-C1. §10 now reads:

> Each C5 trial MUST produce ... `coverage_map.axis_1.spec_named_hook_presence[]` with one row per spec-literal hook extracted DYNAMICALLY at round time via `grep -oE 'framework/hooks/[a-zA-Z_-]+\.(sh|cjs|ps1)' <lab>/apex-spec.md | sort -u` (expected count ~19-25; verified **19** at C0 freeze on baseline `43b37db`).

**Empirical 19-hook list at C0 freeze** (this list does NOT enter the design as a frozen artifact — round-time re-grep is the binding mechanism; this is just the snapshot at freeze for orientation):

```
framework/hooks/_agent-dispatch.sh
framework/hooks/_state-update.sh
framework/hooks/apex-prompt-guard.cjs
framework/hooks/circuit-breaker.sh
framework/hooks/context-monitor.sh
framework/hooks/decision-gate.sh
framework/hooks/destructive-guard.sh
framework/hooks/dora-collect.sh
framework/hooks/exfil-guard.sh
framework/hooks/first-hour-telemetry.sh
framework/hooks/mutation-gate.sh
framework/hooks/owner-guard.sh
framework/hooks/path-guard.sh
framework/hooks/phantom-check.sh
framework/hooks/phase-compaction.sh
framework/hooks/prompt-guard.sh
framework/hooks/quarantine-guard.sh
framework/hooks/sequence-guard.sh
framework/hooks/test-deletion-guard.sh
```

Note: this list includes 4 hooks that DO NOT YET EXIST in framework/hooks/ (`dora-collect.sh`, `first-hour-telemetry.sh`, `phase-compaction.sh`, `decision-gate.sh` — verified in Phase 12 forward-references per apex-spec.md §"Phase 12 M16.1 deliverables"). These are spec-named-but-future. C5 trials WILL emit P0 findings for them — that's the correct behavior: spec-vs-implementation drift is exactly what axis-1 should surface. The owner can either land the hooks or annotate them as forward-references in apex-spec (the spec already says "forward-reference" prose, but the grep doesn't honor prose qualifiers — see CR-C-R3-02 follow-up below).

**Future-reference handling:** add an optional `extracted_set_with_forward_ref_classification[]` field to coverage_map. Round-checker accepts a finding marked `forward_reference: true` (with spec-line citation showing "forward-reference" prose) as a P3 advisory instead of P0. This avoids flooding C5 trials with 4 false-P0 findings on documented forward-references. Authored as new §1.6 below.

---

## §1.5 Forward-reference classification (NEW post CR-C-R3-01 analysis)

When axis-1 enumeration finds a missing file, the auditor checks apex-spec.md for "forward-reference" prose near the hook citation:

```bash
# In auditor's per-hook test:
SPEC_CONTEXT=$(grep -B2 -A2 "framework/hooks/<hook>" <lab>/apex-spec.md | tr '\n' ' ')
if echo "$SPEC_CONTEXT" | grep -qiE 'forward.reference|phase.12|deliverable|planned'; then
  # Emit P3 advisory (forward-reference acknowledged), not P0
  EMIT_AS="P3"
else
  EMIT_AS="P0"
fi
```

Round-checker pairing predicate (TP-2 §6.b R3 extension): for every `spec_named_hook_presence[i].exit_code != 0`:
- If matching finding has severity in {P0, P1} AND `cite[]` contains the hook → PASS pairing.
- If matching finding has `forward_reference: true` flag AND `cite[]` contains BOTH the hook AND a spec line containing forward-reference prose → PASS pairing as advisory.
- Otherwise → REJECT closure.

This closes the spec-vs-implementation drift question without false-positive flood.

---

## §2. CR-C-R3-02 — Round-checker independence

The R3 design said "round-checker REJECTS closure if enumerated_set is a strict subset of extracted_set" but did NOT bind the round-checker to independently RE-RUN the grep. An auditor could report `extracted_set_size == enumerated_set_size` with both narrow — the equality check passes trivially.

**Fix:** explicit two-source verification in the round-checker spec.

### Round-checker TP-2 §6.b R3 extension (new instruction language)

```markdown
**§6.b R3 — Axis-1 mechanical-enumeration verification (Campaign C TP-C1):**

The round-checker MUST independently re-run the spec-extraction grep against the same apex-spec.md the auditor used:

```bash
RC_EXTRACTED=$(grep -oE 'framework/hooks/[a-zA-Z_-]+\.(sh|cjs|ps1)' <lab>/apex-spec.md | sort -u)
RC_EXTRACTED_COUNT=$(echo "$RC_EXTRACTED" | wc -l)
```

Then:
1. Compare against auditor's `coverage_map.axis_1.spec_named_hook_presence[].hook` list (collected from the trial output).
2. Set-difference: `RC_EXTRACTED \ auditor_enumerated` → if non-empty, REJECT closure with reason "auditor missed N spec-named hooks: [...]".
3. Reverse set-difference: `auditor_enumerated \ RC_EXTRACTED` → advisory only (auditor may have enumerated extra hooks beyond the spec, which is acceptable).
4. For every `spec_named_hook_presence[i].exit_code != 0`: verify paired finding per §1.5 classification rule.

The round-checker's grep is the AUTHORITY; the auditor's claimed `extracted_set_size` is advisory. This closes CR-C-R3-02 — the auditor cannot satisfy the gate by reporting matched-narrow numbers.
```

### Why this works
- Two independent producers of the "spec-named hook set" — auditor + round-checker.
- Round-checker's grep is the canonical source.
- Auditor cannot game the gate; underreporting is caught by round-checker's independent extraction.

---

## §3. CR-C-R3-03 — Shell parser hardening

The R3 shell helper had:
```bash
local after_prefix="${cmd#$marker_prefix}"
local nonce="${after_prefix%%:*}"
local rest="${after_prefix#$nonce:}"
local agent_id="${rest%% *}"
```

Edge case: `cmd = "__APEX_AUDIT_PROBE__:abc123"` (no second colon).
- `after_prefix = "abc123"`
- `nonce = "abc123"` (parameter expansion `${...%%:*}` returns the full string if `:` is absent)
- `rest = "abc123"` (the `${after_prefix#$nonce:}` strip is a no-op because `abc123:` is NOT a prefix of `abc123`)
- `agent_id = "abc123"` — same as nonce

The downstream F2 check then looks up `agent_id="abc123"` in the registry, which won't match any real `subagent-framework-auditor-25-...` entry, so the function returns false (correct fail-closed). **No false-allow vector** — but the parser parity with the node version is violated (node correctly rejects).

### Fix — explicit colon-presence check before nonce/agent_id extraction

```bash
local after_prefix="${cmd#$marker_prefix}"
case "$after_prefix" in
  *:*) ;;
  *) return 1 ;;  # marker lacks the second colon — malformed
esac
local nonce="${after_prefix%%:*}"
local rest="${after_prefix#*:}"
case "$rest" in
  ?*) ;;
  *) return 1 ;;  # nothing after the second colon
esac
local agent_id="${rest%% *}"
[ -z "$nonce" ] || [ -z "$agent_id" ] && return 1
[ "$nonce" = "$agent_id" ] && return 1  # defensive: prevent same-string degenerate
```

Three guards now:
1. Mandatory second colon (closes the no-op-strip path).
2. Mandatory non-empty content after second colon.
3. Defensive: nonce ≠ agent_id (catches any remaining same-string degenerate).

Parity restored with node parser.

### Test addition (C-7 → C-8)

Add to test-audit-trail-layer.sh:
```bash
# C-8: malformed marker (no second colon) → block (parser correctness)
echo '{"tool_input":{"command":"__APEX_AUDIT_PROBE__:abc123 rm -rf /tmp/x"}}' \
  | bash framework/hooks/destructive-guard.sh
# Expect: exit 2 (parser rejects; falls to existing block path)
```

---

## §4. CR-C-R3-04 — Race-safety proof corrected

### R3's wrong claim
R3 §2 stated:
> "subagent-stop.sh mutates the file via `jq -c ... | mv $TMP $REG` to flip status — but only flips field values; never deletes lines."

### Live evidence (R3 critic verified)
`framework/hooks/subagent-stop.sh` lines 175-186:
```bash
jq -c --arg id "$RESOLVED_ID" '
  if .agent_id == $id and .status == "in_flight"
  then .status = "stopped" | .stopped_at = (now | strftime("%Y-%m-%dT%H:%M:%SZ"))
  else . end' "$REG" > "$TMP_REG" 2>/dev/null \
    && mv "$TMP_REG" "$REG" \
    || rm -f "$TMP_REG"
```

The pattern reads the entire file, processes via jq, writes a NEW file, then atomic-renames. **Concurrent appends during the read→write window are LOST**: the writer's `>> "$REG"` opens the original inode (still readable); subagent-stop's `mv "$TMP_REG" "$REG"` swaps the inode; concurrent append lands on the orphaned old inode and is silently lost.

### Bounded-residual semantics (correct proof)

**Read-side guarantee (the consumer's perspective — guard checking the registry):**
- Atomic rename means a guard's read sees EITHER the pre-mv file OR the post-mv file, never a torn intermediate.
- If a probe arrives DURING the read→write window, the guard sees the pre-mv content. The pre-mv content contains the registry entry the auditor is identifying with (`agent_id` + `nonce`); F2/F3 succeed.
- After mv: the guard sees the post-mv content. The auditor's entry now has `status=stopped`; F2 fails (correct — the auditor has ended; probes from it should not pass).

**Write-side hazard (the producer's perspective — pre-subagent-start.sh appending):**
- If pre-subagent-start.sh appends DURING subagent-stop's write window, the append lands on the orphaned inode. The new framework-auditor entry is LOST.
- Consequence: the new auditor has NO `audit_probe_nonce` in the registry. Its probes will be BLOCKED (F2 fails — agent_id not found). **Fail-closed.**

### Acceptable residual

The race-loss window is bounded by subagent-stop's jq+mv duration (typically <50ms). A new framework-auditor spawned within this window will fail all axis-10/13 probes (correct security default — better to block legitimate audits than to allow malicious ones).

**Mitigation reservation:** R-AT-P7-12 — replace the registry's rewrite-pattern with a strictly-append-only design (append a `status_transition` event line instead of rewriting). Out of Campaign C scope; reserved for Phase 7. The current bounded-residual semantics is documented and acknowledged as acceptable for C5 measurement.

### Updated documentation in design

Replace R3 §2 race-safety paragraph with:

> **Race-safety with bounded residual:** `.apex/in-flight-subagents.jsonl` is append-only-with-rewrite. The guard's read is atomic-rename-protected (no torn reads). The producer's append during subagent-stop's rewrite window may be lost on the orphaned inode (bounded-loss window <50ms). Lost entries cause new framework-auditor probes to fail F2 (agent_id not in registry) — fail-closed, correct security default. Strict append-only redesign reserved as R-AT-P7-12.

---

## §5. Critic resubmission

B3-critic R4 — please verify the 4 R3 deltas are closed cleanly:

| R3 finding | R4 resolution | Verify how |
|------------|---------------|------------|
| CR-C-R3-01 (BLOCKING) | EXPERIMENT-PROTOCOL-C §10 already edited to dynamic-extraction | Read §10 of EXPERIMENT-PROTOCOL-C.md |
| CR-C-R3-02 (MAJOR) | Round-checker explicitly binds to independent grep; auditor's claim is advisory | §2 of this R4 doc + add to round-checker.md when C3 lands |
| CR-C-R3-03 (MAJOR) | Shell parser hardened with explicit colon-presence check + defensive nonce≠agent_id | §3 of this R4 |
| CR-C-R3-04 (MAJOR escalated) | Race-safety proof corrected; bounded-residual semantics documented; R-AT-P7-12 reserved | §4 of this R4 |
| NEW: forward-reference classification (§1.5) | Avoids false-P0 flood on Phase-12 forward-referenced hooks | §1.5 + round-checker pairing extension |

R1+R2+R3 (17 prior findings) stand closed. R4 review surface: 4 + §1.5 addition = 5 items.

Output: `audit-trail-review/FIX-DESIGN-C-CRITIC-R4.md` with verdict PASS / PASS-WITH-CHANGES / FAIL.

If PASS → C2 implementation begins immediately. The design is now locked across R1-R4 reviews.
