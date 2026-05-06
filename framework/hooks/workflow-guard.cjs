#!/usr/bin/env node
// workflow-guard.cjs — Node port of workflow-guard.sh.
//
// Spec anchor: apex-spec.md, Failure 9 — "apex-workflow-guard.js" in the
//   Defense-in-Depth Security Layer roster.
//
// Hook type
//   Auto-PreToolUse (Read) + explicit invocation by /apex:workflow.
//   Self-filters on path: scans only files under apex-workflows/.
//
// Behavior parity
//   Detection patterns are loaded from
//   framework/test-fixtures/security-patterns.json and are byte-equivalent
//   to the regex literals in workflow-guard.sh + _security-common.sh. Exit
//   code 2 on match (block), 0 on clean — same contract as the .sh.
//
// Input
//   1. CLI argv[2] — explicit file path (test invocation pattern).
//   2. stdin JSON  — Claude Code hook protocol; reads tool_input.file_path.
//
// R5-003 — Wave 5.

'use strict';

const fs = require('fs');
const sec = require('./security.cjs');

function extractFilePath() {
  const argv = process.argv.slice(2);
  if (argv.length > 0 && argv[0]) {
    return argv[0];
  }

  if (process.stdin.isTTY) return '';
  const raw = sec.readStdinSync();
  if (!raw) return '';
  const parsed = sec.parseHookStdin(raw);
  if (parsed && typeof parsed === 'object') {
    const ti = parsed.tool_input || {};
    return ti.file_path || '';
  }
  return '';
}

function main() {
  const filePath = extractFilePath();

  // Self-filter: only scan workflow recipe files. Instant exit for everything
  // else — non-workflow Read operations must not incur file I/O cost.
  if (filePath && !filePath.includes('apex-workflows/')) {
    process.exit(0);
  }

  if (!filePath) {
    // Parity with the .sh: when invoked with no arg and no stdin, exit 0
    // (auto-wired Reads on non-workflow paths). When invoked explicitly with
    // an empty arg by /apex:workflow we surface the "no file path" error,
    // but the auto-wired path never trips that.
    if (process.stdin.isTTY && process.argv.length > 2) {
      process.stderr.write('APEX WORKFLOW GUARD: No file path provided\n');
      process.exit(1);
    }
    process.exit(0);
  }

  if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
    process.stderr.write(`APEX WORKFLOW GUARD: File not found: ${filePath}\n`);
    process.exit(1);
  }

  const content = fs.readFileSync(filePath, 'utf8');
  const hit = sec.matchWorkflowInjection(content);
  if (hit) {
    sec.emitBlock('WORKFLOW GUARD', hit.name, `${hit.matched} in ${filePath}`);
    process.exit(2);
  }
  process.exit(0);
}

main();
