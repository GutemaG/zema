---
unit: 001-accounts-backend
intent: 005-accounts-backup-restore
unit_type: backend
default_bolt_type: simple-construction-bolt
phase: inception
status: complete
created: '2026-10-29T19:05:45Z'
updated: '2026-10-29T19:05:45Z'
---

# Unit Brief: Accounts Backend

## Purpose

Gives signed-in users a server identity, with private storage for one backup each. All of it is enforced by RLS and proven with pgTAP against the local Supabase.

## Scope

### In Scope
- Google provider in `config.toml`, from env variables; setup guide in `docs/`
- `profiles` table, made by a trigger on sign-up, with `contributor` added to `user_roles`
- Users read their own profile and roles, and change only their own display name
- `backups` table: one row per user, JSON document, format version, 2 MB limit
- `delete_account()`: removes the profile, backup, roles and auth user

### Out of Scope
- Hosted project, real Google client IDs (added by the owner later)
- Moderator tools and role changes (006/008)

---

## Assigned Requirements

| FR | Requirement | Priority |
|----|-------------|----------|
| FR-2 | Google sign-in (server config) | Must |
| FR-3 | Profile (server data) | Must |
| FR-4 | Delete account (server function) | Must |
| FR-5 | Backup storage | Must |
| FR-10 | Server profile and backup storage | Must |

---

## Story Summary

| Metric | Count |
|--------|-------|
| Total Stories | 4 |
| Must Have | 4 |
| Should Have | 0 |
| Could Have | 0 |

### Stories

| Story ID | Title | Priority | Status |
|----------|-------|----------|--------|
| 001-profiles-and-roles | Profiles made on sign-up, with roles | Must | Planned |
| 002-google-auth-config | Google provider config and setup guide | Must | Planned |
| 003-backups-table | One private backup per user | Must | Planned |
| 004-delete-account-function | Delete account on the server | Must | Planned |

---

## Dependencies

### Depends On
| Unit | Reason |
|------|--------|
| 004 `001-cloud-lyrics-catalog-backend` | Schema, `user_roles`, grants pattern |

### Depended By
| Unit | Reason |
|------|--------|
| 002-accounts-backup-restore-ui | Sign-in, profile, backup, delete |
| Intents 006/008 | Contributor and moderator identity |

---

## Technical Context

### Suggested Technology
Supabase CLI via `npx supabase` (Docker), Postgres + pgTAP. Test users made in SQL inside rolled-back transactions, with `request.jwt.claims` set to act as them.

### Data Storage
| Data | Type | Volume | Retention |
|------|------|--------|-----------|
| Profiles | Postgres | One per user | Until the account is deleted |
| Backups | Postgres `jsonb` | One per user, < 2 MB | Latest only; deleted with the account |

---

## Constraints

- No service key or Google secret committed; `config.toml` reads them with `env()`.
- Users can never change roles, another user's row, or backups over 2 MB.
- Reports (004) stay anonymous and unchanged.

---

## Success Criteria

### Functional
- [ ] `supabase db reset` + `supabase test db` pass
- [ ] A new auth user gets a profile and the `contributor` role
- [ ] RLS: own rows only; role and other users' rows unreachable
- [ ] `delete_account` leaves nothing of the user behind

### Non-Functional
- [ ] Key scan clean; no secrets in the repo
