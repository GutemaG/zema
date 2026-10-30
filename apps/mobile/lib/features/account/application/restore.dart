import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../../../app/database/restore_dao.dart';
import '../../settings/application/settings_controller.dart';
import '../data/backup_builder.dart';

/// Merges a backup into this phone: the library in one transaction (see
/// [RestoreDao.merge]), then the backup's settings.
final backupRestorerProvider = Provider<BackupRestorer>(
  (ref) => BackupRestorer(ref),
);

class BackupRestorer {
  BackupRestorer(this._ref);

  final Ref _ref;

  /// Restores [document]. [keepUnmatched] runs inside the library's
  /// transaction with the entries not found. Settings are applied only
  /// once the library is merged; if the merge throws, nothing changes.
  Future<RestoreReport> restore(
    BackupDocument document, {
    Future<void> Function(List<UnmatchedEntry> notFound)? keepUnmatched,
  }) async {
    final report = await _ref
        .read(databaseProvider)
        .restoreDao
        .merge(document, keepUnmatched: keepUnmatched);
    final settings = _ref.read(settingsProvider.notifier);
    await settings.replaceAll(
      settingsFromBackup(document.settings, _ref.read(settingsProvider)),
    );
    return report;
  }
}
