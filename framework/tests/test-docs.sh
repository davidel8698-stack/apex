echo "  Docs: content correctness"

BRANDING="$HOME/.claude/apex-branding.md"
DESIGN="$HOME/.claude/apex-design-notes.md"
LEARNINGS="$HOME/.claude/apex-learnings.md"
TEMPLATE="$HOME/.claude/CLAUDE-TEMPLATE.md"
STATUS="$COMMANDS_DIR/status.md"

# C-5: R5 scope note for hooks vs commands
assert_contains "$BRANDING" "hooks.*emoji|hooks.*plain|intentional" "C-5: R5 scope note exists"

# C-6: R12 Live Ticker Hebrew exception
assert_contains "$BRANDING" "Live Ticker|SESSION-LOG.*Hebrew" "C-6: R12 Live Ticker exception"

# C-10: CLAUDE-TEMPLATE says v7
assert_contains "$TEMPLATE" "v7" "C-10a: CLAUDE-TEMPLATE has v7"
assert_not_contains "$TEMPLATE" "APEX v6" "C-10b: no APEX v6 in CLAUDE-TEMPLATE"

# C-11: learnings frequency correct
assert_contains "$LEARNINGS" "session start|SessionStart" "C-11: learnings says session start"

# F-2: maxTurns not max_turns in branding
assert_not_contains "$BRANDING" "max_turns" "F-2: no max_turns in branding (uses maxTurns)"

# H-4: Improvement Index exists
assert_contains "$DESIGN" "Improvement Index" "H-4: Improvement Index section exists"

# H-5: rendering convention documented
assert_contains "$BRANDING" "hooks.*plain|intentional" "H-5: rendering convention documented"

# NEW-3: OneDrive warning
assert_contains "$DESIGN" "OneDrive" "NEW-3: OneDrive risk documented"

# Branding R13 exists
assert_contains "$BRANDING" "R13|Mission Briefing|Flight Recorder" "R13: briefing/recorder rule exists"

# Model routing file exists and is valid JSON
assert_jq "$HOME/.claude/apex-model-routing.json" '.agents != null or ._comment != null' "model-routing.json is valid"
