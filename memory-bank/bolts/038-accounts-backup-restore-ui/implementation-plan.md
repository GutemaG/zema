---
stage: plan
bolt: 038-accounts-backup-restore-ui
created: 2026-10-30T12:17:00Z
---

## Implementation Plan: accounts-backup-restore-ui (S26, songs not found kept)

### Objective

- **After sign-in**, if the account has a cloud backup this phone hasn't seen, S26
  offers it with Restore and Start fresh. S26 also opens from Backup & sync.
- **Songs not found** on this phone are kept, included in the next backup, and
  added once a library scan finds them.

### Deliverables

- **Drift v7: `unmatched_entries`**:
  - kind, the song's identity, a favorite's date, a playlist's name and position,
    and a lyrics choice's song
  - a migration step, schema files and a migration test
- **`UnmatchedDao`**: `all`, `addAll` (skipping duplicates), `replaceAll` and
  `clear`.
- **`BackupRestorer.restore`** keeps the entries not found, inside the merge's
  transaction.
- **`retryUnmatched()`** turns the kept entries into a partial document and merges
  it.
  - Found songs are added; the rest stay kept, with their original positions.
  - Entries of playlists deleted on this phone are dropped.
  - `unmatchedRetryProvider` runs it after every library scan.
- **`BackupBuilder`** puts the kept entries back:
  - favorites, lyrics choices and hidden songs are added
  - playlist entries go back to their old position, if the playlist still exists
- **Sign-out and delete account** clear the kept entries.
- **S26 (`/restore`)** shows:
  - "We found your backup from (date): N favorites, N playlists, settings."
  - Restore and Start fresh
  - **Restore**:
    - waits for the first library scan if there hasn't been one
    - merges with progress shown
    - ends on a summary that lists the songs not found
    - then marks the cloud backup as this phone's (`syncedAt`)
  - **Start fresh** changes nothing.
  - **Other states**: no backup, offline (Try again), and a newer format (update
    the app).
- **S24**: after a sign-in, `restoreToOffer` compares the cloud's `savedAt` with
  `syncedAt`. If they differ, S26 opens in S24's place.
- **S25b**: a "Restore from backup" row.

### Acceptance Criteria

- [ ] After sign-in with a cloud backup, S26 shows its date, its counts and
  settings.
- [ ] Restore merges with progress, then a summary and the songs not found.
- [ ] Start fresh changes nothing, and the cloud backup stays.
- [ ] S25b → Restore opens S26.
- [ ] Songs not found are saved (Drift v7) and included in the next backup.
- [ ] A rescan that finds them adds them and removes them from the kept list.
- [ ] Sign-out or delete clears them.
- [ ] Migration v6 → v7 keeps the data.
- [ ] **Intent check**: phone A's backup, restored on a wiped phone, gives the
  same data.
