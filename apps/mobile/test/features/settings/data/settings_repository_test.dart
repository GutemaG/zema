import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/theme/zema_palette.dart';
import 'package:zema/features/settings/data/app_settings.dart';
import 'package:zema/features/settings/data/settings_repository.dart';

Future<SettingsRepository> _repository([
  Map<String, Object> saved = const {},
]) async {
  SharedPreferences.setMockInitialValues(saved);
  return SettingsRepository(await SharedPreferences.getInstance());
}

void main() {
  group('SettingsRepository', () {
    test('loads defaults when nothing is saved', () async {
      final repository = await _repository();

      expect(repository.load(), const AppSettings());
      expect(repository.load().palette, ZemaPalette.nightVigil);
      expect(repository.load().themeMode, ThemeMode.system);
      expect(repository.load().languageCode, isNull);
    });

    test('round-trips the theme mode', () async {
      final repository = await _repository();

      await repository.saveThemeMode(ThemeMode.light);

      final reloaded = SettingsRepository(
        await SharedPreferences.getInstance(),
      );
      expect(reloaded.load().themeMode, ThemeMode.light);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('themeMode'), 'light');
    });

    test('falls back to System for an unknown saved theme mode', () async {
      final repository = await _repository({'themeMode': 'sepia'});

      expect(repository.load().themeMode, ThemeMode.system);
    });

    test('round-trips the palette', () async {
      final repository = await _repository();

      await repository.savePalette(ZemaPalette.wine);

      final reloaded = SettingsRepository(
        await SharedPreferences.getInstance(),
      );
      expect(reloaded.load().palette, ZemaPalette.wine);
    });

    test('round-trips the language', () async {
      final repository = await _repository();

      await repository.saveLanguage('am');

      final reloaded = SettingsRepository(
        await SharedPreferences.getInstance(),
      );
      expect(reloaded.load().languageCode, 'am');
    });

    test('stores values under paletteId and localeCode', () async {
      final repository = await _repository();

      await repository.savePalette(ZemaPalette.wine);
      await repository.saveLanguage('ti');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('paletteId'), 'wine');
      expect(prefs.getString('localeCode'), 'ti');
    });

    test('loads values saved by a previous run', () async {
      final repository = await _repository({
        'paletteId': 'wine',
        'themeMode': 'dark',
        'localeCode': 'om',
      });

      expect(
        repository.load(),
        const AppSettings(
          palette: ZemaPalette.wine,
          themeMode: ThemeMode.dark,
          languageCode: 'om',
        ),
      );
    });

    test('falls back to Night Vigil for an unknown saved palette', () async {
      final repository = await _repository({'paletteId': 'purple'});

      expect(repository.load().palette, ZemaPalette.nightVigil);
    });
  });

  group('AppSettings', () {
    test('copyWith replaces only the given fields', () {
      const settings = AppSettings(languageCode: 'am');

      expect(
        settings.copyWith(palette: ZemaPalette.wine),
        const AppSettings(palette: ZemaPalette.wine, languageCode: 'am'),
      );
      expect(settings.copyWith(languageCode: 'ti').palette, settings.palette);
    });
  });
}
