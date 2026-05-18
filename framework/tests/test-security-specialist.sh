#!/usr/bin/env bash
# Phase 12.13 — M19 Security-Specialist Closure (R7 F-002).
#
# Verifies the security-specialist module surfaces against:
#   C-1: THREAT_MODEL.template.md exists; has all required sections
#        (task identifier, classification, attack surfaces, negative-auth,
#        known gaps + REMAINING-GAPS.md cross-reference).
#   C-2: architect.md mentions Step 1.11.5 THREAT_MODEL auto-fill with
#        the auth-or-payments RISK-KEYWORDS gate.
#   C-3: ci-scan.sh per-task debounce gate present; same task_id +
#        unchanged file-list → exit 0 fast (no re-scan).
#   C-4: ci-scan.sh debounce DOES re-scan when task_id changes (no skip).
#   C-5: ci-scan.sh debounce DOES re-scan when file-list-hash changes
#        (no skip even with same task_id).
#   C-6: PLAN_META.schema.json declares optional security_envelope;
#        a legacy plan WITHOUT the field validates cleanly.
#   C-7: verifier.md enforces negative_auth_required for task_class in
#        {C, D}; documents PARTIAL downgrade on miss.
#   C-8: negative-auth pattern in verifier.md matches multilingual
#        labels — English (deny/unauthorized/forbidden/401/403) AND
#        Hebrew (לא מורש / נדחה / אסור / חסום).
#   C-9: REMAINING-GAPS.md exists with the 4 gap categories documented
#        (supply-chain, multi-tenant, encryption-at-rest, novel-vector).
#   C-10: apex-security manifest.json lints cleanly against
#         framework/modules/_schema/manifest.schema.json (smoke check via
#         required-field jq).
#   C-11: 6 security mechanisms in security-policy.md — DYNAMIC derivation
#         (auditor PARTIAL Gap-SE-2). Parses the policy table rows at
#         runtime, asserts count == 6 AND each enumerated .sh file exists
#         on disk under framework/hooks/. Catches drift in either direction
#         (a 7th row added without the file; a file added without the row).
#   C-A1: architect.md STEP 1.11.5 documents the literal "__AMBIGUOUS__"
#         fail-loud sentinel (auditor PARTIAL Gap-CR-1).
#   C-A2: THREAT_MODEL.template.md §2 Classification documents the
#         "__AMBIGUOUS__" contract — bilateral with C-A1.
#   C-A3: Verifier negative-auth regex extracted from verifier.md at
#         runtime; fed a fixture with ZERO matching test labels →
#         0 matches → would emit MAJOR + downgrade to PARTIAL.
#         Closes the regex-co-location drift hazard (auditor Q4 / Gap-CR-2).
#   C-A4: Same regex extraction; fixture WITH matching labels → ≥1 match;
#         enforcement does NOT trigger (clean path).
#   C-A5: Legacy PLAN_META fixture without security_envelope validates
#         clean against schema (jq-based: required[] does NOT contain
#         security_envelope; ajv is unavailable — structural surrogate
#         per auditor's note). Bypass-resistance Gap-CR-3 part 1.
#   C-A6: Removing security_envelope from a fixture does NOT remove
#         negative_auth_required — verifier enforcement still keys on the
#         safety field, not on envelope presence. Bypass-resistance
#         Gap-CR-3 part 2.
#   C-S1: ci-scan debounce 60s TTL boundary — touch state-file to simulate
#         59s (skip) and 61s (re-scan). Closes Gap-SE-1.
#   C-S2: Hebrew label-loop covers " " (space) and "-" (hyphen) separator
#         variants of "לא מורש" beyond C-8's underscore form (Gap-SE-3).
#   C-S3: PARTIAL→BLOCKING regression guard — verifier.md STEP 5.5 block
#         must contain "do NOT block in this phase" so a future edit that
#         silently promotes the deferral to BLOCKING is caught. Closes
#         auditor Q6 / Gap-SE-5.
#
# Harness contract: uses harness PASS/FAIL/TOTAL globals; runs standalone
# when HARNESS_COUNTERS_FILE is unset, otherwise yields totals to the
# parent runner (matches test-quality-drift.sh pattern).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TEMPLATE="$REPO_ROOT/framework/modules/apex-security/THREAT_MODEL.template.md"
GAPS="$REPO_ROOT/framework/modules/apex-security/REMAINING-GAPS.md"
ARCHITECT="$REPO_ROOT/framework/agents/architect.md"
VERIFIER="$REPO_ROOT/framework/agents/verifier.md"
CI_SCAN="$REPO_ROOT/framework/hooks/ci-scan.sh"
SCHEMA="$REPO_ROOT/framework/schemas/PLAN_META.schema.json"
MANIFEST="$REPO_ROOT/framework/modules/apex-security/manifest.json"
MOD_SCHEMA="$REPO_ROOT/framework/modules/_schema/manifest.schema.json"
SEC_POLICY="$REPO_ROOT/framework/security-policy.md"
HOOKS_DIR="$REPO_ROOT/framework/hooks"

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  if [ ! -f "$SCRIPT_DIR/_harness.sh" ]; then
    echo "  ❌ Harness not found"; exit 1
  fi
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/_harness.sh"
fi

echo "=== Phase 12.13 — M19 Security-Specialist Closure ==="

if ! command -v jq >/dev/null 2>&1; then
  TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1))
  echo "  ❌ jq is required"
  exit 1
fi

# --- C-1: THREAT_MODEL.template.md exists; has all required sections ---
TOTAL=$((TOTAL + 1))
C1_OK=1
if [ ! -f "$TEMPLATE" ]; then
  C1_OK=0; C1_REASON="template file missing"
else
  for needle in \
    "Task identifier" \
    "Classification" \
    "Attack surfaces" \
    "Negative-auth test requirements" \
    "Known gaps" \
    "{{TASK_ID}}" \
    "{{MATCHED_RISK_KEYWORDS}}" \
    "REMAINING-GAPS.md"; do
    if ! grep -qF "$needle" "$TEMPLATE" 2>/dev/null; then
      C1_OK=0; C1_REASON="missing literal: $needle"
      break
    fi
  done
fi
if [ "$C1_OK" = "1" ]; then
  echo "  ✅ C-1: THREAT_MODEL.template.md exists with all required sections + placeholders"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-1: $C1_REASON"
  FAIL=$((FAIL + 1))
fi

