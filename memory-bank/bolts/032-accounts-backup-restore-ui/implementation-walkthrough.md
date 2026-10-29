---
stage: implement
bolt: 032-accounts-backup-restore-ui
created: 2026-10-29T20:31:00Z
---

## Implementation Walkthrough: accounts-backup-restore-ui (bolt 2 of 8)

### Summary

- **First start.** A build that can sign in shows the account choice (S04) once,
  instead of Home. Continue as guest is the main button.
- **Sign in (S24)** opens the Google account picker and signs in to the backend with
  the account's ID token.
- **Without Google client IDs or a backend**, the build skips S04 and offers no
  sign-in.
- **The picker is behind an interface**, so tests use a fake.
- **The iOS URL scheme** comes from a gitignored xcconfig, so no client ID is
  committed.

### Structure Overview

- **`features/account/data/`**:
  - `GoogleConfig`: the client IDs from `--dart-define`.
  - `GoogleAccountPicker`: the seam. `PluginGoogleAccountPicker` is the
    `google_sign_in` 7 version.
- **`features/account/application/`**:
  - `signInAvailableProvider`: a backend and a picker.
  - `accountChoicePendingProvider`: the S04 flag.
  - `signInProvider`: the S24 controller.
- **`features/account/presentation/`**: the two screens and their shared layout
  (`widgets/account_page.dart`).
- **Router**: the top-level redirect from Home to S04, and both routes above the
  shell.

### Completed Work

- [x] `lib/features/account/data/google_config.dart`: the web and iOS client IDs.
  `isConfiguredFor(platform)` needs the iOS ID only on iOS.
- [x] `lib/features/account/data/google_account_picker.dart`:
  - `GoogleTokens`, and `pick()`, which returns null when the user cancels.
  - The plugin version initializes once, and tries again on the next call if that
    fails. It passes the web ID as `serverClientId` so the token is for the backend,
    and the iOS ID as `clientId` on iOS only.
  - A `canceled` code becomes null. Any other code becomes `AuthFailure`, with the
    code logged.
- [x] `lib/features/account/application/account_providers.dart`:
  `googleConfigProvider`, `googleAccountPickerProvider` (null without IDs for this
  platform) and `signInAvailableProvider`.
- [x] `lib/features/account/application/sign_in.dart`:
  - `AccountChoiceController`: pending while sign-in is available and the
    `accountChoiceShown` preference isn't set. `chosen()` saves the preference.
  - `SignInController.signIn()`: pick, then `signInWithGoogle`. A cancel gives false
    with no error; a failure gives `AsyncError` with a `ZemaFailure`; a second tap
    while busy is ignored.
- [x] `lib/features/account/presentation/widgets/account_page.dart`:
  - `AccountBenefits`: contribute, back up and restore, each with an icon.
  - `AccountActions`: a full-width gold filled button and a text button; while busy,
    the filled button shows progress and both are disabled.
  - `AccountPage`: content at the top and actions at the bottom; they scroll together
    when the content doesn't fit.
- [x] `lib/features/account/presentation/account_choice_screen.dart`: S04 at
  `/welcome`. Either button saves the choice; guest goes Home, Sign in goes to S24.
- [x] `lib/features/account/presentation/sign_in_screen.dart`: S24 at `/sign-in`.
  - It shows the benefits, a note on the Google name and photo, Continue with Google
    and Continue as guest.
  - Signing in, guest and back all pop to the screen underneath. Opened from S04,
    there's nothing underneath, so they go Home: the close button, and
    `PopScope` for system back.
  - A SnackBar shows "No connection" for a `NetworkFailure`, and "Couldn't sign in"
    otherwise.
- [x] `lib/app/routes.dart` and `router.dart`:
  - `AppRoutes.accountChoice` and `signIn`.
  - `buildRouter(ref, …)` now takes the `Ref`, and its redirect sends Home to S04
    while the choice is pending.
- [x] **iOS**:
  - `Info.plist` gets a `CFBundleURLTypes` entry, `$(GOOGLE_REVERSED_CLIENT_ID)`.
  - Debug and Release `#include?` the gitignored `Google.local.xcconfig`.
  - `tool/google_env.sh` writes that file from `config/google.local.json`.
  - The `.gitignore` gets `apps/mobile/ios/Flutter/*.local.xcconfig`.
- [x] `google_sign_in: ^7.2.0`.
- [x] **Strings**: 13 new English strings (`accountChoice*`, `accountBenefit*`,
  `signIn*`).
- [x] **Test helpers**:
  - `FakeGoogleAccountPicker` (`tokens`, `failure`, `gate`, `picks`,
    `signOutCalls`).
  - `accountOverrides(picker:)` and `pumpZemaApp(googlePicker:)`. Without a picker,
    sign-in isn't offered, so existing tests start on Home as before.
- [x] **Docs**:
  - `docs/google-sign-in-setup.md`: `google_env.sh`, what a build without IDs does,
    and troubleshooting (a silent cancel on Android, "access blocked").
  - The `backend/README` run command.

### Key Decisions

- **The picker is a seam.** The Google plugin can't run in widget tests. Every path
  (cancel, failure, slow) is driven through the fake; only the real picker is checked
  by hand.
- **S04 is off by default in tests.** `pumpZemaApp` gives no picker, matching a build
  without client IDs. The 820 existing tests needed no change except the router call.
- **The flag is saved on a button press, not when S04 shows**, so killing the app on
  S04 shows it again (the story's edge case).
- **The redirect doesn't check for a signed-in user.** `restore()` reads secure
  storage asynchronously, after the first redirect. Anyone signed in has already made
  the choice, because S04 is the only way to S24 in this bolt, and later entry points
  only appear after S04.
- **S24 pops when it can.** Bolt 035's entry points will push it, and S04 replaces
  itself with it, so one rule covers both.
- **Change from the plan: English strings only.** am, om and ti translate only the
  core strings, and fall back to English for everything from intents 002–004. The new
  strings follow that rather than adding unreviewed translations. They're listed in
  `build/untranslated-messages.json` for the translators.
- **Access token:** `google_sign_in` 7 gives only an ID token without an extra
  authorization step, so `accessToken` stays null. Supabase doesn't need it.

### Deviations from Plan

- English strings only (above).
- `tool/google_env.sh` checks that the iOS ID ends in `.apps.googleusercontent.com`
  before reversing it.
- Added in the test stage: a "Signed in as {name}" SnackBar after a sign-in
  (`signInDone`). Nothing else shows the user until bolt 033, and the owner noticed
  on the emulator that there was no sign of it. `SignInController.signIn` now returns
  the `AuthUser`, or null.

### Dependencies Added

- [x] `google_sign_in` ^7.2.0 (with `google_sign_in_android` 7.2 and
  `google_sign_in_ios` 6.3)

### Developer Notes

- **The Google button uses a generic account icon, not Google's "G" logo.** Before
  release, swap in Google's official asset, which their branding rules require.
- **A silent cancel on Android** after picking an account is the usual sign of a SHA-1
  or package mismatch. The `account.google` log shows the code.
- **Signing out of Google** (`GoogleAccountPicker.signOut`) is ready for bolt 033's
  Sign out.
