# Workflow: Add Testing

## Goal
Add a comprehensive testing setup to an existing application. Covers unit tests, integration tests, and end-to-end tests with CI integration.

## Prerequisites
- Existing application with identifiable modules and API endpoints
- Package manager configured (npm, pip, etc.)
- Basic understanding of which components are most critical

## Phases

### Phase 1: Test Infrastructure Setup
- Install test framework (Jest, Vitest, pytest, Go test, etc.) matching project stack
- Configure test runner with sensible defaults (coverage thresholds, watch mode)
- Create test directory structure mirroring source structure
- Add test scripts to package.json / Makefile / equivalent
- Configure coverage reporting (minimum 60% for new code)
- Verify: `npm test` (or equivalent) runs and reports zero tests found (not errors)

### Phase 2: Unit & Integration Tests
- Write unit tests for core business logic (models, utilities, validators)
- Write integration tests for API endpoints (happy path + error cases)
- Write integration tests for database operations (CRUD, migrations)
- Mock external services (payment providers, email, third-party APIs)
- Verify: all tests pass; coverage report shows tested modules above threshold

### Phase 3: E2E Tests & CI Integration
- Set up E2E test framework (Playwright, Cypress, or equivalent) if frontend exists
- Write E2E tests for critical user flows (login, primary feature, checkout)
- Add test step to CI pipeline (run on every PR)
- Configure test parallelization if suite is slow
- Add test result badges to README
- Verify: CI pipeline runs tests; E2E tests pass in headless mode

## Skills Required
- Testing framework matching project stack
- CI/CD (GitHub Actions, GitLab CI, etc.)

## Security Invariants
- Test fixtures MUST NOT contain real user data or production secrets
- Test database MUST be isolated from production
- CI test runs MUST NOT have access to production credentials
