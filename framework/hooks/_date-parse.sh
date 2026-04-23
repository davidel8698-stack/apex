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
