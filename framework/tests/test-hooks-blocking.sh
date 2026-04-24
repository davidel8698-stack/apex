# R4-004: self-source harness if run standalone
if [ -z "${COMMANDS_DIR:-}" ]; then
  TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$TEST_DIR/_harness.sh"
  harness_setup
  STANDALONE=1
fi

echo "  Hooks: blocking behavior"

cd "$TEMP_REPO"

# A-3a: post-write blocks on tsc errors
echo '{"compilerOptions":{"strict":true,"noEmit":true}}' > tsconfig.json
echo 'const x: number = "not a number";' > bad.ts
bash "$HOOKS_DIR/post-write.sh" bad.ts >out.txt 2>&1; EXIT=$?
assert_exit 2 "$EXIT" "A-3a: post-write exits 2 on TypeScript errors"
rm -f tsconfig.json bad.ts out.txt

# A-3b: post-write passes valid TS (needs working tsc environment)
# Create minimal package.json + install typescript for isolated tsc
if command -v npx &>/dev/null; then
  echo '{"compilerOptions":{"strict":true,"noEmit":true,"skipLibCheck":true,"module":"commonjs","target":"es2020"}}' > tsconfig.json
  echo '{"private":true}' > package.json
  npm install --save-dev typescript 2>/dev/null >&2
  echo 'const x: number = 42;' > good.ts
  bash "$HOOKS_DIR/post-write.sh" good.ts >out.txt 2>&1; EXIT=$?
  assert_exit 0 "$EXIT" "A-3b: post-write exits 0 on valid TypeScript"
  rm -rf tsconfig.json good.ts out.txt package.json package-lock.json node_modules
else
  SKIP=$((SKIP + 1)); TOTAL=$((TOTAL + 1))
  echo "  ⏭️  A-3b: skipped (npx not available)"
fi

# A-3c: post-write skips without tsconfig (G-4 guard)
echo 'const x: number = "error";' > bad.ts
bash "$HOOKS_DIR/post-write.sh" bad.ts >out.txt 2>&1; EXIT=$?
assert_exit 0 "$EXIT" "A-3c: post-write exits 0 without tsconfig (G-4 guard)"
rm -f bad.ts out.txt

# R-020a: post-write blocks non-conventional commit message
echo "added new stuff to the app" > "$TEMP_REPO/COMMIT_EDITMSG"
bash "$HOOKS_DIR/post-write.sh" "$TEMP_REPO/COMMIT_EDITMSG" >out.txt 2>&1; EXIT=$?
assert_exit 2 "$EXIT" "R-020a: post-write exits 2 on non-conventional commit"
rm -f "$TEMP_REPO/COMMIT_EDITMSG" out.txt

# R-020b: post-write passes conventional commit message
echo "feat(auth): add login page" > "$TEMP_REPO/COMMIT_EDITMSG"
bash "$HOOKS_DIR/post-write.sh" "$TEMP_REPO/COMMIT_EDITMSG" >out.txt 2>&1; EXIT=$?
assert_exit 0 "$EXIT" "R-020b: post-write exits 0 on conventional commit"
rm -f "$TEMP_REPO/COMMIT_EDITMSG" out.txt

# R-020c: post-write passes conventional commit with scope and bang
echo "fix(api)!: handle null response in payments" > "$TEMP_REPO/COMMIT_EDITMSG"
bash "$HOOKS_DIR/post-write.sh" "$TEMP_REPO/COMMIT_EDITMSG" >out.txt 2>&1; EXIT=$?
assert_exit 0 "$EXIT" "R-020c: post-write exits 0 on breaking change commit"
rm -f "$TEMP_REPO/COMMIT_EDITMSG" out.txt

# A-8: circuit-breaker unique hash for empty diff
echo '{"circuit_breaker":{"consecutive_no_change_actions":0,"max_allowed":3,"last_file_hash":null,"triggered":false,"total_tool_calls_this_task":0,"max_tool_calls_per_task":80}}' > .apex/STATE.json
git add -A && git commit -qm "clean state" 2>/dev/null
bash "$HOOKS_DIR/circuit-breaker.sh" 2>/dev/null
HASH1=$(jq -r '.circuit_breaker.last_file_hash' .apex/STATE.json 2>/dev/null)
sleep 0.1
bash "$HOOKS_DIR/circuit-breaker.sh" 2>/dev/null
HASH2=$(jq -r '.circuit_breaker.last_file_hash' .apex/STATE.json 2>/dev/null)
[ "$HASH1" != "$HASH2" ]
assert_exit 0 $? "A-8: empty diff produces unique hashes (no false loop)"

# C-1a: mutation-gate code has exit 2 on below threshold
grep -A2 'BELOW THRESHOLD' "$HOOKS_DIR/mutation-gate.sh" | grep -q 'exit 2'
assert_exit 0 $? "C-1a: mutation-gate exits 2 below threshold"

# C-1b: mutation-gate code has exit 0 on pass
grep -A2 'PASS.*mutation' "$HOOKS_DIR/mutation-gate.sh" | grep -q 'exit 0'
assert_exit 0 $? "C-1b: mutation-gate exits 0 on pass"

# B-5: pre-task-snapshot sources _require-git
assert_contains "$HOOKS_DIR/pre-task-snapshot.sh" "_require-git" "B-5: pre-task-snapshot has git guard"

# B-4 (Round 3.2): subagent-stop has 3-way exit branching
assert_contains "$HOOKS_DIR/subagent-stop.sh" "exit 0" "W-1a: subagent-stop has exit 0 (validated)"
assert_contains "$HOOKS_DIR/subagent-stop.sh" "exit 1" "W-1b: subagent-stop has exit 1 (git error advisory)"
assert_contains "$HOOKS_DIR/subagent-stop.sh" "exit 2" "W-1c: subagent-stop has exit 2 (hallucination)"

# R4-004: standalone-mode cleanup (only fires when this test file was invoked directly)
if [ "${STANDALONE:-0}" = "1" ]; then
  harness_teardown
  harness_report
fi
