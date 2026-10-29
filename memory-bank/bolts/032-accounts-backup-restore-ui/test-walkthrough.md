---
stage: test
bolt: 032-accounts-backup-restore-ui
created: 2026-10-29T20:51:00Z
---

## Test Report: accounts-backup-restore-ui (bolt 2 of 8)

### Summary

- **Tests**: app 861, all passing (41 new). `flutter analyze` is clean, and
  `dart format` changes nothing.
- **Builds**: the Android debug APK and the iOS simulator app both build with
  `google_sign_in`. The built iOS `Info.plist` has the reversed client ID as its URL
  scheme.
- **Real Google sign-in on the Android emulator**, against the local backend: it
  works.
  - The owner signed in twice with their own Google account.
  - The server created one user, through the `google` provider.
  - The profile has the Google name and avatar, and the role `contributor`.
  - The second sign-in added a session, not a second user.
- **Planted bugs**: 16, all caught. One got through the first run; a new controller
  test now catches it.

### Test Files

- [x] `test/features/account/google_account_picker_test.dart` (10): the plugin
  wrapper over a fake `GoogleSignInPlatform`.
  - **Config**: the web ID is required everywhere, and the iOS ID only on iOS. This
    test run has no IDs, like a build without config.
  - **Client IDs**:
    - The web ID always goes as `serverClientId`.
    - The iOS ID goes as `clientId` on iOS only; Android gets null.
  - **Initialize** runs once for many picks, and a failed one is tried again.
  - **Errors**:
    - `canceled` gives null.
    - `interrupted`, `clientConfigurationError`, `uiUnavailable` and `unknownError`
      give `AuthFailure`, and so does a missing ID token.
    - Sign-out errors are swallowed.
- [x] `test/features/account/sign_in_controller_test.dart` (4):
  - a second `signIn` while one is running is ignored
  - a cancel ends idle with no error
  - a failure is held as its `ZemaFailure`
  - with no picker, nothing happens
- [x] `test/features/account/account_providers_test.dart` (+3):
  - with no Google IDs: no picker and no sign-in, even with a backend
  - with IDs: the plugin picker, and sign-in offered
  - IDs but no backend: no sign-in
- [x] `test/features/account/sign_in_flow_test.dart` (24), the full app:
  - **S04**:
    - It shows before Home on the first start, with all three benefits and guest as
      the filled button. Nothing is saved until a choice.
    - Guest goes Home and saves the choice; going Home again doesn't bring S04 back.
    - A later start goes straight Home.
    - Killed on S04, it shows again.
    - Sign in opens S24. Leaving S24 by Continue as guest, the close button or
      system back goes Home, without signing in.
    - S04 is skipped without Google IDs or without a backend.
    - Only Home is redirected.
  - **S24**:
    - It shows the benefits, Continue with Google and Continue as guest.
    - Picking an account signs in with its ID token, shows "Signed in as …" (the
      email when there's no name) and goes Home from S04.
    - Pushed over Library, it shows a back button, and signing in pops back to
      Library.
    - A cancel stays on S24, with no message and the button ready again.
    - Offline, it shows "No connection", and the user stays a guest.
    - A refused sign-in, a Google failure and an unexpected plugin error each show
      "Couldn't sign in".
    - While busy: progress shows, both buttons are off, and a second tap is ignored.
    - Trying again after a failure signs in.
  - **Fit**:
    - S04 and S24 fit at 1.3× text on a 360×640 screen, in dark and light.
    - At 320×480 they scroll instead of overflowing.

### Acceptance Criteria Validation

- ✅ **S04 shows before Home on the first launch, guest first, with the benefits**:
  flow tests, and on the emulator.
- ✅ **Continue as guest goes Home, and S04 never shows again**: flow tests.
- ✅ **Sign in opens S24; cancelling there goes Home, and S04 doesn't return**: flow
  tests (guest, close, system back).
- ✅ **Killed on S04, it shows again**: flow test.
- ✅ **Without sign-in, S04 is skipped and sign-in hidden**:
  - Flow tests, and the provider tests.
  - There are no other sign-in buttons yet; bolt 035's will read
    `signInAvailableProvider`.
- ✅ **S24 shows the benefits, Google and guest**: flow test, and on the emulator.
- ✅ **Picking an account signs in, the profile has the Google name and avatar, and
  the user goes back**:
  - Flow tests.
  - On the emulator, checked on the server.
  - Going to S26 when a backup exists is bolt 037's.
- ✅ **A cancelled picker stays with no message**: flow test.
- ✅ **No network or a failure: a short message, still a guest**: flow tests.
- ✅ **Fits at 1.3×, light and dark**:
  - Widget tests.
  - On the emulator, light, at 1.0× and 1.3× text: S04 fits with no scrolling.

### On the Emulator (Medium Phone, API 37, Google Play)

- **First start**: S04, then Sign in, then S24 with a close button.
- **Continue with Google**:
  - The emulator had no Google account, so Google opened "Add account", and the
    owner signed in there.
  - Back in Zema it signed in and landed on Home.
  - On the server:
    - one `google` user named "Birhanu Gudisa"
    - an avatar, and the `contributor` role
    - a refresh token
- **No sign of it in the app** on that first run, as the owner noticed. The profile
  and the Home avatar come in bolt 033. Added a "Signed in as {name}" SnackBar
  (`signInDone`) and its tests.
- **After clearing the app's data**:
  - S04, then S24, then Google's "Choose an account" listing the owner's account.
    S24's busy state shows behind it.
  - Picking it lands on Home with "Signed in as Birhanu Gudisa".
  - The server then has two sessions for the same single user.

### Planted Bugs (16; each run against `test/features/account/` and `test/app/`)

- **Caught (15) in the first run**:
  - cancel treated as an error
  - the iOS client ID on every platform
  - no `serverClientId`
  - a failed initialize not retried
  - the iOS ID not required on iOS
  - sign-in offered without a picker
  - the choice flag ignored
  - the choice not saved
  - a failure not surfaced
  - the wrong offline message
  - S24 always going Home
  - guest on S04 not leaving
  - the redirect applied to every route
  - the buttons not disabled while busy
  - no signed-in message
- **Missed, then fixed (1)**: the controller's busy guard removed. The widget test's
  second tap couldn't reach it, because the button was already disabled. Added
  `sign_in_controller_test.dart`, which calls `signIn` twice directly and now
  catches it.

### Not Checked

- **A real sign-in on the iOS simulator.** The app builds with the right URL scheme,
  but signing in there means typing a Google password in the simulator's browser
  sheet. That's left for the owner, or for a real iPhone later.
- **The dark theme on the emulator.** Dark is covered by the widget fit test only.

### Issues Found

- **No feedback after signing in** (found on the emulator): fixed with the SnackBar.
- **Planted-bug gap**: fixed with the controller test.
- **Test-font note**: the test font draws every character as a full-width square, so
  S04 is taller in tests than on a phone. On the emulator at 1.3×, S04 fits with no
  scrolling.
