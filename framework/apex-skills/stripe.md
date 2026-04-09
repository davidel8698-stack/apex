# Stripe Patterns for APEX

## Setup
- Server-only: stripe SDK in server code only
- Webhook endpoint: src/app/api/webhooks/stripe/route.ts
- Keys: STRIPE_SECRET_KEY (server), NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY (client)

## Anti-Patterns — NEVER
- Never log full Stripe event payloads (contain PII)
- Never trust client-side price calculations
- Never skip webhook signature verification
- Never store card details — use Stripe Elements

## Webhook Pattern
```typescript
export async function POST(req: Request) {
  const body = await req.text()
  const sig = req.headers.get('stripe-signature')!

  let event: Stripe.Event
  try {
    event = stripe.webhooks.constructEvent(body, sig, webhookSecret)
  } catch (err) {
    return Response.json({ error: 'Invalid signature' }, { status: 400 })
  }

  // Always return 200 quickly — process async if heavy
  switch (event.type) {
    case 'checkout.session.completed':
      // handle
      break
  }

  return Response.json({ received: true })
}
```

## Idempotency
- Use idempotency keys for all create operations
- Check event.id against processed events table before handling
- Stripe may send the same event multiple times

## Testing
- Use Stripe CLI: stripe listen --forward-to localhost:3000/api/webhooks/stripe
- Test mode keys only in development
- Mock Stripe in unit tests, real Stripe in integration tests (verify_level=D)