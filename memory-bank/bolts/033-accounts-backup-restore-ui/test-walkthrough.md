---
stage: test
bolt: 033-accounts-backup-restore-ui
created: 2026-10-30T09:32:30Z
---

## Test Report: accounts-backup-restore-ui (bolt 3 of 8)

### Summary

- **Tests**: app 909 and zema_data 52, all passing (52 new in all). `flutter analyze`
  and `dart analyze` are clean, and `dart format` changes nothing.
- **On the Android emulator, against the local backend**, with the owner's Google
  account:
  - Home's avatar, Profile, rename, sign out, sign in again, delete account, and
    delete while offline all worked.
  - After deleting, every row of the user on the server is gone.
- **Found on the emulator and fixed**:
  - The "Signed out" and "Account deleted" messages never showed.
  - The avatar was blurry.
- **Planted bugs**: 19, all caught. Two got through the first run; new tests now
  catch them.

### Test Files

- [x] `packages/zema_data/test/supabase_auth_repository_test.dart` (+4,
  `deleteAccount`):
  - It POSTs `rpc/delete_account` with the user's token, then signs out here.
  - Offline: `NetworkFailure`, still signed in, session kept.
  - Server error: thrown, still signed in.
  - Not signed in: `AuthFailure`, no request.
- [x] `packages/zema_data/test/account_backend_test.dart` (+1, the local backend):
  `deleteAccount` removes the user and signs out. The old session's refresh fails
  afterwards, so it can't come back.
- [x] `test/features/account/google_account_picker_test.dart` (+1): `disconnect`
  reaches the plugin, and its errors are swallowed.
- [x] `test/features/account/avatar_cache_test.dart` (7, `FileAvatarCache` over a
  temp folder and a mock client):
  - The image downloads once, then is read from the file.
  - A new URL downloads again.
  - Offline, or on an HTTP error, the older image is kept; null when there's none.
  - An HTTP error or an empty answer saves nothing.
  - Google photos are asked for at 256 pixels; other URLs are unchanged.
  - `clear()` deletes the folder.
- [x] `test/features/account/profile_controller_test.dart` (13):
  - **Profile**:
    - A guest has none.
    - With none saved, the server's is shown and saved.
    - A saved one shows first, then the server's.
    - Offline, the saved one stays.
    - Offline with none saved, the Google name and photo.
    - It follows a sign-out, and an unreadable saved profile is ignored.
  - **Rename**: saved on the server and here. Offline, it throws and the old name
    stays.
  - **Sign out**: here and of Google (not disconnect). The saved profile and the
    avatar are forgotten.
  - **Delete**:
    - The server first, then sign-out, disconnect and forgetting.
    - Offline or a server error: thrown, still signed in, nothing forgotten.
    - The running action is held, and a second call while one runs is ignored.
- [x] `test/features/account/profile_flow_test.dart` (29, the full app):
  - **Home header**:
    - Signed in, the avatar image opens Profile.
    - A guest gets the guest icon.
    - Without sign-in, it's the Settings button.
    - Without a photo, a letter tile.
  - **S25 signed in**:
    - Avatar, name, role, Settings, Sign out and Delete account.
    - The badge shows the highest role.
    - Settings opens from Profile, and back returns.
    - Offline, the saved name and photo show.
  - **Edit name**:
    - It saves, trimmed.
    - Save is off when the name is empty or unchanged; the field stops at 40.
    - Cancel keeps the name.
    - Offline and refused each show their message.
  - **Sign out**:
    - Confirm, then the guest version and "Signed out".
    - The message shows even when Google signs out slowly.
    - Cancel keeps the user signed in.
  - **S25 as a guest**:
    - The guest icon, the sign-in card, and Settings.
    - Signing in from the card comes back to Profile, signed in.
  - **Delete**:
    - The first dialog says what's deleted and what stays, and Cancel there ends it.
    - The second has a red Delete; Cancel there keeps everything.
    - Confirmed: deleted, signed out, and Google disconnected.
    - The message shows even when Google disconnects slowly.
    - The screen is covered while deleting.
    - Offline and a server error each show their message, still signed in.
  - **Fit**: S25 signed in (with a long name, ellipsized) and as a guest fit at
    1.3× text, in dark and light.

### Acceptance Criteria Validation

- ✅ **Home shows the avatar or guest icon, opening S25; Settings opens from S25**:
  flow tests, and on the emulator with the real Google photo. Builds without
  sign-in keep the gear (flow test).
- ✅ **S25 signed in: avatar, name, role badge, Settings, Sign out, Delete**: flow
  tests, and on the emulator.
