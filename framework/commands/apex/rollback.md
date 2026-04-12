---
description: One-click rollback to a previous checkpoint (task snapshot or phase tag).
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## GUARD
If no .apex/STATE.json: "❌ No APEX project. Run /apex:start first." STOP.

## COLLECT ROLLBACK POINTS

### Task-level snapshots (git stash)
```bash
STASH_LIST=$(git stash list --grep="apex-snapshot" 2>/dev/null)
```

### Phase-level tags
```bash
TAG_LIST=$(git tag -l "apex/*" --sort=-creatordate 2>/dev/null)
```

If both empty:
  "❌ No rollback points found.
   Task snapshots are created by /apex:fast and /apex:quick (pre-task-snapshot.sh).
   Phase tags are created when a phase passes verification (phase-tag.sh).
   There is nothing to roll back to."
  STOP.

## PRESENT OPTIONS

"🔄 ROLLBACK POINTS

### Task Snapshots (git stash)"
For each stash entry matching apex-snapshot:
  "[N] {stash description} — {date}"

"### Phase Tags"
For each apex/* tag:
  "[N] {tag name} — {date} — {message}"

"Enter number to rollback, or 'cancel':"

## EXECUTE ROLLBACK

If user selects cancel: "Cancelled." STOP.

### Confirmation (destructive operation)
"⚠️ WARNING: This will revert your working tree to the selected checkpoint.
Uncommitted changes will be stashed first as safety backup.
Proceed? (y/n)"

If 'n': "Cancelled." STOP.

### Safety backup
```bash
git stash push -m "apex-pre-rollback-backup-$(date +%s)"
```

### Execute
If selected a stash entry:
  ```bash
  git stash pop {stash_ref}
  ```

If selected a tag:
  ```bash
  git checkout {tag_name} -- .
  ```

### Update STATE.json after rollback
Read the rolled-back STATE.json (it may have reverted to an earlier state).
If STATE.json was overwritten by rollback: use the rolled-back version as-is.
If STATE.json was NOT part of the rollback scope:
  Update STATE.json:
    status: "rolled_back"
    updated_at: now
    snapshots.pre_task_stash: null
    snapshots.last_snapshot_task: null

bash ~/.claude/hooks/session-log.sh "rollback" "Rolled back to: {selected checkpoint description}"

"✅ Rolled back to: {checkpoint description}
   Safety backup saved as stash. Run 'git stash list' to see it.
   Run /apex:next to continue from this point."
</context>
