import 'package:drift/drift.dart';

import 'tables.dart';
import 'zema_database.dart';

part 'lyrics_links_dao.g.dart';

/// Links from tracks to lyrics songs, by Zema's track ID (kept across
/// rescans). A track's link goes with its row.
@DriftAccessor(tables: [LyricsLinks])
class LyricsLinksDao extends DatabaseAccessor<ZemaDatabase>
    with _$LyricsLinksDaoMixin {
  LyricsLinksDao(super.attachedDatabase);

  Stream<List<LyricsLinkRow>> watchLinks() => select(lyricsLinks).watch();

  /// The user's choice for [trackId]: [songId], or no lyrics when null.
  Future<void> setManual(int trackId, String? songId, {DateTime? at}) =>
      into(lyricsLinks).insertOnConflictUpdate(
        LyricsLinksCompanion.insert(
          trackId: Value(trackId),
          songId: Value(songId),
          manual: true,
          linkedAt: (at ?? DateTime.now()).toUtc(),
        ),
      );

  /// Makes the automatic links exactly [links] (track ID → song ID), in one
  /// transaction. Tracks with a manual link are left alone.
  Future<void> replaceAutomatic(Map<int, String> links, {DateTime? at}) =>
      transaction(() async {
        final manual = {
          for (final row in await (select(
            lyricsLinks,
          )..where((l) => l.manual)).get())
            row.trackId,
        };
        await (delete(lyricsLinks)..where((l) => l.manual.not())).go();
        final now = (at ?? DateTime.now()).toUtc();
        await batch((b) {
          b.insertAll(lyricsLinks, [
            for (final MapEntry(key: trackId, value: songId) in links.entries)
              if (!manual.contains(trackId))
                LyricsLinksCompanion.insert(
                  trackId: Value(trackId),
                  songId: Value(songId),
                  manual: false,
                  linkedAt: now,
                ),
          ]);
        });
      });
}
