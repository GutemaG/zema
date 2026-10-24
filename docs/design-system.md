# Zema — Design System

Source of truth for the app's visual design. Mockups are on the design canvas:
https://claude.ai/artifact/UnAbrkZsD39yP6VLdVCqjh (private — share it from its Share menu
before sending the link to others).

Decided on 2026-10-23:

- **Palette:** **Night Vigil** (default). **Night Vigil · Wine** is the approved alternative.
- **Font:** **Sans** for UI, titles and lyrics (no serif).
- All design is done on the canvas above (Google Stitch is not used).

## Files in the repo

```
design/
  screens/night-vigil/        one PNG per screen + 00-overview.png (default palette)
  screens/night-vigil-wine/   same screens in the Wine palette
  canvas/                     canvas source (canvas.json, Main.dc.html) as a backup
```

The PNGs are exports of the canvas. After the design changes, re-export them so the repo
matches the canvas.

---

## Colors

Each palette has a dark and a light version. In Settings → Appearance the user picks the
palette (Night Vigil or Night Vigil · Wine, shown as "Wine") and the theme mode (System,
Light or Dark; System is the default and follows the phone) in one sheet. Names below are the token names used on the canvas and
should be used as-is in Flutter (`ZemaColors`).

### Dark (approved)

| Token | Use | Night Vigil | Night Vigil · Wine |
|---|---|---|---|
| `bg` | Screen background | `#110D0B` | `#15090D` |
| `surface` | Cards, inputs, sheets, mini player | `#1C1613` | `#22121A` |
| `line` | Borders, dividers, inactive progress | `#2F2622` | `#3A2029` |
| `text` | Primary text | `#F2E8D7` | `#F4E7DD` |
| `muted` | Secondary text, inactive icons | `#A39586` | `#B3989A` |
| `faint` | Lyrics already sung (dimmed) | `#7D7065` | `#876C6F` |
| `primary` | Main buttons, active states, progress | `#E3AE4A` | `#D9A441` |
| `onPrimary` | Text/icons on `primary` | `#110D0B` | `#15090D` |
| `primaryText` | Current lyric line, active nav item | `#FFF4E0` | `#FFF1E2` |
| `accent` | Chorus markers, highlights, borders of the active line | `#E3AE4A` | `#D9A441` |
| `accentText` | Accent-colored text (badges, links, timestamps) | `#E3AE4A` | `#E2B45B` |
| `soft` | Badge / tip backgrounds ("Synced", chorus chips) | `#3A2B17` | `#3B2418` |
| `tile` | Album-art placeholder tile | `#2A1E19` | `#2C141C` |
| `tileFg` | Letter on the placeholder tile | `#E3AE4A` | `#D9A441` |
| `shadow` | Shadows | `rgba(0,0,0,0.5)` | `rgba(0,0,0,0.5)` |

### Light (draft, 2026-10-24)

Drafted during construction when the light theme was added. All contrast rules are met;
replace with designer-reviewed values after a design pass on the canvas.

| Token | Night Vigil · Light | Night Vigil · Wine · Light |
|---|---|---|
| `bg` | `#FAF6EE` | `#FAF3F2` |
| `surface` | `#FFFDF8` | `#FFFCFB` |
| `line` | `#E6DCCB` | `#EAD9D8` |
| `text` | `#1F1712` | `#24141A` |
| `muted` | `#6B5D50` | `#735C60` |
| `faint` | `#958676` | `#9C8689` |
| `primary` | `#E3AE4A` | `#D9A441` |
| `onPrimary` | `#1F1712` | `#24141A` |
| `primaryText` | `#120C08` | `#170A0F` |
| `accent` | `#A87420` | `#A06C24` |
| `accentText` | `#87570A` | `#85540C` |
| `soft` | `#F5E6C8` | `#F5E3CF` |
| `tile` | `#F0E5D3` | `#F2E1E1` |
| `tileFg` | `#87570A` | `#85540C` |
| `shadow` | `rgba(0,0,0,0.12)` | `rgba(0,0,0,0.12)` |

