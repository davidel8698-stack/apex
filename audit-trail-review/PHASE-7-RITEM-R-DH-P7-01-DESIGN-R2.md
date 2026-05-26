# R-DH-P7-01 — Design R2 · BF-1/BF-2/BF-3 closure

**Supersedes:** `PHASE-7-RITEM-R-DH-P7-01-DESIGN.md` (R1).
**Critic R1:** FAIL — 3 blocking findings.
**Date:** 2026-05-26.

R1 content carries forward unchanged unless noted. R2 addresses BF-1 (scan-pattern coverage), BF-2 (audit-probe-marker exemption), BF-3 (fixture-shape contract).

---

## §0. Critic R1 closure summary

| BF | Issue | R2 resolution |
|----|-------|---------------|
| **BF-1** | Scan patterns omit `case` — W-B3 (the canonical target) uses `case "$target_path" in */vendor/*)` form, would NOT be surfaced | §2.A scan procedure widened to 7 pattern families: `[[ X == *L* ]]`, `[[ X == "L" ]]`, `[ "$X" = "L" ]` (POSIX), `case … in *L*)`, `grep -Fq -- "L"` (in any form, incl. printf-pipe), `echo … grep`, function-call delegation `\w+_check "$X"` etc. |
| **BF-2** | Exemption gate misses audit-probe-marker (`__APEX_AUDIT_PROBE__:`) — legitimate Campaign C TP-C2 carve-out, would emit P0 false-positive on framework's own hooks | §2.A exemption set expanded to include: (1) `framework/HOOK-CLASSIFICATION.md`, (2) `apex-spec.md`, (3) `audit-trail-review/FIX-DESIGN-C-R4.md`, (4) `framework/test-fixtures/security-patterns.json`, (5) inline-comment-block detection: literal preceded within 5 lines by `# Campaign [A-C] TP-` OR `# IMP-\d+` OR `# spec anchor` |
| **BF-3** | Fixture-shape constraint under-specified — H-F fixtures must satisfy clauses (i)-(viii) baseline | §2.C explicit Fixture Coherence Contract subsection + simulator-extension append-point pseudo-code |

---

## §2. Design (revised)

### Change A (REVISED per BF-1 + BF-2) — axis-13.c

**Location:** AFTER axis-13.b, BEFORE axis-13.e (unchanged from R1).

```markdown
**13.c · Source-literal carve-out scan.** [Phase-7 R-DH-P7-01
— closes L-DH-01 magic-string allowlist gap. Anchor:
`detector-review/FINAL-CERTIFICATION.md` §3 L-DH-01.]

For every spec-named guard hook in axis-1 extracted_set, the
auditor MUST scan the hook's source for early-exit branches
(`exit 0`, `return 0`) conditioned on string-literal matches.

**Scan-pattern set (BF-1 widened — 7 families MUST be checked):**

1. `[[ "$X" == *"<literal>"* ]] && exit 0` — bash glob substring
2. `[[ "$X" == "<literal>" ]] && exit 0` — bash exact-equal
3. `[ "$X" = "<literal>" ] && exit 0` — POSIX exact-equal
4. `case "$X" in *"<literal>"*) exit 0 ;; esac` — case glob
5. `grep -Fq -- "<literal>"` (in `if`/`&&`/`||` chains; in any
   pipe direction including `printf '%s' "$X" | grep -Fq`)
6. `echo "$X" | grep -q "<literal>"` — echo-pipe-grep
7. `<function_name> "$X"` (function-call delegation) where the
   called function definition is searched recursively for
   patterns 1-6

For each guard, run all 7 pattern families against the source.
Extract every `<literal>` string found across all matches.

**Exemption set (BF-2 widened — 5 sources of legitimate carve-outs):**

A literal is exempt (PASS-by-contract; no finding) if found in:

1. `framework/HOOK-CLASSIFICATION.md`
2. `apex-spec.md`
3. `audit-trail-review/FIX-DESIGN-C-R4.md` (Campaign C TP-C2
   audit-probe-marker)
4. `framework/test-fixtures/security-patterns.json`
   `audit_probe_marker.literal` or `prompt_injection_patterns[]`
5. Inline-comment-block exemption: the literal is preceded
   within 5 source lines by a comment matching one of:
   `# Campaign [A-C] TP-`, `# IMP-\d+`, `# spec anchor`,
   `# audit-probe`, `# Mythos §`. (Auditor reads 5 lines above
   the match and greps for the regex.)

A literal NOT in the exemption set → emit P0 finding:

- **Title:** `<guard> has undocumented source-literal carve-out: "<literal>"`
- **Cite:** the guard file path + line number + the literal text
- **Evidence:** the source-line text verbatim + the bypass
  payload constructed
- **Defect class:** magic-string allowlist (Class B)

**Probe-construction requirement:** for each undocumented
extracted literal, construct >= 1 close-but-not-identical payload
(e.g., for literal `--apex-maintenance-token=ok`, probe
`--apex-maintenance-token=okx` AND `--Apex-Maintenance-Token=ok`
AND `--apex-maintenance-token=ok ` — three boundary variants),
invoke the guard against each, record exit codes. Exit-0 bypass
confirms the carve-out is exploitable.

