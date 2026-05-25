# FIX-DESIGN-C — B3-critic R3 (clean-room adversarial design review)

> **Scope (clean-room):** `audit-trail-review/FIX-DESIGN-C-R3.md` + binding inputs (`EXPERIMENT-PROTOCOL-C.md` R3-updated, live `framework/hooks/apex-prompt-guard.cjs` lines 54-61, live `framework/hooks/pre-subagent-start.sh` lines 140-148, live `framework/hooks/subagent-stop.sh` lines 175-186, live `apex-spec.md`). R2 review (`FIX-DESIGN-C-CRITIC-R2.md`) consulted as the closure rubric only.
>
> **Date:** 2026-05-25. **Baseline pin in design:** `43b37db`.
> **Verdict:** **PASS-WITH-CHANGES** — 3 of 5 R2 deltas cleanly closed; 1 BLOCKING + 2 MAJOR R3-NEW findings.

---

## §0. R2-delta closure scorecard

| R2 finding | Sev. | Claimed R3 resolution | Verify outcome | New finding |
|------------|------|-----------------------|----------------|-------------|
| CR-C-R2-01 | BLOCKING | AC-C1 dynamic-extraction; round-checker uses runtime grep | **Closed-with-defect** — see CR-C-R3-01 (protocol §10 not updated) and CR-C-R3-02 (round-checker independence not specified) | CR-C-R3-01, CR-C-R3-02 |
| CR-C-R2-02 | MAJOR | Self-identifying marker `__APEX_AUDIT_PROBE__:<nonce>:<agent_id>`; F2 exact agent_id lookup | Closed for the concurrent-auditor sibling-cross-talk case; but introduces parser-asymmetry defect — see CR-C-R3-03 | CR-C-R3-03 |
| CR-C-R2-03 | MAJOR | Both helpers extract from `content / new_string / prompt / command / description` | Closed cleanly (verified against live apex-prompt-guard.cjs lines 54-61 — exact verbatim parity) | — |
| CR-C-R2-04 | MINOR | Append-only race-safety proof | **NOT CLOSED** — proof is factually wrong against live subagent-stop.sh; see CR-C-R3-04 | CR-C-R3-04 |
| CR-C-R2-05 | MINOR | Empty-nonce loud-fail to stderr | Closed (R3 §2 pre-subagent-start.sh patch lines 286-290 emit `[pre-subagent-start] CRITICAL:` to stderr) | — |

Net: 3/5 R2 deltas cleanly closed. CR-C-R2-01 closure mechanism leaves two structural gaps (one BLOCKING, one MAJOR). CR-C-R2-02 closure introduces a parser-parity defect (MAJOR). CR-C-R2-04 is reopened by an empirically false race-safety claim (MAJOR — re-classed up from MINOR because the proof is wrong, not just absent).

---

## §1. R3-NEW findings — BLOCKING

### CR-C-R3-01 — BLOCKING. EXPERIMENT-PROTOCOL-C.md §10 still hardcodes "17 rows" — directly contradicts R3's dynamic-extraction AC-C1.

R3 §0 changelog claims AC-C1 is "re-architected: dynamic extraction, not fixed count." R3 §1 supersedes R2 §1 with grep-extraction prose. EXPERIMENT-PROTOCOL-C.md §3 (lines 60-63) IS updated to the dynamic gate (good).

**But EXPERIMENT-PROTOCOL-C.md §10 (lines 156-163) was NOT updated:**

> Line 159: `coverage_map.axis_1.spec_named_hook_presence[]` with 17 rows (one per spec-named hook).
> Line 163: Round-checker rejects any trial whose `coverage_map.axis_1.spec_named_hook_presence[]` has fewer than 17 entries OR whose probes claim execution but lack matching `audit_probe_allowed` events.

This is the exact CR-C-R2-01 BLOCKING defect re-introduced via an un-updated section. EXPERIMENT-PROTOCOL-C.md is the PROTOCOL ANCHOR for the round-checker. A round-checker reading §10 verbatim has TWO conflicting instructions:
- §3 (AC-C1): "set-equality + pairing predicate" (dynamic, runtime grep)
- §10: "fewer than 17 entries" (frozen, magic number 17)

