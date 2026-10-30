---
stage: plan
bolt: 034-accounts-backup-restore-ui
created: 2026-10-30T10:05:00Z
---

## Implementation Plan: accounts-backup-restore-ui (C09, entry points, backup document)

### Objective

- Guests who open Settings → Account & backup get a short sign-in prompt (C09).
- Signed-in users get the Backup & sync screen (S25b).
- No other screen asks anyone to sign in.
- The backup document is defined in `zema_core`, and the app can build one from its
  database and preferences.

### Deliverables

- **`zema_core`, `src/backup/`** (pure Dart):
  - **`TrackIdentity`**: title, artist, album, duration in ms, and file name.
    - Built from a `Track`.
    - The file name is the last part of the path; nothing else from the path is
      kept.
  - **`BackupDocument`** (format 1) holds:
    - favorites (track and date added)
    - playlists (name, description, date created, tracks in order)
    - hand-made lyrics choices (track and song ID, null for "no lyrics")
    - hidden folders and hidden tracks
    - settings, as a map of plain values
  - **Encoding**:
    - `toJson` and `fromJson`, plus `encode` and `decode` for the JSON text.
    - Tracks are written once in a `tracks` list, and every section refers to them
      by index. A song that is both a favorite and in three playlists is stored
      once.
    - Track keys are short (`title`, `artist`, `album`, `ms`, `file`), and nulls
      are left out.
  - **Reading other versions**:
    - Top-level sections the app doesn't know are kept, and written back unchanged
      (`extras`).
    - Fields the app doesn't know inside an entry are ignored.
    - A newer `format` throws `BackupFormatFailure` (`newerFormat` true), and the
      app shows "update the app".
    - Malformed JSON throws `BackupFormatFailure` as well.
  - **`BackupFormatFailure`**, a new `ZemaFailure`.
- **The app's builder**:
  - **`BackupDao`** (`lib/app/database/backup_dao.dart`): reads favorites,
    playlists with ordered entries, manual lyrics links, and hidden folders and
    tracks, each joined to its track.
  - **`BackupBuilder`** (`features/account/data/backup_builder.dart`): turns those
    rows and `AppSettings` into a `BackupDocument`, through `backupSettings`, which
    bolt 037 reverses.
  - **Hidden folders are stored relative to their storage volume.** For example,
    `/storage/emulated/0/Recordings` is saved as `Recordings`. The backup then
    holds no phone-specific path, and the folder maps onto the new phone.
  - Not included: play history, queue, audio, cached lyrics, automatic links, and
    any other path.
- **C09** (`features/account/presentation/widgets/sign_in_prompt.dart`):
  - `showSignInPrompt(context, reason:)` opens a bottom sheet with a title, the
    reason, Sign in and Not now.
    - Sign in pushes S24 and returns to the screen underneath.
    - It resolves to whether the user ended signed in.
  - Intent 006 will reuse it for Contribute.
- **Entry points**:
  - Settings gains an Account group with "Account & backup", shown only when
    sign-in is available.
    - A guest gets C09.
    - A signed-in user gets S25b.
  - **S25b** at `/backup` (`backup_screen.dart`) lists what is backed up and what
    is not. Bolt 035 adds the backup time, the buttons and the toggle to it.
- **Strings**: English ARB strings for C09, the Settings row and S25b.

### Dependencies

- None new. `zema_core` stays dependency-free.

### Technical Approach

- The document's model holds `TrackIdentity` objects; the track index exists only
  in the JSON. Restore (bolt 037) matches identities, never phone IDs.
- **Size**: tracks are written once, with short keys. In the worst case, 1,000
  favorites plus 50 × 100 playlist songs are all different tracks. With typical tag
  lengths that stays under 1 MB, and a test checks it.
- **The "Never sign-in" rule** (FR-9): a guest flow test visits Home, Search,
  Library, Now Playing and the lyrics view, plays a song, and favorites it. It
  checks that neither C09 nor S24 appeared.

### Acceptance Criteria

- [ ] **C09 from Settings → Account & backup as a guest**: it gives the reason,
  with Sign in and Not now.
- [ ] **Not now** closes C09 with no change.
- [ ] **Sign in** opens S24, then returns to Settings.
- [ ] **No sign-in prompt** on the player, library, search or lyrics actions.
- [ ] **A signed-in user** goes to S25b. Without sign-in, the row is hidden.
- [ ] **`BackupDocument` format 1** holds every section listed above, with
  `TrackIdentity`.
- [ ] **Round trip**: decode(encode) is exact, unknown sections are kept, and
  unknown fields are ignored.
- [ ] **A newer format** gives a clear error.
- [ ] **Size**: 1,000 favorites + 50 × 100 songs is under 1 MB.
- [ ] **The builder** reads Drift and preferences. Its output has no paths except
  file names, no audio and no history.
