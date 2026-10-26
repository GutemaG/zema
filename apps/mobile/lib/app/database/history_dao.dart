import 'package:drift/drift.dart';

import 'tables.dart';
import 'zema_database.dart';

part 'history_dao.g.dart';

/// Play history: one row per counted play. Rows point at tracks by Zema's
/// ID, which a rescan keeps, so history survives rescans.
///
/// Dates are compared with `julianday()`, which reads every stored form of
/// the ISO-8601 text (UTC or with an offset).
@DriftAccessor(tables: [PlayEvents])
class HistoryDao extends DatabaseAccessor<ZemaDatabase> with _$HistoryDaoMixin {
  HistoryDao(super.attachedDatabase);

  Future<void> recordPlay(int trackId, {DateTime? at}) =>
      into(playEvents).insert(
        PlayEventsCompanion.insert(
          trackId: trackId,
          playedAt: (at ?? DateTime.now()).toUtc(),
        ),
      );

  /// Deletes plays before [cutoff]; returns how many.
  Future<int> pruneBefore(DateTime cutoff) => customUpdate(
    'DELETE FROM play_events WHERE julianday(played_at) < julianday(?1)',
    variables: [Variable.withString(cutoff.toUtc().toIso8601String())],
    updates: {playEvents},
    updateKind: UpdateKind.delete,
  );

  /// Every played track's ID, most plays first; ties go to the one played
  /// last.
  Stream<List<int>> watchMostPlayed() => _watchIds('''
    SELECT track_id FROM play_events
    GROUP BY track_id
    ORDER BY COUNT(*) DESC, MAX(julianday(played_at)) DESC, MAX(id) DESC
    ''');

  /// Every played track's ID once, the one played last first.
  Stream<List<int>> watchRecentlyPlayed() => _watchIds('''
    SELECT track_id FROM play_events
    GROUP BY track_id
    ORDER BY MAX(julianday(played_at)) DESC, MAX(id) DESC
    ''');

  Stream<List<int>> _watchIds(String sql) => customSelect(
    sql,
    readsFrom: {playEvents},
  ).watch().map((rows) => [for (final row in rows) row.read<int>('track_id')]);
}
