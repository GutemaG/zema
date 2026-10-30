import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../settings/data/app_settings.dart';
import '../data/backup_builder.dart';
import '../data/backup_status.dart';

final _log = Logger('account.backup');

/// How a backup run ended.
enum BackupOutcome {
  /// Uploaded; the cloud backup is this phone's.
  done,

  /// Nothing changed since the last backup, so nothing was uploaded.
  unchanged,

  /// The cloud holds another phone's backup; nothing was uploaded.
  otherBackup,

  /// The server couldn't be reached; the cloud backup is unchanged.
  offline,

  /// The server refused or failed; the cloud backup is unchanged.
  failed,
}

/// A backup run's [outcome]; for [BackupOutcome.otherBackup], when the
/// cloud backup was saved.
typedef BackupResult = ({BackupOutcome outcome, DateTime? otherSavedAt});

/// Builds the backup document and uploads it, keeping the user's
/// [BackupStatus]. Plain Dart over its parts, so the background task can
/// run it without the app.
class BackupService {
  BackupService({
    required this.repository,
    required this.builder,
    required this.store,
    required this.settings,
  });

  final BackupRepository repository;
  final BackupBuilder builder;
  final BackupStatusStore store;

  /// The current settings, read when the document is built.
  final AppSettings Function() settings;

  /// Backs up [userId]'s library and settings.
  ///
  /// A cloud backup this phone didn't make is replaced only with [replace].
  /// With [skipUnchanged] (auto backup), a library unchanged since this
  /// phone's last backup isn't uploaded again.
  Future<BackupResult> backUp(
    String userId, {
    bool replace = false,
    bool skipUnchanged = false,
  }) async {
    var status = await store.read(userId);
    try {
      final document = await builder.build(settings());
      final hash = backupContentHash(document);
      if (skipUnchanged &&
          status.syncedAt != null &&
          status.contentHash == hash) {
        return (outcome: BackupOutcome.unchanged, otherSavedAt: null);
      }
      final cloud = await repository.savedAt();
      if (cloud != null && cloud != status.syncedAt && !replace) {
        status = status.copyWith(lastError: () => BackupError.otherBackup);
        return (outcome: BackupOutcome.otherBackup, otherSavedAt: cloud);
      }
      final savedAt = await repository.save(document);
      status = status.copyWith(
        lastBackupAt: savedAt,
        syncedAt: savedAt,
        contentHash: hash,
        lastError: () => null,
      );
      return (outcome: BackupOutcome.done, otherSavedAt: null);
    } on NetworkFailure catch (e) {
      _log.info('Backup offline', e);
      status = status.copyWith(lastError: () => BackupError.offline);
      return (outcome: BackupOutcome.offline, otherSavedAt: null);
    } on Object catch (e) {
      _log.warning('Backup failed', e);
      status = status.copyWith(lastError: () => BackupError.failed);
      return (outcome: BackupOutcome.failed, otherSavedAt: null);
    } finally {
      await store.write(userId, status);
    }
  }
}

/// A hash of [document]'s content, leaving out when it was made: equal for
/// two backups of an unchanged library. FNV-1a, stable across runs.
int backupContentHash(BackupDocument document) {
  final json = document.toJson()..remove('createdAt');
  var hash = 0xcbf29ce484222325;
  for (final byte in utf8.encode(jsonEncode(json))) {
    hash = ((hash ^ byte) * 0x100000001b3) & 0x7fffffffffffffff;
  }
  return hash;
}
