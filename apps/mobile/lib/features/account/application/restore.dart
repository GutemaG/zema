import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../../../app/database/restore_dao.dart';
import '../../library/application/library_sync_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../data/backup_builder.dart';
import 'account_providers.dart';
import 'backup.dart';

final _log = Logger('account.restore');

/// Merges a backup into this phone: the library in one transaction (see
/// [RestoreDao.merge]), then the backup's settings.
final backupRestorerProvider = Provider<BackupRestorer>(
  (ref) => BackupRestorer(ref),
);

class BackupRestorer {
  BackupRestorer(this._ref);

  final Ref _ref;

  /// Restores [document]. The entries not found are kept on this phone
  /// (unless [keepUnmatched] says otherwise), in the same transaction.
  /// Settings are applied only once the library is merged; if the merge
  /// throws, nothing changes.
  Future<RestoreReport> restore(
    BackupDocument document, {
    Future<void> Function(List<UnmatchedEntry> notFound)? keepUnmatched,
  }) async {
    final database = _ref.read(databaseProvider);
    final report = await database.restoreDao.merge(
      document,
      keepUnmatched: keepUnmatched ?? database.unmatchedDao.addAll,
    );
    final settings = _ref.read(settingsProvider.notifier);
    await settings.replaceAll(
      settingsFromBackup(document.settings, _ref.read(settingsProvider)),
    );
    return report;
  }

  /// Tries the kept entries again, e.g. after a scan found new songs: the
  /// ones found are added, the rest stay kept. Entries of playlists deleted
  /// on this phone are dropped. How many were added.
  Future<int> retryUnmatched() async {
    final database = _ref.read(databaseProvider);
    final entries = await database.unmatchedDao.all();
    if (entries.isEmpty) return 0;
    final playlists = {
      for (final row in await database.select(database.playlists).get())
        row.nameKey: row.name,
    };
    final byPlaylist = <String, List<TrackIdentity>>{};
    for (final e in entries) {
      if (e.kind != BackupEntryKind.playlist) continue;
      final name = playlists[playlistNameKey(e.playlist!)];
      if (name != null) byPlaylist.putIfAbsent(name, () => []).add(e.track);
    }
    final document = BackupDocument(
      createdAt: DateTime.now().toUtc(),
      favorites: [
        for (final e in entries)
          if (e.kind == BackupEntryKind.favorite)
            BackupFavorite(track: e.track, addedAt: e.addedAt!),
      ],
      playlists: [
        for (final MapEntry(:key, :value) in byPlaylist.entries)
          BackupPlaylist(name: key, tracks: value),
      ],
      lyricsChoices: [
        for (final e in entries)
          if (e.kind == BackupEntryKind.lyricsChoice)
            BackupLyricsChoice(track: e.track, songId: e.songId),
      ],
      hiddenTracks: [
        for (final e in entries)
          if (e.kind == BackupEntryKind.hiddenTrack) e.track,
      ],
    );
    // Keeps the original entries (with their positions) still not found.
    final report = await database.restoreDao.merge(
      document,
      keepUnmatched: (notFound) {
        final missing = notFound.map(_retryKey).toSet();
        return database.unmatchedDao.replaceAll([
          for (final e in entries)
            if (missing.contains(_retryKey(e))) e,
        ]);
      },
    );
    return report.favoritesAdded +
        report.playlistSongsAdded +
        report.lyricsChoicesAdded +
        report.hiddenAdded;
  }
}

/// An entry without its playlist position, which a retry doesn't keep.
Object _retryKey(UnmatchedEntry e) => (
  e.kind,
  e.track,
  e.addedAt,
  e.songId,
  e.playlist == null ? null : playlistNameKey(e.playlist!),
);

/// Tries the kept entries again after every library scan. Kept alive by
/// the app.
final unmatchedRetryProvider = Provider<void>((ref) {
  ref.listen(librarySyncProvider, (previous, next) {
    if ((previous?.isScanning ?? false) &&
        !next.isScanning &&
        next.lastResult != null) {
      unawaited(
        ref
            .read(backupRestorerProvider)
            .retryUnmatched()
            .then(
              (added) => _log.info('Re-tried songs not found: $added added'),
              onError: (Object e) => _log.warning('Retry failed', e),
            ),
      );
    }
  });
});

