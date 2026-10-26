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
