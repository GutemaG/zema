---
stage: plan
bolt: 003-app-foundation-ui
created: 2026-10-24T18:40:28Z
---

## Implementation Plan: app-foundation-ui (bolt 3 of 3)

### Objective

Replace the Settings placeholder with the minimal S28 screen: a General card (Language,
Theme) and an About card (Version, Open-source licenses). Palette and language are
saved with `shared_preferences` and loaded in `main()` before `runApp`. A change applies
immediately, and the first frame after a relaunch already uses the saved choices. This
bolt closes intent 001.

### Deliverables

**Settings data and state (shared by 009 and 010)**
- `lib/features/settings/data/app_settings.dart`: an immutable `AppSettings` with
  `palette` (a `ZemaPalette`, Night Vigil by default) and `languageCode` (a nullable
  string; null means "not chosen, follow the device"). It has `==`, `hashCode` and
  `copyWith`.
- `lib/features/settings/data/settings_repository.dart`: `SettingsRepository` over
  `SharedPreferences`, with keys `paletteId` and `localeCode`.
  - `load()` is synchronous and reads the preferences already in memory. Missing or
    unknown values become the defaults.
  - `savePalette()` and `saveLanguage()` are async and throw if the write fails.
- `lib/features/settings/application/settings_controller.dart` defines three providers:
  - `settingsRepositoryProvider` and `initialSettingsProvider` are both set in `main()`
    through `ProviderScope` overrides.
  - `settingsProvider` is a `Notifier<AppSettings>` with `setPalette` and `setLanguage`.
    Each method updates state first, so the UI changes immediately, then saves. If the
    save fails, the new value stays for the session and a warning is logged. Picking the
    value that is already active does nothing.
- `paletteProvider` and `savedLanguageCodeProvider` from bolts 1 and 2 now read from
  `settingsProvider`, so `ZemaApp` and the language resolution need no changes.
- `lib/main.dart` does the following before `runApp`:
  1. Initializes the binding.
  2. Awaits `SharedPreferences.getInstance()`.
  3. Builds the repository and calls `load()`.
  4. Passes both into the `ProviderScope` overrides.
  5. Sets up debug-only log printing for `package:logging`.

**008 – Settings screen**
- `lib/features/settings/presentation/settings_screen.dart`:
  - An app bar with back and the "Settings" title.
  - Uppercase section labels "General" and "About".
  - Grouped cards on `surface` with radius 16 and `line` dividers, as on the canvas.
- `lib/features/settings/presentation/widgets/settings_group.dart` and
  `settings_row.dart` provide the reusable section label, card and row. A row is at
  least 56 px tall, with the label on the left and the value in `muted` plus › on the
  right. A row without an action has no ›. Each row is one screen-reader node, read as
  label plus value.
- The rows:
  - **Language** shows the current language in its own script (English, አማርኛ, Afaan
    Oromoo, ትግርኛ) and opens the language picker.
  - **Theme** shows the localized palette name ("Night Vigil" or "Night Vigil · Wine")
    and opens the palette picker.
  - **Version** shows `1.0.0 (1)` from `package_info_plus` through an
    `appVersionProvider`. It shows "—" if reading the version fails. It cannot be tapped.
  - **Open-source licenses** opens Flutter's license page with the app name and version.
    The page lists all packages and the two font licenses.
- None of the other S28 sections are included.

**009 – Switch palette**
- `lib/features/settings/presentation/widgets/palette_picker.dart` is a modal bottom
  sheet with radio options for both palettes. Each option shows a small swatch (a `bg`
  circle with a `primary` dot). The current palette is selected, and picking one applies
  it, saves it and closes the sheet.

**010 – Switch language**
- `lib/features/settings/presentation/widgets/language_picker.dart` is a modal bottom
  sheet with radio options for the four languages. Each is written in its own script and
  never translated. Ethiopic labels keep a line height of at least 1.4. The current
  language is selected, and picking one applies it, saves it and closes the sheet.

**Strings**
- New English keys: `settingsSectionGeneral`, `settingsSectionAbout`, `settingsLanguage`,
  `settingsTheme`, `paletteNightVigil`, `paletteWine`, `settingsVersion` and
  `settingsLicenses`. The unused `settingsComingSoonMessage` is removed.
- Draft translations for `settingsTitle` and `settingsLanguage`, so someone who switches
  language by accident can still find their way back:
  - **am**: ቅንብሮች · ቋንቋ
  - **om**: Qindaa'ina · Afaan
  - **ti**: ቅጥዕታት · ቋንቋ

### Dependencies

- **shared_preferences 2.5.x**: stores the two settings. Its legacy API supports
  `setMockInitialValues` in tests, which the story asks for.
- **package_info_plus 10.2.x**: the version and build number.
- **logging 1.3.x**: the warning when a save fails, as the coding standards require.
- **Bolt 2**: router, `/settings` route, providers, localization, C07.

### Technical Approach

- **Preload instead of async state**: settings are read once in `main()`, so
  `settingsProvider` starts with the saved values. There is no loading state and the
  first frame can't show the wrong theme or language.
