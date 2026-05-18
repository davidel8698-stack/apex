#!/bin/bash
set -u
# v7: Hardened against bypass — normalized matching, chained command splitting [R1]
# R1: 10 documented destructive incidents, 0 vendor postmortems
# Hook type: PreToolUse (Bash)
#
# R5-014: On block, source `_fix-plan-emit.sh` and write `.apex/FIX_PLAN.md`
# so the user has a concrete next-action plan. Detection / chained-command
# splitting / exit codes below are unchanged.

# shellcheck source=/dev/null
if [ -f "$(dirname "$0")/_fix-plan-emit.sh" ]; then
  source "$(dirname "$0")/_fix-plan-emit.sh"
fi

COMMAND="${1:-}"

# v7: Split chained commands and check each segment
# Handles: cmd1 && cmd2, cmd1 ; cmd2
check_segment() {
  local SEGMENT="$1"

  # v7.1 [B-7]: Strip quoted strings only from known-safe (read-only) commands.
  # This prevents false positives on echo "rm -rf /" or grep "DROP TABLE"
  # while preserving detection of psql -c "DROP TABLE users" (execution command).
  local STRIPPED="$SEGMENT"
  local FIRST_WORD
  FIRST_WORD=$(echo "$SEGMENT" | sed 's/^ *//' | cut -d' ' -f1)
  case "$FIRST_WORD" in
    echo|printf|grep|egrep|fgrep|rg|sed|awk|cat|head|tail|wc|sort|uniq|diff|test|\[)
      # Read-only commands: quoted args are data, not execution — safe to strip
      STRIPPED=$(echo "$SEGMENT" | sed 's/"[^"]*"//g; s/'"'"'[^'"'"']*'"'"'//g')
      ;;
  esac

  # Normalize: collapse whitespace, lowercase for matching
  local NORMALIZED
  NORMALIZED=$(echo "$STRIPPED" | tr -s ' ' | sed 's/^ *//;s/ *$//')

  # === DENY PATTERNS (exact and regex) ===

  # Destructive rm patterns — normalize flags then check for recursive+force combo
  if echo "$NORMALIZED" | grep -qiE "^rm\s+" 2>/dev/null; then
    local HAS_RECURSIVE=0 HAS_FORCE=0 HAS_DANGEROUS_TARGET=0
    # Check all flag forms: -r, -R, --recursive, embedded in combined flags like -rf
    if echo "$NORMALIZED" | grep -qiE "(-[a-zA-Z]*[rR]|--recursive)" 2>/dev/null; then HAS_RECURSIVE=1; fi
    if echo "$NORMALIZED" | grep -qiE "(-[a-zA-Z]*f|--force)" 2>/dev/null; then HAS_FORCE=1; fi
    if echo "$NORMALIZED" | grep -qE "\s(/|~|\.\.|\.|\*)" 2>/dev/null; then HAS_DANGEROUS_TARGET=1; fi
    if [ "$HAS_RECURSIVE" -eq 1 ] && [ "$HAS_FORCE" -eq 1 ] && [ "$HAS_DANGEROUS_TARGET" -eq 1 ]; then
      block "$SEGMENT" "rm with recursive+force on dangerous target"
      return 1
    fi
  fi

  # Git destructive operations
  if echo "$NORMALIZED" | grep -qiE "git\s+(reset\s+--hard|clean\s+-[a-zA-Z]*f)" 2>/dev/null; then
    block "$SEGMENT" "git reset --hard / git clean -f"
    return 1
  fi

  # v7: git push --force (all variants)
  if echo "$NORMALIZED" | grep -qiE "git\s+push\s+(-[a-zA-Z]*f|--force|--force-with-lease)" 2>/dev/null; then
    block "$SEGMENT" "git push --force"
    return 1
  fi

  # SQL destructive operations
  if echo "$NORMALIZED" | grep -qiE "(DROP\s+(TABLE|DATABASE|SCHEMA|INDEX)|TRUNCATE\s+TABLE)" 2>/dev/null; then
    block "$SEGMENT" "SQL DROP/TRUNCATE"
    return 1
  fi

  # v7: ALTER TABLE DROP (column/constraint drops)
  if echo "$NORMALIZED" | grep -qiE "ALTER\s+TABLE\s+.*\s+DROP\s+" 2>/dev/null; then
    block "$SEGMENT" "ALTER TABLE DROP"
    return 1
  fi

  # v7: DELETE FROM without WHERE (mass deletion)
  if echo "$NORMALIZED" | grep -qiE "DELETE\s+FROM\s+" 2>/dev/null; then
    if ! echo "$NORMALIZED" | grep -qiE "WHERE\s+" 2>/dev/null; then
      block "$SEGMENT" "DELETE FROM without WHERE clause"
      return 1
    fi
  fi

  # Infrastructure destruction
  if echo "$NORMALIZED" | grep -qiE "(terraform\s+destroy|kubectl\s+delete\s+namespace)" 2>/dev/null; then
    block "$SEGMENT" "infrastructure destruction"
    return 1
  fi

  # System-level destruction
  if echo "$NORMALIZED" | grep -qiE "(docker\s+system\s+prune\s+-[a-zA-Z]*a[a-zA-Z]*f|chmod\s+-R\s+777|mkfs\.|>\s*/dev/sd|dd\s+if=/dev/zero)" 2>/dev/null; then
    block "$SEGMENT" "system-level destructive command"
    return 1
  fi

  # Fork bomb
  if echo "$NORMALIZED" | grep -q ':(){ :|:& };:' 2>/dev/null; then
    block "$SEGMENT" "fork bomb"
    return 1
  fi

  # rm -rf with parent directory traversal
  if echo "$NORMALIZED" | grep -qE "rm\s+(-[a-zA-Z]*r[a-zA-Z]*|--recursive)\s+\.\." 2>/dev/null; then
    block "$SEGMENT" "rm -rf with parent directory traversal"
    return 1
  fi

  # R16-609 (F-609, IMP-008): git-config tamper primitives — persistence vector
  # for cover-up attacks (Mythos §4.5.4.1). Pairs with critic STEP 1.5 GIT TRACE
  # VERIFICATION (R16-603) which assumes git itself is uncompromised.
  # Pattern set: core.fsmonitor (hooks every fs op), core.hooksPath (relocates
  # hook dir), git alias (core.alias-family) with leading ! shell escape, writes to .git/hooks/,
  # .git/config, ~/.gitconfig, /etc/gitconfig, and `git -c core.<name>=` overrides.
  # Carve-out: legitimate `git config user.email` / `user.name` / `core.editor`
  # are NOT in this pattern set.
  if echo "$NORMALIZED" | grep -qiE "git\s+config\s+(--global\s+|--system\s+|--local\s+)*core\.fsmonitor" 2>/dev/null; then
    block "$SEGMENT" "git config core.fsmonitor (cover-up persistence)"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qiE "git\s+config\s+(--global\s+|--system\s+|--local\s+)*core\.hooksPath" 2>/dev/null; then
    block "$SEGMENT" "git config core.hooksPath (hook relocation)"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qE "git\s+config\s+(--global\s+|--system\s+|--local\s+)*alias\.[^=]*=['\"]!" 2>/dev/null; then
    block "$SEGMENT" "git alias with shell escape (! prefix)"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qE "(>|>>|tee)\s+([^|]*\s+)?(\.git/hooks/|\.git/config|~/\.gitconfig|/etc/gitconfig)" 2>/dev/null; then
    block "$SEGMENT" "direct write to git config / hook dir"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qiE "git\s+-c\s+core\.[a-zA-Z]+=[^[:space:]]+" 2>/dev/null; then
    block "$SEGMENT" "git -c core.<name>= override"
    return 1
  fi

  # R16-612 (F-612, IMP-002): process-memory introspection — credential
  # extraction attack surface. Two-tier coverage:
  #   DENY (exit 2): /proc/<pid>/(mem|environ|fd|maps|stat), /dev/(mem|kmem|kcore),
  #     gdb -p / --pid / attach, dd if=/proc/* / of=/dev/(mem|kmem),
  #     ptrace, strace -p, LD_PRELOAD= environment override.
  #   ADVISORY (exit 1): cat /proc/<pid>/maps and /sys/class/net/ reads —
  #     legitimate-ish but suspicious; warn-not-block.
  # Pairs with apex-prompt-guard.cjs encoded_bypass_patterns (R16-617P).
  # Carve-outs: LD_PRELOAD is constrained to the `^LD_PRELOAD=` form so env-var
  # discussions in prose / comments don't trigger.

  # DENY tier
  if echo "$NORMALIZED" | grep -qE "/proc/[0-9]+/(mem|environ|fd|maps|stat)\b" 2>/dev/null; then
    block "$SEGMENT" "/proc/<pid>/(mem|environ|fd|maps|stat) — process-memory introspection"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qE "/dev/(mem|kmem|kcore)\b" 2>/dev/null; then
    block "$SEGMENT" "/dev/(mem|kmem|kcore) — raw kernel memory access"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qiE "\bgdb\s+(-p|--pid|attach)\b" 2>/dev/null; then
    block "$SEGMENT" "gdb -p / --pid / attach — debugger attach"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qiE "\bdd\s+(if=/proc/|of=/dev/(mem|kmem))" 2>/dev/null; then
    block "$SEGMENT" "dd if=/proc/* or of=/dev/(mem|kmem) — memory copy"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qiE "\bptrace\b" 2>/dev/null; then
    block "$SEGMENT" "ptrace — process tracing primitive"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qiE "\bstrace\s+-p\b" 2>/dev/null; then
    block "$SEGMENT" "strace -p — attach to running process"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qE "(^|[[:space:];&|])LD_PRELOAD=" 2>/dev/null; then
    block "$SEGMENT" "LD_PRELOAD= — dynamic linker override"
    return 1
  fi

  # R16-613 (F-613, IMP-014): mass-effect destructive patterns — operations
  # that affect a wide blast radius in a single call (process trees, container
  # fleets, namespace-wide deletes, recursive find -delete / -exec rm). All
  # block (exit 2).
  # Pattern set: pkill -f, killall, pkill -[09], kubectl delete ... --all,
  # kubectl delete ... -A, docker kill $(docker ps -aq),
  # docker rm -f $(docker ps -aq), find ... -delete, find ... -exec rm,
  # rm -rf * / rm -rf .*  (handled here when not caught by the earlier rm
  # block — e.g. when the dangerous-target shape is the bare glob).
  # Carve-out: legitimate test-cleanup scripts run under
  # APEX_ACTIVE_AGENT=test-architect bypass via the exfil-guard convention;
  # this hook does not honor that variable (defense-in-depth — destructive-
  # guard is the last line). Document the carve-out for operators.
  if echo "$NORMALIZED" | grep -qiE "\bpkill\s+(-[0-9]+\s+)?(-f\b|-[a-zA-Z]*f\b)" 2>/dev/null; then
    block "$SEGMENT" "pkill -f — mass process kill by pattern"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qiE "\bkillall\b" 2>/dev/null; then
    block "$SEGMENT" "killall — mass process kill by name"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qiE "\bpkill\s+-(0|9)\b" 2>/dev/null; then
    block "$SEGMENT" "pkill -0 / pkill -9 — process probe / mass-kill signal"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qiE "kubectl\s+delete\s+\S+\s+.*(--all\b|\s-A\b|\s--all-namespaces\b)" 2>/dev/null; then
    block "$SEGMENT" "kubectl delete <resource> --all / -A — namespace-wide delete"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qE "docker\s+(kill|rm\s+-f)\s+\\\$\(\s*docker\s+ps\s+-aq" 2>/dev/null; then
    block "$SEGMENT" "docker kill/rm -f \$(docker ps -aq) — container fleet wipe"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qiE "\bfind\b.*\s-delete\b" 2>/dev/null; then
    block "$SEGMENT" "find ... -delete — recursive deletion via find"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qiE "\bfind\b.*\s-exec\s+rm\b" 2>/dev/null; then
    block "$SEGMENT" "find ... -exec rm — recursive deletion via find -exec"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qE "\brm\s+-[a-zA-Z]*rf[a-zA-Z]*\s+(\*|\.\*)(\s|$)" 2>/dev/null; then
    block "$SEGMENT" "rm -rf * / rm -rf .* — glob-wide mass delete"
    return 1
  fi

  # R16-617D (F-617, IMP-017): encoded-command bypass — block payloads that
  # decode a base64/hex string and pipe the result into a shell or interpreter.
  # Pair with apex-prompt-guard.cjs encoded_bypass_patterns (R16-617P) for
  # layered defense (prompt-side blocks the prompt itself; this hook blocks
  # the executed command when the bypass still reaches Bash). The
  # discriminator is the pipe target — base64-decoding to a *file* or
  # variable is legitimate; piping to bash/sh/python/node is the attack
  # primitive Mythos §4.5.4.4 (cover-up vector) calls out.
  #
  # Pattern families:
  #   * `echo ... | base64 -d | (bash|sh|python|node|perl|ruby)` — classic.
  #   * `eval "$(echo ... | base64 -d)"` — eval-wrapped variant.
  #   * `python -c "...base64.b64decode..."` — in-language decode and exec.
  #   * `node -e "...Buffer.from(..., 'base64').toString()..."` — JS variant.
  #   * `printf ... | xxd -r -p | (bash|sh|...)` — hex-decode variant.
  # Carve-out: `base64 -d > file.bin`, `b64decode` to a non-exec sink is
  # *not* matched — these patterns require the shell/interpreter target.
  if echo "$NORMALIZED" | grep -qiE "base64\s+(-d|--decode|-D)\b.*\|\s*(bash|sh|zsh|ksh|dash|python[0-9.]*|node|perl|ruby|php)\b" 2>/dev/null; then
    block "$SEGMENT" "base64 -d | shell-interpreter — encoded-command bypass"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qiE "eval\s+(\\\$\(|\")?\s*echo\b.*\|\s*base64\s+(-d|--decode|-D)\b" 2>/dev/null; then
    block "$SEGMENT" "eval \$(echo ... | base64 -d) — encoded-command bypass"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qE "python[0-9.]*\s+-c\s+.*base64\.b64decode" 2>/dev/null; then
    block "$SEGMENT" "python -c base64.b64decode — in-language decode"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qE "node\s+-e\s+.*Buffer\.from.*['\"]base64['\"]" 2>/dev/null; then
    block "$SEGMENT" "node -e Buffer.from(..., 'base64') — in-language decode"
    return 1
  fi
  if echo "$NORMALIZED" | grep -qiE "(printf|echo)\b.*\|\s*xxd\s+-r\s+-p\b.*\|\s*(bash|sh|zsh|ksh|dash|python[0-9.]*|node|perl|ruby|php)\b" 2>/dev/null; then
    block "$SEGMENT" "xxd -r -p | shell-interpreter — hex-decoded bypass"
    return 1
  fi

  # ADVISORY tier — emits to stderr, does not block. Sets ADVISORY=1 so the
  # outer dispatcher exits 1 instead of 0 (per IMP-002 two-tier contract).
  if echo "$NORMALIZED" | grep -qE "cat\s+/proc/[0-9]+/maps\b" 2>/dev/null; then
    echo "⚠️  APEX DESTRUCTIVE GUARD (advisory): cat /proc/<pid>/maps — memory map read" >&2
    echo "Segment: $SEGMENT" >&2
    ADVISORY=1
  fi
  if echo "$NORMALIZED" | grep -qE "/sys/class/net/" 2>/dev/null; then
    echo "⚠️  APEX DESTRUCTIVE GUARD (advisory): /sys/class/net/ read" >&2
    echo "Segment: $SEGMENT" >&2
    ADVISORY=1
  fi

  return 0
}

