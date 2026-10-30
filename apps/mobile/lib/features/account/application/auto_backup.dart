import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../data/backup_status.dart';
import 'account_providers.dart';
import 'backup.dart';
import 'backup_service.dart';

final _log = Logger('account.auto_backup');

/// The background task's ID, also its iOS BGTaskScheduler identifier.
const autoBackupTask = 'com.zemaapp.zema.autoBackup';

/// Where a running app listens for the background task, so the backup is
/// made with the app's own session (see `runAutoBackupTask`).
const autoBackupPortName = 'zema.autoBackup';

/// At most one auto backup per this long.
const autoBackupEvery = Duration(hours: 24);

/// Whether [status] calls for an auto backup at [now]: it is on, and the
/// last backup was at least [autoBackupEvery] ago (or never).
bool autoBackupDue(BackupStatus status, DateTime now) {
  final last = status.lastBackupAt;
  return status.autoBackup &&
      (last == null || !now.isBefore(last.add(autoBackupEvery)));
}

/// Backs up [userId]'s library if an auto backup is due and the phone is
/// on Wi-Fi ([unmetered]); an unchanged library is not uploaded again. The
/// outcome, or null when nothing was due (signed out, off, too soon or on
/// mobile data).
Future<BackupOutcome?> runAutoBackup({
  required String? userId,
  required BackupService service,
  required BackupStatusStore store,
  required Future<bool> Function() unmetered,
  DateTime Function() now = DateTime.now,
}) async {
  if (userId == null) return null;
  if (!autoBackupDue(await store.read(userId), now())) return null;
  if (!await unmetered()) return null;
  final result = await service.backUp(userId, skipUnchanged: true);
  _log.info('Auto backup: ${result.outcome.name}');
  return result.outcome;
}

/// Whether the phone is on Wi-Fi or Ethernet.
Future<bool> isUnmetered() async =>
    unmeteredConnection(await Connectivity().checkConnectivity());

/// Whether [kinds] include Wi-Fi or Ethernet. Mobile data alongside them
/// doesn't matter: the phone uses Wi-Fi first.
bool unmeteredConnection(List<ConnectivityResult> kinds) =>
    kinds.contains(ConnectivityResult.wifi) ||
    kinds.contains(ConnectivityResult.ethernet);

/// Whether the phone is on an unmetered network. Tests override it.
final unmeteredNetworkProvider = Provider<Future<bool> Function()>(
  (ref) => isUnmetered,
);

/// Runs a due auto backup while the app is open: when the user is known at
/// start, when the app comes back to the foreground, and when the
/// background task asks (see [autoBackupPortName]). Kept alive by the app.
final autoBackupProvider = Provider<AutoBackup>((ref) {
  final autoBackup = AutoBackup(ref);
  final port = ReceivePort();
  IsolateNameServer.removePortNameMapping(autoBackupPortName);
  IsolateNameServer.registerPortWithName(port.sendPort, autoBackupPortName);
  port.listen((_) => unawaited(autoBackup.runIfDue()));
  final lifecycle = AppLifecycleListener(
    onResume: () => unawaited(autoBackup.runIfDue()),
  );
  ref
    ..listen(authUserProvider, (_, next) {
      if (next.value != null) unawaited(autoBackup.runIfDue());
    }, fireImmediately: true)
    ..onDispose(() {
      lifecycle.dispose();
      IsolateNameServer.removePortNameMapping(autoBackupPortName);
      port.close();
    });
  return autoBackup;
});

class AutoBackup {
  AutoBackup(this._ref);

  final Ref _ref;
  bool _running = false;

  /// [runAutoBackup] for the signed-in user; one at a time.
  Future<BackupOutcome?> runIfDue() async {
    final service = _ref.read(backupServiceProvider);
    final userId = _ref.read(authUserProvider).value?.id;
    if (_running || service == null || userId == null) return null;
    _running = true;
    try {
      final outcome = await runAutoBackup(
        userId: userId,
        service: service,
        store: _ref.read(backupStatusStoreProvider),
        unmetered: _ref.read(unmeteredNetworkProvider),
      );
      if (outcome != null && _ref.mounted) {
        await _ref.read(backupProvider.notifier).refresh();
      }
      return outcome;
    } on Object catch (e) {
      _log.warning('Auto backup failed', e);
      return null;
    } finally {
      _running = false;
    }
  }
}
