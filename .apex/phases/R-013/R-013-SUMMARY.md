# Task R-013 Summary
## Status: COMPLETE
## What Was Built
Expanded all 4 specialist agents (security, data, frontend, integration) from 16-17 lines to 80-82 lines each. Added domain-specific named failure mode prohibitions, TDAD awareness sections, domain invariants, and domain-specific checks. All content focuses on permanent domain rules, not task-specific instructions.

## Files Changed
- `framework/agents/specialist/security.md`: Added 5 prohibitions (TENANT BYPASS, HARDCODED SECRET, UNVALIDATED INPUT, MISSING RATE LIMIT, NEGATIVE AUTH OMISSION), 5 domain invariants, 6 domain checks, TDAD awareness. 17 -> 82 lines.
- `framework/agents/specialist/data.md`: Added 4 prohibitions (UNVALIDATED MIGRATION, MISSING ROLLBACK, UNBOUNDED QUERY, SWALLOWED DB ERROR), 8 domain invariants, 7 domain checks, TDAD awareness. 17 -> 81 lines.
- `framework/agents/specialist/frontend.md`: Added 4 prohibitions (ACCESSIBILITY VIOLATION, UNRESPONSIVE LAYOUT, MISSING ERROR STATE, SILENT ASYNC FAILURE), 8 domain invariants, 7 domain checks, TDAD awareness. 16 -> 81 lines.
- `framework/agents/specialist/integration.md`: Added 4 prohibitions (MISSING RETRY, UNHANDLED TIMEOUT, TOKEN LEAK, SWALLOWED EXTERNAL ERROR), 7 domain invariants, 6 domain checks, TDAD awareness. 17 -> 80 lines.

## Verification Output
```
$ wc -l security.md data.md frontend.md integration.md
  82 security.md
  81 data.md
  81 frontend.md
  80 integration.md
 324 total
```

## TDAD: Impacted Tests Run
No IMPACTED_TESTS.txt in context. These are markdown agent prompt files — no automated tests apply.

## Edge Cases Handled
- Domain invariants vs task-specific: DOMAIN INVARIANTS section explicitly scoped with "regardless of task XML content"
- No bloat: All files 80-82 lines, within 80-120 range
- No executor duplication: All prohibitions are domain-specific, not repeating generic executor prohibitions

## Silent Failure Risks Addressed
- Each prohibition includes a "Required pattern" line forcing agents to paste actual evidence
- TDAD section provides exact command to run impacted tests

## Trajectory Notes
No spec drift or loops detected.

## What Next Tasks Can Assume
All 4 specialist agents have domain-specific named failure prohibitions, TDAD awareness, domain invariants, and domain-specific checks at 80-82 lines each.

## Known Limitations
None.
