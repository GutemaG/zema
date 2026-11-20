---
id: 007-clip-look
unit: 002-clip-maker
intent: 011-share-lyrics-clips
status: complete
priority: must
created: '2026-11-20T18:00:00Z'
assigned_bolt: 068-clip-look
implemented: true
---

# Story: 007-clip-look

Choose the look

**As a** listener
**I want** to choose the background, text, transparency, names and pictures of my clip
**So that** it looks the way I want, without having to set anything if I don't

## Acceptance Criteria

- [ ] **Given** the editor, **When** I change nothing, **Then** the clip uses the defaults: blurred cover art, 40 % dim, medium white centred text, title and artist on, album off, no artist picture, Zema mark on
- [ ] **Given** Background, **When** I pick a gallery photo or a plain colour, **Then** the preview and the video use it
- [ ] **Given** Transparency, **When** I move the slider (0–80 %), **Then** the background dims behind the text
- [ ] **Given** Text, **When** I change size, colour or position, or turn transliteration on, **Then** the preview and the video follow; text stays readable (at least 4.5:1 against the dim)
- [ ] **Given** Song details, **When** I turn artist or album name on or off or edit one, **Then** it shows at the top of the clip; edits apply to this clip only
- [ ] **Given** Pictures, **When** I pick an album or artist photo from the gallery, **Then** it shows small and round next to the names; the album picture defaults to the cover art
- [ ] **Given** a finished clip, **When** I make the next one, **Then** my last background type, transparency, text and on/off choices are the new defaults (photos and edited names are not kept)