**Empirical check.** Running the R3-specified grep against live apex-spec.md right now returns **19 hooks** (verified — `grep -oE 'framework/hooks/[a-zA-Z_-]+\.(sh|cjs|ps1)' apex-spec.md | sort -u | wc -l` = 19). This is:
- OUTSIDE R3 §1's "~20-25" prose claim (under by 1).
- ABOVE §10's "fewer than 17" floor (passes the §10 floor, but the §10 prose says "with 17 rows" which is ambiguous between exact-17 and ≥17).

A rigorous C5 round-checker following the protocol file verbatim is left to guess which clause is canonical. The R2 BLOCKING CR-C-R2-01 was not actually closed — it was closed in one of two paragraphs.

**Required for R4:**
- Update EXPERIMENT-PROTOCOL-C.md §10 line 159 from "with 17 rows" to "with one row per hook returned by the AC-C1 dynamic grep (see §3); count is ~20-25 depending on spec version."
- Update §10 line 163 from "has fewer than 17 entries" to "is a strict subset of the AC-C1 dynamically extracted set, OR has any `exit_code != 0` row lacking paired finding."
- Add a §11 cross-reference: "§3 AC-C1 is the canonical gate. §10 enumerates the required artifacts. Where the two diverge, §3 wins."

This is the only BLOCKING R3 finding. Without it, the protocol file ships internally inconsistent and the round-checker contract is ambiguous.

---

## §2. R3-NEW findings — MAJOR

### CR-C-R3-02 — MAJOR. Round-checker independence under-specified: AC-C1's "extracted set" is never explicitly bound to be re-computed by the round-checker, not trusted from the auditor's reported `extracted_set_size`.

R3 §1 AC-C1 (lines 30-37) says: *"Round-checker REJECTS closure if the auditor's enumeration is a strict subset of the extracted set."* The output shape (lines 78-79) includes `extracted_set_size: 22, enumerated_set_size: 22` as auditor-reported fields.

But R3 nowhere instructs the round-checker to **independently re-run the grep** against `apex-spec.md`. If the round-checker simply trusts the auditor's `extracted_set_size` field, an auditor can:
1. Run a deliberately narrow grep (e.g. against an old apex-spec.md cache).
2. Enumerate the narrow set.
3. Report `extracted_set_size == enumerated_set_size` (both narrow).
4. The set-equality check PASSES on the auditor's own report.

The verbatim protocol words "the auditor's enumeration" vs "the extracted set" imply two distinct sources, but neither EXPERIMENT-PROTOCOL-C nor FIX-DESIGN-C-R3 explicitly commits the round-checker to compute its own ground-truth via a second grep run. R2's closure mechanism for CR-C-02/03 (round-checker pairs `exit_code != 0` rows with findings) IS mechanically bound to round-checker reads of the trial file. The dynamic-extraction closure mechanism is NOT bound the same way.

**Required for R4:**
- Add explicit instruction (R3 §1 or a new sub-section): "TP-2 §6.b round-checker MUST independently run `grep -oE 'framework/hooks/[a-zA-Z_-]+\.(sh|cjs|ps1)' <lab>/apex-spec.md | sort -u` against the SAME apex-spec.md the auditor used (cite SHA at round-time). Compare the round-checker's extracted set against the auditor's `spec_named_hook_presence[].hook` field set. If round-checker_set \ auditor_set is non-empty, REJECT closure."
- Add round-checker output requirement: report both `auditor_extracted_size`, `round_checker_extracted_size`, and the symmetric difference. Discrepancies are FAILs, not warnings.

Without round-checker independence, the dynamic-extraction gate is auditor-self-attested — a weaker guarantee than the static "exactly 15" gate it replaces. The whole point of CR-C-R2-01's escalation was to make the gate enforceable; R3 made it adaptive but lost enforceability.

### CR-C-R3-03 — MAJOR. Shell vs. node marker-parser asymmetry: shell parser silently accepts malformed marker `__APEX_AUDIT_PROBE__:<nonce>` (no agent_id, no command) as nonce=agent_id=same-string; node parser correctly rejects.

I traced both parsers manually with edge-case inputs. Results:

| Input | Shell parser | Node parser |
|-------|--------------|-------------|
| `__APEX_AUDIT_PROBE__:abc:agent rm` | OK nonce=abc agent_id=agent | OK nonce=abc agent_id=agent |
| `__APEX_AUDIT_PROBE__::agent rm` | REJECT (empty nonce) | REJECT (empty nonce) |
| `__APEX_AUDIT_PROBE__:nonce:agent` (no cmd) | OK nonce=nonce agent_id=agent | OK nonce=nonce agent_id=agent |
| `__APEX_AUDIT_PROBE__:nonce123` (no second colon, no cmd) | **OK nonce=nonce123 agent_id=nonce123** | **REJECT (no rest after split)** |
| `__APEX_AUDIT_PROBE__:nonce: rm` (empty agent_id) | REJECT (empty agent_id) | REJECT (empty agent_id) |

