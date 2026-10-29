---
stage: implement
bolt: 031-accounts-backup-restore-ui
created: 2026-10-29T19:52:19Z
---

## Implementation Walkthrough: accounts-backup-restore-ui (bolt 1 of 8)

### Summary

- `zema_core` now defines what an account is: `AuthUser`, `Profile` and
  `AccountRole`, the name rule, and the `AuthRepository` and `ProfileRepository`
  interfaces.
- `zema_data` implements them on Supabase Auth. The session is saved to a pluggable
  store, and a saved session is restored at once and checked in the background.
- The app keeps the session in secure storage, and exposes the repositories and the
  signed-in user through providers.
- Tests use fakes, and are guests by default. No screen changes in this bolt.

### Structure Overview

- **`zema_core`** holds the contracts.
- **`zema_data`**:
  - `SupabaseAuthRepository` owns the user's `SupabaseClient`. The profile
    repository, and the backup repository later, make their calls through its `run`.
  - The catalog keeps its own anonymous client.
  - The error mapping and the timeout HTTP client are now shared by all the
    repositories.
- **App**: `features/account/` holds the secure session store and the providers.

### Completed Work

- [x] **`packages/zema_core/lib/src/account/account.dart`**
  - **Models**: `AuthUser`, `AccountRole`, and `Profile` (with `isModerator` and
    `copyWith`).
  - **The name rule**: `displayNameMaxLength` and `validateDisplayName`. Characters
    are counted as code points, as Postgres's `char_length` does.
  - **Interfaces**: `AuthRepository` and `ProfileRepository`.
- [x] **`packages/zema_core/lib/src/failures.dart`**: `AuthFailure` and
  `ValidationFailure`.
- [x] **`packages/zema_data/lib/src/session_store.dart`**: the `SessionStore`
  interface and `MemorySessionStore`.
- [x] **`packages/zema_data/lib/src/supabase_auth_repository.dart`**
  - **Sign-in**: with a Google ID token.
  - **The session**: saved on sign-in and on refresh, with writes kept in order, and
    cleared on sign-out.
  - **`restore()`**: returns the saved user without waiting. It checks the session in
    the background (`confirmed`). A refusal signs out. Offline, the session is kept
    and checked again before the next call.
  - **`run()`**: for calls made as the user. A refused session becomes
    `AuthFailure`, after one refresh attempt.
  - **`signOut`**: always ends signed out, even offline.
- [x] **`packages/zema_data/lib/src/supabase_profile_repository.dart`**
  - Reads the profile and the roles, and renames, filtered by the user's ID.
  - Validates the name before sending.
- [x] **`packages/zema_data/lib/src/backend_errors.dart`** (moved out of the catalog
  repository)
  - `backendFailure` now has a `userSession` mode: a JWT refusal becomes
    `AuthFailure`, and `23514` becomes `ValidationFailure`.
  - `TimeoutClient` is shared. The catalog's behaviour is unchanged.
- [x] **`packages/zema_data/lib/zema_data.dart`, `pubspec.yaml` and `README.md`**:
  the exports, the package description, and an Accounts section.
- [x] **`apps/mobile/lib/features/account/data/secure_session_store.dart`**
  - On iOS, the Keychain, readable after the first unlock and never moved to another
    device. On Android, the Keystore, reset if it can't be read.
  - A session that can't be read is cleared.
- [x] **`apps/mobile/lib/features/account/application/account_providers.dart`**
  - `sessionStoreProvider`, `authRepositoryProvider`,
    `profileRepositoryProvider` and `accountsAvailableProvider`.
  - `authUserProvider`: restores once, then follows every change.
- [x] **`apps/mobile/pubspec.yaml`**: `flutter_secure_storage` ^11.2.0.
- [x] **`apps/mobile/test/helpers/fake_auth.dart`**:
  - `FakeAuthRepository`: sign-in as a chosen user, a failure, a gate, a lost
    session, and a record of the calls made.
  - `FakeProfileRepository`.
  - `accountOverrides`.
- [x] **`apps/mobile/test/helpers/pump_app.dart`**: `auth` and `profiles`
  parameters. The default is a signed-out fake.

### Key Decisions

- **`restore()` doesn't wait for the server.** On a failed refresh, `gotrue` retries
  for up to about 10 seconds, which would hold app start offline. So the saved user
  is signed in at once, and a refusal arrives later on `userChanges`.
- **Lists instead of `maybeSingle()`.** `postgrest`'s `maybeSingle` rethrows a
  server error inside its own `catch`, which swaps the error code (`23514`) for the
  HTTP status (`400`). Found by a unit test.
- **The profile repository uses the auth repository's client**, so calls carry the
  user's token. The catalog's client stays anonymous, so reports keep the install
  hash.
- **iOS `first_unlock_this_device`.** It allows the background backup (bolt 036),
  and keeps an iCloud restore from carrying a session to another phone.

### Deviations from Plan

- **`restore()` returns at once, and `confirmed` was added.** The plan had
  `restore()` waiting for the refresh. Changed because of the offline wait above.
- **`backendFailure` and `TimeoutClient` were moved** into a shared file. That
  wasn't listed in the plan, but the new repositories needed them.

### Dependencies Added

- [x] `flutter_secure_storage` ^11.2.0: keeps the session in the Keystore or
  Keychain. It needs Android minSdk 24, which is Flutter's default.

### Developer Notes

- **Nothing reads `authUserProvider` yet.** S04, S24 and Profile (bolts 032–033)
  are its first users.
- **For backend tests**, make an expired session with an unsigned stand-in access
  token whose `exp` is in the past. `gotrue` reads the expiry from the token, not
  from `expires_at`.
