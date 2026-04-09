# Supabase Patterns for APEX

## Client Setup
- Server client: src/lib/supabase/server.ts (uses cookies)
- Client client: src/lib/supabase/client.ts (browser)
- NEVER share a single client between server and client

## RLS — NON-NEGOTIABLE
- Every table MUST have RLS enabled
- Every policy MUST filter by auth.uid() or tenant_id
- Test: user A cannot access user B data

## Query Pattern
```typescript
const { data, error } = await supabase
  .from('table')
  .select('*')
  .eq('tenant_id', tenantId)

if (error) {
  throw new Error(`DB query failed: ${error.message}`)
}
// NEVER: if (error) console.log(error) — this is a silent failure
```

## Migrations
- Files: supabase/migrations/NNN_description.sql
- Always idempotent (IF NOT EXISTS)
- RLS policy in same migration as table creation

## Edge Cases
- Token expiry: Supabase auto-refreshes, but check for auth state changes
- Realtime: always unsubscribe in cleanup
- Storage: signed URLs expire — never cache permanently