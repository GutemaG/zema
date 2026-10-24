import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';
import 'app_localizations_om.dart';
import 'app_localizations_ti.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en'),
    Locale('om'),
    Locale('ti'),
  ];

  /// App name, shown in the Home header and the window title.
  ///
  /// In en, this message translates to:
  /// **'Zema'**
  String get appTitle;

  /// Bottom navigation label for the Home tab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation label for the Search tab.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// Bottom navigation label for the Library tab (the user's local music).
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// Bottom navigation label for the Contribute tab (add lyrics and timings).
  ///
  /// In en, this message translates to:
  /// **'Contribute'**
  String get navContribute;

  /// Tooltip and screen-reader label of the gear button in the Home header.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettingsTooltip;

  /// Title on screens that are not built yet.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoonTitle;

  /// Message on the Home tab before it is built.
  ///
  /// In en, this message translates to:
  /// **'Your recent songs and songs playing in other apps will show up here.'**
  String get homeComingSoonMessage;

  /// Message on the Search tab before it is built.
  ///
  /// In en, this message translates to:
  /// **'Search mezmur by title, artist or a line of the lyrics.'**
  String get searchComingSoonMessage;

  /// Message on the Contribute tab before it is built.
  ///
  /// In en, this message translates to:
  /// **'Add lyrics and sync timings to help other listeners.'**
  String get contributeComingSoonMessage;

  /// Heading of the explanation shown before asking for access to audio files.
  ///
  /// In en, this message translates to:
  /// **'Play the music on your phone'**
  String get libraryAccessTitle;

  /// Explanation shown before the system asks for access to audio files.
  ///
  /// In en, this message translates to:
  /// **'Zema needs access to your audio files to list and play them. It reads audio files only, nothing else.'**
  String get libraryAccessMessage;

  /// Button that shows the system dialog for access to audio files.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get libraryAccessAllow;

  /// Button that skips giving access to audio files for now.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get libraryAccessNotNow;

  /// Heading when the app has no access to audio files.
  ///
  /// In en, this message translates to:
  /// **'Music access is off'**
  String get libraryAccessDeniedTitle;

  /// Message when the app has no access to audio files.
  ///
  /// In en, this message translates to:
  /// **'Allow access to your audio files to see and play your music.'**
  String get libraryAccessDeniedMessage;

  /// Button that asks again for access to audio files.
  ///
  /// In en, this message translates to:
  /// **'Grant access'**
  String get libraryAccessGrant;

  /// Message when access to audio files can only be given in the phone's settings.
  ///
  /// In en, this message translates to:
  /// **'Turn on music and audio access for Zema in your phone\'s settings.'**
  String get libraryAccessSettingsMessage;

  /// Button that opens Zema's page in the phone's settings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get libraryAccessOpenSettings;

  /// Heading on iPhone, where the music library is not supported yet.
  ///
  /// In en, this message translates to:
  /// **'Not available on iOS yet'**
  String get libraryUnsupportedTitle;

  /// Message on iPhone, where the music library is not supported yet.
  ///
  /// In en, this message translates to:
  /// **'Playing the music on your phone will come to iPhone in a later version.'**
  String get libraryUnsupportedMessage;

  /// Shown while the first scan of the phone's audio files runs.
  ///
  /// In en, this message translates to:
  /// **'Looking for music on your phone…'**
  String get libraryScanning;

  /// Heading when scanning the phone's audio files failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read your music'**
  String get libraryScanFailedTitle;

  /// Message when scanning the phone's audio files failed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while reading your audio files.'**
  String get libraryScanFailedMessage;

  /// Snackbar when a rescan failed but the stored library is still shown.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update your library'**
  String get libraryScanFailedSnack;

  /// Heading when the phone has no audio files to show.
  ///
  /// In en, this message translates to:
  /// **'No music found'**
  String get libraryEmptyTitle;

  /// Message when the phone has no audio files to show.
  ///
  /// In en, this message translates to:
  /// **'Songs saved on your phone appear here.'**
  String get libraryEmptyMessage;

  /// Shown when a song has no artist tag.
  ///
  /// In en, this message translates to:
  /// **'Unknown artist'**
  String get unknownArtist;

  /// Shown when a song has no album tag.
  ///
  /// In en, this message translates to:
  /// **'Unknown album'**
  String get unknownAlbum;

  /// Button that retries something that failed.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionTryAgain;

  /// Number of songs in the library.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}}'**
  String librarySongCount(int count);

  /// Library top tab with all songs.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get libraryTabTracks;

  /// Library top tab with songs by folder.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get libraryTabFolders;

  /// Library top tab with albums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get libraryTabAlbums;

  /// Library top tab with artists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get libraryTabArtists;

  /// Library top tab with favorite songs.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get libraryTabFavorites;

  /// Library top tab with playlists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get libraryTabPlaylists;

  /// Message on a Library top tab that is not built yet.
  ///
  /// In en, this message translates to:
  /// **'This part of your library is coming soon.'**
  String get libraryTabComingSoon;

  /// Hint in the search field above the song list.
  ///
  /// In en, this message translates to:
  /// **'Search songs, artists, albums'**
  String get librarySearchHint;

  /// Button that clears the search field.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get libraryClearSearch;

  /// Heading when no song matches the search.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get libraryNoResultsTitle;

  /// Message when no song matches the search.
  ///
  /// In en, this message translates to:
  /// **'Try a different word or check the spelling.'**
  String get libraryNoResultsMessage;

  /// Button that opens the sort options for the song list.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get librarySortTooltip;

  /// Sort the song list by title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get sortTitle;

  /// Sort the song list by artist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get sortArtist;

  /// Sort the song list by album.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get sortAlbum;

  /// Sort the song list by when the file was added.
  ///
  /// In en, this message translates to:
  /// **'Date added'**
  String get sortDateAdded;

  /// Sort the song list by length.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sortDuration;

  /// Sort from A to Z, oldest or shortest first.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get sortAscending;

  /// Sort from Z to A, newest or longest first.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get sortDescending;

  /// Button that plays a list of songs in order.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get actionPlay;

  /// Button that plays a list of songs in random order.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get actionShuffle;

  /// Player button that starts playback.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playerPlay;

  /// Player button that pauses playback.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get playerPause;

  /// Player button that skips to the next song.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get playerNext;

  /// Player button that goes to the previous song or restarts this one.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get playerPrevious;

  /// Player shuffle button when shuffle is on.
  ///
  /// In en, this message translates to:
  /// **'Shuffle on'**
  String get playerShuffleOn;

  /// Player shuffle button when shuffle is off.
  ///
  /// In en, this message translates to:
  /// **'Shuffle off'**
  String get playerShuffleOff;

  /// Player repeat button when repeat is off.
  ///
  /// In en, this message translates to:
  /// **'Repeat off'**
  String get playerRepeatOff;

  /// Player repeat button when the whole queue repeats.
  ///
  /// In en, this message translates to:
  /// **'Repeat all'**
  String get playerRepeatAll;

  /// Player repeat button when the current song repeats.
  ///
  /// In en, this message translates to:
  /// **'Repeat one'**
  String get playerRepeatOne;

  /// Button that closes the Now Playing screen.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get playerClose;

  /// Title of the Now Playing screen, for screen readers.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get playerNowPlaying;

  /// Screen-reader hint on the mini player.
  ///
  /// In en, this message translates to:
  /// **'Open Now Playing'**
  String get playerOpen;

  /// Screen-reader label of the seek bar.
  ///
  /// In en, this message translates to:
  /// **'Song position'**
  String get playerSeek;

  /// Shown on Now Playing where lyrics will appear in a later version.
  ///
  /// In en, this message translates to:
  /// **'No lyrics yet'**
  String get playerNoLyrics;

  /// Name of the Android notification channel for music playback.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get playbackChannelName;

  /// Snackbar when a song file can't be played and is skipped.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t play {title}'**
  String playerUnplayable(String title);

  /// Screen-reader label of the mini player: song title and artist.
  ///
  /// In en, this message translates to:
  /// **'{title}, {artist}'**
  String playerMiniLabel(String title, String artist);

  /// Screen-reader value of the seek bar, e.g. "1:05 of 3:40".
  ///
  /// In en, this message translates to:
  /// **'{position} of {duration}'**
  String playerTrackPosition(String position, String duration);

  /// Title of the Settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section heading for language and theme.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsSectionGeneral;

  /// Settings section heading for version and licenses.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// Settings row and picker title for the app's UI language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Settings row and sheet title for light/dark mode and color palette.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Theme option: follow the phone's light/dark setting.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// Theme option: always light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// Theme option: always dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// Name of the default color palette (gold on near-black, or on parchment in light mode).
  ///
  /// In en, this message translates to:
  /// **'Night Vigil'**
  String get paletteNightVigil;

  /// Short name of the "Night Vigil · Wine" palette (gold on deep wine).
  ///
  /// In en, this message translates to:
  /// **'Wine'**
  String get paletteWine;

  /// Settings row showing the installed app version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// Settings row that opens the list of open-source licenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get settingsLicenses;

  /// Title when the app is asked to open a screen that does not exist.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get errorNotFoundTitle;

  /// Message when the app is asked to open a screen that does not exist.
  ///
  /// In en, this message translates to:
  /// **'This page doesn\'t exist. Go back to Home to continue.'**
  String get errorNotFoundMessage;

  /// Button that returns to the Home tab.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get actionGoHome;

  /// Button that closes a sheet after making changes.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'en', 'om', 'ti'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'en':
      return AppLocalizationsEn();
    case 'om':
      return AppLocalizationsOm();
    case 'ti':
      return AppLocalizationsTi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
