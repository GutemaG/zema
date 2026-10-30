---
intent: 005-accounts-backup-restore
phase: inception
status: complete
created: '2026-10-23T22:16:40Z'
updated: '2026-10-29T16:20:00Z'
---

# Requirements: Accounts, Backup and Restore

> Source: `docs/roadmap.md` Stage 5 · screens: `docs/screens.md` S04, S24, S25, S25b, S26,
> C09 · Complexity ★★★☆☆ · Needs backend.

## Intent Overview

Optional Google sign-in, with backup and restore of the user's library data and settings
across phones. Guest mode stays the default.

The intent has two halves:

- **Sign-in and Profile.** These give a user an identity on the server. Intents 006
  (contributions), 008 (admin website), 009 and 012 build on it.
- **Backup and restore.** These are built on that identity.

## Business Goals

| Goal | Success Metric | Priority |
|------|----------------|----------|
| Seamless phone change | Phone A backs up, phone B restores: the same favorites, playlists and lyrics choices (for songs that are on B) and the same settings | Must |
| No forced accounts | Every feature that exists today works the same as a guest, with no new prompt in its way | Must |
| An identity for later intents | A signed-in user has a server profile with a role, which 006 can use for contributions and moderation | Must |

---

## Functional Requirements

### FR-1: Account choice (S04)

- **Description**: A one-time screen offering "Continue as guest" (the default and most
  prominent button) or "Sign in". It explains what an account adds: backup, restore on a
  new phone, and contributing lyrics later.
- **Acceptance Criteria**:
  - Shown once, on the first launch after this update, including on phones that already
    have the app. It is never shown again after either choice.
  - "Continue as guest" goes to Home. "Sign in" opens S24, and cancelling there also
    goes to Home.
  - There are no onboarding screens yet (S01–S03), so S04 shows before Home. When
    onboarding is built, S04 moves to its end.
- **Priority**: Must

### FR-2: Google sign-in (S24)

- **Description**: Google is the only way to sign in. The app uses the native Google
  account picker, and the Google ID token signs in to Supabase Auth
  (`signInWithIdToken`). There are no passwords, phone numbers or codes.
- **Acceptance Criteria**:
  - The screen shows the benefits list, "Continue with Google" and "Continue as guest".
  - On success, the profile is created with the Google name and avatar.
  - Cancelled sign-in returns to the previous screen with no message. A failure or no
    network returns with a short message.
  - After sign-in: if a backup exists for this user, S26 opens. Otherwise the user goes
    back to where they came from.
  - The session is kept across app restarts and refreshed automatically. An expired
    session that can't be refreshed shows the guest state and keeps all local data.
  - Builds without the Google client IDs hide the sign-in buttons, the way builds with
    no backend hide catalog features.
- **Priority**: Must

### FR-3: Profile (S25)

- **Description**: Opened from a new avatar (or guest icon) in the Home header. It
  replaces Home's current Settings entry, and Settings stays reachable from Profile.
- **Acceptance Criteria**:
  - **Signed in**: avatar, display name (editable, 1–40 characters, trimmed), role badge
    ("Contributor" by default, or "Moderator"), and links to Backup & sync, Settings and
    Sign out.
  - **Guest**: guest icon, a sign-in card, and a link to Settings.
  - Stats (lyrics added, synced, approved) and My contributions are not shown until 006.
  - The Google avatar is cached for offline use. With no avatar, the first letter of the
    name is shown.
  - Sign out asks for confirmation. It keeps all local data and stops auto backup.
- **Priority**: Must

### FR-4: Delete account

- **Description**: From Profile, the user can delete their account and their cloud
  backup. The Apple App Store and Google Play both require this for apps that offer
  accounts.
- **Acceptance Criteria**:
  - Two-step confirmation, which names what will be deleted.
  - The server deletes the user's profile, backup and auth user. The phone signs out and
    keeps its local data.
  - It works only online, and shows a message when offline.
- **Priority**: Must

### FR-5: Backup & sync (S25b)

- **Description**: Copies the user's library data and settings to a private backup on
  the server.
- **Included**:
  - favorites, with the date added
  - playlists: name, order, and entries in order
  - lyrics choices made by hand (a song linked by the user, or "no lyrics" chosen)
  - hidden folders and hidden songs
  - app settings: theme, palette, language, minimum track length, sleep timer default,
    gapless, pause on unplug, ducking
- **Not included**: audio files, play history, the play queue, and cached or downloaded
  lyrics, which are downloaded again from the catalog.
- **Track identity**: each track in the backup is stored as title, artist, album,
  duration and file name, not as the phone's own track ID.
- **Acceptance Criteria**:
  - Shows the last backup time, or "Never", and any last error.
  - "Back up now" works on any network. Offline, it shows a message.
  - "Auto backup" toggle, on by default after sign-in: at most once a day, on Wi-Fi
    only.
  - On Android, auto backup runs with the app closed (WorkManager). On iOS it runs on a
    best-effort basis (background fetch), and also when the app opens if the last backup
    is more than 24 hours old.
  - A backup replaces the previous one. Only the latest backup is kept.
  - The backup format has a version number, so 006 (sync offsets) and 007 (floating
    lyrics settings) can add sections later without breaking older backups.
- **Priority**: Must

### FR-6: Restore (S26)

- **Description**: After sign-in, or from Backup & sync, shows "We found your backup
  from <date>: N favorites, N playlists, settings", with Restore and Start fresh.
