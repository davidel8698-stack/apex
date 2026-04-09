# Next.js Patterns for APEX

## App Router Conventions
- All API routes: src/app/api/[resource]/route.ts
- Server components by default; 'use client' only when needed
- Layouts for shared UI: src/app/(group)/layout.tsx
- Loading states: loading.tsx per route segment
- Error boundaries: error.tsx per route segment

## Anti-Patterns — NEVER
- Never use pages/ directory (App Router only)
- Never use getServerSideProps (use server components)
- Never import server-only code in 'use client' components
- Never use window/document outside useEffect

## API Route Pattern
```typescript
export async function POST(req: Request) {
  try {
    const body = await req.json()
    // ... logic
    return Response.json({ data: result })
  } catch (error) {
    console.error('[API] /resource:', error)
    return Response.json(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    )
  }
}
```

## Testing
- Vitest for unit tests
- Playwright for E2E
- Test files: __tests__/ or *.test.ts co-located

## Common Gotchas
- Dynamic imports for heavy client components: `const Chart = dynamic(() => import('./Chart'), { ssr: false })`
- Environment variables: NEXT_PUBLIC_ prefix for client-side
- Middleware: src/middleware.ts (not inside app/)