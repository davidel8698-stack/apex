# Workflow: Add Role-Based Access Control (RBAC)

## Goal
Add role-based access control to an existing application with authentication. Covers role/permission modeling, authorization middleware, admin management UI, and audit logging.

## Prerequisites
- Existing authentication system (users can log in)
- Database configured
- Roles and permissions requirements defined (e.g., admin, editor, viewer)

## Phases

### Phase 1: Data Model & Role Assignment
- Create roles table: id, name, description, created_at
- Create permissions table: id, resource, action (read/write/delete/admin)
- Create role_permissions junction table
- Create user_roles junction table
- Seed default roles (admin, member, viewer) with appropriate permissions
- Add role assignment to user creation flow (default role: member)
- Verify: roles and permissions seeded; new users assigned default role; role-permission relationships queryable

### Phase 2: Authorization Middleware
- Create authorization middleware that checks user role + required permission per route
- Implement permission check helpers: `hasPermission(user, resource, action)`
- Apply middleware to all protected routes with appropriate permission requirements
- Return 403 Forbidden on unauthorized access (not 401 — user is authenticated but not authorized)
- Add resource-level ownership checks where applicable (users can edit their own resources)
- Verify: admin can access all routes; member has limited access; viewer is read-only; 403 returned for unauthorized

### Phase 3: Admin Management
- Create admin UI for managing roles: list, create, edit role permissions
- Create admin UI for assigning roles to users
- Add role change audit logging (who changed what role for whom, when)
- Implement role hierarchy (admin inherits all member permissions)
- Add API endpoint for checking current user's permissions (for frontend conditional rendering)
- Verify: admin can manage roles via UI; role changes logged; frontend hides unauthorized actions

### Phase 4: Testing & Edge Cases
- Test permission escalation prevention (user cannot assign themselves higher role)
- Test role removal behavior (what happens when last admin loses admin role)
- Test concurrent permission changes (role updated while user is active)
- Add integration tests for each role accessing each protected resource
- Verify: no privilege escalation possible; at least one admin always exists; tests pass for all role combinations

## Skills Required
- Authentication system matching project stack
- Database skill matching project stack
- Frontend framework skill (for admin UI)

## Security Invariants
- Authorization checks MUST happen server-side (frontend checks are UX only)
- Role assignment MUST require admin permission
- Users MUST NOT be able to escalate their own permissions
- At least one admin user MUST always exist (prevent lockout)
- All role changes MUST be audit logged with actor, target, old role, new role, timestamp
