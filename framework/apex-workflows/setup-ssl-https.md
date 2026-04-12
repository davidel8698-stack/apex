# Workflow: Setup SSL/HTTPS

## Goal
Configure SSL/TLS and enforce HTTPS for an existing application. Covers certificate provisioning, HTTPS configuration, and security headers.

## Prerequisites
- Application deployed and accessible via HTTP
- Domain name configured with DNS pointing to server
- Server access (or cloud provider configuration access)

## Phases

### Phase 1: Certificate Provisioning
- Choose certificate source: Let's Encrypt (free, automated), cloud provider (ACM, Cloud SSL), or purchased certificate
- Install certificate management tool (certbot for Let's Encrypt, or configure cloud provider)
- Generate or provision SSL certificate for domain (include www subdomain if applicable)
- Configure automatic certificate renewal (Let's Encrypt: certbot cron job; cloud: auto-managed)
- Verify: certificate issued successfully; `openssl s_client -connect domain:443` shows valid cert

### Phase 2: HTTPS Configuration & Enforcement
- Configure web server (Nginx, Apache, Caddy) or load balancer for HTTPS
- Set up HTTP → HTTPS redirect (301 permanent redirect on port 80)
- Configure HSTS header (Strict-Transport-Security: max-age=31536000; includeSubDomains)
- Set secure cookie flags on all cookies (Secure, HttpOnly, SameSite)
- Update application configuration to use HTTPS URLs (canonical URLs, OAuth callbacks, webhooks)
- Verify: HTTP requests redirect to HTTPS; HSTS header present; cookies have Secure flag; SSL Labs score A or A+

## Skills Required
- Web server configuration (nginx, apache, caddy)
- DNS management
- SSL/TLS

## Security Invariants
- HTTP MUST redirect to HTTPS (no mixed content)
- HSTS MUST be enabled with minimum 1 year max-age
- TLS 1.2 MUST be the minimum supported version (disable TLS 1.0/1.1)
- Private key MUST have restricted file permissions (600)
- Certificate renewal MUST be automated (prevent expiry downtime)
