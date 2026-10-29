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
}