**Recording shape:**
`coverage_map.axis_13.source_literal_carveouts[]` with
`(guard, literal, line, exempt_via, probe_payloads[],
probe_exits[])` where `exempt_via` is the source name from the
exemption set OR `"undocumented"`.

**Minimum scan set:** every guard in axis-1 extracted_set whose
contract is regex-deny or pattern-deny. A coverage_map row with
`axis_13.source_literal_carveouts.length == 0` for the extracted_set
is an incomplete audit.
```

### Change B (unchanged) — round-checker.md clause (ix)

Same as R1.

### Change C (REVISED per BF-3) — Layer tests + fixture coherence contract

**Fixture coherence contract (BF-3):** every H-F-N fixture's
`axis_10` block + `axis_13.runtime_contract_probes[]` block MUST
match the H-E-3.jsonl baseline EXACTLY (use it as the
copy-and-extend template). Required minimum content:

1. `axis_10.concrete_bypass_attempts[]` MUST include:
   - path-guard.sh canonical + boundary variant (2 entries)
   - prompt-guard.sh ≥ 3 case variants + ≥ 3 role variants (6 entries)
   - _state-update.sh with `stderr_nonempty: true` AND `stderr_contains: "jq"`
   - session-log.sh with `stderr_nonempty: true`
   - test-runner-counter
2. `axis_13.runtime_contract_probes[]` MUST include at least one
   non-discrepant entry for destructive-guard.sh
3. NEW axis_13.source_literal_carveouts[] block — the variant per
   test scenario (H-F1 empty array; H-F2 entry with exit-0 bypass
   + undocumented + no finding; H-F3 clean entries)

**Simulator-extension append-point (BF-3):** insert new clause
(ix) logic in `round_checker_sim()` BETWEEN the closing brace of
clause (viii)'s discrepant_guards loop (line ~637 of
test-audit-trail-layer.sh) AND the final `echo "PASS"` (line ~639).

Pseudo-code for clause (ix):

```bash
# Clause (ix) — Source-literal carve-out scan (R-DH-P7-01).
# Settings-wired regex-deny subset for layer-test purposes:
local regex_deny_guards="destructive-guard.sh path-guard.sh"
for g in $regex_deny_guards; do
  local has_scan_entry
  has_scan_entry=$(jq_clean -r --arg g "$g" '
    .axis_13.source_literal_carveouts[]?
    | select((.guard // "" | ascii_downcase) == ($g | ascii_downcase))
    | "ok"
  ' "$transcript" 2>/dev/null | head -1)
  if [ "$has_scan_entry" != "ok" ]; then
    echo "axis_13_source_literal_scan_blind_spot"
    return
  fi
done
# Per-entry: exit-0 bypass + undocumented + no finding → unreported
local unreported_guards
unreported_guards=$(jq_clean -r '
  .axis_13.source_literal_carveouts[]?
  | select((.exempt_via // "") == "undocumented")
  | select(any(.probe_exits[]?; . == 0))
  | .guard
' "$transcript" 2>/dev/null | sort -u)
if [ -n "$unreported_guards" ]; then
  while IFS= read -r ug; do
    [ -z "$ug" ] && continue
    local cite_match
    cite_match=$(jq_clean -r --arg g "$ug" '
      .findings[]? | .cite[]? | select(. == $g) | "ok"
    ' "$transcript" 2>/dev/null | head -1)
    if [ "$cite_match" != "ok" ]; then
      echo "axis_13_source_literal_bypass_unreported"
      return
    fi
  done <<< "$unreported_guards"
fi
```

H-F1..H-F3 test rows:

| H-ID | Fixture content | Expected verdict |
|------|-----------------|------------------|
| H-F1 | `axis_13.source_literal_carveouts[]` empty for required regex-deny guards | P1 `axis_13_source_literal_scan_blind_spot` |
| H-F2 | entry with `exempt_via:"undocumented"` + `probe_exits[0]==0` + no finding citing the guard | P0 `axis_13_source_literal_bypass_unreported` |
| H-F3 | clean entries (either empty probe_payloads[] or all `exempt_via != "undocumented"` or no exit-0 bypass) | PASS |

---

## §5. G5 PASS criteria (REVISED)

Same as R1 + new criteria reflecting BF closures:
7. ✅ Scan-pattern set (7 families) present in axis-13.c body.
8. ✅ Exemption set (5 sources including audit-probe-marker carve-out) present.
9. ✅ Simulator clause (ix) inserts at the documented append point.

---

## §6-§8 unchanged from R1.

---

## §9. Decision summary (R2)

**R1:** FAIL (3 BFs — scan coverage, exemption coverage, fixture spec).
**R2:** widens scan to 7 patterns; expands exemption to 5 sources (including audit-probe carve-out); adds explicit fixture coherence contract + simulator append-point pseudo-code.

**Blast radius:** unchanged from R1 (7 files).

**Next gate:** G2 critic R2 verification.
