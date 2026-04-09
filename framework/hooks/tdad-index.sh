#!/bin/bash
# Builds code-test dependency graph for TDAD impact analysis
# Run once after architect creates plans, before Phase 01 execution

echo "🔬 TDAD: Building code-test dependency graph..."

if ! command -v python3 &>/dev/null; then
  echo "⚠️ TDAD: python3 not found — skipping dependency indexing"
  exit 0
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
    except:
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

# Create the impact analysis helper
cat > ~/.claude/hooks/tdad-impact.py << 'IMPACT_PY'
#!/usr/bin/env python3
"""TDAD Impact Analysis: given changed files, find impacted tests"""
import sys, os

def get_impacted_tests(changed_files_str, map_file='.apex/TEST_MAP.txt'):
    if not os.path.exists(map_file):
        return []

    changed = [f.strip() for f in changed_files_str.split() if f.strip()]
    impacted = set()

    try:
        with open(map_file) as f:
            for line in f:
                line = line.strip()
                if '|' not in line:
                    continue
                src, tests_str = line.split('|', 1)
                for changed_file in changed:
                    if changed_file in src or src in changed_file:
                        for t in tests_str.split(','):
                            if t.strip():
                                impacted.add(t.strip())
    except:
        pass

    return sorted(impacted)

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--files', required=True)
    parser.add_argument('--map', default='.apex/TEST_MAP.txt')
    args = parser.parse_args()

    tests = get_impacted_tests(args.files, args.map)

    if tests:
        output = '\n'.join(tests)
        with open('.apex/IMPACTED_TESTS.txt', 'w') as f:
            f.write(output)
        print(f"✅ TDAD: {len(tests)} impacted tests identified")
        print('\n'.join(tests))
    else:
        if os.path.exists('.apex/IMPACTED_TESTS.txt'):
            os.remove('.apex/IMPACTED_TESTS.txt')
        print("ℹ️ TDAD: No specific test dependencies found — using default verification")
IMPACT_PY

chmod +x ~/.claude/hooks/tdad-impact.py

exit 0