#!/usr/bin/env bash
# pre-rotation-snapshot.sh — M14 atomic pre-rotation snapshot (Phase 12.08).
#
# Hook type: Command-Invoked (fired by /apex:next's rotation dispatch
# BEFORE pre-compact.sh / observation-mask.sh / pre-task-snapshot.sh).
#
# Purpose
#   When a context rotation (proactive_compact / warn_and_compact /
#   hard_rotate) is about to fire, capture an ATOMIC 4-artifact
#   snapshot so /apex:resume on the other side can reconstruct
#   coherent context. Currently the existing surfaces (turn-checkpoint
#   for STATE-lite, pre-task-snapshot for code, DECISIONS.md in normal
#   flow, SUMMARY.md at task completion) are fragmented across 3 hooks
#   that fire at different times; this hook unifies the rotation-time
#   capture.
#
# The 4 artifacts (per PLAN.md §5):
#   1. STATE.json — fresh canonical write.
#   2. DECISIONS.md — flush pending decisions from .apex/pending_decisions.json.
#   3. git tag — apex/rotation/<timestamp>-<phase>.
#   4. ROTATION-NOTE-<timestamp>.md — 200-400 words (done/next/issues)
#      under .apex/phases/<current>/.
#
# Safe-or-noop contract: on ANY step failure, abort and emit error.
# If step 4 (ROTATION-NOTE) fails after step 3 (git tag) succeeded,
# roll back the git tag so resume.md doesn't see a tag without a note.
#
# Tag cleanup: keep most recent 50 apex/rotation/* tags; older
# auto-purged via `git tag -d`.
#
# Spec anchors
#   apex-spec.md — `עקרונות העבודה` (state-preservation discipline).
#   .apex/phases/12-apex-evolution-v8/PLAN.md task 12.08 §§5-6.
#   R2-C203 (state-preservation pre-rotation).
#
# Usage
#   bash framework/hooks/pre-rotation-snapshot.sh [<rotation_action>]
#
# Inputs
#   $1 rotation_action — one of `proactive_compact | warn_and_compact |
#                        hard_rotate | manual`. Default `manual`. Logged
#                        in the ROTATION-NOTE header.
#
# Exit codes
#   0 = all 4 artifacts written atomically (rotation safe to proceed)
#   1 = an artifact failed (rotation MUST NOT proceed; safe-or-noop)
#   2 = invocation error (missing git, no .apex/, etc.)

set -uo pipefail

ROTATION_ACTION="${1:-manual}"

if [ ! -d ".apex" ]; then
  echo "🚫 pre-rotation-snapshot: no .apex/ in cwd — nothing to snapshot" >&2
  exit 2
fi

if ! command -v git >/dev/null 2>&1; then
  echo "🚫 pre-rotation-snapshot: git is required" >&2
  exit 2
fi

STATE_FILE=".apex/STATE.json"
PENDING_DECISIONS=".apex/pending_decisions.json"

# Resolve current phase from STATE (defensive — falls back to "unknown").
CURRENT_PHASE="unknown"
if command -v jq >/dev/null 2>&1 && [ -f "$STATE_FILE" ]; then
  CURRENT_PHASE="$(jq -r '.current_phase // "unknown"' "$STATE_FILE" 2>/dev/null || echo unknown)"
fi
[ -z "$CURRENT_PHASE" ] || [ "$CURRENT_PHASE" = "null" ] && CURRENT_PHASE="unknown"

PHASE_DIR=".apex/phases/${CURRENT_PHASE}"
mkdir -p "$PHASE_DIR" 2>/dev/null

TS_HUMAN="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
TS_FILE="$(date -u +'%Y%m%dT%H%M%SZ')"
TAG_NAME="apex/rotation/${TS_FILE}-${CURRENT_PHASE}"
ROTATION_NOTE="${PHASE_DIR}/ROTATION-NOTE-${TS_FILE}.md"

# ── ARTIFACT 1: STATE.json fresh write ──────────────────────────────
STATE_OK=true
if [ ! -f "$STATE_FILE" ]; then
  echo "🚫 pre-rotation-snapshot: STATE.json missing at $STATE_FILE" >&2
  STATE_OK=false
elif command -v jq >/dev/null 2>&1; then
  # Touch the file via jq round-trip — confirms valid JSON + canonicalizes.
  TMP="$(mktemp)"
  if jq '.' "$STATE_FILE" > "$TMP" 2>/dev/null && [ -s "$TMP" ]; then
    mv "$TMP" "$STATE_FILE"
  else
    rm -f "$TMP"
    echo "🚫 pre-rotation-snapshot: STATE.json failed jq canonicalize (invalid JSON?)" >&2
    STATE_OK=false
  fi
fi
[ "$STATE_OK" = false ] && exit 1

