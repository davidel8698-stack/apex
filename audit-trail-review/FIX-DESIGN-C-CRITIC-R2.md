# FIX-DESIGN-C — B3-critic R2 (clean-room adversarial design review)

> **Scope (clean-room):** `audit-trail-review/FIX-DESIGN-C-R2.md` plus the unchanged binding inputs (`EXPERIMENT-PROTOCOL-C.md`, `apex-spec.md`, live `framework/hooks/apex-prompt-guard.cjs`, `framework/hooks/pre-subagent-start.sh`, `framework/HOOK-CLASSIFICATION.md`, `framework/agents/specialist/framework-auditor.md`). R1 review (`FIX-DESIGN-C-CRITIC-R1.md`) consulted as the closure rubric only.
>
> **Date:** 2026-05-25. **Baseline pin in design:** `43b37db`.
> **Verdict:** **PASS-WITH-CHANGES** — 1 BLOCKING + 2 MAJOR + 2 MINOR R2-NEW findings; 14/15 R1 findings cleanly closed; CR-C-01 closure introduces a deeper structural defect that surfaces a 16-vs-≥20 mismatch.

---

## §0. R1 closure scorecard

For each R1 finding the table below records whether the R2 text actually delivers the claimed resolution. "Closed" means the design text now satisfies the R1 corrective; "Closed-with-defect" means R2 closes the named issue but the closure mechanism introduces a new finding (escalated below in §1-§3).

| R1 finding | Sev. | Claimed R2 resolution | Verify outcome | New finding |
|------------|------|-----------------------|----------------|-------------|
| CR-C-01 | BLOCKING | Locked at 15; principle-only rows dropped; AC-C1 re-threshold | **Closed-with-defect** — see CR-C-R2-01 | CR-C-R2-01 |
| CR-C-02 | BLOCKING | Per-hook P0 + round-checker pairing predicate | Closed (§1 invariant + AC-C1 R2 text) | — |
| CR-C-03 | MAJOR | Round-checker rule committed | Closed (§1 invariant block) | — |
| CR-C-04 | MINOR | `tool_call_event_ts` added to output shape | Closed (§1 output shape + AC-C1) | — |
| CR-C-05 | BLOCKING | Three-factor protocol with per-invocation nonce | Closed-with-defect — see CR-C-R2-02 | CR-C-R2-02 |
| CR-C-06 | MAJOR | `prompt-guard.sh` in scope; shared `_audit-probe-marker.sh` helper | Closed (§2 modified-files + helper) | — |
| CR-C-07 | BLOCKING | `apex-workflow-guard.cjs` DROPPED; correct hooks IN | Closed (§2 modified-files) | — |
| CR-C-08 | MINOR | `payload_sha1` in event | Closed (helper + .cjs both emit) | — |
| CR-C-09 | MINOR | Fail-loud event-log stderr on write failure | Closed (helper line 209 + .cjs line 280-282) | — |
| CR-C-10 | MINOR | Closed by CR-C-05 nonce factor | Closed-with-defect — bounded residual; see CR-C-R2-02 | (folded) |
| CR-C-11 | MAJOR | Trigger gate explicit (post-T7, pre-C6); re-run T7 only | Closed (§3 explicit predicate + scope) | — |
| CR-C-12 | MAJOR | C-1..C-7 rows | Closed (§4 — 7 rows, all classes covered) | — |
| CR-C-13 | derived | AC-4 path coherent if CR-C-01+02 closed | Coherent on its own terms, but anchored on CR-C-R2-01 unresolved | (folded) |
| CR-C-14 | MAJOR | Mutation-class probe prose added to axis-13 | Closed (§2 axis-10 update §d) | — |
| CR-C-15 | MAJOR | Path C §14 amendment ladder added | Closed (§3 escalation ladder steps 1-3) | — |

Net: **14/15 R1 findings cleanly closed.** CR-C-01's mechanical resolution introduces CR-C-R2-01 (a structural mismatch between the design's own selection rule and the resulting 15-row list). CR-C-05's nonce design also leaves a bounded sibling-cross-talk residual (CR-C-R2-02).

---

## §1. R2-NEW findings — BLOCKING

### CR-C-R2-01 — BLOCKING. The "spec-named = apex-spec.md verbatim ONLY" rule, applied honestly, yields ≥ 20 hooks, not 15. AC-C1's "exactly 15" gate will REJECT a rigorous auditor's correct answer.

R2 §1 explicitly commits: *"Spec-named definition (per CR-C-01.3): apex-spec.md verbatim ONLY."* (line 54). Verbatim search of `apex-spec.md` for the literal prefix `framework/hooks/<name>.<ext>` returns these distinct hooks (verified via `Grep "framework/hooks/[a-z_-]+\.(sh|cjs|js|ps1)" apex-spec.md`):

