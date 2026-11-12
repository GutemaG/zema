import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:logging/logging.dart';

import 'app/l10n/app_language.dart';
import 'app/licenses.dart';
import 'app/zema_app.dart';
import 'features/account/application/auto_backup_task.dart';
import 'features/identify/presentation/quick_listen_app.dart';
import 'features/player/application/player_providers.dart';
import 'features/player/data/audio_backend.dart';
import 'features/player/data/zema_audio_handler.dart';
import 'features/settings/application/settings_bootstrap.dart';
import 'features/settings/application/settings_controller.dart';
import 'l10n/generated/app_localizations.dart';

@pragma('vm:entry-point')
Future<void> listenMain() => runQuickListen();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setUpLogging();
  registerFontLicenses();

  // Load settings before the first frame so the saved palette and language
  // are used from the start (no flash of the defaults).
  final settingsOverrides = await loadSettingsOverrides();
  final player = await _startPlayer(settingsOverrides);

  runApp(
    ProviderScope(
      overrides: [
        ...settingsOverrides,
        audioHandlerProvider.overrideWithValue(player),
      ],
      child: const ZemaApp(),
    ),
  );
  unawaited(scheduleAutoBackup());
}

/// Starts the background playback service. The notification channel is
/// named in the app's language.
Future<ZemaAudioHandler> _startPlayer(List<Override> settingsOverrides) {
  final settings = ProviderContainer(overrides: settingsOverrides);
  final language = resolveInitialLanguage(
    saved: settings.read(settingsProvider).languageCode,
    deviceLocales: PlatformDispatcher.instance.locales,
  );
  settings.dispose();
  return AudioService.init(
    builder: () => ZemaAudioHandler(JustAudioBackend()),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.zemaapp.zema.playback',
      androidNotificationChannelName: lookupAppLocalizations(language.locale)
          .playbackChannelName,
      androidNotificationIcon: 'drawable/ic_launcher_monochrome',
      // Dismissing the notification while paused stops the service.
      androidStopForegroundOnPause: true,
    ),
  );
}

/// Prints log records in debug builds only.
void _setUpLogging() {
  if (!kDebugMode) {
    return;
  }
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint(
      '[${record.level.name}] ${record.loggerName}: ${record.message}'
      '${record.error == null ? '' : ' (${record.error})'}',
    );
  });
}
