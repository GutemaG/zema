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
  String get playerNoLyrics => 'No lyrics for this song';

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

  @override
  String get playerShowLyrics => 'Show lyrics';

  @override
  String get playerShowArtwork => 'Show artwork';

  @override
  String get lyricsChorus => 'Chorus';

  @override
  String get lyricsOptions => 'Lyrics options';

  @override
  String get lyricsShowTransliteration => 'Show transliteration';

  @override
  String get lyricsTextSize => 'Text size';

  @override
  String get lyricsTextSmaller => 'Smaller text';

  @override
  String get lyricsTextLarger => 'Larger text';

  @override
  String get lyricsSyncOffset => 'Sync timing';

  @override
  String get lyricsOffsetEarlier => 'Show lines earlier';

  @override
  String get lyricsOffsetLater => 'Show lines later';

  @override
  String get lyricsOffsetReset => 'Reset timing';

  @override
  String get songViewLyrics => 'View lyrics';

  @override
  String get searchScopeLyrics => 'Lyrics';

  @override
  String get songDetailLyricsTab => 'Lyrics';

  @override
  String get songDetailInfoTab => 'Info';

  @override
  String get songDetailNotOnPhone => 'Not on this phone';

  @override
  String get songDetailAlbum => 'Album';

  @override
  String get songDetailArtist => 'Artist';

  @override
  String get songDetailSource => 'Source';

  @override
  String get songSourceBundled => 'Bundled sample';

  @override
  String get songSourceLocal => 'Your phone';

  @override
  String get lyricsVerse => 'Verse';

  @override
  String lyricsRepeat(String section) {
    return '↻ $section';
  }

  @override
  String get settingsSectionLyrics => 'Lyrics';

  @override
  String get settingsLyricsDefaultOffset => 'Default sync timing';

  @override
  String get settingsLyricsDefaultOffsetNote =>
      'Songs you\'ve adjusted in Now Playing keep their own timing.';

  @override
  String get catalogRefreshFailed =>
      'Couldn\'t update the song list. Check your connection.';

  @override
  String get catalogNotConfigured =>
      'The song list isn\'t available in this build.';

  @override
  String get lyricsOfflineTitle => 'You\'re offline';

  @override
  String get lyricsOfflineMessage =>
      'These lyrics haven\'t been downloaded yet. Connect to the internet and try again.';

  @override
  String get lyricsLoadFailedTitle => 'Couldn\'t load the lyrics';

  @override
  String get lyricsLoadFailedMessage =>
      'Something went wrong getting these lyrics. Try again in a moment.';

  @override
  String get lyricsPreviewOffline =>
      'Offline: these lyrics aren\'t downloaded yet';

  @override
  String get searchCatalogOffline =>
      'Offline: showing lyrics saved on this phone';

  @override
  String get searchCatalogFailed => 'Couldn\'t search the catalog';

  @override
  String get settingsLyricsDownloaded => 'Downloaded lyrics';

  @override
  String settingsLyricsDownloadedValue(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs',
      one: '1 song',
    );
    return '$_temp0 · $size';
  }

  @override
  String get settingsLyricsDownloadedNone => 'None yet';

  @override
  String get settingsLyricsDownloadAll => 'Download all lyrics for offline';

  @override
  String get settingsLyricsDownloadChecking => 'Checking the song list…';

  @override
  String settingsLyricsDownloadProgress(int done, int total) {
    return '$done of $total';
  }

  @override
  String get settingsLyricsDownloadDone => 'All lyrics downloaded';

  @override
  String settingsLyricsDownloadCancelled(int done, int total) {
    return 'Cancelled: $done of $total saved';
  }

  @override
  String settingsLyricsDownloadOffline(int done, int total) {
    return 'Stopped: check your connection. $done of $total saved';
  }

  @override
  String settingsLyricsDownloadFailed(int done, int total) {
    return 'Stopped: something went wrong. $done of $total saved';
  }

  @override
  String get settingsLyricsDownloadUnavailable => 'Not available in this build';

  @override
  String get settingsLyricsClear => 'Clear downloaded lyrics';

  @override
  String get settingsLyricsClearTitle => 'Clear downloaded lyrics?';

  @override
  String get settingsLyricsClearMessage =>
      'Songs will download again when you open them online. Your matched songs stay matched.';

  @override
  String get settingsLyricsClearConfirm => 'Clear';

  @override
  String get songDetailRecordingsTab => 'Recordings';

  @override
  String get songDetailMoreOptions => 'More options';

  @override
  String get songRecordingsEmpty => 'No recordings yet';

  @override
  String get songRecordingSynced => 'Synced';

  @override
  String get songRecordingTextOnly => 'Text only';

  @override
  String get songRecordingUsed => 'Used for lyrics';

  @override
  String get reportLyrics => 'Report wrong lyrics';

  @override
  String get reportReasonPrompt => 'What\'s wrong?';

  @override
  String get reportReasonWrongWords => 'Wrong words';

  @override
  String get reportReasonWrongTiming => 'Wrong timing';

  @override
  String get reportReasonWrongSong => 'Wrong song';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get reportNote => 'Note (optional)';

  @override
  String get reportSend => 'Send';

  @override
  String get reportSent => 'Thanks, we\'ll take a look';

  @override
  String get reportQueued => 'You\'re offline, so it\'ll be sent later';

  @override
  String get reportLimited =>
      'You\'ve sent the most reports for today. Try again tomorrow.';

  @override
  String get reportFailed => 'Couldn\'t send the report';

  @override
  String get homeNewLyrics => 'New lyrics from the community';

  @override
  String get accountChoiceTitle => 'Welcome to Zema';

  @override
  String get accountChoiceMessage =>
      'Everything works without an account. Sign in with Google to get more:';

  @override
  String get accountBenefitContribute => 'Add and fix lyrics for everyone';

  @override
  String get accountBenefitBackup =>
      'Back up your favorites, playlists and settings';

  @override
  String get accountBenefitRestore => 'Get them back on a new phone';

  @override
  String get accountContinueAsGuest => 'Continue as guest';

  @override
  String get accountSignIn => 'Sign in';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInHeading => 'Sign in to Zema';

  @override
  String get signInWithGoogle => 'Continue with Google';

  @override
  String get signInGoogleNote =>
      'Your Google name and photo are used for your profile. You can change the name later.';

  @override
  String get signInOffline => 'No connection. Try again when you\'re online.';

  @override
  String get signInFailed => 'Couldn\'t sign in. Try again.';

  @override
  String signInDone(String name) {
    return 'Signed in as $name';
  }

  @override
  String get homeProfileTooltip => 'Profile';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileGuestName => 'Guest';

  @override
  String get profileSignInCardTitle => 'Sign in to do more';

  @override
  String get profileRoleContributor => 'Contributor';

  @override
  String get profileRoleModerator => 'Moderator';

  @override
  String get profileRoleAdmin => 'Admin';

  @override
  String get profileSectionGeneral => 'General';

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get profileEditName => 'Edit name';

  @override
  String get profileNameLabel => 'Display name';

  @override
  String get profileNameOffline => 'No connection. Your name wasn\'t changed.';

  @override
  String get profileNameFailed => 'Couldn\'t save your name. Try again.';

  @override
  String get profileSignOut => 'Sign out';

  @override
  String get profileSignOutTitle => 'Sign out?';

  @override
  String get profileSignOutMessage =>
      'Your songs, playlists and favorites stay on this phone.';

  @override
  String get profileSignedOut => 'Signed out';

  @override
  String get profileDeleteAccount => 'Delete account';

  @override
  String get profileDeleteTitle => 'Delete your account?';

  @override
  String get profileDeleteMessage =>
      'This deletes your Zema account, your profile and your cloud backup. Lyrics you contributed stay, without your name.\n\nSongs, playlists and favorites on this phone stay.';

  @override
  String get profileDeleteContinue => 'Continue';

  @override
  String get profileDeleteConfirmTitle => 'This can\'t be undone';

  @override
  String get profileDeleteConfirmMessage =>
      'Your account and cloud backup will be deleted now, and you\'ll be signed out.';

  @override
  String get profileDeleting => 'Deleting your account…';

  @override
  String get profileDeleted => 'Account deleted';

  @override
  String get profileDeleteOffline =>
      'No connection. Your account wasn\'t deleted.';

  @override
  String get profileDeleteFailed =>
      'Couldn\'t delete your account. Try again later.';

  @override
  String get signInPromptTitle => 'Sign in to continue';

  @override
  String get signInPromptNotNow => 'Not now';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsAccountBackup => 'Account & backup';

  @override
  String get backupSignInReason =>
      'Sign in with Google to back up your favorites, playlists and settings, and get them back on a new phone.';

  @override
  String get backupTitle => 'Backup & sync';

  @override
  String get backupIncludedTitle => 'What\'s backed up';

  @override
  String get backupIncluded =>
      'Favorites, playlists, the lyrics you chose for songs, hidden folders and songs, and your settings.';

  @override
  String get backupNotIncludedTitle => 'Not backed up';

  @override
  String get backupNotIncluded =>
      'Your audio files, play history and downloaded lyrics. On a new phone, songs are found again by their title, artist, length and file name.';

  @override
  String get backupSectionStatus => 'Backup';

  @override
  String get backupLast => 'Last backup';

  @override
  String get backupNever => 'Never';

  @override
  String backupLastAt(String date, String time) {
    return '$date, $time';
  }

  @override
  String get backupNow => 'Back up now';

  @override
  String get backupAuto => 'Auto backup';

  @override
  String get backupAutoNote => 'Daily on Wi-Fi';

  @override
  String get backupErrorOffline => 'The last backup failed: no connection.';

  @override
  String get backupErrorFailed => 'The last backup failed. Try again later.';

  @override
  String get backupErrorOther =>
      'The cloud has a backup from another phone. Back up now to replace it.';

  @override
  String get backupDone => 'Backed up';

  @override
  String get backupOffline => 'No connection. Your backup wasn\'t changed.';

  @override
  String get backupFailed => 'Backup failed. Your backup wasn\'t changed.';

  @override
  String get backupReplaceTitle => 'Replace the cloud backup?';

  @override
  String backupReplaceMessage(String date) {
    return 'The backup from $date was made on another phone, or kept when you started fresh. Backing up now replaces it with this phone\'s library.';
  }

  @override
  String get backupReplace => 'Replace';

  @override
  String get restoreTitle => 'Restore';

  @override
  String get restoreLoading => 'Looking for your backup…';

  @override
  String restoreFound(String date, String favorites, String playlists) {
    return 'We found your backup from $date: $favorites, $playlists, settings.';
  }

  @override
  String restoreCountFavorites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count favorites',
      one: '1 favorite',
    );
    return '$_temp0';
  }

  @override
  String restoreCountPlaylists(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count playlists',
      one: '1 playlist',
    );
    return '$_temp0';
  }

  @override
  String get restoreMergeNote =>
      'Restoring adds them to what\'s on this phone, and replaces your settings. Nothing here is removed.';

  @override
  String get restoreAction => 'Restore';

  @override
  String get restoreStartFresh => 'Start fresh';

  @override
  String get restoreStartFreshNote =>
      'Start fresh keeps your backup in the cloud and changes nothing here.';

  @override
  String get restoreNone => 'There\'s no backup for this account yet.';

  @override
  String get restoreOffline => 'No connection. Try again when you\'re online.';

  @override
  String get restoreFailed => 'Couldn\'t restore your backup. Try again later.';

  @override
  String get restoreNewer =>
      'This backup was made by a newer version of Zema. Update the app to restore it.';

  @override
  String get restoreRetry => 'Try again';

  @override
  String get restoreWaitingForScan => 'Finding the songs on this phone…';

  @override
  String get restoreRunning => 'Restoring…';

  @override
  String get restoreDoneTitle => 'Restored';

  @override
  String restoreDoneFavorites(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count favorites added',
      one: '1 favorite added',
    );
    return '$_temp0';
  }

  @override
  String restoreDonePlaylists(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs added to playlists',
      one: '1 song added to playlists',
    );
    return '$_temp0';
  }

  @override
  String restoreDoneChoices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lyrics choices added',
      one: '1 lyrics choice added',
    );
    return '$_temp0';
  }

  @override
  String get restoreDoneSettings => 'Settings restored';

  @override
  String restoreNotFoundTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count songs aren\'t on this phone',
      one: '1 song isn\'t on this phone',
    );
    return '$_temp0';
  }

  @override
  String get restoreNotFoundNote =>
      'They\'re kept, and added as soon as they show up on this phone.';

  @override
  String get restoreDone => 'Done';

  @override
  String get backupRestore => 'Restore from backup';

  @override
  String get contributeSubtitle => 'Help everyone sing along';

  @override
  String get contributeHowTitle => 'How contributing works';

  @override
  String get contributeStepLyrics => 'Write the lyrics';

  @override
  String get contributeStepLyricsBody =>
      'Type or paste the words. Mark verses and the chorus.';

  @override
  String get contributeStepRecording => 'Link a recording';

  @override
  String get contributeStepRecordingBody =>
      'A YouTube link, a Telegram audio, or a file on your phone.';

  @override
  String get contributeStepSync => 'Sync the lines';

  @override
  String get contributeStepSyncBody =>
      'Play the song and tap when each line starts.';

  @override
  String get contributeStepReview => 'Review';

  @override
  String get contributeStepReviewBody =>
      'A moderator checks it, then everyone can sing along.';

  @override
  String get contributeAddLyrics => 'Add lyrics';

  @override
  String get contributeSignInReason =>
      'Sign in with Google to add lyrics and timings for everyone. A moderator checks each contribution before it\'s shared.';

  @override
  String get contributeNoBackend =>
      'Contributing needs the online catalog, which this version of the app doesn\'t have.';

  @override
  String get contributeDraftsTitle => 'Drafts';

  @override
  String get contributeDraftUntitled => 'Untitled';

  @override
  String contributeDraftSubtitle(String step, String time) {
    return '$step · $time';
  }

  @override
  String get contributeDraftDelete => 'Delete draft';

  @override
  String get contributeDraftDeleteTitle => 'Delete this draft?';

  @override
  String contributeDraftDeleteMessage(String title) {
    return '“$title” will be deleted from this phone.';
  }

  @override
  String get contributeDraftGone => 'This draft no longer exists.';

  @override
  String get contributeFieldTitle => 'Title';

  @override
  String get contributeFieldTransliteration =>
      'Title in Latin letters (optional)';

  @override
  String get contributeFieldArtist => 'Artist or choir';

  @override
  String get contributeFieldAlbum => 'Album (optional)';

  @override
  String get contributeTitleRequired => 'Enter the song\'s title';

  @override
  String get contributeTitleTooLong => 'Keep the title under 200 characters';

  @override
  String get contributeFieldTooLong =>
      'Keep the transliteration, artist and album under 200 characters each.';

  @override
  String get contributeSavedOnPhone => 'Saved on this phone as you type';

  @override
  String profileDraftsWarning(int count, String titles) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drafts on this phone will be deleted: $titles.',
      one: '1 draft on this phone will be deleted: $titles.',
    );
    return '$_temp0';
  }

  @override
  String contributeBlockVerse(int n) {
    return 'Verse $n';
  }

  @override
  String contributeBlockChorusN(int n) {
    return 'Chorus $n';
  }

  @override
  String get contributeBlockBridge => 'Bridge';

  @override
  String contributeBlockBridgeN(int n) {
    return 'Bridge $n';
  }

  @override
  String get contributeBlockOther => 'Other';

  @override
  String contributeBlockOtherN(int n) {
    return 'Other $n';
  }

  @override
  String get contributeBlockKind => 'Block type';

  @override
  String get contributeBlockMenu => 'Block options';

  @override
  String get contributeBlockMoveUp => 'Move up';

  @override
  String get contributeBlockMoveDown => 'Move down';

  @override
  String get contributeBlockShowLatin => 'Add Latin letters';

  @override
  String get contributeBlockHideLatin => 'Hide Latin letters';

  @override
  String get contributeBlockLatin => 'In Latin letters (optional)';

  @override
  String get contributeBlockLatinHelp =>
      'One row for each line above, in the same order.';

  @override
  String get contributeBlockDelete => 'Delete block';

  @override
  String contributeBlockDeleteTitle(String block) {
    return 'Delete $block?';
  }

  @override
  String contributeBlockDeleteMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Its lines will be deleted, and its $count places in the play order are taken out.',
      one: 'Its lines will be deleted, and it\'s taken out of the play order.',
      zero: 'Its lines will be deleted.',
    );
    return '$_temp0';
  }

  @override
  String get contributeBlockHint => 'Type the lines, one per row';

  @override
  String get contributeBlockBlankLine =>
      'Remove empty rows. To start a new part, add a block.';

  @override
  String contributeLineTooLong(int max) {
    return 'Keep each line under $max characters';
  }

  @override
  String contributeTooManyLines(int max) {
    return 'Songs can have up to $max written lines.';
  }

  @override
  String get contributeChorusHint =>
      'Write the chorus once. Then add it to the play order every time it\'s sung.';

  @override
  String get contributeAddBlock => 'Add block';

  @override
  String get contributePasteAll => 'Paste all text';

  @override
  String get contributePasteHelp =>
      'Paste the whole song. A blank line starts a new block, and a block that comes again becomes the chorus.';

  @override
  String get contributePasteReplaces => 'This replaces the blocks you have.';

  @override
  String get contributePasteSplit => 'Split into blocks';

  @override
  String contributePasted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count blocks made. Check their types and the play order.',
      one: '1 block made. Check its type and the play order.',
    );
    return '$_temp0';
  }

  @override
  String get contributePlayOrder => 'Play order';

  @override
  String get contributePlayOrderHelp => 'Tap an entry to move or remove it.';

  @override
  String contributePlayOrderEntry(int n) {
    return 'Entry $n of the play order';
  }

  @override
  String get contributePlayOrderAdd => 'Add';

  @override
  String get contributePlayOrderEarlier => 'Move earlier';

  @override
  String get contributePlayOrderLater => 'Move later';

  @override
  String get contributePlayOrderRemove => 'Remove';

  @override
  String get contributePlayOrderEmpty =>
      'Add at least one block to the play order.';

  @override
  String get contributeNextRecording => 'Next: link a recording';

  @override
  String get contributeRecordingTitle =>
      'Which recording are these lyrics for?';

  @override
  String get contributeRecordingBody =>
      'Timings belong to one performance. Pick the one you\'ll sync with.';

  @override
  String get contributeRecordingLocal => 'A song on this phone';

  @override
  String get contributeRecordingYoutube => 'A YouTube link';

  @override
  String get contributeRecordingShared => 'An audio from Telegram';

  @override
  String get contributeRecordingArtist => 'Artist or choir in this recording';

  @override
  String get contributeChooseSong => 'Choose a song';

  @override
  String get contributeChange => 'Change';

  @override
  String get contributeNoSongs => 'No songs on this phone yet.';

  @override
  String get contributeYoutubeLink => 'YouTube link';

  @override
  String get contributeYoutubeBadLink =>
      'This isn\'t a link to one video. Copy the link from the video\'s Share button.';

  @override
  String get contributeYoutubeTitle => 'Video title';

  @override
  String get contributeYoutubeOffline =>
      'Couldn\'t look up the video. Type its title, or try again online.';

  @override
  String get contributeYoutubeDuration => 'Length (optional)';

  @override
  String get contributeYoutubeBadDuration =>
      'Type the length as minutes:seconds, like 4:05';

  @override
  String get contributeYoutubeNoSync =>
      'YouTube videos can\'t be played in Zema, so they can\'t be synced. The lyrics and the link are sent without timings.';

  @override
  String get contributeSharedHow =>
      'In Telegram, open the audio\'s menu, tap Share, and choose Zema. It opens here.';

  @override
  String get contributeNextSync => 'Next: sync the lines';

  @override
  String get contributeNextReview => 'Next: review';

  @override
  String get contributeBack => 'Back';

  @override
  String get contributeSkipRecording => 'Skip, lyrics only';

  @override
  String get contributeLyricsFirst => 'Finish the lyrics first.';

  @override
  String get contributeStepLater => 'This step is coming in the next update.';

  @override
  String get contributeShareNeedsBackend =>
      'Contributing needs the online catalog, which this version of the app doesn\'t have.';

  @override
  String get contributeSyncNoAudio =>
      'This recording isn\'t on this phone any more, so it can\'t be played for syncing.';

  @override
  String get contributeSyncChooseRecording => 'Choose another recording';

  @override
  String get contributeSyncTapHint => 'Tap when this line starts';

  @override
  String get contributeSyncEarlier => '0.1 s earlier (hold to keep moving)';

  @override
  String get contributeSyncLater => '0.1 s later (hold to keep moving)';

  @override
  String get contributeSyncRedo => 'Redo from here';

  @override
  String get contributeSyncUndo => 'Undo last tap';

  @override
  String get contributeSyncSkip => 'Skip, send text only';

  @override
  String get contributeSyncTap => 'Tap — next line';

  @override
  String get contributeSyncPressPlay => 'Play to start';

  @override
  String get contributeSyncBack5 => '−5 s';

  @override
  String get contributeSyncSpeedNormal => '1×';

  @override
  String get contributeSyncSpeedSlow => '0.75×';

  @override
  String get contributeSyncList => 'List';

  @override
  String get contributeSyncFocus => 'Focus';

  @override
  String get contributeSyncPreview => 'Preview';

  @override
  String get contributeSyncEndPreview => 'Back to syncing';

  @override
  String get contributeSyncHearIt => 'Tap when you hear it';

  @override
  String contributeSyncTimedAt(String time) {
    return '✓ $time';
  }

  @override
  String get contributeSyncAllTimed =>
      'Every line has a time. Check it with Preview.';

  @override
  String get contributeSyncMore => 'More';

  @override
  String get contributeReviewIntro =>
      'Check everything, then send it. A moderator checks it before everyone can see it.';

  @override
  String get contributeReviewSong => 'Song';

  @override
  String get contributeReviewLyrics => 'Lyrics';

  @override
  String get contributeReviewRecording => 'Recording';

  @override
  String get contributeReviewSync => 'Timings';

  @override
  String get contributeReviewEdit => 'Edit';

  @override
  String get contributeReviewEditSong => 'Edit song details';

  @override
  String get contributeReviewEditLyrics => 'Edit lyrics';

  @override
  String get contributeReviewEditRecording => 'Edit recording';

  @override
  String get contributeReviewEditSync => 'Edit timings';

  @override
  String get contributeReviewNoRecording =>
      'No recording. The lyrics are sent on their own.';

  @override
  String get contributeReviewYoutubeVideo => 'YouTube video';

  @override
  String get contributeReviewSynced => 'Synced';

  @override
  String get contributeReviewTextOnly => 'Text only';

  @override
  String get contributeReviewYoutube => 'YouTube — not synced';

  @override
  String get contributeSubmit => 'Submit for review';

  @override
  String get contributeSubmitSending => 'Sending';

  @override
  String get contributeSubmitSent =>
      'Sent for review. Its lyrics show on this phone now, and for everyone once a moderator approves them.';

  @override
  String get contributeSubmitOffline =>
      'You\'re offline, so it wasn\'t sent. Your draft is kept. Try again when you\'re online.';

  @override
  String get contributeSubmitFailed =>
      'The server had a problem, so it wasn\'t sent. Your draft is kept. Try again.';

  @override
  String get contributeSubmitSignIn =>
      'You\'re signed out, so it wasn\'t sent. Sign in again, then send it. Your draft is kept.';

  @override
  String contributeSubmitTooManyOpen(int max) {
    return 'You already have $max contributions waiting for review, the most allowed. Send this one once some are reviewed. Your draft is kept.';
  }

  @override
  String contributeSubmitTooManyToday(int max) {
    return 'You can send up to $max contributions a day. Your draft is kept. Send it tomorrow.';
  }

  @override
  String get contributeSubmitFixLyrics =>
      'Something in the lyrics isn\'t right. Check them, then send again.';

  @override
  String get contributeSubmitFixRecording =>
      'Something about the recording isn\'t right. Check it, then send again.';

  @override
  String get contributeSubmitFixSync =>
      'The timings don\'t fit the lyrics or the recording. Sync again, then send.';

  @override
  String get contributeSubmitRefused =>
      'The server didn\'t accept it. Your draft is kept. Check each step and try again.';

  @override
  String get lyricsPendingReview => 'Pending review';
}