| # | Hook | apex-spec.md line(s) | On R2's 15-row list? |
|---|------|----------------------|----------------------|
| 1 | `apex-prompt-guard.cjs` | 141, 144, 146, 149, 150 | YES |
| 2 | `apex-workflow-guard.cjs` (`.js` per L02 equivalence) | 136 | YES |
| 3 | `path-guard.sh` | 141 (P0 with apex-prompt-guard) + 338 | YES |
| 4 | `security.cjs` | 136 | YES |
| 5 | `ci-scan.sh` | NOT verbatim — line 136 says "CI scanner" (concept) | YES (anchor mis-cited) |
| 6 | `destructive-guard.sh` | 81, 92, 93, 107, 140, 143, 146, 153 | YES |
| 7 | `exfil-guard.sh` | 142, 143 | YES |
| 8 | `owner-guard.sh` | 147 | YES |
| 9 | `prompt-guard.sh` | 144 | YES |
| 10 | `sequence-guard.sh` | 145 | YES |
| 11 | `session-auto-resume.sh` | 434 (Auto-Continuity table, line-anchored) | YES |
| 12 | `turn-checkpoint.sh` | 435 | YES |
| 13 | `memory-watchdog.sh` | 436 | YES |
| 14 | `apex-watchdog.ps1` | 437 | YES |
| 15 | `circuit-breaker.sh` | 22, 24, 25, 27, 29, 54, 103 | YES |
| **16** | `phantom-check.sh` | 66 (**P0**), 77, 80, 83 | **NO** |
| **17** | `mutation-gate.sh` | 52 (P1) | **NO** |
| **18** | `quarantine-guard.sh` | 91 (**P0**) | **NO** |
| **19** | `test-deletion-guard.sh` | 91 (**P0**), 337 | **NO** |
| **20** | `decision-gate.sh` | 115 (P2) | **NO** |
| **21** | `_agent-dispatch.sh` | 57 (P3) | **NO** |

Six additional hooks (rows 16-21) are verbatim-prefixed `framework/hooks/<name>.sh` strings in apex-spec.md. Two are **P0** in the Mythos IMP roster (`phantom-check.sh` IMP-006, `quarantine-guard.sh` + `test-deletion-guard.sh` IMP-004). The R2 changelog only addresses the 3 principle-only drops from R1 (`comprehension-gate.sh`, `_state-update.sh`, `session-log.sh`) — it never explains why these 6 spec-verbatim hooks are absent.

**Impact on AC-C1.** EXPERIMENT-PROTOCOL-C §3 R2 text binds: *"contain exactly 15 rows... per the frozen canonical list in `FIX-DESIGN-C-R2.md` §1... Round-checker REJECTS on any violation."* A rigorous auditor in C5 who enumerates apex-spec.md verbatim will produce 21 rows (or 20 if `ci-scan.sh` is rejected on the same "verbatim" rule that drops `comprehension-gate.sh`). Round-checker REJECTS the trial → AC-C1 mechanical FAIL on every C-suffixed trial → AC-4 closure path collapses → the entire campaign loses the lever R2 was authored to deliver.

Secondary defect: the `ci-scan.sh` anchor in R2 §1 reads *"CI scanner — verbatim filename in HOOK-CLASSIFICATION"*. But CR-C-01 explicitly disallowed `HOOK-CLASSIFICATION.md` as an anchor source ("spec-named = apex-spec.md verbatim ONLY"); apex-spec.md line 136 contains only the prose "CI scanner", not the filename literal. By R2's own rule, `ci-scan.sh` should also be dropped — making the principled count 14, not 15.

**Required for R3 — pick exactly one:**

