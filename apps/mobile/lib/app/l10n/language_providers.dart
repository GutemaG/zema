import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_language.dart';

/// Language code the user picked in Settings, or `null` if they never did.
///
/// Always `null` until Settings exists (bolt 3), which overrides this from
/// saved preferences.
final savedLanguageCodeProvider = Provider<String?>((ref) => null);

/// The phone's preferred languages, in order. Overridden in tests.
final deviceLocalesProvider = Provider<List<Locale>>(
  (ref) => PlatformDispatcher.instance.locales,
);

/// The active UI language.
final appLanguageProvider = Provider<AppLanguage>(
  (ref) => resolveInitialLanguage(
    saved: ref.watch(savedLanguageCodeProvider),
    deviceLocales: ref.watch(deviceLocalesProvider),
  ),
);
