#!/usr/bin/env bash
# event-log-rotate.sh — Campaign B B2.3 (GAP-2 + GAP-4 closure).
#
# Hook type: SessionStart.
#
# Purpose
#   Rotate .apex/event-log.jsonl and .apex/subagent-transcripts/ when
#   they exceed the bounded-storage thresholds, and prune archives
#   older than the retention window. Without rotation the audit trail
#   grows unbounded; without retention the .apex/ tree leaks disk over
#   sessions. Both gaps are documented in CAMPAIGN-B-PLAN.md §B-2.
#
# Thresholds (frozen in audit-trail-review/EXPERIMENT-PROTOCOL.md §6.3
# and §B-2.B2.3)
#   * .apex/event-log.jsonl ≥ 10 MB (10 * 1024 * 1024 = 10485760 bytes)
#     → rotate to .apex/event-log-<YYYY-MM-DD>.jsonl.gz (gzip in place)
#   * .apex/subagent-transcripts/ entries individually ≥ 30 days
#     → tar+gzip into .apex/subagent-transcripts-<YYYY-MM-DD>.tar.gz
#       and remove the originals (joint rotation per §6.3)
#   * Any rotated archive ≥ 90 days → unlink
#
# Cross-platform notes
#   * gzip + tar required. Both are present on every supported APEX
#     platform (Win32 bash includes both via MSYS / Git for Windows).
#   * stat -c %s portable: try GNU first, fall back to BSD `stat -f %z`,
#     fall back to `wc -c` as a final resort.
#   * `find -mtime +N` for the retention sweep — POSIX-portable.
#
# Idempotence
#   Safe to fire multiple times per session — the size and mtime guards
#   short-circuit if nothing needs rotation. Re-firing also re-runs the
#   90-day prune (harmless extra `find ... -delete`).
#
# Three-place contract
#   1. this file (with the `# Hook type: SessionStart` header)
#   2. framework/settings.json SessionStart entry
#   3. framework/HOOK-CLASSIFICATION.md Auto-PostToolUse / SessionStart table
#
# Exit codes
#   0 always — fire-and-forget; never blocks session start.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export APEX_HOOK_SOURCE="event-log-rotate"

if ! command -v jq >/dev/null 2>&1; then
  echo "[event-log-rotate] jq absent; skipping rotation telemetry" >&2
fi

# Outside a git repo / .apex absent: silent no-op.
if ! command -v git >/dev/null 2>&1 || ! ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  exit 0
fi
cd "$ROOT" || exit 0
[ -d .apex ] || exit 0

EVENT_LOG=".apex/event-log.jsonl"
TRANSCRIPTS_DIR=".apex/subagent-transcripts"
ARCHIVE_DIR=".apex"
ROTATE_SIZE_BYTES=10485760    # 10 MB (10 * 1024 * 1024) — frozen §6.3
RETENTION_DAYS=90              # archives kept this long — frozen §6.3
TRANSCRIPT_AGE_DAYS=30         # per-transcript jointly-rotated age — §6.3

# Portable file-size in bytes.
_filesize_bytes() {
  local f="$1"
  [ -f "$f" ] || { printf '0\n'; return 0; }
  local s
  s=$(stat -c %s "$f" 2>/dev/null) || s=""
  if [ -z "$s" ]; then s=$(stat -f %z "$f" 2>/dev/null) || s=""; fi
  if [ -z "$s" ]; then s=$(wc -c < "$f" 2>/dev/null | tr -d ' ') || s=0; fi
  printf '%s\n' "${s:-0}"
}

NOW_DATE=$(date -u +%Y-%m-%d 2>/dev/null || echo "1970-01-01")
NOW_TS=$(date -u +%s 2>/dev/null || echo 0)

