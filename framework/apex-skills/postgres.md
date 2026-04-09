# PostgreSQL Patterns for APEX

## Schema Conventions
- snake_case for tables (plural) and columns
- `id UUID DEFAULT gen_random_uuid() PRIMARY KEY` (not serial)
- `created_at TIMESTAMPTZ DEFAULT now()` and `updated_at` on every table
- Foreign keys with explicit `ON DELETE` behavior (CASCADE, SET NULL, or RESTRICT)
- Indexes on all foreign keys and frequently filtered columns

## Anti-Patterns — NEVER
- Never use `SELECT *` in production queries (select specific columns)
- Never use `DELETE FROM` without `WHERE` (use soft delete: `deleted_at` column)
- Never store JSON for structured, queryable data (use proper columns)
- Never skip `IF NOT EXISTS` in CREATE TABLE/INDEX migrations
- Never use `TEXT` for fields with known constraints (use `VARCHAR(n)` or domain types)

## Migration Pattern
```sql
-- Always idempotent
CREATE TABLE IF NOT EXISTS users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
```

## Testing
- Use test transactions: BEGIN → test → ROLLBACK (no test data pollution)
- Seed minimal test data — don't rely on production dumps
- Test constraints: verify unique, not-null, FK violations raise errors

## Common Gotchas
- N+1 queries: use JOINs or batch queries, never loop+query
- Connection pooling: use PgBouncer or built-in pool (max 20 connections per app instance)
- JSONB indexes: use GIN index for `@>` operator, not btree
- RLS: enable row-level security for multi-tenant — `ALTER TABLE t ENABLE ROW LEVEL SECURITY`