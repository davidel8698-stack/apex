# EXPERIMENT-PROTOCOL — Campaign C (Proof-of-Process Maximization)

> **Pre-registered. Frozen.** Authored 2026-05-25 before any Campaign-C
> code lands. Mirrors `audit-trail-review/EXPERIMENT-PROTOCOL.md` (B0
> version) structure. Inherits B's §10 trial protocol verbatim. Adds 4
> new TPs (TP-C1..TP-C4) targeting the 3 §12.2 hard-FAIL ACs that
> empirically missed in Campaign B's R2 closure.
>
> **Baseline commit (pinned):** `43b37db` (HEAD post Gate B5 R2 closure
> `0dc101b`; clean working tree).
>
> **Predecessor:** Campaign B — closed HALTED-AT-B5-R2 2026-05-25
> (`audit-trail-review/FINAL-CERTIFICATION.md`; B5-critic R2 PASS).
>
> **Companion plan:** `~/.claude/plans/unified-imagining-sparrow.md`.

---

## §1. Scope

Campaign C closes the 3 §12.2 hard-FAIL ACs that empirically missed in B's R2:
- **AC-4** (heldout Class-A 0/2) — auditor pattern-recognition trumps mechanical enumeration.
- **AC-5b** (heldout B+C+D 0/5) — SGC-001 systemic sandbox interference + subtle-mutation read-pass floor.
- **AC-6b** (NC count outside [10, 35]) — coverage collapse driven by axes 10+13 sandbox blocks.

The structural lever is **mechanical enumeration over pattern recognition** + **legitimate audit-probe carve-out**: every spec-named hook is iterated by filename (not by architectural intent); the host's prompt-guard recognises legitimate audit probes via a two-factor protocol (literal marker prefix + registry agent-identity).

