import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:zema_core/zema_core.dart';

import 'tables.dart';
import 'zema_database.dart';

part 'cached_songs_dao.g.dart';

/// A cached song: its document and the catalog version it was fetched at.
typedef CachedSong = ({SongDocument document, int version});

/// Lyrics downloaded from the catalog.
@DriftAccessor(tables: [CachedSongs])
class CachedSongsDao extends DatabaseAccessor<ZemaDatabase>
    with _$CachedSongsDaoMixin {
  CachedSongsDao(super.attachedDatabase);

  /// The cached song [id], or null. A row that no longer decodes counts as
  /// not cached.
  Future<CachedSong?> song(String id) async {
    final row = await (select(
      cachedSongs,
    )..where((s) => s.id.equals(id))).getSingleOrNull();
    return row == null ? null : _decode(row);
  }

  /// Saves [document] at [version], replacing any older copy.
  Future<void> save(SongDocument document, int version) =>
      into(cachedSongs).insertOnConflictUpdate(
        CachedSongsCompanion.insert(
          id: document.song.id,
          version: version,
          document: jsonEncode(document.toJson()),
          cachedAt: clock.now().toUtc(),
        ),
      );

  /// Every cached song, by ID.
  Stream<List<CachedSong>> watchSongs() =>
      (select(cachedSongs)..orderBy([(s) => OrderingTerm.asc(s.id)]))
          .watch()
          .map((rows) => [for (final row in rows) ?_decode(row)]);
}

CachedSong? _decode(CachedSongRow row) {
  try {
    return (
      document: SongDocument.fromJson(jsonDecode(row.document)),
      version: row.version,
    );
  } on Object {
    return null;
  }
}
