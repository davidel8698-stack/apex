# Workflow: Setup Database

## Goal
Add a database to an existing application. Covers database selection, schema design, ORM/query layer setup, migrations, and seed data.

## Prerequisites
- Existing application with data storage needs identified
- Database engine selected (PostgreSQL, MySQL, SQLite, MongoDB, etc.)
- Database server accessible (local, Docker, or managed cloud)

## Phases

### Phase 1: Connection & ORM Setup
- Install database driver and ORM/query builder matching project stack (Prisma, SQLAlchemy, GORM, Drizzle, etc.)
- Configure database connection string via environment variable
- Set up connection pooling with sensible defaults (min: 2, max: 10)
- Create database initialization script (create database if not exists)
- Add database health check to application startup
- Verify: application connects to database; health check reports database status

### Phase 2: Schema & Migrations
- Design initial schema based on application data requirements
- Create migration files for each table/collection (reversible up/down)
- Define indexes for frequently queried columns
- Add foreign key constraints and cascading rules where appropriate
- Create seed data script for development environment
- Verify: migrations run forward and backward cleanly; seed data loads correctly

### Phase 3: Data Access Layer
- Create repository/DAO pattern for each entity (or equivalent for project's architecture)
- Implement CRUD operations with proper error handling
- Add query logging in development mode (show SQL, parameters, duration)
- Configure transaction support for multi-step operations
- Add connection error handling and retry logic
- Verify: all CRUD operations work; transactions commit and rollback correctly; connection loss handled gracefully

## Skills Required
- Database skill matching engine (postgres, mysql, mongodb, sqlite)
- ORM/query builder matching project stack

## Security Invariants
- Database credentials MUST be stored in environment variables, never in source code
- All user-facing queries MUST use parameterized queries (no string concatenation)
- Database user MUST have least-privilege permissions (no SUPERUSER)
- Migrations MUST be reversible
- Seed data MUST NOT contain real user data
