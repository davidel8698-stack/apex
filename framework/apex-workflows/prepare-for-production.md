# Workflow: Prepare for Production

## Goal
Harden an existing application for production deployment. Covers environment configuration, security hardening, performance optimization, observability, and deployment readiness checks.

## Prerequisites
- Working application with passing tests in development
- Deployment target identified (cloud provider, VPS, or container platform)
- Domain name configured (or ready to configure)
- Database provisioned for production use

## Phases

### Phase 1: Environment & Configuration Hardening
- Audit all environment variables — ensure no hardcoded secrets in source
- Create `.env.production` template with required variables documented
- Set NODE_ENV / RAILS_ENV / equivalent to production
- Configure production database connection (connection pooling, SSL)
- Enable HTTPS-only (redirect HTTP → HTTPS)
- Set secure cookie flags (httpOnly, secure, sameSite)
- Configure CORS for production domains only
- Verify: no secrets in git history (`git log -p | grep -i password/secret/key`)

### Phase 2: Security Hardening
- Add rate limiting on authentication and public API endpoints
- Enable CSRF protection on all state-changing endpoints
- Add security headers (Content-Security-Policy, X-Frame-Options, HSTS)
- Audit dependencies for known vulnerabilities (`npm audit` / `pip audit` / equivalent)
- Remove debug endpoints and development-only routes
- Disable stack traces in error responses
- Verify: security headers present on all responses; no debug info leaks in error responses

### Phase 3: Performance & Reliability
- Enable gzip/brotli compression for responses
- Configure static asset caching (Cache-Control headers, fingerprinted filenames)
- Set up database connection pooling
- Add health check endpoint (`/healthz` or `/health`)
- Configure graceful shutdown (handle SIGTERM, drain connections)
- Set appropriate request timeouts
- Verify: health check returns 200; assets served with cache headers; graceful shutdown works

### Phase 4: Observability & Deployment
- Configure structured logging (JSON format, log levels, request IDs)
- Set up error tracking (Sentry, Bugsnag, or equivalent)
- Add basic metrics endpoint or integration (request count, latency, error rate)
- Create deployment script or CI/CD pipeline configuration
- Document rollback procedure
- Run load test (basic — verify no crashes under moderate load)
- Verify: logs are structured; errors reported to tracking service; deployment script runs successfully

## Skills Required
- DevOps / infrastructure skill matching deployment target
- Security hardening
- Database skill matching project stack

## Security Invariants
- No secrets in source code or git history
- HTTPS enforced in production
- Debug mode MUST be disabled
- Error responses MUST NOT expose stack traces or internal details
- Dependencies MUST have no known critical vulnerabilities
