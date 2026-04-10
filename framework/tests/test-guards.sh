echo "  Guards: tool availability"

# G-1a: _require-git fails without git (code inspection — PATH tricks unreliable on Windows)
grep -q 'command -v git' "$HOOKS_DIR/_require-git.sh"
assert_exit 0 $? "G-1a: _require-git checks for git in PATH"
grep -q 'exit 2' "$HOOKS_DIR/_require-git.sh"
assert_exit 0 $? "G-1a: _require-git exits 2 on failure"

# G-1b: _require-git checks repo presence
grep -q 'git rev-parse' "$HOOKS_DIR/_require-git.sh"
assert_exit 0 $? "G-1b: _require-git checks git repo with rev-parse"

# G-1c: 6 hooks source _require-git
for hook in circuit-breaker cross-phase-audit generate-task-map phase-tag pre-task-snapshot tdad-index; do
  assert_contains "$HOOKS_DIR/${hook}.sh" "_require-git" "G-1c: ${hook}.sh sources _require-git"
done

# G-2: no bc dependency in cross-phase-audit
assert_not_contains "$HOOKS_DIR/cross-phase-audit.sh" "\| bc" "G-2: cross-phase-audit uses bash arithmetic, not bc"

# G-3: rg guarded in generate-task-map
assert_contains "$HOOKS_DIR/generate-task-map.sh" "command -v rg" "G-3: rg usage guarded"

# G-4: tsc guarded in post-write
assert_contains "$HOOKS_DIR/post-write.sh" "tsconfig.json" "G-4a: tsc guarded by tsconfig check"
assert_contains "$HOOKS_DIR/post-write.sh" "command -v npx" "G-4b: tsc guarded by npx check"
