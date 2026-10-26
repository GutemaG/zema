// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Oromo (`om`).
class AppLocalizationsOm extends AppLocalizations {
  AppLocalizationsOm([String locale = 'om']) : super(locale);

  @override
  String get appTitle => 'Zema';

  @override
  String get navHome => 'Fuula Duraa';

  @override
  String get navSearch => 'Barbaadi';

  @override
  String get navLibrary => 'Kuusaa';

  @override
  String get navContribute => 'Gumaachi';

  @override
  String get homeSettingsTooltip => 'Settings';

  @override
  String get comingSoonTitle => 'Dhiyootti ni dhufa';

  @override
  String get homeComingSoonMessage =>
      'Your recent songs and songs playing in other apps will show up here.';

  @override
  String get searchComingSoonMessage =>
      'Search mezmur by title, artist or a line of the lyrics.';

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
  String get libraryTabComingSoon =>
      'This part of your library is coming soon.';

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
  String get settingsTitle => 'Qindaa\'ina';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsLanguage => 'Afaan';

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
}
