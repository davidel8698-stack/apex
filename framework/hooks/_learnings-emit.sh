#!/bin/bash
# _learnings-emit.sh — Living Evidence Counter writer (R5-019).
#
# Hook type: Library — Sourced (or Command-Invoked utility)
#
# Purpose
#   Write structured entries to ~/.claude/apex-learnings.md on FAIL,
#   veto, phase-completion, and similar event-emitting sites. The
#   spec-named "Living Evidence Counter" is read by status.md and
#   verify-learnings.sh; without writers it is a misnomer. Every
#   entry appends to the WARM section in a format that
#   verify-learnings.sh continues to parse.
#
# Spec anchor
#   "Living Evidence Counter" + "Proof-of-process beats proof-of-promise."
#
# Usage
#   From a hook or command (canonical pattern):
#     source ~/.claude/hooks/_learnings-emit.sh
#     emit_learning <event_type> <phase> <summary> [extra_field=value ...]
#
#   Or as an executable subcommand (when sourcing is impractical):
#     bash ~/.claude/hooks/_learnings-emit.sh <event_type> <phase> <summary>
#
#   event_type: phase-completed | phantom-fail | critic-fail | test-architect-veto | ...
#   phase:      phase id (e.g. "01") or "global"
#   summary:    one-line human-readable summary (no newlines)
#
# Format written to apex-learnings.md (in the WARM section, appended):
#   ### [EVT-<YYYY-MM-DD>-<event_type>] <summary>
#   - **Evidence count:** 1
#   - **Status:** ACTIVE
#   - **Decay:** framework
#   - **Verified:** YYYY-MM-DD
#   - **Event type:** <event_type>
#   - **Phase:** <phase>
#   - **Summary:** <summary>
#
# Contract
#   - Format chosen so verify-learnings.sh continues to parse:
#     - Has `### [` heading prefix and is in WARM section.
#     - Has `**Evidence count:** N` (>= 1) and `**Decay:** framework`
#       so the `MISSING EVIDENCE` and decay checks are satisfied.
#     - No bare `**Citation:**` line, so the stale-citation reader
#       is not tripped.
#   - Idempotent on event-id basis: repeated emits with the same
#     identical event_type+phase+summary in the same day still append
#     (the counter is intentionally append-only — the reader/aggregator
#     is responsible for de-duplication).

apex_learnings_file() {
  # Resolution order:
  #   1. APEX_LEARNINGS_FILE env var (explicit override; used by tests
  #      and by callers that want to write to a sandbox file).
  #   2. ~/.claude/apex-learnings.md (live install).
  #   3. ./apex-learnings.md fallback when neither is present.
  if [ -n "${APEX_LEARNINGS_FILE:-}" ]; then
    echo "$APEX_LEARNINGS_FILE"
  elif [ -d "$HOME/.claude" ]; then
    echo "$HOME/.claude/apex-learnings.md"
  else
    echo "./apex-learnings.md"
  fi
}

emit_learning() {
  local event_type="${1:-}"
  local phase="${2:-global}"
  local summary="${3:-}"
  if [ -z "$event_type" ] || [ -z "$summary" ]; then
    echo "🚫 emit_learning: event_type and summary are required" >&2
    return 2
  fi

  local file
  file=$(apex_learnings_file)
  local today
  today=$(date +%Y-%m-%d)

  # Bootstrap the file if missing — write a minimal header so
  # verify-learnings.sh's section-tracking still works.
  if [ ! -f "$file" ]; then
    mkdir -p "$(dirname "$file")"
    {
      echo "# APEX Learnings — Tiered Citation-Based Knowledge Base [v7]"
      echo ""
      echo "## HOT (max 30 — always loaded into architect context)"
      echo ""
      echo "## WARM (max 100 — loaded when stack/domain matches)"
      echo ""
    } > "$file"
  fi

  # Build the entry. Newline-safe: summary is single-line (callers
  # pass one-line strings; we strip newlines defensively).
  local clean_summary
  clean_summary=$(printf '%s' "$summary" | tr '\n' ' ' | tr -s ' ')
  local entry_id="EVT-${today}-${event_type}"

  # Append to the file. We do NOT try to find the WARM section header
  # and insert there — the file's tail is conventionally inside WARM
  # after enough emits. If the reader needs strict section ordering,
  # a future R can add a smarter inserter; for R5-019 we keep this
  # simple and append-only.
  {
    echo ""
    echo "### [${entry_id}] ${clean_summary}"
    echo "- **Evidence count:** 1"
    echo "- **Status:** ACTIVE"
    echo "- **Decay:** framework"
    echo "- **Verified:** ${today}"
    echo "- **Event type:** ${event_type}"
    echo "- **Phase:** ${phase}"
    echo "- **Summary:** ${clean_summary}"
  } >> "$file"
}

# Subcommand form — only fires when this file is executed (not sourced).
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  emit_learning "$@"
fi
