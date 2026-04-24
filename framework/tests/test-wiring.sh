echo "  Wiring: command → hook references"

# A-2: next.md passes phase arg to cross-phase-audit (2 sites)
COUNT=$(grep -c 'cross-phase-audit.sh.*current_phase' "$COMMANDS_DIR/next.md" 2>/dev/null)
[ "$COUNT" -ge 2 ]
assert_exit 0 $? "A-2: next.md passes phase arg at both cross-phase-audit sites ($COUNT found)"

# E-1: next.md wires mutation-gate
assert_contains "$COMMANDS_DIR/next.md" "mutation-gate" "E-1: next.md calls mutation-gate"

# A-10: resume.md null guard for mode
assert_contains "$COMMANDS_DIR/resume.md" "mode.*null|null.*mode" "A-10: resume.md has null guard for autopilot.mode"

# C-4: 4 commands have briefing (post-rename: /apex:micro renamed to /apex:fast)
for cmd in quick fast spec _debate; do
  assert_contains "$COMMANDS_DIR/${cmd}.md" "Mission Briefing|10-B|briefing" "C-4: ${cmd}.md has Mission Briefing"
done

# C-4b: micro.md preserved as backward-compatible redirect to fast
assert_contains "$COMMANDS_DIR/micro.md" "Renamed to /apex:fast|Use /apex:fast instead" "C-4b: micro.md is a redirect to fast"

# E-4: CLAUDE-TEMPLATE.md deployed
[ -f "$HOME/.claude/CLAUDE-TEMPLATE.md" ]
assert_exit 0 $? "E-4: CLAUDE-TEMPLATE.md exists in ~/.claude/"

# NEW-1: start.md has canonical state reference
assert_contains "$COMMANDS_DIR/start.md" "CANONICAL STATE|single source of truth|STATE INITIALIZATION|STATE\.json" "NEW-1: start.md canonical state reference"

# NEW-2: quick.md has reflexion path
assert_contains "$COMMANDS_DIR/quick.md" "reflexion|REFLEXION|retry|Retry" "NEW-2: quick.md has reflexion path"

# NEW-5: status.md shows autopilot breaker fields
assert_contains "$COMMANDS_DIR/status.md" "previous_last_completed|consecutive_sessions" "NEW-5: status.md shows autopilot fields"

# C-8: status.md shows mutation scores
assert_contains "$COMMANDS_DIR/status.md" "mutation" "C-8: status.md references mutation scores"

# next.md calls phantom-check (C-3 from Round 3.2)
assert_contains "$COMMANDS_DIR/next.md" "phantom-check" "C-3: next.md calls phantom-check"

# next.md calls pre-task-snapshot
assert_contains "$COMMANDS_DIR/next.md" "pre-task-snapshot" "next.md calls pre-task-snapshot"

# next.md calls generate-task-map
assert_contains "$COMMANDS_DIR/next.md" "generate-task-map" "next.md calls generate-task-map"

# next.md calls session-log
assert_contains "$COMMANDS_DIR/next.md" "session-log" "next.md calls session-log"

# next.md calls context-monitor
assert_contains "$COMMANDS_DIR/next.md" "context-monitor" "next.md calls context-monitor"

# health-check tests all critical agents
assert_contains "$COMMANDS_DIR/health-check.md" "critic" "health-check tests critic"
assert_contains "$COMMANDS_DIR/health-check.md" "architect" "health-check tests architect"
assert_contains "$COMMANDS_DIR/health-check.md" "executor" "health-check tests executor"
assert_contains "$COMMANDS_DIR/health-check.md" "security" "health-check tests security specialist"

# resume.md reads STATE.json for recovery
assert_contains "$COMMANDS_DIR/resume.md" "STATE.json|STATE" "resume.md reads STATE"

# start.md has environment precheck
assert_contains "$COMMANDS_DIR/start.md" "ENVIRONMENT|precheck|jq.*git" "start.md has environment precheck"

# pause.md exists
[ -f "$COMMANDS_DIR/pause.md" ]
assert_exit 0 $? "pause.md exists"

# recover.md exists
[ -f "$COMMANDS_DIR/recover.md" ]
assert_exit 0 $? "recover.md exists"

# precheck.md exists
[ -f "$COMMANDS_DIR/precheck.md" ]
assert_exit 0 $? "precheck.md exists"

# R-001: help.md exists with routing table
[ -f "$COMMANDS_DIR/help.md" ]
assert_exit 0 $? "R-001: help.md exists"
assert_contains "$COMMANDS_DIR/help.md" "forensics|rollback|status|walkthrough" "R-001: help.md has intent-to-command routing"

# R3-007: apex-model-routing.json schema sanity
# resolve_model() in next.md is AI-interpreted pseudocode — not bash-testable.
# Instead, we assert the structural invariants that pseudocode depends on:
# every agent has .default, and escalation maps (when present) are objects.
MODEL_ROUTING="$HOME/.claude/apex-model-routing.json"
if [ -f "$MODEL_ROUTING" ]; then
  MISSING_DEFAULT=$(jq -r '.routing | to_entries[] | select(.value.default == null) | .key' "$MODEL_ROUTING" 2>/dev/null)
  [ -z "$MISSING_DEFAULT" ]
  assert_exit 0 $? "R3-007: every agent in apex-model-routing.json has .default"

  BAD_ESCALATION=$(jq -r '
    .routing | to_entries[] |
    select(
      (.value.escalate_on_level  // {} | type) != "object" or
      (.value.escalate_on_mode   // {} | type) != "object" or
      (.value.downgrade_on_verify_level // {} | type) != "object"
    ) | .key
  ' "$MODEL_ROUTING" 2>/dev/null)
  [ -z "$BAD_ESCALATION" ]
  assert_exit 0 $? "R3-007: escalation maps are objects where present"

  # escalate_on_retry is a scalar string (not an object) — separate check
  BAD_RETRY=$(jq -r '
    .routing | to_entries[] |
    select(
      .value.escalate_on_retry != null and
      (.value.escalate_on_retry | type) != "string"
    ) | .key
  ' "$MODEL_ROUTING" 2>/dev/null)
  [ -z "$BAD_RETRY" ]
  assert_exit 0 $? "R3-007: escalate_on_retry is a string where present"
else
  echo "  (skip R3-007 model-routing schema checks — $MODEL_ROUTING not deployed)"
fi

# R3-012: Defensive mkdir contract for user-facing memory/write commands
# Every listed command writes under a .apex/ subdir that may not exist in
# edge cases (dir deleted, project pre-R-008 init). All must have a
# `mkdir -p .apex/<subdir>/` instruction before their Write.
for cmd_pair in "thread:threads" "plant-seed:seeds" "add-backlog:backlog" "_debate:debate-log" "_roundtable:roundtable-log" "ui-phase:phases"; do
  cmd="${cmd_pair%%:*}"
  dir="${cmd_pair##*:}"
  assert_contains "$COMMANDS_DIR/${cmd}.md" "mkdir -p .apex/${dir}" "R3-012: ${cmd}.md has defensive mkdir -p .apex/${dir}"
done