- ✅ **Name edit to 1–40 characters saves on the server; offline, a message and the
  old name**:
  - Flow and controller tests.
  - On the emulator: "Birhanu G." reached the server and survived signing out and
    back in.
- ✅ **Sign out after confirming: the guest version, local data kept, Google signed
  out**:
  - On the emulator, the server lost that session.
  - The photo folder on the phone was deleted.
  - Google asked which account to use next time.
- ✅ **S25 as a guest: guest icon, sign-in card opening S24, Settings**: flow tests,
  and on the emulator. Signing in from the card came back to Profile.
- ✅ **Offline, the cached avatar and name show**: controller and flow tests, and on
  the emulator with the network off.
- ✅ **A long name ends with an ellipsis at 1.3×**: fit test.
- ✅ **Delete: the first dialog names what's deleted and that local data stays; the
  second has a red Delete**: flow tests, and on the emulator.
- ✅ **Confirmed online, `delete_account` runs, the phone signs out and Google is
  disconnected**:
  - On the emulator, the server has 0 rows for the user afterwards: users,
    identities, sessions, refresh tokens, profiles, user roles, and a backup row
    added for the check.
  - Signing in again, Google asked for consent ("Allow Google to sign you in to
    Zema"). So Zema's access had been revoked.
- ✅ **Offline or a server error: a message, still signed in**:
  - On the emulator with Wi-Fi and data off: "No connection. Your account wasn't
    deleted.", still signed in, and the server unchanged.
  - The server error case is covered by tests.
- ✅ **On the emulator, the user's rows are gone on the local backend**: above.

### On the Emulator (Medium Phone, API 37, Google Play)

- **Home**: the owner's Google photo as the avatar, then Profile.
- **Edit name**: the dialog, then "Birhanu G.", which was on the server at once. On
  screen it took about 2 seconds in this debug build.
- **Sign out**: the confirmation, then the guest version. One of the two server
  sessions ended, and `files/avatar` was deleted.
- **Sign in from the guest card**:
  - S24 with a back arrow, then Google's "Choose an account" (it asked again).
  - Back on Profile, signed in, with the renamed profile kept.
- **Delete account**:
  - Both dialogs, then "Deleting your account…". The guest version showed behind it
    as soon as the server had deleted.
  - The cover stayed about 8 seconds while Google disconnected.
  - The server had 0 rows for the user.
- **Signing in again** brought Google's consent screen. The owner accepted it, which
  created a fresh user.
- **Delete, offline**: "No connection. Your account wasn't deleted." The saved name
  and photo still showed, and the user was still on the server.
- **Sign out, online**: "Signed out" showed (after the fix below). Then the owner's
  account was signed in again, so it ends signed in.

### Planted Bugs (19; each against `test/features/account/` and `test/app/`, or zema_data's tests)

- **Caught (17) in the first run**:
  - a delete failure swallowed
  - sign-out instead of disconnect
  - no Google sign-out
  - no busy guard
  - the saved profile or the avatar not forgotten
  - no refresh after the saved profile
  - never asking the server
  - a rename not saved here
  - the wrong rename message
  - the badge always Contributor
  - Delete not red
  - the name not ellipsized
  - an unchanged name savable
  - no gear without sign-in
  - a URL change ignored
  - no local sign-out after `delete_account`
- **Missed, then fixed (2)**:
  - **Cancel on the first delete dialog ignored.** The test checked only that nothing
    was deleted, while the second dialog sat open. It now expects no dialog.
  - **An HTTP error dropping the older photo.** No test had an older photo with a
    failing download. Added one.

### Issues Found

- **No "Signed out" or "Account deleted" message on the phone** (found on the
  emulator):
  - Both actions sign out before they return, which removes the Account rows, so
    their context was gone when the message was due.
  - Fixed by looking up the messenger before the action.
  - The fakes now let Google's sign-out and disconnect be slow, and two tests fail
    on the old code.
- **A blurry avatar** (found on the emulator): Google's photo URL asks for 96
  pixels. The cache now asks for 256.
- **Two planted-bug gaps**: fixed with tests.

### Not Checked / Follow-ups

- **The iOS simulator**, as in bolt 032.
- **Saving a name shows no progress.** It took about 2 seconds on the emulator.
  Consider a spinner in the dialog.
- **The focused field label is pale gold on white.** This comes from the app-wide
  input theme, not this bolt; it's hard to read.
- **Google Play services on this emulator is slow**: the picker took up to a few
  minutes, and disconnect about 8 seconds. Nothing to change in Zema.
