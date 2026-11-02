---
id: 003-publish-on-approval
unit: 001-contribution-backend
intent: 006-contribution-and-sync-editor
status: complete
priority: must
created: '2026-11-02T07:00:52Z'
assigned_bolt: 041-contribution-backend
implemented: true
---

# Story: 003-publish-on-approval

## User Story

**As a** listener
**I want** approved contributions to appear in the catalog
**So that** every phone gets the new lyrics and timings

## Acceptance Criteria

- [x] **Given** an approved `new_song`, **When** approval runs, **Then** an approved song with sections, lines, play order, and its recording and timings is created in the same transaction, with a slug ID made from the title (unique)
- [x] **Given** an approved `edit_lyrics`, **When** approval runs, **Then** the song's text, sections, lines and play order are replaced and its version bumps; recordings whose timing count no longer matches the line occurrences lose their timings; others keep them
- [x] **Given** an approved `recording` or `sync_timing`, **When** approval runs, **Then** the recording is added (or its timings set) on the song
- [x] **Given** YouTube, local and Telegram recordings, **When** published, **Then** `recordings` stores the source reference (`youtube_id` or `file_name`) and the duration, and `get_song` returns them
- [x] **Given** a failure while publishing, **When** approval runs, **Then** nothing is published and the contribution stays pending
- [x] **Given** an edit based on an older song version, **When** the moderator approves, **Then** it publishes over the current version (the queue already flagged it)
- [x] **Given** pgTAP, **When** run, **Then** each kind publishes; nothing is readable by `anon` before approval; version bumps; the timing rule on edits

## Technical Notes

- Reuse `seed_song`'s document handling where possible. The edit's timing rule counts line occurrences in the play order. `get_song` gains the source reference keys (optional in Dart).

## Dependencies

### Requires
- 002-review-and-moderator-role

### Enables
- 009-review-and-submit (ui)
- 013-moderator-queue (ui)

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Two new songs with the same title | Second gets a suffixed slug |
| Sync for a recording that has timings | Replaced |

## Out of Scope

- Deleting songs or recordings
