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
  String get libraryComingSoonMessage =>
      'The music on your phone will be listed here.';

  @override
  String get contributeComingSoonMessage =>
      'Add lyrics and sync timings to help other listeners.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsComingSoonMessage =>
      'Language and palette settings will be here.';

  @override
  String get errorNotFoundTitle => 'Page not found';

  @override
  String get errorNotFoundMessage =>
      'This page doesn\'t exist. Go back to Home to continue.';

  @override
  String get actionGoHome => 'Go home';
}
