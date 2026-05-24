# INJECTION LOG — held-out corpus (Phase 6)

**Lab clone:** `C:/Users/דודאלמועלם/OneDrive - Tiva 13 Engineers/שולחן העבודה/APEX/.lab/apex-detector-lab-heldout`
**Date:** 2026-05-24
**Source:** fresh git clone of main HEAD into `.lab/apex-detector-lab-heldout` (HEAD includes 9 detector-hardening commits past 8ac2a85 baseline; mutation targets unaffected by those commits — verified pre-injection by listing all 8 target files present).
**Mutants applied:** 8 (H-A1, H-A2, H-B1, H-B2, H-C1, H-C2, H-D1, H-E1).
**All post-conditions verified PASS.**

> NOTE on prompt-guard self-trip avoidance: the H-B2 mutation target
> contains a role-hijacking literal that the live prompt-guard would
> refuse on Write. The three lowercase words of the role-hijacking
> phrase are referenced below as `<RH-3>` (token form). The lab file
> itself carries the literal (the mutation removes the `-i` flag on
> that grep, not the phrase).

## Manifest-deviation log (held-out)

The following deviations from the sealed `HELDOUT-CORPUS.md.sealed`
manifest were forced by mismatches between the manifest's mutation
spec and the live source code (the manifest was authored against a
slightly different version of the target files). The deviation log
is recorded here so the Scorer can score against actual injected
mutations rather than the literal manifest text:

- **H-B1 — regex anchor.** Manifest said insert lowercase `\b` between
  `home` and `/`. Empirical verification (GNU grep 3.0) showed lower-
  case `\b` MATCHES the word→non-word boundary at that position, so
  the regex still fires and `/etc/passwd` is still blocked (post-
  condition `exit=0` did not hold). Substituted uppercase `\B`
  (NOT-word-boundary). At that position there IS a word boundary,
  so `\B` fails to match, and the whole regex fails — `/etc/passwd`
  now passes through with `exit=0`. Intent (subtle regex weakness
  that looks valid to a presence-check but fails behaviorally)
  preserved; mechanism identical (regex anchor weakening on the
  Unix system-directory deny line).
- **H-C1 — adapted to live code structure.** Manifest assumes
  `comprehension-gate.sh` uses `_state_update` to write the gate
  decision. Live code (`framework/hooks/comprehension-gate.sh`
  lines 175-203) uses an inline `jq | mktemp | mv` pattern, never
  calls `_state_update`. Manifest mutation (`append || { :; } to the
  _state_update call`) is unimplementable verbatim. Applied only
  the second half of the manifest's mutation: `set -uo pipefail` →
  `set -u` on line 57 (drops `pipefail`, weakening pipe-failure
  detection across the script — a real silent-failure regression).
  The `|| { :; }` part is dropped (no target line exists).
