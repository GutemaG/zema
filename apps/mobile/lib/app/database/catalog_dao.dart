import 'package:drift/drift.dart';
import 'package:zema_core/zema_core.dart';

import 'tables.dart';
import 'zema_database.dart';

part 'catalog_dao.g.dart';

/// The phone's copy of the catalog's song index.
@DriftAccessor(tables: [CatalogSongs])
class CatalogDao extends DatabaseAccessor<ZemaDatabase> with _$CatalogDaoMixin {
  CatalogDao(super.attachedDatabase);

  /// Every indexed song, by ID.
  Stream<List<CatalogEntry>> watchEntries() => (select(
    catalogSongs,
  )..orderBy([(s) => OrderingTerm.asc(s.id)])).map(_entry).watch();

  /// The indexed song [id], or null when the catalog doesn't list it.
  Future<CatalogEntry?> entry(String id) => (select(
    catalogSongs,
  )..where((s) => s.id.equals(id))).map(_entry).getSingleOrNull();

  Future<int> count() => catalogSongs.count().getSingle();

  /// Makes the index exactly [entries], in one transaction: songs no longer
  /// in the catalog are removed, the rest added or updated.
  Future<void> replaceAll(List<CatalogEntry> entries) => transaction(() async {
    await (delete(
      catalogSongs,
    )..where((s) => s.id.isNotIn([for (final e in entries) e.id]))).go();
    await batch((b) {
      b.insertAllOnConflictUpdate(catalogSongs, [
        for (final e in entries)
          CatalogSongsCompanion.insert(
            id: e.id,
            title: e.title,
            transliteration: Value(e.transliteration),
            artist: Value(e.artist),
            album: Value(e.album),
            synced: e.synced,
            version: e.version,
            approvedAt: e.approvedAt.toUtc(),
          ),
      ]);
    });
  });
}

CatalogEntry _entry(CatalogSongRow row) => CatalogEntry(
  id: row.id,
  title: row.title,
  transliteration: row.transliteration,
  artist: row.artist,
  album: row.album,
  synced: row.synced,
  version: row.version,
  approvedAt: row.approvedAt,
);