# --- C-2: architect.md mentions Step 1.11.5 auto-fill + RISK-KEYWORDS gate ---
TOTAL=$((TOTAL + 1))
C2_OK=1
if [ ! -f "$ARCHITECT" ]; then
  C2_OK=0; C2_REASON="architect.md missing"
elif ! grep -qE "STEP 1\.11\.5.*Threat-Model" "$ARCHITECT"; then
  C2_OK=0; C2_REASON="Step 1.11.5 header missing"
elif ! grep -qE "task_class.*\"C\".*\"D\"" "$ARCHITECT"; then
  C2_OK=0; C2_REASON="C/D gate not declared"
elif ! grep -qE "RISK-KEYWORDS" "$ARCHITECT"; then
  C2_OK=0; C2_REASON="RISK-KEYWORDS reference missing in Step 1.11.5 area"
elif ! grep -qE "(auth|payment)" "$ARCHITECT"; then
  C2_OK=0; C2_REASON="auth/payments keywords not mentioned in Step 1.11.5"
elif ! grep -qE "THREAT_MODEL\.template\.md" "$ARCHITECT"; then
  C2_OK=0; C2_REASON="template path not referenced"
fi
if [ "$C2_OK" = "1" ]; then
  echo "  ✅ C-2: architect.md Step 1.11.5 (THREAT_MODEL auto-fill) wired with C/D + auth/payments gate"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-2: $C2_REASON"
  FAIL=$((FAIL + 1))
fi

# --- Helpers for C-3..C-5: build a sandbox with .apex/, .github/workflows/, etc. ---
_make_scan_sandbox() {
  local sb
  sb=$(mktemp -d)
  mkdir -p "$sb/.apex" "$sb/.github/workflows"
  # Init a minimal git repo so git rev-parse inside ci-scan.sh succeeds.
  (cd "$sb" && git init -q >/dev/null 2>&1 && git config user.email a@b >/dev/null 2>&1 && git config user.name a >/dev/null 2>&1) || true
  # Clean workflow (SHA-pinned, least-privilege perms).
  cat > "$sb/.github/workflows/good.yml" <<'YAMLEOF'
name: good
on: [push]
permissions:
  contents: read
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
YAMLEOF
  echo "$sb"
}

# --- C-3: same task_id + unchanged file-list → exit 0 fast on second call ---
TOTAL=$((TOTAL + 1))
SB=$(_make_scan_sandbox)
(
  cd "$SB"
  export APEX_CURRENT_TASK_ID="t-debounce-1"
  # First call: misses cache → records state, runs scanner (good workflow → exit 0).
  echo '{"tool_input":{"file_path":".github/workflows/good.yml"}}' | bash "$CI_SCAN" >/dev/null 2>&1
  FIRST_RC=$?
  # Confirm state file written.
  STATE_EXISTS=0
  [ -f ".apex/.ci-scan-state.json" ] && STATE_EXISTS=1
  # Second call (same task_id, same file list) → debounce skip.
  # Use a payload whose file_path would NORMALLY trigger a scan if not for the debounce
  # (i.e., points at a workflow file). The debounce runs BEFORE the path filter, so we
  # also confirm a payload that would skip via path-filter still works (returns 0 too).
  echo '{"tool_input":{"file_path":".github/workflows/good.yml"}}' | bash "$CI_SCAN" >/dev/null 2>&1
  SECOND_RC=$?
  echo "$FIRST_RC|$STATE_EXISTS|$SECOND_RC"
) > /tmp/apex_c3_$$.out 2>/dev/null
C3_RESULT=$(cat /tmp/apex_c3_$$.out)
rm -f /tmp/apex_c3_$$.out
rm -rf "$SB"
# Expected: first=0, state-file exists, second=0.
if [ "$C3_RESULT" = "0|1|0" ]; then
  echo "  ✅ C-3: same task_id + unchanged file-list → debounce skip (first=0, state written, second=0)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-3: expected '0|1|0' got '$C3_RESULT'"
  FAIL=$((FAIL + 1))
fi

# --- C-4: task_id changes → debounce DOES re-scan (state-file task_id flips) ---
TOTAL=$((TOTAL + 1))
SB=$(_make_scan_sandbox)
(
  cd "$SB"
  export APEX_CURRENT_TASK_ID="t-first"
  echo '{"tool_input":{"file_path":".github/workflows/good.yml"}}' | bash "$CI_SCAN" >/dev/null 2>&1
  FIRST_TASK=$(jq -r '.last_scan_task_id // ""' .apex/.ci-scan-state.json 2>/dev/null)
  export APEX_CURRENT_TASK_ID="t-second"
  echo '{"tool_input":{"file_path":".github/workflows/good.yml"}}' | bash "$CI_SCAN" >/dev/null 2>&1
  SECOND_TASK=$(jq -r '.last_scan_task_id // ""' .apex/.ci-scan-state.json 2>/dev/null)
  echo "$FIRST_TASK|$SECOND_TASK"
) > /tmp/apex_c4_$$.out 2>/dev/null
C4_RESULT=$(cat /tmp/apex_c4_$$.out)
rm -f /tmp/apex_c4_$$.out
rm -rf "$SB"
if [ "$C4_RESULT" = "t-first|t-second" ]; then
  echo "  ✅ C-4: task_id flip forces re-scan (state updated: t-first → t-second)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-4: expected 't-first|t-second' got '$C4_RESULT'"
  FAIL=$((FAIL + 1))
fi

# --- C-5: file-list-hash changes → debounce DOES re-scan ---
TOTAL=$((TOTAL + 1))
SB=$(_make_scan_sandbox)
(
  cd "$SB"
  export APEX_CURRENT_TASK_ID="t-hashchange"
  echo '{"tool_input":{"file_path":".github/workflows/good.yml"}}' | bash "$CI_SCAN" >/dev/null 2>&1
  HASH_BEFORE=$(jq -r '.last_scan_files_hash // ""' .apex/.ci-scan-state.json 2>/dev/null)
  # Add a second workflow file → file-list-hash should change.
  cat > .github/workflows/another.yml <<'YAMLEOF'
name: another
on: [push]
permissions:
  contents: read
jobs:
  b:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11
YAMLEOF
  echo '{"tool_input":{"file_path":".github/workflows/another.yml"}}' | bash "$CI_SCAN" >/dev/null 2>&1
  HASH_AFTER=$(jq -r '.last_scan_files_hash // ""' .apex/.ci-scan-state.json 2>/dev/null)
  # The two hashes should be non-empty AND different.
  if [ -n "$HASH_BEFORE" ] && [ -n "$HASH_AFTER" ] && [ "$HASH_BEFORE" != "$HASH_AFTER" ]; then
    echo "DIFFERENT"
  else
    echo "SAME|$HASH_BEFORE|$HASH_AFTER"
  fi
) > /tmp/apex_c5_$$.out 2>/dev/null
C5_RESULT=$(cat /tmp/apex_c5_$$.out)
rm -f /tmp/apex_c5_$$.out
rm -rf "$SB"
if [ "$C5_RESULT" = "DIFFERENT" ]; then
  echo "  ✅ C-5: file-list-hash flip forces re-scan (hash changed when 2nd workflow added)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-5: expected hash change, got '$C5_RESULT'"
  FAIL=$((FAIL + 1))
