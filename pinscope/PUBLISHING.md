# Publishing PinScope to npm

This document is the one-shot instructions for publishing PinScope. Each
section is a single command — copy/paste in order.

## Prerequisites

- npm account (free) on https://npmjs.com
- The `pinscope` package name is **free** on the public registry as of
  2026-05-24 (verified via `npm view pinscope`).

## One-time setup

```bash
# Authenticate this machine to npm
npm adduser
# Follow the prompts (username, password, email, OTP if 2FA enabled)

# Verify
npm whoami
# Should print your username
```

## Publish (each time)

```bash
cd pinscope

# Make sure the build is current
npm run build

# Sanity: pre-publish pack dry-run (verifies tarball contents + no
# `data-pin` / `PinScope` strings will leak to consumers)
npm pack --dry-run

# Verify production-stripper AC-010 (must return 0)
grep -rc "data-pin\|PinScope\|pinscope" dist/ 2>/dev/null || echo "0 — clean"

# Publish to the public registry
npm publish

# Tag the git tree to mirror the npm version
cd ..
git tag -a pinscope-npm/v1.0.0 -m "PinScope 1.0.0 — first npm release (PS-R20 included)"
git push origin pinscope-npm/v1.0.0
```

## What gets published

- `dist/` — built TypeScript output (149 files, ~216KB unpacked)
- `package.json` with exports map:
  - `pinscope` → `./dist/index.js` (Vite plugin re-export)
  - `pinscope/vite` → `./dist/plugin/index.js` (the actual Vite plugin)
  - `pinscope/runtime` → `./dist/runtime/PinScope.js` (`<PinScope/>` React component)
  - `pinscope/next` → `./dist/plugin/next.js` (Next.js plugin)
  - `pinscope/webpack` → `./dist/plugin/webpack.js` (Webpack plugin)

NOT published (per `.npmignore` / `files` field):
- `src/` source files
- `tests/`
- `convergence/` self-healing loop artifacts
- `examples/`

## After publish

Users can install with:
```bash
npm install --save-dev pinscope
```

And the APEX-scaffolded project's `vite.config.ts` will look like:
```typescript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import pinscope from 'pinscope/vite';

export default defineConfig({
  plugins: [react(), pinscope()],
});
```

With `<PinScope/>` mounted once at the app root:
```tsx
import { PinScope } from 'pinscope/runtime';

// in your root layout
<>
  <App />
  <PinScope />
</>
```

## Versioning policy

- `1.X.Y` — PS-R{N} convergence rounds map to minor bumps
  (e.g., PS-R19 = 1.0.0; PS-R20 already integrated)
- `X.0.0` major bumps require a `pinscope/SPEC.md` `north_star_version`
  bump (the SPEC is FROZEN; only the user can authorize)
- Patch versions are reserved for fixes that don't touch ACs

## Rollback / deprecate

Within 72h of publishing a release:
```bash
npm unpublish pinscope@<VERSION>
```

After 72h, use deprecate instead:
```bash
npm deprecate pinscope@<VERSION> "rolled back — use VERSION instead"
```
