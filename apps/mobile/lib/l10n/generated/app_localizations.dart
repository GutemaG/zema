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

  /// Tooltip and screen-reader label of the search button in the Home header; opens the Search tab.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get homeSearchTooltip;

  /// Home quick action that plays every song in the library in random order.
  ///
  /// In en, this message translates to:
  /// **'Shuffle all'**
  String get homeShuffleAll;

  /// Home section heading above the song that was playing when the app was last closed.
  ///
  /// In en, this message translates to:
  /// **'Continue listening'**
  String get homeContinueListening;

  /// Under the song in Continue listening: where playback will continue.
  ///
  /// In en, this message translates to:
  /// **'Resume from {position}'**
  String homeResumeFrom(String position);

  /// Screen-reader label of the play button in Continue listening.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get homeResume;

  /// Home section heading above a row of recently played songs.
  ///
  /// In en, this message translates to:
  /// **'Recently played'**
  String get homeRecentlyPlayed;

  /// Home section heading above a row of the user's playlists.
  ///
  /// In en, this message translates to:
  /// **'Your playlists'**
  String get homeYourPlaylists;

  /// Button next to a Home section heading that opens the full list.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// Search filter chip: show songs, artists and albums together.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get searchScopeAll;

  /// Search filter chip and results heading for songs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get searchScopeSongs;

  /// Search filter chip and results heading for artists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get searchScopeArtists;

  /// Search filter chip and results heading for albums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get searchScopeAlbums;

  /// Button next to a search results heading that shows every result of that kind.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get searchSeeAll;

  /// Heading above the user's recent searches when the search field is empty.
  ///
  /// In en, this message translates to:
  /// **'Recent searches'**
  String get searchRecentHeading;

  /// Button that removes every recent search.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get searchClearRecent;

  /// Screen-reader label of the button that removes one recent search.
  ///
  /// In en, this message translates to:
  /// **'Remove {query}'**
  String searchRemoveRecent(String query);

  /// Title shown on the Search tab before anything is typed, when there are no recent searches.
  ///
  /// In en, this message translates to:
  /// **'Find a song'**
  String get searchHintTitle;

  /// Message under the search hint title; the example shows Latin letters finding an Amharic title. Keep both example words as they are.
  ///
  /// In en, this message translates to:
  /// **'Search by title, artist or album. Any keyboard works: “kidist” finds “ቅድስት”.'**
  String get searchHintMessage;

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

  /// Shown on Now Playing when the song has no linked lyrics.
  ///
  /// In en, this message translates to:
  /// **'No lyrics for this song'**
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

  /// Snackbar button that reverses the change just made.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// Dialog button that closes without saving.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Dialog button that saves the entered value.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Title of the sheet listing the songs that will play, and the Now Playing button that opens it.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queueTitle;

  /// Number of songs after the current one in the queue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing up next} =1{1 song up next} other{{count} songs up next}}'**
  String queueUpNext(int count);

  /// Button that removes every song after the current one from the queue.
  ///
  /// In en, this message translates to:
  /// **'Clear queue'**
  String get queueClear;

  /// Snackbar after swiping a song out of the queue.
  ///
  /// In en, this message translates to:
  /// **'Removed \"{title}\" from the queue'**
  String queueRemoved(String title);

  /// Screen-reader action that removes a song from the queue.
  ///
  /// In en, this message translates to:
  /// **'Remove from queue'**
  String get queueRemove;

  /// Label of the handle used to move a song within the queue.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get queueReorder;

  /// Title of the sleep timer sheet, and the Now Playing button that opens it.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTitle;

  /// Sleep timer option: stop playback after this many minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String sleepMinutes(int minutes);

  /// Sleep timer option: stop playback when the song playing now ends.
  ///
  /// In en, this message translates to:
  /// **'End of current song'**
  String get sleepEndOfSong;

  /// Short label on Now Playing when the sleep timer stops at the end of the song.
  ///
  /// In en, this message translates to:
  /// **'End of song'**
  String get sleepEndOfSongShort;

  /// Sleep timer option that asks for a number of minutes.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get sleepCustom;

  /// Title of the dialog asking for a number of minutes.
  ///
  /// In en, this message translates to:
  /// **'Custom sleep timer'**
  String get sleepCustomTitle;

  /// Label of the field for the number of minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get sleepCustomLabel;

  /// Allowed range for a custom sleep timer; shown as help, and as an error when the value is outside it.
  ///
  /// In en, this message translates to:
  /// **'Enter {min} to {max} minutes'**
  String sleepCustomRange(int min, int max);

  /// Time left before the sleep timer stops playback, e.g. "Stops in 12:30".
  ///
  /// In en, this message translates to:
  /// **'Stops in {time}'**
  String sleepStopsIn(String time);

  /// Shown when the sleep timer is set to stop at the end of the current song.
  ///
  /// In en, this message translates to:
  /// **'Stops at the end of this song'**
  String get sleepStopsAtEndOfSong;

  /// Button that turns off the running sleep timer.
  ///
  /// In en, this message translates to:
  /// **'Cancel timer'**
  String get sleepCancel;

  /// Name shown for the phone's internal storage in folder paths.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get folderPhone;

  /// Name shown for a memory card in folder paths.
  ///
  /// In en, this message translates to:
  /// **'SD card'**
  String get folderSdCard;

  /// Folder menu item that hides the folder's songs from the whole library.
  ///
  /// In en, this message translates to:
  /// **'Hide folder'**
  String get folderHide;

  /// Label of the folder's menu button.
  ///
  /// In en, this message translates to:
  /// **'More options for {name}'**
  String folderMenu(String name);

  /// Snackbar after hiding a folder.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" hidden'**
  String folderHidden(String name);

  /// Title when no folder holds any music.
  ///
  /// In en, this message translates to:
  /// **'No folders'**
  String get foldersEmptyTitle;

  /// Message when no folder holds any music.
  ///
  /// In en, this message translates to:
  /// **'Folders with music on your phone will show here.'**
  String get foldersEmptyMessage;

  /// Title when an opened folder has no music any more (hidden or emptied).
  ///
  /// In en, this message translates to:
  /// **'Folder not found'**
  String get folderGoneTitle;

  /// Message when an opened folder has no music any more.
  ///
  /// In en, this message translates to:
  /// **'This folder has no music now. It may have been hidden or emptied.'**
  String get folderGoneMessage;

  /// Number of albums.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 album} other{{count} albums}}'**
  String albumCount(int count);

  /// Artist shown for an album whose songs are by different artists.
  ///
  /// In en, this message translates to:
  /// **'Various artists'**
  String get variousArtists;

  /// Albums sort option: by album name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortAlbumName;

  /// Albums sort option: by release year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get sortYear;

  /// Title when the library has no albums.
  ///
  /// In en, this message translates to:
  /// **'No albums'**
  String get albumsEmptyTitle;

  /// Message when the library has no albums.
  ///
  /// In en, this message translates to:
  /// **'Albums from your music files will show here.'**
  String get albumsEmptyMessage;

  /// Title when an opened album is no longer in the library.
  ///
  /// In en, this message translates to:
  /// **'Album not found'**
  String get albumGoneTitle;

  /// Message when an opened album is no longer in the library.
  ///
  /// In en, this message translates to:
  /// **'This album is no longer in your library.'**
  String get albumGoneMessage;

  /// Total length under an hour, e.g. "48 min".
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// Total length of an hour or more, e.g. "1 h 12 min".
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHoursMinutes(int hours, int minutes);

  /// Number of artists.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 artist} other{{count} artists}}'**
  String artistCount(int count);

  /// Section title on an artist's page listing their albums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get artistAlbums;

  /// Section title on an artist's page listing their songs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get artistSongs;

  /// Title when the library has no artists.
  ///
  /// In en, this message translates to:
  /// **'No artists'**
  String get artistsEmptyTitle;

  /// Message when the library has no artists.
  ///
  /// In en, this message translates to:
  /// **'Singers from your music files will show here.'**
  String get artistsEmptyMessage;

  /// Title when an opened artist is no longer in the library.
  ///
  /// In en, this message translates to:
  /// **'Artist not found'**
  String get artistGoneTitle;

  /// Message when an opened artist is no longer in the library.
  ///
  /// In en, this message translates to:
  /// **'This artist is no longer in your library.'**
  String get artistGoneMessage;

  /// Button that creates something new, e.g. a playlist.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// Button that confirms deleting something.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// Label of the button that opens a song's menu.
  ///
  /// In en, this message translates to:
  /// **'More options for {title}'**
  String songMenu(String title);

  /// Song menu: play this song after the current one.
  ///
  /// In en, this message translates to:
  /// **'Play next'**
  String get songPlayNext;

  /// Snackbar after choosing Play next.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will play next'**
  String songPlayingNext(String title);

  /// Song menu: add this song to the end of the queue.
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get songAddToQueue;

  /// Snackbar after choosing Add to queue.
  ///
  /// In en, this message translates to:
  /// **'Added \"{title}\" to the queue'**
  String songAddedToQueue(String title);

  /// Song menu item, Now Playing button and title of the sheet listing playlists.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get songAddToPlaylist;

  /// Song menu item and heart button label when the song is not a favorite.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get songFavorite;

  /// Song menu item and heart button label when the song is a favorite; also the screen-reader action on Favorites rows.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get songUnfavorite;

  /// Snackbar after favoriting a song from its menu.
  ///
  /// In en, this message translates to:
  /// **'Added \"{title}\" to favorites'**
  String songFavorited(String title);

  /// Snackbar after unfavoriting a song.
  ///
  /// In en, this message translates to:
  /// **'Removed \"{title}\" from favorites'**
  String songUnfavorited(String title);

  /// Song menu item, and title of the sheet, for choosing which song's lyrics this audio file shows.
  ///
  /// In en, this message translates to:
  /// **'Match lyrics'**
  String get songMatchLyrics;

  /// Song menu item for a file that already shows lyrics: choose different lyrics.
  ///
  /// In en, this message translates to:
  /// **'Change lyrics'**
  String get songChangeLyrics;

  /// Song menu item: stop showing lyrics for this file (Zema won't link it again by itself).
  ///
  /// In en, this message translates to:
  /// **'Unlink lyrics'**
  String get songUnlinkLyrics;

  /// Snackbar after choosing lyrics for a file.
  ///
  /// In en, this message translates to:
  /// **'Showing the lyrics of {title}'**
  String songLyricsLinked(String title);

  /// Snackbar after unlinking a file's lyrics.
  ///
  /// In en, this message translates to:
  /// **'No lyrics for {title}'**
  String songLyricsUnlinked(String title);

  /// Song menu: open the song's album.
  ///
  /// In en, this message translates to:
  /// **'Go to album'**
  String get songGoToAlbum;

  /// Song menu: open the song's artist.
  ///
  /// In en, this message translates to:
  /// **'Go to artist'**
  String get songGoToArtist;

  /// Song menu: hide this song from the whole library.
  ///
  /// In en, this message translates to:
  /// **'Hide song'**
  String get songHide;

  /// Snackbar after hiding a song, with Undo.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" is hidden'**
  String songHidden(String title);

  /// Song menu: send the audio file to another app.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get songShare;

  /// Snackbar when the share sheet could not be opened.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open sharing for this song'**
  String get songShareFailed;

  /// Title when there are no favorite songs.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get favoritesEmptyTitle;

  /// Explains how to add a favorite.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on Now Playing, or choose \"Add to favorites\" in a song\'s menu.'**
  String get favoritesEmptyMessage;

  /// C04 row that creates a playlist, and the title of the create dialog.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get playlistNew;

  /// Card at the top of the Playlists tab.
  ///
  /// In en, this message translates to:
  /// **'Create playlist'**
  String get playlistCreate;

  /// Second line of the Create playlist card.
  ///
  /// In en, this message translates to:
  /// **'Keep songs for a feast day or a service together'**
  String get playlistCreateHint;

  /// Playlist menu item and the title of the rename dialog.
  ///
  /// In en, this message translates to:
  /// **'Rename playlist'**
  String get playlistRename;

  /// Label of the playlist name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get playlistName;

  /// Label of the playlist description field.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get playlistDescription;

  /// Error when the playlist name is empty or only spaces.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get playlistNameRequired;

  /// Error when another playlist has the same name, ignoring letter case.
  ///
  /// In en, this message translates to:
  /// **'You already have a playlist with this name'**
  String get playlistNameTaken;

  /// Label of the playlist page's menu button.
  ///
  /// In en, this message translates to:
  /// **'More options for {name}'**
  String playlistMenu(String name);

  /// Playlist menu item.
  ///
  /// In en, this message translates to:
  /// **'Delete playlist'**
  String get playlistDelete;

  /// Title of the confirmation before deleting a playlist.
  ///
  /// In en, this message translates to:
  /// **'Delete playlist?'**
  String get playlistDeleteTitle;

  /// Confirmation before deleting a playlist.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be deleted. The songs stay on your phone.'**
  String playlistDeleteMessage(String name);

  /// Title when an opened playlist no longer exists.
  ///
  /// In en, this message translates to:
  /// **'Playlist not found'**
  String get playlistGoneTitle;

  /// Message when an opened playlist no longer exists.
  ///
  /// In en, this message translates to:
  /// **'This playlist was deleted.'**
  String get playlistGoneMessage;

  /// Button on a playlist page and title of the song picker.
  ///
  /// In en, this message translates to:
  /// **'Add songs'**
  String get playlistAddSongs;

  /// Title on an empty playlist.
  ///
  /// In en, this message translates to:
  /// **'No songs yet'**
  String get playlistEmptyTitle;

  /// Message on an empty playlist.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add songs\" to pick songs from your library.'**
  String get playlistEmptyMessage;

  /// Screen-reader action on a playlist's song rows.
  ///
  /// In en, this message translates to:
  /// **'Remove from playlist'**
  String get playlistRemove;

  /// Snackbar after swiping a song out of a playlist.
  ///
  /// In en, this message translates to:
  /// **'Removed \"{title}\" from the playlist'**
  String playlistRemoved(String title);

  /// Button at the bottom of the song picker.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Add songs} =1{Add 1 song} other{Add {count} songs}}'**
  String playlistAddCount(int count);

  /// Screen-reader value for a picker row whose song is already in the playlist.
  ///
  /// In en, this message translates to:
  /// **'Already in the playlist'**
  String get playlistInPlaylist;

  /// Title of the selection bar in Tracks.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectionCount(int count);

  /// Tooltip of the close button on the selection bar.
  ///
  /// In en, this message translates to:
  /// **'End selection'**
  String get selectionClose;

  /// Selection bar button that selects every song in the (filtered) list.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectionSelectAll;

  /// Title of the playlist sheet opened from the selection bar.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 song to a playlist} other{Add {count} songs to a playlist}}'**
  String selectionAddToPlaylistTitle(int count);

  /// Snackbar after adding selected songs to a playlist; songs already there are skipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{All already in {name}} =1{Added 1 song to {name}} other{Added {count} songs to {name}}}'**
  String selectionAddedToPlaylist(int count, String name);

  /// Snackbar after queueing the selected songs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 song to the queue} other{Added {count} songs to the queue}}'**
  String selectionAddedToQueue(int count);

  /// Snackbar after favoriting the selected songs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 song to favorites} other{Added {count} songs to favorites}}'**
  String selectionFavorited(int count);

  /// Snackbar after unfavoriting the selected songs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Removed 1 song from favorites} other{Removed {count} songs from favorites}}'**
  String selectionUnfavorited(int count);

  /// Snackbar after hiding the selected songs, with Undo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song hidden} other{{count} songs hidden}}'**
  String selectionHidden(int count);

  /// Heading above the read-only playlists Zema keeps by itself.
  ///
  /// In en, this message translates to:
  /// **'Auto playlists'**
  String get autoPlaylistsHeading;

  /// Auto playlist: songs added in the last 30 days.
  ///
  /// In en, this message translates to:
  /// **'Recently added'**
  String get autoRecentlyAdded;

  /// Auto playlist: the 50 songs played most.
  ///
  /// In en, this message translates to:
  /// **'Most played'**
  String get autoMostPlayed;

  /// Auto playlist: the last 50 songs played.
  ///
  /// In en, this message translates to:
  /// **'Recently played'**
  String get autoRecentlyPlayed;

  /// Empty Recently added playlist, title.
  ///
  /// In en, this message translates to:
  /// **'Nothing new'**
  String get autoRecentlyAddedEmptyTitle;

  /// Empty Recently added playlist, message.
  ///
  /// In en, this message translates to:
  /// **'Songs added to your phone in the last 30 days show up here.'**
  String get autoRecentlyAddedEmptyMessage;

  /// Empty Most played or Recently played playlist, title.
  ///
  /// In en, this message translates to:
  /// **'Nothing played yet'**
  String get autoPlayedEmptyTitle;

  /// Empty Most played playlist, message.
  ///
  /// In en, this message translates to:
  /// **'The songs you play most show up here.'**
  String get autoMostPlayedEmptyMessage;

  /// Empty Recently played playlist, message.
  ///
  /// In en, this message translates to:
  /// **'The songs you play show up here, latest first.'**
  String get autoRecentlyPlayedEmptyMessage;

  /// Settings section heading for hidden items, rescan and minimum duration.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get settingsSectionLibrary;

  /// Settings row and page title listing hidden folders.
  ///
  /// In en, this message translates to:
  /// **'Hidden folders'**
  String get settingsHiddenFolders;

  /// Settings row and page title listing hidden songs.
  ///
  /// In en, this message translates to:
  /// **'Hidden songs'**
  String get settingsHiddenSongs;

  /// Settings row that scans the phone for audio again.
  ///
  /// In en, this message translates to:
  /// **'Rescan library'**
  String get settingsRescan;

  /// Value of the Rescan row while a scan runs.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get settingsRescanning;

  /// Snackbar after a rescan: how many songs the library now shows.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Found 1 song} other{Found {count} songs}}'**
  String settingsRescanDone(int count);

  /// Settings row and dialog title for the minimum song length (hides voice notes).
  ///
  /// In en, this message translates to:
  /// **'Ignore audio shorter than'**
  String get settingsMinDuration;

  /// Setting value: turned off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsOff;

  /// A number of seconds, e.g. 30 s.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String settingsSeconds(int seconds);

  /// Button that brings a hidden folder or song back.
  ///
  /// In en, this message translates to:
  /// **'Unhide'**
  String get actionUnhide;

  /// Hidden folders page when empty, title.
  ///
  /// In en, this message translates to:
  /// **'No hidden folders'**
  String get hiddenFoldersEmptyTitle;

  /// Hidden folders page when empty, message.
  ///
  /// In en, this message translates to:
  /// **'Hide a folder from its menu in Library → Folders.'**
  String get hiddenFoldersEmptyMessage;

  /// Hidden songs page when empty, title.
  ///
  /// In en, this message translates to:
  /// **'No hidden songs'**
  String get hiddenSongsEmptyTitle;

  /// Hidden songs page when empty, message.
  ///
  /// In en, this message translates to:
  /// **'Hide a song from its menu.'**
  String get hiddenSongsEmptyMessage;

  /// Settings section heading for playback options.
  ///
  /// In en, this message translates to:
  /// **'Playback'**
  String get settingsSectionPlayback;

  /// Settings row: the option preselected in the sleep timer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer default'**
  String get settingsSleepDefault;

  /// Setting value: nothing chosen.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get settingsNone;

  /// Settings switch.
  ///
  /// In en, this message translates to:
  /// **'Pause when headphones are unplugged'**
  String get settingsPauseOnUnplug;

  /// Settings row and dialog title: what happens on navigation prompts, notification sounds and similar.
  ///
  /// In en, this message translates to:
  /// **'When another app plays sound'**
  String get settingsInterruptions;

  /// Interruption option: pause playback.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get settingsInterruptionsPause;

  /// Interruption option: keep playing more quietly.
  ///
  /// In en, this message translates to:
  /// **'Lower volume'**
  String get settingsInterruptionsDuck;

  /// Note under the interruption options.
  ///
  /// In en, this message translates to:
  /// **'Calls always pause.'**
  String get settingsInterruptionsNote;

  /// Settings switch: start the next song without a pause.
  ///
  /// In en, this message translates to:
  /// **'Gapless playback'**
  String get settingsGapless;

  /// Now Playing button: switch the artwork to the lyrics.
  ///
  /// In en, this message translates to:
  /// **'Show lyrics'**
  String get playerShowLyrics;

  /// Now Playing button: switch the lyrics back to the artwork.
  ///
  /// In en, this message translates to:
  /// **'Show artwork'**
  String get playerShowArtwork;

  /// Small label above the first line of each chorus in the lyrics.
  ///
  /// In en, this message translates to:
  /// **'Chorus'**
  String get lyricsChorus;

  /// Button and sheet title for how lyrics show.
  ///
  /// In en, this message translates to:
  /// **'Lyrics options'**
  String get lyricsOptions;

  /// Switch: show each lyric line in Latin letters below it.
  ///
  /// In en, this message translates to:
  /// **'Show transliteration'**
  String get lyricsShowTransliteration;

  /// Lyrics options row for the size of the lyrics text.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get lyricsTextSize;

  /// Button: make the lyrics text smaller.
  ///
  /// In en, this message translates to:
  /// **'Smaller text'**
  String get lyricsTextSmaller;

  /// Button: make the lyrics text larger.
  ///
  /// In en, this message translates to:
  /// **'Larger text'**
  String get lyricsTextLarger;

  /// Lyrics options row: move the highlight earlier or later to match the audio.
  ///
  /// In en, this message translates to:
  /// **'Sync timing'**
  String get lyricsSyncOffset;

  /// Button: lyrics highlight half a second earlier.
  ///
  /// In en, this message translates to:
  /// **'Show lines earlier'**
  String get lyricsOffsetEarlier;

  /// Button: lyrics highlight half a second later.
  ///
  /// In en, this message translates to:
  /// **'Show lines later'**
  String get lyricsOffsetLater;

  /// Button: set the lyrics timing correction back to zero.
  ///
  /// In en, this message translates to:
  /// **'Reset timing'**
  String get lyricsOffsetReset;

  /// Song menu item: open the song's page with its full lyrics.
  ///
  /// In en, this message translates to:
  /// **'View lyrics'**
  String get songViewLyrics;

  /// Search chip and group heading: songs found by a line of their lyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get searchScopeLyrics;

  /// Song page tab with the full lyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get songDetailLyricsTab;

  /// Song page tab with album, artist and source.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get songDetailInfoTab;

  /// Song page: no audio file on the phone is linked to these lyrics, so it can't be played.
  ///
  /// In en, this message translates to:
  /// **'Not on this phone'**
  String get songDetailNotOnPhone;

  /// Song page info row label.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get songDetailAlbum;

  /// Song page info row label.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get songDetailArtist;

  /// Song page info row label: where the lyrics and recording come from.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get songDetailSource;

  /// Source of lyrics shipped with the app for testing.
  ///
  /// In en, this message translates to:
  /// **'Bundled sample'**
  String get songSourceBundled;

  /// Source of lyrics that came from a file on the phone.
  ///
  /// In en, this message translates to:
  /// **'Your phone'**
  String get songSourceLocal;

  /// Name of a verse section, used in repeat markers.
  ///
  /// In en, this message translates to:
  /// **'Verse'**
  String get lyricsVerse;

  /// Marker on the song page where a section is sung again, e.g. '↻ Chorus'.
  ///
  /// In en, this message translates to:
  /// **'↻ {section}'**
  String lyricsRepeat(String section);

  /// Settings section heading for how lyrics show.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get settingsSectionLyrics;

  /// Settings row: timing correction for songs without their own.
  ///
  /// In en, this message translates to:
  /// **'Default sync timing'**
  String get settingsLyricsDefaultOffset;

  /// Note under the default sync timing setting.
  ///
  /// In en, this message translates to:
  /// **'Songs you\'ve adjusted in Now Playing keep their own timing.'**
  String get settingsLyricsDefaultOffsetNote;

  /// Snackbar when pulling to refresh the catalog's song list fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the song list. Check your connection.'**
  String get catalogRefreshFailed;

  /// Snackbar when pulling to refresh in a build without a backend.
  ///
  /// In en, this message translates to:
  /// **'The song list isn\'t available in this build.'**
  String get catalogNotConfigured;

  /// C07 title when a song's lyrics aren't downloaded and there is no network.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get lyricsOfflineTitle;

  /// C07 message when a song's lyrics aren't downloaded and there is no network.
  ///
  /// In en, this message translates to:
  /// **'These lyrics haven\'t been downloaded yet. Connect to the internet and try again.'**
  String get lyricsOfflineMessage;

  /// C07 title when downloading a song's lyrics fails for another reason.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the lyrics'**
  String get lyricsLoadFailedTitle;

  /// C07 message when downloading a song's lyrics fails for another reason.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong getting these lyrics. Try again in a moment.'**
  String get lyricsLoadFailedMessage;

  /// Small lyrics panel on Now Playing when the song's lyrics aren't downloaded and there is no network; tapping it opens the full lyrics with Try again.
  ///
  /// In en, this message translates to:
  /// **'Offline: these lyrics aren\'t downloaded yet'**
  String get lyricsPreviewOffline;

  /// Note in Search's Lyrics group when the catalog can't be searched without a network; the lines below come from downloaded songs.
  ///
  /// In en, this message translates to:
  /// **'Offline: showing lyrics saved on this phone'**
  String get searchCatalogOffline;

  /// Note in Search's Lyrics group when searching the catalog fails for another reason; the lines below come from downloaded songs.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t search the catalog'**
  String get searchCatalogFailed;

  /// Settings → Lyrics row: how much storage downloaded lyrics take.
  ///
  /// In en, this message translates to:
  /// **'Downloaded lyrics'**
  String get settingsLyricsDownloaded;

  /// Value of the Downloaded lyrics row, e.g. '12 songs · 340 KB'.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song} other{{count} songs}} · {size}'**
  String settingsLyricsDownloadedValue(int count, String size);

  /// Value of the Downloaded lyrics row when nothing is downloaded.
  ///
  /// In en, this message translates to:
  /// **'None yet'**
  String get settingsLyricsDownloadedNone;

  /// Settings → Lyrics row that downloads every song's lyrics for use without a network.
  ///
  /// In en, this message translates to:
  /// **'Download all lyrics for offline'**
  String get settingsLyricsDownloadAll;

  /// Download all row while the song list is being checked, before songs download.
  ///
  /// In en, this message translates to:
  /// **'Checking the song list…'**
  String get settingsLyricsDownloadChecking;

  /// Download all row while downloading, e.g. '12 of 40'.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String settingsLyricsDownloadProgress(int done, int total);

  /// Download all row after every song was downloaded.
  ///
  /// In en, this message translates to:
  /// **'All lyrics downloaded'**
  String get settingsLyricsDownloadDone;

  /// Download all row after the listener cancelled it.
  ///
  /// In en, this message translates to:
  /// **'Cancelled: {done} of {total} saved'**
  String settingsLyricsDownloadCancelled(int done, int total);

  /// Download all row after it stopped because there was no network.
  ///
  /// In en, this message translates to:
  /// **'Stopped: check your connection. {done} of {total} saved'**
  String settingsLyricsDownloadOffline(int done, int total);

  /// Download all row after it stopped for another reason.
  ///
  /// In en, this message translates to:
  /// **'Stopped: something went wrong. {done} of {total} saved'**
  String settingsLyricsDownloadFailed(int done, int total);

  /// Download all row in a build with no lyrics catalog.
  ///
  /// In en, this message translates to:
  /// **'Not available in this build'**
  String get settingsLyricsDownloadUnavailable;

  /// Settings → Lyrics row that deletes downloaded lyrics.
  ///
  /// In en, this message translates to:
  /// **'Clear downloaded lyrics'**
  String get settingsLyricsClear;

  /// Title of the dialog confirming Clear downloaded lyrics.
  ///
  /// In en, this message translates to:
  /// **'Clear downloaded lyrics?'**
  String get settingsLyricsClearTitle;

  /// Message of the dialog confirming Clear downloaded lyrics.
  ///
  /// In en, this message translates to:
  /// **'Songs will download again when you open them online. Your matched songs stay matched.'**
  String get settingsLyricsClearMessage;

  /// Button in the dialog that clears downloaded lyrics.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsLyricsClearConfirm;

  /// Song page tab listing the song's recordings.
  ///
  /// In en, this message translates to:
  /// **'Recordings'**
  String get songDetailRecordingsTab;

  /// Tooltip of the song page's overflow menu.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get songDetailMoreOptions;

  /// Recordings tab when the song has none.
  ///
  /// In en, this message translates to:
  /// **'No recordings yet'**
  String get songRecordingsEmpty;

  /// Label on a recording whose lyrics are timed to it.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get songRecordingSynced;

  /// Label on a recording with no lyrics timing.
  ///
  /// In en, this message translates to:
  /// **'Text only'**
  String get songRecordingTextOnly;

  /// Marks the recording whose timing the lyrics view uses.
  ///
  /// In en, this message translates to:
  /// **'Used for lyrics'**
  String get songRecordingUsed;

  /// Menu item and sheet title for reporting a song's lyrics.
  ///
  /// In en, this message translates to:
  /// **'Report wrong lyrics'**
  String get reportLyrics;

  /// Asks for the reason in the report sheet.
  ///
  /// In en, this message translates to:
  /// **'What\'s wrong?'**
  String get reportReasonPrompt;

  /// Report reason: the words are wrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong words'**
  String get reportReasonWrongWords;

  /// Report reason: the lines show at the wrong time.
  ///
  /// In en, this message translates to:
  /// **'Wrong timing'**
  String get reportReasonWrongTiming;

  /// Report reason: these are another song's lyrics.
  ///
  /// In en, this message translates to:
  /// **'Wrong song'**
  String get reportReasonWrongSong;

  /// Report reason: something else.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportReasonOther;

  /// Label of the report sheet's note field.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get reportNote;

  /// Sends the report.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get reportSend;

  /// Snackbar after a report is accepted.
  ///
  /// In en, this message translates to:
  /// **'Thanks, we\'ll take a look'**
  String get reportSent;

  /// Snackbar after a report is kept on the phone to send later.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline, so it\'ll be sent later'**
  String get reportQueued;

  /// Snackbar when the daily report limit is reached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve sent the most reports for today. Try again tomorrow.'**
  String get reportLimited;

  /// Snackbar when the catalog refuses a report.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send the report'**
  String get reportFailed;

  /// Home row of the songs most recently added to the shared lyrics catalog.
  ///
  /// In en, this message translates to:
  /// **'New lyrics from the community'**
  String get homeNewLyrics;

  /// Title of the one-time account choice (S04) shown before Home.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Zema'**
  String get accountChoiceTitle;

  /// S04 text above the list of what an account adds.
  ///
  /// In en, this message translates to:
  /// **'Everything works without an account. Sign in with Google to get more:'**
  String get accountChoiceMessage;

  /// What an account adds: contributing to the shared lyrics.
  ///
  /// In en, this message translates to:
  /// **'Add and fix lyrics for everyone'**
  String get accountBenefitContribute;

  /// What an account adds: backup.
  ///
  /// In en, this message translates to:
  /// **'Back up your favorites, playlists and settings'**
  String get accountBenefitBackup;

  /// What an account adds: restore on another phone.
  ///
  /// In en, this message translates to:
  /// **'Get them back on a new phone'**
  String get accountBenefitRestore;

  /// Button that keeps using the app without an account.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get accountContinueAsGuest;

  /// Button that opens the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get accountSignIn;

  /// Title of the sign-in screen (S24).
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// Heading on the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Zema'**
  String get signInHeading;

  /// Button that opens the Google account picker.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInWithGoogle;

  /// Small note under the sign-in buttons.
  ///
  /// In en, this message translates to:
  /// **'Your Google name and photo are used for your profile. You can change the name later.'**
  String get signInGoogleNote;

  /// Snackbar when sign-in fails because the phone is offline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Try again when you\'re online.'**
  String get signInOffline;

  /// Snackbar when Google or the server refuses the sign-in.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in. Try again.'**
  String get signInFailed;

  /// Snackbar after a successful sign-in, with the account's name or email.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String signInDone(String name);

  /// Home header button that opens Profile (S25).
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeProfileTooltip;

  /// Title of the Profile screen (S25).
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Shown instead of a name on Profile when not signed in.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get profileGuestName;

  /// Heading of the sign-in card on Profile for a guest.
  ///
  /// In en, this message translates to:
  /// **'Sign in to do more'**
  String get profileSignInCardTitle;

  /// Role badge: a signed-in user who can add lyrics.
  ///
  /// In en, this message translates to:
  /// **'Contributor'**
  String get profileRoleContributor;

  /// Role badge: a user who reviews contributions.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get profileRoleModerator;

  /// Role badge: an administrator.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get profileRoleAdmin;

  /// Profile section holding the link to Settings.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get profileSectionGeneral;

  /// Profile section holding Sign out and Delete account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileSectionAccount;

  /// Tooltip of the edit button next to the name, and title of its dialog.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get profileEditName;

  /// Label of the name field in the Edit name dialog.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileNameLabel;

  /// Snackbar when the new name can't be saved because the phone is offline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Your name wasn\'t changed.'**
  String get profileNameOffline;

  /// Snackbar when the server refuses the new name.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your name. Try again.'**
  String get profileNameFailed;

  /// Profile row and dialog button that signs out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get profileSignOut;

  /// Title of the sign-out confirmation.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get profileSignOutTitle;

  /// Sign-out confirmation text.
  ///
  /// In en, this message translates to:
  /// **'Your songs, playlists and favorites stay on this phone.'**
  String get profileSignOutMessage;

  /// Snackbar after signing out.
  ///
  /// In en, this message translates to:
  /// **'Signed out'**
  String get profileSignedOut;

  /// Profile row that starts deleting the account.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get profileDeleteAccount;

  /// Title of the first delete-account dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get profileDeleteTitle;

  /// First delete-account dialog: what is deleted and what stays.
  ///
  /// In en, this message translates to:
  /// **'This deletes your Zema account, your profile and your cloud backup. Lyrics you contributed stay, without your name.\n\nSongs, playlists and favorites on this phone stay.'**
  String get profileDeleteMessage;

  /// Button that goes on to the second delete-account dialog.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get profileDeleteContinue;

  /// Title of the second delete-account dialog.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone'**
  String get profileDeleteConfirmTitle;

  /// Second delete-account dialog text.
  ///
  /// In en, this message translates to:
  /// **'Your account and cloud backup will be deleted now, and you\'ll be signed out.'**
  String get profileDeleteConfirmMessage;

  /// Shown while the account is being deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account…'**
  String get profileDeleting;

  /// Snackbar after the account is deleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get profileDeleted;

  /// Snackbar when deleting fails because the phone is offline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Your account wasn\'t deleted.'**
  String get profileDeleteOffline;

  /// Snackbar when the server fails to delete the account.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete your account. Try again later.'**
  String get profileDeleteFailed;

  /// Title of the sheet (C09) shown when a guest tries something that needs an account.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInPromptTitle;

  /// Closes the sign-in sheet (C09) without signing in.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get signInPromptNotNow;

  /// Settings section holding Account & backup.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// Settings row opening Backup & sync, or the sign-in sheet for a guest.
  ///
  /// In en, this message translates to:
  /// **'Account & backup'**
  String get settingsAccountBackup;

  /// Why Backup & sync needs an account, on the sign-in sheet.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google to back up your favorites, playlists and settings, and get them back on a new phone.'**
  String get backupSignInReason;

  /// Title of the Backup & sync screen (S25b).
  ///
  /// In en, this message translates to:
  /// **'Backup & sync'**
  String get backupTitle;

  /// Heading of the list of what a backup holds.
  ///
  /// In en, this message translates to:
  /// **'What\'s backed up'**
  String get backupIncludedTitle;

  /// What a backup holds.
  ///
  /// In en, this message translates to:
  /// **'Favorites, playlists, the lyrics you chose for songs, hidden folders and songs, and your settings.'**
  String get backupIncluded;

  /// Heading of what a backup leaves out.
  ///
  /// In en, this message translates to:
  /// **'Not backed up'**
  String get backupNotIncludedTitle;

  /// What a backup leaves out, and how songs are found again.
  ///
  /// In en, this message translates to:
  /// **'Your audio files, play history and downloaded lyrics. On a new phone, songs are found again by their title, artist, length and file name.'**
  String get backupNotIncluded;

  /// Backup & sync section with the last backup, Back up now and Auto backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupSectionStatus;

  /// Label of the row showing when the last backup was made.
  ///
  /// In en, this message translates to:
  /// **'Last backup'**
  String get backupLast;

  /// Last backup value when there has been none.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get backupNever;

  /// When the last backup was made, e.g. 'Oct 30, 2026, 2:15 PM'.
  ///
  /// In en, this message translates to:
  /// **'{date}, {time}'**
  String backupLastAt(String date, String time);

  /// Row that uploads a backup at once.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupNow;

  /// Switch for the daily automatic backup.
  ///
  /// In en, this message translates to:
  /// **'Auto backup'**
  String get backupAuto;

  /// When auto backup runs, shown beside its switch.
  ///
  /// In en, this message translates to:
  /// **'Daily on Wi-Fi'**
  String get backupAutoNote;

  /// Shown under the last backup time when it failed offline.
  ///
  /// In en, this message translates to:
  /// **'The last backup failed: no connection.'**
  String get backupErrorOffline;

  /// Shown under the last backup time when the server failed.
  ///
  /// In en, this message translates to:
  /// **'The last backup failed. Try again later.'**
  String get backupErrorFailed;

  /// Shown when auto backup stopped because the cloud backup came from elsewhere.
  ///
  /// In en, this message translates to:
  /// **'The cloud has a backup from another phone. Back up now to replace it.'**
  String get backupErrorOther;

  /// Message after Back up now succeeds.
  ///
  /// In en, this message translates to:
  /// **'Backed up'**
  String get backupDone;

  /// Message when Back up now fails offline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Your backup wasn\'t changed.'**
  String get backupOffline;

  /// Message when Back up now fails on the server.
  ///
  /// In en, this message translates to:
  /// **'Backup failed. Your backup wasn\'t changed.'**
  String get backupFailed;

  /// Title of the warning before replacing a backup made elsewhere.
  ///
  /// In en, this message translates to:
  /// **'Replace the cloud backup?'**
  String get backupReplaceTitle;

  /// Warning before replacing a backup this phone didn't make.
  ///
  /// In en, this message translates to:
  /// **'The backup from {date} was made on another phone, or kept when you started fresh. Backing up now replaces it with this phone\'s library.'**
  String backupReplaceMessage(String date);

  /// Confirms replacing the cloud backup.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get backupReplace;

  /// Title of the Restore screen (S26).
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreTitle;

  /// Shown while the cloud backup downloads.
  ///
  /// In en, this message translates to:
  /// **'Looking for your backup…'**
  String get restoreLoading;

  /// What the cloud backup holds. {favorites} and {playlists} are restoreCountFavorites and restoreCountPlaylists.
  ///
  /// In en, this message translates to:
  /// **'We found your backup from {date}: {favorites}, {playlists}, settings.'**
  String restoreFound(String date, String favorites, String playlists);

  /// Number of favorites in a backup.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 favorite} other{{count} favorites}}'**
  String restoreCountFavorites(int count);

  /// Number of playlists in a backup.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 playlist} other{{count} playlists}}'**
  String restoreCountPlaylists(int count);

  /// How a restore merges.
  ///
  /// In en, this message translates to:
  /// **'Restoring adds them to what\'s on this phone, and replaces your settings. Nothing here is removed.'**
  String get restoreMergeNote;

  /// Button that restores the backup.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreAction;

  /// Button that leaves the backup in the cloud and changes nothing on this phone.
  ///
  /// In en, this message translates to:
  /// **'Start fresh'**
  String get restoreStartFresh;

  /// Explains Start fresh.
  ///
  /// In en, this message translates to:
  /// **'Start fresh keeps your backup in the cloud and changes nothing here.'**
  String get restoreStartFreshNote;

  /// Shown when the account has no cloud backup.
  ///
  /// In en, this message translates to:
  /// **'There\'s no backup for this account yet.'**
  String get restoreNone;

  /// Shown when the backup can't be downloaded offline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Try again when you\'re online.'**
  String get restoreOffline;

  /// Shown when the backup can't be read or restored.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t restore your backup. Try again later.'**
  String get restoreFailed;

  /// Shown when the backup's format is newer than this app.
  ///
  /// In en, this message translates to:
  /// **'This backup was made by a newer version of Zema. Update the app to restore it.'**
  String get restoreNewer;

  /// Retries loading the backup.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get restoreRetry;

  /// Shown while the library is scanned before a restore.
  ///
  /// In en, this message translates to:
  /// **'Finding the songs on this phone…'**
  String get restoreWaitingForScan;

  /// Shown while a backup is merged.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get restoreRunning;

  /// Heading after a restore.
  ///
  /// In en, this message translates to:
  /// **'Restored'**
  String get restoreDoneTitle;

  /// Restore summary line.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 favorite added} other{{count} favorites added}}'**
  String restoreDoneFavorites(int count);

  /// Restore summary line.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song added to playlists} other{{count} songs added to playlists}}'**
  String restoreDonePlaylists(int count);

  /// Restore summary line.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 lyrics choice added} other{{count} lyrics choices added}}'**
  String restoreDoneChoices(int count);

  /// Restore summary line.
  ///
  /// In en, this message translates to:
  /// **'Settings restored'**
  String get restoreDoneSettings;

  /// Heading of the songs a restore couldn't find.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 song isn\'t on this phone} other{{count} songs aren\'t on this phone}}'**
  String restoreNotFoundTitle(int count);

  /// Explains what happens to songs not found.
  ///
  /// In en, this message translates to:
  /// **'They\'re kept, and added as soon as they show up on this phone.'**
  String get restoreNotFoundNote;

  /// Closes the Restore screen after a restore.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get restoreDone;

  /// Backup & sync row opening the Restore screen.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get backupRestore;

  /// Under the Contribute tab's title (S05).
  ///
  /// In en, this message translates to:
  /// **'Help everyone sing along'**
  String get contributeSubtitle;

  /// Title of the steps card on S05.
  ///
  /// In en, this message translates to:
  /// **'How contributing works'**
  String get contributeHowTitle;

  /// Step 1 of contributing.
  ///
  /// In en, this message translates to:
  /// **'Write the lyrics'**
  String get contributeStepLyrics;

  /// Explains step 1.
  ///
  /// In en, this message translates to:
  /// **'Type or paste the words. Mark verses and the chorus.'**
  String get contributeStepLyricsBody;

  /// Step 2 of contributing.
  ///
  /// In en, this message translates to:
  /// **'Link a recording'**
  String get contributeStepRecording;

  /// Explains step 2.
  ///
  /// In en, this message translates to:
  /// **'A YouTube link, a Telegram audio, or a file on your phone.'**
  String get contributeStepRecordingBody;

  /// Step 3 of contributing.
  ///
  /// In en, this message translates to:
  /// **'Sync the lines'**
  String get contributeStepSync;

  /// Explains step 3.
  ///
  /// In en, this message translates to:
  /// **'Play the song and tap when each line starts.'**
  String get contributeStepSyncBody;

  /// Step 4 of contributing.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get contributeStepReview;

  /// Explains step 4.
  ///
  /// In en, this message translates to:
  /// **'A moderator checks it, then everyone can sing along.'**
  String get contributeStepReviewBody;

  /// Starts a new contribution; also the flow's title.
  ///
  /// In en, this message translates to:
  /// **'Add lyrics'**
  String get contributeAddLyrics;

  /// Why contributing needs an account (C09).
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google to add lyrics and timings for everyone. A moderator checks each contribution before it\'s shared.'**
  String get contributeSignInReason;

  /// S05 in a build without a backend.
  ///
  /// In en, this message translates to:
  /// **'Contributing needs the online catalog, which this version of the app doesn\'t have.'**
  String get contributeNoBackend;

  /// Heading of the drafts list on S05.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get contributeDraftsTitle;

  /// A draft with no title yet.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get contributeDraftUntitled;

  /// A draft's step and when it last changed.
  ///
  /// In en, this message translates to:
  /// **'{step} · {time}'**
  String contributeDraftSubtitle(String step, String time);

  /// Deletes a draft (button and tooltip).
  ///
  /// In en, this message translates to:
  /// **'Delete draft'**
  String get contributeDraftDelete;

  /// Title of the confirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete this draft?'**
  String get contributeDraftDeleteTitle;

  /// Confirmation message.
  ///
  /// In en, this message translates to:
  /// **'“{title}” will be deleted from this phone.'**
  String contributeDraftDeleteMessage(String title);

  /// Shown when a draft was deleted elsewhere.
  ///
  /// In en, this message translates to:
  /// **'This draft no longer exists.'**
  String get contributeDraftGone;

  /// Song title field (S19).
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get contributeFieldTitle;

  /// Transliteration field (S19).
  ///
  /// In en, this message translates to:
  /// **'Title in Latin letters (optional)'**
  String get contributeFieldTransliteration;

  /// Artist field (S19).
  ///
  /// In en, this message translates to:
  /// **'Artist or choir'**
  String get contributeFieldArtist;

  /// Album field (S19).
  ///
  /// In en, this message translates to:
  /// **'Album (optional)'**
  String get contributeFieldAlbum;

  /// Error under an empty title.
  ///
  /// In en, this message translates to:
  /// **'Enter the song\'s title'**
  String get contributeTitleRequired;

  /// Error under a long title.
  ///
  /// In en, this message translates to:
  /// **'Keep the title under 200 characters'**
  String get contributeTitleTooLong;

  /// Error when a detail is too long.
  ///
  /// In en, this message translates to:
  /// **'Keep the transliteration, artist and album under 200 characters each.'**
  String get contributeFieldTooLong;

  /// Tells the user drafts save themselves.
  ///
  /// In en, this message translates to:
  /// **'Saved on this phone as you type'**
  String get contributeSavedOnPhone;

  /// Added to the sign-out and delete confirmations when drafts exist.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 draft on this phone will be deleted: {titles}.} other{{count} drafts on this phone will be deleted: {titles}.}}'**
  String profileDraftsWarning(int count, String titles);

  /// A verse block's label, numbered.
  ///
  /// In en, this message translates to:
  /// **'Verse {n}'**
  String contributeBlockVerse(int n);

  /// A chorus block's label when the song has more than one chorus.
  ///
  /// In en, this message translates to:
  /// **'Chorus {n}'**
  String contributeBlockChorusN(int n);

  /// The bridge block kind.
  ///
  /// In en, this message translates to:
  /// **'Bridge'**
  String get contributeBlockBridge;

  /// A bridge block's label when there is more than one.
  ///
  /// In en, this message translates to:
  /// **'Bridge {n}'**
  String contributeBlockBridgeN(int n);

  /// A block that is neither verse, chorus nor bridge (an intro, a spoken part).
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get contributeBlockOther;

  /// An other block's label when there is more than one.
  ///
  /// In en, this message translates to:
  /// **'Other {n}'**
  String contributeBlockOtherN(int n);

  /// Tooltip of the menu that changes a block's kind.
  ///
  /// In en, this message translates to:
  /// **'Block type'**
  String get contributeBlockKind;

  /// Tooltip of a block's menu.
  ///
  /// In en, this message translates to:
  /// **'Block options'**
  String get contributeBlockMenu;

  /// Moves a block up.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get contributeBlockMoveUp;

  /// Moves a block down.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get contributeBlockMoveDown;

  /// Opens a field for the block's lines in Latin letters.
  ///
  /// In en, this message translates to:
  /// **'Add Latin letters'**
  String get contributeBlockShowLatin;

  /// Closes the block's Latin-letters field while it's empty.
  ///
  /// In en, this message translates to:
  /// **'Hide Latin letters'**
  String get contributeBlockHideLatin;

  /// Label of a block's transliteration field.
  ///
  /// In en, this message translates to:
  /// **'In Latin letters (optional)'**
  String get contributeBlockLatin;

  /// Helper under a block's transliteration field.
  ///
  /// In en, this message translates to:
  /// **'One row for each line above, in the same order.'**
  String get contributeBlockLatinHelp;

  /// Deletes a block (menu item and confirm button).
  ///
  /// In en, this message translates to:
  /// **'Delete block'**
  String get contributeBlockDelete;

  /// Title when deleting a block.
  ///
  /// In en, this message translates to:
  /// **'Delete {block}?'**
  String contributeBlockDeleteTitle(String block);

  /// Body when deleting a block; count is how often it's in the play order.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Its lines will be deleted.} =1{Its lines will be deleted, and it\'s taken out of the play order.} other{Its lines will be deleted, and its {count} places in the play order are taken out.}}'**
  String contributeBlockDeleteMessage(int count);

  /// Hint in an empty block.
  ///
  /// In en, this message translates to:
  /// **'Type the lines, one per row'**
  String get contributeBlockHint;

  /// Error when a block has an empty row between lines.
  ///
  /// In en, this message translates to:
  /// **'Remove empty rows. To start a new part, add a block.'**
  String get contributeBlockBlankLine;

  /// Error when a line is too long.
  ///
  /// In en, this message translates to:
  /// **'Keep each line under {max} characters'**
  String contributeLineTooLong(int max);

  /// Error when the blocks have too many lines in total.
  ///
  /// In en, this message translates to:
  /// **'Songs can have up to {max} written lines.'**
  String contributeTooManyLines(int max);

  /// Hint above the blocks.
  ///
  /// In en, this message translates to:
  /// **'Write the chorus once. Then add it to the play order every time it\'s sung.'**
  String get contributeChorusHint;

  /// Adds a block.
  ///
  /// In en, this message translates to:
  /// **'Add block'**
  String get contributeAddBlock;

  /// Opens the dialog that splits pasted lyrics into blocks.
  ///
  /// In en, this message translates to:
  /// **'Paste all text'**
  String get contributePasteAll;

  /// Explains how pasted text is split.
  ///
  /// In en, this message translates to:
  /// **'Paste the whole song. A blank line starts a new block, and a block that comes again becomes the chorus.'**
  String get contributePasteHelp;

  /// Added when pasting would replace existing blocks.
  ///
  /// In en, this message translates to:
  /// **'This replaces the blocks you have.'**
  String get contributePasteReplaces;

  /// Confirms pasting.
  ///
  /// In en, this message translates to:
  /// **'Split into blocks'**
  String get contributePasteSplit;

  /// Shown after pasting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 block made. Check its type and the play order.} other{{count} blocks made. Check their types and the play order.}}'**
  String contributePasted(int count);

  /// Heading of the play order strip.
  ///
  /// In en, this message translates to:
  /// **'Play order'**
  String get contributePlayOrder;

  /// Help under the play order heading.
  ///
  /// In en, this message translates to:
  /// **'Tap an entry to move or remove it.'**
  String get contributePlayOrderHelp;

  /// Tooltip of a play order entry.
  ///
  /// In en, this message translates to:
  /// **'Entry {n} of the play order'**
  String contributePlayOrderEntry(int n);

  /// Adds a block to the end of the play order.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get contributePlayOrderAdd;

  /// Moves a play order entry one place earlier.
  ///
  /// In en, this message translates to:
  /// **'Move earlier'**
  String get contributePlayOrderEarlier;

  /// Moves a play order entry one place later.
  ///
  /// In en, this message translates to:
  /// **'Move later'**
  String get contributePlayOrderLater;

  /// Removes an entry from the play order.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get contributePlayOrderRemove;

  /// Error when the play order is empty.
  ///
  /// In en, this message translates to:
  /// **'Add at least one block to the play order.'**
  String get contributePlayOrderEmpty;

  /// Goes from the lyrics to step 2.
  ///
  /// In en, this message translates to:
  /// **'Next: link a recording'**
  String get contributeNextRecording;

  /// S20 heading.
  ///
  /// In en, this message translates to:
  /// **'Which recording are these lyrics for?'**
  String get contributeRecordingTitle;

  /// S20 explanation.
  ///
  /// In en, this message translates to:
  /// **'Timings belong to one performance. Pick the one you\'ll sync with.'**
  String get contributeRecordingBody;

  /// S20 choice: a track in the library.
  ///
  /// In en, this message translates to:
  /// **'A song on this phone'**
  String get contributeRecordingLocal;

  /// S20 choice: a YouTube video.
  ///
  /// In en, this message translates to:
  /// **'A YouTube link'**
  String get contributeRecordingYoutube;

  /// S20 choice: an audio file shared to Zema from Telegram or another app.
  ///
  /// In en, this message translates to:
  /// **'An audio from Telegram'**
  String get contributeRecordingShared;

  /// Field for the recording's performer.
  ///
  /// In en, this message translates to:
  /// **'Artist or choir in this recording'**
  String get contributeRecordingArtist;

  /// Opens the list of songs on the phone.
  ///
  /// In en, this message translates to:
  /// **'Choose a song'**
  String get contributeChooseSong;

  /// Chooses another song.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get contributeChange;

  /// Shown in the song picker when the library is empty.
  ///
  /// In en, this message translates to:
  /// **'No songs on this phone yet.'**
  String get contributeNoSongs;

  /// Field for a YouTube link.
  ///
  /// In en, this message translates to:
  /// **'YouTube link'**
  String get contributeYoutubeLink;

  /// Error for a link that isn't one YouTube video (a playlist, a channel, another site).
  ///
  /// In en, this message translates to:
  /// **'This isn\'t a link to one video. Copy the link from the video\'s Share button.'**
  String get contributeYoutubeBadLink;

  /// Field for the video's title when it can't be looked up.
  ///
  /// In en, this message translates to:
  /// **'Video title'**
  String get contributeYoutubeTitle;

  /// Helper when the YouTube lookup failed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t look up the video. Type its title, or try again online.'**
  String get contributeYoutubeOffline;

  /// Field for the video's length, as m:ss.
  ///
  /// In en, this message translates to:
  /// **'Length (optional)'**
  String get contributeYoutubeDuration;

  /// Error for a length that doesn't read.
  ///
  /// In en, this message translates to:
  /// **'Type the length as minutes:seconds, like 4:05'**
  String get contributeYoutubeBadDuration;

  /// Explains that a YouTube recording skips the sync step.
  ///
  /// In en, this message translates to:
  /// **'YouTube videos can\'t be played in Zema, so they can\'t be synced. The lyrics and the link are sent without timings.'**
  String get contributeYoutubeNoSync;

  /// How to share an audio file from Telegram to Zema.
  ///
  /// In en, this message translates to:
  /// **'In Telegram, open the audio\'s menu, tap Share, and choose Zema. It opens here.'**
  String get contributeSharedHow;

  /// Goes from the recording to the sync step.
  ///
  /// In en, this message translates to:
  /// **'Next: sync the lines'**
  String get contributeNextSync;

  /// Goes to the review step (YouTube skips syncing).
  ///
  /// In en, this message translates to:
  /// **'Next: review'**
  String get contributeNextReview;

  /// Goes to the previous step.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get contributeBack;

  /// Sends a new song without a recording or timings.
  ///
  /// In en, this message translates to:
  /// **'Skip, lyrics only'**
  String get contributeSkipRecording;

  /// Shown when Next is pressed on S20 while the lyrics still have problems.
  ///
  /// In en, this message translates to:
  /// **'Finish the lyrics first.'**
  String get contributeLyricsFirst;

  /// Temporary text for steps not built yet.
  ///
  /// In en, this message translates to:
  /// **'This step is coming in the next update.'**
  String get contributeStepLater;

  /// Shown when an audio file is shared to an app without a backend.
  ///
  /// In en, this message translates to:
  /// **'Contributing needs the online catalog, which this version of the app doesn\'t have.'**
  String get contributeShareNeedsBackend;

  /// S21 when the track or shared file is gone.
  ///
  /// In en, this message translates to:
  /// **'This recording isn\'t on this phone any more, so it can\'t be played for syncing.'**
  String get contributeSyncNoAudio;

  /// Goes back to S20 from S21.
  ///
  /// In en, this message translates to:
  /// **'Choose another recording'**
  String get contributeSyncChooseRecording;

  /// Under the line the next tap times.
  ///
  /// In en, this message translates to:
  /// **'Tap when this line starts'**
  String get contributeSyncTapHint;

  /// Tooltip: nudges a line's start earlier.
  ///
  /// In en, this message translates to:
  /// **'0.1 s earlier (hold to keep moving)'**
  String get contributeSyncEarlier;

  /// Tooltip: nudges a line's start later.
  ///
  /// In en, this message translates to:
  /// **'0.1 s later (hold to keep moving)'**
  String get contributeSyncLater;

  /// Clears this line's time and later ones, and plays from just before it.
  ///
  /// In en, this message translates to:
  /// **'Redo from here'**
  String get contributeSyncRedo;

  /// Clears the last time tapped.
  ///
  /// In en, this message translates to:
  /// **'Undo last tap'**
  String get contributeSyncUndo;

  /// Leaves S21 without timings.
  ///
  /// In en, this message translates to:
  /// **'Skip, send text only'**
  String get contributeSyncSkip;

  /// The big button that times the next line.
  ///
  /// In en, this message translates to:
  /// **'Tap — next line'**
  String get contributeSyncTap;

  /// The big button while the recording is paused; pressing it plays.
  ///
  /// In en, this message translates to:
  /// **'Play to start'**
  String get contributeSyncPressPlay;

  /// Moves playback back 5 seconds.
  ///
  /// In en, this message translates to:
  /// **'−5 s'**
  String get contributeSyncBack5;

  /// Playback speed button at normal speed; tap for 0.75×.
  ///
  /// In en, this message translates to:
  /// **'1×'**
  String get contributeSyncSpeedNormal;

  /// Playback speed button at 0.75×; tap for normal speed.
  ///
  /// In en, this message translates to:
  /// **'0.75×'**
  String get contributeSyncSpeedSlow;

  /// S21 view with every line in a list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get contributeSyncList;

  /// S21 view with one line large and a big tap area.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get contributeSyncFocus;

  /// Plays the song from the start with the lyrics highlighting.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get contributeSyncPreview;

  /// Leaves the preview.
  ///
  /// In en, this message translates to:
  /// **'Back to syncing'**
  String get contributeSyncEndPreview;

  /// The Focus view's tap area while playing.
  ///
  /// In en, this message translates to:
  /// **'Tap when you hear it'**
  String get contributeSyncHearIt;

  /// The time of the line before, in the Focus view.
  ///
  /// In en, this message translates to:
  /// **'✓ {time}'**
  String contributeSyncTimedAt(String time);

  /// The Focus view when all lines are timed.
  ///
  /// In en, this message translates to:
  /// **'Every line has a time. Check it with Preview.'**
  String get contributeSyncAllTimed;

  /// Tooltip of S21 menu with Skip.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get contributeSyncMore;

  /// Shown on S19 when the typed title matches catalog songs.
  ///
  /// In en, this message translates to:
  /// **'A similar song exists'**
  String get contributeSimilarTitle;

  /// Under the similar-song heading on S19.
  ///
  /// In en, this message translates to:
  /// **'If it\'s the same song, add your recording to it or suggest a correction instead.'**
  String get contributeSimilarHelp;

  /// Switches the draft to adding a recording of the matched song.
  ///
  /// In en, this message translates to:
  /// **'Add a recording'**
  String get contributeSimilarAddRecording;

  /// Switches the draft to correcting the matched song's lyrics.
  ///
  /// In en, this message translates to:
  /// **'Suggest a correction'**
  String get contributeSimilarCorrect;

  /// Tooltip of the button that hides the similar-song warning.
  ///
  /// In en, this message translates to:
  /// **'Not the same song'**
  String get contributeSimilarIgnore;

  /// Snackbar when the matched song can't be downloaded.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open that song. Check your connection and try again.'**
  String get contributeSimilarUnavailable;

  /// Search with no results: starts a new song with the query as its title.
  ///
  /// In en, this message translates to:
  /// **'Add this song\'s lyrics'**
  String get contributeEntryAddSongLyrics;

  /// Song detail menu: adds a recording to this catalog song.
  ///
  /// In en, this message translates to:
  /// **'Link a recording'**
  String get contributeEntryLinkRecording;

  /// Song detail menu: times the lyrics for the phone's recording of this song.
  ///
  /// In en, this message translates to:
  /// **'Sync this recording'**
  String get contributeEntrySyncRecording;

  /// Song detail menu: opens S19 filled with this song to fix it.
  ///
  /// In en, this message translates to:
  /// **'Suggest a correction'**
  String get contributeCorrectionSuggest;

  /// Shown at the top of S19 for a correction.
  ///
  /// In en, this message translates to:
  /// **'You\'re correcting the catalog\'s lyrics. Change only what\'s wrong; a moderator checks it.'**
  String get contributeCorrectionNote;

  /// Heading of the list of lines a correction changes.
  ///
  /// In en, this message translates to:
  /// **'Changed lines'**
  String get contributeCorrectionChanges;

  /// When a correction changes no line.
  ///
  /// In en, this message translates to:
  /// **'No lines changed.'**
  String get contributeCorrectionNoChanges;

  /// Label of a line the correction adds.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get contributeCorrectionAdded;

  /// Label of a line the correction removes.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get contributeCorrectionRemoved;

  /// Label of a line the correction changes.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get contributeCorrectionChanged;

  /// Above the recordings a correction would leave unsynced.
  ///
  /// In en, this message translates to:
  /// **'The number of sung lines changes, so these recordings lose their timings until someone syncs them again:'**
  String get contributeCorrectionLosesTimings;
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
