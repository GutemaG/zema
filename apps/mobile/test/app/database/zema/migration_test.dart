// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v4.dart' as v4;
import 'generated/schema_v5.dart' as v5;
import 'generated/schema_v6.dart' as v6;
import 'generated/schema_v7.dart' as v7;
import 'generated/schema_v8.dart' as v8;
import 'generated/schema_v9.dart' as v9;
import 'generated/schema_v13.dart' as v13;
import 'generated/schema_v14.dart' as v14;
import 'generated/schema_v15.dart' as v15;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = ZemaDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test('migration from v1 to v2 keeps the library and adds no links', () async {
    const track = v1.TracksData(
      id: 1,
      mediaStoreId: 11,
      uri: 'content://media/external/audio/media/11',
      path: '/m/1.mp3',
      folder: '/m',
      title: 'ሰላም',
      durationMs: 60000,
      sizeBytes: 1000,
      dateAdded: '2026-10-01T00:00:00.000Z',
      missing: 0,
    );
    const favorite = v1.FavoritesData(
      trackId: 1,
      addedAt: '2026-10-02T00:00:00.000Z',
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: ZemaDatabase.new,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.tracks, track)
          ..insert(oldDb.favorites, favorite);
      },
      validateItems: (newDb) async {
        expect((await newDb.select(newDb.tracks).get()).single.title, 'ሰላም');
        expect((await newDb.select(newDb.favorites).get()).single.trackId, 1);
        expect(await newDb.select(newDb.lyricsLinks).get(), isEmpty);
      },
    );
  });

  test(
    'migration from v2 to v3 keeps links and starts an empty index',
    () async {
      const track = v2.TracksData(
        id: 1,
        mediaStoreId: 11,
        uri: 'content://media/external/audio/media/11',
        path: '/m/1.mp3',
        folder: '/m',
        title: 'ሰላም ለዚህ ቤት',
        durationMs: 60000,
        sizeBytes: 1000,
        dateAdded: '2026-10-01T00:00:00.000Z',
        missing: 0,
      );
      const link = v2.LyricsLinksData(
        trackId: 1,
        songId: 'selam-lezih-bet',
        manual: 1,
        linkedAt: '2026-10-02T00:00:00.000Z',
      );

      await verifier.testWithDataIntegrity(
        oldVersion: 2,
        newVersion: 3,
        createOld: v2.DatabaseAtV2.new,
        createNew: v3.DatabaseAtV3.new,
        openTestedDatabase: ZemaDatabase.new,
        createItems: (batch, oldDb) {
          batch
            ..insert(oldDb.tracks, track)
            ..insert(oldDb.lyricsLinks, link);
        },
        validateItems: (newDb) async {
          final links = await newDb.select(newDb.lyricsLinks).get();
          expect(links.single.songId, 'selam-lezih-bet');
          expect(links.single.manual, 1);
          expect(await newDb.select(newDb.catalogSongs).get(), isEmpty);
        },
      );
    },
  );

  test('migration from v3 to v4 keeps links and the index, and starts an empty '
      'cache', () async {
    const link = v3.LyricsLinksData(
      trackId: 1,
      songId: 'selam-lezih-bet',
      manual: 0,
      linkedAt: '2026-10-02T00:00:00.000Z',
    );
    const entry = v3.CatalogSongsData(
      id: 'selam-lezih-bet',
      title: 'ሰላም ለዚህ ቤት',
      synced: 1,
      version: 2,
      approvedAt: '2026-10-01T00:00:00.000Z',
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 3,
      newVersion: 4,
      createOld: v3.DatabaseAtV3.new,
      createNew: v4.DatabaseAtV4.new,
      openTestedDatabase: ZemaDatabase.new,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.tracks, _v3Track)
          ..insert(oldDb.lyricsLinks, link)
          ..insert(oldDb.catalogSongs, entry);
      },
      validateItems: (newDb) async {
        final links = await newDb.select(newDb.lyricsLinks).get();
        expect(links.single.songId, 'selam-lezih-bet');
        final index = await newDb.select(newDb.catalogSongs).get();
        expect(index.single.version, 2);
        expect(await newDb.select(newDb.cachedSongs).get(), isEmpty);
      },
    );
  });

  test('migration from v4 to v5 keeps the cache and index, and starts an '
      'empty report queue', () async {
    const entry = v4.CatalogSongsData(
      id: 'selam-lezih-bet',
      title: 'ሰላም ለዚህ ቤት',
      synced: 1,
      version: 2,
      approvedAt: '2026-10-01T00:00:00.000Z',
    );
    const cached = v4.CachedSongsData(
      id: 'selam-lezih-bet',
      version: 2,
      document: '{"song":{}}',
      cachedAt: '2026-10-02T00:00:00.000Z',
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 4,
      newVersion: 5,
      createOld: v4.DatabaseAtV4.new,
      createNew: v5.DatabaseAtV5.new,
      openTestedDatabase: ZemaDatabase.new,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.catalogSongs, entry)
          ..insert(oldDb.cachedSongs, cached);
      },
      validateItems: (newDb) async {
        final index = await newDb.select(newDb.catalogSongs).get();
        expect(index.single.version, 2);
        final cache = await newDb.select(newDb.cachedSongs).get();
        expect(cache.single.document, '{"song":{}}');
        expect(await newDb.select(newDb.queuedReports).get(), isEmpty);
      },
    );
  });

  test(
    'migration from v5 to v6 gives each waiting report its own ID',
    () async {
      const first = v5.QueuedReportsData(
        id: 1,
        songId: 'galatoomi',
        recordingId: 'galatoomi',
        reason: 'wrongTiming',
        createdAt: '2026-10-29T13:20:35.000Z',
      );
      const second = v5.QueuedReportsData(
        id: 2,
        songId: 'selam-lezih-bet',
        reason: 'other',
        note: 'Verse 2',
        createdAt: '2026-10-29T13:21:00.000Z',
      );

      await verifier.testWithDataIntegrity(
        oldVersion: 5,
        newVersion: 6,
        createOld: v5.DatabaseAtV5.new,
        createNew: v6.DatabaseAtV6.new,
        openTestedDatabase: ZemaDatabase.new,
        createItems: (batch, oldDb) =>
            batch.insertAll(oldDb.queuedReports, [first, second]),
        validateItems: (newDb) async {
          final rows = await (newDb.select(
            newDb.queuedReports,
          )..orderBy([(r) => OrderingTerm.asc(r.id)])).get();
          expect(
            [for (final r in rows) r.songId],
            ['galatoomi', 'selam-lezih-bet'],
          );
          expect(rows.first.recordingId, 'galatoomi');
          expect(rows.last.note, 'Verse 2');
          final uuid = RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          );
          for (final row in rows) {
            expect(row.reportId, matches(uuid));
          }
          expect(rows.first.reportId, isNot(rows.last.reportId));
        },
      );
    },
  );

  test('migration from v6 to v7 keeps the library and starts with no '
      'unmatched entries', () async {
    const track = v6.TracksData(
      id: 1,
      mediaStoreId: 11,
      uri: 'content://media/11',
      path: '/storage/emulated/0/Music/Tizita.mp3',
      folder: '/storage/emulated/0/Music',
      title: 'Tizita',
      durationMs: 241000,
      sizeBytes: 1000,
      dateAdded: '2026-10-01T00:00:00.000Z',
      missing: 0,
    );
    const favorite = v6.FavoritesData(
      trackId: 1,
      addedAt: '2026-10-02T00:00:00.000Z',
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 6,
      newVersion: 7,
      createOld: v6.DatabaseAtV6.new,
      createNew: v7.DatabaseAtV7.new,
      openTestedDatabase: ZemaDatabase.new,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.tracks, track)
          ..insert(oldDb.favorites, favorite);
      },
      validateItems: (newDb) async {
        expect((await newDb.select(newDb.tracks).get()).single.title, 'Tizita');
        expect(await newDb.select(newDb.favorites).get(), hasLength(1));
        expect(await newDb.select(newDb.unmatchedEntries).get(), isEmpty);
      },
    );
  });

  test(
    'migration from v7 to v8 keeps the data and starts with no drafts',
    () async {
      const track = v7.TracksData(
        id: 1,
        mediaStoreId: 11,
        uri: 'content://media/11',
        path: '/storage/emulated/0/Music/Tizita.mp3',
        folder: '/storage/emulated/0/Music',
        title: 'Tizita',
        durationMs: 241000,
        sizeBytes: 1000,
        dateAdded: '2026-10-01T00:00:00.000Z',
        missing: 0,
      );
      const kept = v7.UnmatchedEntriesData(
        id: 1,
        kind: 'favorite',
        title: 'Gone',
        durationMs: 60000,
        fileName: 'Gone.mp3',
        addedAt: '2026-10-02T00:00:00.000Z',
      );

      await verifier.testWithDataIntegrity(
        oldVersion: 7,
        newVersion: 8,
        createOld: v7.DatabaseAtV7.new,
        createNew: v8.DatabaseAtV8.new,
        openTestedDatabase: ZemaDatabase.new,
        createItems: (batch, oldDb) {
          batch
            ..insert(oldDb.tracks, track)
            ..insert(oldDb.unmatchedEntries, kept);
        },
        validateItems: (newDb) async {
          expect(
            (await newDb.select(newDb.tracks).get()).single.title,
            'Tizita',
          );
          expect(
            await newDb.select(newDb.unmatchedEntries).get(),
            hasLength(1),
          );
          expect(await newDb.select(newDb.drafts).get(), isEmpty);
        },
      );
    },
  );

  test(
    'migration from v8 to v9 keeps the drafts and starts with no own copies',
    () async {
      const draft = v8.DraftsData(
        id: 1,
        kind: 'new_song',
        step: 'review',
        title: 'Selam',
        draft: '{}',
        createdAt: '2026-11-02T00:00:00.000Z',
        updatedAt: '2026-11-02T00:00:00.000Z',
      );

      await verifier.testWithDataIntegrity(
        oldVersion: 8,
        newVersion: 9,
        createOld: v8.DatabaseAtV8.new,
        createNew: v9.DatabaseAtV9.new,
        openTestedDatabase: ZemaDatabase.new,
        createItems: (batch, oldDb) => batch.insert(oldDb.drafts, draft),
        validateItems: (newDb) async {
          expect(
            (await newDb.select(newDb.drafts).get()).single.title,
            'Selam',
          );
          expect(await newDb.select(newDb.ownCopies).get(), isEmpty);
        },
      );
    },
  );

  test('migration from v13 to v14 keeps History and starts with no pending '
      'lookups', () async {
    const track = v13.TracksData(
      id: 1,
      mediaStoreId: 11,
      uri: 'content://media/11',
      path: '/m/1.mp3',
      folder: '/m',
      title: 'Tizita',
      durationMs: 241000,
      sizeBytes: 1000,
      dateAdded: '2026-10-01T00:00:00.000Z',
      missing: 0,
    );
    const identified = v13.IdentifiedSongsData(
      id: 1,
      trackId: 1,
      identifiedAt: '2026-11-12T12:00:00.000Z',
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 13,
      newVersion: 14,
      createOld: v13.DatabaseAtV13.new,
      createNew: v14.DatabaseAtV14.new,
      openTestedDatabase: ZemaDatabase.new,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.tracks, track)
          ..insert(oldDb.identifiedSongs, identified);
      },
      validateItems: (newDb) async {
        final rows = await newDb.select(newDb.identifiedSongs).get();
        expect(rows.single.trackId, 1);
        expect(rows.single.songId, equals(null));
        expect(await newDb.select(newDb.pendingLookups).get(), isEmpty);
      },
    );
  });

  test('migration from v14 to v15 keeps library fingerprints and starts '
      'with no catalog ones', () async {
    const track = v14.TracksData(
      id: 1,
      mediaStoreId: 11,
      uri: 'content://media/11',
      path: '/m/1.mp3',
      folder: '/m',
      title: 'Tizita',
      durationMs: 241000,
      sizeBytes: 1000,
      dateAdded: '2026-10-01T00:00:00.000Z',
      missing: 0,
    );
    final fingerprint = v14.TrackFingerprintsData(
      trackId: 1,
      version: 1,
      sizeBytes: 1000,
      data: Uint8List.fromList([1, 2, 3]),
      updatedAt: '2026-11-12T12:00:00.000Z',
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 14,
      newVersion: 15,
      createOld: v14.DatabaseAtV14.new,
      createNew: v15.DatabaseAtV15.new,
      openTestedDatabase: ZemaDatabase.new,
      createItems: (batch, oldDb) {
        batch
          ..insert(oldDb.tracks, track)
          ..insert(oldDb.trackFingerprints, fingerprint);
      },
      validateItems: (newDb) async {
        expect(
          (await newDb.select(newDb.trackFingerprints).get()).single.data,
          [1, 2, 3],
        );
        expect(await newDb.select(newDb.catalogFingerprints).get(), isEmpty);
      },
    );
  });
}

const _v3Track = v3.TracksData(
  id: 1,
  mediaStoreId: 11,
  uri: 'content://media/external/audio/media/11',
  path: '/m/1.mp3',
  folder: '/m',
  title: 'ሰላም ለዚህ ቤት',
  durationMs: 60000,
  sizeBytes: 1000,
  dateAdded: '2026-10-01T00:00:00.000Z',
  missing: 0,
);
