---
intent: 008-admin-website
phase: inception
status: units-decomposed
updated: 2026-11-19T10:00:00Z
---

# Admin Website - Unit Decomposition

As in 006: a backend unit first, then the site.

### Unit 1: 001-moderation-backend

The server functions the site needs that don't exist yet: reading and resolving
reports, and listing, hiding and restoring songs. pgTAP-tested on local Supabase.

**Stories**: 001-reports-for-moderators, 002-hide-and-restore-songs

### Unit 2: 002-admin-website

`apps/admin` in Flutter web: sign-in and role gate, the contribution and fingerprint
queues, reports, catalog, and the Cloudflare Pages deploy.

**Stories**: 001-admin-app-and-sign-in, 002-contribution-review, 003-fingerprint-review,
004-reports-page, 005-catalog-page

## Bolts

| Bolt | Unit | Stories |
|------|------|---------|
| 054-moderation-backend | 1 | 001, 002 |
| 055-admin-website | 2 | 001 (app, sign-in, first deploy) |
| 056-admin-website | 2 | 002, 003 |
| 057-admin-website | 2 | 004, 005 |
