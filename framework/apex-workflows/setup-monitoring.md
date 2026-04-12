# Workflow: Setup Monitoring

## Goal
Add application and infrastructure monitoring to a production system. Covers health checks, metrics collection, alerting, and dashboards.

## Prerequisites
- Application deployed to a reachable environment
- Monitoring platform selected (Datadog, Grafana+Prometheus, New Relic, or CloudWatch)
- Alert notification channel configured (Slack, email, PagerDuty)

## Phases

### Phase 1: Health Checks & Basic Metrics
- Add health check endpoint (`/healthz`) that verifies app, database, and critical dependencies
- Add readiness probe endpoint (`/readyz`) for orchestrators
- Instrument request metrics: count, latency (p50, p95, p99), error rate
- Add system metrics collection: CPU, memory, disk, open connections
- Verify: health endpoint returns 200 with dependency status; metrics endpoint exposes data

### Phase 2: Application-Level Instrumentation
- Add custom metrics for business-critical operations (signups, purchases, jobs processed)
- Instrument database query performance (slow query logging, connection pool utilization)
- Add distributed tracing headers (trace-id propagation across services)
- Log structured events for audit trail (who did what, when)
- Verify: custom metrics visible in monitoring platform; slow queries logged

### Phase 3: Dashboards & Alerting
- Create operational dashboard: request rate, error rate, latency, resource utilization
- Create business dashboard: key business metrics over time
- Configure alerts: error rate spike (>5%), latency degradation (p95 > threshold), health check failure
- Set up on-call rotation or escalation policy
- Document runbook for each alert (what it means, how to investigate, how to remediate)
- Verify: dashboards load with real data; test alert fires and reaches notification channel

## Skills Required
- Monitoring platform skill (datadog, prometheus, cloudwatch)
- DevOps / infrastructure

## Security Invariants
- Metrics endpoints MUST NOT expose sensitive data (PII, tokens, passwords)
- Monitoring credentials MUST be stored as secrets, not in source
- Dashboard access MUST require authentication
