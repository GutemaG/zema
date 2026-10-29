import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:zema_core/zema_core.dart';

import 'tables.dart';
import 'zema_database.dart';

part 'cached_songs_dao.g.dart';

/// A cached song: its document and the catalog version it was fetched at.
typedef CachedSong = ({SongDocument document, int version});

/// The space downloaded lyrics take: songs, and bytes of their documents.
typedef LyricsUsage = ({int songs, int bytes});

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

  /// How many songs are cached and how many bytes their documents take,
  /// updated after every save and clear.
  Stream<LyricsUsage> watchUsage() {
    final count = cachedSongs.id.count();
    final bytes = cachedSongs.document.length.sum();
    return (selectOnly(
      cachedSongs,
    )..addColumns([count, bytes])).watchSingle().map(
      (row) => (songs: row.read(count) ?? 0, bytes: row.read(bytes) ?? 0),
    );
  }

  /// Deletes every cached song.
  Future<void> clear() => delete(cachedSongs).go();

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
