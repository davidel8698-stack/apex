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
    except Exception as e:
        print(f"⚠️ TDAD: Error reading {map_file}: {e}", file=sys.stderr)

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
        try:
            os.remove('.apex/IMPACTED_TESTS.txt')
        except FileNotFoundError:
            pass
        print("ℹ️ TDAD: No specific test dependencies found — using default verification")
