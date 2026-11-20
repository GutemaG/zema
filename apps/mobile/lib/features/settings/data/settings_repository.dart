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
  static const String minTrackSecondsKey = 'minTrackSeconds';
  static const String sleepTimerDefaultKey = 'sleepTimerDefault';
  static const String pauseOnUnplugKey = 'pauseOnUnplug';
  static const String duckOnInterruptionKey = 'duckOnInterruption';
  static const String gaplessKey = 'gapless';
  static const String floatLyricsKey = 'floatLyrics';

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
      minTrackSeconds: switch (_prefs.getInt(minTrackSecondsKey)) {
        final int seconds when AppSettings.minTrackChoices.contains(seconds) =>
          seconds,
        _ => defaults.minTrackSeconds,
      },
      sleepTimerDefault: _byName(
        SleepTimerDefault.values,
        _prefs.getString(sleepTimerDefaultKey),
        defaults.sleepTimerDefault,
      ),
      pauseOnUnplug: _prefs.getBool(pauseOnUnplugKey) ?? defaults.pauseOnUnplug,
      duckOnInterruption:
          _prefs.getBool(duckOnInterruptionKey) ?? defaults.duckOnInterruption,
      gapless: _prefs.getBool(gaplessKey) ?? defaults.gapless,
      floatLyrics: _prefs.getBool(floatLyricsKey) ?? defaults.floatLyrics,
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

  /// Throws [SettingsWriteException] if the value could not be saved.
  Future<void> saveMinTrackSeconds(int seconds) =>
      _write(minTrackSecondsKey, _prefs.setInt(minTrackSecondsKey, seconds));

  /// Throws [SettingsWriteException] if the value could not be saved.
  Future<void> saveSleepTimerDefault(SleepTimerDefault value) =>
      _save(sleepTimerDefaultKey, value.name);

  /// Throws [SettingsWriteException] if the value could not be saved.
  Future<void> savePauseOnUnplug(bool value) =>
      _saveBool(pauseOnUnplugKey, value);

  /// Throws [SettingsWriteException] if the value could not be saved.
  Future<void> saveDuckOnInterruption(bool value) =>
      _saveBool(duckOnInterruptionKey, value);

  /// Throws [SettingsWriteException] if the value could not be saved.
  Future<void> saveGapless(bool value) => _saveBool(gaplessKey, value);

  Future<void> saveFloatLyrics(bool value) => _saveBool(floatLyricsKey, value);

  Future<void> _save(String key, String value) =>
      _write(key, _prefs.setString(key, value));

  Future<void> _saveBool(String key, bool value) =>
      _write(key, _prefs.setBool(key, value));

  Future<void> _write(String key, Future<bool> write) async {
    if (!await write) {
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