Measured contrast (Night Vigil · Light / Wine · Light): `text` on `bg` 16.4 / 16.1,
`muted` on `bg` 5.9 / 5.6, `accentText` on `soft` 5.0 / 5.1, `onPrimary` on `primary`
8.8 / 7.9, `faint` on `bg` 3.3 / 3.1.

Rules:
- Text on `bg`/`surface` uses `text` or `muted` (both pass 4.5:1). `faint` is only for
  dimmed lyric lines at ≥17px.
- Gold (`primary`/`accent`) is for one thing per area: the main action, the current line,
  or the active state — not decoration everywhere.
- Lyrics status: **Synced** = `soft` background + `accentText`; **Text only** = `line`
  border + `muted`.
- Album art without an image: `tile` square with the first letter of the title in `tileFg`.
- Light mode: bright gold `primary` on a light `bg` is only ≈ 1.9:1. Use it for filled
  buttons (dark `onPrimary` text) but use `accent` for thin indicators such as progress
  bars and active borders.

## Typography

| Role | Font | Size / weight | Notes |
|---|---|---|---|
| UI text (Latin) | Inter | 13–16 / 400–600 | |
| UI text (Ethiopic) | Noto Sans Ethiopic | same as UI | fallback after Inter |
| Screen titles | Inter + Noto Sans Ethiopic | 24–30 / 700 | |
| Song titles in lists | Noto Sans Ethiopic | 16 / 600 | ellipsis on one line |
| Lyrics — current line | Noto Sans Ethiopic | 26–30 / 700, color `primaryText` | user-adjustable size |
| Lyrics — other lines | Noto Sans Ethiopic | 17–22 / 500 | line height 1.5–1.6 |
| Transliteration | Inter | 14–15 / 400 | under the current line, optional |
| Labels / badges | Inter | 11–12 / 600–700 | uppercase only for short labels like CHORUS |

Ethiopic text needs extra vertical space: never use line height below 1.4 for Ge'ez.

## Shape, spacing, touch

- Radius: 12 (inputs, small cards), 14–16 (cards, mini player), 22–28 (large tap areas),
  pills fully rounded.
- Screen side padding 16–20; list rows 66px high.
- Every tap target ≥ 44×44.
- Icons: 1.8px stroke line icons, 20–24px.

## Components on the canvas

- Bottom navigation: Home, Search, Library, Contribute (active = `primaryText`, bold).
- Mini player above the navigation: tile, title, current lyric line, play/pause.
- Library tab chips (Tracks, Folders, Albums, Artists, Favorites, Playlists): active chip
  = `text` background with `bg` text.
- Track row: tile, title, artist · duration, Synced/Text badge, overflow menu.
- Floating lyrics card: current line + next line, lock / expand / close; collapsed
  bubble with the ዜ logo.
- Settings rows: grouped cards with toggles (`primary` when on) and value rows (›).

## Screens designed so far

| # | Screen | Status |
|---|---|---|
| 1 | Library — Tracks | Approved style |
| 2 | Library — Favorites | Approved style |
| 3 | Now Playing — synced lyrics | Approved style |
| 4 | Floating lyrics over another app | Approved style |
| 5 | Contribute — how it works | Approved style |
| 6 | Add lyrics (step 1 of 4) | Approved style |
| 7a / 7b / 7c / 7d | Sync lyrics — list / focus / tap the line / "we guess, you check" | **Choose one** |
| 8 | Settings | Approved style |

Still to design: Home, Search, Song detail, Library (Folders, Albums, Artists, Playlists,
playlist detail), Link recording, Review & submit, My contributions, Sign in (Google),
Profile & backup, onboarding and permissions.

## Flutter mapping

- A light and a dark `ThemeData`, each built from a `ZemaColors` `ThemeExtension` holding
  the tokens above; the palette (Night Vigil / Wine) and theme mode (System / Light /
  Dark) are chosen in Settings.
- `ColorScheme.dark(...)` / `ColorScheme.light(...)` (surface: bg, primary, onPrimary, ...) for
  Material widgets; custom tokens (`faint`, `soft`, `tile`, `primaryText`, `accentText`)
  are read from the extension.
- Fonts: `Inter` and `Noto Sans Ethiopic` bundled as assets (not fetched at runtime), with
  Noto Sans Ethiopic set as a font fallback.
