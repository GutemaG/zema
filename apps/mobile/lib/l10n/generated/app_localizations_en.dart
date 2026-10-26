// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Zema';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navLibrary => 'Library';

  @override
  String get navContribute => 'Contribute';

  @override
  String get homeSettingsTooltip => 'Settings';

  @override
  String get comingSoonTitle => 'Coming soon';

  @override
  String get homeSearchTooltip => 'Search';

  @override
  String get homeShuffleAll => 'Shuffle all';

  @override
  String get homeContinueListening => 'Continue listening';

  @override
  String homeResumeFrom(String position) {
    return 'Resume from $position';
  }

  @override
  String get homeResume => 'Resume';

  @override
  String get homeRecentlyPlayed => 'Recently played';

  @override
  String get homeYourPlaylists => 'Your playlists';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get searchScopeAll => 'All';

  @override
  String get searchScopeSongs => 'Songs';

  @override
  String get searchScopeArtists => 'Artists';

  @override
  String get searchScopeAlbums => 'Albums';

  @override
  String get searchSeeAll => 'See all';

  @override
  String get searchRecentHeading => 'Recent searches';

  @override
  String get searchClearRecent => 'Clear all';

  @override
  String searchRemoveRecent(String query) {
    return 'Remove $query';
  }

  @override
  String get searchHintTitle => 'Find a song';

  @override
  String get searchHintMessage =>
      'Search by title, artist or album. Any keyboard works: “kidist” finds “ቅድስት”.';

  @override
  String get contributeComingSoonMessage =>
      'Add lyrics and sync timings to help other listeners.';

  @override
  String get libraryAccessTitle => 'Play the music on your phone';

  @override
  String get libraryAccessMessage =>
      'Zema needs access to your audio files to list and play them. It reads audio files only, nothing else.';

  @override
  String get libraryAccessAllow => 'Allow';

  @override
  String get libraryAccessNotNow => 'Not now';

  @override
  String get libraryAccessDeniedTitle => 'Music access is off';

  @override
  String get libraryAccessDeniedMessage =>
      'Allow access to your audio files to see and play your music.';

  @override
  String get libraryAccessGrant => 'Grant access';

  @override
  String get libraryAccessSettingsMessage =>
      'Turn on music and audio access for Zema in your phone\'s settings.';

  @override
  String get libraryAccessOpenSettings => 'Open settings';

  @override
  String get libraryUnsupportedTitle => 'Not available on iOS yet';

  @override
  String get libraryUnsupportedMessage =>
      'Playing the music on your phone will come to iPhone in a later version.';

  @override
  String get libraryScanning => 'Looking for music on your phone…';

  @override
  String get libraryScanFailedTitle => 'Couldn\'t read your music';

  @override
  String get libraryScanFailedMessage =>
      'Something went wrong while reading your audio files.';

  @override
  String get libraryScanFailedSnack => 'Couldn\'t update your library';

  @override
  String get libraryEmptyTitle => 'No music found';

  @override
  String get libraryEmptyMessage => 'Songs saved on your phone appear here.';

  @override
  String get unknownArtist => 'Unknown artist';

  @override
  String get unknownAlbum => 'Unknown album';

  @override
  String get actionTryAgain => 'Try again';

  @override
  String librarySongCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String get libraryTabTracks => 'Tracks';

  @override
  String get libraryTabFolders => 'Folders';

  @override
  String get libraryTabAlbums => 'Albums';

  @override
  String get libraryTabArtists => 'Artists';

  @override
  String get libraryTabFavorites => 'Favorites';

  @override
  String get libraryTabPlaylists => 'Playlists';

  @override
  String get librarySearchHint => 'Search songs, artists, albums';

  @override
  String get libraryClearSearch => 'Clear search';

  @override
  String get libraryNoResultsTitle => 'No matches';

  @override
  String get libraryNoResultsMessage =>
      'Try a different word or check the spelling.';

  @override
  String get librarySortTooltip => 'Sort';

  @override
  String get sortTitle => 'Title';

  @override
  String get sortArtist => 'Artist';

  @override
  String get sortAlbum => 'Album';

  @override
  String get sortDateAdded => 'Date added';

  @override
  String get sortDuration => 'Duration';

  @override
  String get sortAscending => 'Ascending';

  @override
  String get sortDescending => 'Descending';

  @override
  String get actionPlay => 'Play';

  @override
  String get actionShuffle => 'Shuffle';

  @override
  String get playerPlay => 'Play';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerNext => 'Next';

  @override
  String get playerPrevious => 'Previous';

  @override
  String get playerShuffleOn => 'Shuffle on';

  @override
  String get playerShuffleOff => 'Shuffle off';

  @override
  String get playerRepeatOff => 'Repeat off';

  @override
  String get playerRepeatAll => 'Repeat all';

  @override
  String get playerRepeatOne => 'Repeat one';

  @override
  String get playerClose => 'Close';

  @override
  String get playerNowPlaying => 'Now playing';

  @override
  String get playerOpen => 'Open Now Playing';

  @override
  String get playerSeek => 'Song position';

  @override
  String get playerNoLyrics => 'No lyrics yet';

  @override
  String get playbackChannelName => 'Playback';

  @override
  String playerUnplayable(String title) {
    return 'Couldn\'t play $title';
  }

  @override
  String playerMiniLabel(String title, String artist) {
    return '$title, $artist';
  }

  @override
  String playerTrackPosition(String position, String duration) {
    return '$position of $duration';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get paletteNightVigil => 'Night Vigil';

  @override
  String get paletteWine => 'Wine';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicenses => 'Open-source licenses';

  @override
  String get errorNotFoundTitle => 'Page not found';

  @override
  String get errorNotFoundMessage =>
      'This page doesn\'t exist. Go back to Home to continue.';

  @override
  String get actionGoHome => 'Go home';

  @override
  String get actionDone => 'Done';

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get queueTitle => 'Queue';

  @override
  String queueUpNext(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs up next',
      one: '1 song up next',
      zero: 'Nothing up next',
    );
    return '$_temp0';
  }

  @override
  String get queueClear => 'Clear queue';

  @override
  String queueRemoved(String title) {
    return 'Removed \"$title\" from the queue';
  }

  @override
  String get queueRemove => 'Remove from queue';

  @override
  String get queueReorder => 'Drag to reorder';

  @override
  String get sleepTitle => 'Sleep timer';

  @override
  String sleepMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get sleepEndOfSong => 'End of current song';

  @override
  String get sleepEndOfSongShort => 'End of song';

  @override
  String get sleepCustom => 'Custom…';

  @override
  String get sleepCustomTitle => 'Custom sleep timer';

  @override
  String get sleepCustomLabel => 'Minutes';

  @override
  String sleepCustomRange(int min, int max) {
    return 'Enter $min to $max minutes';
  }

  @override
  String sleepStopsIn(String time) {
    return 'Stops in $time';
  }

  @override
  String get sleepStopsAtEndOfSong => 'Stops at the end of this song';

  @override
  String get sleepCancel => 'Cancel timer';

  @override
  String get folderPhone => 'Phone';

  @override
  String get folderSdCard => 'SD card';

  @override
  String get folderHide => 'Hide folder';

  @override
  String folderMenu(String name) {
    return 'More options for $name';
  }

  @override
  String folderHidden(String name) {
    return '\"$name\" hidden';
  }

  @override
  String get foldersEmptyTitle => 'No folders';

  @override
  String get foldersEmptyMessage =>
      'Folders with music on your phone will show here.';

  @override
  String get folderGoneTitle => 'Folder not found';

  @override
  String get folderGoneMessage =>
      'This folder has no music now. It may have been hidden or emptied.';

  @override
  String albumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
    );
    return '$_temp0';
  }

  @override
  String get variousArtists => 'Various artists';

  @override
  String get sortAlbumName => 'Name';

  @override
  String get sortYear => 'Year';

  @override
  String get albumsEmptyTitle => 'No albums';

  @override
  String get albumsEmptyMessage =>
      'Albums from your music files will show here.';

  @override
  String get albumGoneTitle => 'Album not found';

  @override
  String get albumGoneMessage => 'This album is no longer in your library.';

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String artistCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artists',
      one: '1 artist',
    );
    return '$_temp0';
  }

  @override
  String get artistAlbums => 'Albums';

  @override
  String get artistSongs => 'Songs';

  @override
  String get artistsEmptyTitle => 'No artists';

  @override
  String get artistsEmptyMessage =>
      'Singers from your music files will show here.';

  @override
  String get artistGoneTitle => 'Artist not found';

  @override
  String get artistGoneMessage => 'This artist is no longer in your library.';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionDelete => 'Delete';

  @override
  String songMenu(String title) {
    return 'More options for $title';
  }

  @override
  String get songPlayNext => 'Play next';

  @override
  String songPlayingNext(String title) {
    return '\"$title\" will play next';
  }

  @override
  String get songAddToQueue => 'Add to queue';

  @override
  String songAddedToQueue(String title) {
    return 'Added \"$title\" to the queue';
  }

  @override
  String get songAddToPlaylist => 'Add to playlist';

  @override
  String get songFavorite => 'Add to favorites';

  @override
  String get songUnfavorite => 'Remove from favorites';

  @override
  String songFavorited(String title) {
    return 'Added \"$title\" to favorites';
  }

  @override
  String songUnfavorited(String title) {
    return 'Removed \"$title\" from favorites';
  }

  @override
  String get songMatchLyrics => 'Match lyrics';

  @override
  String get songChangeLyrics => 'Change lyrics';

  @override
  String get songUnlinkLyrics => 'Unlink lyrics';

  @override
  String songLyricsLinked(String title) {
    return 'Showing the lyrics of $title';
  }

  @override
  String songLyricsUnlinked(String title) {
    return 'No lyrics for $title';
  }

  @override
  String get songGoToAlbum => 'Go to album';

  @override
  String get songGoToArtist => 'Go to artist';

  @override
  String get songHide => 'Hide song';

  @override
  String songHidden(String title) {
    return '\"$title\" is hidden';
  }

  @override
  String get songShare => 'Share';

  @override
  String get songShareFailed => 'Couldn\'t open sharing for this song';

  @override
  String get favoritesEmptyTitle => 'No favorites yet';

  @override
  String get favoritesEmptyMessage =>
      'Tap the heart on Now Playing, or choose \"Add to favorites\" in a song\'s menu.';

  @override
  String get playlistNew => 'New playlist';

  @override
  String get playlistCreate => 'Create playlist';

  @override
  String get playlistCreateHint =>
      'Keep songs for a feast day or a service together';

  @override
  String get playlistRename => 'Rename playlist';

  @override
  String get playlistName => 'Name';

  @override
  String get playlistDescription => 'Description (optional)';

  @override
  String get playlistNameRequired => 'Enter a name';

  @override
  String get playlistNameTaken => 'You already have a playlist with this name';

  @override
  String playlistMenu(String name) {
    return 'More options for $name';
  }

  @override
  String get playlistDelete => 'Delete playlist';

  @override
  String get playlistDeleteTitle => 'Delete playlist?';

  @override
  String playlistDeleteMessage(String name) {
    return '\"$name\" will be deleted. The songs stay on your phone.';
  }

  @override
  String get playlistGoneTitle => 'Playlist not found';

  @override
  String get playlistGoneMessage => 'This playlist was deleted.';

  @override
  String get playlistAddSongs => 'Add songs';

  @override
  String get playlistEmptyTitle => 'No songs yet';

  @override
  String get playlistEmptyMessage =>
      'Tap \"Add songs\" to pick songs from your library.';

  @override
  String get playlistRemove => 'Remove from playlist';

  @override
  String playlistRemoved(String title) {
    return 'Removed \"$title\" from the playlist';
  }

  @override
  String playlistAddCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count songs',
      one: 'Add 1 song',
      zero: 'Add songs',
    );
    return '$_temp0';
  }

  @override
  String get playlistInPlaylist => 'Already in the playlist';

  @override
  String selectionCount(int count) {
    return '$count selected';
  }

  @override
  String get selectionClose => 'End selection';

  @override
  String get selectionSelectAll => 'Select all';

  @override
  String selectionAddToPlaylistTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count songs to a playlist',
      one: 'Add 1 song to a playlist',
    );
    return '$_temp0';
  }

  @override
  String selectionAddedToPlaylist(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count songs to $name',
      one: 'Added 1 song to $name',
      zero: 'All already in $name',
    );
    return '$_temp0';
  }

  @override
  String selectionAddedToQueue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count songs to the queue',
      one: 'Added 1 song to the queue',
    );
    return '$_temp0';
  }

  @override
  String selectionFavorited(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count songs to favorites',
      one: 'Added 1 song to favorites',
    );
    return '$_temp0';
  }

  @override
  String selectionUnfavorited(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Removed $count songs from favorites',
      one: 'Removed 1 song from favorites',
    );
    return '$_temp0';
  }

  @override
  String selectionHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs hidden',
      one: '1 song hidden',
    );
    return '$_temp0';
  }

  @override
  String get autoPlaylistsHeading => 'Auto playlists';

  @override
  String get autoRecentlyAdded => 'Recently added';

  @override
  String get autoMostPlayed => 'Most played';

  @override
  String get autoRecentlyPlayed => 'Recently played';

  @override
  String get autoRecentlyAddedEmptyTitle => 'Nothing new';

  @override
  String get autoRecentlyAddedEmptyMessage =>
      'Songs added to your phone in the last 30 days show up here.';

  @override
  String get autoPlayedEmptyTitle => 'Nothing played yet';

  @override
  String get autoMostPlayedEmptyMessage =>
      'The songs you play most show up here.';

  @override
  String get autoRecentlyPlayedEmptyMessage =>
      'The songs you play show up here, latest first.';

  @override
  String get settingsSectionLibrary => 'Library';

  @override
  String get settingsHiddenFolders => 'Hidden folders';

  @override
  String get settingsHiddenSongs => 'Hidden songs';

  @override
  String get settingsRescan => 'Rescan library';

  @override
  String get settingsRescanning => 'Scanning…';

  @override
  String settingsRescanDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Found $count songs',
      one: 'Found 1 song',
    );
    return '$_temp0';
  }

  @override
  String get settingsMinDuration => 'Ignore audio shorter than';

  @override
  String get settingsOff => 'Off';

  @override
  String settingsSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get actionUnhide => 'Unhide';

  @override
  String get hiddenFoldersEmptyTitle => 'No hidden folders';

  @override
  String get hiddenFoldersEmptyMessage =>
      'Hide a folder from its menu in Library → Folders.';

  @override
  String get hiddenSongsEmptyTitle => 'No hidden songs';

  @override
  String get hiddenSongsEmptyMessage => 'Hide a song from its menu.';

  @override
  String get settingsSectionPlayback => 'Playback';

  @override
  String get settingsSleepDefault => 'Sleep timer default';

  @override
  String get settingsNone => 'None';

  @override
  String get settingsPauseOnUnplug => 'Pause when headphones are unplugged';

  @override
  String get settingsInterruptions => 'When another app plays sound';

  @override
  String get settingsInterruptionsPause => 'Pause';

  @override
  String get settingsInterruptionsDuck => 'Lower volume';

  @override
  String get settingsInterruptionsNote => 'Calls always pause.';

  @override
  String get settingsGapless => 'Gapless playback';
}
