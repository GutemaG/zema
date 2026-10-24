import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart';

import 'generated/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  group('ZemaDatabase schema', () {
    test('is version 1', () {
      final db = ZemaDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, 1);
    });

    // When schema v2 is added, `dart run drift_dev make-migrations` generates
    // the step-by-step migration tests next to this file.
    test('the tables match the saved v1 schema dump', () async {
      final connection = await verifier.startAt(1);
      final db = ZemaDatabase(connection);
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 1);
    });

    test('a fresh database has all seven tables', () async {
      final connection = await verifier.startAt(1);
      final db = ZemaDatabase(connection);
      addTearDown(db.close);

      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%' ORDER BY name",
          )
          .get();

      expect(rows.map((r) => r.read<String>('name')), [
        'favorites',
        'hidden_folders',
        'hidden_tracks',
        'play_events',
        'playlist_entries',
        'playlists',
        'tracks',
      ]);
    });
  });
}
