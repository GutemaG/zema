---
id: 001-admin-app-and-sign-in
unit: 002-admin-website
intent: 008-admin-website
status: complete
priority: must
created: '2026-11-19T10:00:00Z'
assigned_bolt: 055-admin-website
implemented: true
---

# Story: 001-admin-app-and-sign-in

Admin app and sign-in

**As a** moderator
**I want** to sign in to the site with Google
**So that** only moderators get in

## Acceptance Criteria

- [x] **Given** the repo, **When** `apps/admin` is created (Flutter web, workspace member, `zema_core`/`zema_data`, app theme), **Then** `flutter analyze` and tests pass
- [x] **Given** a signed-out visitor, **When** they open the site, **Then** they see Sign in with Google (Supabase OAuth redirect, PKCE)
- [x] **Given** a signed-in user without the role, **When** the site loads, **Then** it shows Not a moderator and Sign out
- [x] **Given** a moderator, **When** signed in, **Then** a side bar shows Contributions, Fingerprints, Reports, Catalog
- [x] **Given** `apps/admin/tool/deploy.sh`, **When** run with the hosted config, **Then** it builds and runs `wrangler pages deploy`; `docs/admin-website.md` lists the one-time Cloudflare and Supabase redirect setup
