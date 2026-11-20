---
id: 068-clip-look
unit: 002-clip-maker
intent: 011-share-lyrics-clips
type: simple-construction-bolt
status: complete
stories:
  - 007-clip-look
created: '2026-11-20T18:00:00Z'
started: '2026-11-21T00:10:00Z'
completed: '2026-11-21T01:00:00Z'
current_stage: null
stages_completed: [plan, implement, test]
requires_bolts: [067-clip-render-share]
enables_bolts: [069-clip-extras]
requires_units: []
blocks: false
---

# Bolt: 068-clip-look

## Overview

A Look panel in the clip editor with a live preview: background (cover, gallery photo,
colour), transparency, text size, colour and position, title, artist and album names,
album and artist pictures, the Zema mark. Defaults for everything; the last choices are
remembered.

## Built

- `ClipLook` (`clip_look_choices.dart`) has defaults for everything:
  - Background: song colours. The others are blurred cover, gallery photo and plain colour.
  - Transparency: 0 % on colours, 40 % behind pictures.
  - Text: medium, white, centre; transliteration off.
  - Names: title and artist on, album off.
  - Pictures: album picture is the cover art; no artist picture.
  - Zema mark: on.
- Changes from the story: the default background is the song colours the owner approved
  on the phone, not the blurred cover. The text colours are all light.
- The last choices are saved (`clipLook`) when a clip is made. Photos and edited names
  are not kept, and a photo background comes back as song colours.
- Readability: the background is dimmed further, if needed, until the text colour reaches
  4.5:1 against the lyrics band's average.
- A Look tab next to Clip in the editor:
  - background chips with colour swatches and a gallery photo;
  - a transparency slider (0–80 %);
  - text size, position and colour, and transliteration;
  - title, artist and album switches, each editable for this clip;
  - album and artist pictures (the artist picture is round);
  - the Zema mark.
- The preview repaints when the look changes.

## Emulator run

The run used "03. Baitewar Aregegn.mp3" with the catalogue's synced lyrics, a 0:45–1:34
range, a random gallery photo as the background and another as the artist picture. The
video took about 35 s to make. It came out at 1080×1920, 30 fps, with AAC audio, and the
lines scroll in time. The run found two problems, both fixed:
- The lyrics provider was freed while it was still loading, so the editor kept loading
  forever. The controller now keeps it alive.
- The Look list lost its scroll position after the photo picker. The tab lists now have
  storage keys.

## Stories Included

- [x] **007-clip-look**

## Stages

- [x] **1. plan** → implementation-plan.md
- [x] **2. implement** → code + implementation-walkthrough.md
- [x] **3. test** → tests + test-walkthrough.md

## Tests

`clip_look_test` checks the defaults, the kept choices, the dim raised for readable text, and the transliteration rows. 1,486 tests pass.
