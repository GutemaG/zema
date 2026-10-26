---
stage: plan
bolt: 009-lyrics-engine-and-display-ui
created: 2026-10-26T13:46:18Z
---

## Implementation Plan: lyrics-engine-and-display-ui (bolt 1 of 9)

### Objective

Replace Home's "Coming soon" with a working screen built from what intent 002 already
provides: library access state, tracks, favorites, play history, playlists and the
restored player queue (stories 001 and 002).

### Deliverables

- **Home screen** (`features/home/presentation/home_screen.dart`), a scrolling column of
  sections, top to bottom:
  - **Header**: title, a search button that switches to the Search tab, and the
    existing Settings button.
  - **Quick actions**: Shuffle all, Favorites, Recently added, Playlists, as a
    wrapping grid of tiles. Shuffle all plays the visible library shuffled and is
    disabled while there are no songs. Favorites and Playlists open those Library tabs.
    Recently added opens its auto playlist page.
  - **Continue listening**: a card showing the restored song with "Resume from m:ss"
    and a play button. It shows only when there is a current song that isn't playing,
    and it hides when the song's file is missing or hidden.
  - **Recently played**: a horizontal row of up to 10 songs from the existing auto
    playlist. Tapping a song plays the row from that song; "See all" opens the auto
    playlist page.
  - **Your playlists**: a horizontal row of collage cards. Tapping one opens the
    playlist page.
  - Each section hides when it has nothing to show.
- **States**, using the existing C07 messages:
  - No audio access: the same permission states as Library (explain, denied, open
    settings, iOS unsupported). The widget moves out of `library_screen.dart` into a
    shared `LibraryAccessState` so both tabs use it.
  - Empty library after a scan: C07 empty state with a Rescan action.
  - While scanning with nothing stored: quick actions plus a progress indicator.
- **Opening a Library tab**: `/library?tab=favorites|playlists` selects that tab.
  `AppRoutes.libraryTab(...)` builds the link, and an unknown value falls back to
  Tracks.
- **Strings**: about 12 new English ARB strings. The unused `homeComingSoonMessage` is
  removed; `comingSoonTitle` stays because Search and Contribute still use it.

### Dependencies

- **Intent 002 providers**:
  - `libraryAccessProvider`, `libraryTracksProvider`, `librarySyncProvider`: access
    state, songs and Rescan
  - `autoPlaylistProvider`: Recently played and Recently added
  - `playlistsProvider`, `PlaylistCollage`: the playlists row
  - `currentTrackProvider`, `playerStateProvider`, `positionProvider`: Continue
    listening
  - `playerControllerProvider`: Shuffle all, Resume and Play
- No new packages and no schema change.

### Technical Approach

- `HomeScreen` becomes a `ConsumerWidget`. It shows the shared access state until
  access is granted, then a `CustomScrollView` with one sliver per section.
- Section widgets live in `features/home/presentation/widgets/`:
  - `quick_actions.dart`
  - `continue_listening_card.dart`
  - `home_track_row.dart`: the horizontal song row
  - `home_playlists_row.dart`
  - `home_section_header.dart`: title and an optional "See all"
- Shuffle all calls the existing Shuffle path that Tracks' Play bar uses.
- Resume calls `play()` on the restored queue. The position was already restored by
  intent 002.
- Opening a tab: `LibraryScreen` reads the `tab` query parameter, and
  `DefaultTabController` gets that tab as its `initialIndex`. A key built from the tab
  name rebuilds the controller when Home links to a different tab.
- Search button: `StatefulNavigationShell.goBranch` to the Search branch, or
  `context.go(AppRoutes.search)`.
- Row cards have a fixed width that scales with the text scale, so 1.3× doesn't clip.
  Each card has a semantics label combining title and artist.

### Acceptance Criteria

- [ ] Home shows the header, quick actions, Continue listening, Recently played and
  Your playlists; each section hides when it's empty
- [ ] Shuffle all, Favorites, Recently added and Playlists open or play the right thing
- [ ] Resume continues from the saved position; the card hides while playing
- [ ] Tapping a recent song plays the row from it; See all opens Recently played
- [ ] No access shows the same permission flow as Library; an empty library shows
  Rescan
- [ ] Rows update as songs play and playlists change, without a restart
- [ ] 1.3× text in light and dark without overflow; TalkBack labels on cards
- [ ] `flutter analyze` and format clean; the existing tests still pass (the Home
  "Coming soon" test is replaced)
- [ ] Checked on the Android emulator
