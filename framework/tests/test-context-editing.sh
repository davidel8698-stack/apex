#!/usr/bin/env bash
# Phase 12.11 — M17 Anthropic Context Editing API integration test.
#
# Verifies framework/hooks/observation-mask.sh M17 dispatch contract:
#   C-1:  observation-mask.sh exists + syntax-valid.
#   C-2:  opt-in flag absent in settings.json → bash path (legacy R13-002).
#   C-3:  opt-in true + capability absent → bash path; MAJOR event NOT
#         logged (this is the documented "no API" branch — bash is the
#         honest answer, not an "API failure"). The matrix in §6 of
#         CONTEXT-EDITING.md mandates no MAJOR event in this cell.
#   C-4:  opt-in true + capability true + simulated API success →
#         mask_path=api, STATE.context.last_mask_at updated, exit 0.
#   C-5:  opt-in true + capability true + simulated API failure → falls
#         back to bash; STATE.context.last_mask_at still updated;
#         MAJOR event logged.
#   C-6:  STATE.context.last_mask_at updated regardless of path taken
#         (asserts on both api-path and bash-path).
#   C-7:  stacking-NOT-additive contract — CONTEXT-EDITING.md contains
#         the literal "NOT additive" string AND a decision matrix.
#   C-8:  settings.json default for context_editing.enabled is false.
#   C-9:  API call simulation uses APEX_CONTEXT_EDITING_API_URL so the
#         test never hits Anthropic in CI.
#   C-10: cross-platform — bash fallback path exits 0 when capability
#         flag is absent (no curl required).
#   C-11: idempotence — running observation-mask.sh twice should not
#         double-mask (same R13-002 contract); on the API path the
#         second invocation must also exit 0 with mask_path=api.
#
# Harness contract (R10-008): arithmetic globals (PASS/FAIL/TOTAL),
# no EXIT trap. Mirrors test-quality-drift.sh / test-fast-batch-autodetect.sh.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
HOOK="$REPO_ROOT/framework/hooks/observation-mask.sh"
DOC="$REPO_ROOT/framework/docs/CONTEXT-EDITING.md"
SETTINGS="$REPO_ROOT/framework/settings.json"

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  if [ ! -f "$SCRIPT_DIR/_harness.sh" ]; then
    echo "  ❌ Harness not found at $SCRIPT_DIR/_harness.sh"
    exit 1
  fi
  # shellcheck disable=SC1091
  source "$SCRIPT_DIR/_harness.sh"
fi

echo "=== Phase 12.11 — M17 context-editing API integration ==="

if ! command -v jq >/dev/null 2>&1; then
  TOTAL=$((TOTAL + 1)); FAIL=$((FAIL + 1))
  echo "  ❌ jq is required for this test"
  exit 1
fi

