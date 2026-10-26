import 'package:clock/clock.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/lyrics_links_dao.dart';

/// A track's link to a lyrics song.
class LyricsLink {
  const LyricsLink({required this.songId, required this.manual});

  /// Null for a manual "no lyrics".
  final String? songId;

  /// Chosen by the user; automatic matching leaves it alone.
  final bool manual;
}

/// Links from tracks to lyrics songs. Store failures surface as
/// [DatabaseFailure].
class LyricsLinksRepository {
  LyricsLinksRepository(this._dao);

  final LyricsLinksDao _dao;

  /// Every link, by track ID.
  Stream<Map<int, LyricsLink>> watchLinks() => _dao.watchLinks().map(
    (rows) => {
      for (final row in rows)
        row.trackId: LyricsLink(songId: row.songId, manual: row.manual),
    },
  );

  /// Links [trackId] to [songId] by hand; null means no lyrics.
  Future<void> setManual(int trackId, String? songId) =>
      _guard(_dao.setManual(trackId, songId, at: clock.now()));

  /// Makes the automatic links exactly [links]; manual ones stay.
  Future<void> replaceAutomatic(Map<int, String> links) =>
      _guard(_dao.replaceAutomatic(links, at: clock.now()));

  Future<T> _guard<T>(Future<T> operation) async {
    try {
      return await operation;
    } catch (e) {
      throw DatabaseFailure('Saving lyrics links failed', cause: e);
    }
  }
}
