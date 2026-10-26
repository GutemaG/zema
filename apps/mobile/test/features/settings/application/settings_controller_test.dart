import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:zema/app/l10n/app_language.dart';
import 'package:zema/app/l10n/language_providers.dart';
import 'package:zema/app/theme/palette_provider.dart';
import 'package:zema/app/theme/zema_palette.dart';
import 'package:zema/features/settings/application/settings_controller.dart';
import 'package:zema/features/settings/data/app_settings.dart';
import 'package:zema/features/settings/data/settings_repository.dart';

/// Records saves; optionally fails every write.
class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({this.fail = false});

  final bool fail;
  final saves = <String>[];

  @override
  AppSettings load() => const AppSettings();

  @override
  Future<void> savePalette(ZemaPalette palette) async {
    if (fail) {
      throw const SettingsWriteException(SettingsRepository.paletteKey);
    }
    saves.add('palette:${palette.name}');
  }

  @override
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    if (fail) {
      throw const SettingsWriteException(SettingsRepository.themeModeKey);
    }
    saves.add('themeMode:${themeMode.name}');
  }

  @override
  Future<void> saveLanguage(String languageCode) async {
    if (fail) {
      throw const SettingsWriteException(SettingsRepository.languageKey);
    }
    saves.add('language:$languageCode');
  }

  void _record(String key, String save) {
    if (fail) throw SettingsWriteException(key);
    saves.add(save);
  }

  @override
  Future<void> saveMinTrackSeconds(int seconds) async =>
      _record(SettingsRepository.minTrackSecondsKey, 'minTrack:$seconds');

  @override
  Future<void> saveSleepTimerDefault(SleepTimerDefault value) async =>
      _record(SettingsRepository.sleepTimerDefaultKey, 'sleep:${value.name}');

  @override
  Future<void> savePauseOnUnplug(bool value) async =>
      _record(SettingsRepository.pauseOnUnplugKey, 'unplug:$value');

  @override
  Future<void> saveDuckOnInterruption(bool value) async =>
      _record(SettingsRepository.duckOnInterruptionKey, 'duck:$value');

  @override
  Future<void> saveGapless(bool value) async =>
      _record(SettingsRepository.gaplessKey, 'gapless:$value');
}

ProviderContainer _container(
  SettingsRepository repository, {
  AppSettings initial = const AppSettings(),
}) {
  final container = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(repository),
      initialSettingsProvider.overrideWithValue(initial),
      deviceLocalesProvider.overrideWithValue(const []),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('SettingsController', () {
    test('starts with the settings loaded before runApp', () {
      const initial = AppSettings(
        palette: ZemaPalette.wine,
        languageCode: 'am',
      );
      final container = _container(_FakeSettingsRepository(), initial: initial);

      expect(container.read(settingsProvider), initial);
      expect(container.read(paletteProvider), ZemaPalette.wine);
      expect(container.read(appLanguageProvider), AppLanguage.am);
    });

    test('setPalette updates state and saves it', () async {
      final repository = _FakeSettingsRepository();
      final container = _container(repository);

      await container
          .read(settingsProvider.notifier)
          .setPalette(ZemaPalette.wine);

      expect(container.read(paletteProvider), ZemaPalette.wine);
      expect(repository.saves, ['palette:wine']);
    });

    test('setThemeMode updates the theme mode and saves it', () async {
      final repository = _FakeSettingsRepository();
      final container = _container(repository);

      await container
          .read(settingsProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(repository.saves, ['themeMode:dark']);
    });

    test('setLanguage updates the active language and saves it', () async {
      final repository = _FakeSettingsRepository();
      final container = _container(repository);

      await container.read(settingsProvider.notifier).setLanguage('ti');

      expect(container.read(appLanguageProvider), AppLanguage.ti);
      expect(repository.saves, ['language:ti']);
    });

    test('library and playback setters update state and save', () async {
      final repository = _FakeSettingsRepository();
      final container = _container(repository);
      final controller = container.read(settingsProvider.notifier);

      await controller.setMinTrackSeconds(10);
      await controller.setSleepTimerDefault(SleepTimerDefault.minutes45);
      await controller.setPauseOnUnplug(false);
      await controller.setDuckOnInterruption(true);
      await controller.setGapless(false);
      // Unchanged values are not saved again.
      await controller.setMinTrackSeconds(10);
      await controller.setGapless(false);

      expect(
        container.read(settingsProvider),
        const AppSettings(
          minTrackSeconds: 10,
          sleepTimerDefault: SleepTimerDefault.minutes45,
          pauseOnUnplug: false,
          duckOnInterruption: true,
          gapless: false,
        ),
      );
      expect(repository.saves, [
        'minTrack:10',
        'sleep:minutes45',
        'unplug:false',
        'duck:true',
        'gapless:false',
      ]);
    });

    test('picking the current value does not save again', () async {
      final repository = _FakeSettingsRepository();
      final container = _container(
        repository,
        initial: const AppSettings(languageCode: 'am'),
      );
      final controller = container.read(settingsProvider.notifier);

      await controller.setPalette(ZemaPalette.nightVigil);
      await controller.setThemeMode(ThemeMode.system);
      await controller.setLanguage('am');

      expect(repository.saves, isEmpty);
    });

    test('a failed save keeps the new value and logs a warning', () async {
      final records = <LogRecord>[];
      final subscription = Logger.root.onRecord.listen(records.add);
      addTearDown(subscription.cancel);
      final container = _container(_FakeSettingsRepository(fail: true));

      await container
          .read(settingsProvider.notifier)
          .setPalette(ZemaPalette.wine);
      await container.read(settingsProvider.notifier).setLanguage('om');
      await container
          .read(settingsProvider.notifier)
          .setThemeMode(ThemeMode.light);

      expect(container.read(paletteProvider), ZemaPalette.wine);
      expect(container.read(appLanguageProvider), AppLanguage.om);
      expect(container.read(themeModeProvider), ThemeMode.light);
      expect(records, hasLength(3));
      expect(records.map((r) => r.level), everyElement(Level.WARNING));
      expect(records.first.error, isA<SettingsWriteException>());
    });

    test('saving without a repository override fails loudly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(settingsRepositoryProvider),
        throwsA(
          predicate((e) => e.toString().contains('must be overridden in main')),
        ),
      );
    });
  });
}
