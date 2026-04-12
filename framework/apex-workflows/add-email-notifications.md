# Workflow: Add Email Notifications

## Goal
Add transactional email capability to an existing application. Covers email service integration, template system, sending logic, and delivery tracking.

## Prerequisites
- Existing application with user accounts (or email recipients)
- Email service selected (SendGrid, Postmark, AWS SES, Resend, or SMTP)
- Sender domain verified with DNS records (SPF, DKIM, DMARC)

## Phases

### Phase 1: Email Service Integration
- Install email service client library matching provider
- Configure API key / SMTP credentials via environment variables
- Create email utility module with send function (to, subject, html, text)
- Implement email template system (Handlebars, Jinja2, or provider templates)
- Create base email layout template (header, footer, branding)
- Add email sending to background job queue (don't block request)
- Verify: test email sends successfully; template renders correctly; background job processes

### Phase 2: Transactional Emails
- Implement welcome email on user registration
- Implement password reset email with secure token link
- Implement account activity notifications (login from new device, password changed)
- Implement application-specific notifications (order confirmation, invoice, etc.)
- Add unsubscribe link for non-critical notifications
- Verify: each email type triggers at the correct event; unsubscribe works

### Phase 3: Delivery & Reliability
- Add email delivery webhook handler (bounce, complaint, delivery notifications)
- Implement retry logic for failed sends (3 retries with exponential backoff)
- Log all email events (sent, delivered, bounced, complained)
- Add email sending rate limiting (respect provider limits)
- Create admin view for email delivery status (optional)
- Verify: bounces logged; retries work; rate limiting prevents provider throttling

## Skills Required
- Email service skill (sendgrid, ses, postmark, resend)
- Background job processing

## Security Invariants
- Email templates MUST escape user-provided content (prevent HTML injection)
- Password reset tokens MUST be single-use, time-limited, and cryptographically random
- Unsubscribe MUST NOT require authentication (one-click per CAN-SPAM)
- Email API keys MUST be stored as secrets, never in source code
- Bounce handling MUST NOT expose internal system details in error responses