**Root cause of the asymmetry (row 4):**

Shell (`_audit-probe-marker.sh` R3 lines 179-183):
```bash
local after_prefix="${cmd#$marker_prefix}"   # "nonce123"
local nonce="${after_prefix%%:*}"            # "nonce123" (no colon → entire string)
local rest="${after_prefix#$nonce:}"         # "nonce123" (prefix-strip fails, returns unchanged)
local agent_id="${rest%% *}"                 # "nonce123" (no space → entire string)
[ -z "$nonce" ] || [ -z "$agent_id" ] && return 1   # both non-empty → PASS
```

Node (apex-prompt-guard.cjs R3 lines 226-230):
```javascript
const afterPrefix = cmd.slice(markerPrefix.length);  // "nonce123"
const [nonce, rest] = afterPrefix.split(/:(.+)/, 2); // ["nonce123", undefined]
if (!rest) return false;                              // REJECT
```

The node parser correctly rejects because `split(/:(.+)/)` returns no second capture group when no colon exists. The shell parser does not detect the missing colon because `${after_prefix#$nonce:}` silently succeeds when the prefix-pattern doesn't match (bash semantics — no-op on mismatch).

**Practical impact.** Limited. The downstream F2/F3 registry lookup uses `(agent_id, nonce)` = `(nonce123, nonce123)`. No real registry entry has `agent_id == audit_probe_nonce`, so the lookup fails-closed at F2. **No false-allow vector is opened.** However:

1. **The R3 design's own stated invariant (shell + node parity) is violated.** R3 §0 lists CR-C-R2-03 closure as "exact same field list, exact same fallback order." The field-list parity is closed; the parser-grammar parity is broken. Same defect class, newly introduced.
2. **A future malformed-marker probe** that happens to have `agent_id == nonce` (e.g. a copy-paste bug in an axis-10 trial prompt) would be silently accepted by shell but rejected by node — different `audit_probe_allowed` event counts across guards using different helpers. The C-7 perf-smoke row catches O(n) but doesn't cover parser-asymmetry.
3. **Edge case 7** (`__APEX_AUDIT_PROBE__:nonce:agent` with no trailing command) is accepted by both parsers — but the registry lookup would succeed (if such an entry exists) and the helper would emit `audit_probe_allowed` for an EMPTY command. Downstream guard sees `cmd == "__APEX_AUDIT_PROBE__:nonce:agent"` and may pattern-block on the literal — or may pass-through. Either way, an audit event is emitted that doesn't correspond to a real bypass.

**Required for R4:**
- Add an explicit second-colon presence check in the shell parser: after `local rest="${after_prefix#$nonce:}"`, verify `[ "$rest" = "$after_prefix" ] && return 1` (prefix-strip was a no-op → no second colon → malformed).
- Add an explicit command-presence check in both parsers: after extracting `agent_id`, verify `[ -n "$cmd_remainder" ] && return 1` if no trailing command was provided. (Or accept empty command but document the design choice.)
- Add C-8 test row: probe with `__APEX_AUDIT_PROBE__:nonce-only` (no second colon) — expect REJECT in both shell and node helpers.
- Add C-9 test row: probe with `__APEX_AUDIT_PROBE__:n:a` (no trailing command) — expect deterministic behavior across both helpers.

### CR-C-R3-04 — MAJOR (escalated from R2's MINOR — proof is wrong, not just absent). The append-only race-safety proof in R3 §2 is factually incorrect: live `subagent-stop.sh` lines 178-185 rewrites the entire registry via tmp+mv. The "append-only" invariant the proof relies on does not hold.

R3 §2 race-safety proof (lines 274) claims:

> "`.apex/in-flight-subagents.jsonl` is append-only by contract: `pre-subagent-start.sh` line 144 uses `>> "$REG"` (no truncation, no rotation). `subagent-stop.sh` mutates the file via `jq -c ... | mv $TMP $REG` to flip status — but only flips field values; never deletes lines. The `tail -n 1` of a jq filter (last-match-wins iteration) is therefore safe under concurrent appends because the final correct entry exists in the file and earlier mutations only flipped status — a stale 'in_flight' hit on a now-stopped entry is impossible because the flip is atomic-rename."

