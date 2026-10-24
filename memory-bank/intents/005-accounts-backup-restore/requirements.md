---
intent: 005-accounts-backup-restore
phase: inception
status: draft
created: 2026-10-23T22:16:40Z
updated: 2026-10-23T22:16:40Z
---

# Requirements: Accounts, Backup and Restore

> Source: `docs/roadmap.md` Stage 5 · screens: `docs/screens.md` S04, S24, S25, S25b, S26,
> C09 · Complexity ★★★☆☆ · Needs backend.

## Intent Overview

Optional Google sign-in, with backup and restore of the user's library data and settings
across phones. Guest mode remains the default.

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| Seamless phone change | Phone A backup → phone B restore gives same favorites/playlists (for songs present on B) and same settings | Must |
| No forced accounts | All non-contribution features work as guest | Must |

---

## Functional Requirements

### FR-1: Account choice (S04)
- **Description**: "Continue as guest" (default) or "Sign in"; explains what an account adds.
- **Priority**: Must

### FR-2: Google sign-in (S24)
- **Description**: Google only via Supabase Auth; name/avatar from Google; cancel/failure returns with a short message; after sign-in → S26 if a backup exists, else back to origin.
- **Priority**: Must

### FR-3: Profile (S25)
- **Description**: Avatar, editable display name, role badge, stats, links (My contributions, Backup & sync, Settings, Sign out); guest variant with sign-in card.
- **Priority**: Must

### FR-4: Backup & sync (S25b)
- **Description**: Back up favorites, playlists (with track identity: title, artist, duration, file name), song matches, sync offsets, floating-lyrics settings, app settings. Manual "Back up now" and automatic (daily on Wi-Fi). Shows last backup time. Audio files never included.
- **Priority**: Must

### FR-5: Restore on new phone (S26)
- **Description**: Summary of found backup; Restore re-links playlists/favorites to tracks on this phone and lists songs not found; "Start fresh" keeps cloud backup.
- **Priority**: Must

### FR-6: Guest sign-in prompt (C09)
- **Description**: Shown when a guest attempts a sign-in-only action.
- **Priority**: Must

### FR-7: Sign-in entry points
- **Description**: Sign-in offered only from Profile, Contribute, or backup prompts.
- **Priority**: Must

---

## Non-Functional Requirements

### Security
| Requirement | Standard | Notes |
|-------------|----------|-------|
| Authentication | Google OAuth via Supabase Auth | No passwords/phone/OTP |
| Authorization | RLS | Users read/write only their own backup |
| Privacy | — | Backups private to the user; no audio uploaded |

### Reliability
| Requirement | Metric | Target |
|-------------|--------|--------|
| Auto backup | Runs daily when on Wi-Fi | Survives app being closed (WorkManager-style scheduling) |

---

## Constraints

### Technical Constraints

**Project-wide standards**: Required standards will be loaded from memory-bank standards folder by Construction Agent

**Intent-specific constraints**:
- Re-linking depends on the track identity chosen in 002.

### Business Constraints
- Google sign-in only.

---

## Assumptions

| Assumption | Risk if Invalid | Mitigation |
|------------|-----------------|------------|
| Title+artist+duration+file name re-links most tracks | Many "not found" | Fuzzy match with normalization; show manual re-link |
| Users have a Google account | Can't back up | Guest mode still fully works |

---

## Open Questions

| Question | Owner | Due Date | Resolution |
|----------|-------|----------|------------|
| Backup format: single JSON blob vs. normalized tables? | Construction | Before design | Pending |
| Conflict policy when restoring onto a phone with existing local data (merge vs replace)? | Product owner | Requirements review | Pending |
