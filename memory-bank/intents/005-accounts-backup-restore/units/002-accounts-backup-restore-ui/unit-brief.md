---
unit: 002-accounts-backup-restore-ui
intent: 005-accounts-backup-restore
unit_type: frontend
default_bolt_type: simple-construction-bolt
phase: inception
status: stories-defined
created: '2026-10-29T19:05:45Z'
updated: '2026-10-29T19:05:45Z'
---

# Unit Brief: Accounts, Backup and Restore UI

## Purpose

Optional Google sign-in with a Profile in the app, then backup and restore of the user's library data and settings, with tracks re-linked by metadata on a new phone.

## Scope

### In Scope
- `zema_core`: `AuthRepository`, `ProfileRepository`, `BackupRepository` interfaces; backup document (versioned) and track identity; track matcher
- `zema_data`: Supabase implementations; fakes for tests
- `google_sign_in` + `signInWithIdToken`; session in secure storage
- Screens: S04, S24, S25 (+ Home avatar), delete account, C09, S25b, S26
- Auto backup: WorkManager (Android), background fetch + on open (iOS)
- Drift v7: unmatched backup entries; merge in one transaction
- ARB strings in en (am/om/ti fall back to English)

### Out of Scope
- Profile stats and My contributions (006)
- Manual re-linking of songs not found
- Sync offsets and floating lyrics settings in the backup (006/007 add sections)

---

## Assigned Requirements

| FR | Requirement | Priority |
|----|-------------|----------|
| FR-1 | Account choice (S04) | Must |
| FR-2 | Google sign-in (S24) | Must |
| FR-3 | Profile (S25) | Must |
| FR-4 | Delete account | Must |
| FR-5 | Backup & sync (S25b) | Must |
| FR-6 | Restore (S26) | Must |
| FR-7 | Songs not found are kept | Should |
| FR-8 | Guest sign-in prompt (C09) | Must |
| FR-9 | Sign-in entry points | Must |

---

## Story Summary

| Metric | Count |
|--------|-------|
| Total Stories | 12 |
| Must Have | 11 |
| Should Have | 1 |
| Could Have | 0 |

### Stories

| Story ID | Title | Priority | Status |
|----------|-------|----------|--------|
| 001-auth-repository | Auth and profile repositories | Must | Planned |
| 002-account-choice | Account choice once (S04) | Must | Planned |
| 003-google-sign-in | Sign in with Google (S24) | Must | Planned |
| 004-profile | Profile and Home avatar (S25) | Must | Planned |
| 005-delete-account | Delete account | Must | Planned |
| 006-guest-prompt-and-entry-points | Guest sign-in prompt (C09) and entry points | Must | Planned |
| 007-backup-document | Versioned backup document | Must | Planned |
| 008-backup-now | Back up now (S25b) | Must | Planned |
| 009-auto-backup | Daily auto backup on Wi-Fi | Must | Planned |
| 010-relink-and-merge | Re-link tracks and merge | Must | Planned |
| 011-restore-screen | Restore on a new phone (S26) | Must | Planned |
| 012-unmatched-entries-kept | Songs not found are kept | Should | Planned |

---

## Dependencies

### Depends On
| Unit | Reason |
|------|--------|
| 001-accounts-backend | Auth config, profiles, backups, delete_account |
| Intents 001–004 | Library, playlists, links, settings, `zema_data` |

### Depended By
| Unit | Reason |
|------|--------|
| Intents 006/008/012 | Signed-in identity, C09 |

---

## Technical Context

### Suggested Technology
`google_sign_in`, `supabase` (already in `zema_data`), `flutter_secure_storage` for the session, `workmanager`, Riverpod 3, Drift, go_router.

### Data Storage
| Data | Type | Volume | Retention |
|------|------|--------|-----------|
| Session | Secure storage | One | Until sign-out |
| Unmatched entries | Drift | Small | Until matched or the account changes |
| Last backup time / auto toggle | Preferences | Tiny | Permanent |

---

## Constraints

- Google client IDs come from the gitignored local config; builds without them hide sign-in.
- No `Color(0x…)` literals outside `lib/app/theme/`; no user-visible string literals.
- iOS build must keep compiling.
- Sign-in is tested against a fake until the Google Cloud project exists.

---

## Success Criteria

### Functional
- [ ] Guest flow unchanged except the one-time S04
- [ ] Phone A backup → phone B (emulator, wiped) restore gives the same favorites, playlists, choices and settings
- [ ] Delete account removes everything on the server

### Non-Functional
- [ ] Backup < 1 MB for 1,000 favorites + 50 × 100 playlists; re-link 2,000 vs 5,000 < 2 s
- [ ] Analyze and format clean; all tests pass
