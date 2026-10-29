---
stage: test
bolt: 031-accounts-backup-restore-ui
created: 2026-10-29T19:59:08Z
---

## Test Report: accounts-backup-restore-ui (bolt 1 of 8)

### Summary

- **Tests**: all pass.
  - App: 820 (10 new).
  - `zema_core`: 209 (8 new).
  - `zema_data`: 47 (19 new). 7 of those are tagged `backend` and run against the
    local backend.
- **Checks**:
  - `flutter analyze` and `dart analyze` are clean, and `dart format` changes
    nothing.
  - The Android debug APK and the iOS simulator app both build with
    `flutter_secure_storage`.
- **Planted bugs**: 14. 13 were caught. 1 survived, but that change does nothing,
  because the same sign-out is also done elsewhere (see below).
- **No emulator check**: this bolt has no screens. The first one is in bolt 032.

### Test Files

- [x] `packages/zema_core/test/account/account_test.dart` (8)
  - **Name rule**:
    - Names are trimmed. 1 and 40 characters pass.
    - Empty, spaces-only and 41-character names fail.
    - 40 Ge'ez letters or 40 emoji pass, and 41 emoji fail: characters, not UTF-16
      units.
    - The limit is 40.
  - **Roles**:
    - `isModerator` is true for moderators and admins only.
    - The default role is `contributor`.
  - **Equality**:
    - `Profile` ignores the order of roles, and `copyWith` works.
    - `AuthUser` has value equality.
- [x] `packages/zema_data/test/supabase_auth_repository_test.dart` (12, a fake HTTP
  client)
  - **Restoring**:
    - Nothing saved: a guest, with no request.
    - An unreadable saved session is cleared.
    - A valid saved session signs in at once, with no request.
  - **Google sign-in**:
    - It sends `grant_type=id_token` with the provider, the ID token and the access
      token, then saves the session and tells listeners.
    - A refused token gives `AuthFailure` and stays a guest.
    - No connection gives `NetworkFailure`.
    - The name falls back to Google's `name` field, and a blank name counts as none.
  - **Signing out offline** still signs out and clears the store.
  - **Profiles**:
    - They need a user, and send no request otherwise.
    - A bad name is refused before any request.
    - The server's `23514` becomes `ValidationFailure`.
    - The profile and known roles are read with the user's token and filtered by
      the user's ID. Unknown roles are ignored.
- [x] `packages/zema_data/test/account_backend_test.dart` (7, the local backend)
  - Each test signs a user up by email with a separate client, hands its session to
    the repository, and deletes the user afterwards with `delete_account`.
  - **Restore**: gives the user, then the profile (the name trimmed by the server),
    the avatar and the `contributor` role.
  - **Rename**: trimmed. A 41-character or blank name is refused, and the stored
    name is kept.
  - **An expired session** is refreshed in the background, and the new access token
    is saved.
  - **Sign-out**:
    - It clears the store and sends null.
    - The profile then gives `AuthFailure`.
    - The server session survives a local sign-out.
  - **A revoked session** (a global sign-out elsewhere) signs in at first, then
    becomes a guest, and the store is cleared.
  - **Offline with an expired session**:
    - It stays signed in, and keeps the saved session.
    - The profile gives `NetworkFailure`.
    - Back online, the same saved session refreshes.
  - **After `delete_account`**, the profile gives `AuthFailure`.
- [x] `packages/zema_data/test/backend_test.dart`: now uses the shared
  `support/local_backend.dart`. No other change.
- [x] `apps/mobile/test/features/account/account_providers_test.dart` (10)
  - **No backend**: no repositories and no accounts, and the user is null.
  - **With a backend**:
    - The Supabase repositories over the session store.
    - With nothing saved, a guest, without reaching the server.
  - **`authUserProvider`**:
    - It restores once, then follows sign-in and sign-out.
    - A saved session restores the user.
    - A lost session becomes a guest.
  - **The fakes**:
    - A failure is thrown once.
    - Profiles need a user, and `rename` validates.
    - The backend-less overrides are null.
  - **`SecureSessionStore`**:
    - It writes, reads and clears, using the plugin's mock.
    - A read error clears the session and gives none.

### Planted Bugs (14; each patched into the source, tested, then restored)

- **Caught (13)**:
  - restore doesn't sign in at once
  - the session isn't saved on sign-in
  - sign-out keeps the store
  - a refused sign-in is treated as offline
  - an offline session is never retried
  - the profile isn't filtered by user
  - rename skips validation
  - the server's name check isn't mapped
  - no `name` fallback
  - the name counted in UTF-16 units
  - admins can't moderate
  - the provider misses the restored user
  - an unreadable session isn't cleared
- **Survived, and the change does nothing: "a refused session isn't signed out" in
  `_recover`**
  - When the server refuses a refresh, `gotrue` itself removes the session and sends
    `signedOut`. The repository's listener signs out on that event.
  - So the behaviour stays right without the line. It's kept as a second guard, for
    a refusal that comes without the event.
- **After restoring**: every suite passes again.

### Acceptance Criteria Validation

- ✅ **The interfaces and models are in `zema_core`, and the name rule matches the
  server's**: `account_test`, with code points on both sides.
- ✅ **`zema_data` restores, reads the profile and roles, renames and signs out
  against the local backend**: `account_backend_test`.
- ✅ **The session is saved on sign-in and refresh, and cleared on sign-out**: unit and
  backend tests.
- ✅ **A restart restores the session, and an expired one is refreshed**: the backend
  test.
- ✅ **Offline with an expired session stays signed in, and the next call retries**:
  the backend test.
- ✅ **A refused session becomes the guest state, and the store is cleared**: the
  backend test.
- ✅ **Errors become `AuthFailure`, `NetworkFailure` or `ValidationFailure`**: unit
  tests.
- ✅ **A build with no backend has no account providers**: the app provider test.
- ✅ **The fake signs in, fails and stays a guest on demand, and existing tests stay
  guests**: the fake tests, plus the full suite (820 pass).

### Issues Found

- **Fixed during this stage**: `maybeSingle()` lost server error codes. Profile reads
  now use lists.
- **Fixed during this stage**: `restore()` waited about 10 seconds offline, because
  of `gotrue`'s retries. It now returns at once.

### Notes

- **One test failure printed a test user's access token.** It was a throwaway local
  user's JWT, not a project key, and that user was deleted. The assertion now
  compares tokens without printing them.
- **Each offline test takes about 25 seconds**, because `gotrue` retries for about
  10 seconds per refresh.
- **The real Google token exchange** is checked in bolt 032, once the Google Cloud
  client IDs are set up.
