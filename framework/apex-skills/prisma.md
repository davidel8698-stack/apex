# Prisma Patterns for APEX

## Schema Conventions
- File: prisma/schema.prisma
- Models: PascalCase singular (User, not users)
- Fields: camelCase
- Relations: explicit with @relation

## Anti-Patterns — NEVER
- Never use raw SQL when Prisma query exists
- Never skip migrations (always prisma migrate dev)
- Never use findFirst without unique constraint awareness
- Never ignore @updatedAt field on mutable models

## Query Pattern
```typescript
const result = await prisma.user.findUnique({
  where: { id: userId },
  include: { posts: true }
})

if (!result) {
  throw new Error(`User ${userId} not found`)
}
```

## Migrations
- Generate: npx prisma migrate dev --name description
- Deploy: npx prisma migrate deploy
- Reset: npx prisma migrate reset (dev only)

## Common Gotchas
- Connection pooling: use connection limit in DATABASE_URL for serverless
- Transactions: use prisma.$transaction for multi-step operations
- Soft deletes: add deletedAt field, filter in queries