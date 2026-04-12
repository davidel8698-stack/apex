# Workflow: Add OAuth Social Login

## Goal
Add social login (Google, GitHub, Facebook, etc.) to an existing application with authentication. Covers OAuth provider setup, callback handling, and account linking.

## Prerequisites
- Existing authentication system (email/password login working)
- OAuth provider developer accounts created (Google Console, GitHub Developer Settings, etc.)
- Redirect URIs determined for each environment (dev, staging, production)

## Phases

### Phase 1: OAuth Provider Configuration
- Register application with selected OAuth providers (get client ID + secret)
- Install OAuth library matching project stack (Passport.js, NextAuth, OmniAuth, etc.)
- Configure OAuth client credentials via environment variables
- Implement OAuth redirect endpoint: redirect user to provider's authorization URL
- Implement OAuth callback endpoint: exchange authorization code for access token
- Verify: OAuth redirect sends user to provider login; callback receives authorization code

### Phase 2: Account Linking & User Flow
- Extract user profile from OAuth provider (email, name, avatar)
- Handle account creation for new OAuth users (create user, mark as OAuth-linked)
- Handle account linking for existing users (same email → link OAuth to existing account)
- Handle multiple OAuth providers per account (user can link Google AND GitHub)
- Create UI: social login buttons on login/register pages, linked accounts in settings
- Verify: new OAuth user gets account created; existing user with same email gets linked; multiple providers linkable

### Phase 3: Edge Cases & Security
- Handle OAuth token refresh (if using refresh tokens for API access)
- Handle provider account disconnection (user unlinks social login)
- Ensure users with only OAuth login can set a password (fallback access)
- Handle email verification differences (some providers verify email, some don't)
- Add CSRF protection to OAuth flow (state parameter)
- Verify: token refresh works; account unlinking works; users without password can set one; state parameter validated

## Skills Required
- OAuth library matching stack (passport, nextauth, omniauth)
- Authentication system matching project stack

## Security Invariants
- OAuth client secrets MUST be stored as environment variables, never in frontend code
- State parameter MUST be used in OAuth flow (CSRF protection)
- Email from OAuth provider MUST be verified before auto-linking to existing account
- OAuth tokens MUST be stored encrypted if persisted
- Callback URLs MUST be validated against allowlist
