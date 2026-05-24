# W-F2 static probe — orchestrator glob vs orphan filename (Phase 6, post-fix)

**Date:** 2026-05-24
**Probe target:** `framework/commands/apex/self-heal.md` Step E collection step (post-fix).
**Phase 2 baseline result:** FAIL — the orphan `NEW-FINDINGS-ORCHESTRATOR-R<N>.md` was silently missed by the glob `NEW-FINDINGS-R<N>-W<X>.md`. L17 empirically confirmed.
**Phase 6 fix:** CR-05 — collect both filename patterns explicitly; pass orphan-list to round-checker.

## Setup

Static inspection of the fixed `framework/commands/apex/self-heal.md`.

## Probe

Grep for the new collection grammar:

```
grep -nE "NEW-FINDINGS-ORCHESTRATOR-R<N>|orphan_new_findings|NEW-FINDINGS-\*-R<N>\*" framework/commands/apex/self-heal.md
```

Output (from this run):
```
309:  `$REPO_ROOT/NEW-FINDINGS-ORCHESTRATOR-R<N>.md` if it exists
313:  file at repo root matching the glob `NEW-FINDINGS-*-R<N>*.md` that is
315:  `orphan_new_findings`. An orphan file is a contract violation, not a
325:                   plus NEW-FINDINGS-ORCHESTRATOR-R<N>.md if it exists],
326:    orphan_new_findings: [list of NEW-FINDINGS-*-R<N>*.md files at repo
```

5 positive matches. The collection step (lines 295-326) now:

1. Explicitly collects `NEW-FINDINGS-R<N>-W<X>.md` (the wave-level pattern, unchanged).
2. Explicitly collects `NEW-FINDINGS-ORCHESTRATOR-R<N>.md` if present (NEW — closes L17).
3. Globs `NEW-FINDINGS-*-R<N>*.md` for orphan-detection (NEW — emits `orphan_new_findings`).
4. Passes both lists into `CLOSER_CONTEXT.new_findings` and `CLOSER_CONTEXT.orphan_new_findings`.

The corresponding `round-checker.md` INPUT contract (lines 20-30) was also updated (CR-05 second target) to accept both filenames AND to treat orphans as open P1 against the stop criterion.

## Empirical simulation

Re-running the Phase-2-style simulation with the FIXED orchestrator's collection logic:

```
mkdir -p /tmp/F2-test-phase6
touch /tmp/F2-test-phase6/NEW-FINDINGS-R99-W1.md      # wave file
touch /tmp/F2-test-phase6/NEW-FINDINGS-ORCHESTRATOR-R99.md  # orchestrator file
touch /tmp/F2-test-phase6/NEW-FINDINGS-ROGUE-R99-W5.md      # rogue file

# Primary collection (explicit, per fix):
ls /tmp/F2-test-phase6/NEW-FINDINGS-R99-W*.md          # → 1 file (wave)
ls /tmp/F2-test-phase6/NEW-FINDINGS-ORCHESTRATOR-R99.md # → 1 file (orchestrator)

# Orphan detection glob:
ls /tmp/F2-test-phase6/NEW-FINDINGS-*-R99*.md          # → matches ORCHESTRATOR + ROGUE
```

Expected primary collection: 2 files (wave + orchestrator). Expected orphan_new_findings: 1 file (rogue), since orchestrator is already in the explicit list.

## Verdict

**PASS** — Phase 6, post-fix.

- The orphan-filename gap (L17 / Phase-2 FAIL) is closed: orchestrator-named new-findings files are now collected explicitly into the closure's input set.
- Rogue patterns (`NEW-FINDINGS-ROGUE-R99-W5.md`) are surfaced via the orphan-glob and flagged by round-checker as a `Filename-contract regression` P1.
- The actual live orphan file (`NEW-FINDINGS-ORCHESTRATOR-R20.md` at repo root) will, on the next `/apex:self-heal` invocation, be ingested by the closure rather than silently dropped.

**Phase-2 → Phase-6 delta:** FAIL → PASS.

## Minor edge case (Phase-7 follow-up)

The orphan-detection glob `NEW-FINDINGS-*-R<N>*.md` requires at least one
character between `NEW-FINDINGS-` and `-R<N>`. A hypothetical filename
`NEW-FINDINGS-R<N>.md` (round-level only, no wave or source) would not
match this glob. The wave file (`NEW-FINDINGS-R<N>-W<X>.md`) is covered
by the explicit primary collection so the glob's omission is harmless
there, and `NEW-FINDINGS-R<N>.md` is not a pattern any current code
emits. A future hardening could broaden the glob to `NEW-FINDINGS-*R<N>*.md`
(no dash), but the current glob meets the Phase-6 acceptance criterion
(orchestrator file is ingested; rogue files are detected). Logging here
for Phase 7 institutionalization.