**In-scope.** TP-C1..TP-C4 per `unified-imagining-sparrow.md`. The 11-trial × 5-lab corpus re-run per §10 (mirrors B's §10).

**Out-of-scope.** New corpus mutations (re-uses Campaign A's WORKING + HELDOUT corpora verbatim, as B did). New AC categories (re-uses B's 12 ACs, ties new outcome to existing AC numbers as -R3 suffixed).

---

## §2. Baseline state (what was true at freeze)

- **Repo HEAD:** `43b37db` (clean working tree).
- **Campaign B closure:** B5-critic R2 PASS at commit `0dc101b`. Gate B5 NOT crossed (HALTED-AT-B5-R2). 3 hard-FAIL ACs reserved for Campaign C closure.
- **Live `framework/hooks/apex-prompt-guard.cjs`:** 117 lines; no environment-variable check; no agent-identity awareness; fires on `tool_input` content patterns only.
- **Live `framework/hooks/pre-subagent-start.sh`:** writes `.apex/in-flight-subagents.jsonl` AFTER apex-prompt-guard fires (Claude Code hook ordering).
- **Live `framework/agents/specialist/framework-auditor.md`:** axis-1 (lines 75-79) uses conceptual language ("mechanisms present, active, invoked"); axis-10 (lines 119-178) already mechanical-checklist for 5 guards.
- **Live `framework/test-fixtures/security-patterns.json`:** 227 lines; pattern manifest schema in place; no `audit_probe_marker` field.
- **`.lab/apex-detector-lab-*` clones:** unchanged from Campaign B; same mutant corpora.

---

## §3. Acceptance criteria — Campaign C (R3 versions)

**AC-4-R3 — Heldout Class-A reliable-kill ≥ 2/2.** Mechanical enumeration via TP-C1 MUST surface H-A1 (memory-watchdog.sh deletion) AND H-A2 (session-auto-resume.sh deletion) in ≥ 2 of 3 heldout trials (T4, T5, T6).
- **Threshold:** binary (each mutant must be reliably killed).
- **§12.2 hard-FAIL.** No L-item path.

**AC-5b-R3 — Heldout B+C+D reliable-kill ≥ 5/5.** TP-C2 marker-carve-out MUST unblock procedural axis-13 probes; auditor MUST then surface H-B1, H-B2, H-C1, H-C2, H-D1 in ≥ 2 of 3 heldout trials.
- **Threshold:** binary.
- **§12.2 hard-FAIL.**

**AC-6b-R3 — NC count in [10, 35].** With sandbox carve-out (TP-C2), T7 NC trial's axes 10+13 procedural probes execute live; coverage lifts; surfaced findings count lands in band.
- **Threshold:** [10, 35] range (unchanged from B0 §9.2).
- **§12.2 hard-FAIL.**

**AC-C1 (new) — Mechanical enumeration completeness.** Every C-suffixed trial's `coverage_map.axis_1.spec_named_hook_presence[]` MUST contain one entry per spec-literal hook extracted DYNAMICALLY at round time via `grep -oE 'framework/hooks/[a-zA-Z_-]+\.(sh|cjs|ps1)' <lab>/apex-spec.md | sort -u`. Every row MUST carry `tool_call_event_ts` matching a real `tool_call` event. Every row with `exit_code != 0` MUST have a matching dedicated finding whose `cite[]` contains the hook's filename (per-hook P0; rolled-up baseline-absent finding does NOT discharge). Round-checker REJECTS closure if the auditor's enumerated set is a strict subset of the extracted set, OR if any `exit_code != 0` row lacks paired finding.
- **Threshold:** binary (set-equality + pairing predicate). The expected count is ~20-25 depending on spec version — never frozen.
- **§12.2 hard-FAIL.**
- **R3 update post B3-critic CR-C-R2-01: replaced fixed-count gate (R2's 15) with dynamic-extraction gate. See `FIX-DESIGN-C-R3.md` §1 for rationale.**

**AC-C2 (new) — Two-factor marker protocol integrity.** Adversarial test: synthetic probe carrying the marker prefix but originating from a non-`framework-auditor` agent_name MUST be BLOCKED by apex-prompt-guard.cjs (exit 2). Verified by `test-audit-trail-layer.sh` C-3.
- **Threshold:** binary (false-allow = 0).
- **§12.2 hard-FAIL.**

**Inherited from B0 (must continue to PASS):** AC-1, AC-2, AC-3a/b/c/d, AC-5a, AC-6a, AC-7b/c, AC-8a, AC-9, AC-11, AC-12.

---

## §4. Trust Points (designed in C1 / FIX-DESIGN-C.md)

| TP | Closes AC | File(s) modified | Estimated LOC |
|----|-----------|-------------------|---------------|
| **TP-C1** | AC-4, AC-C1 | `framework/agents/specialist/framework-auditor.md` axis-1 lines 75-79 (replace + extend with 17-hook checklist) | ~60 LOC added |
| **TP-C2** | AC-5b, AC-6b (via coverage lift), AC-C2 | `framework/hooks/apex-prompt-guard.cjs` + `framework/hooks/apex-workflow-guard.cjs` + `framework/test-fixtures/security-patterns.json` + `framework/agents/specialist/framework-auditor.md` axis-10 | ~30 LOC added across files |
| **TP-C3** | AC-6b (lazy fallback if TP-C2 alone doesn't lift NC count) | Conditional — `framework/agents/specialist/framework-auditor.md` axis-4/axis-12 if needed | ~30 LOC (only if triggered) |
| **TP-C4** | Test coverage | `framework/tests/test-audit-trail-layer.sh` + 3 new rows (C-1, C-2, C-3) | ~80 LOC added |

---

## §5. Marker protocol specification (TP-C2 frozen)

**Marker literal:** `__APEX_AUDIT_PROBE__` (frozen; collision-resistant random-prefix).

**Auditor invocation pattern (axis-10 + axis-13 procedural sub-passes):**
```bash
__APEX_AUDIT_PROBE__ env APEX_BYPASS_TEST=1 bash framework/hooks/<guard>.sh "<payload>"
```

**Guard recognition logic (apex-prompt-guard.cjs + apex-workflow-guard.cjs):**
- FIRST check before any pattern matching:
  1. Does `tool_input.command` (or `tool_input.content` for workflow-guard) start with the marker?
  2. If yes: read `.apex/in-flight-subagents.jsonl`; find most-recent `status=in_flight` entry.
  3. If `agent_name === "framework-auditor"`: emit `audit_probe_allowed` event with `agent_id` + payload-summary; exit 0 (allow).
  4. If either factor missing: continue to existing pattern-matching path (block on hit).

**Two-factor failure modes:**
- Marker without registry support → blocked (factor 2 missing).
- Registry says framework-auditor but no marker → blocked (factor 1 missing); auditor would have to add marker explicitly.
- Both factors present → allowed, but the allowance is auditable via the emitted event.

**Audit-trail invariant:** every `audit_probe_allowed` event MUST have a matching `subagent_start` for `framework-auditor` within the same session. Adversarial allowance impossible without registry forgery; registry is append-only.

---

## §6. Trial protocol (inherits B §10 verbatim)

Re-use B0 §10.1's 11-trial matrix verbatim:
- T1-T3 baseline (`.lab/apex-detector-lab-baseline`, sequential within lab)
- T4-T6 heldout (`.lab/apex-detector-lab-heldout`, sequential)
- T7 NC pristine (`.lab/apex-detector-lab`)
- T8 W-F3 neutral + T9 W-F3 PRIMED (`.lab/apex-detector-lab-W-F3`)
- T10 H-F2 (`.lab/apex-detector-lab-hf2`)
- T11 W-F2 static (no Task() needed; grep probe)

Output files: `audit-trail-review/trials/c5-*.md` (C5-prefixed to distinguish from B5-trials).

Per-trial prompt template: mirrors B's template with one addition — instruct the auditor to emit the marker prefix on every axis-10/axis-13 procedural Bash probe. Updated template lives in `audit-trail-review/CAMPAIGN-C-TRIAL-PROMPT.md` (authored in C5).

---

## §7. Scoring rubric

Mirrors B0 §12 verbatim with R3 substitutions:
- AC-4 → AC-4-R3 (heldout reliable-kill from §3 above)
- AC-5b → AC-5b-R3
- AC-6b → AC-6b-R3
- Plus new AC-C1 (mechanical enumeration coverage)
- Plus new AC-C2 (two-factor marker integrity)

Trial-validity fingerprint (per B0 §10.6) extended:
```
audit_trail_v=2; subagent_transcript_ok=<y|n>; gap1_closed=<y|n>; sgc=<n>; axis1_hooks_enumerated=<count>; audit_probes_allowed=<count>
```

The two new fields (`axis1_hooks_enumerated`, `audit_probes_allowed`) are the structural signal that TP-C1 + TP-C2 fired this trial.

---

## §8. §12 closure paths (inherit B0 verbatim)

- **§12.1 PASS-WITH-LIMITATION** — AC-3a/b/c/d, AC-5c (informational), AC-10a/b/c/d eligible.
- **§12.2 HARD-FAIL** — AC-1, AC-4, AC-5a, AC-5b, AC-6a, AC-6b, AC-C1, AC-C2 — no L-item path; fix or amend (§14).

---

## §9. Anti-amendment self-discipline

Per B0 §10.2: trial counts may be RAISED before C5 starts; never lowered. The 3 hard-FAIL ACs from B are FROZEN at their B0 thresholds; this protocol does NOT lower them. C5 measures whether TP-C1+TP-C2 deliver — empirically. If a hard-FAIL still misses post-C5, the loop continues to C5-R2, not to an amendment.

---

## §10. New live-evidence requirements (C-specific)

Each C5 trial MUST produce, in addition to B0's required artifacts:
1. `coverage_map.axis_1.spec_named_hook_presence[]` with one row per spec-literal hook extracted DYNAMICALLY at round time via `grep -oE 'framework/hooks/[a-zA-Z_-]+\.(sh|cjs|ps1)' <lab>/apex-spec.md | sort -u` (expected count ~19-25 depending on spec version; verified 19 at C0 freeze on baseline `43b37db`).
2. For each axis-10/axis-13 probe attempted: the `audit_probe_allowed` event in `.apex/event-log.jsonl` MUST exist with matching `agent_id` AND `payload_sha1` matching `sha1(tool_call.tool_input.<field>)`.
3. Native Claude Code transcript path verified per trial (carries over from B's §6.1 verified mechanism).

Round-checker rejects any trial whose `coverage_map.axis_1.spec_named_hook_presence[]` is a strict subset of the runtime-extracted set, OR whose probes claim execution but lack matching `audit_probe_allowed` events with the correct `payload_sha1`.

**R3 update post B3-critic CR-C-R3-01: replaced hardcoded "17 rows" with dynamic-extraction gate to match §3 AC-C1.**

---

## §11. Frozen — no changes without §14 amendment.

Authored 2026-05-25T21:30Z.
Baseline commit: `43b37db`.
Next session reads this verbatim as the C5 closure rubric.