/// Whether the signed-in user has a cloud backup this phone hasn't saved
/// or restored, i.e. one to offer on S26 after sign-in. False offline.
Future<bool> restoreToOffer(Ref ref) async {
  final userId = ref.read(authRepositoryProvider)?.currentUser?.id;
  final backups = ref.read(backupRepositoryProvider);
  if (userId == null || backups == null) return false;
  try {
    final cloud = await backups.savedAt();
    if (cloud == null) return false;
    final status = await ref.read(backupStatusStoreProvider).read(userId);
    return cloud != status.syncedAt;
  } on Object catch (e) {
    _log.info('Checking for a backup failed', e);
    return false;
  }
}

/// Whether to open S26 after a sign-in. Tests override it.
final restoreToOfferProvider = Provider<Future<bool> Function()>(
  (ref) =>
      () => restoreToOffer(ref),
);

/// What S26 shows.
sealed class RestoreState {
  const RestoreState();
}

final class RestoreLoading extends RestoreState {
  const RestoreLoading();
}

/// The cloud backup, ready to restore.
final class RestoreFound extends RestoreState {
  const RestoreFound(this.backup);

  final StoredBackup backup;
}

/// There is no cloud backup.
final class RestoreNone extends RestoreState {
  const RestoreNone();
}

/// The backup couldn't be read: offline, refused, or from a newer app.
final class RestoreError extends RestoreState {
  const RestoreError(this.failure);

  final Object failure;
}

/// Restoring; [waitingForScan] while the library is first scanned.
final class RestoreRunning extends RestoreState {
  const RestoreRunning({this.waitingForScan = false});

  final bool waitingForScan;
}

final class RestoreDone extends RestoreState {
  const RestoreDone(this.report);

  final RestoreReport report;
}

final restoreProvider =
    NotifierProvider.autoDispose<RestoreController, RestoreState>(
      RestoreController.new,
    );

/// S26: finds the cloud backup, then restores it or starts fresh.
class RestoreController extends Notifier<RestoreState> {
  @override
  RestoreState build() {
    scheduleMicrotask(() => unawaited(load()));
    return const RestoreLoading();
  }

  /// Downloads the cloud backup.
  Future<void> load() async {
    final backups = ref.read(backupRepositoryProvider);
    if (backups == null) {
      state = const RestoreNone();
      return;
    }
    state = const RestoreLoading();
    try {
      final backup = await backups.fetch();
      if (!ref.mounted) return;
      state = backup == null ? const RestoreNone() : RestoreFound(backup);
    } on Object catch (e) {
      _log.warning('Loading the backup failed', e);
      if (ref.mounted) state = RestoreError(e);
    }
  }

  /// Merges the backup into this phone, after the first library scan if
  /// there hasn't been one. This phone then counts as having the cloud
  /// backup, so its next backup replaces it without asking.
  Future<void> restore() async {
    final found = state;
    final userId = ref.read(authUserProvider).value?.id;
    if (found is! RestoreFound || userId == null) return;
    if (ref.read(librarySyncProvider).lastResult == null) {
      state = const RestoreRunning(waitingForScan: true);
      await ref.read(librarySyncProvider.notifier).sync();
      if (!ref.mounted) return;
    }
    state = const RestoreRunning();
    try {
      final report = await ref
          .read(backupRestorerProvider)
          .restore(found.backup.document);
      final store = ref.read(backupStatusStoreProvider);
      await store.write(
        userId,
        (await store.read(userId))
            .copyWith(syncedAt: found.backup.savedAt, lastError: () => null),
      );
      unawaited(ref.read(backupProvider.notifier).refresh());
      if (ref.mounted) state = RestoreDone(report);
    } on Object catch (e) {
      _log.warning('Restore failed', e);
      if (ref.mounted) state = RestoreError(e);
    }
  }
}
