import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/backend/backend_providers.dart';
import '../../../app/database/catalog_dao.dart';
import '../../../app/database/database_provider.dart';
import '../../../app/database/reports_dao.dart';
import '../../../app/preferences_provider.dart';
import 'catalog_index.dart';

final _log = Logger('catalog.reports');

/// What became of a report.
enum ReportOutcome {
  /// The catalog accepted it.
  sent,

  /// The catalog couldn't be reached; it waits on the phone.
  queued,

  /// This install has sent the most reports for today.
  limited,

  /// The catalog refused it for good, so it isn't kept.
  failed,
}

/// This install's random ID, which the daily report limit counts by (the
/// server stores only its hash). Created on first use and kept.
String installId(SharedPreferences preferences) {
  const key = 'catalog.installId';
  final saved = preferences.getString(key);
  if (saved != null) return saved;
  final random = Random.secure();
  final id = [
    for (var i = 0; i < 16; i++)
      random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
  unawaited(preferences.setString(key, id));
  return id;
}

/// Sends reports of wrong lyrics to the catalog, keeping those made offline
/// until it can be reached.
class ReportSender {
  ReportSender({
    required this._catalog,
    required this._reports,
    required this._index,
    required this._preferences,
  });

  final CatalogRepository? _catalog;
  final ReportsDao _reports;
  final CatalogDao _index;
  final SharedPreferences _preferences;
  Future<void>? _flushing;

  /// Sends [report] after any waiting ones. Offline it is queued; past the
  /// daily limit, or refused, it is not.
  Future<ReportOutcome> send(LyricsReport report) async {
    final catalog = _catalog;
    if (catalog == null) return ReportOutcome.failed;
    await flush();
    try {
      await _report(catalog, report);
      return ReportOutcome.sent;
    } on NetworkFailure catch (e) {
      _log.info('Report queued', e);
      await _reports.add(report);
      return ReportOutcome.queued;
    } on RateLimitFailure catch (e) {
      _log.info('Report refused: daily limit', e);
      return ReportOutcome.limited;
    } on ZemaFailure catch (e) {
      _log.warning('Report refused', e);
      return ReportOutcome.failed;
    }
  }

  /// Sends the waiting reports, oldest first. A report whose song has left
  /// the index, or that the catalog refuses for good, is dropped; offline
  /// or past the limit, the rest wait for next time. Runs once at a time.
  Future<void> flush() => _flushing ??= _flush().whenComplete(() {
    _flushing = null;
  });

  Future<void> _flush() async {
    final catalog = _catalog;
    if (catalog == null) return;
    final queued = await _reports.all();
    if (queued.isEmpty) return;
    final songs = {for (final e in await _index.watchEntries().first) e.id};
    for (final (:id, :report) in queued) {
      if (!songs.contains(report.songId)) {
        _log.info(
          'Dropped a queued report for ${report.songId}: not in the '
          'index',
        );
        await _reports.remove(id);
        continue;
      }
      try {
        await _report(catalog, report);
      } on NetworkFailure catch (e) {
        _log.info('Queued reports wait: offline', e);
        return;
      } on RateLimitFailure catch (e) {
        _log.info('Queued reports wait: daily limit', e);
        return;
      } on ZemaFailure catch (e) {
        _log.warning('Dropped a queued report the catalog refused', e);
      }
      await _reports.remove(id);
    }
  }

  Future<void> _report(CatalogRepository catalog, LyricsReport report) =>
      catalog.report(
        songId: report.songId,
        reason: report.reason,
        installId: installId(_preferences),
        recordingId: report.recordingId,
        note: report.note,
      );
}

final reportSenderProvider = Provider<ReportSender>(
  (ref) => ReportSender(
    catalog: ref.watch(catalogRepositoryProvider),
    reports: ref.watch(databaseProvider).reportsDao,
    index: ref.watch(databaseProvider).catalogDao,
    preferences: ref.watch(sharedPreferencesProvider),
  ),
);

/// Sends reports queued offline once when the app starts. Kept alive by the
/// app shell.
final reportStartupFlushProvider = Provider<void>((ref) {
  unawaited(
    ref
        .read(reportSenderProvider)
        .flush()
        .catchError(
          (Object e) => _log.warning('Queued reports not sent', e),
          test: (e) => e is ZemaFailure,
        ),
  );
});

/// Whether the song [songId] can be reported: the build has a backend and
/// the song is in the catalog's index.
final canReportProvider = Provider.family<bool, String>((ref, songId) {
  if (ref.watch(catalogRepositoryProvider) == null) return false;
  final index = ref.watch(catalogEntriesProvider).value ?? const [];
  return index.any((e) => e.id == songId);
});
