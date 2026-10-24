# UX Guide

## Overview

UI/UX standards and design system choices. **The source of truth is
`docs/design-system.md`** (tokens, typography, components) and the screen images in
`design/screens/`. This file summarizes the rules agents must follow. When the two
disagree, `docs/design-system.md` wins.

## Design System / Component Library

- Material 3 widgets themed from design tokens. There is no third-party component library.
- Palettes: **Night Vigil** (default) and **Night Vigil · Wine**, both dark. The app is
  **dark only**. The Settings "Theme" row is a palette switch (decided 2026-10-23).
- Shared components (IDs from `docs/screens.md` §9): C01 mini player, C02 queue sheet,
  C03 song menu, C04 add-to-playlist, C05 sleep timer, C06 lyrics view, C07 empty/error/
  offline states, C08 media notification, C09 guest sign-in prompt. Build each once in
  `shared/` and reuse it.
- Screens are referred to by their IDs (S01–S28) in requirements and stories.

## Styling Approach

- One `ThemeData` built from a `ZemaColors` `ThemeExtension`;
  `ColorScheme.dark(surface: bg, primary: primary, onPrimary: onPrimary, …)`. Custom
  tokens (`faint`, `soft`, `tile`, `primaryText`, `accentText`) are read from the
  extension. Never hard-code hex values in widgets.
- Gold (`primary`/`accent`) marks one thing per area: the main action, the current line,
  or the active state.
- Lyrics status badges: **Synced** = `soft` bg + `accentText`; **Text only** = `line`
  border + `muted`.
- Missing album art: `tile` square with the title's first letter in `tileFg`.
- Typography: Inter for Latin UI, Noto Sans Ethiopic for Ge'ez (fallback after Inter).
  Line height ≥ 1.4 for Ethiopic text. Sizes per role are in `docs/design-system.md`.
- Shape: radius 12 / 14–16 / 22–28, pills fully rounded; side padding 16–20; list rows
  66 px; 1.8 px-stroke line icons, 20–24 px.

## Accessibility Standards

- Every tap target ≥ 44×44.
- Text on `bg`/`surface` uses `text` or `muted` (≥ 4.5:1). Use `faint` only for dimmed
  lyric lines ≥ 17 px.
- Lyrics size is user-adjustable. Respect the system text scale in UI chrome.
- Semantic labels on icon buttons and on the overlay controls.

## Responsive Design Strategy

- Phone-first portrait layouts (360–430 dp wide). The admin website (stage 8) gets its own
  wide layouts.
- Layouts must tolerate longer translations (am, om, ti) and taller Ethiopic glyphs:
  single-line titles ellipsize, and buttons don't have fixed widths.