- **Acceptance Criteria**:
  - **Restore merges** into what's on the phone, and nothing local is removed:
    - favorites are added
    - a playlist with the same name gets its missing songs added at the end; others are
      created
    - lyrics choices are added where the track has none made by hand
    - settings are replaced by the backup's values
  - **Re-linking** matches each backed-up track to a track on this phone, in this order:
    1. file name and duration within ±2 s
    2. normalized title and artist (case, spacing and punctuation ignored) and duration
       within ±2 s
    - The match is never made on title alone.
  - When done, a summary shows the number restored and lists the songs not found on
    this phone.
  - **Start fresh** keeps the cloud backup and changes nothing on the phone. The next
    backup from this phone replaces the cloud backup only after a warning.
  - Restore is also available later from Backup & sync.
- **Priority**: Must

### FR-7: Songs not found are kept

- **Description**: Backed-up entries that didn't match any track stay saved on the
  phone, so they aren't lost from the cloud by the next backup.
- **Acceptance Criteria**:
  - Unmatched entries are kept locally, and included again in the next backup.
  - After a library rescan, the app tries to match them again. A match is added to its
    favorites or playlists.
- **Priority**: Should

### FR-8: Guest sign-in prompt (C09)

- **Description**: A reusable sheet shown when a guest tries a sign-in-only action. It
  says why an account is needed, and offers "Sign in" or "Not now".
- **Acceptance Criteria**:
  - It is used by Settings → Account & backup for guests. 006 will use it for
    contributing.
  - "Not now" closes it with no change.
- **Priority**: Must

### FR-9: Sign-in entry points

- **Description**: Apart from the one-time S04, sign-in is offered only from Profile,
  C09 (Settings → Account & backup, and Contribute from 006), and the restore prompt.
- **Acceptance Criteria**:
  - No other screen, player action or lyrics action asks the user to sign in.
- **Priority**: Must

### FR-10: Server profile and backup storage

- **Description**: New tables, policies and functions on the server.
- **Acceptance Criteria**:
  - **`profiles`**: one row per auth user, made on first sign-in, holding the display
    name and the avatar URL.
    - Users read and change only their own name.
  - **Roles**: the existing `user_roles` table from 004. A new user gets `contributor`.
    Users can read only their own roles, and roles can be changed only on the server
    (by 006 or 008), not by the app.
  - **`backups`**: one row per user, holding the JSON document, its format version, its
    size and the time it was updated.
    - Users read and write only their own row.
    - The size is limited to 2 MB on the server.
  - **Account deletion**: a server function deletes the profile, the backup and the auth
    user.
  - Covered by pgTAP tests (RLS, size limit, role not changeable, deletion).
- **Priority**: Must

---

## Non-Functional Requirements

### Security and Privacy

| Requirement | Standard | Notes |
|-------------|----------|-------|
| Authentication | Google ID token → Supabase Auth | No passwords, phone or OTP. Sessions are kept in secure storage (Keychain / Keystore) |
| Authorization | RLS | Users read and write only their own profile name and backup. The role is set on the server only |
| Keys | Only the public anon key and the Google client IDs in the app | No service key in the app or the repo. Client IDs come from the local config (gitignored), never committed |
| Privacy | — | Backups are private to the user. No audio or play history is uploaded. Deleting the account deletes the backup |

### Reliability

| Requirement | Metric | Target |
|-------------|--------|--------|
| Auto backup (Android) | Runs with the app closed | At least once per 24 h when the phone has been on Wi-Fi |
| Auto backup (iOS) | Best effort | Also runs on app open if the last backup is > 24 h old |
| Failed backup | Retried | The next scheduled run or "Back up now". The cloud copy is never left half written |
| Interrupted restore | Local data | Restore runs in one database transaction: all or nothing |

### Performance

| Requirement | Metric | Target |
|-------------|--------|--------|
| Backup size | 1,000 favorites + 50 playlists × 100 songs | < 1 MB of JSON |
| Restore re-linking | 2,000 backed-up entries against 5,000 tracks | < 2 s on a mid-range Android phone |
| Re-link accuracy | Same files copied to a new phone | ≥ 95% matched |

---

## Constraints

### Technical Constraints

**Project-wide standards**: Required standards will be loaded from memory-bank standards folder by Construction Agent

**Intent-specific constraints**:

- Re-linking relies on the track metadata from 002: title, artist, album, duration and
  path.
- **Google Cloud setup isn't done yet.** Until there's an OAuth client (Android with the
  app's SHA-1, iOS, and a web client for Supabase), sign-in is built and tested against
  a fake auth repository. The backup and RLS parts are tested against the local
  Supabase with test users. The setup steps are written as part of this intent.
- Reports (004) stay anonymous and keep using the install hash.

### Business Constraints

- Google sign-in only.

---

## Assumptions

| Assumption | Risk if Invalid | Mitigation |
|------------|-----------------|------------|
| File name + duration, or title + artist + duration, re-links most tracks | Many songs not found | FR-7 keeps them and retries after rescans. Manual re-linking can come later |
| Users have a Google account | Can't back up | Guest mode still works fully |
| WorkManager runs daily on most Android phones | Some vendors kill background work | "Back up now" and the last backup time are visible. Also backs up on app open after 24 h |

---

## Open Questions

| Question | Owner | Due Date | Resolution |
|----------|-------|----------|------------|
| Backup format: single JSON blob vs. normalized tables? | Product owner | Requirements | **One versioned JSON document per user** (2026-10-29) |
| Conflict policy when restoring onto a phone with local data? | Product owner | Requirements | **Merge**: nothing local is removed; settings come from the backup (2026-10-29) |
| Profile stats before 006? | Product owner | Requirements | **Hidden until 006** (2026-10-29) |
| Google Cloud project? | Product owner | Before the sign-in bolt's emulator check | **Not yet.** Built against a fake until the client IDs are added |