# ── ARTIFACT 2: DECISIONS.md flush ──────────────────────────────────
# Append any pending decisions queued in .apex/pending_decisions.json.
# Architects + executors signal pending decisions by writing to that
# queue; this hook flushes them into DECISIONS.md at rotation time.
DECISIONS_OK=true
if [ -f "$PENDING_DECISIONS" ] && command -v jq >/dev/null 2>&1; then
  if [ -s "$PENDING_DECISIONS" ]; then
    {
      printf '\n## Decisions flushed at rotation %s (action=%s)\n\n' "$TS_HUMAN" "$ROTATION_ACTION"
      jq -r '.decisions[]? | "- **\(.timestamp // "n/a")** [\(.source // "unknown")]: \(.text // .decision // .summary // "(no text)")"' "$PENDING_DECISIONS" 2>/dev/null
    } >> .apex/DECISIONS.md 2>/dev/null || DECISIONS_OK=false
    # Clear the queue post-flush.
    echo '{"decisions":[]}' > "$PENDING_DECISIONS"
  fi
fi
[ "$DECISIONS_OK" = false ] && {
  echo "🚫 pre-rotation-snapshot: DECISIONS.md flush failed" >&2
  exit 1
}

# ── ARTIFACT 3: git tag apex/rotation/<timestamp>-<phase> ───────────
TAG_OK=true
if ! git tag -a "$TAG_NAME" -m "APEX rotation snapshot: ${ROTATION_ACTION} at ${TS_HUMAN}" 2>/dev/null; then
  echo "🚫 pre-rotation-snapshot: git tag failed (uncommitted changes? collision?)" >&2
  TAG_OK=false
fi
[ "$TAG_OK" = false ] && exit 1

# ── ARTIFACT 4: ROTATION-NOTE-<timestamp>.md ────────────────────────
# 200-400 word summary with sections: done / next / issues.
# v0: hook writes the SHELL of the note; the agent fills the body via
# Task() invocation orchestrated by /apex:next's rotation dispatch.
# This keeps the hook a pure-bash side-effect with no LLM dependency.
NOTE_OK=true
{
  cat <<HEADER
# ROTATION NOTE — ${TS_HUMAN}

**Action:** ${ROTATION_ACTION}
**Phase:** ${CURRENT_PHASE}
**Git tag:** ${TAG_NAME}
**STATE snapshot:** ${STATE_FILE} (canonicalized at ${TS_HUMAN})

## Done

(populated by /apex:next rotation dispatch — Task() invocation
summarizes the last N completed units from
\`.apex/phases/${CURRENT_PHASE}/*-RESULT.json\`)

## Next

(populated similarly — names the next pending task per
\`.apex/phases/${CURRENT_PHASE}/PLAN_META.json\` and any in-flight
work captured in STATE.turn_checkpoint)

## Issues

(populated similarly — surfaces any FAIL / PARTIAL verdicts from
the current phase, any open drift_indicators, any pending
Track D modals from \`.apex/pending_track_d.json\`)

---

**Word cap:** 400. **Audience:** the resumed session reads this
preferentially over DECISIONS.md for "what was I doing"; DECISIONS.md
remains the historical record.
HEADER
} > "$ROTATION_NOTE" 2>/dev/null || NOTE_OK=false

if [ "$NOTE_OK" = false ]; then
  # Roll back git tag — ROTATION-NOTE failure means resume.md would see
  # a tag without a note, violating the atomicity contract.
  git tag -d "$TAG_NAME" >/dev/null 2>&1 || true
  echo "🚫 pre-rotation-snapshot: ROTATION-NOTE write failed; git tag rolled back" >&2
  exit 1
fi

# ── Tag retention: keep last 50 apex/rotation/* tags ────────────────
ALL_ROTATION_TAGS=$(git tag --list 'apex/rotation/*' 2>/dev/null | sort -r)
if [ -n "$ALL_ROTATION_TAGS" ]; then
  TAG_COUNT=$(echo "$ALL_ROTATION_TAGS" | wc -l)
  if [ "$TAG_COUNT" -gt 50 ]; then
    echo "$ALL_ROTATION_TAGS" | tail -n +51 | while IFS= read -r old_tag; do
      git tag -d "$old_tag" >/dev/null 2>&1 || true
    done
  fi
fi

# ── Success ─────────────────────────────────────────────────────────
echo "✅ pre-rotation-snapshot: 4 artifacts written atomically"
echo "   STATE:         $STATE_FILE"
echo "   DECISIONS:     .apex/DECISIONS.md (flush)"
echo "   Tag:           $TAG_NAME"
echo "   ROTATION-NOTE: $ROTATION_NOTE"

# Log to session log + event log.
SESSION_LOG="${HOME}/.claude/hooks/session-log.sh"
[ -x "$SESSION_LOG" ] && bash "$SESSION_LOG" "rotation_snapshot" "Pre-rotation snapshot OK (action=${ROTATION_ACTION}, tag=${TAG_NAME})"

EVENT_LOG="./.apex/event-log.jsonl"
printf '{"ts":"%s","severity":"MINOR","hook":"pre-rotation-snapshot","type":"snapshot.ok","action":"%s","tag":"%s","phase":"%s"}\n' \
  "$TS_HUMAN" "$ROTATION_ACTION" "$TAG_NAME" "$CURRENT_PHASE" >> "$EVENT_LOG" 2>/dev/null

exit 0
