---
stage: plan
bolt: 032-accounts-backup-restore-ui
created: 2026-10-29T20:20:00Z
---

## Implementation Plan: accounts-backup-restore-ui (S04 account choice, S24 sign in)

### Objective

A one-time choice between guest and sign-in before Home (S04), and the Google sign-in
screen (S24) that signs in to Supabase with the Google ID token. Builds without Google
client IDs or without a backend skip S04 and hide every sign-in button.

### Deliverables

- **Google config** `lib/features/account/data/google_config.dart`: `GoogleConfig`
  from `--dart-define` (`ZEMA_GOOGLE_WEB_CLIENT_ID`, `ZEMA_GOOGLE_IOS_CLIENT_ID`, from
  the gitignored `config/google.local.json`). `isConfigured` needs the web ID, and on
  iOS also the iOS ID.
- **Account picker seam** `lib/features/account/data/google_account_picker.dart`:
  - `GoogleAccountPicker.pick()` returns `GoogleTokens{idToken, accessToken?}`, or null
    when the user cancels; it throws a `ZemaFailure` otherwise.
  - `PluginGoogleAccountPicker` over `google_sign_in` 7.x: `initialize(clientId: iOS
    ID, serverClientId: web ID)` once, then `authenticate()`. The `canceled` exception
    becomes null; other errors become `AuthFailure` or `NetworkFailure`.
- **Providers** in `account_providers.dart`:
  - `googleConfigProvider` and `googleAccountPickerProvider` (tests override both).
  - `signInAvailableProvider`: a backend, Google IDs and a picker. Every sign-in button
    reads this, now and in later bolts.
  - `SignInController` (an AsyncNotifier): pick, then `signInWithGoogle`. Cancel leaves
    it idle with no error; a failure keeps the user a guest and holds the failure for
    a message.
- **S04 account choice** `lib/features/account/presentation/account_choice_screen.dart`
  at `/welcome`:
  - It explains what an account adds: contribute lyrics, back up, restore on a new
    phone.
  - **Continue as guest** is the main (filled) button and **Sign in** is secondary.
  - Either button saves the `accountChoiceShown` preference. Guest goes to Home; Sign in
    replaces S04 with S24.
- **Router**: a top-level `redirect`. Opening Home goes to `/welcome` when the choice
  hasn't been saved, sign-in is available and no one is signed in. Killing the app on
  S04 shows it again, because the flag is saved only on a button press.
- **S24 sign in** `lib/features/account/presentation/sign_in_screen.dart` at
  `/sign-in`:
  - The benefits list, **Continue with Google** and **Continue as guest**.
  - While signing in, the Google button shows progress and both buttons are disabled.
  - Cancelling the picker keeps S24 with no message. A failure shows a short SnackBar:
    "No connection" or "Couldn't sign in".
  - Success, Continue as guest and back all go back to where the user came from: they
    pop when there is something underneath, and go Home when it was opened from S04.
  - S26 (a backup was found) comes in bolt 037.
- **Platform setup**:
  - `google_sign_in: ^7.2.0` in the pubspec.
  - iOS: `Info.plist` gets a `CFBundleURLTypes` entry, `$(GOOGLE_REVERSED_CLIENT_ID)`.
    Its value comes from a gitignored `ios/Flutter/Google.local.xcconfig`, included
    with `#include?` from Debug and Release, so no client ID is committed. A
    `tool/google_env.sh` writes that file from `config/google.local.json`.
  - Android: nothing beyond the Cloud client (package and SHA-1), which is done.
- **Strings**: added in en, am, om and ti.
- **Docs**: the run commands in `docs/google-sign-in-setup.md` and `apps/mobile/README`.

### Dependencies

- **Bolt 031:** `AuthRepository.signInWithGoogle`, `authUserProvider`, and the fakes.
- **Bolt 029:** the Google provider in `config.toml`. The local backend now has your
  three client IDs and the web secret in `backend/supabase/.env`.
- **`google_sign_in` 7.x:** Credential Manager on Android, GoogleSignIn SDK on iOS. Its
  ID token's audience is the web client ID, which Supabase accepts.

### Technical Approach

- **The picker is a seam.** Widget tests use a `FakeGoogleAccountPicker` that returns
  tokens, returns null for cancel, throws, or waits on a gate. The real plugin is only
  checked by hand on the emulator and simulator.
- **The redirect reads providers** through the `ref` passed to `buildRouter`. It
  doesn't wait for the session check: it uses `currentUser`, which `restore` sets from
  storage at once.
- **Existing tests stay valid.** `pumpZemaApp` saves `accountChoiceShown` by default
  and uses no Google config, so the 820 tests still start on Home. The new tests opt in.
- **Signing out of Google** (so the picker asks again next time) belongs with Sign out
  in bolt 033. The picker already exposes `signOut()` for it.

### Acceptance Criteria

- [ ] On first launch with sign-in available, S04 shows before Home; Continue as guest is the main button, and the benefits are listed
- [ ] Continue as guest goes to Home, and S04 never shows again
- [ ] Sign in opens S24; leaving S24 without signing in goes to Home, and S04 doesn't return
- [ ] Killing the app on S04 shows it again on the next start
- [ ] With no Google IDs or no backend, S04 is skipped and no sign-in button shows
- [ ] S24 shows the benefits, Continue with Google and Continue as guest
- [ ] Picking an account signs in to Supabase with the ID token and goes back where the user came from
- [ ] Cancelling the picker keeps S24 with no message
- [ ] With no network or a failed sign-in, a short message shows and the user stays a guest
- [ ] S04 and S24 fit at 1.3× text, in light and dark themes
- [ ] On the emulator: a real Google sign-in against the local backend creates the profile with the Google name. Also checked on the iOS simulator if the picker runs there.
- [ ] Analyze and format clean; all tests pass; key scan clean; no `*.local.*` file staged
