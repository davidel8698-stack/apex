# Task R-003 Summary
## Status: COMPLETE
## What Was Built
Two new security hooks for the APEX framework: prompt-guard.sh (52 lines) detects prompt injection patterns in tool inputs, and path-guard.sh (42 lines) blocks path traversal and sensitive file access. Both follow the destructive-guard.sh pattern with set -u, block() to stderr, exit 0/2.

## Files Changed
- `framework/hooks/prompt-guard.sh`: New hook detecting 6 prompt injection patterns (instruction override, role hijacking, system: framing, ```system blocks, IMPORTANT:/CRITICAL: priority injection)
- `framework/hooks/path-guard.sh`: New hook blocking 4 categories of dangerous paths (../ traversal, Unix system dirs, Windows system dirs, sensitive files like .env/.ssh/credentials)

## Verification Output
prompt-guard.sh: 12 test cases all returned expected exit codes (2 for blocks, 0 for passes)
path-guard.sh: 9 test cases all returned expected exit codes (2 for blocks, 0 for passes)
Line counts: 52 (prompt-guard.sh), 42 (path-guard.sh) - both within 40-70 range

## Edge Cases Handled
- "system" appearing mid-sentence does NOT trigger (only at line start)
- "important" mid-sentence does NOT trigger (only IMPORTANT: at line start)
- Multiline input with system: on a later line correctly triggers
- .env.local/.env.production variants correctly blocked
- Windows paths with backslashes correctly matched

## Silent Failure Risks Addressed
- block() outputs to stderr so callers see the reason
- set -u prevents unset variable bugs
- All grep commands have 2>/dev/null for robustness

## What Next Tasks Can Assume
prompt-guard.sh and path-guard.sh exist at framework/hooks/, are executable, use exit 0 (pass) / exit 2 (block) convention. They can be wired into settings.json hook matchers for PreToolUse events.

## Known Limitations
- Symlink following not checked in path-guard (shell limitation, noted in spec)
- Base64-encoded injection phrases not detected (spec says skip for now)
- Prompt guard is defense-in-depth, not comprehensive WAF
