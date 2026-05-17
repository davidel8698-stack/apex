#!/bin/bash
set -u
# v7: Tiered enforcement + type-specific decay + write gates [R6]
# Validates citations, enforces HOT tier ceiling, decay-class-aware staleness

LEARNINGS=~/.claude/apex-learnings.md
STALE=0
DECAYED=0
HASH_STALE=0           # M13 / Phase 12.04: count of entries whose Code hash no longer matches the current cited code block
HOT_COUNT=0
WARM_COUNT=0
MISSING_EVIDENCE=0
MISSING_PROVENANCE=0   # M13: count of entries missing Source agent OR Code hash (advisory)
CURRENT_SECTION=""
CURRENT_DECAY=""
CURRENT_ENTRY=""
CURRENT_CODE_HASH=""   # M13: parsed Code hash for the current entry (empty if absent)
CURRENT_SOURCE_AGENT=""
HAS_EVIDENCE_COUNT=0
NOW_EPOCH=$(date +%s)

[ ! -f "$LEARNINGS" ] && exit 0

# Portable date-to-epoch: shared utility with 4-tier fallback
source "$(dirname "$0")/_date-parse.sh"
parse_date_epoch() {
  parse_epoch "$1" "%Y-%m-%d"
}

# v7 [R6]: Map decay class to max days
decay_max_days() {
  case "$1" in
    safety)        echo 999999 ;;
    architectural) echo 365 ;;
    bug)           echo 180 ;;
    framework)     echo 90 ;;
    project)       echo 30 ;;
    *)             echo 90 ;;
  esac
}