- **Optimistic updates**: state changes before the save. A failed save never reverts the
  UI, only logs, as the story's edge case requires.
- **The row is labeled "Theme", not "Palette"**: the canvas and the UX guide (decided
  2026-10-23) use "Theme" for this row. The values are palette names. The story's
  "Palette" wording refers to what the row controls.
- **Device checks**: no Android emulator or phone is set up, so I can't run the
  force-stop and cold-start checks on Android. On the iOS simulator I'll write
  `paletteId` and `localeCode` into the app's preferences (`NSUserDefaults`), relaunch,
  and screenshot the first frame to confirm the saved values load before it is drawn.

### Acceptance Criteria

- [ ] Settings shows a General card (Language, Theme) and an About card (Version,
      Open-source licenses), styled as grouped cards with value rows and ›
- [ ] Language shows the current language in its own script; Theme shows the localized
      palette name
- [ ] Version shows `version (build)`, and "—" if reading it fails
- [ ] Open-source licenses opens the license page, which lists packages and both font
      licenses
- [ ] No other S28 sections
- [ ] Every row is labeled, at least 44 px tall, and nothing overflows at 1.3× text scale
- [ ] Theme picker shows both palettes with swatches, with the current one selected;
      picking Wine re-themes visible screens immediately
- [ ] A saved Wine is used on the first frame after relaunch; a missing or unknown saved
      value gives Night Vigil without crashing
- [ ] Language picker lists English, አማርኛ, Afaan Oromoo and ትግርኛ in their own scripts,
      with the current one selected; picking አማርኛ switches visible strings immediately
- [ ] A saved language is used on the first frame after relaunch, even if the device
      locale differs; picking the active language does nothing and just closes the sheet
- [ ] `SettingsRepository` saves and reads back palette and language with
      `SharedPreferences.setMockInitialValues`; a failed save keeps the new value for the
      session and logs a warning
- [ ] `flutter analyze` and `dart format` clean; all tests pass

---

## Addendum (2026-10-24T19:05:00Z): story 011 – theme mode

Scope change requested by the product owner before the bolt completed: add light and
dark options. Decisions, made by the product owner when asked:

- **Options**: System / Light / Dark, default **System** (follows the phone).
- **Palettes**: each palette gets a light version, and Theme and Palette are two
  separate rows (4 color sets in total).
- **Light colors**: the drafted tokens (contrast-checked), recorded in
  `docs/design-system.md` as a draft until a design pass.

### Additional deliverables

- `zema_colors.dart` gets `nightVigilLight` and `wineLight` instances.
- `ZemaPalette` carries `dark` and `light` colors, plus `colorsFor(brightness)`.
- `buildTheme(palette, brightness)` builds a light or dark `ThemeData` (`ColorScheme.light`
  or `.dark`). Light and dark versions of the text theme, app bar and bottom sheet come
  from the tokens.
- `AppSettings.themeMode` (`ThemeMode`, default `system`) is stored under key `themeMode`.
  `SettingsRepository.saveThemeMode` saves it and `SettingsController.setThemeMode` sets
  it. `themeModeProvider` exposes it.
- `ZemaApp` uses `theme` (light), `darkTheme` (dark) and `themeMode` from settings.
- Settings → General gets three rows: Language, **Theme** (System / Light / Dark, opens
  `theme_mode_picker.dart`) and **Palette** (renamed from "Theme"). The palette swatch
  shows the colors of the current brightness.
- New strings: `settingsPalette`, `themeModeSystem`, `themeModeLight`, `themeModeDark`.
- Docs are updated wherever "dark only" was recorded: intent requirements (FR-3, FR-9, new
  FR-12), unit brief, stories 008 and 011, story index, `docs/design-system.md`,
  `standards/ux-guide.md`, `standards/tech-stack.md` and `docs/roadmap.md`.

### Additional acceptance criteria

- [ ] General shows Language and one Appearance row (palette · mode); its sheet sets
      mode and palette together and stays open until Done
- [ ] With nothing saved, the app follows the phone's brightness, including live changes
- [ ] Picking Light or Dark re-themes immediately; the choice is used on the first frame
      after relaunch; an unknown saved value falls back to System
- [ ] Both light palettes match `docs/design-system.md` (30 more token values tested) and
      pass the contrast rules (tested)
- [ ] `SettingsRepository` round-trips the theme mode

### Revision (2026-10-24T19:35:00Z): one Appearance choice

After seeing two separate rows, the product owner asked for Theme and Palette as one
choice. They picked "one row, combined sheet":

- One **Appearance** row with a value like "Night Vigil · System".
- Its sheet has a System / Light / Dark segmented switch and two palette preview cards
  drawn in the current mode. Taps apply and save immediately, the sheet stays open so
  combinations can be tried, and **Done** closes it.
- The palette pickers and theme-mode pickers are replaced by
  `widgets/appearance_picker.dart`. The Wine palette's display name is shortened to
  "Wine" so the row value fits.
- Strings: `settingsAppearance` and `actionDone` added; `settingsTheme` and
  `settingsPalette` removed.
