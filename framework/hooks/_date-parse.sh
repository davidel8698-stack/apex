#!/bin/bash
# _date-parse.sh — Portable date-to-epoch conversion.
# Sourced by hooks that need cross-platform date parsing.
# Fallback chain: GNU date -> BSD date -> Python3 -> Python2
parse_epoch() {
  local d="$1" fmt="${2:-%Y-%m-%dT%H:%M:%S}"
  date -d "$d" +%s 2>/dev/null && return 0
  date -j -f "$fmt" "${d%%.*}" +%s 2>/dev/null && return 0
  python3 -c "from datetime import datetime; print(int(datetime.strptime('${d%%.*}','$fmt').timestamp()))" 2>/dev/null && return 0
  python -c "from datetime import datetime; import calendar; dt=datetime.strptime('${d%%.*}','$fmt'); print(int(calendar.timegm(dt.timetuple())))" 2>/dev/null && return 0
  echo ""
}

# parse_epoch_selftest — Probe the fallback chain with a known-good ISO-8601
# timestamp and report which tier answered. Exit 0 on success, 1 on total failure.
# Output format (single line): "OK <tier>" or "FAIL <reason>".
# Tier names: gnu-date, bsd-date, python3, python2.
# Used by /apex:health-check TEST 0k and by /apex:start preflight (R3-009).
parse_epoch_selftest() {
  local probe="2026-04-23T12:00:00"
  local expected="1745409600"  # matches `date -u -d "2026-04-23T12:00:00Z" +%s` on GNU
  local out

  if out=$(date -d "$probe" +%s 2>/dev/null) && [ -n "$out" ]; then
    echo "OK gnu-date"
    return 0
  fi
  if out=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$probe" +%s 2>/dev/null) && [ -n "$out" ]; then
    echo "OK bsd-date"
    return 0
  fi
  if out=$(python3 -c "from datetime import datetime; print(int(datetime.strptime('$probe','%Y-%m-%dT%H:%M:%S').timestamp()))" 2>/dev/null) && [ -n "$out" ]; then
    echo "OK python3"
    return 0
  fi
  if out=$(python -c "from datetime import datetime; import calendar; dt=datetime.strptime('$probe','%Y-%m-%dT%H:%M:%S'); print(int(calendar.timegm(dt.timetuple())))" 2>/dev/null) && [ -n "$out" ]; then
    echo "OK python2"
    return 0
  fi

  echo "FAIL no date parser available (GNU/BSD date, python3, python all unusable). Install Python 3 from python.org."
  return 1
}

# When invoked directly (not sourced), run the selftest.
# Enables: bash framework/hooks/_date-parse.sh  →  OK <tier> / FAIL <reason>
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  parse_epoch_selftest
  exit $?
fi