block() {
  echo "🛑 APEX DESTRUCTIVE GUARD: BLOCKED"
  echo "Command segment: $1"
  echo "Matched: $2"
  echo ""
  echo "This command is on APEX's deny-list. It cannot be executed."
  echo "If you believe this is a false positive, use the manual terminal."
  # R5-014: structured fix plan
  if command -v emit_fix_plan >/dev/null 2>&1; then
    emit_fix_plan \
      "destructive-guard" \
      "Destructive command was blocked because the segment matched a deny pattern: $2." \
      "Blocked segment: $1" \
      "/apex:forensics -- inspect the chain that led to this command" \
      "/apex:rollback -- revert recent edits to the last green tag" \
      "/apex:recover -- reset and re-plan without the destructive op" \
      2>/dev/null || true
  fi
}

# v7: Split on && and ; — check each segment independently
# This prevents bypass via: innocent_cmd && rm -rf /
# Note: pipes (|) are data flow, not command chains — not split
#
# v7.1 [B-7]: Quote-aware splitting. Naive sed split on && and ; breaks
# inside quoted strings (e.g., echo "a && b" would be split incorrectly).
# Solution: pure-bash state machine that tracks single/double quote context.
BLOCKED=0
# R16-612 (F-612, IMP-002): advisory tier flag — set by check_segment when an
# advisory-class pattern matches; surfaces as exit 1 below (no block).
ADVISORY=0