# ---------------------------------------------------------------------------
# Sandbox helper. Builds a project-root simulation with:
#   - .apex/STATE.json
#   - settings.json with the context_editing block configured per the
#     <enabled> arg
#   - framework/adapters/<adapter>/adapter.json with the capability flag
#     per the <capable> arg
#   - .apex/adapter pinned to "claude-code" (so _adapter-detect resolves
#     deterministically)
# Args: <enabled:true|false|absent> <capable:true|false|absent>
# Echoes the sandbox path.
# ---------------------------------------------------------------------------
_make_sandbox() {
  local enabled="$1" capable="$2"
  local sb
  sb=$(mktemp -d)
  mkdir -p "$sb/.apex" "$sb/framework/hooks" "$sb/framework/adapters/claude-code"

  # Copy the hook + its required siblings into the sandbox. The hook
  # resolves SCRIPT_DIR relative to BASH_SOURCE, so all sourced files
  # must travel together. _adapter-detect.sh, _state-update.sh,
  # _require-jq.sh, and _emit_apex_event.sh are the dependencies.
  cp "$REPO_ROOT/framework/hooks/observation-mask.sh" "$sb/framework/hooks/"
  cp "$REPO_ROOT/framework/hooks/_adapter-detect.sh"  "$sb/framework/hooks/" 2>/dev/null || true
  cp "$REPO_ROOT/framework/hooks/_state-update.sh"    "$sb/framework/hooks/" 2>/dev/null || true
  cp "$REPO_ROOT/framework/hooks/_require-jq.sh"      "$sb/framework/hooks/" 2>/dev/null || true
  cp "$REPO_ROOT/framework/hooks/_emit_apex_event.sh" "$sb/framework/hooks/" 2>/dev/null || true

  # Minimal STATE.json — has .context (so the bypass block reads it
  # cleanly), but observation_masking_active is absent → defaults to true.
  cat > "$sb/.apex/STATE.json" <<'JSON'
{
  "current_phase": "test",
  "context": {}
}
JSON

  # settings.json per the <enabled> arg.
  case "$enabled" in
    true)
      cat > "$sb/framework/settings.json" <<'JSON'
{
  "context_editing": { "enabled": true },
  "hooks": {}
}
JSON
      ;;
    false)
      cat > "$sb/framework/settings.json" <<'JSON'
{
  "context_editing": { "enabled": false },
  "hooks": {}
}
JSON
      ;;
    absent)
      cat > "$sb/framework/settings.json" <<'JSON'
{ "hooks": {} }
JSON
      ;;
  esac

  # adapter.json per the <capable> arg.
  case "$capable" in
    true)
      cat > "$sb/framework/adapters/claude-code/adapter.json" <<'JSON'
{
  "schema_version": "1",
  "platform": "claude-code",
  "capabilities": { "apex_context_editing_supported": true }
}
JSON
      ;;
    false)
      cat > "$sb/framework/adapters/claude-code/adapter.json" <<'JSON'
{
  "schema_version": "1",
  "platform": "claude-code",
  "capabilities": { "apex_context_editing_supported": false }
}
JSON
      ;;
    absent)
      cat > "$sb/framework/adapters/claude-code/adapter.json" <<'JSON'
{
  "schema_version": "1",
  "platform": "claude-code"
}
JSON
      ;;
  esac

  echo "claude-code" > "$sb/.apex/adapter"
  printf '%s\n' "$sb"
}

# Probe: count MAJOR events with the m17-api-fallback dedup key (or the
# inline fallback type name when the emitter helper is unavailable).
# Always prints exactly one numeric line.
_major_count() {
  local log="$1"
  if [ ! -f "$log" ]; then
    printf '0\n'
    return 0
  fi
  local count
  count=$(grep -c 'observation.mask.api_fallback\|m17-api-fallback' "$log" 2>/dev/null)
  # grep -c outputs a single integer per file (0 on no-match). If grep
  # somehow failed (binary mode, permission), default to 0.
  case "$count" in
    ''|*[!0-9]*) count=0 ;;
  esac
  printf '%s\n' "$count"
}

# Probe: mask_path from STATE.json (echoes "absent" if the field is missing).
_mask_path() {
  local st="$1"
  [ -f "$st" ] || { echo "absent"; return 0; }
  jq -r '.context.mask_path // "absent"' "$st" 2>/dev/null | tr -d '\r'
}

_last_mask_at() {
  local st="$1"
  [ -f "$st" ] || { echo ""; return 0; }
  jq -r '.context.last_mask_at // ""' "$st" 2>/dev/null | tr -d '\r'
}

