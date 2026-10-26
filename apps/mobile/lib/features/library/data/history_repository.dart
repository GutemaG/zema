import 'package:clock/clock.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/history_dao.dart';

/// Play history. Store failures surface as [DatabaseFailure].
class HistoryRepository {
  HistoryRepository(this._dao);

  /// Plays older than this are pruned at start.
  static const retention = Duration(days: 365);

  final HistoryDao _dao;

  Future<void> recordPlay(int trackId) =>
      _guard(_dao.recordPlay(trackId, at: clock.now()));

  /// Deletes plays older than [retention]; returns how many.
  Future<int> prune() =>
      _guard(_dao.pruneBefore(clock.now().subtract(retention)));

  /// Played track IDs, most plays first.
  Stream<List<int>> watchMostPlayed() => _dao.watchMostPlayed();

  /// Played track IDs once each, the one played last first.
  Stream<List<int>> watchRecentlyPlayed() => _dao.watchRecentlyPlayed();

  Future<T> _guard<T>(Future<T> operation) async {
    try {
      return await operation;
    } catch (e) {
      throw DatabaseFailure('Saving play history failed', cause: e);
    }
  }
}
