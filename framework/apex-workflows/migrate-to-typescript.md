# Workflow: Migrate to TypeScript

## Goal
Incrementally migrate an existing JavaScript project to TypeScript. Covers configuration, incremental adoption, type definitions, and CI enforcement.

## Prerequisites
- Existing JavaScript project (Node.js, React, Vue, or similar)
- Build toolchain in place (webpack, Vite, esbuild, or tsc)
- Team agreement on strictness level (strict recommended, but incremental is acceptable)

## Phases

### Phase 1: TypeScript Configuration
- Install TypeScript and type definitions for dependencies (`@types/*`)
- Create `tsconfig.json` with incremental adoption settings (`allowJs: true`, `strict: false` initially)
- Configure build toolchain to handle `.ts`/`.tsx` files alongside `.js`/`.jsx`
- Rename entry point file from `.js` to `.ts` (verify build still works)
- Add `tsc --noEmit` to CI pipeline as type-check step
- Verify: project builds with mixed JS/TS files; type-check runs in CI

### Phase 2: Core Module Migration
- Migrate shared utilities and helpers first (most imported, fewest dependencies)
- Add type definitions for core data models (interfaces/types for entities)
- Migrate API layer (request/response types, API client)
- Migrate database layer (query types, model types)
- Fix type errors incrementally (use `// @ts-expect-error` sparingly for complex cases)
- Verify: core modules are `.ts`; no `any` in migrated core modules; build passes

### Phase 3: Feature Module Migration
- Migrate feature modules in dependency order (leaf modules first)
- Add component prop types (React) or prop definitions (Vue) where applicable
- Remove `allowJs: true` once all files migrated
- Enable `strict: true` and fix remaining type errors
- Remove all `@ts-expect-error` and `@ts-ignore` comments
- Verify: all files are `.ts`/`.tsx`; strict mode enabled; zero type errors; CI passes

### Phase 4: Type Safety Enforcement
- Add ESLint TypeScript rules (`@typescript-eslint/recommended-type-checked`)
- Configure pre-commit hook for type checking
- Document TypeScript conventions for the team (naming, utility types, generics usage)
- Add type coverage tracking (aim for >95%)
- Verify: ESLint catches type issues; pre-commit prevents type regressions; coverage tracked

## Skills Required
- TypeScript
- Build toolchain matching project (webpack, vite, esbuild)
- ESLint configuration

## Security Invariants
- Type definitions MUST NOT weaken runtime validation (types are compile-time only)
- `any` type MUST NOT be used to bypass security-critical type checks
- External data (API responses, user input) MUST be validated at runtime even with types
