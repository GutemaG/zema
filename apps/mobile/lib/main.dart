import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import 'app/licenses.dart';
import 'app/zema_app.dart';
import 'features/settings/application/settings_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _setUpLogging();
  registerFontLicenses();

  // Load settings before the first frame so the saved palette and language
  // are used from the start (no flash of the defaults).
  final settingsOverrides = await loadSettingsOverrides();

  runApp(ProviderScope(overrides: settingsOverrides, child: const ZemaApp()));
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
