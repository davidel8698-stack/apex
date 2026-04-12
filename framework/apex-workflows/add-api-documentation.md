# Workflow: Add API Documentation

## Goal
Add interactive API documentation to an existing application. Covers OpenAPI/Swagger spec generation, interactive playground, and documentation hosting.

## Prerequisites
- Existing application with API endpoints
- Documentation format selected (OpenAPI 3.0/Swagger, or framework-native like FastAPI autodocs)

## Phases

### Phase 1: OpenAPI Spec Generation
- Install OpenAPI/Swagger library matching project stack (swagger-jsdoc, drf-spectacular, swag, etc.)
- Annotate existing endpoints with schema definitions (parameters, request body, responses)
- Define reusable schema components for shared data models
- Generate OpenAPI JSON/YAML specification file
- Validate spec with OpenAPI linter (no errors or warnings)
- Verify: valid OpenAPI spec generated; all endpoints documented; schema validates

### Phase 2: Interactive Documentation & Hosting
- Set up interactive documentation UI (Swagger UI, Redoc, or Scalar)
- Mount documentation at `/docs` or `/api-docs` endpoint
- Add authentication support in playground (try endpoints with real tokens)
- Add example request/response payloads for each endpoint
- Configure documentation auto-update on code changes (regenerate on build)
- Verify: documentation accessible at configured URL; endpoints testable from playground; examples accurate

## Skills Required
- OpenAPI / Swagger
- API framework matching project stack

## Security Invariants
- API documentation MUST NOT be publicly accessible in production (or require authentication)
- Example payloads MUST NOT contain real user data or production secrets
- Authentication tokens in playground MUST NOT be persisted or logged
- Internal-only endpoints MUST be excluded from public documentation
