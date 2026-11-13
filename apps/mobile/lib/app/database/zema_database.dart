import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'backup_dao.dart';
import 'cached_songs_dao.dart';
import 'catalog_dao.dart';
import 'collections_dao.dart';
import 'detected_matches_dao.dart';
import 'drafts_dao.dart';
import 'fingerprints_dao.dart';
import 'history_dao.dart';
import 'identified_dao.dart';
import 'library_dao.dart';
import 'lyrics_links_dao.dart';
import 'own_copies_dao.dart';
import 'reports_dao.dart';
import 'restore_dao.dart';
import 'tables.dart';
import 'unmatched_dao.dart';
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
    CachedSongs,
    QueuedReports,
    UnmatchedEntries,
    Drafts,
    OwnCopies,
    TrackOverrides,
    TrackFingerprints,
    IdentifiedSongs,
    DetectedMatches,
  ],
  daos: [
    LibraryDao,
    CollectionsDao,
    HistoryDao,
    LyricsLinksDao,
    CatalogDao,
    CachedSongsDao,
    ReportsDao,
    BackupDao,
    RestoreDao,
    UnmatchedDao,
    DraftsDao,
    OwnCopiesDao,
    FingerprintsDao,
    IdentifiedDao,
    DetectedMatchesDao,
  ],
)
class ZemaDatabase extends _$ZemaDatabase {
  ZemaDatabase(super.executor);

  /// The app's database file, opened in a background isolate.
  factory ZemaDatabase.open() => ZemaDatabase(
    driftDatabase(
      name: 'zema',
      native: const DriftNativeOptions(shareAcrossIsolates: true),
    ),
  );

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      // v2: links from tracks to lyrics songs.
      from1To2: (m, schema) => m.createTable(schema.lyricsLinks),
      // v3: the catalog's song index.
      from2To3: (m, schema) => m.createTable(schema.catalogSongs),
      // v4: lyrics downloaded from the catalog.
      from3To4: (m, schema) => m.createTable(schema.cachedSongs),
      // v5: reports of wrong lyrics waiting to be sent.
      from4To5: (m, schema) => m.createTable(schema.queuedReports),
      // v6: each queued report keeps one ID; waiting ones get a random one.
      from5To6: (m, schema) => m.alterTable(
        TableMigration(
          schema.queuedReports,
          newColumns: [schema.queuedReports.reportId],
          columnTransformer: {
            schema.queuedReports.reportId: const CustomExpression<String>(
              _randomUuidSql,
            ),
          },
        ),
      ),
      // v7: backed-up entries whose song wasn't found at restore.
      from6To7: (m, schema) => m.createTable(schema.unmatchedEntries),
      // v8: contributions in progress.
      from7To8: (m, schema) => m.createTable(schema.drafts),
      // v9: the user's own copies of contributions waiting for review.
      from8To9: (m, schema) => m.createTable(schema.ownCopies),
      // v10: song info edited by the user (S09).
      from9To10: (m, schema) => m.createTable(schema.trackOverrides),
      // v11: audio fingerprints of library files.
      from10To11: (m, schema) => m.createTable(schema.trackFingerprints),
      // v12: songs identified by Listen.
      from11To12: (m, schema) => m.createTable(schema.identifiedSongs),
      from12To13: (m, schema) => m.createTable(schema.detectedMatches),
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// A random version 4 UUID, in SQLite.
const _randomUuidSql =
    "lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || "
    "substr(hex(randomblob(2)), 2) || '-' || "
    "substr('89ab', 1 + (abs(random()) % 4), 1) || "
    "substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6)))";
