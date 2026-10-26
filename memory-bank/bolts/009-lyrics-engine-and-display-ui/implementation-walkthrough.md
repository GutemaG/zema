---
stage: implement
bolt: 009-lyrics-engine-and-display-ui
created: 2026-10-26T13:53:06Z
---

## Implementation Walkthrough: lyrics-engine-and-display-ui (bolt 1 of 9)

### Summary

Home now shows quick actions, the song to continue, recently played songs and the user's playlists instead of "Coming soon". It is built only from intent 002's providers. The library permission screens moved into a shared gate so Home and Library show the same flow.

### Structure Overview

Home is a list of independent section widgets, and each one hides itself when it has nothing to show. The screen decides between the permission states, a scan failure, an empty library with Rescan, and the sections (with a progress indicator while the first scan runs). The quick actions and "See all" open Library on a chosen tab through a small request provider.

### Completed Work

- [x] `apps/mobile/lib/features/home/presentation/home_screen.dart` - header with Search and Settings buttons; access gate; empty, failed and scanning states; the sections
- [x] `apps/mobile/lib/features/home/presentation/widgets/quick_actions.dart` - Shuffle all (disabled with no songs), Favorites, Recently added, Playlists in a two-column wrap
- [x] `apps/mobile/lib/features/home/presentation/widgets/continue_listening_card.dart` - the restored song with "Resume from m:ss"; hidden while playing or when the song is no longer in the library
- [x] `apps/mobile/lib/features/home/presentation/widgets/home_rows.dart` - Recently played (up to 10, plays the row from the tapped song) and Your playlists, as horizontal card rows with See all
- [x] `apps/mobile/lib/features/home/presentation/widgets/home_section_header.dart` - section title with an optional See all
- [x] `apps/mobile/lib/features/library/presentation/library_access_gate.dart` - the permission states, moved out of the Library screen and shared with Home
- [x] `apps/mobile/lib/features/library/application/library_tab_request.dart` - `LibraryTab` and a request provider other screens use to open a Library tab
- [x] `apps/mobile/lib/features/library/presentation/library_screen.dart` - uses the gate; its tabs have their own controller that opens on, and switches to, a requested tab
- [x] `apps/mobile/lib/l10n/app_en.arb` - 8 Home strings; the unused Home "Coming soon" message removed
- [x] `apps/mobile/test/app/app_shell_test.dart`, `test/app/l10n/localizations_test.dart` - updated for Home no longer showing "Coming soon"

### Key Decisions

- **Request provider, not a `?tab=` link**: the Library branch keeps its state, so a link with the same tab as last time wouldn't switch back if the user had moved to another tab since. Each request is a new object, so it always switches.
- **Detail pages open in the Library branch** (`go`, as the rest of the app does): Back from Recently added or a playlist returns to Library, not Home.
- **Rows as a Row in a horizontal scroll view**: at most a few dozen cards, and the height follows the text scale with no fixed row height to clip at 1.3×.
- **Continue listening needs the song in the visible library**: hidden or missing songs don't show a card that can't play.

### Deviations from Plan

- Opening a Library tab uses `libraryTabRequestProvider` instead of a `/library?tab=` query parameter (see Key Decisions).
- 8 strings instead of about 12: the labels for Favorites, Playlists, Recently added and Rescan reuse existing strings.

### Dependencies Added

None.

### Developer Notes

- The Search button switches to the Search tab, which still shows "Coming soon" until bolt 011.
- Checked on the emulator: Home shows all sections with real data, and Favorites and Playlists open the right Library tab, including when Library was already open.
- Full suite: 532 tests pass after the two test updates.
