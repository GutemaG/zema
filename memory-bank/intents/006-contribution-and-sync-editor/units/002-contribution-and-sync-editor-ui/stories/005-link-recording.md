---
id: 005-link-recording
unit: 002-contribution-and-sync-editor-ui
intent: 006-contribution-and-sync-editor
status: planned
priority: must
created: '2026-11-02T07:00:52Z'
assigned_bolt: 045-contribution-and-sync-editor-ui
implemented: false
---

# Story: 005-link-recording

## User Story

**As a** contributor
**I want** to say which recording my lyrics and timings belong to
**So that** the timings match a real performance

## Acceptance Criteria

- [ ] **Given** S20, **When** Local file, **Then** a searchable track list opens; the chosen track's duration and file name are kept; the track that opened the flow is preselected
- [ ] **Given** S20, **When** a YouTube link is pasted, **Then** the video ID is parsed, oEmbed gives the title and thumbnail, duration can be typed; offline or failure keeps the ID and lets the title be typed
- [ ] **Given** a YouTube recording, **When** Next, **Then** S21 is skipped with an explanation that YouTube can't be synced
- [ ] **Given** a new song, **When** Skip, **Then** the lyrics continue to S22 with no recording
- [ ] **Given** the artist / choir field, **When** shown, **Then** it is prefilled from the track's artist

## Technical Notes

- oEmbed via the `http` package; no key. Thumbnail cached like avatars.

## Dependencies

### Requires
- 004-add-lyrics-editor

### Enables
- 006-telegram-share
- 007-sync-editor-list

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| Playlist or channel link | Not a video: error on the field |

## Out of Scope

- Telegram (006)
