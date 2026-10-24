import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/application/settings_controller.dart';
import 'app_language.dart';

/// Language code the user picked in Settings, or `null` if they never did.
final savedLanguageCodeProvider = Provider<String?>(
  (ref) => ref.watch(settingsProvider.select((s) => s.languageCode)),
);

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
