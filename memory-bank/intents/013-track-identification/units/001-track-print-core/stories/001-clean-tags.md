---
id: 001-clean-tags
unit: 001-track-print-core
intent: 013-track-identification
status: complete
priority: must
created: '2026-11-19T16:00:00Z'
assigned_bolt: 058-track-print-core
implemented: true
---

# Story: 001-clean-tags

Clean tags before title matching

**As a** listener
**I want** a file with junk in its tags or name to find its song
**So that** it gets lyrics without my fixing the tags

## Acceptance Criteria

- [x] **Given** a title or artist with `@channel`, `[...]`, `(128)`, a YouTube ID, "Track N" or "CD N", **When** matched, **Then** those parts are ignored
- [x] **Given** an artist or album that is a channel name (`@…`), **When** matched, **Then** it counts as unknown, not as a different artist
- [x] **Given** a title containing a known catalog artist ("ድንቅ አድርጎልኛል ቀሲስ ምንዳዬ ብርሀኑ"), **When** matched, **Then** the artist is taken out and used
- [x] **Given** empty tags and a name like `01_የማይረሳው_ጌታ_ታምራት_ደስታ` or `04 - Album - Title`, **When** matched, **Then** title and artist come from the name
- [ ] (deferred to 060) **Given** two songs equally close, **When** one recording is within 3 s of the file, **Then** that one wins; otherwise no link (as today)
- [x] **Given** the owner's 11 files and the existing matcher tests, **When** run, **Then** none links worse than before
