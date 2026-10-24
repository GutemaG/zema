// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tigrinya (`ti`).
class AppLocalizationsTi extends AppLocalizations {
  AppLocalizationsTi([String locale = 'ti']) : super(locale);

  @override
  String get appTitle => 'ዜማ';

  @override
  String get navHome => 'መበገሲ';

  @override
  String get navSearch => 'ድለ';

  @override
  String get navLibrary => 'ቤተ-መዛግብቲ';

  @override
  String get navContribute => 'ኣበርክቶ';

  @override
  String get homeSettingsTooltip => 'Settings';

  @override
  String get comingSoonTitle => 'ብቐረባ ክመጽእ እዩ';

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
  String get settingsTitle => 'ቅጥዕታት';

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
}
