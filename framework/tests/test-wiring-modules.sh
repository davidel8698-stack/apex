# R5-001: Module ecosystem wiring test.
#
# Verifies the manifest-driven module layout introduced by R5-001:
#   - exactly the eight spec-named modules listed in the registry
#   - every manifest has the required fields per
#     framework/modules/_schema/manifest.schema.json
#   - sync-to-claude.sh --dry-run delivers each migrated specialist to the
#     flat live tree at ~/.claude/agents/specialist/<short>.md
#   - core-engine agents are NOT relocated
#   - self-heal pipeline workers are NOT relocated
#   - Task() invocation counts in framework/commands/apex/ are stable
#
# Asserts run against the framework source tree (not ~/.claude/) — module
# layout is a build-time concern, not a runtime install.

# Resolve framework root from this test file's location BEFORE the harness
# changes the working directory (harness_setup cd's into a temp repo).
T_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FW_ROOT="$(cd "$T_DIR/.." && pwd)"
MOD_ROOT="$FW_ROOT/modules"

# R4-004: self-source harness if run standalone
if [ -z "${COMMANDS_DIR:-}" ]; then
  source "$T_DIR/_harness.sh"
  harness_setup
  STANDALONE=1
fi

echo "  Module ecosystem (R5-001): manifest-driven layout"

# 1. Registry exists and parses.
[ -f "$MOD_ROOT/_registry.json" ]
assert_exit 0 $? "R5-001: framework/modules/_registry.json exists"

jq empty "$MOD_ROOT/_registry.json" >/dev/null 2>&1
assert_exit 0 $? "R5-001: _registry.json is valid JSON"

# 2. Registry contains exactly the eight spec-named modules (sorted).
EXPECTED="apex-builder,apex-core,apex-data,apex-fintech,apex-frontend,apex-healthcare,apex-security,apex-test-architect"
ACTUAL=$(jq -r '.modules | map(.name) | sort | join(",")' "$MOD_ROOT/_registry.json")
[ "$ACTUAL" = "$EXPECTED" ]
assert_exit 0 $? "R5-001: registry lists exactly the eight spec-named modules"

# 3. Manifest schema exists and parses.
[ -f "$MOD_ROOT/_schema/manifest.schema.json" ]
assert_exit 0 $? "R5-001: manifest.schema.json exists"

jq empty "$MOD_ROOT/_schema/manifest.schema.json" >/dev/null 2>&1
assert_exit 0 $? "R5-001: manifest.schema.json is valid JSON"

# 4. Every module dir has a manifest with all required fields.
REQUIRED='["name","version","owner","status","capabilities"]'
for mod_dir in "$MOD_ROOT"/*/; do
  mod_name=$(basename "$mod_dir")
  case "$mod_name" in _*) continue ;; esac
  manifest="$mod_dir/manifest.json"
  [ -f "$manifest" ]
  assert_exit 0 $? "R5-001: $mod_name has manifest.json"
  missing=$(jq -r --argjson r "$REQUIRED" '$r - (keys // []) | join(",")' "$manifest" 2>/dev/null)
  [ -z "$missing" ]
  assert_exit 0 $? "R5-001: $mod_name manifest has all required fields (missing: ${missing:-none})"
  # status enum check
  status_val=$(jq -r '.status' "$manifest")
  case "$status_val" in
    active|stub|core) ;;
    *) status_val="INVALID:$status_val" ;;
  esac
  [ "${status_val%%:*}" != "INVALID" ]
  assert_exit 0 $? "R5-001: $mod_name manifest status is one of {active,stub,core} (got $status_val)"
done

# 5. Migrated specialists have agent.md byte-preserved (frontmatter name field
#    matches the dispatcher contract).
for pair in apex-data:data-specialist apex-frontend:frontend-specialist apex-integration:integration-specialist apex-memory-synthesis:memory-synthesis apex-security:security-specialist apex-test-architect:test-architect; do
  mod="${pair%%:*}"; expected="${pair##*:}"
  agent="$MOD_ROOT/$mod/agent.md"
  [ -f "$agent" ]
  assert_exit 0 $? "R5-001: $mod/agent.md exists"
  actual=$(grep -m1 '^name:' "$agent" 2>/dev/null | sed 's/name: *//')
  [ "$actual" = "$expected" ]
  assert_exit 0 $? "R5-001: $mod/agent.md frontmatter name=$expected (got '$actual')"
