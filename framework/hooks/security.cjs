// security.cjs — APEX Defense-in-Depth Security Layer (CommonJS module).
//
// Spec anchor: apex-spec.md, Failure 9 — "Defense-in-Depth Security Layer:
//   apex-prompt-guard.js, Path Traversal Prevention, apex-workflow-guard.js,
//   CI scanner, security.cjs module."
//
// Role
//   Single source of truth for input normalization, zero-width-character
//   stripping, prompt-injection / workflow-injection pattern detection, and
//   block-response formatting for the .cjs guard hooks (apex-prompt-guard.cjs,
//   apex-workflow-guard.cjs; R6-014 added the `apex-` prefix to both ported
//   guards to match the spec literal naming). Keeps the .cjs guards behavior-identical to the
//   pre-existing .sh guards (prompt-guard.sh, workflow-guard.sh,
//   _security-common.sh).
//
// Constraints
//   - Zero npm dependencies. Pure Node.js standard library (fs, path).
//   - No top-level side effects. Importable by tests.
//   - Patterns are loaded from framework/test-fixtures/security-patterns.json
//     so the .sh and .cjs implementations cannot drift.
//
// R5-003 — Wave 5.

'use strict';

const fs = require('fs');
const path = require('path');

// ---- Pattern fixture loader ------------------------------------------------

function _resolveFixturePath() {
  // 1. Live-install path: ~/.claude/test-fixtures/security-patterns.json
  //    (delivered by framework/scripts/sync-to-claude.sh).
  // 2. Framework source-of-truth path:
  //    framework/test-fixtures/security-patterns.json (used during dev/CI).
  // 3. Override path: APEX_SECURITY_FIXTURE env var (used by tests).

  if (process.env.APEX_SECURITY_FIXTURE && fs.existsSync(process.env.APEX_SECURITY_FIXTURE)) {
    return process.env.APEX_SECURITY_FIXTURE;
  }

  const candidates = [];
  // Sibling-of-this-file: when delivered to ~/.claude/hooks/, the test-fixtures
  // tree lives at ~/.claude/test-fixtures/
  candidates.push(path.resolve(__dirname, '..', 'test-fixtures', 'security-patterns.json'));
  // Framework dev path: framework/test-fixtures/security-patterns.json
  candidates.push(path.resolve(__dirname, '..', 'test-fixtures', 'security-patterns.json'));

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }
  return null;
}

let _cachedPatterns = null;

function loadPatterns() {
  if (_cachedPatterns) return _cachedPatterns;
  const fixturePath = _resolveFixturePath();
  if (!fixturePath) {
    // Fail-loud: spec mandates fail-loud, never fail-silent.
    throw new Error('APEX SECURITY: pattern fixture not found (looked for test-fixtures/security-patterns.json)');
  }
  const raw = fs.readFileSync(fixturePath, 'utf8');
  _cachedPatterns = JSON.parse(raw);
  return _cachedPatterns;
}

// ---- Normalization (parity with _sec_normalize) ----------------------------

// Strip zero-width chars: U+200B, U+200C, U+200D, U+FEFF, U+00AD.
// Then collapse runs of whitespace into single spaces (parity with `tr -s '[:space:]' ' '`).
function normalize(input) {
  if (input === null || input === undefined) return '';
  const stripped = String(input).replace(/[​‌‍﻿­]/g, '');
  return stripped.replace(/[\s]+/g, ' ');
}

// Detect zero-width chars in raw (un-normalized) text.
function hasZeroWidthChars(input) {
  if (input === null || input === undefined) return false;
  return /[​‌‍﻿­]/.test(String(input));
}

// ---- Pattern matching ------------------------------------------------------

function _patternToRegExp(p) {
  let flags = '';
  if (p.case_insensitive) flags += 'i';
  if (p.multiline) flags += 'm';
  return new RegExp(p.pattern, flags);
}

// R16-611 (F-611, IMP-003): arg-content validation. Three tiers:
//   1. path-arg dispatch — args named path/filename/file/file_path: reject
//      shell metachars and CR/LF.
//   2. name-arg dispatch — args named name/title/description: reject role
//      markers (<|im_start|>, [INST], ### System, Assistant:).
//   3. length-threshold advisory — name-typed args >1000 chars: warn-not-block
//      via stderr. Returns { advisory: <msg> } so the caller emits the
//      advisory without blocking.
// Returns: null on clean; { name, matched } on block; { advisory } on warn.
// Caller (apex-prompt-guard.cjs) interprets advisory as "emit and continue".
function matchArgContent(argName, value) {
  if (!argName || value === null || value === undefined) return null;
  const cfg = loadPatterns();
  const valStr = String(value);
  const lowerName = argName.toLowerCase();

  // Path-arg block patterns
  if (Array.isArray(cfg.path_arg_patterns)) {
    for (const p of cfg.path_arg_patterns) {
      const names = (p.applies_to_arg_names || []).map(n => n.toLowerCase());
      if (!names.includes(lowerName)) continue;
      const re = _patternToRegExp(p);
      if (re.test(valStr)) {
        return { name: p.name, matched: p.matched_message };
      }
    }
  }

  // Name-arg block patterns — R17-645 (F-645, IMP-003 + IMP-020):
  // canonical source is role_marker_patterns.patterns[] (the same list
  // critic PRE-PROCESSING reads). matchArgContent derives its candidate
  // set from that list with default applies_to_arg_names of
  // ['name','title','description'] when a pattern does not specify its
  // own scope. Adding a pattern to role_marker_patterns now propagates
  // to BOTH critic PRE-PROCESSING (R16-620C) AND this arg-name
  // dispatch — single source of truth, no drift surface.
  const rolePatterns = cfg.role_marker_patterns && Array.isArray(cfg.role_marker_patterns.patterns)
    ? cfg.role_marker_patterns.patterns
    : null;
  if (rolePatterns) {
    for (const p of rolePatterns) {
      const names = (p.applies_to_arg_names || ['name', 'title', 'description'])
        .map(n => n.toLowerCase());
      if (!names.includes(lowerName)) continue;
      const re = _patternToRegExp(p);
      if (re.test(valStr)) {
        return { name: p.name, matched: p.matched_message };
      }
    }
  }

  // Length-threshold advisory (warn, not block)
  const lt = cfg.length_threshold_advisory;
  if (lt && Array.isArray(lt.applies_to_arg_names)) {
    const names = lt.applies_to_arg_names.map(n => n.toLowerCase());
    if (names.includes(lowerName) && valStr.length > (lt.threshold_chars || 1000)) {
      return { advisory: `${lt.name}: ${argName}=${valStr.length} chars > ${lt.threshold_chars}` };
    }
  }

  return null;
}