while IFS= read -r line; do
  # Track which section we're in
  if [[ "$line" =~ ^##[[:space:]]HOT ]]; then
    CURRENT_SECTION="HOT"
  elif [[ "$line" =~ ^##[[:space:]]WARM ]]; then
    CURRENT_SECTION="WARM"
  elif [[ "$line" =~ ^##[[:space:]]COLD ]]; then
    CURRENT_SECTION="COLD"
  elif [[ "$line" =~ ^##[[:space:]] ]]; then
    CURRENT_SECTION="OTHER"
  fi

  # Count entries per tier and track current entry name
  if [[ "$line" =~ ^###[[:space:]]\[ ]]; then
    # Check previous entry had evidence_count (skip first and template entries)
    if [ -n "$CURRENT_ENTRY" ] && [ "$HAS_EVIDENCE_COUNT" -eq 0 ] \
       && [[ "$CURRENT_SECTION" == "HOT" || "$CURRENT_SECTION" == "WARM" ]] \
       && [[ "$CURRENT_ENTRY" != *"PATTERN-"* ]]; then
      echo "⚠️ MISSING EVIDENCE COUNT: $CURRENT_ENTRY"
      MISSING_EVIDENCE=$((MISSING_EVIDENCE + 1))
    fi
    # M13 (Phase 12.04): advisory check on prior entry — missing provenance fields.
    # Template/PATTERN-* entries excluded (they're documentation examples, not real entries).
    if [ -n "$CURRENT_ENTRY" ] \
       && [[ "$CURRENT_SECTION" == "HOT" || "$CURRENT_SECTION" == "WARM" ]] \
       && [[ "$CURRENT_ENTRY" != *"PATTERN-"* ]] \
       && { [ -z "$CURRENT_CODE_HASH" ] || [ -z "$CURRENT_SOURCE_AGENT" ]; }; then
      # Advisory only — don't fail the run for legacy entries pre-M13.
      MISSING_PROVENANCE=$((MISSING_PROVENANCE + 1))
    fi
    CURRENT_ENTRY="$line"
    CURRENT_DECAY=""
    CURRENT_CODE_HASH=""
    CURRENT_SOURCE_AGENT=""
    HAS_EVIDENCE_COUNT=0
    case "$CURRENT_SECTION" in
      HOT) HOT_COUNT=$((HOT_COUNT + 1)) ;;
      WARM) WARM_COUNT=$((WARM_COUNT + 1)) ;;
    esac
  fi

  # v8 [R-032]: Validate evidence_count field (living evidence counter)
  if [[ "$line" =~ \*\*Evidence[[:space:]]count:\*\*[[:space:]]*([0-9]+) ]]; then
    HAS_EVIDENCE_COUNT=1
    EC_VAL="${BASH_REMATCH[1]}"
    if [ "$EC_VAL" -lt 1 ]; then
      echo "⚠️ INVALID EVIDENCE COUNT: $CURRENT_ENTRY — count must be ≥ 1"
    fi
  fi

  # v7 [R6]: Read decay class from entry
  if [[ "$line" =~ \*\*Decay:\*\*[[:space:]]*([a-z]+) ]]; then
    CURRENT_DECAY="${BASH_REMATCH[1]}"
  fi

  # M13 (Phase 12.04): Parse provenance fields from the current entry.
  if [[ "$line" =~ \*\*Code[[:space:]]hash:\*\*[[:space:]]*(sha256:[a-f0-9]{4,}([…]?)([a-f0-9]+)?) ]]; then
    CURRENT_CODE_HASH="${BASH_REMATCH[1]}"
  fi
  if [[ "$line" =~ \*\*Source[[:space:]]agent:\*\*[[:space:]]*([a-zA-Z_-]+) ]]; then
    CURRENT_SOURCE_AGENT="${BASH_REMATCH[1]}"
  fi

  # v7 [R6]: Check date-based staleness with decay-class-aware thresholds
  if [[ "$line" =~ \*\*Verified:\*\*[[:space:]]*([0-9]{4}-[0-9]{2}-[0-9]{2}) ]] || \
     [[ "$line" =~ \*\*Citation:\*\*.*([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
    ENTRY_DATE="${BASH_REMATCH[1]}"
    ENTRY_EPOCH=$(parse_date_epoch "$ENTRY_DATE")
    if [ -n "$ENTRY_EPOCH" ]; then
      DAYS_OLD=$(( (NOW_EPOCH - ENTRY_EPOCH) / 86400 ))
      MAX_DAYS=$(decay_max_days "$CURRENT_DECAY")
      if [ "$DAYS_OLD" -gt "$MAX_DAYS" ] && [ "$CURRENT_SECTION" != "COLD" ]; then
        echo "⏰ DECAYED: $CURRENT_ENTRY (${DAYS_OLD}d old, decay=$CURRENT_DECAY, max=${MAX_DAYS}d)"
        DECAYED=$((DECAYED + 1))
      fi
    fi
  fi

  # Check citations — extract file:line patterns from citation text
  if [[ "$line" =~ \*\*Citation:\*\*[[:space:]]*([^:]+):([0-9]+) ]]; then
    RAW_REF="${BASH_REMATCH[1]}"
    # Extract just the filename: last space-separated token that looks like a path
    # Handles "Round 3.2 C-3 — critic.md" → "critic.md"
    FILE=$(echo "$RAW_REF" | grep -oE '[^ ]*\.[a-zA-Z]+$' || echo "$RAW_REF")
    # Skip template/example citations (contain placeholder text)
    if [[ "$FILE" == *"project-"* ]] || [[ "$FILE" == *"["*"]"* ]]; then
      continue
    fi
    # Resolve paths: check relative, src/, project, and framework (~/.claude/) locations
    EXPANDED_FILE="${FILE/#\~/$HOME}"
    if [ ! -f "$FILE" ] && [ ! -f "src/$FILE" ] && [ ! -f "./$FILE" ] \
       && [ ! -f "$EXPANDED_FILE" ] \
       && [ ! -f "$HOME/.claude/agents/$FILE" ] \
       && [ ! -f "$HOME/.claude/commands/apex/$FILE" ]; then
      echo "⚠️ STALE CITATION: $CURRENT_ENTRY — $FILE (file not found)"
      STALE=$((STALE + 1))
    fi
  fi
done < "$LEARNINGS"

# Check last entry for evidence_count
if [ -n "$CURRENT_ENTRY" ] && [ "$HAS_EVIDENCE_COUNT" -eq 0 ] \
   && [[ "$CURRENT_SECTION" == "HOT" || "$CURRENT_SECTION" == "WARM" ]] \
   && [[ "$CURRENT_ENTRY" != *"PATTERN-"* ]]; then
  echo "⚠️ MISSING EVIDENCE COUNT: $CURRENT_ENTRY"
  MISSING_EVIDENCE=$((MISSING_EVIDENCE + 1))
fi

# v7: Tier enforcement
if [ "$HOT_COUNT" -gt 30 ]; then
  echo "⚠️ HOT tier over capacity: $HOT_COUNT entries (max: 30). Demote least-used to WARM."
fi

if [ "$WARM_COUNT" -gt 100 ]; then
  echo "⚠️ WARM tier over capacity: $WARM_COUNT entries (max: 100). Archive oldest to COLD."
fi

# Report
ISSUES=$((STALE + DECAYED + MISSING_EVIDENCE))
if [ "$ISSUES" -gt 0 ]; then
  [ "$STALE" -gt 0 ] && echo "⚠️ $STALE stale citations. Review apex-learnings.md."
  [ "$DECAYED" -gt 0 ] && echo "⏰ $DECAYED entries past decay threshold. Move to COLD."
  [ "$MISSING_EVIDENCE" -gt 0 ] && echo "⚠️ $MISSING_EVIDENCE entries missing evidence_count field."
  [ "$MISSING_PROVENANCE" -gt 0 ] && echo "ℹ️ $MISSING_PROVENANCE entries missing M13 provenance (Source agent / Code hash) — advisory only; legacy entries pre-M13 are exempt."
else
  echo "✅ All citations valid | HOT: $HOT_COUNT/30 | WARM: $WARM_COUNT/100"
fi

# R13-006 (F-306): emit a single-line JSON metric the
# Context Health dashboard (/apex:status) consumes for the
# 'drift_indicators' / stale-state row. Total = HOT + WARM (COLD is
# archived and intentionally excluded from the freshness rate);
# stale_count = STALE (citation file-not-found) only — decay and
# missing-evidence are separate gauges. Rate is integer percent.
# Emission is unconditional so the consumer can parse a stable line
# regardless of pass/fail state. Prefix `APEX_HEALTH_JSON ` makes
# the line grep-able for the status renderer without interleaving
# with the human-readable summary lines above.
TIER_TOTAL=$((HOT_COUNT + WARM_COUNT))
if [ "$TIER_TOTAL" -gt 0 ]; then
  STALE_RATE=$(( STALE * 100 / TIER_TOTAL ))
else
  STALE_RATE=0
fi
printf 'APEX_HEALTH_JSON {"stale_reference_rate":%s,"stale_count":%s,"hot_count":%s,"warm_count":%s}\n' \
  "$STALE_RATE" "$STALE" "$HOT_COUNT" "$WARM_COUNT"

if [ "$ISSUES" -gt 0 ] || [ "$HOT_COUNT" -gt 30 ] || [ "$WARM_COUNT" -gt 100 ]; then exit 1; fi
exit 0