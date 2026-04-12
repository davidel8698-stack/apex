# Workflow: Add Docker

## Goal
Containerize an existing application with Docker. Covers Dockerfile creation, multi-stage builds, docker-compose for local development, and production-ready image optimization.

## Prerequisites
- Existing application that runs locally
- Docker Desktop or Docker Engine installed
- Understanding of application's runtime dependencies (OS packages, language runtime, system libraries)

## Phases

### Phase 1: Dockerfile & Base Image
- Choose appropriate base image (language-specific slim or alpine variant)
- Create multi-stage Dockerfile: build stage (compile/install) → production stage (runtime only)
- Configure `.dockerignore` to exclude node_modules, .git, tests, docs, .env files
- Set non-root user in container (`USER appuser`)
- Define health check in Dockerfile (`HEALTHCHECK CMD`)
- Verify: `docker build` succeeds; image runs locally; health check passes

### Phase 2: Docker Compose & Local Development
- Create `docker-compose.yml` with application service, database, and dependencies (Redis, etc.)
- Configure volume mounts for hot-reload in development
- Add environment variable file support (`.env` → `env_file:`)
- Configure networking between services (app → database, app → cache)
- Add convenience scripts: `make up`, `make down`, `make logs`, `make shell`
- Verify: `docker-compose up` starts all services; application accessible at localhost; hot-reload works

### Phase 3: Production Optimization
- Minimize image size: remove build tools, use multi-stage, pin base image version
- Add image labels (version, maintainer, build date)
- Configure resource limits in compose (memory, CPU)
- Scan image for vulnerabilities (`docker scout`, `trivy`, or equivalent)
- Document image build and push process for CI/CD integration
- Verify: production image size reasonable (<500MB for most apps); no critical vulnerabilities; container starts in <10s

## Skills Required
- Docker
- DevOps / infrastructure

## Security Invariants
- Container MUST run as non-root user
- Secrets MUST NOT be baked into the image (use runtime env vars or secrets mount)
- Base image MUST be pinned to specific version (not `latest`)
- `.dockerignore` MUST exclude `.env`, credentials, and `.git`
- Image MUST have no critical vulnerabilities from scanner