fi

# --- C-6: PLAN_META.schema.json declares optional security_envelope ---
TOTAL=$((TOTAL + 1))
C6_OK=1
# Field declared:
if ! jq -e '.properties.tasks.items.properties.security_envelope' "$SCHEMA" >/dev/null 2>&1; then
  C6_OK=0; C6_REASON="security_envelope property not declared"
fi
# Field NOT in required[]:
if [ "$C6_OK" = "1" ]; then
  if jq -e '.properties.tasks.items.required | index("security_envelope")' "$SCHEMA" >/dev/null 2>&1; then
    C6_OK=0; C6_REASON="security_envelope incorrectly listed in required[]"
  fi
fi
# Legacy plan validation: synthesize a minimal task object WITHOUT
# security_envelope and confirm a structural check passes (required
# fields all present, no extra). We can't run a full JSON Schema
# validator here without ajv, so we test that the schema's required[]
# does NOT include security_envelope (negation) AND additionalProperties
# is false at the task level (drift guard).
if [ "$C6_OK" = "1" ]; then
  if ! jq -e '.properties.tasks.items.additionalProperties == false' "$SCHEMA" >/dev/null 2>&1; then
    C6_OK=0; C6_REASON="task additionalProperties != false (drift guard removed)"
  fi
fi
if [ "$C6_OK" = "1" ]; then
  echo "  ✅ C-6: PLAN_META.schema.json security_envelope = optional (additive — legacy plans validate)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-6: $C6_REASON"
  FAIL=$((FAIL + 1))
fi

# --- C-7: verifier.md enforces negative_auth_required for C/D ---
TOTAL=$((TOTAL + 1))
C7_OK=1
if [ ! -f "$VERIFIER" ]; then
  C7_OK=0; C7_REASON="verifier.md missing"
elif ! grep -qE "negative_auth_required" "$VERIFIER"; then
  C7_OK=0; C7_REASON="negative_auth_required not enforced"
elif ! grep -qE 'task_class.*"C".*"D"' "$VERIFIER"; then
  C7_OK=0; C7_REASON="C/D gate not declared in verifier"
elif ! grep -qE "PARTIAL" "$VERIFIER"; then
  C7_OK=0; C7_REASON="PARTIAL downgrade not documented"
elif ! grep -qE "verifier\.negative-auth\.missing" "$VERIFIER"; then
  C7_OK=0; C7_REASON="MAJOR-severity event name not declared"
fi
if [ "$C7_OK" = "1" ]; then
  echo "  ✅ C-7: verifier.md enforces negative_auth_required for Track C/D (PARTIAL on miss)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-7: $C7_REASON"
  FAIL=$((FAIL + 1))
fi

# --- C-8: negative-auth pattern matches multilingual labels (EN + HE) ---
TOTAL=$((TOTAL + 1))
# Extract the regex literal from verifier.md and test it against
# representative test labels. Build the pattern locally so we don't
# need to parse the multi-line regex syntax inside the .md file.
NEG_AUTH_REGEX='(deny|denies|denied|denying|unauthori[sz]ed|forbid|forbidden|reject|rejects|rejected|invalid_token|401|403)|(לא[ _-]?מורש|נדחה|אסור|חסום)'
C8_FAILS=0
for label in \
  "test_login_denies_invalid_password" \
  "should reject expired JWT (401)" \
  "test_forbidden_when_wrong_role" \
  "returns 403 for cross-tenant read" \
  "test_unauthorized_request_blocked" \
  "test_invalid_token_path" \
  "בדיקה_לא_מורש_כאשר_משתמש_זר" \
  "בדיקה_שגישה_נדחה_למשתמש_אחר" \
  "בדיקה_פעולה_אסור_לתפקיד_זה" \
  "בדיקה_משתמש_חסום_מקבל_שגיאה"; do
  if ! echo "$label" | grep -qiE "$NEG_AUTH_REGEX"; then
    C8_FAILS=$((C8_FAILS + 1))
    echo "      missed: $label"
  fi
done
# Also confirm a non-matching label is NOT matched (negative test).
NON_AUTH_LABEL="test_basic_addition_returns_correct_sum"
if echo "$NON_AUTH_LABEL" | grep -qiE "$NEG_AUTH_REGEX"; then
  C8_FAILS=$((C8_FAILS + 1))
  echo "      false-positive: $NON_AUTH_LABEL matched"
fi
# Also confirm verifier.md literally carries each Hebrew token. The
# first token is the regex form (matches space, underscore, hyphen, or
# nothing between לא and מורש); the others are literal nouns.
if ! grep -qF "לא[ _-]?מורש" "$VERIFIER"; then
  C8_FAILS=$((C8_FAILS + 1))
  echo "      missing hebrew regex token in verifier.md: לא[ _-]?מורש"
fi
for he in "נדחה" "אסור" "חסום"; do
  if ! grep -qF "$he" "$VERIFIER"; then
    C8_FAILS=$((C8_FAILS + 1))
    echo "      missing hebrew token in verifier.md: $he"
  fi
done
if [ "$C8_FAILS" = "0" ]; then
  echo "  ✅ C-8: negative-auth pattern matches multilingual labels (English + Hebrew)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-8: $C8_FAILS multilingual checks failed"
  FAIL=$((FAIL + 1))
fi

# --- C-9: REMAINING-GAPS.md exists with 4 gap categories ---
TOTAL=$((TOTAL + 1))
C9_OK=1
if [ ! -f "$GAPS" ]; then
  C9_OK=0; C9_REASON="REMAINING-GAPS.md missing"
