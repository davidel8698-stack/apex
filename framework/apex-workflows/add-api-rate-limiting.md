# Workflow: Add API Rate Limiting

## Goal
Add per-user and per-endpoint rate limiting to protect API endpoints from abuse. Supports in-memory (single instance) or Redis-backed (multi-instance) stores.

## Prerequisites
- Existing web application with API routes
- Authentication system (for per-user limits)
- Redis available if multi-instance deployment (optional for single-server)

## Phases

### Phase 1: Rate Limiter Core
- Choose storage backend:
  - In-memory (Map/object) for single-instance deployments
  - Redis for multi-instance deployments
- Implement sliding window counter algorithm:
  - Key: "{endpoint}:{user_id or IP}" 
  - Window: configurable per endpoint (default 60 seconds)
  - Limit: configurable per endpoint (default 100 requests)
- Return remaining requests and reset time in response headers:
  - X-RateLimit-Limit
  - X-RateLimit-Remaining
  - X-RateLimit-Reset
- Return 429 Too Many Requests when limit exceeded
- Verify: rate limiter counts correctly, resets after window, returns proper headers

### Phase 2: Middleware Integration + Configuration
- Create rate limiting middleware that runs before route handlers
- Configure per-endpoint limits:
  - Auth endpoints (login, register): strict (5-10/minute)
  - Read endpoints: moderate (100/minute)
  - Write endpoints: moderate (30/minute)
  - Webhook endpoints: generous (1000/minute) or exempt
- Apply middleware to all API routes
- Exempt health check and static asset routes
- Authenticated users identified by user_id, anonymous by IP
- Verify: different endpoints respect their configured limits

## Skills Required
- Backend framework skill matching project stack

## Security Invariants
- Rate limit by authenticated user ID when available, IP as fallback
- NEVER trust X-Forwarded-For without explicit proxy configuration
- Login/registration endpoints MUST have strict limits (brute force prevention)
- Rate limit responses MUST NOT leak information about other users
- Log rate limit violations for security monitoring