# ----- 1. Rotate event-log.jsonl if oversized ----------------------------
ROTATED_EVENT_LOG=""
if [ -f "$EVENT_LOG" ]; then
  SIZE=$(_filesize_bytes "$EVENT_LOG")
  if [ "$SIZE" -ge "$ROTATE_SIZE_BYTES" ] 2>/dev/null; then
    # Pick a non-colliding archive name. If today's archive already
    # exists, append a unix-ts disambiguator.
    BASE="${ARCHIVE_DIR}/event-log-${NOW_DATE}"
    ARCHIVE="${BASE}.jsonl"
    if [ -e "${BASE}.jsonl.gz" ] || [ -e "${BASE}.jsonl" ]; then
      ARCHIVE="${BASE}-${NOW_TS}.jsonl"
    fi
    # Atomic rotate: rename original, gzip the rename, leave a fresh empty log.
    if mv "$EVENT_LOG" "$ARCHIVE" 2>/dev/null; then
      : > "$EVENT_LOG" 2>/dev/null || true
      if command -v gzip >/dev/null 2>&1; then
        gzip "$ARCHIVE" 2>/dev/null && ARCHIVE="${ARCHIVE}.gz"
      fi
      ROTATED_EVENT_LOG="$ARCHIVE"
    fi
  fi
fi

# ----- 2. Rotate aged subagent-transcripts -------------------------------
ROTATED_TRANSCRIPTS=0
if [ -d "$TRANSCRIPTS_DIR" ]; then
  # Collect files older than TRANSCRIPT_AGE_DAYS.
  AGED_LIST=$(find "$TRANSCRIPTS_DIR" -maxdepth 1 -type f -name '*.jsonl' -mtime +$TRANSCRIPT_AGE_DAYS 2>/dev/null)
  if [ -n "$AGED_LIST" ]; then
    TAR_BASE="${ARCHIVE_DIR}/subagent-transcripts-${NOW_DATE}"
    TAR_FILE="${TAR_BASE}.tar.gz"
    if [ -e "$TAR_FILE" ]; then
      TAR_FILE="${TAR_BASE}-${NOW_TS}.tar.gz"
    fi
    if command -v tar >/dev/null 2>&1; then
      # Build a relative file list — tar with -C works around Win32
      # path quirks (no drive-letter mismatch in the archive).
      AGED_REL=$(echo "$AGED_LIST" | sed "s|^$TRANSCRIPTS_DIR/||")
      if (cd "$TRANSCRIPTS_DIR" && echo "$AGED_REL" | tar -czf "../../${TAR_FILE}" -T - 2>/dev/null); then
        echo "$AGED_LIST" | xargs -I{} rm -f "{}" 2>/dev/null || true
        ROTATED_TRANSCRIPTS=$(echo "$AGED_LIST" | wc -l | tr -d ' ')
      fi
    fi
  fi
fi

# ----- 3. Retention prune (any rotated archive ≥ 90 days) ----------------
PRUNED=0
PRUNED_LIST=$(find "$ARCHIVE_DIR" -maxdepth 1 -type f \
  \( -name 'event-log-*.jsonl.gz' -o -name 'event-log-*.jsonl' \
     -o -name 'subagent-transcripts-*.tar.gz' \) \
  -mtime +$RETENTION_DAYS 2>/dev/null)
if [ -n "$PRUNED_LIST" ]; then
  PRUNED=$(echo "$PRUNED_LIST" | wc -l | tr -d ' ')
  echo "$PRUNED_LIST" | xargs -I{} rm -f "{}" 2>/dev/null || true
fi

# ----- 4. Emit a log_rotated event when something actually moved ---------
if command -v jq >/dev/null 2>&1 && [ -n "$ROTATED_EVENT_LOG$ROTATED_TRANSCRIPTS$PRUNED" ]; then
  if [ "${ROTATED_TRANSCRIPTS:-0}" -gt 0 ] 2>/dev/null \
     || [ "${PRUNED:-0}" -gt 0 ] 2>/dev/null \
     || [ -n "$ROTATED_EVENT_LOG" ]; then
    # shellcheck disable=SC1091
    source "$SCRIPT_DIR/_state-update.sh"
    _emit_apex_event "log_rotated" .apex \
      rotated_event_log "${ROTATED_EVENT_LOG:-none}" \
      rotated_transcripts "${ROTATED_TRANSCRIPTS:-0}" \
      pruned_archives "${PRUNED:-0}" \
      rotate_size_bytes "$ROTATE_SIZE_BYTES" \
      retention_days "$RETENTION_DAYS"
  fi
fi

exit 0