Verified live `framework/hooks/subagent-stop.sh` lines 175-186:
```bash
if [ -n "$RESOLVED_ID" ]; then
    if [ -f "$REG" ]; then
      TMP_REG="${REG}.tmp.$$"
      jq -c --arg id "$RESOLVED_ID" '
        if .agent_id == $id and .status == "in_flight"
        then .status = "stopped" | .stopped_at = (now | strftime(...))
        else . end' "$REG" > "$TMP_REG" 2>/dev/null \
          && mv "$TMP_REG" "$REG" \
          || rm -f "$TMP_REG"
    fi
```

**The proof is wrong in two ways:**

1. **`mv` replaces the inode.** A concurrent `>> "$REG"` (via O_APPEND) from `pre-subagent-start.sh` operating on the ORIGINAL inode continues writing to the inode that has been orphaned by the rename. The new line is **lost** from the registry. R3's claim that "only flips field values; never deletes lines" is true for the lines `jq` read, but lines that ARRIVE during the jq-read-to-mv window are silently dropped. This is a known JSONL race pattern.

2. **The "stale in_flight on a now-stopped entry is impossible" claim is also wrong.** During the jq-read-to-mv window, a guard reading the OLD inode (e.g. via `jq -c ... $REG | tail -n 1`) sees the pre-flip state. The guard's read is consistent (single-inode), but the registry it reads is stale relative to the in-progress subagent-stop. A sibling auditor that just stopped, but whose `mv` has not yet completed, will appear in the guard's read as `status: in_flight`. F3 may match the now-stopped sibling's nonce. **The "atomic-rename" guarantee protects against torn reads; it does NOT prevent stale-snapshot reads.**

**Practical impact.** Low frequency in normal operation (jq-read-to-mv window is sub-millisecond). But under Wave 1 with 5 concurrent framework-auditors, the probability is non-zero. And the design's stated invariant (registry consistency at marker-check time) is wrong by construction.

**Required for R4:**
- Correct the proof to acknowledge: (a) subagent-stop.sh rewrites the entire file, NOT in-place; (b) concurrent appends during the rewrite window are lost; (c) guard reads during the rewrite window see stale state.
- Either: (a) add a registry-lock mechanism (flock around append + rewrite) — significant complexity; OR (b) document the bounded residual: "F3 may match a sibling auditor whose subagent-stop is racing the guard's read; bounded by jq-read-to-mv wall-time (~1ms); acceptable trust envelope." Re-classify as R-AT-P7-XX residual rather than CLOSED.
- Add C-10 test row (or extend C-5): simulate the race by writing a registry where status="stopped" was flipped between the auditor's marker emission and the guard's read. Expect: the helper SHOULD return false (no match for live in_flight + nonce + agent_name). Verify behavior matches the documented residual.

This finding is escalated from R2's MINOR (which asked for a proof) to R3's MAJOR (the proof was provided but is empirically false against the live code).

---

## §3. Cross-design coherence (R3)

### AC-4 / AC-C1 closure path
Sound IF CR-C-R3-01 (protocol §10 update) AND CR-C-R3-02 (round-checker independence) are closed. The dynamic-extraction mechanism itself is correct in principle; the gate is currently auditor-self-attested rather than independently verified.

### AC-5b / AC-C2 closure path
Sound. The self-identifying marker `__APEX_AUDIT_PROBE__:<nonce>:<agent_id>` correctly closes the concurrent-auditor sibling cross-talk for Wave 1 with 5 framework-auditors. The trust-matrix claim ("only the auditor whose nonce was emitted passes F3") now holds because F2 is exact agent_id lookup (R3 §2 helper lines 188-190). The CR-C-R3-03 parser-asymmetry does not open a false-allow vector (downstream F2/F3 fails-closed); it only violates the design's own parity invariant.

### Concurrent-auditor trace (Wave 1, 5 auditors)
For each auditor `i ∈ {1..5}`, prompt-guard's helper extracts `(nonce_i, agent_id_i)` from the marker, then F2 looks up `agent_id_i` in registry (must be in_flight as framework-auditor), then F3 verifies `audit_probe_nonce == nonce_i`. If auditor #2 emits its marker, no possible way for guard to mis-attribute to auditor #1: agent_id is in the marker itself, not derived from "most recent." **Closes CR-C-R2-02 cleanly for the in-flight case.** (CR-C-R3-04 race-window residual is separate.)

