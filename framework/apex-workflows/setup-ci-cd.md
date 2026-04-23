# Workflow: Setup CI/CD Pipeline

## Goal
Create a continuous integration and deployment pipeline using GitHub Actions (or equivalent). Includes test, lint, build, and deploy stages with environment-specific configurations.

## Prerequisites
- Project hosted on GitHub (or GitLab/Bitbucket with equivalent CI)
- Test suite exists and passes locally
- Deployment target identified (Vercel, AWS, Railway, Docker, etc.)
- Environment variables documented

## Phases

### Phase 1: CI Pipeline — Test + Lint + Build
- Create `.github/workflows/ci.yml`:
  - Trigger: push to main, pull requests to main
  - Matrix: Node.js versions (or language-specific versions)
  - Steps: checkout, install dependencies, lint, type-check, test, build
- Configure caching for dependencies (node_modules, .next cache, etc.)
- Add status badge to README
- Set branch protection rules:
  - Require CI to pass before merge
  - Require at least 1 review
- Verify: CI runs on push and PR, fails on lint/test errors, passes on clean code

### Phase 2: CD Pipeline — Deploy
- Create `.github/workflows/deploy.yml`:
  - Trigger: push to main (after CI passes)
  - Environment: production (with manual approval for first setup)
  - Steps: checkout, install, build, deploy to target
- Configure deployment secrets:
  - Add deployment credentials to GitHub Secrets
  - Add environment variables to deployment target
- Add deployment notifications (Slack, Discord, or GitHub comment)
- Create staging environment for PRs (preview deployments if supported)
- Verify: deployment triggers on main push, staging preview on PR, rollback works

## Skills Required
- Framework-specific skill for build configuration
- Deployment platform documentation

## Pipeline Invariants
- NEVER commit secrets or API keys to workflow files
- CI MUST run the full test suite (no skipping tests for speed)
- Build artifacts MUST match what was tested (same dependencies, same env)
- Deployment MUST be reversible (keep previous deployment for rollback)
- Cache invalidation MUST be tied to lock file hash (package-lock.json, yarn.lock)

## Security Invariants
- All secrets MUST use GitHub Secrets (or equivalent vault), never environment file commits
- Workflow files MUST NOT echo or log secret values (mask with `::add-mask::`)
- Deployment tokens MUST have least-privilege scope (deploy only, no admin access)
- Third-party Actions MUST be pinned to specific SHA, not mutable tags (e.g., `actions/checkout@v4` -> `actions/checkout@<sha>`)
- Pipeline MUST NOT allow PRs from forks to access production secrets (use `pull_request_target` with caution)
