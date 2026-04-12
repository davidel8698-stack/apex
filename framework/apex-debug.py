#!/usr/bin/env python3
"""APEX Standalone Diagnostic Tool.

Usage: python3 apex-debug.py [project_root]

Reads .apex/ state files and reports diagnostics without requiring a Claude session.
When APEX is broken, use this tool to debug without relying on the broken system.

No external dependencies — stdlib only.
"""

import json
import os
import sys
import glob


def read_json(path):
    """Read and parse a JSON file. Returns None if missing or invalid."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return None


def read_tail(path, lines=10):
    """Read last N lines of a text file. Returns empty list if missing."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            all_lines = f.readlines()
            return all_lines[-lines:]
    except (FileNotFoundError, OSError):
        return []


def report_state(root):
    """Report current phase, task, and circuit breaker status from STATE.json."""
    state = read_json(os.path.join(root, ".apex", "STATE.json"))
    if not state:
        print("  STATE.json: NOT FOUND or invalid")
        return

    print(f"  Project:         {state.get('project_name', '?')}")
    print(f"  Current phase:   {state.get('current_phase', '?')}")
    print(f"  Current task:    {state.get('current_task', '?')}")
    print(f"  Pipeline:        {state.get('pipeline', '?')}")
    print(f"  Complexity:      {state.get('complexity_level', '?')}")

    cb = state.get("circuit_breaker", {})
    if cb:
        trips = cb.get("consecutive_failures", 0)
        tripped = cb.get("tripped", False)
        print(f"  Circuit breaker: {'TRIPPED' if tripped else 'OK'} (failures: {trips})")
    else:
        print("  Circuit breaker: no data")

    spec_ver = state.get("spec_version", None)
    if spec_ver:
        print(f"  Spec version:    {spec_ver[:16]}...")

    pm = state.get("proposals_mode", None)
    if pm is not None:
        print(f"  Proposals mode:  {pm}")


def report_budget(root):
    """Report token usage from CONTEXT_BUDGET.json."""
    budget = read_json(os.path.join(root, ".apex", "CONTEXT_BUDGET.json"))
    if not budget:
        print("  CONTEXT_BUDGET.json: NOT FOUND or invalid")
        return

    used = budget.get("tokens_used", "?")
    limit = budget.get("token_limit", "?")
    pct = ""
    if isinstance(used, (int, float)) and isinstance(limit, (int, float)) and limit > 0:
        pct = f" ({used / limit * 100:.0f}%)"
    print(f"  Tokens used:     {used} / {limit}{pct}")

    sessions = budget.get("session_count", "?")
    print(f"  Sessions:        {sessions}")


def report_session_log(root):
    """Show last 10 entries from SESSION-LOG.md."""
    lines = read_tail(os.path.join(root, ".apex", "SESSION-LOG.md"), 10)
    if not lines:
        print("  SESSION-LOG.md: NOT FOUND or empty")
        return

    for line in lines:
        stripped = line.rstrip()
        if stripped:
            print(f"  {stripped}")


def report_phases(root):
    """Show status of each phase from PLAN_META.json files."""
    phases_dir = os.path.join(root, ".apex", "phases")
    if not os.path.isdir(phases_dir):
        print("  No phases directory found")
        return

    phase_dirs = sorted(glob.glob(os.path.join(phases_dir, "*")))
    if not phase_dirs:
        print("  No phases found")
        return

    for pd in phase_dirs:
        if not os.path.isdir(pd):
            continue
        phase_name = os.path.basename(pd)
        meta = read_json(os.path.join(pd, "PLAN_META.json"))
        if meta:
            tasks = meta.get("tasks", [])
            total = len(tasks)
            done = sum(1 for t in tasks if t.get("status") == "done")
            print(f"  Phase {phase_name}: {done}/{total} tasks done")
        else:
            files = os.listdir(pd)
            print(f"  Phase {phase_name}: no PLAN_META.json ({len(files)} files)")


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else "."
    apex_dir = os.path.join(root, ".apex")

    print("=" * 50)
    print("  APEX Diagnostic Report")
    print("=" * 50)

    if not os.path.isdir(apex_dir):
        print(f"\n  ERROR: No .apex/ directory found at {os.path.abspath(root)}")
        print("  Run this from the project root or pass the path as argument.")
        sys.exit(1)

    print("\n--- State ---")
    report_state(root)

    print("\n--- Token Budget ---")
    report_budget(root)

    print("\n--- Phases ---")
    report_phases(root)

    print("\n--- Session Log (last 10 lines) ---")
    report_session_log(root)

    print("\n" + "=" * 50)


if __name__ == "__main__":
    main()
