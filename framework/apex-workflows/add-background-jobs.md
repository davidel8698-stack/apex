# Workflow: Add Background Jobs

## Goal
Add background job processing to an existing application. Covers job queue setup, worker configuration, job types, retry logic, and monitoring.

## Prerequisites
- Existing application with tasks that should run asynchronously (email sending, report generation, data processing)
- Queue backend selected (Redis + BullMQ, Celery + Redis/RabbitMQ, Sidekiq, or database-backed)

## Phases

### Phase 1: Queue Infrastructure
- Install job queue library matching project stack
- Configure queue connection (Redis URL, RabbitMQ URL, or database)
- Create worker process configuration (separate from web server)
- Define job base class/interface with standard lifecycle: perform, retry, fail
- Add queue health check to application health endpoint
- Create first job: move an existing synchronous operation to background
- Verify: worker starts and connects to queue; test job enqueued and processed; health check reports queue status

### Phase 2: Job Types & Retry Logic
- Migrate identified async operations to background jobs (emails, reports, webhooks, etc.)
- Configure retry strategy per job type: max attempts, backoff (exponential), dead letter queue
- Add job priority levels (urgent: process immediately; normal: FIFO; low: process when idle)
- Implement job timeout (kill jobs that run longer than expected)
- Add job deduplication for idempotent operations (prevent duplicate processing)
- Verify: each job type processes correctly; failed jobs retry with backoff; dead letter queue captures permanently failed jobs

### Phase 3: Monitoring & Scaling
- Add job processing dashboard (BullBoard, Flower, Sidekiq Web, or custom)
- Configure alerts: dead letter queue growing, processing latency spike, worker crash
- Add structured logging for job lifecycle (enqueued, started, completed, failed, retried)
- Document scaling strategy (add workers horizontally)
- Test graceful shutdown (finish current job before stopping worker)
- Verify: dashboard shows job status; alerts fire for failures; graceful shutdown works

## Skills Required
- Job queue library matching stack (bullmq, celery, sidekiq)
- Redis or message broker skill

## Security Invariants
- Job payloads MUST NOT contain plaintext secrets (pass references, not values)
- Queue dashboard MUST require authentication in production
- Workers MUST run with least-privilege database permissions
- Job processing MUST be idempotent (safe to retry)