### CR-C-R2-03 field-list parity verification
Live apex-prompt-guard.cjs lines 54-61: `ti.content || ti.new_string || ti.prompt || ti.command || ti.description || ''`. R3 helper shell line 168-173: `.tool_input.content // .tool_input.new_string // .tool_input.prompt // .tool_input.command // .tool_input.description // empty`. R3 node helper line 218-222: same JS chain. **Exact verbatim parity confirmed.** CR-C-R2-03 closed.

### Coherence with §12.2
Unchanged. AC-4, AC-5b, AC-6b, AC-C1, AC-C2 all §12.2 hard-FAIL. No L-item path. Path C amendment ladder intact.

---

## §4. Summary table

| Finding | Sev. | TP | Impact | R4 required |
|---|---|---|---|---|
| CR-C-R3-01 | BLOCKING | C1 | EXPERIMENT-PROTOCOL-C.md §10 still hardcodes 17 rows; contradicts §3 dynamic gate | Yes — update §10 to match §3 |
| CR-C-R3-02 | MAJOR | C1 | Round-checker independence under-specified; AC-C1 gate is auditor-self-attested | Yes — bind round-checker to re-run grep independently |
| CR-C-R3-03 | MAJOR | C2 | Shell parser silently accepts malformed marker (no second colon); diverges from node parser | Recommended — add second-colon check + parity test rows |
| CR-C-R3-04 | MAJOR | C2 | Race-safety proof is factually wrong against live subagent-stop.sh rewriter | Yes — correct proof, document bounded residual, add race test row |
| CR-C-R2-03 closure | — | C2 | Field-list parity verified verbatim | None |
| CR-C-R2-05 closure | — | C2 | Empty-nonce stderr loud-fail in place | None |

---

## §5. Verdict

**PASS-WITH-CHANGES.**

3 of 5 R2 deltas cleanly closed (CR-C-R2-02 concurrent-auditor case via self-identifying marker, CR-C-R2-03 field-list parity, CR-C-R2-05 empty-nonce stderr). The structural lever is intact: dynamic-extraction replaces magic-number, self-identifying marker eliminates "most-recent" ambiguity, both helpers extract from the same 5-field priority list.

However:

1. **CR-C-R3-01** is BLOCKING. EXPERIMENT-PROTOCOL-C.md §10 still says "17 rows" / "fewer than 17 entries" — the exact CR-C-R2-01 defect re-introduced via an un-updated section. The protocol file is internally inconsistent.

2. **CR-C-R3-02** is MAJOR. The dynamic-extraction gate is currently auditor-self-attested. The round-checker is never explicitly bound to re-run the grep independently. An auditor who reports `extracted_set_size == enumerated_set_size` (both narrow) passes the set-equality check trivially. The enforceability that the static "exactly 15" gate had is lost.

3. **CR-C-R3-03** is MAJOR. The shell + node marker parsers diverge on the malformed input `__APEX_AUDIT_PROBE__:<nonce-only>`. Shell accepts as nonce=agent_id=same-string; node rejects. No false-allow vector (downstream F2/F3 fails closed), but violates the design's own stated parity invariant — same defect class as CR-C-R2-03 that R3 just closed.

4. **CR-C-R3-04** is MAJOR. R3's race-safety proof is factually wrong: live `subagent-stop.sh` lines 178-185 rewrites the entire registry via tmp+mv, not in-place status-flips. Concurrent appends during the rewrite window are silently lost; guard reads see stale state. The "atomic-rename" claim conflates torn-read protection with concurrent-writer safety.

No FAIL warranted. The structural skeleton is sound; CR-C-R3-01 is a documentation-update miss (10-minute fix); CR-C-R3-02 is a 1-paragraph addition + round-checker contract bind; CR-C-R3-03 is a 2-line shell helper hardening + 2 test rows; CR-C-R3-04 requires a correct proof + bounded-residual documentation. None of the 4 R3 findings require re-architecting.

**Re-submission path:** author `FIX-DESIGN-C-R4.md` with §0 changelog addressing all 4 findings. R4 review will be tight — the 3 R2-cleanly-closed items stay closed; only the 4 R3 deltas need re-validation.

---

Authored 2026-05-25. Clean-room R3. No implementation written. No commits proposed.
