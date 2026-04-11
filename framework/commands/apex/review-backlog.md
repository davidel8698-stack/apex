---
description: Review pending backlog items — promote, archive, or delete.
---

<context>
## GUARD
If no .apex/STATE.json: "❌ No APEX project. Run /apex:start first." STOP.

## LIST ITEMS
```bash
ITEMS=$(ls .apex/backlog/*.md 2>/dev/null)
```

If no items found:
  "📋 Backlog is empty. Add items with /apex:add-backlog."
  STOP.

## DISPLAY
"📋 BACKLOG REVIEW

"
For each item in .apex/backlog/*.md:
  Read first 3 lines of content (skip frontmatter).
  "[N] {filename} — {first line of content}"

"
Actions:
  (p)romote N — move to current phase as a new task
  (a)rchive N — move to .apex/backlog/archived/
  (d)elete N — permanently remove
  (s)kip — exit review

Enter action:"

## HANDLE ACTION

promote:
  Read the backlog item content.
  Move file to .apex/backlog/archived/ with status: promoted.
  "✅ Promoted. Add to current phase plan with /apex:next."

archive:
  mkdir -p .apex/backlog/archived
  Move file to .apex/backlog/archived/.
  "📦 Archived: {filename}"

delete:
  Remove file.
  "🗑️ Deleted: {filename}"

skip:
  "Done." STOP.
</context>