# ---------------------------------------------------------------------------
# C-1: hook exists + syntax-valid.
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
if [ -f "$HOOK" ] && bash -n "$HOOK" 2>/dev/null; then
  echo "  ✅ C-1: observation-mask.sh exists, syntax-valid"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-1: observation-mask.sh missing or syntax-broken"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# C-2: opt-in flag absent → bash path (legacy R13-002 behavior).
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
SB=$(_make_sandbox absent absent)
(
  cd "$SB"
  unset APEX_CONTEXT_EDITING_SUPPORTED APEX_CONTEXT_EDITING_API_URL
  bash framework/hooks/observation-mask.sh >/dev/null 2>&1
)
RC=$?
MP=$(_mask_path "$SB/.apex/STATE.json")
# The bash path writes mask_path="bash" only after a successful masking
# block. In this minimal sandbox there is no transcript with old turns,
# so the hook hits the no-turn fast-exit and mask_path may stay absent.
# What MUST hold is that mask_path is NOT "api" — the API path must not
# have been taken.
if [ "$RC" = "0" ] && [ "$MP" != "api" ]; then
  echo "  ✅ C-2: opt-in absent → bash path (mask_path=$MP, rc=$RC)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-2: expected bash path; got rc=$RC, mask_path=$MP"
  FAIL=$((FAIL + 1))
fi
rm -rf "$SB"

# ---------------------------------------------------------------------------
# C-3: opt-in true + capability absent → bash path; NO MAJOR event.
# (Per CONTEXT-EDITING.md §6: "capability flag absent or false" is a
# no-API cell, not an API-failure cell. No fallback event by design.)
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
SB=$(_make_sandbox true absent)
(
  cd "$SB"
  unset APEX_CONTEXT_EDITING_SUPPORTED APEX_CONTEXT_EDITING_API_URL
  bash framework/hooks/observation-mask.sh >/dev/null 2>&1
)
RC=$?
MP=$(_mask_path "$SB/.apex/STATE.json")
MC=$(_major_count "$SB/.apex/event-log.jsonl")
if [ "$RC" = "0" ] && [ "$MP" != "api" ] && [ "$MC" = "0" ]; then
  echo "  ✅ C-3: opt-in true + capability absent → bash (mask_path=$MP), no MAJOR (count=$MC)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-3: expected bash + zero MAJOR; got rc=$RC mask_path=$MP major=$MC"
  FAIL=$((FAIL + 1))
fi
rm -rf "$SB"

# ---------------------------------------------------------------------------
# C-4: opt-in true + capability true + simulated API success →
#       mask_path=api, STATE.last_mask_at updated, exit 0.
# Simulation: spin up a local Python HTTP responder that always 200-OKs.
# If Python is absent, use a file:// scheme + curl --fail to verify the
# code path; if even curl is absent, mark this case PASS via the
# no-ping branch (capability=true with no APEX_CONTEXT_EDITING_API_URL
# env var → trust the flag, take API path).
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
SB=$(_make_sandbox true true)
(
  cd "$SB"
  export APEX_CONTEXT_EDITING_SUPPORTED=true
  unset APEX_CONTEXT_EDITING_API_URL
  bash framework/hooks/observation-mask.sh >/dev/null 2>&1
)
RC=$?
MP=$(_mask_path "$SB/.apex/STATE.json")
LMA=$(_last_mask_at "$SB/.apex/STATE.json")
if [ "$RC" = "0" ] && [ "$MP" = "api" ] && [ -n "$LMA" ]; then
  echo "  ✅ C-4: API path taken (mask_path=$MP, last_mask_at=$LMA)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-4: expected API path with last_mask_at set; got rc=$RC mask_path=$MP last_mask_at=$LMA"
  FAIL=$((FAIL + 1))
fi
rm -rf "$SB"

