# Workflow: Add GraphQL API

## Goal
Add a GraphQL API layer to an existing application. Covers schema design, resolver implementation, authentication integration, and performance optimization.

## Prerequisites
- Existing application with data models and business logic
- GraphQL server library selected (Apollo Server, Yoga, Strawberry, gqlgen, or Juniper)
- Existing REST API or data access layer to build upon

## Phases

### Phase 1: Schema & Server Setup
- Install GraphQL server library matching project stack
- Design GraphQL schema: types, queries, mutations matching existing data models
- Configure GraphQL server endpoint (`/graphql`)
- Set up development tools: GraphQL Playground / GraphiQL / Apollo Studio
- Implement basic Query resolvers for primary entities (list, get by ID)
- Verify: GraphQL endpoint responds; playground accessible in development; queries return data

### Phase 2: Mutations & Auth
- Implement Mutation resolvers for create, update, delete operations
- Integrate authentication: extract user from request context (JWT/session)
- Add field-level authorization (users can only access data they own or are permitted to see)
- Implement input validation on all mutations
- Add error handling with proper GraphQL error format (extensions, codes)
- Verify: mutations work with valid auth; unauthorized mutations return auth error; validation errors return helpful messages

### Phase 3: Relationships & Performance
- Implement nested resolvers for entity relationships (user → posts → comments)
- Add DataLoader pattern to prevent N+1 query problem
- Implement pagination (cursor-based or offset-based) on list queries
- Add query complexity analysis and depth limiting (prevent abuse)
- Configure persisted queries for production (optional)
- Verify: nested queries resolve without N+1; pagination works; complex queries rejected above limit

### Phase 4: Subscriptions & Documentation
- Implement GraphQL subscriptions for real-time data (if applicable)
- Generate API documentation from schema (descriptions on types and fields)
- Add schema versioning strategy (deprecation annotations)
- Write integration tests for critical queries, mutations, and auth flows
- Verify: subscriptions deliver real-time updates; schema documentation complete; tests pass

## Skills Required
- GraphQL library matching stack (apollo, yoga, strawberry, gqlgen)
- Database skill matching project stack

## Security Invariants
- Query depth MUST be limited (prevent deeply nested attacks)
- Query complexity MUST be limited (prevent resource exhaustion)
- Introspection MUST be disabled in production
- All mutations MUST require authentication
- Field-level authorization MUST be enforced in resolvers (not just schema directives)