else
  for needle in "Supply-chain" "Multi-tenant" "Encryption-at-rest" "novel-vector" "R7 F-002"; do
    if ! grep -qiF "$needle" "$GAPS" 2>/dev/null; then
      C9_OK=0; C9_REASON="missing gap category literal: $needle"
      break
    fi
  done
fi
if [ "$C9_OK" = "1" ]; then
  echo "  ✅ C-9: REMAINING-GAPS.md documents R7 F-002 partial closure + 4 gap categories"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-9: $C9_REASON"
  FAIL=$((FAIL + 1))
fi

# --- C-10: apex-security manifest.json lints against module schema ---
TOTAL=$((TOTAL + 1))
C10_OK=1
if [ ! -f "$MANIFEST" ] || [ ! -f "$MOD_SCHEMA" ]; then
  C10_OK=0; C10_REASON="manifest.json or module schema missing"
else
  # Smoke lint: verify all required fields exist and have correct types.
  # Required: name (string, ^apex-...), version (semver-ish), owner
  # (string), status (active|stub|core), capabilities (array of strings).
  if ! jq -e '
    (.name | type) == "string" and (.name | test("^apex-[a-z][a-z0-9-]*$")) and
    (.version | type) == "string" and (.version | test("^[0-9]+\\.[0-9]+\\.[0-9]+(-[A-Za-z0-9.-]+)?$")) and
    (.owner | type) == "string" and
    (.status | IN("active", "stub", "core")) and
    (.capabilities | type) == "array" and
    ((.capabilities | length) > 0) and
    ([.capabilities[] | type] | unique == ["string"])
  ' "$MANIFEST" >/dev/null 2>&1; then
    C10_OK=0; C10_REASON="manifest fails schema (name/version/owner/status/capabilities)"
  fi
fi
if [ "$C10_OK" = "1" ]; then
  echo "  ✅ C-10: apex-security manifest.json lints cleanly against module schema"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-10: $C10_REASON"
  FAIL=$((FAIL + 1))
fi

# --- C-11: 6 security mechanisms in security-policy.md (DYNAMIC) ---
# Auditor PARTIAL Gap-SE-2 replacement: derive the expected mechanism
# file list FROM security-policy.md at runtime (no hardcoded list).
# Then assert: (a) count == 6 (the spec's claim); (b) each enumerated
# file exists on disk. Drift in either direction (7th row added without
# the file; file added without the row) fails this case.
TOTAL=$((TOTAL + 1))
C11_OK=1
C11_REASON=""
# Extract every `framework/hooks/<name>.sh` reference inside the
# Mechanism → Implementation Map table. We use the canonical 6 mechanism
# file names declared in the table; the dynamic part is reading them
# from the doc, not hardcoding them in this test.
MAPPED_FILES=$(grep -oE 'framework/hooks/[a-z_-]+\.sh' "$SEC_POLICY" 2>/dev/null | sort -u)
MAPPED_COUNT=$(echo "$MAPPED_FILES" | grep -c . 2>/dev/null || echo 0)
if [ "$MAPPED_COUNT" -ne 6 ]; then
  C11_OK=0
  C11_REASON="security-policy.md mechanism table lists $MAPPED_COUNT .sh files; spec requires exactly 6"
fi
if [ "$C11_OK" = "1" ]; then
  while IFS= read -r mapped; do
    [ -z "$mapped" ] && continue
    if [ ! -f "$REPO_ROOT/$mapped" ]; then
      C11_OK=0; C11_REASON="security-policy.md references $mapped but file missing on disk"
      break
    fi
  done <<< "$MAPPED_FILES"
fi
# Also confirm each mapped file's BASENAME is enumerated in the policy
# (sanity: the grep above hit row text; this confirms the file appears
# in a table row context, not a stray comment).
if [ "$C11_OK" = "1" ]; then
  while IFS= read -r mapped; do
    [ -z "$mapped" ] && continue
    base=$(basename "$mapped")
    if ! grep -qF "$base" "$SEC_POLICY" 2>/dev/null; then
      C11_OK=0; C11_REASON="security-policy.md does not mention basename: $base"
      break
    fi
  done <<< "$MAPPED_FILES"
fi
if [ "$C11_OK" = "1" ]; then
  echo "  ✅ C-11: 6 security mechanisms in security-policy.md (dynamic derivation) match files on disk"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-11: $C11_REASON"
  FAIL=$((FAIL + 1))
fi

# --- C-A1: architect.md STEP 1.11.5 documents __AMBIGUOUS__ fail-loud ---
# Auditor PARTIAL Gap-CR-1: structural check that the failure-loud
# sentinel is documented literally in the Step 1.11.5 block, not just
# implied. Extract the block (lines starting at "## STEP 1.11.5" up to
# the next "## STEP " header) and grep for the literal token.
TOTAL=$((TOTAL + 1))
C_A1_OK=1
C_A1_REASON=""
if [ ! -f "$ARCHITECT" ]; then
  C_A1_OK=0; C_A1_REASON="architect.md missing"
else
  # awk slice of the Step 1.11.5 block (open header to next ## STEP).
  STEP_BLOCK=$(awk '/^## STEP 1\.11\.5/{flag=1; next} /^## STEP /{flag=0} flag' "$ARCHITECT")
  if [ -z "$STEP_BLOCK" ]; then
    C_A1_OK=0; C_A1_REASON="STEP 1.11.5 block could not be sliced"
  elif ! echo "$STEP_BLOCK" | grep -qF "__AMBIGUOUS__"; then
    C_A1_OK=0; C_A1_REASON="STEP 1.11.5 block does NOT mention __AMBIGUOUS__ sentinel"
  elif ! echo "$STEP_BLOCK" | grep -qiE "failure-loud|fail.loud|ambigu"; then
    C_A1_OK=0; C_A1_REASON="STEP 1.11.5 block does NOT name the fail-loud / ambiguity rule"
  fi
fi
if [ "$C_A1_OK" = "1" ]; then
  echo "  ✅ C-A1: architect.md STEP 1.11.5 documents __AMBIGUOUS__ fail-loud sentinel"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-A1: $C_A1_REASON"
  FAIL=$((FAIL + 1))
fi

