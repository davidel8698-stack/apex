# Workflow: Deploy to Cloud

## Goal
Deploy an existing application to a cloud provider. Covers infrastructure setup, deployment pipeline, environment configuration, and production readiness.

## Prerequisites
- Working application that runs locally
- Cloud provider account (AWS, GCP, Azure, Vercel, Railway, Fly.io, or similar)
- Domain name (optional but recommended)
- Database provisioned or plan for managed database

## Phases

### Phase 1: Infrastructure Setup
- Choose deployment model (container, serverless, PaaS, or VM)
- Provision compute resources (ECS, Cloud Run, App Service, Fly machine, etc.)
- Provision managed database (RDS, Cloud SQL, Azure DB, or provider's offering)
- Configure networking (VPC, security groups, firewall rules)
- Set up DNS records (A/CNAME pointing to deployment)
- Verify: infrastructure provisioned; DNS resolves to deployment target

### Phase 2: Environment & Secrets Configuration
- Create production environment variable configuration
- Store secrets in cloud provider's secrets manager (not env files)
- Configure SSL/TLS certificate (Let's Encrypt, ACM, or provider-managed)
- Set up production database with connection pooling
- Configure log streaming to centralized logging
- Verify: secrets accessible from application; HTTPS working; database connected

### Phase 3: Deployment Pipeline
- Create deployment configuration (Dockerfile, buildpack, serverless config)
- Set up CI/CD pipeline: test → build → deploy (GitHub Actions, GitLab CI, etc.)
- Configure blue/green or rolling deployment strategy
- Add deployment notifications (Slack, email on success/failure)
- Verify: push to main triggers automated deployment; application accessible at production URL

### Phase 4: Production Validation
- Run smoke tests against production deployment
- Verify health check endpoint accessible externally
- Confirm monitoring and alerting are receiving production data
- Document rollback procedure (previous version, database rollback)
- Load test at expected traffic levels
- Verify: smoke tests pass; monitoring shows production traffic; rollback procedure tested

## Skills Required
- Cloud provider skill (aws, gcp, azure, vercel, fly)
- Docker (if containerized)
- CI/CD pipeline
- DNS configuration

## Security Invariants
- Secrets MUST be stored in secrets manager, never in source code or env files committed to git
- Database MUST NOT be publicly accessible (private subnet or IP allowlist)
- SSH/admin access MUST require key-based authentication
- Deployment credentials MUST use least-privilege IAM roles
- HTTPS MUST be enforced for all production traffic
