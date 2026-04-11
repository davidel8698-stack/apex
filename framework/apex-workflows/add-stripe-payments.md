# Workflow: Add Stripe Payments

## Goal
Integrate Stripe for one-time payments and/or subscriptions. Includes checkout flow, webhook handling, and customer portal.

## Prerequisites
- Existing web application with authentication
- Stripe account with API keys (test mode)
- Database for storing customer/subscription records
- HTTPS endpoint reachable for webhooks (or Stripe CLI for local dev)

## Phases

### Phase 1: Stripe SDK + Configuration
- Install Stripe SDK (server + client)
- Add STRIPE_SECRET_KEY, STRIPE_PUBLISHABLE_KEY, STRIPE_WEBHOOK_SECRET to environment
- Create Stripe utility module with initialized client
- Add customers table: id, user_id, stripe_customer_id, created_at
- Verify: Stripe client initializes without errors, test API call succeeds

### Phase 2: Checkout Flow
- Create Stripe customer on user registration (or lazily on first purchase)
- POST /api/payments/create-checkout-session — creates Stripe Checkout session
- Redirect user to Stripe-hosted checkout page
- Handle success/cancel redirect URLs
- Create orders/subscriptions table for tracking
- Verify: checkout session creates successfully, redirect URLs work

### Phase 3: Webhook Handling
- POST /api/webhooks/stripe — receives Stripe events
- Verify webhook signature using STRIPE_WEBHOOK_SECRET
- Handle events: checkout.session.completed, invoice.paid, invoice.payment_failed, customer.subscription.updated, customer.subscription.deleted
- Update local database records on each event
- Idempotency: handle duplicate webhook deliveries gracefully
- Verify: webhook signature validation works, events update database correctly

### Phase 4: Customer Portal + Subscription Management
- POST /api/payments/create-portal-session — Stripe Customer Portal
- Display current subscription status in user dashboard
- Handle subscription cancellation and reactivation
- Show payment history from local records
- Verify: portal session creates, subscription status displays correctly

### Phase 5: Error Handling + Edge Cases
- Handle card declined scenarios gracefully
- Handle Stripe API downtime (retry with exponential backoff)
- Handle webhook delivery failures (Stripe retries automatically)
- Add logging for all payment events
- Test with Stripe test cards (4242... success, 4000... decline)
- Verify: all error paths display user-friendly messages

## Skills Required
- stripe
- auth-jwt (authentication must exist)
- Database skill matching project stack

## Security Invariants
- NEVER log full card numbers or Stripe secret keys
- ALWAYS verify webhook signatures before processing
- Store Stripe customer IDs, never raw payment data
- Use Stripe Checkout (PCI-compliant) instead of custom card forms
- All payment amounts calculated server-side, never trust client
