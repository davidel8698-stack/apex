# Workflow: Add Logging

## Goal
Add structured, centralized logging to an existing application. Covers log formatting, log levels, request correlation, and log aggregation.

## Prerequisites
- Existing application with identifiable entry points (API routes, background jobs)
- Log aggregation platform selected (ELK, CloudWatch Logs, Datadog Logs, or file-based)

## Phases

### Phase 1: Structured Logging Setup
- Install logging library matching stack (winston, pino, structlog, slog, etc.)
- Configure structured output format (JSON in production, pretty-print in development)
- Define log levels and usage conventions: error (failures), warn (degraded), info (business events), debug (development only)
- Add request ID middleware — generate unique ID per request, attach to all log entries
- Replace all `console.log` / `print` statements with structured logger calls
- Verify: application logs output valid JSON with timestamp, level, message, and request_id

### Phase 2: Integration & Aggregation
- Add request/response logging middleware (method, path, status, duration — no body in production)
- Add error logging with stack traces (sanitized — no secrets in logs)
- Configure log rotation or streaming to aggregation platform
- Add correlation IDs for cross-service tracing (if multi-service)
- Set log level via environment variable (default: info in production, debug in development)
- Verify: logs stream to aggregation platform; searchable by request_id; no PII in logs

## Skills Required
- Logging library matching project stack
- Log aggregation platform skill

## Security Invariants
- Logs MUST NOT contain passwords, tokens, API keys, or PII
- Request/response body logging MUST be disabled or redacted in production
- Log files MUST have restricted file permissions (600 or 640)
