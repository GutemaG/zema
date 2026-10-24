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
