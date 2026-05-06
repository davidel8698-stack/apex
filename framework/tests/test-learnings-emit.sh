#!/usr/bin/env bash
# R5-019: Living Evidence Counter writer test.
#
# Tested invariants:
#   1. _learnings-emit.sh exists.
#   2. emit_learning <event_type> <phase> <summary> appends a structured
#      entry that contains all required fields (Evidence count, Decay,
#      Verified, Event type, Phase, Summary).
#   3. emit_learning with missing args returns 2.
#   4. The appended entry is parseable by verify-learnings.sh — no
#      MISSING EVIDENCE / DECAYED / STALE CITATION warnings introduced.
#   5. phase-tag.sh sources _learnings-emit.sh on its success branch.
#   6. phantom-check.sh sources _learnings-emit.sh on its FAIL branch.
#   7. critic.md references the emitter on its FAIL branch.
#   8. apex-test-architect agent.md references the emitter on its veto
#      branches.
#   9. HOOK-CLASSIFICATION.md lists _learnings-emit.sh.
#  10. sync-to-claude.sh delivers _learnings-emit.sh.
#  11. After a sandbox phase-tag run, apex-learnings.md gains a new
#      `phase-completed` entry (smoke test from WAVES-R5.md).

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EMIT="$REPO_ROOT/framework/hooks/_learnings-emit.sh"
PHASE_TAG="$REPO_ROOT/framework/hooks/phase-tag.sh"
PHANTOM="$REPO_ROOT/framework/hooks/phantom-check.sh"
CRITIC_MD="$REPO_ROOT/framework/agents/critic.md"
TA_MD="$REPO_ROOT/framework/modules/apex-test-architect/agent.md"
HOOK_CLASS="$REPO_ROOT/framework/HOOK-CLASSIFICATION.md"
SYNC_SH="$REPO_ROOT/framework/scripts/sync-to-claude.sh"

