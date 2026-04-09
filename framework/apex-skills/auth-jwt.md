# Auth & JWT Patterns for APEX

## Token Conventions
- Access token: JWT, 15-minute expiry, httpOnly cookie
- Refresh token: opaque (not JWT), 7-day expiry, httpOnly+Secure+SameSite=Strict
- Never store tokens in localStorage (XSS vulnerable)
- Never put sensitive data in JWT payload (it's base64, not encrypted)

## Anti-Patterns — NEVER
- Never use symmetric signing (HS256) for distributed systems — use RS256/ES256
- Never skip token expiry validation on the server
- Never trust client-provided user IDs — extract from validated token
- Never send tokens in URL query parameters (logged by proxies)
- Never implement custom crypto — use established libraries (jose, jsonwebtoken)

## Auth Flow Pattern
```
1. Login: validate credentials → issue access + refresh tokens → set cookies
2. Request: middleware extracts token from cookie → validate → attach user to request
3. Refresh: access expired → send refresh token → validate → issue new pair → rotate refresh
4. Logout: clear cookies + invalidate refresh token in DB
```

## Security Checklist
- Rate limit login: 5 attempts per 15 minutes per IP
- Hash passwords: bcrypt with cost >= 12
- CSRF: SameSite=Strict cookies OR CSRF token for non-GET mutations
- Audit log: record login, logout, password change, permission escalation

## Testing
- Test expired tokens return 401 (not 500)
- Test invalid signatures return 401
- Test refresh rotation: used refresh token should be invalidated
- Test user A cannot access user B resources with valid token