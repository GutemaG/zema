// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appTitle => 'ዜማ';

  @override
  String get navHome => 'ዋና ገጽ';

  @override
  String get navSearch => 'ፍለጋ';

  @override
  String get navLibrary => 'ቤተ መዛግብት';

  @override
  String get navContribute => 'አስተዋጽኦ';

  @override
  String get homeSettingsTooltip => 'Settings';

  @override
  String get comingSoonTitle => 'በቅርቡ ይመጣል';

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
  String get settingsTitle => 'ቅንብሮች';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsLanguage => 'ቋንቋ';

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
}
