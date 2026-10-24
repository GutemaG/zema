import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../app/theme/zema_palette.dart';
import '../data/app_settings.dart';
import '../data/settings_repository.dart';

final _log = Logger('settings.controller');

/// Set in `main()` through a `ProviderScope` override.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw UnimplementedError(
    'settingsRepositoryProvider must be overridden in main() with a '
    'SettingsRepository over loaded SharedPreferences.',
  ),
);

/// Settings loaded before `runApp`, so the first frame already uses them.
/// Set in `main()`; defaults when not overridden.
final initialSettingsProvider = Provider<AppSettings>(
  (ref) => const AppSettings(),
);

/// The current settings. Changes apply immediately and are then saved.
final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(initialSettingsProvider);

  Future<void> setPalette(ZemaPalette palette) async {
    if (palette == state.palette) {
      return;
    }
    state = state.copyWith(palette: palette);
    await _persist(
      () => ref.read(settingsRepositoryProvider).savePalette(palette),
    );
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (themeMode == state.themeMode) {
      return;
    }
    state = state.copyWith(themeMode: themeMode);
    await _persist(
      () => ref.read(settingsRepositoryProvider).saveThemeMode(themeMode),
    );
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode == state.languageCode) {
      return;
    }
    state = state.copyWith(languageCode: languageCode);
    await _persist(
      () => ref.read(settingsRepositoryProvider).saveLanguage(languageCode),
    );
  }

  /// A failed save keeps the new value for this session; it is only lost on
  /// the next launch.
  Future<void> _persist(Future<void> Function() save) async {
    try {
      await save();
    } on Exception catch (error, stackTrace) {
      _log.warning('Could not save settings', error, stackTrace);
    }
  }
}
