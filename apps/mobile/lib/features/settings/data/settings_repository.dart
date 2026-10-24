import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/zema_palette.dart';
import 'app_settings.dart';

/// Reads and writes [AppSettings] in `shared_preferences`.
class SettingsRepository {
  SettingsRepository(this._prefs);

  static const String paletteKey = 'paletteId';
  static const String themeModeKey = 'themeMode';
  static const String languageKey = 'localeCode';

  final SharedPreferences _prefs;

  /// Reads the saved settings from the already-loaded preferences, so it can
  /// run in `main()` before the first frame. Missing or unknown values fall
  /// back to the defaults.
  AppSettings load() {
    const defaults = AppSettings();
    return AppSettings(
      palette: _byName(
        ZemaPalette.values,
        _prefs.getString(paletteKey),
        defaults.palette,
      ),
      themeMode: _byName(
        ThemeMode.values,
        _prefs.getString(themeModeKey),
        defaults.themeMode,
      ),
      languageCode: _prefs.getString(languageKey),
    );
  }

  /// Throws [SettingsWriteException] if the value could not be saved.
  Future<void> savePalette(ZemaPalette palette) =>
      _save(paletteKey, palette.name);

  /// Throws [SettingsWriteException] if the value could not be saved.
  Future<void> saveThemeMode(ThemeMode themeMode) =>
      _save(themeModeKey, themeMode.name);

  /// Throws [SettingsWriteException] if the value could not be saved.
  Future<void> saveLanguage(String languageCode) =>
      _save(languageKey, languageCode);

  Future<void> _save(String key, String value) async {
    if (!await _prefs.setString(key, value)) {
      throw SettingsWriteException(key);
    }
  }

  static T _byName<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return fallback;
  }
}

class SettingsWriteException implements Exception {
  const SettingsWriteException(this.key);

  final String key;

  @override
  String toString() => 'SettingsWriteException: could not save "$key"';
}
