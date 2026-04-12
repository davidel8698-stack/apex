# Workflow: Add Caching

## Goal
Add a caching layer to an existing application to reduce database load and improve response times. Covers in-memory caching, distributed caching, and cache invalidation strategies.

## Prerequisites
- Existing application with identified slow queries or repeated data fetches
- Caching backend selected (Redis, Memcached, or in-memory)
- Performance baseline established (current response times for target endpoints)

## Phases

### Phase 1: Cache Infrastructure
- Install caching client library matching project stack
- Configure cache connection (Redis/Memcached URL, connection pooling, timeouts)
- Create cache utility module with get/set/delete/invalidate operations
- Add cache health check to existing health endpoint
- Define TTL strategy per data type (static config: long TTL; user data: short TTL; session: medium TTL)
- Verify: cache client connects successfully; health check reports cache status

### Phase 2: Application-Level Caching
- Identify top 5 most expensive queries or API calls (by frequency × latency)
- Add cache-aside pattern for read-heavy endpoints (check cache → miss → fetch → store)
- Add write-through invalidation for mutating endpoints (update DB → invalidate cache)
- Implement cache key namespacing to prevent collisions (e.g., `user:123:profile`)
- Add cache miss/hit metrics for monitoring
- Verify: cached endpoints respond faster than baseline; cache hit rate visible in metrics

### Phase 3: Edge Cases & Resilience
- Handle cache stampede (mutex/lock on cache miss for expensive queries)
- Handle cache failure gracefully (fallback to database, don't crash)
- Add cache warming for critical startup data
- Document cache invalidation strategy for each cached entity
- Test: verify application works correctly with cache disabled (graceful degradation)
- Verify: application survives cache failure; no stale data after writes

## Skills Required
- Caching backend skill (redis, memcached)
- Database skill matching project stack

## Security Invariants
- Cache MUST NOT store plaintext passwords or unencrypted sensitive tokens
- Cache keys MUST NOT leak PII in monitoring or logs
- Cache connections MUST use authentication in production
- Cache data MUST respect the same access control as the source data
