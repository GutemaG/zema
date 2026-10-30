---
stage: implement
bolt: 033-accounts-backup-restore-ui
created: 2026-10-30T08:54:15Z
---

## Implementation Walkthrough: accounts-backup-restore-ui (bolt 3 of 8)

### Summary

- **Home's header** shows the user's avatar, or a guest icon, in place of the
  Settings gear. It opens Profile (S25), and Settings now opens from there.
- **S25** shows the avatar, the name (editable), the role, Settings, Sign out and
  Delete account. A guest gets a sign-in card instead.
- **Offline**, the name and avatar come from the phone: the profile is saved in
  shared preferences and the image in a file.
- **Delete account** runs the server's `delete_account`, then signs out on the phone
  and disconnects Google. Any failure leaves the user signed in.

### Structure Overview

- **`zema_core` / `zema_data`**: `AuthRepository.deleteAccount()`, and its Supabase
  version.
- **`features/account/data/`**: `ProfileCache` (shared preferences) and
  `AvatarCache` (`FileAvatarCache`, files in the app support folder). The picker
  gains `disconnect()`.
- **`features/account/application/profile.dart`**: `profileProvider`,
  `avatarProvider`, and `accountActionsProvider` for sign-out and delete.
- **`features/account/presentation/`**: `ProfileScreen`, `AccountAvatar`,
  `ProfileButton` (Home's header) and the Edit name dialog.

### Completed Work

- [x] `packages/zema_core/lib/src/account/account.dart`:
  `AuthRepository.deleteAccount()`.
- [x] `packages/zema_data/lib/src/supabase_auth_repository.dart`: `deleteAccount`
  calls `delete_account` as the user through `run`, then `signOut()`. A failure is
  thrown before the sign-out, so the user stays signed in.
- [x] `lib/features/account/data/google_account_picker.dart`: `disconnect()`, which
  revokes Zema's access to the Google account. Like `signOut`, it never throws.
- [x] `lib/features/account/data/profile_cache.dart`: `profile.<userId>` as JSON
  (name, avatar URL, roles). Unreadable JSON reads as none.
- [x] `lib/features/account/data/avatar_cache.dart`:
  - `FileAvatarCache` keeps `avatar/<userId>` and the URL it came from in
    `<userId>.url`.
  - The same URL reads the file. A new URL downloads again, with a 10-second
    timeout.
  - Offline or on an HTTP error it keeps the older image, or gives null.
  - `clear()` deletes the folder.
- [x] `lib/features/account/application/profile.dart`:
  - `ProfileController`:
    - It waits for the restored user, then shows the saved profile and refreshes
      from the server after the first frame.
    - With nothing saved, it asks the server, and falls back to the Google name
      and photo when the server can't be reached.
    - `rename` saves to the server, then to the cache, and throws on failure.
  - `AccountActionsController`:
    - Its state is the running action (`signOut`, `deleteAccount`), or null.
    - A second call while one runs gives false.
    - Both actions forget the saved profile and clear the avatar folder.
- [x] `lib/features/account/presentation/widgets/account_avatar.dart`: the photo
  (`ClipOval`), a round `LetterTile` while loading, without a photo or if the image
  fails, and a guest icon for null.
- [x] `lib/features/account/presentation/widgets/profile_button.dart`: the avatar or
  guest icon (tooltip "Profile") with sign-in available. Without it, the Settings
  gear, as before.
- [x] `lib/features/account/presentation/widgets/rename_dialog.dart`: a field with a
  40-character counter. Save is off while the name is empty, unchanged or too long.
- [x] `lib/features/account/presentation/profile_screen.dart`, S25 at `/profile`:
  - **Signed in**:
    - The avatar (88), the name with an ellipsis and an edit button, and the role
      badge (the highest of Admin, Moderator and Contributor).
    - General: Settings. Account: Sign out, and Delete account in the error color.
  - **Guest**: the guest icon, "Guest", and a card with the benefits and Sign in
    (pushes S24, which pops back here). Then General: Settings.
  - **Sign out**: one confirmation (local data stays), then the "Signed out"
    message.
  - **Delete**:
    - The first dialog says what's deleted and what stays, with Continue.
    - The second has a red filled Delete.
    - While deleting, a barrier with "Deleting your account…" covers the screen and
      back is blocked.
    - A message afterwards: deleted, offline, or failed.
  - **Edit name**: on failure, an offline or a failed message.
- [x] `lib/app/routes.dart` and `router.dart`: `AppRoutes.profile`, above the shell.
- [x] `lib/features/home/presentation/home_screen.dart`: `ProfileButton` in place of
  the gear.
- [x] `lib/features/settings/presentation/widgets/settings_row.dart`: an optional
  `labelColor`.
- [x] **Strings**: 27 new English strings (`homeProfileTooltip`, `profile*`).
- [x] **Dependencies**: `http` and `path_provider`, both already in the lock file,
  are now direct dependencies of the app.
- [x] **Test helpers**:
  - `FakeAuthRepository.deleteAccount`, with `deleteFailure`, `deleteGate` and
    `deleteCalls`.
  - `FakeGoogleAccountPicker.disconnectCalls`.
  - `FakeAvatarCache`, with a real 1×1 PNG, the default in `accountOverrides` and
    `pumpZemaApp(avatars:)`.

### Key Decisions

- **Builds without sign-in keep the Settings gear.** They have no accounts, so a
  Profile screen would only lead to Settings.
- **A small cache of our own, not a package.** `cached_network_image` would bring
  sqflite and a cache manager for one image. A file and a URL beside it cover it,
  and sit behind an interface for tests.
- **The saved profile shows first.** The refresh runs after the first frame, so the
  server's answer can't be overwritten by the saved one. A failed refresh keeps
  what's shown, with no error.
- **Delete: server first.** Only after `delete_account` succeeds does the phone sign
  out, disconnect Google and forget the cache. So offline or a server error changes
  nothing.
- **The actions controller holds the running action, not an `AsyncValue`.** The
  overlay names only deleting; sign-out is quick and shows just a spinner. Failures
  are thrown to the screen, as `rename` does.
- **The fake's `restore` no longer clears a user who signed in first.** Home now
  reads the signed-in user, which restores after an S04 → S24 sign-in. The real
  store would hold the new session, so the fake now behaves the same.

### Deviations from Plan

- **The busy overlay is part of S25, not a dialog**, so back and taps are blocked
  without a second route to pop.
- **The sign-out confirmation names only local data.** Auto backup (bolt 036) will
  follow the signed-in user, so it has nothing to stop yet.

- **Added in the test stage, after the emulator run:**
  - The sign-out and delete messages look up the `ScaffoldMessenger` before the
    action. Signing out removes the Account rows before the action returns, so
    their context was gone and the message never showed.
  - `FileAvatarCache.sized` asks Google for a 256-pixel photo instead of 96
    (`=s96-c`), which looked blurry at 88 pixels.

### Dependencies Added

- [x] `http` ^1.6.0 and `path_provider` ^2.1.6 as direct dependencies (no new
  packages in the lock file)

### Developer Notes

- **Restoring the session** now first happens when Home, S25 or the avatar reads
  the user. Nothing read it before this bolt.
- **The Backup & sync link** goes into S25's Account group in bolt 035.
