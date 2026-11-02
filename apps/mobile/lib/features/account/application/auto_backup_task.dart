import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zema_data/zema_data.dart';

import '../../../app/backend/backend_config.dart';
import '../../../app/database/zema_database.dart';
import '../../settings/data/settings_repository.dart';
import '../data/backup_builder.dart';
import '../data/backup_status.dart';
import '../data/secure_session_store.dart';
import 'auto_backup.dart';
import 'backup_service.dart';

final _log = Logger('account.auto_backup_task');

/// How often the background task wakes to check; it backs up only when
/// [autoBackupDue].
const _checkEvery = Duration(hours: 6);

/// Schedules the background auto backup: Android's WorkManager on an
/// unmetered network, iOS background refresh (best effort). Does nothing
/// in builds without a backend or on other platforms.
Future<void> scheduleAutoBackup() async {
  if (!const BackendConfig.fromEnvironment().isConfigured) return;
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    return;
  }
  try {
    await Workmanager().initialize(autoBackupDispatcher);
    await Workmanager().registerPeriodicTask(
      autoBackupTask,
      autoBackupTask,
      frequency: _checkEvery,
      constraints: Constraints(networkType: NetworkType.unmetered),
      // Keeps the schedule, and applies a changed one after an update.
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  } on Object catch (e) {
    _log.warning('Scheduling auto backup failed', e);
  }
}

/// The background task's entry point.
@pragma('vm:entry-point')
void autoBackupDispatcher() {
  Workmanager().executeTask((task, _) async {
    try {
      await runAutoBackupTask();
    } on Object catch (e) {
      _log.warning('Auto backup task failed', e);
    }
    // Failures are recorded in the backup status; WorkManager needn't retry.
    return true;
  });
}

/// One background check. When the app is running in this process (e.g.
/// playing music), it is asked to back up with its own session: two
/// clients refreshing the same session would revoke it. Otherwise this
/// isolate signs in from the saved session and backs up itself.
Future<void> runAutoBackupTask() async {
  final app = IsolateNameServer.lookupPortByName(autoBackupPortName);
  if (app != null) {
    app.send(null);
    return;
  }
  const config = BackendConfig.fromEnvironment();
  if (!config.isConfigured) return;
  final prefs = await SharedPreferences.getInstance();
  final auth = SupabaseAuthRepository(
    url: config.url,
    key: config.key,
    store: SecureSessionStore(),
  );
  final database = ZemaDatabase.open();
  try {
    final user = await auth.restore();
    final settings = SettingsRepository(prefs).load();
    final store = BackupStatusStore(prefs);
    await runAutoBackup(
      userId: user?.id,
      service: BackupService(
        repository: SupabaseBackupRepository(auth),
        builder: backupBuilderOf(database, prefs),
        store: store,
        settings: () => settings,
      ),
      store: store,
      unmetered: isUnmetered,
    );
  } finally {
    await auth.close();
    await database.close();
  }
}
