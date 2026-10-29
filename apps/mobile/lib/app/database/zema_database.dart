import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'catalog_dao.dart';
import 'collections_dao.dart';
import 'history_dao.dart';
import 'library_dao.dart';
import 'lyrics_links_dao.dart';
import 'tables.dart';
import 'zema_database.steps.dart';

part 'zema_database.g.dart';

/// Zema's on-device database. Regenerate the `.g.dart` files with
/// `dart run build_runner build` from apps/mobile; the output is committed.
@DriftDatabase(
  tables: [
    Tracks,
    HiddenFolders,
    HiddenTracks,
    Favorites,
    Playlists,
    PlaylistEntries,
    PlayEvents,
    LyricsLinks,
    CatalogSongs,
  ],
  daos: [LibraryDao, CollectionsDao, HistoryDao, LyricsLinksDao, CatalogDao],
)
class ZemaDatabase extends _$ZemaDatabase {
  ZemaDatabase(super.executor);

  /// The app's database file, opened in a background isolate.
  factory ZemaDatabase.open() => ZemaDatabase(driftDatabase(name: 'zema'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      // v2: links from tracks to lyrics songs.
      from1To2: (m, schema) => m.createTable(schema.lyricsLinks),
      // v3: the catalog's song index.
      from2To3: (m, schema) => m.createTable(schema.catalogSongs),
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