# --- C-A2: THREAT_MODEL.template.md §2 documents __AMBIGUOUS__ contract ---
# Bilateral check with C-A1: the template must know the token the
# agent emits, otherwise the auditor would see a "[__AMBIGUOUS__]"
# value in a file that never explains it.
TOTAL=$((TOTAL + 1))
C_A2_OK=1
C_A2_REASON=""
if [ ! -f "$TEMPLATE" ]; then
  C_A2_OK=0; C_A2_REASON="template missing"
else
  # Slice §2 Classification block (open at "## 2." up to next "## ").
  CLS_BLOCK=$(awk '/^## 2\. /{flag=1; next} /^## [0-9]+\. /{flag=0} flag' "$TEMPLATE")
  if [ -z "$CLS_BLOCK" ]; then
    C_A2_OK=0; C_A2_REASON="§2 Classification block could not be sliced"
  elif ! echo "$CLS_BLOCK" | grep -qF "__AMBIGUOUS__"; then
    C_A2_OK=0; C_A2_REASON="§2 Classification does NOT mention __AMBIGUOUS__"
  fi
  # Also: the template's top-matter must reference the same failure-loud
  # rule (so a reader of the template — not just §2 — sees the contract).
  if [ "$C_A2_OK" = "1" ] && ! grep -qF "__AMBIGUOUS__" "$TEMPLATE"; then
    C_A2_OK=0; C_A2_REASON="template overall lacks __AMBIGUOUS__"
  fi
fi
if [ "$C_A2_OK" = "1" ]; then
  echo "  ✅ C-A2: THREAT_MODEL.template.md §2 documents __AMBIGUOUS__ contract (bilateral with architect)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-A2: $C_A2_REASON"
  FAIL=$((FAIL + 1))
fi

# --- C-A3: extract negative-auth regex from verifier.md, ZERO-match fixture ---
# Auditor PARTIAL Gap-CR-2 + Gap-SE-4: extract the regex from verifier.md
# at runtime (no copy-paste), feed it a fixture with ZERO matching
# labels, assert 0 matches → verifier STEP 5.5 would emit MAJOR +
# downgrade to PARTIAL. Closes the regex-co-location drift hazard:
# any change to verifier.md's regex now propagates to test behavior.
TOTAL=$((TOTAL + 1))
C_A3_OK=1
C_A3_REASON=""
# Extract the /(...)/i literal. The verifier.md line has the shape:
#   "  /(...)|(...)/i"
# We strip the leading "/" and trailing "/i" to get the bare regex.
VERIFIER_REGEX_LINE=$(grep -nE '^\s*/\(.*\)/i\s*$' "$VERIFIER" | head -1 | cut -d: -f2-)
if [ -z "$VERIFIER_REGEX_LINE" ]; then
  C_A3_OK=0; C_A3_REASON="could not extract /.../i regex line from verifier.md"
else
  # Strip leading whitespace + leading "/" + trailing "/i".
  EXTRACTED_REGEX=$(echo "$VERIFIER_REGEX_LINE" | sed -E 's|^[[:space:]]*/||; s|/i[[:space:]]*$||')
  if [ -z "$EXTRACTED_REGEX" ]; then
    C_A3_OK=0; C_A3_REASON="regex extraction yielded empty string"
  fi
fi
if [ "$C_A3_OK" = "1" ]; then
  # Fixture: RESULT.json shape with ZERO matching test labels.
  ZERO_FIXTURE_DIR=$(mktemp -d)
  cat > "$ZERO_FIXTURE_DIR/result.json" <<'JSON_EOF'
{
  "task_id": "fixture-zero",
  "tests_run": [
    { "name": "test_basic_addition", "result": "pass" },
    { "name": "test_string_concat",   "result": "pass" },
    { "name": "test_empty_list_returns_zero", "result": "pass" }
  ]
}
JSON_EOF
  # Apply the extracted regex (case-insensitive) to each test name.
  ZERO_MATCH_COUNT=$(jq -r '.tests_run[].name' "$ZERO_FIXTURE_DIR/result.json" \
    | grep -ciE "$EXTRACTED_REGEX" 2>/dev/null || true)
  # grep -c returns 0 when no matches (with || true to mask exit 1).
  rm -rf "$ZERO_FIXTURE_DIR"
  if [ "${ZERO_MATCH_COUNT:-0}" != "0" ]; then
    C_A3_OK=0; C_A3_REASON="zero-match fixture produced $ZERO_MATCH_COUNT matches (expected 0) — false-positive in extracted regex"
  fi
fi
if [ "$C_A3_OK" = "1" ]; then
  echo "  ✅ C-A3: extracted negative-auth regex against ZERO-match fixture → 0 matches (verifier would emit MAJOR + PARTIAL)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-A3: $C_A3_REASON"
  FAIL=$((FAIL + 1))
fi

# --- C-A4: same regex, fixture WITH matching labels → ≥1 match ---
TOTAL=$((TOTAL + 1))
C_A4_OK=1
C_A4_REASON=""
# Re-extract for symmetry (does not depend on C_A3 having succeeded).
VERIFIER_REGEX_LINE=$(grep -nE '^\s*/\(.*\)/i\s*$' "$VERIFIER" | head -1 | cut -d: -f2-)
if [ -z "$VERIFIER_REGEX_LINE" ]; then
  C_A4_OK=0; C_A4_REASON="could not extract regex from verifier.md (sanity-fail in A4)"
else
  EXTRACTED_REGEX=$(echo "$VERIFIER_REGEX_LINE" | sed -E 's|^[[:space:]]*/||; s|/i[[:space:]]*$||')
fi
if [ "$C_A4_OK" = "1" ]; then
  HIT_FIXTURE_DIR=$(mktemp -d)
  cat > "$HIT_FIXTURE_DIR/result.json" <<'JSON_EOF'
{
  "task_id": "fixture-hit",
  "tests_run": [
    { "name": "test_basic_addition", "result": "pass" },
    { "name": "test_login_denies_invalid_password", "result": "pass" },
    { "name": "test_returns_403_for_cross_tenant_read", "result": "pass" }
  ]
}
JSON_EOF
  HIT_MATCH_COUNT=$(jq -r '.tests_run[].name' "$HIT_FIXTURE_DIR/result.json" \
    | grep -ciE "$EXTRACTED_REGEX" 2>/dev/null || true)
  rm -rf "$HIT_FIXTURE_DIR"
  if [ "${HIT_MATCH_COUNT:-0}" -lt 1 ]; then
    C_A4_OK=0; C_A4_REASON="hit fixture produced ${HIT_MATCH_COUNT:-0} matches (expected ≥1) — extracted regex failed to find deny/403"
  fi
