---
intent: 005-accounts-backup-restore
phase: inception
status: units-decomposed
updated: 2026-10-29T19:05:45Z
---

# Accounts, Backup and Restore - Unit Decomposition

## Units Overview

As in 004, the intent splits into **2 units**:

- **A backend unit**: auth config, tables, RLS and functions, built and tested with
  pgTAP against the local Supabase.
- **The app unit**: `zema_core`/`zema_data` code, the screens, backup and restore.

Both use the simple construction bolt. Sign-in comes first, because it's what later
intents need. Backup and restore follow.

### Unit 1: 001-accounts-backend

**Description**: The Google provider in the local Supabase Auth config, with the Google
Cloud setup guide. Also `profiles` (made on sign-up, with `contributor` in
`user_roles`), `backups` (one JSON row per user, 2 MB limit), `delete_account`, and
pgTAP tests for all of it.

**Stories**:

- 001-profiles-and-roles
- 002-google-auth-config
- 003-backups-table
- 004-delete-account-function

**Deliverables**:

- `backend/supabase/migrations/` (profiles, backups, delete_account)
- `backend/supabase/config.toml` (Google provider from env variables)
- `backend/supabase/tests/database/` (pgTAP)
- `docs/google-sign-in-setup.md`

**Dependencies**:

- Depends on: intent 004's backend (schema, `user_roles`)
- Depended by: `002-accounts-backup-restore-ui`; intents 006 and 008

**Estimated Complexity**: S

### Unit 2: 002-accounts-backup-restore-ui

**Description**:

- **Sign-in**: the auth repository (`zema_core` interface, `zema_data` Supabase
  implementation, fake for tests); S04, S24, S25 with the Home avatar, delete account,
  C09 and the sign-in entry points.
- **Backup and restore**: the versioned backup document and track identity in
  `zema_core`; Back up now and auto backup (S25b); re-linking and merge; S26; keeping
  unmatched entries.

**Stories**:

- 001-auth-repository
- 002-account-choice
- 003-google-sign-in
- 004-profile
- 005-delete-account
- 006-guest-prompt-and-entry-points
- 007-backup-document
- 008-backup-now
- 009-auto-backup
- 010-relink-and-merge
- 011-restore-screen
- 012-unmatched-entries-kept

**Deliverables**:

- `packages/zema_core` (auth and backup interfaces, backup document, track matcher)
- `packages/zema_data` (Supabase auth, profile and backup repositories)
- `apps/mobile/lib/features/account/` (new): S04, S24, S25, S25b, S26, C09
- Drift schema v7 (unmatched entries), WorkManager setup, ARB strings in en
- Unit, Drift, widget and emulator checks against the local backend

**Dependencies**:

- Depends on: `001-accounts-backend`, intents 001–004
- Depended by: intents 006 (contributions), 008, 012

**Estimated Complexity**: L

## Requirement-to-Unit Mapping

- **FR-1** Account choice (S04) → `002-accounts-backup-restore-ui` (002)
- **FR-2** Google sign-in (S24) → backend (002); ui (001, 003)
- **FR-3** Profile (S25) → backend (001); ui (004)
- **FR-4** Delete account → backend (004); ui (005)
- **FR-5** Backup & sync (S25b) → backend (003); ui (007, 008, 009)
- **FR-6** Restore (S26) → ui (010, 011)
- **FR-7** Songs not found are kept → ui (012)
- **FR-8** Guest sign-in prompt (C09) → ui (006)
- **FR-9** Sign-in entry points → ui (006)
- **FR-10** Server profile and backup storage → backend (001, 003, 004)

## Unit Dependency Graph

```text
[004 backend: schema, user_roles] (complete)
     │
     ▼
[001-accounts-backend]
     │
     ▼
[002-accounts-backup-restore-ui]
```

## Execution Order

Bolts have 1–2 stories each, so each finishes in one session:

1. Bolt 029: profiles + roles, Google auth config and setup guide (backend 001–002)
2. Bolt 030: backups table + delete_account (backend 003–004)
3. Bolt 031: auth repository (ui 001)
4. Bolt 032: account choice S04 + Google sign-in S24 (ui 002–003)
5. Bolt 033: Profile S25 + delete account (ui 004–005)
6. Bolt 034: C09 + entry points, backup document (ui 006–007)
7. Bolt 035: Back up now, S25b (ui 008)
8. Bolt 036: auto backup (ui 009)
9. Bolt 037: re-linking and merge (ui 010)
10. Bolt 038: restore screen S26 + unmatched entries kept + intent checks (ui 011–012)
