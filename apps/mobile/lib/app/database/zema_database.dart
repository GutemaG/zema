import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'library_dao.dart';
import 'tables.dart';

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
  ],
  daos: [LibraryDao],
)
class ZemaDatabase extends _$ZemaDatabase {
  ZemaDatabase(super.executor);

  /// The app's database file, opened in a background isolate.
  factory ZemaDatabase.open() => ZemaDatabase(driftDatabase(name: 'zema'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