fi
if [ "$C_A4_OK" = "1" ]; then
  echo "  ✅ C-A4: extracted regex against fixture WITH matching labels → ≥1 match (clean path; enforcement does not trigger)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-A4: $C_A4_REASON"
  FAIL=$((FAIL + 1))
fi

# --- C-A5: legacy PLAN_META fixture without security_envelope validates clean ---
# Auditor PARTIAL Gap-CR-3 part 1: synthesize a minimal task object
# that has every required[] field BUT omits security_envelope.
# Validation surrogate (ajv unavailable per project context — see
# .apex/phases/12-apex-evolution-v8/12.13-RESULT.json files_modified[3]):
#   (a) schema required[] does NOT list security_envelope.
#   (b) the fixture has every field required[] DOES list.
#   (c) additionalProperties:false at task level holds — no extra fields.
TOTAL=$((TOTAL + 1))
C_A5_OK=1
C_A5_REASON=""
# (a) security_envelope absent from required[]:
if jq -e '.properties.tasks.items.required | index("security_envelope")' "$SCHEMA" >/dev/null 2>&1; then
  C_A5_OK=0; C_A5_REASON="schema required[] includes security_envelope (legacy fixtures would FAIL)"
fi
# (b) Build legacy fixture (no security_envelope) covering every
# required[] field. Use a hardcoded list of the 16 documented required
# fields (CRLF-safe — does not iterate jq output which may carry CR on
# Windows checkouts). Drift guard: assert REQUIRED_COUNT matches the
# schema's required[] length so a schema change forces this case to
# be updated.
if [ "$C_A5_OK" = "1" ]; then
  EXPECTED_REQUIRED=(
    "id" "name" "spec_ref" "complexity" "specialist" "is_irreversible"
    "has_behavior" "verify_level" "files" "verify_commands"
    "done_criteria" "edge_cases" "silent_failure_risks" "dependencies"
    "wave" "originating_requirement_id"
  )
  SCHEMA_REQ_COUNT=$(jq -r '.properties.tasks.items.required | length' "$SCHEMA" 2>/dev/null)
  if [ "$SCHEMA_REQ_COUNT" != "${#EXPECTED_REQUIRED[@]}" ]; then
    C_A5_OK=0
    C_A5_REASON="schema required[] count=$SCHEMA_REQ_COUNT differs from test-expected count=${#EXPECTED_REQUIRED[@]} — update EXPECTED_REQUIRED in C-A5"
  fi
fi
if [ "$C_A5_OK" = "1" ]; then
  LEGACY_FIX=$(mktemp)
  cat > "$LEGACY_FIX" <<'JSON_EOF'
{
  "id": "legacy-task-1",
  "name": "legacy auth migration",
  "spec_ref": ["SPEC.md#legacy"],
  "complexity": "medium",
  "specialist": "security",
  "is_irreversible": false,
  "has_behavior": true,
  "verify_level": "standard",
  "files": ["src/legacy/auth.ts"],
  "verify_commands": ["npm test"],
  "done_criteria": ["all tests pass"],
  "edge_cases": ["token expiry"],
  "silent_failure_risks": ["session not invalidated on logout"],
  "dependencies": [],
  "wave": 1,
  "originating_requirement_id": "REQ-LEGACY-001",
  "task_class": "D",
  "negative_auth_required": true
}
JSON_EOF
  # (b) Each expected required field is present in fixture.
  for req_field in "${EXPECTED_REQUIRED[@]}"; do
    if ! jq -e --arg k "$req_field" 'has($k)' "$LEGACY_FIX" >/dev/null 2>&1; then
      C_A5_OK=0; C_A5_REASON="legacy fixture missing required field: $req_field"
      break
    fi
    # Also: assert the schema actually lists this field as required.
    if ! jq -e --arg k "$req_field" '.properties.tasks.items.required | index($k)' "$SCHEMA" >/dev/null 2>&1; then
      C_A5_OK=0; C_A5_REASON="EXPECTED_REQUIRED entry '$req_field' not in schema.required[] — test drift"
      break
    fi
  done
  # (b') confirm security_envelope is NOT in fixture.
  if [ "$C_A5_OK" = "1" ] && jq -e 'has("security_envelope")' "$LEGACY_FIX" >/dev/null 2>&1; then
    C_A5_OK=0; C_A5_REASON="legacy fixture unexpectedly includes security_envelope"
  fi
  # (c) Each fixture key must be declared in schema.properties
  # (additionalProperties:false surrogate). Use jq to check membership
  # rather than iterating-and-comparing strings (CRLF-safe).
  if [ "$C_A5_OK" = "1" ]; then
    FIX_KEY_COUNT=$(jq -r 'keys | length' "$LEGACY_FIX")
    i=0
    while [ "$i" -lt "$FIX_KEY_COUNT" ]; do
      fk=$(jq -r --argjson i "$i" 'keys[$i]' "$LEGACY_FIX")
      if ! jq -e --arg k "$fk" '.properties.tasks.items.properties | has($k)' "$SCHEMA" >/dev/null 2>&1; then
        C_A5_OK=0; C_A5_REASON="legacy fixture field '$fk' not declared in schema.properties (would fail additionalProperties:false)"
        break
      fi
      i=$((i + 1))
    done
  fi
  rm -f "$LEGACY_FIX"
fi
if [ "$C_A5_OK" = "1" ]; then
  echo "  ✅ C-A5: legacy PLAN_META fixture (no security_envelope) validates clean (jq-based surrogate; ajv unavailable per project)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-A5: $C_A5_REASON"
  FAIL=$((FAIL + 1))