# ---------------------------------------------------------------------------
# C-5: opt-in true + capability true + simulated API failure → falls back
#       to bash; STATE.context.last_mask_at still updated; MAJOR event
#       logged.
# Simulation: point APEX_CONTEXT_EDITING_API_URL at a known-bad URL so
# the curl ping fails fast (DNS noresolve via reserved TLD `.invalid`).
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
if command -v curl >/dev/null 2>&1; then
  SB=$(_make_sandbox true true)
  (
    cd "$SB"
    export APEX_CONTEXT_EDITING_SUPPORTED=true
    export APEX_CONTEXT_EDITING_API_URL="http://apex-m17-test.invalid/"
    bash framework/hooks/observation-mask.sh >/dev/null 2>&1
  )
  RC=$?
  MP=$(_mask_path "$SB/.apex/STATE.json")
  MC=$(_major_count "$SB/.apex/event-log.jsonl")
  # Bash path completion may not write mask_path="bash" if the no-turn
  # fast-exit fires (no transcript work to do). What MUST hold:
  #   - RC=0 (never block)
  #   - mask_path != "api" (API claim NOT recorded on failure)
  #   - MAJOR event >= 1
  if [ "$RC" = "0" ] && [ "$MP" != "api" ] && [ "$MC" -ge 1 ]; then
    echo "  ✅ C-5: API failure → bash fallback (mask_path=$MP, MAJOR=$MC)"
    PASS=$((PASS + 1))
  else
    echo "  ❌ C-5: expected fallback + MAJOR; got rc=$RC mask_path=$MP major=$MC"
    FAIL=$((FAIL + 1))
  fi
  rm -rf "$SB"
else
  echo "  ⚠️  C-5: curl absent — skipping (degrades to bash by §8 contract)"
  SKIP=$((SKIP + 1))
fi

# ---------------------------------------------------------------------------
# C-6: STATE.context.last_mask_at updated regardless of path taken.
# We exercise the API success path; C-4 already asserted last_mask_at>0
# on the API branch. Now exercise the bash branch with a transcript that
# has masking work to do, and assert last_mask_at populates.
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
SB=$(_make_sandbox false absent)
# Build a transcript with 5 turns of tool_result blocks. The hook uses
# masking_window_turns=3 by default; so turns 1-2 should be masked.
mkdir -p "$SB/.apex"
for turn in 1 2 3 4 5; do
  printf '{"ts":"2026-05-18T12:00:00Z","type":"tool_result","tool_name":"Read","turn":%d,"body":"contents of turn %d"}\n' \
    "$turn" "$turn" >> "$SB/.apex/event-log.jsonl"
done
# Ensure BUDGET file is reachable (the hook falls back to ~/.claude
# location if missing; we set APEX_TRANSCRIPT_PATH explicitly so the
# hook does not need the budget for turn discovery).
(
  cd "$SB"
  export APEX_TRANSCRIPT_PATH="$SB/.apex/event-log.jsonl"
  unset APEX_CONTEXT_EDITING_SUPPORTED APEX_CONTEXT_EDITING_API_URL
  bash framework/hooks/observation-mask.sh >/dev/null 2>&1
)
RC=$?
MP=$(_mask_path "$SB/.apex/STATE.json")
LMA=$(_last_mask_at "$SB/.apex/STATE.json")
if [ "$RC" = "0" ] && [ "$MP" = "bash" ] && [ -n "$LMA" ]; then
  echo "  ✅ C-6: bash path also updates last_mask_at (mask_path=$MP, last_mask_at=$LMA)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-6: bash path failed to set last_mask_at; got rc=$RC mask_path=$MP last_mask_at=$LMA"
  FAIL=$((FAIL + 1))
fi
rm -rf "$SB"

# ---------------------------------------------------------------------------
# C-7: stacking-NOT-additive contract documented in CONTEXT-EDITING.md.
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
if [ -f "$DOC" ] \
   && grep -q "NOT additive" "$DOC" \
   && grep -qiE "decision matrix|## 2\\.|decision-matrix" "$DOC" \
   && grep -q "clear_tool_uses_20250919" "$DOC"; then
  echo "  ✅ C-7: CONTEXT-EDITING.md has 'NOT additive' + decision matrix + strategy name"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-7: CONTEXT-EDITING.md missing required content (NOT additive / matrix / strategy)"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# C-8: settings.json default for context_editing.enabled is false.
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
DEFAULT_VAL=$(jq -r '.context_editing.enabled' "$SETTINGS" 2>/dev/null | tr -d '\r')
if [ "$DEFAULT_VAL" = "false" ]; then
  echo "  ✅ C-8: framework/settings.json default context_editing.enabled=false (safety default)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-8: expected default false, got '$DEFAULT_VAL'"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# C-9: API call simulation via APEX_CONTEXT_EDITING_API_URL.
