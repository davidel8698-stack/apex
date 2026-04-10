#!/usr/bin/env bash
# Guard: fail loud if git is not available or not inside a git repository.
# Source this from any hook that uses git commands.
# Parallel to _require-jq.sh — one concern per helper.

_require_git() {
  if ! command -v git &>/dev/null; then
    echo "🚫 APEX: git not found in PATH (required by $(basename "${BASH_SOURCE[1]:-$0}"))" >&2
    exit 2
  fi
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "🚫 APEX: not inside a git repository (required by $(basename "${BASH_SOURCE[1]:-$0}"))" >&2
    exit 2
  fi
}

_require_git
