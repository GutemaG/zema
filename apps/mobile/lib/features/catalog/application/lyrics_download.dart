import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/cached_songs_dao.dart';
import '../../../app/database/database_provider.dart';
import '../../lyrics/application/lyrics_links.dart';
import '../data/catalog_lyrics_repository.dart';
import 'catalog_index.dart';

final _log = Logger('catalog.download');

/// Where Download all is.
enum LyricsDownloadStatus { idle, running, finished, cancelled, failed }

/// Download all's progress: [done] of [total] songs saved or already up to
/// date. [total] is 0 while the index is being checked.
class LyricsDownload {
  const LyricsDownload({
    this.status = LyricsDownloadStatus.idle,
    this.done = 0,
    this.total = 0,
    this.failure,
  });

  final LyricsDownloadStatus status;
  final int done;
  final int total;

  /// Why the download stopped, when [status] is failed.
  final ZemaFailure? failure;

  bool get running => status == LyricsDownloadStatus.running;

  @override
  String toString() => 'LyricsDownload(${status.name} $done/$total)';
}

/// Download all lyrics for offline: saves every song in the index, a few at
/// a time. Kept alive, so it goes on after leaving Settings.
class LyricsDownloader extends Notifier<LyricsDownload> {
  /// Songs fetched at the same time.
  static const batchSize = 4;

  var _cancelled = false;

  @override
  LyricsDownload build() => const LyricsDownload();

  /// Downloads every song the index lists that isn't cached at its
  /// version. Does nothing while a download runs.
  ///
  /// The index is refreshed first if it is stale; offline, the saved one is
  /// used. Cancel takes effect between batches, so a started song is never
  /// left half-saved. A failure stops the download and keeps every song
  /// that finished.
  Future<void> start() async {
    if (state.running) return;
    _cancelled = false;
    state = const LyricsDownload(status: LyricsDownloadStatus.running);
    try {
      await ref.read(catalogIndexRefresherProvider).refresh();
    } on ZemaFailure catch (e) {
      _log.info('Downloading with the saved index', e);
    }
    final entries = await ref
        .read(databaseProvider)
        .catalogDao
        .watchEntries()
        .first;
    final repository = ref.read(lyricsRepositoryProvider);
    final total = entries.length;
    var done = 0;
    state = LyricsDownload(status: LyricsDownloadStatus.running, total: total);
    for (var i = 0; i < total; i += batchSize) {
      if (_cancelled) {
        state = LyricsDownload(
          status: LyricsDownloadStatus.cancelled,
          done: done,
          total: total,
        );
        return;
      }
      ZemaFailure? failure;
      Future<void> one(String id) async {
        try {
          await repository.download(id);
          done++;
        } on ZemaFailure catch (e) {
          failure ??= e;
        }
      }

      await Future.wait([
        for (final entry in entries.skip(i).take(batchSize)) one(entry.id),
      ]);
      if (failure case final failure?) {
        _log.info('Download all stopped at $done of $total', failure);
        state = LyricsDownload(
          status: LyricsDownloadStatus.failed,
          done: done,
          total: total,
          failure: failure,
        );
        return;
      }
      state = LyricsDownload(
        status: LyricsDownloadStatus.running,
        done: done,
        total: total,
      );
    }
    state = LyricsDownload(
      status: LyricsDownloadStatus.finished,
      done: done,
      total: total,
    );
  }

  /// Stops the download after the batch in progress.
  void cancel() => _cancelled = true;

  /// Deletes every downloaded song; links and the index stay. Open songs
  /// are read again, so nothing cleared is still shown.
  Future<void> clear() async {
    if (state.running) return;
    await ref.read(lyricsRepositoryProvider).clearCache();
    ref.invalidate(songProvider);
    state = const LyricsDownload();
  }
}

final lyricsDownloaderProvider =
    NotifierProvider<LyricsDownloader, LyricsDownload>(LyricsDownloader.new);

/// The space downloaded lyrics take.
final lyricsUsageProvider = StreamProvider<LyricsUsage>(
  (ref) => ref.watch(databaseProvider).cachedSongsDao.watchUsage(),
);
