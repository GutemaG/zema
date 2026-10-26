import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/collections_dao.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';

void main() {
  late ZemaDatabase db;
  late CollectionsDao dao;
  late List<int> ids;

  /// Stores [files] as a scan (a rescan when tracks exist already).
  Future<void> scan(List<ScannedAudio> files) async {
    final library = db.libraryDao;
    await library.applyReconciliation(
      reconcileTracks(stored: await library.allTracks(), scan: files),
    );
  }

  final files = [
    for (var i = 1; i <= 4; i++) scannedAudio(i, '/m/$i.mp3', title: 'S$i'),
  ];

  setUp(() async {
    db = ZemaDatabase(NativeDatabase.memory());
    dao = db.collectionsDao;
    await scan(files);
    ids = [for (final t in await db.libraryDao.allTracks()) t.id];
  });
  tearDown(() => db.close());

  Future<List<int>> favoriteIds() async => [
    for (final row in await dao.watchFavorites().first) row.trackId,
  ];

  Future<StoredPlaylist> playlist(int id) async =>
      (await dao.watchPlaylists().first).singleWhere((p) => p.id == id);

  group('favorites', () {
    test('newest first; adding twice keeps the first time', () async {
      await dao.addFavorite(ids[0], at: DateTime.utc(2026, 1, 1));
      await dao.addFavorite(ids[1], at: DateTime.utc(2026, 1, 3));
      await dao.addFavorite(ids[2], at: DateTime.utc(2026, 1, 2));
      await dao.addFavorite(ids[0], at: DateTime.utc(2026, 1, 9));

      expect(await favoriteIds(), [ids[1], ids[2], ids[0]]);
    });

    test('remove returns the row; restore puts it back in place', () async {
      await dao.addFavorite(ids[0], at: DateTime.utc(2026, 1, 1));
      await dao.addFavorite(ids[1], at: DateTime.utc(2026, 1, 2));
      await dao.addFavorite(ids[2], at: DateTime.utc(2026, 1, 3));

      final removed = await dao.removeFavorite(ids[1]);
      expect(await favoriteIds(), [ids[2], ids[0]]);
      expect(await dao.removeFavorite(ids[1]), isNull);

      await dao.restoreFavorite(removed!);
      expect(await favoriteIds(), [ids[2], ids[1], ids[0]]);
    });
  });

  group('playlists', () {
    test('create trims the name and drops an empty description', () async {
      final id = await dao.createPlaylist('  Kidase ', description: '  ');

      final stored = await playlist(id);
      expect(stored.name, 'Kidase');
      expect(stored.description, isNull);
      expect(stored.trackIds, isEmpty);
    });

    test('names are unique ignoring letter case and spaces', () async {
      final id = await dao.createPlaylist('Kidase');

      expect(
        () => dao.createPlaylist(' KIDASE '),
        throwsA(isA<DuplicateNameFailure>()),
      );
      final other = await dao.createPlaylist('ቅዳሴ');
      expect(
        () => dao.renamePlaylist(other, 'kidase'),
        throwsA(isA<DuplicateNameFailure>()),
      );
      // Renaming to its own name in another case is fine.
      await dao.renamePlaylist(id, 'KIDASE', description: 'Sunday');
      final renamed = await playlist(id);
      expect(renamed.name, 'KIDASE');
      expect(renamed.description, 'Sunday');
    });

    test('adds to the end, skipping songs already there', () async {
      final id = await dao.createPlaylist('P');

      expect(await dao.addToPlaylist(id, [ids[2], ids[0]]), 2);
      expect(await dao.addToPlaylist(id, [ids[0], ids[1], ids[1]]), 1);

      expect((await playlist(id)).trackIds, [ids[2], ids[0], ids[1]]);
    });

    test('remove returns the index; insert puts the song back', () async {
      final id = await dao.createPlaylist('P');
      await dao.addToPlaylist(id, ids);

      final index = await dao.removeFromPlaylist(id, ids[1]);
      expect(index, 1);
      expect((await playlist(id)).trackIds, [ids[0], ids[2], ids[3]]);
      expect(await dao.removeFromPlaylist(id, ids[1]), isNull);

      await dao.insertIntoPlaylist(id, ids[1], index!);
      expect((await playlist(id)).trackIds, ids);
      // Already there: nothing changes.
      await dao.insertIntoPlaylist(id, ids[1], 0);
      expect((await playlist(id)).trackIds, ids);
    });

    test('saves a new order', () async {
      final id = await dao.createPlaylist('P');
      await dao.addToPlaylist(id, ids);

      await dao.setPlaylistOrder(id, ids.reversed.toList());

      expect((await playlist(id)).trackIds, ids.reversed.toList());
    });

    test('deleting a playlist deletes its entries', () async {
      final id = await dao.createPlaylist('P');
      await dao.addToPlaylist(id, ids);

      await dao.deletePlaylist(id);

      expect(await dao.watchPlaylists().first, isEmpty);
      expect(await db.select(db.playlistEntries).get(), isEmpty);
    });

    test('lists every playlist, empty ones too', () async {
      final a = await dao.createPlaylist('A');
      final b = await dao.createPlaylist('B');
      await dao.addToPlaylist(b, [ids[0]]);

      final all = await dao.watchPlaylists().first;
      expect([for (final p in all) p.id], [a, b]);
      expect(
        [for (final p in all) p.trackIds],
        [
          <int>[],
          [ids[0]],
        ],
      );
    });
  });

  test(
    'favorites and playlists survive a rescan with a missing file',
    () async {
      final id = await dao.createPlaylist('P');
      await dao.addToPlaylist(id, ids);
      await dao.addFavorite(ids[3]);

      await scan(files.sublist(0, 3));
      await scan(files);

      expect((await playlist(id)).trackIds, ids);
      expect(await favoriteIds(), [ids[3]]);
    },
  );
}
