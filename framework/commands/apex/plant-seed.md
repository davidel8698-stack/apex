---
description: Plant a future idea or prospective task for later consideration.
---

<context>
## GUARD
If no .apex/STATE.json: "❌ No APEX project. Run /apex:start first." STOP.
If $ARGUMENTS is empty:
  "❌ /apex:plant-seed requires an idea description.
   Usage: /apex:plant-seed 'Add WebSocket support for real-time notifications'
   Seeds are prospective — ideas for future phases, not current tasks."
  STOP.

## WRITE
TIMESTAMP = $(date +%Y%m%d-%H%M%S)
SEED_FILE = .apex/seeds/seed-${TIMESTAMP}.md

Create file:
```
# Seed: planted [timestamp]

${$ARGUMENTS}

---
Status: planted
Source: manual (/apex:plant-seed)
```

"🌱 Seed planted: ${SEED_FILE}
   Seeds are reviewed during /apex:pause and memory synthesis."
</context>
