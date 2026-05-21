#!/usr/bin/env bash
# Run the PinScope convergence-engine test suite.
#
# Uses Node's built-in test runner (`node --test`), NOT vitest — the engine
# tests live outside pinscope/tests/unit/ and are `.mjs`, so they can never
# be picked up by `npm test` or pollute ac-verify's AC-tag scan.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Explicit glob, not a directory argument — `node --test <dir>` mis-discovers
# in Node 22; an explicit file list runs every suite reliably.
node --test "$HERE"/*.test.mjs
