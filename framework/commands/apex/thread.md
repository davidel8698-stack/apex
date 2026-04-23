---
description: Start or append to a discussion thread for ongoing technical decisions.
---

<context>
## PROPOSALS MODE GUARD
Read .apex/STATE.json → proposals_mode.
If proposals_mode == true: NEVER ask open-ended questions in this command.
Instead, present numbered proposals with a recommended default marked [recommended].

## GUARD
If no .apex/STATE.json: "❌ No APEX project. Run /apex:start first." STOP.
If $ARGUMENTS is empty:
  "❌ /apex:thread requires a topic and content.
   Usage: /apex:thread 'auth-strategy: Consider JWT vs session tokens for mobile clients'
   Format: topic-slug: content"
  STOP.

## PARSE INPUT
Extract topic slug from $ARGUMENTS:
  If contains ':' → SLUG = lowercase, hyphenated text before first ':'
  Else → SLUG = first 3 words, lowercase, hyphenated

CONTENT = full $ARGUMENTS text
THREAD_FILE = .apex/threads/${SLUG}.md

Ensure directory exists: `mkdir -p .apex/threads/`

## WRITE
If THREAD_FILE exists:
  Append to file:
  ```
  ---
  **[timestamp]**
  ${CONTENT}
  ```

If THREAD_FILE does not exist:
  Create file:
  ```
  # Thread: ${SLUG}
  Created: [timestamp]

  ---
  **[timestamp]**
  ${CONTENT}
  ```

"✅ Thread updated: ${THREAD_FILE}"
</context>
