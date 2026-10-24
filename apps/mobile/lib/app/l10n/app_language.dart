import 'package:flutter/widgets.dart';

/// UI languages the app ships. English is complete; the others fall back to
/// English for strings that are not translated yet.
enum AppLanguage {
  en('English'),
  am('አማርኛ'),
  om('Afaan Oromoo'),
  ti('ትግርኛ');

  const AppLanguage(this.nativeName);

  static const AppLanguage fallback = AppLanguage.en;

  /// The language's name in its own script, for the language picker. Never
  /// translated.
  final String nativeName;

  /// ISO 639-1 code, also the value stored in settings.
  String get code => name;

  Locale get locale => Locale(code);

  /// Returns the language with [code], or `null` for an unknown or missing
  /// code.
  static AppLanguage? fromCode(String? code) {
    for (final language in values) {
      if (language.code == code) {
        return language;
      }
    }
    return null;
  }
}

/// Picks the UI language on launch.
///
/// A valid [saved] code wins. Otherwise the first entry in [deviceLocales]
/// (the phone's preferred languages, in order) with a supported language code
/// is used, ignoring region (`am_ET` counts as `am`). Otherwise English.
AppLanguage resolveInitialLanguage({
  required String? saved,
  required List<Locale> deviceLocales,
}) {
  final savedLanguage = AppLanguage.fromCode(saved);
  if (savedLanguage != null) {
    return savedLanguage;
  }
  for (final locale in deviceLocales) {
    final language = AppLanguage.fromCode(locale.languageCode);
    if (language != null) {
      return language;
    }
  }
  return AppLanguage.fallback;
}
