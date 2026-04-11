# Workflow: Add Authentication

## Goal
Add user authentication to an existing web application. Supports JWT-based or session-based auth with login, registration, password reset, and protected route middleware.

## Prerequisites
- Existing web application with API routes
- Database already configured (any supported DB)
- Environment variables mechanism in place (.env or equivalent)

## Phases

### Phase 1: Database Schema + User Model
- Create users table: id, email, password_hash, created_at, updated_at
- Add unique constraint on email
- Create migration file (reversible)
- Add password hashing utility (bcrypt or argon2)
- Verify: migration runs and rolls back cleanly

### Phase 2: Auth API Endpoints
- POST /api/auth/register — validate input, hash password, create user, return token
- POST /api/auth/login — validate credentials, return token
- POST /api/auth/logout — invalidate session/token
- POST /api/auth/forgot-password — send reset email (stub if no email service)
- Verify: each endpoint returns correct status codes for success and failure

### Phase 3: Middleware + Protected Routes
- Create auth middleware that validates JWT/session on every request
- Apply middleware to routes that require authentication
- Return 401 on missing/invalid token, 403 on insufficient permissions
- Add current user to request context
- Verify: protected routes reject unauthenticated requests, allow authenticated ones

### Phase 4: Frontend Integration
- Login page with form validation and error display
- Registration page with password strength indicator
- Auth context/store for managing logged-in state
- Redirect unauthenticated users to login
- Persist auth state across page refreshes (localStorage or httpOnly cookie)
- Verify: full login/logout flow works end-to-end

## Skills Required
- auth-jwt (if JWT-based)
- Database skill matching project stack (postgres, supabase, etc.)
- Frontend framework skill (react, nextjs, etc.)

## Security Invariants
- Passwords MUST be hashed (never stored plaintext)
- Tokens MUST have expiration
- Password reset tokens MUST be single-use
- Rate limiting on login endpoint (prevent brute force)
- Input validation on all auth endpoints