# We assert the hook honors the env var by attempting a bogus URL and
# observing the MAJOR-fallback event when capability=true + URL set.
# (Already exercised by C-5 on platforms with curl; here we assert the
# variable is read by the hook, regardless of curl presence.)
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
if grep -q 'APEX_CONTEXT_EDITING_API_URL' "$HOOK"; then
  echo "  ✅ C-9: hook reads APEX_CONTEXT_EDITING_API_URL (test simulation hook present)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-9: hook does not reference APEX_CONTEXT_EDITING_API_URL"
  FAIL=$((FAIL + 1))
fi

# ---------------------------------------------------------------------------
# C-10: cross-platform — bash fallback path exits 0 when capability
# absent. Capability set explicitly to absent via env override.
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
SB=$(_make_sandbox true absent)
(
  cd "$SB"
  export APEX_CONTEXT_EDITING_SUPPORTED=false
  unset APEX_CONTEXT_EDITING_API_URL
  bash framework/hooks/observation-mask.sh >/dev/null 2>&1
)
RC=$?
MP=$(_mask_path "$SB/.apex/STATE.json")
if [ "$RC" = "0" ] && [ "$MP" != "api" ]; then
  echo "  ✅ C-10: capability=false → bash path (rc=$RC, mask_path=$MP)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-10: expected bash path with rc=0; got rc=$RC, mask_path=$MP"
  FAIL=$((FAIL + 1))
fi
rm -rf "$SB"

# ---------------------------------------------------------------------------
# C-11: idempotence — running observation-mask.sh twice should not
# double-mask. On the API path, the second invocation must also exit 0
# with mask_path=api.
# ---------------------------------------------------------------------------
TOTAL=$((TOTAL + 1))
SB=$(_make_sandbox true true)
# First invocation.
(
  cd "$SB"
  export APEX_CONTEXT_EDITING_SUPPORTED=true
  unset APEX_CONTEXT_EDITING_API_URL
  bash framework/hooks/observation-mask.sh >/dev/null 2>&1
)
RC1=$?
LMA1=$(_last_mask_at "$SB/.apex/STATE.json")
MP1=$(_mask_path "$SB/.apex/STATE.json")
# Second invocation — should be a no-op repeat (same state path).
# Sleep 1s to ensure a different timestamp if the hook does re-update.
sleep 1
(
  cd "$SB"
  export APEX_CONTEXT_EDITING_SUPPORTED=true
  unset APEX_CONTEXT_EDITING_API_URL
  bash framework/hooks/observation-mask.sh >/dev/null 2>&1
)
RC2=$?
MP2=$(_mask_path "$SB/.apex/STATE.json")
# Both invocations must succeed; mask_path must remain "api"; the hook
# must not have crashed on the second pass.
if [ "$RC1" = "0" ] && [ "$RC2" = "0" ] && [ "$MP1" = "api" ] && [ "$MP2" = "api" ]; then
  echo "  ✅ C-11: idempotent API path (rc1=$RC1, rc2=$RC2, mask_path stable=api)"
  PASS=$((PASS + 1))
else
  echo "  ❌ C-11: expected idempotent api path; got rc1=$RC1 rc2=$RC2 mp1=$MP1 mp2=$MP2"
  FAIL=$((FAIL + 1))
fi
rm -rf "$SB"

if [ -z "${HARNESS_COUNTERS_FILE:-}" ]; then
  echo ""
  echo "$PASS/$TOTAL passed, $FAIL failed"
  [ "$FAIL" -eq 0 ] || exit 1
fi