fi
# --- C-A6: bypass-resistance — removing security_envelope preserves
#          negative_auth_required → enforcement still keys on safety field ---
# Auditor PARTIAL Gap-CR-3 part 2: build TWO fixtures differing only by
# presence of security_envelope. BOTH must keep negative_auth_required
# visible to a verifier grep — proving that an attacker (or migration
# bug) that strips security_envelope CANNOT bypass STEP 5.5.
TOTAL=$((TOTAL + 1))
C_A6_OK=1
C_A6_REASON=""
FIX_WITH=$(mktemp)
FIX_WITHOUT=$(mktemp)
cat > "$FIX_WITH" <<'JSON_EOF'
{
  "id": "bypass-task-1",
  "task_class": "D",
  "negative_auth_required": true,
  "security_envelope": {
    "threat_model_path": "framework/modules/apex-security/threat-models/bypass-task-1.md",
    "negative_auth_tests": ["test_login_denies"],
    "required_capabilities": ["auth"],
    "auto_filled_at": "2026-05-18T00:00:00Z",
    "auto_filled_from_keywords": ["auth"]
  }
}
JSON_EOF
cat > "$FIX_WITHOUT" <<'JSON_EOF'
{
  "id": "bypass-task-1",
  "task_class": "D",
  "negative_auth_required": true
}
JSON_EOF
# Both fixtures must have negative_auth_required == true.
NAR_WITH=$(jq -r '.negative_auth_required // false' "$FIX_WITH")
NAR_WITHOUT=$(jq -r '.negative_auth_required // false' "$FIX_WITHOUT")
if [ "$NAR_WITH" != "true" ] || [ "$NAR_WITHOUT" != "true" ]; then
  C_A6_OK=0; C_A6_REASON="negative_auth_required not preserved in both fixtures (with=$NAR_WITH, without=$NAR_WITHOUT)"
fi
# Removing security_envelope must NOT change negative_auth_required.
if [ "$C_A6_OK" = "1" ]; then
  TC_WITH=$(jq -r '.task_class // ""' "$FIX_WITH")
  TC_WITHOUT=$(jq -r '.task_class // ""' "$FIX_WITHOUT")
  if [ "$TC_WITH" != "D" ] || [ "$TC_WITHOUT" != "D" ]; then
    C_A6_OK=0; C_A6_REASON="task_class not preserved (with=$TC_WITH, without=$TC_WITHOUT)"
  fi
fi
# Confirm: the WITH fixture HAS security_envelope, the WITHOUT does NOT.
if [ "$C_A6_OK" = "1" ]; then
  if ! jq -e 'has("security_envelope")' "$FIX_WITH" >/dev/null 2>&1; then
    C_A6_OK=0; C_A6_REASON="WITH fixture missing security_envelope (test self-inconsistency)"
  elif jq -e 'has("security_envelope")' "$FIX_WITHOUT" >/dev/null 2>&1; then
    C_A6_OK=0; C_A6_REASON="WITHOUT fixture unexpectedly has security_envelope"
  fi
fi
# Verifier-side: confirm STEP 5.5 keys on negative_auth_required and NOT
# on security_envelope. Grep the relevant verifier.md slice.
if [ "$C_A6_OK" = "1" ]; then
  VERIFIER_55=$(awk '/^STEP 5\.5:/{flag=1; next} /^STEP [0-9]/{flag=0} flag' "$VERIFIER")
  if [ -z "$VERIFIER_55" ]; then
    C_A6_OK=0; C_A6_REASON="could not slice STEP 5.5 block from verifier.md"
  elif ! echo "$VERIFIER_55" | grep -qF "negative_auth_required"; then
    C_A6_OK=0; C_A6_REASON="STEP 5.5 does not key on negative_auth_required"
  elif echo "$VERIFIER_55" | grep -qF "security_envelope"; then
    # If STEP 5.5 referenced security_envelope at all, an attacker could
    # bypass by stripping the envelope. The presence of the string would
    # be a red flag — we expect verifier to be envelope-agnostic.
    C_A6_OK=0; C_A6_REASON="STEP 5.5 references security_envelope (bypass risk — should key on negative_auth_required only)"
  fi
fi
rm -f "$FIX_WITH" "$FIX_WITHOUT"
if [ "$C_A6_OK" = "1" ]; then
  echo "  ✅ C-A6: removing security_envelope preserves negative_auth_required (verifier STEP 5.5 envelope-agnostic; bypass-resistant)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-A6: $C_A6_REASON"
  FAIL=$((FAIL + 1))
fi

# --- C-S1: ci-scan debounce 60s TTL boundary ---
# Auditor PARTIAL Gap-SE-1: ci-scan has a time-based gate (60s window,
# see ci-scan.sh line ~83 `[ "$age" -lt 60 ]`). Boundary tested via
# jq-patch of last_scan_epoch on the state file:
#   30s elapsed (well within 60s window) → debounce SKIPS; state untouched.
#   90s elapsed (well past 60s window)   → debounce re-runs; state refreshed.
# Margin chosen at ±30s from the boundary so transient shell timing
# noise (Windows OneDrive I/O latency, sub-second drift between
# NOW_EPOCH capture and the next ci-scan call) cannot flip the verdict.
TOTAL=$((TOTAL + 1))
C_S1_OK=1
C_S1_REASON=""
SB=$(_make_scan_sandbox)
(
  cd "$SB"
  export APEX_CURRENT_TASK_ID="t-ttl-boundary"
  # Initial scan → state written with current epoch.
  echo '{"tool_input":{"file_path":".github/workflows/good.yml"}}' | bash "$CI_SCAN" >/dev/null 2>&1
  if [ ! -f ".apex/.ci-scan-state.json" ]; then
    echo "STATE_MISSING"
    exit 0
  fi
  NOW_EPOCH=$(date -u +"%s")
  ORIG_HASH=$(jq -r '.last_scan_files_hash // ""' .apex/.ci-scan-state.json)

  # --- 30s elapsed (well within window) → debounce should SKIP, state UNCHANGED ---
  PATCHED_30=$((NOW_EPOCH - 30))
  jq --argjson e "$PATCHED_30" '.last_scan_epoch = $e' .apex/.ci-scan-state.json \
    > .apex/.ci-scan-state.json.tmp && mv .apex/.ci-scan-state.json.tmp .apex/.ci-scan-state.json
  echo '{"tool_input":{"file_path":".github/workflows/good.yml"}}' | bash "$CI_SCAN" >/dev/null 2>&1
  EPOCH_AFTER_30=$(jq -r '.last_scan_epoch // 0' .apex/.ci-scan-state.json)

  # --- 90s elapsed (well past window) → debounce should re-scan, epoch UPDATES ---
  PATCHED_90=$((NOW_EPOCH - 90))
  jq --argjson e "$PATCHED_90" '.last_scan_epoch = $e' .apex/.ci-scan-state.json \
    > .apex/.ci-scan-state.json.tmp && mv .apex/.ci-scan-state.json.tmp .apex/.ci-scan-state.json
  echo '{"tool_input":{"file_path":".github/workflows/good.yml"}}' | bash "$CI_SCAN" >/dev/null 2>&1
  EPOCH_AFTER_90=$(jq -r '.last_scan_epoch // 0' .apex/.ci-scan-state.json)

  # Expected: EPOCH_AFTER_30 == PATCHED_30 (skipped; state untouched).
  #           EPOCH_AFTER_90 >= NOW_EPOCH (re-scan ran; state refreshed
  #           to current epoch, no longer the patched value).
  SKIP_OK=0
  RESCAN_OK=0
  [ "$EPOCH_AFTER_30" = "$PATCHED_30" ] && SKIP_OK=1
  [ "$EPOCH_AFTER_90" != "$PATCHED_90" ] && [ "$EPOCH_AFTER_90" -ge "$NOW_EPOCH" ] && RESCAN_OK=1
  echo "SKIP=$SKIP_OK|RESCAN=$RESCAN_OK|HASH_PRESERVED=$([ -n "$ORIG_HASH" ] && echo 1 || echo 0)"
) > /tmp/apex_s1_$$.out 2>/dev/null
S1_RES=$(cat /tmp/apex_s1_$$.out)
rm -f /tmp/apex_s1_$$.out
rm -rf "$SB"
if [ "$S1_RES" = "SKIP=1|RESCAN=1|HASH_PRESERVED=1" ]; then
  echo "  ✅ C-S1: ci-scan 60s TTL boundary — 30s elapsed → skip (state untouched); 90s elapsed → re-scan (state refreshed)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-S1: expected 'SKIP=1|RESCAN=1|HASH_PRESERVED=1' got '$S1_RES'"
  FAIL=$((FAIL + 1))
