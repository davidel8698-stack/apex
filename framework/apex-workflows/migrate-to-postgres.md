# Workflow: Migrate to PostgreSQL

## Goal
Migrate an existing application from SQLite, MySQL, or another database to PostgreSQL. Includes schema conversion, data migration, and connection reconfiguration.

## Prerequisites
- Existing application with a working database
- PostgreSQL server available (local, Docker, or hosted like Supabase/Neon)
- Database credentials for both source and target
- Application downtime window acceptable (or blue-green deployment plan)

## Phases

### Phase 1: PostgreSQL Setup + Schema Conversion
- Provision PostgreSQL instance (Docker recommended for local dev)
- Add DATABASE_URL for PostgreSQL to environment
- Convert existing schema to PostgreSQL syntax:
  - AUTOINCREMENT -> SERIAL/BIGSERIAL
  - TEXT with length limits -> VARCHAR(n) where appropriate
  - Boolean handling (SQLite uses 0/1, PostgreSQL uses true/false)
  - Date/time types (SQLite stores as TEXT, PostgreSQL has native types)
- Create all tables in PostgreSQL with proper constraints and indexes
- Verify: schema creates without errors, constraints match source

### Phase 2: Data Migration
- Export data from source database
- Transform data for PostgreSQL compatibility:
  - Boolean values (0/1 -> true/false)
  - Date formats (ISO strings -> TIMESTAMP)
  - Null handling differences
- Import data into PostgreSQL preserving foreign key relationships (disable constraints during import, re-enable after)
- Reset sequences to max(id) + 1 for each table
- Verify: row counts match source, foreign key constraints valid, sequences correct

### Phase 3: Application Reconfiguration
- Update ORM/query builder configuration (Prisma, Knex, Drizzle, raw pg)
- Update connection string to PostgreSQL
- Replace SQLite-specific queries with PostgreSQL syntax:
  - LIMIT/OFFSET syntax
  - String concatenation (|| vs CONCAT)
  - Case sensitivity in LIKE queries
  - JSON operations (if used)
- Run full test suite against PostgreSQL
- Verify: all existing tests pass, no SQLite-specific code remains

## Skills Required
- postgres
- Database ORM skill if applicable (prisma, etc.)

## Data Safety Invariants
- NEVER drop the source database until PostgreSQL is verified in production
- ALWAYS create a backup of source data before migration
- Migration scripts MUST be idempotent (safe to re-run)
- Verify row counts match between source and target for every table
- Test with production-like data volume (not just dev fixtures)

## Security Invariants
- Database credentials MUST use environment variables, never hardcoded in source or migration scripts
- Connection strings MUST use SSL/TLS in production (sslmode=require or verify-full)
- Migration user MUST have minimal required privileges (no SUPERUSER for application connections)
- Exported data files MUST be deleted after import, never committed to git
- PostgreSQL roles MUST follow least-privilege: separate migration user (DDL) from application user (DML only)
