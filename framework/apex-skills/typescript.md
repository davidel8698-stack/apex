# TypeScript Patterns for APEX

## Type Conventions
- Strict mode always (`strict: true` in tsconfig.json)
- Interface for object shapes, type for unions/intersections/mapped types
- Prefer `unknown` over `any` — narrow with type guards
- Export types alongside their implementations, not from barrel files

## Anti-Patterns — NEVER
- Never use `any` (use `unknown` + type guard or generics)
- Never use `as` type assertion to silence errors — fix the underlying type
- Never use `!` non-null assertion in production code (acceptable in tests)
- Never use `enum` — use `as const` objects or union types instead
- Never use `@ts-ignore` — use `@ts-expect-error` with explanation if truly needed

## Common Patterns
```typescript
// Discriminated unions for state machines
type State = { status: 'idle' } | { status: 'loading' } | { status: 'error'; error: Error }

// Zod for runtime validation at system boundaries
const UserSchema = z.object({ name: z.string(), email: z.string().email() })
type User = z.infer<typeof UserSchema>

// Utility types: Pick, Omit, Partial, Required, Record
// Prefer narrow types over broad — string literal unions over plain string
```

## Testing
- Use `satisfies` for type-level assertions in test fixtures
- Type-check test files: include `__tests__` in tsconfig
- Prefer `vitest` or `jest` with ts-jest — no separate compile step

## Common Gotchas
- Structural typing: objects with extra properties still match narrower types
- Optional chaining `?.` returns `undefined`, not null — handle both
- `Promise<void>` vs `void`: async functions always return Promise
- Index signatures `[key: string]` disable excess property checking
- `satisfies` preserves literal types while `as const` makes everything readonly