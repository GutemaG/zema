---
stage: plan
bolt: 033-accounts-backup-restore-ui
created: 2026-10-30T08:38:00Z
---

## Implementation Plan: accounts-backup-restore-ui (S25 profile, delete account)

### Objective

A Profile screen (S25) opened from an avatar on Home, where a signed-in user sees
their account, edits their name, signs out or deletes their account, and a guest
finds a sign-in card. Settings moves into Profile.

### Deliverables

- **Delete account in the repositories**:
  - `AuthRepository.deleteAccount()` in `zema_core`.
  - `SupabaseAuthRepository`: calls the `delete_account` function as the user, then
    signs out on this phone. Offline gives `NetworkFailure` and stays signed in. A
    server error gives its failure and stays signed in.
  - The test fake gets it too.
- **Google sign-out**:
  - `GoogleAccountPicker.disconnect()`, alongside the existing `signOut()`.
    Disconnecting revokes Zema's access, for delete account.
  - Both swallow errors: the user is already signed out of Zema by then.
- **Cached profile** (`features/account/application/profile.dart`):
  - `profileProvider` gives the signed-in user's `Profile`, or null for a guest.
  - It shows the last saved profile at once, then the server's.
  - The profile is saved in shared preferences as JSON, keyed by user ID, so offline
    S25 shows the saved name.
  - Without a saved profile, it falls back to the Google name and avatar on
    `AuthUser`.
  - `rename(name)` saves to the server, then updates the cache. Offline or on
    failure, it throws and the old name stays.
- **Avatar cache** (`features/account/data/avatar_cache.dart`):
  - The avatar image is downloaded once and saved as a file in the app's support
    folder. Offline, S25 and Home show that file.
  - The folder is cleared on sign-out and delete.
  - It's behind an interface, so tests use a fake.
  - A letter tile with the name's first letter (reusing `LetterTile`) shows while
    loading, without a photo, or when the download fails.
- **Home header**:
  - With sign-in available, the Settings gear becomes an avatar button (signed in)
    or a guest icon (guest), which opens S25.
  - Builds without sign-in keep the gear. They have no accounts, so a Profile
    screen would only be a link to Settings.
- **S25 profile** at `/profile`, above the shell like Settings:
  - **Signed in**:
    - Avatar, name with an edit button, and a role badge (Contributor, Moderator or
      Admin).
    - Links: Settings, Sign out, and Delete account in red.
    - Backup & sync is added in bolt 035, when S25b exists. Stats and My
      contributions are intent 006.
  - **Guest**: the guest icon, a sign-in card (the benefits and Sign in, opening
    S24), and Settings.
  - A long name ends with an ellipsis, with no overflow at 1.3× text.
- **Edit name**: a dialog with the current name and a 40-character counter. Save is
  off when the name is empty or unchanged.
  - Saved: the new name shows.
  - Offline: "No connection", and the old name stays.
  - Other failures: "Couldn't save your name".
- **Sign out**:
  - A confirmation dialog: local data stays on this phone.
  - Then the auth sign-out, Google sign-out, and the avatar cache cleared.
  - S25 switches to the guest version, with a "Signed out" message.
  - Auto backup (bolt 036) will follow the signed-in user, so it stops with the
    sign-out. Nothing to stop yet.
- **Delete account**, two dialogs:
  1. What will be deleted (account, profile, cloud backup), and that songs,
     playlists and favorites on this phone stay.
  2. A short warning that it can't be undone, and a red Delete button.
  - While deleting: a progress dialog that can't be dismissed.
  - Done: the phone is signed out, Google disconnected, the cache cleared, S25 shows
    the guest version, and an "Account deleted" message.
  - Offline: "No connection", still signed in, nothing changed.
  - Server error: "Couldn't delete your account", still signed in.
- **Settings**: unchanged, but opened from Profile. Its route stays `/settings`, so
  existing links and tests still work.
- **Strings**: English, as in bolt 032 (am, om and ti fall back to English).
- **Dependencies**:
  - `path_provider` and `http`, which are already in the lock file through drift and
    Supabase, become direct dependencies of the app.
  - No new packages.

### Dependencies

- **Bolt 030**: the server's `delete_account` function, whose cascades remove the
  profile, roles, backup and sessions.
- **Bolt 031**: `ProfileRepository.profile()` and `rename()`, and
  `authUserProvider`.
- **Bolt 032**: the picker seam, S24, and `signInAvailableProvider`.
- **The local backend**, for the emulator checks.

### Technical Approach

- **Offline first.** S25 never waits on the network to show something. It uses the
  cached profile, then the `AuthUser`'s Google name, and updates when the server
  answers. A failed refresh keeps what's shown, with no error on screen.
- **One action controller** for S25 (rename, sign out, delete), like
  `SignInController`. It ignores a second tap while busy, and holds the failure for
  the SnackBar.
- **Delete account order**: server first. Only after it succeeds does the phone sign
  out and disconnect Google. Any failure leaves everything as it was.
- **The avatar cache** writes `avatar/<userId>`, and keeps the URL beside it. A new
  URL downloads again. Downloads are skipped when there's no URL.
- **Tests**:
  - Repository tests for `deleteAccount` against the local backend (real user,
    function call, rows gone), and against a fake HTTP client for offline and server
    errors.
  - Widget tests for Home, S25 (signed in, guest, offline with the cache), rename,
    sign-out and delete flows, and fit at 1.3× in light and dark.
  - On the emulator: open S25 from the Home avatar, rename, sign out, sign in again,
    then delete the account, and check on the local backend that the user's rows are
    gone.

### Acceptance Criteria

- [ ] Home shows the avatar (signed in) or guest icon (guest) that opens S25; Settings opens from S25. Builds without sign-in keep the gear
- [ ] S25 signed in shows avatar, name, role badge, Settings, Sign out and Delete account
- [ ] Editing the name to 1–40 characters saves it on the server; offline, a message shows and the old name stays
- [ ] Sign out, after confirming, shows the guest version, keeps local data and signs out of Google
- [ ] S25 as a guest shows the guest icon, a sign-in card opening S24, and Settings
- [ ] Offline, S25 shows the cached avatar and name
- [ ] A long name ends with an ellipsis at 1.3× text, with no overflow
- [ ] Delete account: the first dialog names what's deleted and that local data stays; the second has a red Delete
- [ ] Confirmed online, `delete_account` runs, the phone signs out and Google is disconnected
- [ ] Offline or a server error: a message shows and the user stays signed in
- [ ] On the emulator: the user's rows are gone on the local backend after deleting
- [ ] Analyze and format clean; all tests pass; key scan clean; no `*.local.*` file staged
