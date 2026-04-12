# Workflow: Setup Error Tracking

## Goal
Add centralized error tracking to an existing application. Covers error capture, context enrichment, alerting, and release tracking.

## Prerequisites
- Existing application deployed or running
- Error tracking service selected (Sentry, Bugsnag, Rollbar, or Datadog Error Tracking)
- Alert notification channel configured (Slack, email)

## Phases

### Phase 1: SDK Integration & Configuration
- Install error tracking SDK matching project stack (frontend and backend)
- Configure DSN/API key via environment variable
- Initialize SDK with environment tag (production, staging, development)
- Add global error handler: uncaught exceptions, unhandled promise rejections
- Configure source maps upload for frontend (readable stack traces)
- Add user context to errors (user ID, email — no passwords or tokens)
- Verify: intentional test error appears in tracking dashboard with correct environment and user context

### Phase 2: Context Enrichment & Alerting
- Add breadcrumbs for key operations (API calls, navigation, user actions)
- Attach request context to backend errors (URL, method, status code, request ID)
- Configure alert rules: new error → immediate alert; error spike → urgent alert
- Set up release tracking (tag errors with git commit or version)
- Configure error grouping rules (avoid duplicate alerts for same root cause)
- Verify: errors have breadcrumbs and request context; alerts fire for new errors; errors grouped by release

## Skills Required
- Error tracking service skill (sentry, bugsnag, rollbar)
- Frontend and backend framework skills

## Security Invariants
- Error reports MUST NOT contain passwords, tokens, or API keys
- User context MUST be limited to non-sensitive identifiers (user ID, not SSN)
- Source maps MUST NOT be publicly accessible (upload to service, don't serve)
- Error tracking DSN MUST be appropriate for environment (no production DSN in development)