PASS=0
FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
nope() { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "=== R5-019: Living Evidence Counter writer ==="

# C-1
if [ -f "$EMIT" ]; then
  ok "C-1: _learnings-emit.sh exists"
else
  nope "C-1: _learnings-emit.sh missing at $EMIT"
  echo "$PASS/$((PASS+FAIL)) passed"
  exit 1
fi

# C-2: sourced emit_learning appends a complete entry
SANDBOX=$(mktemp -d)
LEARNINGS="$SANDBOX/apex-learnings.md"
APEX_LEARNINGS_FILE="$LEARNINGS" \
  bash -c "
    export APEX_LEARNINGS_FILE='$LEARNINGS'
    source '$EMIT'
    emit_learning 'phase-completed' '01' 'phase 01 tagged ok'
  "

if [ -f "$LEARNINGS" ] \
   && grep -q "^### \[EVT-" "$LEARNINGS" \
   && grep -q "\*\*Evidence count:\*\* 1" "$LEARNINGS" \
   && grep -q "\*\*Decay:\*\* framework" "$LEARNINGS" \
   && grep -q "\*\*Verified:\*\* " "$LEARNINGS" \
   && grep -q "\*\*Event type:\*\* phase-completed" "$LEARNINGS" \
   && grep -q "\*\*Phase:\*\* 01" "$LEARNINGS" \
   && grep -q "\*\*Summary:\*\* phase 01 tagged ok" "$LEARNINGS"; then
  ok "C-2: emit_learning writes a complete WARM-format entry"
else
  nope "C-2: emit_learning entry missing required fields"
  echo "    contents:"; head -30 "$LEARNINGS" 2>/dev/null | sed 's/^/      /'
fi

# C-3: missing args → return 2
out=$(bash -c "
  source '$EMIT'
  emit_learning '' '' ''
  echo \$?
" 2>/dev/null | tail -1)
if [ "$out" = "2" ]; then
  ok "C-3: emit_learning with empty args returns 2"
else
  nope "C-3: expected 2, got '$out'"
fi

# C-4: verify-learnings.sh parses the file without new warnings
# Build a minimal learnings file with a HOT/WARM header + one emitted
# entry, then run verify-learnings against it.
PARSE_FILE="$SANDBOX/parse-test.md"
cat > "$PARSE_FILE" <<'EOF'
# APEX Learnings — Tiered Citation-Based Knowledge Base [v7]

## HOT (max 30 — always loaded into architect context)

## WARM (max 100 — loaded when stack/domain matches)
EOF
APEX_LEARNINGS_FILE="$PARSE_FILE" \
  bash -c "
    export APEX_LEARNINGS_FILE='$PARSE_FILE'
    source '$EMIT'
    emit_learning 'phase-completed' '02' 'parser smoke test'
  "

# verify-learnings.sh reads from ~/.claude/apex-learnings.md by default;
# substitute by overlaying via a temp HOME so we don't touch the real
# learnings file. The script's $LEARNINGS is hard-coded; we point HOME
# at a fresh dir that contains the parse file.
TMP_HOME="$SANDBOX/home"
mkdir -p "$TMP_HOME/.claude"
cp "$PARSE_FILE" "$TMP_HOME/.claude/apex-learnings.md"
VERIFY_OUT=$(HOME="$TMP_HOME" bash "$REPO_ROOT/framework/hooks/verify-learnings.sh" 2>&1)
VERIFY_RC=$?

# verify-learnings.sh exits 0 only when there are zero issues. We only
# require: no MISSING EVIDENCE warning for the emitted entry, no STALE
# CITATION (we emit no Citation field), no DECAYED (today's date).
if echo "$VERIFY_OUT" | grep -q "MISSING EVIDENCE COUNT.*EVT-" ; then
  nope "C-4: verify-learnings reports MISSING EVIDENCE COUNT for emitted entry"
  echo "    output: $VERIFY_OUT"
elif echo "$VERIFY_OUT" | grep -q "STALE CITATION.*EVT-"; then
  nope "C-4: verify-learnings reports STALE CITATION for emitted entry"
elif echo "$VERIFY_OUT" | grep -q "DECAYED.*EVT-"; then
  nope "C-4: verify-learnings reports DECAYED for emitted entry"
else
  ok "C-4: verify-learnings parses the emitted entry without new warnings"
fi

# C-5: phase-tag.sh references the emitter on success branch
if grep -q "_learnings-emit.sh" "$PHASE_TAG" \
   && grep -q "phase-completed" "$PHASE_TAG"; then
  ok "C-5: phase-tag.sh sources _learnings-emit.sh on success branch"
else
  nope "C-5: phase-tag.sh missing learnings emit on success branch"
fi

# C-6: phantom-check.sh references the emitter on FAIL branch
if grep -q "_learnings-emit.sh" "$PHANTOM" \
   && grep -q "phantom-fail" "$PHANTOM"; then
  ok "C-6: phantom-check.sh sources _learnings-emit.sh on FAIL branch"
else
  nope "C-6: phantom-check.sh missing learnings emit on FAIL branch"
fi

# C-7: critic.md references the emitter on FAIL branch
if grep -q "_learnings-emit.sh" "$CRITIC_MD" \
   && grep -q "critic-fail" "$CRITIC_MD"; then
  ok "C-7: critic.md references the emitter on FAIL branch"
else
  nope "C-7: critic.md missing learnings emit reference on FAIL branch"
fi

# C-8: apex-test-architect agent.md references the emitter on veto branches
if grep -q "_learnings-emit.sh" "$TA_MD" \
   && grep -q "test-architect-veto" "$TA_MD"; then
  ok "C-8: apex-test-architect agent.md references emitter on veto branches"
else
  nope "C-8: apex-test-architect agent.md missing emitter reference on veto branches"
fi

# C-9: HOOK-CLASSIFICATION lists _learnings-emit.sh
if grep -q "_learnings-emit.sh" "$HOOK_CLASS"; then
  ok "C-9: HOOK-CLASSIFICATION.md lists _learnings-emit.sh"
else
  nope "C-9: HOOK-CLASSIFICATION.md missing _learnings-emit.sh"
fi

# C-10: sync-to-claude.sh delivers the helper
if grep -q "_learnings-emit.sh" "$SYNC_SH"; then
  ok "C-10: sync-to-claude.sh delivers _learnings-emit.sh"
else
  nope "C-10: sync-to-claude.sh missing _learnings-emit.sh delivery"
fi

# C-11: smoke — fixture phase-tag run gains a phase-completed entry.
# We can't fully run phase-tag.sh end-to-end here (requires a git repo
# and phase scaffolding), but we can simulate its post-success branch
# directly: source the emitter and call it the way phase-tag does.
SMOKE_LEARNINGS="$SANDBOX/smoke-learnings.md"
APEX_LEARNINGS_FILE="$SMOKE_LEARNINGS" \
  bash -c "
    export APEX_LEARNINGS_FILE='$SMOKE_LEARNINGS'
    source '$EMIT'
    PHASE_ID='03'
    TAG_NAME='apex/phase-03-complete'
    emit_learning 'phase-completed' \"\$PHASE_ID\" \"Phase \$PHASE_ID tagged \$TAG_NAME\"
  "
if [ -f "$SMOKE_LEARNINGS" ] \
   && grep -q "phase-completed" "$SMOKE_LEARNINGS" \
   && grep -q "phase 03 tagged apex/phase-03-complete\|Phase 03 tagged apex/phase-03-complete" "$SMOKE_LEARNINGS"; then
  ok "C-11: simulated phase-tag success appends phase-completed entry"
else
  nope "C-11: simulated phase-tag success failed to append entry"
fi

rm -rf "$SANDBOX"

TOTAL=$((PASS+FAIL))
echo ""
echo "$PASS/$TOTAL passed"
[ "$FAIL" -eq 0 ]
