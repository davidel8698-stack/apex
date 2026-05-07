#!/usr/bin/env bash
# APEX Test Utilities — shared IO defenses for the framework test suite.
#
# Companion file to `_harness.sh`. Where `_harness.sh` owns counter
# aggregation and assertion helpers, `_test-utils.sh` owns IO-safety
# helpers — primarily defenses against Windows-host CRLF contamination
# in JSON read paths.
#
# R7-009 / spec anchor: "Multi-platform from day one." A test that
# silently inherits CRLF flakiness on Windows is a multi-platform
# contract violation. Codifying the defense here so every test author
# inherits a safe default — instead of rediscovering `jq -r | tr -d
# '\r'` after the bug bites.
#
# Usage from a test file:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/_test-utils.sh"
#   while IFS=$'\t' read -r col1 col2; do ... ; done < <(jq_lines '.x[] | "\(.a)\t\(.b)"' file.json)
#
# Standalone-execution contract: this file is `source`-only. It declares
# functions and exports nothing else. Sourcing inside a subshell-wrapped
# test (per R7-001) inherits the function definitions for the lifetime
# of that subshell — exactly the same pattern `_harness.sh` already
# relies on.

# jq_lines — jq -r wrapper that strips CR from output so `read` loops
# behave consistently across LF and CRLF environments.
#
# Args:
#   $1 ... $N — passed verbatim to `jq -r`. The last positional argument
#               is conventionally the JSON file path; everything before
#               it is jq syntax (filter, --arg pairs, etc.).
#
# Behaviour:
#   - On Linux/macOS hosts (LF input) the `tr -d '\r'` is a no-op.
#   - On Windows hosts where jq emits CR-terminated lines (e.g. when
#     reading a CRLF-tainted JSON), `tr -d '\r'` strips them so that
#     downstream `IFS=$'\t' read` parsing splits on the intended
#     delimiter rather than letting a stray \r contaminate the last
#     field.
#   - Preserves jq's own exit code via PIPESTATUS so callers can still
#     branch on jq failure when set -o pipefail is in effect.
#
# This is intentionally a thin wrapper. Tests that need richer error
# handling can call `jq` directly; the wrapper exists because the
# CRLF-strip is the one defense every multi-line jq read should adopt.
jq_lines() {
  jq -r "$@" | tr -d '\r'
  # Return the jq exit code (left of the pipe) so pipefail-aware callers
  # can detect jq failures distinct from tr noop success.
  return ${PIPESTATUS[0]:-0}
}
