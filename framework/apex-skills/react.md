# React Patterns for APEX

## Component Conventions
- Functional components only (no class components)
- Props interface co-located above component: `interface Props { ... }`
- Custom hooks for shared logic: `useAuth`, `useDebounce`, `useFetch`
- Prefer composition over prop drilling — use context for 3+ level nesting

## Anti-Patterns — NEVER
- Never mutate state directly (use spread/map/filter to create new references)
- Never use array index as key when list can reorder
- Never call hooks inside conditions, loops, or nested functions
- Never store derived state — compute it during render
- Never use useEffect for things that can be computed from props/state

## State Management Pattern
```tsx
// Local: useState for component-scoped state
// Shared: useContext + useReducer for cross-component state
// Server: tanstack-query or SWR for remote data (not useEffect+fetch)
```

## Testing
- Vitest + React Testing Library for unit tests
- Test behavior not implementation: `getByRole`, `getByText` over `getByTestId`
- User-event over fireEvent for realistic interaction simulation
- Mock external services at the network boundary (MSW), not at import level

## Common Gotchas
- Stale closure in useEffect/useCallback — add all dependencies to dep array
- useEffect cleanup: return cleanup function for subscriptions, timers, AbortController
- Strict Mode double-renders in dev — design effects to be idempotent
- Ref vs state: ref changes don't trigger re-render (use for DOM refs, timers, previous values)
- Memoization: `useMemo`/`useCallback` only when profiler shows actual performance issue