// Run all prompt_injection_patterns over normalized text. Returns the first
// match descriptor { name, matched_message } or null.
function matchPromptInjection(text) {
  const cfg = loadPatterns();
  const norm = normalize(text);
  for (const p of cfg.prompt_injection_patterns) {
    const re = _patternToRegExp(p);
    if (re.test(norm)) {
      return { name: p.name, matched: p.matched_message };
    }
  }
  return null;
}

// R16-617P (F-617, IMP-017): encoded-command bypass detection. Pairs with
// destructive-guard.sh R16-617D for layered defense. Patterns target
// echo-base64-pipe-shell, eval-base64, python -c base64.b64decode,
// node -e Buffer.from(..,'base64'), and printf | xxd -r -p | <shell>.
// Pattern source: security-patterns.json `encoded_bypass_patterns` (single
// source of truth shared with the .sh sibling). Returns { name, matched }
// on first match or null.
function matchEncodedBypass(text) {
  const cfg = loadPatterns();
  if (!Array.isArray(cfg.encoded_bypass_patterns)) return null;
  const norm = normalize(text);
  for (const p of cfg.encoded_bypass_patterns) {
    const re = _patternToRegExp(p);
    if (re.test(norm)) {
      return { name: p.name, matched: p.matched_message };
    }
  }
  return null;
}

// Workflow guard runs all prompt_injection_patterns plus workflow_extra_patterns.
// Some workflow patterns apply to the raw file content (HTML comments, code blocks)
// rather than the normalized stream — those patterns carry applies_to: "raw_file".
function matchWorkflowInjection(rawContent) {
  const cfg = loadPatterns();
  const norm = normalize(rawContent);
  // Step 1: shared prompt-injection patterns over normalized text
  for (const p of cfg.prompt_injection_patterns) {
    const re = _patternToRegExp(p);
    if (re.test(norm)) {
      return { name: p.name, matched: p.matched_message };
    }
  }
  // Step 2: workflow-extra patterns. Those flagged applies_to: "raw_file" run
  // against the un-normalized content; others run against normalized.
  for (const p of cfg.workflow_extra_patterns) {
    const re = _patternToRegExp(p);
    const target = (p.applies_to === 'raw_file') ? String(rawContent || '') : norm;
    if (re.test(target)) {
      return { name: p.name, matched: p.matched_message };
    }
  }
  // Step 3: zero-width char detection on raw file (workflow-guard.sh checks raw)
  if (hasZeroWidthChars(rawContent)) {
    return { name: 'zero-width characters', matched: 'invisible characters detected' };
  }
  return null;
}

// ---- Block response (parity with _sec_block) -------------------------------

function emitBlock(guardName, patternName, matchedDetail) {
  process.stderr.write(`APEX ${guardName}: BLOCKED\n`);
  process.stderr.write(`Pattern: ${patternName}\n`);
  process.stderr.write(`Matched: ${matchedDetail}\n`);
  process.stderr.write('\n');
  process.stderr.write('Security violation detected. Operation rejected.\n');
}

// ---- Stdin reader (Claude Code hook protocol) ------------------------------

// Read all of stdin (synchronously-blocking, suitable for short hook input).
function readStdinSync() {
  try {
    const buf = fs.readFileSync(0, 'utf8');
    return buf;
  } catch (_e) {
    return '';
  }
}

// Parse the Claude Code PreToolUse JSON payload to extract a candidate
// "input" string. For Write/Edit/Agent the relevant field is tool_input.
// For workflow-guard reads we need tool_input.file_path.
function parseHookStdin(stdinText) {
  if (!stdinText) return null;
  const trimmed = stdinText.trim();
  if (!trimmed) return null;
  // Hook protocol may pass JSON; if not JSON, treat as the raw input string.
  if (trimmed.startsWith('{')) {
    try {
      return JSON.parse(trimmed);
    } catch (_e) {
      return null;
    }
  }
  return null;
}

module.exports = {
  loadPatterns,
  normalize,
  hasZeroWidthChars,
  matchArgContent,
  matchPromptInjection,
  matchEncodedBypass,
  matchWorkflowInjection,
  emitBlock,
  readStdinSync,
  parseHookStdin,
};