# Quote-aware command splitter: splits on unquoted && and ;
_split_commands() {
  local cmd="$1"
  local len=${#cmd}
  local i=0
  local in_single=0
  local in_double=0
  local current=""

  while [ $i -lt $len ]; do
    local c="${cmd:$i:1}"
    local next="${cmd:$((i+1)):1}"

    if [ "$c" = "'" ] && [ $in_double -eq 0 ]; then
      in_single=$(( 1 - in_single ))
      current+="$c"
    elif [ "$c" = '"' ] && [ $in_single -eq 0 ]; then
      in_double=$(( 1 - in_double ))
      current+="$c"
    elif [ "$c" = "\\" ] && [ $in_single -eq 0 ] && [ $((i+1)) -lt $len ]; then
      # Escaped character — skip next char
      current+="$c$next"
      i=$((i+1))
    elif [ $in_single -eq 0 ] && [ $in_double -eq 0 ]; then
      if [ "$c" = ";" ]; then
        echo "$current"
        current=""
      elif [ "$c" = "&" ] && [ "$next" = "&" ]; then
        echo "$current"
        current=""
        i=$((i+1))  # skip second &
      else
        current+="$c"
      fi
    else
      current+="$c"
    fi
    i=$((i+1))
  done
  # Emit last segment
  [ -n "$current" ] && echo "$current"
}

mapfile -t SEGMENT_ARRAY < <(_split_commands "$COMMAND")

for segment in "${SEGMENT_ARRAY[@]}"; do
  segment=$(echo "$segment" | sed 's/^ *//;s/ *$//')
  [ -z "$segment" ] && continue
  if ! check_segment "$segment"; then
    BLOCKED=1
    break
  fi
done

if [ "$BLOCKED" -eq 1 ]; then
  exit 2
fi

# R16-612: advisory-tier match surfaces as exit 1 (warn-not-block).
if [ "$ADVISORY" -eq 1 ]; then
  exit 1
fi

exit 0