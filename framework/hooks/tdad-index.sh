#!/bin/bash
set -uo pipefail
# Builds code-test dependency graph for TDAD impact analysis
# Hook type: Auto-SessionStart + Auto-PostToolUse (Write|Edit, debounced) + Command-Invoked (R5-011)
# Run once after architect creates plans, before Phase 01 execution.
# Auto-SessionStart re-builds the index when a session starts.
# Auto-PostToolUse Write|Edit re-builds when a source file changes — debounced
# via the freshness guard below: if .apex/TEST_MAP.txt is newer than the most
# recent source file, exit 0 fast (no rebuild needed).

source "$(dirname "$0")/_require-git.sh"

# G-2: Ensure CWD is project root so .apex/ paths resolve.
# Outside a git repo (e.g. generic Claude sessions, SessionStart on a
# non-APEX directory): pass through silently — not our concern.
if ! ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
  exit 0
fi
cd "$ROOT" || exit 0

# R5-011: Freshness guard (debounce). When .apex/TEST_MAP.txt exists and is
# newer than the most recent source file under the repo, skip rebuild.
# Rationale: SessionStart fires this hook on every session; on hot caches
# (TEST_MAP fresh), we must exit 0 fast so SessionStart stays under 2s.
# Detection logic in the index builder below is unchanged — only this
# pre-flight guard is added.
if [ -f .apex/TEST_MAP.txt ]; then
  # Most recent source mtime among tracked source/test files. Limit to a
  # bounded set so the find call is fast on large repos.
  NEWEST_SRC=$(find . \
    \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
       -o -name "*.py" -o -name "*.test.ts" -o -name "*.test.tsx" \
       -o -name "*.spec.ts" -o -name "*.spec.tsx" \) \
    -not -path "./node_modules/*" -not -path "./.next/*" \
    -not -path "./.git/*" -not -path "./dist/*" \
    -newer .apex/TEST_MAP.txt -print -quit 2>/dev/null)
  if [ -z "$NEWEST_SRC" ]; then
    # Index is fresher than every source file — nothing to do.
    exit 0
  fi
fi

echo "🔬 TDAD: Building code-test dependency graph..."

if ! command -v python3 &>/dev/null; then
  echo "⚠️ TDAD: python3 not found — skipping dependency indexing"
  exit 1
fi

# Find all test files
TEST_FILES=$(find . -name "*.test.ts" -o -name "*.test.tsx" -o -name "*.spec.ts" \
  2>/dev/null | grep -v "node_modules\|.next" | head -200)

if [ -z "$TEST_FILES" ]; then
  echo "⚠️ TDAD: No test files found — graph will be empty"
  echo "" > .apex/TEST_MAP.txt
  exit 0
fi

# Build simple import-based dependency map
python3 - << 'PYEOF'
import os, re, json
from pathlib import Path

test_map = {}

# Find all test files
test_files = []
for root, dirs, files in os.walk('.'):
    dirs[:] = [d for d in dirs if d not in ['node_modules', '.next', '.git', 'dist']]
    for f in files:
        if f.endswith(('.test.ts', '.test.tsx', '.spec.ts', '.spec.tsx')):
            test_files.append(os.path.join(root, f))

# For each test file, find what source files it imports
for tf in test_files:
    try:
        content = open(tf).read()
        imports = re.findall(r"from ['\"]([^'\"]+)['\"]", content)
        imports += re.findall(r"require\(['\"]([^'\"]+)['\"]\)", content)
        src_files = []
        for imp in imports:
            if imp.startswith('.'):
                base = os.path.dirname(tf)
                resolved = os.path.normpath(os.path.join(base, imp))
                for ext in ['.ts', '.tsx', '.js', '/index.ts', '/index.tsx']:
                    candidate = resolved + ext if not resolved.endswith(ext) else resolved
                    if os.path.exists(candidate):
                        src_files.append(candidate.lstrip('./'))
                        break
        if src_files:
            test_map[tf.lstrip('./')] = src_files
    except Exception:
        pass

# Write the map: src_file -> [test_files]
reverse_map = {}
for test_file, src_files in test_map.items():
    for src in src_files:
        if src not in reverse_map:
            reverse_map[src] = []
        reverse_map[src].append(test_file)

with open('.apex/TEST_MAP.txt', 'w') as f:
    for src, tests in reverse_map.items():
        f.write(f"{src}|{','.join(tests)}\n")

print(f"✅ TDAD: Indexed {len(reverse_map)} source files → test mappings")
PYEOF

echo "✅ TDAD index complete: .apex/TEST_MAP.txt"

# Verify the impact analysis helper is deployed.
# tdad-impact.py is now a standalone file under framework/hooks/, synced by
# sync-to-claude.sh. Fail loud if it is missing — silently generating it at
# runtime (the previous behavior) hid deployment drift.
if [ ! -f ~/.claude/hooks/tdad-impact.py ]; then
  echo "🚫 APEX HOOK [tdad-index.sh]: ~/.claude/hooks/tdad-impact.py not found" >&2
  echo "   Run framework/scripts/sync-to-claude.sh to deploy hooks." >&2
  exit 2
fi

exit 0