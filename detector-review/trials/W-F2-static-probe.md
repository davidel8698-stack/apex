# W-F2 static probe — orchestrator glob misses orphan filename

**Date:** 2026-05-23
**Probe target:** self-heal.md:296-297 collection step

## Setup

Two files placed at `/tmp/F2-test/`:
- `NEW-FINDINGS-R99-W1.md` (wave-level new-findings — matches the orchestrator's glob)
- `NEW-FINDINGS-ORCHESTRATOR-R99.md` (orchestrator-level new-findings — does NOT match the glob)

## Probe

```
ls /tmp/F2-test/NEW-FINDINGS-R99-W*.md
```

Output: `/tmp/F2-test/NEW-FINDINGS-R99-W1.md` (only).

## Verdict

**FAIL** — the orchestrator's glob `NEW-FINDINGS-R<N>-W<X>.md` (self-heal.md:296-297) does NOT match `NEW-FINDINGS-ORCHESTRATOR-R<N>.md`.
The orphan file is silently missed by the collection step. **L17 EMPIRICALLY CONFIRMED.** A P1 finding the orchestrator itself discovers is never passed to round-checker if it lives in the orchestrator-named file.