done

# 6. Stub modules have NO agent.md (they advertise structure only).
for stub in apex-fintech apex-healthcare apex-builder apex-core; do
  [ ! -f "$MOD_ROOT/$stub/agent.md" ]
  assert_exit 0 $? "R5-001: $stub has no agent.md (status=stub|core)"
done

# 7. Core-engine agents NOT relocated (preservation contract).
for core in architect.md auditor.md critic.md executor.md planner.md verifier.md; do
  [ -f "$FW_ROOT/agents/$core" ]
  assert_exit 0 $? "R5-001: core-engine agent framework/agents/$core preserved at root"
done

# 8. Self-heal pipeline workers NOT relocated (preservation contract).
for worker in framework-auditor.md remediation-planner.md batch-scheduler.md wave-executor.md round-checker.md; do
  [ -f "$FW_ROOT/agents/specialist/$worker" ]
  assert_exit 0 $? "R5-001: self-heal worker framework/agents/specialist/$worker preserved"
done

# 9. test-architect.md no longer at framework/agents/ root (migrated to module).
[ ! -f "$FW_ROOT/agents/test-architect.md" ]
assert_exit 0 $? "R5-001: framework/agents/test-architect.md moved into apex-test-architect module"

# 10. The pre-migration paths are gone (specialists moved to modules).
for old in data.md frontend.md integration.md memory-synthesis.md security.md; do
  [ ! -f "$FW_ROOT/agents/specialist/$old" ]
  assert_exit 0 $? "R5-001: framework/agents/specialist/$old moved into apex-* module"
done

# 11. sync-to-claude.sh --dry-run enumerates all six migrated specialists in
#     the flat live-tree destination.
DRY_OUT=$(bash "$FW_ROOT/scripts/sync-to-claude.sh" --dry-run 2>&1 || true)
for short in data frontend integration memory-synthesis security test-architect; do
  echo "$DRY_OUT" | grep -qE "agents/specialist/${short}\.md\$"
  assert_exit 0 $? "R5-001: sync delivers ~/.claude/agents/specialist/${short}.md"
done

# 12. Task() invocation counts across framework/commands/apex/ are stable.
#     The pre-migration baseline (captured during R5-001 execution):
#       data-specialist=1, frontend-specialist=2, security-specialist=1,
#       memory-synthesis=0, integration-specialist=1, test-architect=2.
#     Post-migration counts must match.
declare -A EXPECTED_COUNTS
EXPECTED_COUNTS["data-specialist"]=1
EXPECTED_COUNTS["frontend-specialist"]=2
EXPECTED_COUNTS["security-specialist"]=1
EXPECTED_COUNTS["memory-synthesis"]=0
EXPECTED_COUNTS["integration-specialist"]=1
EXPECTED_COUNTS["test-architect"]=2
for n in "${!EXPECTED_COUNTS[@]}"; do
  exp="${EXPECTED_COUNTS[$n]}"
  got=$(grep -rE "Task\(\"$n\"" "$FW_ROOT/commands/apex/" 2>/dev/null | wc -l)
  got=$(echo "$got" | tr -d ' ')
  [ "$got" = "$exp" ]
  assert_exit 0 $? "R5-001: Task(\"$n\") invocation count stable (expected $exp, got $got)"
done

# 13. HOOK-CLASSIFICATION.md gained the Module-contributed hooks section.
grep -q "Module-contributed hooks" "$FW_ROOT/HOOK-CLASSIFICATION.md"
assert_exit 0 $? "R5-001: HOOK-CLASSIFICATION.md has Module-contributed hooks section"

# 14. For R5, no module ships any hook (count==0 in every manifest).
NONZERO=$(jq -r '.hooks | length' "$MOD_ROOT"/*/manifest.json 2>/dev/null | grep -v '^0$' | head -1)
[ -z "$NONZERO" ]
assert_exit 0 $? "R5-001: no module-contributed hooks for R5 (all manifest.hooks arrays are empty)"

# R4-004: standalone-mode cleanup
if [ "${STANDALONE:-0}" = "1" ]; then
  harness_teardown
  harness_report
fi
