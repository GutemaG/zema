---
stage: plan
bolt: 031-accounts-backup-restore-ui
created: 2026-10-29T19:45:00Z
---

## Implementation Plan: accounts-backup-restore-ui (bolt 1 of 8)

### Objective

**Story 001, auth repository.** One interface for sign-in and one for the profile,
with three versions of each:

- the **interfaces** in `zema_core`
- a **Supabase version** in `zema_data`
- a **fake** for the app's tests

The session is kept in secure storage and survives restarts. A session that can't be
refreshed because the phone is offline stays signed in. One the server refuses
becomes the guest state. Builds with no backend have no account features. No screens
change yet. S04, S24 and Profile come in bolts 032–033.

### Deliverables

#### `zema_core`: `lib/src/account/account.dart` (new, exported)

- **`AuthUser`**: `id`, `email`, and Google's `name` and `avatarUrl` from the user
  metadata. Value equality.
- **`AccountRole`** enum: `contributor`, `moderator`, `admin`.
- **`Profile`**: `userId`, `displayName`, `avatarUrl`, `roles` (a set), and an
  `isModerator` getter that is true for moderators and admins. Value equality.
- **`displayNameMaxLength = 40`** and **`validateDisplayName(String)`**: returns the
  trimmed name, or throws `ValidationFailure` if it's empty or over 40 characters.
  This matches the server's check.
- **`AuthRepository`** (interface):
  - `AuthUser? get currentUser`
  - `Stream<AuthUser?> get userChanges`, which emits on every sign-in, sign-out and
    session loss
  - `Future<AuthUser?> restore()`: once at start, loads the saved session
  - `Future<AuthUser> signInWithGoogle({required String idToken, String? accessToken})`
  - `Future<void> signOut()`: always ends up signed out on the phone, even offline
- **`ProfileRepository`** (interface):
  - `Future<Profile> profile()`: the signed-in user's profile and roles
  - `Future<Profile> rename(String name)`: validates first, then saves, and returns
    the stored profile
- **New failures** in `failures.dart`:
  - `AuthFailure`: not signed in, the token was refused, or the session was lost
  - `ValidationFailure`: input the user can fix, such as a name that's too long

#### `zema_data`

- **`SessionStore`** (interface): `read`, `write(String)`, `clear`. Also
  `MemorySessionStore` for tests and tools.
- **`SupabaseAuthRepository`**: owns one `SupabaseClient` with `autoRefreshToken`
  on.
  - **`client`** is shared with the profile repository now, and the backup repository
    later. It isn't exported in the app's API surface: it's marked `@internal` by a
    doc comment, because the package has no `meta` dependency.
  - **Saving the session**: every `signedIn` or `tokenRefreshed` event writes the
    session JSON to the store. A sign-out clears it.
  - **`restore()`**:
    - No saved session: null.
    - Otherwise `recoverSession`.
    - **A network failure** (`AuthRetryableFetchException`, a timeout or
      `ClientException`) keeps the saved user as `currentUser`. That user is read
      from the stored JSON, so the app shows the signed-in state offline. Each later
      call that needs the server (`profile`, `rename`, and backups later) tries the
      refresh again first.
    - **Refused** (an invalid or used refresh token, or a deleted user): clears the
      store and returns null, which is the guest state.
  - **`signInWithGoogle`**: `signInWithIdToken(provider: google)`. Errors become
    `AuthFailure` (refused) or `NetworkFailure`.
  - **`signOut`**: `auth.signOut(scope: local)`. Network errors are ignored, and the
    store is always cleared.
  - **Errors** are mapped the same way as in the catalog repository, and tokens are
    never logged.
  - **`close()`**: disposes the client.
- **`SupabaseProfileRepository(SupabaseAuthRepository)`**:
  - **Reading**: `profiles` (`display_name`, `avatar_url`) and `user_roles`
    (`role`), for the current user.
  - **Renaming**: an update of `display_name`, `.select()` back.
  - **No user** gives `AuthFailure`. The server's `23514` (name check) gives
    `ValidationFailure`.

#### App

- **Dependency**: `flutter_secure_storage`. Android uses `EncryptedSharedPreferences`,
  and iOS the Keychain, accessible after first unlock (so the background backup in
  bolt 036 can read it).
- **`lib/features/account/data/secure_session_store.dart`**: a `SessionStore` over
  secure storage, under the key `supabaseSession`. Read errors (for example a
  Keystore reset after a restore) clear it and give null.
- **`lib/features/account/application/account_providers.dart`**:
  - `sessionStoreProvider`
  - `authRepositoryProvider`, which is null when the backend isn't configured, like
    the catalog
  - `profileRepositoryProvider`
  - `authUserProvider`: a `StreamProvider<AuthUser?>` that starts from `restore()`,
    then follows `userChanges`
  - `accountsAvailableProvider`: whether there's a backend. Bolt 032 adds the Google
    client IDs.
- **Tests**:
  - `test/helpers/fake_auth.dart`: `FakeAuthRepository`, which can be signed in or
    out, fail, or be offline, and records its calls. Also `FakeProfileRepository`.
  - `pumpZemaApp` gets `auth` and `profiles` parameters. By default it uses a
    signed-out fake, so every existing test keeps a guest.

### Dependencies

- **Bolts 029–030**: `profiles`, `user_roles` and the auth config.
- **`supabase` 2.16 / `gotrue` 2.27**: `recoverSession`, `signInWithIdToken`,
  `onAuthStateChange`. The behaviour when a refresh fails was checked in the `gotrue`
  source: a network failure keeps the session in storage but doesn't set it, and a
  refused token signs out.
- **`flutter_secure_storage`**: new.

### Technical Approach

- **The catalog stays anonymous** on its own client. Reports keep using the install
  hash, as 004 requires.
- **Google isn't available in tests.** The `zema_data` backend tests sign a user up
  with email on the local backend, using a separate client inside the test, and then
  hand that session to the repository's store. That exercises `restore()`, refresh,
  the profile, renaming and sign-out against the real auth server. The Google path
  itself is the one `signInWithIdToken` call, checked in bolt 032 once the client IDs
  exist.
- **An expired session** is made by changing `expires_at` in the stored JSON.
  **Offline** is a URL with nothing listening.

### Acceptance Criteria → Tests

| Criterion | Test |
|-----------|------|
| Interfaces and models in `zema_core`; name validation matches the server | `zema_core` unit tests (validation edges, equality, `isModerator`) |
| `zema_data` signs in (restore), reads the profile and roles, renames, signs out against the local backend | `backend_test` (tagged `backend`) |
| Session saved on sign-in and refresh, cleared on sign-out | `backend_test` + MockClient tests |
| Restart restores the session; an expired one is refreshed | `backend_test` (`expires_at` in the past → new access token, store updated) |
| Offline with an expired session stays signed in, and the next call retries | MockClient / bad-URL test |
| Refused refresh token → guest, store cleared | `backend_test` (a token from a signed-out session) |
| Errors mapped to `AuthFailure`, `NetworkFailure`, `ValidationFailure` | MockClient tests |
| No backend → no account providers | app provider test |
| The fake signs in, fails and cancels on demand; existing tests stay guests | app test of the fake + the full suite |
