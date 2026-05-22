#!/usr/bin/env bash
# Canonical artifact-naming for the PinScope PS-R{N} convergence loop.
#
# Source this file, then call:  round_path <kind> <N>
#
# Kinds:
#   audit-md        audit-findings-R{N}.md
#   audit-json      audit-findings-R{N}.json
#   narrative-md    narrative-scan-R{N}.md
#   narrative-json  narrative-scan-R{N}.json
#   remediation     REMEDIATION-PLAN-R{N}.md
#   waves           WAVES-R{N}.md
#   wave-result     WAVE-R{N}-RESULT.md
#   verify          VERIFY-R{N}.md
#   test-audit      TEST-AUDIT-R{N}.md
#   closure         ROUND-R{N}-CLOSURE.md
#   ac-results      ac-results-R{N}.json
#
# Every artifact uses the uniform `-R{N}` infix — this kills the
# WAVE-1-RESULT vs WAVE-R2-RESULT drift seen in the original 9-round run.
# (Round-1 legacy files keep their old names; renaming them is churn.)

CONV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

round_path() {
  local kind="$1" n="$2"
  if [ -z "$kind" ] || [ -z "$n" ]; then
    echo "round_path: usage: round_path <kind> <N>" >&2
    return 1
  fi
  case "$kind" in
    audit-md)       echo "${CONV_DIR}/audit-findings-R${n}.md" ;;
    audit-json)     echo "${CONV_DIR}/audit-findings-R${n}.json" ;;
    narrative-md)   echo "${CONV_DIR}/narrative-scan-R${n}.md" ;;
    narrative-json) echo "${CONV_DIR}/narrative-scan-R${n}.json" ;;
    remediation) echo "${CONV_DIR}/REMEDIATION-PLAN-R${n}.md" ;;
    waves)       echo "${CONV_DIR}/WAVES-R${n}.md" ;;
    wave-result) echo "${CONV_DIR}/WAVE-R${n}-RESULT.md" ;;
    verify)      echo "${CONV_DIR}/VERIFY-R${n}.md" ;;
    test-audit)  echo "${CONV_DIR}/TEST-AUDIT-R${n}.md" ;;
    closure)     echo "${CONV_DIR}/ROUND-R${n}-CLOSURE.md" ;;
    ac-results)  echo "${CONV_DIR}/ac-results-R${n}.json" ;;
    *) echo "round_path: unknown kind '${kind}'" >&2; return 1 ;;
  esac
}