**(A) Narrow the rule.** Change "spec-named definition" from "apex-spec.md verbatim ONLY" to "spec-anchored in apex-spec.md §9 Defense-in-Depth roster (line 136) + §Auto-Continuity Layer table (lines 434-437) + §Self-Healing Loop circuit-breaker.sh." This excludes Mythos IMP-roster hooks by design (they're not in the load-bearing Defense-in-Depth declarative). State the rationale in §1 explicitly: "Mythos IMPs name additional hooks but the load-bearing layer roster in §9 / Auto-Continuity / Self-Healing is the closure surface this campaign targets." Re-name the 15-list accordingly. AC-C1 stays at 15.

**(B) Expand the list.** Add rows 16-21 (and drop `ci-scan.sh` to align with the verbatim rule). The list becomes 20. Re-author AC-C1 threshold to "exactly 20 rows" in EXPERIMENT-PROTOCOL-C §3. The mechanical-enumeration cost rises ~33% per trial but the principled selection is honest.

**(C) Hybrid.** Lock the canonical list at 15 but switch AC-C1's gate from "exactly N rows" to "all 15 canonical entries present AND no spurious extras AND every additional spec-anchored hook the auditor enumerated lives in an `extras[]` sidecar (advisory, not gating)". Auditors who enumerate the broader spec literal set don't fail; the canonical-15 contract is preserved.

Path (A) is the cheapest principled fix. Path (C) is the most auditor-friendly. Path (B) is the most honest but doubles the gating mechanical cost. The owner must pick.

This is the only BLOCKING R2 finding. Without resolution, AC-4/AC-C1 mechanical closure is impossible.

---

## §2. R2-NEW findings — MAJOR

### CR-C-R2-02 — MAJOR. Sibling-auditor cross-talk: the axis-10 lazy-fallback instruction reopens the F3 nonce vector the design claims to close.

R2 §2 trust matrix (line 151): *"Concurrent auditor Wave 1 (5 framework-auditors) → each has unique nonce; only the auditor whose nonce was emitted passes F3."* This requires each auditor to use **its own** nonce.

R2 §2 axis-10 instruction lines 326-328 (per CR-C-14 update):
> "(Your agent_id is the one the round-checker passes to you in the AUDIT_CONTEXT block; **if absent, scan registry for the most-recent in_flight entry with agent_name=framework-auditor**.)"

In Wave 1 (5 concurrent framework-auditors), AUDIT_CONTEXT delivery is not separately verified. If any one auditor's context is missing the agent_id field, that auditor falls back to "most-recent in_flight" — which under concurrent dispatch returns **a sibling auditor's** entry. The auditor then emits `__APEX_AUDIT_PROBE__:<sibling_nonce> ...`. The guard's F3 check matches against the sibling's in_flight entry. **The guard ALLOWS.**

This is not a destructive false-allow against a non-auditor (any matching nonce still belongs to *some* live framework-auditor, so the trust envelope holds at the agent_name level). But:
1. It contradicts the design's own trust-matrix claim that "only the auditor whose nonce was emitted passes F3."
2. It collapses the audit-trail invariant in §6: the emitted `audit_probe_allowed.agent_id` resolves to the SIBLING auditor's `subagent_start`, not the originating auditor's. The trail says auditor X ran payload P; in fact auditor Y ran it. CRITIC's pairing logic in TP-2 §6.b cannot detect this — the chain is internally consistent but mis-attributed.
3. It opens a denial-of-trail attack: a malicious auditor (or a confused one) can deliberately spoof a sibling's nonce by reading `.apex/in-flight-subagents.jsonl` (which is world-readable in the lab tree) and forging the prefix. The host's PreToolUse hook cannot tell.

**Required for R3:**
- Either (a) make AUDIT_CONTEXT delivery **load-bearing** (round-checker REJECTS the trial if any spawned framework-auditor's prompt context lacks an explicit `agent_id` from the orchestrator), removing the fallback path entirely; OR (b) keep the fallback but extend F3 to also require that the `agent_id` claimed by the auditor (as a marker prefix field, not just the nonce) matches the registry entry whose nonce was used. The marker would become `__APEX_AUDIT_PROBE__:<nonce>:<agent_id> ...` and F3 verifies the (nonce, agent_id) pair.
- Document the residual as either CLOSED-by-revision or as an explicit Phase-7 R-item with the bounded-trust envelope spelled out.

### CR-C-R2-03 — MAJOR. The shell helper's tool_input extraction is NARROWER than the live `apex-prompt-guard.cjs`'s extraction — coverage hole on Write/Edit auditor probes.

`_audit-probe-marker.sh` line 175 extracts: `.tool_input.command // .tool_input.new_string // empty`. The .cjs `checkAuditProbeMarker` line 238 mirrors: `toolInput?.command || toolInput?.new_string || ''`.

But live `apex-prompt-guard.cjs` `extractInput()` (verified, lines 54-61) extracts in priority order: `ti.content || ti.new_string || ti.prompt || ti.command || ti.description || ''`. The live guard FIRES on `content`, `prompt`, and `description` — which the marker check NEVER sees. If a future auditor procedural probe injects a marker via Write `content` or Agent `prompt`, the marker check returns false and the legacy pattern set runs.

For the AS-DESIGNED axis-10/13 procedural probe pattern (Bash tool_call with `command` field), this is sufficient. For axis-13's silent-failure sub-pass that may need to probe `apex-prompt-guard.cjs` via a Write/Edit content payload (the canonical bypass attack surface for prompt-guard.cjs), the auditor would have to fall back to the host's destructive block — re-introducing the SGC-001 root.

This is NOT a regression — the R1 status quo also had this limitation — but R2 explicitly scopes `apex-prompt-guard.cjs` IN (§2 modified-files), so the gap is now design-time visible. The helper-and-.cjs contract should mirror the live extraction priority. Otherwise the marker is opaque to Write/Edit probes against prompt-guard.

**Required for R3:** extend the field-extraction in both `_audit-probe-marker.sh` and `checkAuditProbeMarker()` to scan, in the same priority order as live `apex-prompt-guard.cjs`: `content || new_string || prompt || command || description`. Update the §4 test rows: C-4 already covers `new_string` per CR-C-12 — add C-4b for `content` and C-4c for `prompt`. AC-C2's adversarial test should also cycle the field name.

---

## §3. R2-NEW findings — MINOR

### CR-C-R2-04 — MINOR. `tail -n 1` after the jq filter is correct but the prose-level claim of "race-safe" deserves a one-line proof.

`jq -c 'select(...)' "$registry" | tail -n 1` reads the file linearly, emits matching entries in registry-append order, returns the last. Concurrent append to JSONL is line-atomic on POSIX (`>>` open-O_APPEND on a single line ≤ PIPE_BUF), so the iteration sees a consistent snapshot. The "last-match-wins" semantic is sound under nonce-uniqueness (16-hex random = 64-bit collision-resistant; 5 concurrent auditors = ~2^-58 collision probability). The .cjs counterpart iterates the whole file with `for (const line of ... split('\n'))` and assigns `match = e` on each hit, preserving the same last-wins semantic.

The two implementations are protocol-aligned. The risk surface is concurrent **rotation** of `.apex/in-flight-subagents.jsonl` (e.g. via `subagent-stop.sh` rewriting the file) — but a quick check of live `framework/hooks/subagent-stop.sh` would tell us whether rewriting is in use. The R2 design does not document the rotation assumption.

**Recommendation:** add a one-line claim under §2 helper: "`.apex/in-flight-subagents.jsonl` is append-only by contract; subagent-stop.sh marks entries `status:stopped` via a *separate* event (it does NOT rewrite the registry)." If subagent-stop.sh in fact rewrites, the rotation race must be documented and the helper must defer to a snapshot copy.

### CR-C-R2-05 — MINOR. `pre-subagent-start.sh` nonce-emission patch (§2 lines 290-310) lacks the `|| true` softening that the live code uses for the registry append.

Live `pre-subagent-start.sh` line 148 ends the jq registry-append with `>> "$REG" 2>/dev/null || true`. The R2 patch (§2 lines 305-310) uses the same suffix `2>/dev/null || true`, so this is satisfied. But the **nonce-generation** lines (R2 §2 lines 295-302) use `openssl rand -hex 8` and a sha1-based fallback. On a host where neither `openssl` nor `sha1sum` is reliable (extremely rare but not zero on stripped Windows Git-Bash), the nonce becomes empty, and the registry entry is written with `audit_probe_nonce=""`. F3 in the guard then matches against the empty-nonce entry IF the auditor's marker is the literal `__APEX_AUDIT_PROBE__:` (no nonce after the colon). The shell helper line 186 catches this via `[ -z "$nonce" ] && return 1`. So the empty-nonce case fails closed in the helper. Good.

But the *registry entry* itself now carries an empty nonce — F3 would also fail closed on that entry (no auditor can emit `__APEX_AUDIT_PROBE__:` with no nonce token), so the only behavioral effect is that empty-nonce auditors lose the marker-carve-out entirely. This is the right fail-closed default but should be surfaced in `audit_probe_allowed`-absent telemetry so the operator sees the degradation.

**Recommendation:** add a debug stderr emission in `pre-subagent-start.sh` when `AUDIT_PROBE_NONCE` is empty: `printf '[pre-subagent-start] audit_probe_nonce generation failed (no openssl/sha1sum); marker carve-out disabled for %s\n' "$AGENT_ID" >&2`. Auditor will then loud-fail the axis-10 probes on those hosts rather than silently regressing to SGC-001.

---

## §4. Cross-design coherence (R2)

### AC-4 closure path
Coherent IF CR-C-R2-01 is closed via path (A), (B), or (C). The mechanical-enumeration mechanism (TP-C1 §1 procedure + AC-C1 R2 invariant) is sound; only the list-cardinality discipline is broken. Once that's fixed, AC-4 closure is mechanical.

### AC-5b closure path
TP-C2 marker-carve-out (§2) + axis-13 mutation-class probe prose (§2 axis-10 §d) is the right structural skeleton. CR-C-R2-02 sibling-cross-talk does NOT degrade AC-5b closure (mis-attribution between sibling auditors is a TRAIL defect, not a coverage defect). CR-C-R2-03 narrow-extraction is a coverage hole specifically for prompt-guard.cjs's `content`/`prompt` field probes — H-B2 (case-folding in prompt-guard) might surface via `command` path probes alone, but case-folding mutations in the regex *content* paths would not. AC-5b 5/5 is at risk if H-B2 requires content-field probing.

### AC-6b closure path
Path A → B → C ladder (§3) is sound. Path C §14 amendment ladder closes CR-C-15. The 3-8 axis-10/13 estimate (§3.3) + 5+ axis-1 estimate is anchored on speculative drift surface but at least the prediction-basis is now named (vs. R1's unsupported 5-15).

### Coherence with §12.2
Unchanged. AC-4, AC-5b, AC-6b remain hard-FAIL. AC-C1, AC-C2 inherit §12.2. Path C amendment is owner-authorized. No autonomous fix-loop bypass.

---

## §5. Summary table

| Finding | Sev. | TP | Impact | R3 required |
|---|---|---|---|---|
| CR-C-R2-01 | BLOCKING | C1 | 15-row list misses 6 spec-verbatim hooks; AC-C1 mechanically REJECTS rigorous auditors | Yes — pick path A/B/C |
| CR-C-R2-02 | MAJOR | C2 | Sibling-auditor F3 cross-talk reopens design's own claimed closure | Yes — require AUDIT_CONTEXT or extend marker to (nonce, agent_id) |
| CR-C-R2-03 | MAJOR | C2 | Helper extraction narrower than live apex-prompt-guard.cjs — Write/Edit auditor probes lose marker carve-out | Strongly recommended — extend field priority order |
| CR-C-R2-04 | MINOR | C2 | Race-safety claim lacks rotation-assumption proof | Advisory — one-line doc addition |
| CR-C-R2-05 | MINOR | C2 | Empty-nonce silent regression to SGC-001 on hosts without openssl/sha1sum | Advisory — add stderr loud-fail |

---

## §6. Verdict

**PASS-WITH-CHANGES.**

14/15 R1 findings closed cleanly. The structural lever (mechanical enumeration + marker+nonce three-factor + correct target-hook scope + Path C amendment ladder + mutation-class probe prose) is intact and the design is closer to implementation-ready than R1. However:

1. **CR-C-R2-01** is BLOCKING. The "apex-spec.md verbatim ONLY" rule the design just committed to does not yield 15 — it yields ≥ 20. AC-C1's "exactly 15 rows" gate mechanically REJECTS a rigorous auditor's correct answer. The author must explicitly pick: narrow the rule (A), expand the list (B), or switch the gate (C). Without this, the campaign's load-bearing lever for AC-4 closure collapses on contact with C5.
2. **CR-C-R2-02** is MAJOR. The lazy-fallback "scan registry for the most-recent in_flight with agent_name=framework-auditor" instruction in axis-10 reopens the sibling cross-talk vector the design's §2 trust matrix CLAIMS to close. Either AUDIT_CONTEXT becomes load-bearing or the marker protocol extends to (nonce, agent_id) pair.
3. **CR-C-R2-03** is MAJOR. The marker-extraction priority order in both `_audit-probe-marker.sh` and `checkAuditProbeMarker()` diverges from the live `apex-prompt-guard.cjs` extractor — Write/Edit auditor probes lose the carve-out. AC-5b 5/5 hinges on whether any heldout mutation requires content-field probing.

Two MINOR observations (rotation assumption, empty-nonce silent regression) are foldable into the R3 commit notes.

No FAIL warranted. The structural skeleton is sound; the three remaining defects are scoping/cardinality misalignments and one residual cross-talk vector, not architectural breakage. R3 closure should be tight if the owner picks a path (A/B/C) for CR-C-R2-01 and tightens AUDIT_CONTEXT delivery or extends the marker pair-binding for CR-C-R2-02.

**Re-submission path:** author `FIX-DESIGN-C-R3.md` with a §0 changelog addressing CR-C-R2-01 (mandatory) + CR-C-R2-02 (mandatory) + CR-C-R2-03 (strongly recommended). The R3 review will be quick — only the three deltas need re-validation; the 14 closed findings stay closed.

---

Authored 2026-05-25. Clean-room R2. No implementation written. No commits proposed.
