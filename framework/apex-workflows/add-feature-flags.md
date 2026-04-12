# Workflow: Add Feature Flags

## Goal
Add feature flag management to an existing application. Covers flag infrastructure, evaluation logic, and gradual rollout capability.

## Prerequisites
- Existing application with features to gate
- Feature flag approach selected (LaunchDarkly, Unleash, GrowthBook, Flagsmith, or custom JSON/env-based)

## Phases

### Phase 1: Flag Infrastructure
- Install feature flag library or create simple flag evaluation module
- Configure flag source (remote service API key, local JSON file, or database table)
- Create flag evaluation function: `isEnabled(flagName, context?) → boolean`
- Add user/environment context to flag evaluation (user ID, environment, percentage rollout)
- Create initial flags for existing features that need gating
- Verify: flag evaluation returns correct values; flags configurable without code deploy

### Phase 2: Integration & Rollout
- Wrap target features with flag checks (both backend and frontend)
- Implement percentage-based rollout (e.g., enable for 10% of users, then 50%, then 100%)
- Add flag state to application logging (which flags active for each request)
- Create flag management UI or configure provider dashboard
- Implement flag override for testing (force enable/disable per user or session)
- Verify: features toggle on/off correctly; percentage rollout distributes consistently; overrides work

## Skills Required
- Feature flag service skill (launchdarkly, unleash, growthbook) or custom implementation
- Frontend and backend framework skills

## Security Invariants
- Flag evaluation MUST NOT expose flag configuration to unauthorized users
- Feature flag service API keys MUST be stored as secrets
- Sensitive features (admin panels, payment changes) MUST default to disabled
- Flag overrides in production MUST require admin permission