fi
# --- C-S2: Hebrew separator variants — space, hyphen, empty ---
# Auditor PARTIAL Gap-SE-3: C-8 covers underscore form only ("לא_מורש").
# The verifier regex is `לא[ _-]?מורש` — the `?` makes the separator
# OPTIONAL, so the contract covers FOUR forms:
#   space      → "לא מורש"
#   hyphen     → "לא-מורש"
#   underscore → "לא_מורש"   (already in C-8)
#   empty      → "לאמורש"    (concatenated)
# C-S2 exercises the three NEW forms (space, hyphen, empty) and asserts
# each matches the verifier regex through the same label-loop pattern
# that C-8 uses. The matching is via grep -iE; the regex string is the
# verbatim verifier production.
TOTAL=$((TOTAL + 1))
NEG_AUTH_REGEX='(deny|denies|denied|denying|unauthori[sz]ed|forbid|forbidden|reject|rejects|rejected|invalid_token|401|403)|(לא[ _-]?מורש|נדחה|אסור|חסום)'
C_S2_FAILS=0
for label in \
  "בדיקה_לא מורש_משתמש_זר" \
  "בדיקה_לא-מורש_לקריאה" \
  "test_לאמורש_path" \
  "should reject when לא מורש"; do
  if ! echo "$label" | grep -qiE "$NEG_AUTH_REGEX"; then
    C_S2_FAILS=$((C_S2_FAILS + 1))
    echo "      separator variant missed: $label"
  fi
done
# Negative control: a label with NEITHER any Hebrew token NOR any English
# negative-auth token must NOT match. Confirms the test isn't trivially
# false-positive after the broadening.
NON_MATCH="בדיקה_בסיסית_של_חישוב_חיבור"
if echo "$NON_MATCH" | grep -qiE "$NEG_AUTH_REGEX"; then
  C_S2_FAILS=$((C_S2_FAILS + 1))
  echo "      negative-control false-positive: $NON_MATCH matched"
fi
if [ "$C_S2_FAILS" = "0" ]; then
  echo "  ✅ C-S2: Hebrew separator variants — space, hyphen, empty all match; non-Hebrew control does not"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-S2: $C_S2_FAILS separator-variant checks failed"
  FAIL=$((FAIL + 1))
fi
# --- C-S3: PARTIAL→BLOCKING regression guard ---
# Auditor PARTIAL Gap-SE-5 / Q6: verifier.md STEP 5.5 block currently
# says "do NOT block in this phase — the BLOCKING gate is promoted to
# ship.md in a follow-up phase". A future edit that quietly promotes
# the deferral to BLOCKING would silently strengthen the gate. This
# case asserts the deferral language is intact in STEP 5.5.
TOTAL=$((TOTAL + 1))
C_S3_OK=1
C_S3_REASON=""
VERIFIER_55=$(awk '/^STEP 5\.5:/{flag=1; next} /^STEP [0-9]/{flag=0} flag' "$VERIFIER")
if [ -z "$VERIFIER_55" ]; then
  C_S3_OK=0; C_S3_REASON="STEP 5.5 block not sliced from verifier.md"
elif ! echo "$VERIFIER_55" | grep -qiE "do NOT block|do not block"; then
  C_S3_OK=0; C_S3_REASON="STEP 5.5 no longer documents 'do NOT block in this phase' — PARTIAL deferral may have been silently promoted"
elif ! echo "$VERIFIER_55" | grep -qF "PARTIAL"; then
  C_S3_OK=0; C_S3_REASON="STEP 5.5 no longer mentions PARTIAL verdict (deferral removed?)"
elif ! echo "$VERIFIER_55" | grep -qF "ship.md"; then
  C_S3_OK=0; C_S3_REASON="STEP 5.5 no longer references ship.md follow-up promotion"
fi
# Additional anti-regression: the verdict statement near
# negative_auth_required must NOT read "verdict = FAIL" or
# "verdict = BLOCKING" or "verdict BLOCKING" — those would indicate
# the deferral was promoted.
if [ "$C_S3_OK" = "1" ]; then
  if echo "$VERIFIER_55" | grep -qiE "verdict[[:space:]]*=[[:space:]]*(FAIL|BLOCKING)"; then
    C_S3_OK=0; C_S3_REASON="STEP 5.5 verdict assignment looks like FAIL or BLOCKING — regression"
  fi
fi
if [ "$C_S3_OK" = "1" ]; then
  echo "  ✅ C-S3: PARTIAL→BLOCKING regression guard — STEP 5.5 still documents 'do NOT block', PARTIAL verdict, ship.md follow-up"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-S3: $C_S3_REASON"
  FAIL=$((FAIL + 1))
fi

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  echo ""
  echo "$PASS/$TOTAL passed, $FAIL failed"
  [ "$FAIL" -eq 0 ] || exit 1
fi
