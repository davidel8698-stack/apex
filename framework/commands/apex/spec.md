---
description: Review or update specification.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## SPEC_VERSION tracking [R-015]

On every invocation:
1. Compute current hash: `CURRENT_HASH=$(sha256sum .apex/SPEC.md | cut -d' ' -f1)`
2. Read stored hash: `STORED_HASH=$(jq -r '.spec_version' .apex/STATE.json)`
3. If hashes differ (spec changed since last check):
   - Generate `.apex/SPEC_DELTA.json`:
     ```json
     {
       "previous_hash": "$STORED_HASH",
       "current_hash": "$CURRENT_HASH",
       "changed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
       "changed_by": "spec command",
       "sections_affected": ["<list sections with diff>"]
     }
     ```
   - Update STATE.json: `jq --arg h "$CURRENT_HASH" '.spec_version = $h' .apex/STATE.json > tmp && mv tmp .apex/STATE.json`
   - "⚠️ Spec drift detected. SPEC_DELTA.json written. Review downstream impact."
4. If hashes match: no action needed.

## Command flow

If empty: show SPEC.md, display spec_version hash, ask "Update anything?"
If changes:
  ## RENDER: Mission Briefing (Section 10-B abbreviated — agent card + task goal only)
  Task("planner", "Update spec only (skip Phase 1). Current: [SPEC.md]. Change: [$ARGUMENTS].
  Update Error Flows section if affected. Log in DECISIONS.md with phase impact.")
  After planner completes:
  - Recompute hash: `NEW_HASH=$(sha256sum .apex/SPEC.md | cut -d' ' -f1)`
  - Write SPEC_DELTA.json with previous and new hash
  - Update STATE.json spec_version to NEW_HASH
  ## RENDER: Flight Recorder (Section 10-C abbreviated — agent + verdict)
  "✅ Updated. spec_version: $NEW_HASH. ⚠️ Review DECISIONS.md for downstream impact."
</context>
