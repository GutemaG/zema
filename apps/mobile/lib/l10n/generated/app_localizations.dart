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