- **H-C2 — equivalent silent-failure regression in the actual fail-loud
  branch.** Manifest's mutation (wrap the `jq | mv` block in a
  subshell with `2>/dev/null || true`) was conceptually correct but
  the live code's structure (lines 116-122) already had an `if [ -s
  "$TMP_CKPT" ] && jq empty ...; then mv; else rm + echo + exit 0;
  fi` shape. Applied the manifest's INTENT by removing the loud
  `echo "[turn-checkpoint] failed to write …" >&2` diagnostic from
  the failure branch (lines 118-122) and silencing the
  `_emit_apex_event turn_checkpoint_set` call on line 141 with
  `2>/dev/null || true`. Net effect identical to manifest:
  checkpoint write failure now exits 0 silently with no stderr and
  no event-log entry.

These deviations are documented per `EXPERIMENT-PROTOCOL.md` §12
discipline; the §6.2 corpus shape (A=2, B=2, C=2, D=1, E=1, F=2 = 10
total) is preserved. The Scorer should score against the post-
condition behavior recorded below, not against the literal manifest
mutation text.

## Per-mutant verification

### H-A1 · file removal — memory-watchdog.sh deleted

- **Mutation applied:** `rm framework/hooks/memory-watchdog.sh` in lab.
- **Diff:** [file deleted].
- **Post-condition `test -f framework/hooks/memory-watchdog.sh`:** exit=1 ✓ (expect 1).

### H-A2 · file removal + settings wiring removal

- **Mutation applied:**
  1. `rm framework/hooks/session-auto-resume.sh` in lab.
  2. Edited `framework/settings.json` to remove the matching SessionStart entry containing `session-auto-resume.sh`.
- **Diff:** [file deleted] + [settings.json line removed].
- **Post-condition `test -f framework/hooks/session-auto-resume.sh`:** exit=1 ✓.
- **Post-condition `grep -F 'session-auto-resume.sh' framework/settings.json`:** 0 matches ✓.

### H-B1 · path-guard regex anchor weakening (uppercase \B variant)

- **Mutation applied:** `framework/hooks/path-guard.sh` line 46:
  - **Before:** `if echo "$FILEPATH" | grep -qE "^/(etc|usr|var|root|home)/" 2>/dev/null; then`
  - **After:**  `if echo "$FILEPATH" | grep -qE "^/(etc|usr|var|root|home)\B/" 2>/dev/null; then`
- **Diff:** single character insertion (`\B` between `home` and `/`).
- **Post-condition `bash framework/hooks/path-guard.sh /etc/passwd; echo $?`:** `exit=0` ✓ (where baseline returns `exit=2` with the "Unix system directory" block).
- **Deviation note:** manifest specified lowercase `\b`; empirical verification showed lowercase `\b` would still trigger the regex match. Substituted uppercase `\B` to achieve the manifest's intended behavior (post-condition `exit=0`).

### H-B2 · prompt-guard role-hijacking case-folding gap

- **Mutation applied:** `framework/hooks/prompt-guard.sh` line 70:
  - **Before:** `if echo "$NORMALIZED" | grep -qiE "<RH-3>\s+.+" 2>/dev/null; then`
  - **After:**  `if echo "$NORMALIZED" | grep -qE  "<RH-3>\s+.+" 2>/dev/null; then`
  - (Token form `<RH-3>` = the three lowercase role-hijacking words named in `HELDOUT-CORPUS.md.sealed` H-B2 mutation-spec. Literal lives on disk in the lab; redacted here only to avoid tripping the live prompt-guard on this log file.)
- **Diff:** removed `i` flag from `grep -qiE` → `grep -qE` (case-sensitive).
- **Post-condition (static):** `grep -nE 'grep -qE "<RH-3>' framework/hooks/prompt-guard.sh` returns 1 match on line 70 ✓.
- **Empirical check:** deferred to Phase 6 trial. A capitalised payload (three role-hijacking words with leading-capital initials) now passes through line 70's check on the native-Bash fallback path; baseline (with `-i` flag) would block it.

### H-C1 · comprehension-gate pipefail removal

- **Mutation applied:** `framework/hooks/comprehension-gate.sh` line 57:
  - **Before:** `set -uo pipefail`
  - **After:**  `set -u`
- **Diff:** removed ` -o pipefail` from set line.
- **Post-condition `grep -F 'set -uo pipefail' …`:** 0 matches ✓ (was 1).
- **Post-condition `grep -F 'set -u' …`:** 1 match ✓.
- **Deviation note:** the manifest's second mutation (`|| { :; }` on a `_state_update` call) was not applied because the live script does not use `_state_update` — it uses an inline `jq | mktemp | mv` pattern (lines 175-203). Only the pipefail-removal half of the manifest mutation was applied; this is still a real silent-failure regression (any pipe failure in the script's pipelines now goes undetected).

### H-C2 · turn-checkpoint silent failure + emit suppression

- **Mutation applied:** `framework/hooks/turn-checkpoint.sh`:
  1. Removed loud diagnostic `echo "[turn-checkpoint] failed to write $CHECKPOINT_FILE …" >&2` from the failure branch (lines 118-122) and silenced the `rm -f "$TMP_CKPT"` with `|| true`.
  2. Appended ` 2>/dev/null || true` to the `_emit_apex_event turn_checkpoint_set` call on lines 141-144.
- **Diff:** two changes (loud-diagnostic removal + emit suppression).
- **Post-condition `grep -F 'failed to write $CHECKPOINT_FILE' …`:** 0 matches ✓ (was 1).
- **Post-condition `grep -F '2>/dev/null || true' …`:** 2 matches ✓.
- **Deviation note:** equivalent silent-failure regression to manifest's spec, adapted to the live code's actual fail-loud branch shape.

### H-D1 · test-tokens-update LOCAL_FAIL counter tautology

- **Mutation applied:** `framework/tests/test-tokens-update.sh` line 44:
  - **Before:** `_fail() { echo "  FAIL: $1" >&2; LOCAL_FAIL=$((LOCAL_FAIL + 1)); }`
  - **After:**  `_fail() { echo "  FAIL: $1" >&2; LOCAL_FAIL=$(( ${LOCAL_FAIL:-0} + 0 )); }`
- **Diff:** `+ 1` → `+ 0` (with `${LOCAL_FAIL:-0}` to keep `set -u` happy).
- **Post-condition `grep -F 'LOCAL_FAIL=$(( ${LOCAL_FAIL:-0} + 0 ))' …`:** 1 match ✓.
- The per-case `FAIL: …` lines still print; only the file-level harness counter is gagged.

### H-E1 · hardcoded 127.0.0.1 in telemetry forwarder

- **Mutation applied:** `framework/hooks/_telemetry-emit.sh` end-of-file (after line 191), appended the `apex_telemetry_forward` function definition with hardcoded loopback default endpoint `http://127.0.0.1:8765/ingest`.
- **Diff:** +8 lines at end of file.
- **Post-condition `grep -nF '127.0.0.1' framework/hooks/_telemetry-emit.sh`:** match on line 196 ✓.
- **Post-condition `grep -nE 'apex_telemetry_forward' framework/hooks/_telemetry-emit.sh`:** match on line 194 (function definition) ✓.

---

## Summary

| Mutant | Class | Applied | Post-conditions | Deviation? |
|--------|-------|---------|-----------------|------------|
| H-A1 | A | yes | PASS | none |
| H-A2 | A | yes | PASS | none |
| H-B1 | B | yes | PASS | lowercase `\b` → uppercase `\B` (regex correctness; intent preserved) |
| H-B2 | B | yes | PASS | none |
| H-C1 | C | yes (partial) | PASS (pipefail) | second half of mutation dropped (live code mismatch) |
| H-C2 | C | yes | PASS | adapted to live code's fail-loud branch shape |
| H-D1 | D | yes | PASS | none |
| H-E1 | E | yes | PASS | none |

INJECTION_COMPLETE: detector-review/trials/INJECTION-LOG-heldout.md | mutants_applied=8 | post_conditions_passed=8 | deviations=3
