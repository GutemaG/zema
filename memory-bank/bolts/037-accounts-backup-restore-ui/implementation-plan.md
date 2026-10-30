---
stage: plan
bolt: 037-accounts-backup-restore-ui
created: 2026-10-30T12:09:00Z
---

## Implementation Plan: accounts-backup-restore-ui (re-link and merge)

### Objective

Find each backed-up song on this phone, then merge the backup into the library in
one transaction. Nothing on the phone is removed. Settings are applied afterwards.

### Deliverables

- **`BackupTrackMatcher` in `zema_core`**: built once from this phone's tracks, then
  a lookup per entry. In order:
  1. the same file name (any letter case) and a length within ±2 s
  2. the same title and artist after `normalizeSearchText` (case, spacing,
     punctuation, noise words and Ethiopic spelling variants ignored), and a length
     within ±2 s
  - **Never on the title alone**: no artist means the file name only.
  - **Missing tracks** are left out.
  - **Ties**: the closest length wins, then the lowest ID.
- **`UnmatchedEntry` in `zema_core`**: a favorite, playlist entry (name and
  position), lyrics choice or hidden song whose track isn't on this phone. Bolt 038
  saves these.
- **`storageRelativePath`** moves to `zema_core`, so the database layer can map
  hidden folders back.
- **`RestoreDao.merge(document, keepUnmatched:)`**, in one transaction:
  - **Favorites**: added with their dates; existing ones are kept.
  - **Playlists**:
    - Matched by name key; missing songs go at the end, in backup order, without
      duplicates.
    - Other playlists are created with their description and creation date.
  - **Lyrics choices**: added only where the track has no manual link. They
    replace automatic links.
  - **Hidden folders**:
    - Each relative path maps to every folder, or parent folder, on this phone with
      that relative path.
    - With none, to `/storage/emulated/0/<path>`, so it is hidden when it appears.
  - **Hidden tracks**: by match.
  - **`keepUnmatched`** runs inside the transaction with the entries not found.
  - **Result**: a `RestoreReport` with counts and the entries not found.
- **`BackupRestorer`**: merges first, then applies the backup's settings
  (`SettingsController.replaceAll`, through `settingsFromBackup` from bolt 034).
  Nothing is applied if the merge fails.

### Acceptance Criteria

- [ ] The matcher: file name + duration ±2 s, then normalized title + artist +
  duration ±2 s, never title alone.
- [ ] **The merge**:
  - favorites added
  - same-name playlists extended at the end, others created
  - manual choices only where none exist
  - settings applied
- [ ] An error midway changes nothing (one transaction).
- [ ] 2,000 entries against 5,000 tracks in under 2 s.
- [ ] A realistic new-phone fixture: ≥ 95% matched.
