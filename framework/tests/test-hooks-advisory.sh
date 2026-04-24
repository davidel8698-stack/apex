# R4-004: self-source harness if run standalone
if [ -z "${COMMANDS_DIR:-}" ]; then
  TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$TEST_DIR/_harness.sh"
  harness_setup
  STANDALONE=1
fi

echo "  Hooks: advisory behavior"

cd "$TEMP_REPO"

# B-2: verify-learnings placeholder not flagged as stale
cat > /tmp/apex-test-learnings.md << 'LEARN'
## HOT
### [TEST] Example pattern
**Citation:** [project-name]:42
**Decay:** framework
**Verified:** 2026-04-01
LEARN
LEARNINGS=/tmp/apex-test-learnings.md bash "$HOOKS_DIR/verify-learnings.sh" > /tmp/apex-b2-out.txt 2>&1
! grep -q "STALE CITATION.*project-name" /tmp/apex-b2-out.txt
assert_exit 0 $? "B-2: placeholder [project-name] not flagged as stale"
rm -f /tmp/apex-test-learnings.md /tmp/apex-b2-out.txt

# B-9: generate-task-map exits 1 on empty map
echo '{"current_phase":"01"}' > .apex/STATE.json
echo '{"tasks":[]}' > .apex/phases/01/PLAN_META.json
bash "$HOOKS_DIR/generate-task-map.sh" nonexistent-task >out.txt 2>err.txt; EXIT=$?
assert_exit 1 "$EXIT" "B-9: generate-task-map exits 1 on empty map"
rm -f out.txt err.txt

# B-10: pre-compact has error checking on cp (code inspection — chmod unreliable on Windows)
assert_contains "$HOOKS_DIR/pre-compact.sh" "Failed to back up|BACKUP_OK|backup.*fail" "B-10: pre-compact has cp error detection"

# B-3: settings.json has no || true on verify-learnings
assert_not_contains "$HOME/.claude/settings.json" "verify-learnings.*true" "B-3: no || true on verify-learnings"

# R4-004: standalone-mode cleanup (only fires when this test file was invoked directly)
if [ "${STANDALONE:-0}" = "1" ]; then
  harness_teardown
  harness_report
fi
