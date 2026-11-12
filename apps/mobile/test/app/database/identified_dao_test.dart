import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/identified_dao.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';

void main() {
  late ZemaDatabase db;
  late IdentifiedDao dao;
  late List<int> ids;

  setUp(() async {
    db = ZemaDatabase(NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = ON');
    dao = db.identifiedDao;
    await db.libraryDao.applyReconciliation(
      reconcileTracks(
        stored: const [],
        scan: [
          scannedAudio(1, '/m/1.mp3', title: 'One'),
          scannedAudio(2, '/m/2.mp3', title: 'Two'),
        ],
      ),
    );
    ids = [for (final t in await db.libraryDao.allTracks()) t.id];
  });
  tearDown(() => db.close());

  final noon = DateTime.utc(2026, 11, 12, 12);

  Future<List<(int, DateTime)>> rows() async => [
    for (final r in await dao.watchAll().first) (r.trackId, r.identifiedAt),
  ];

  test('newest first; the same song again soon after is one entry', () async {
    await dao.add(ids[0], noon);
    await dao.add(ids[0], noon.add(const Duration(minutes: 3)));
    await dao.add(ids[1], noon.add(const Duration(minutes: 5)));
    await dao.add(ids[1], noon.add(const Duration(minutes: 30)));

    expect(await rows(), [
      (ids[1], noon.add(const Duration(minutes: 30))),
      (ids[1], noon.add(const Duration(minutes: 5))),
      (ids[0], noon.add(const Duration(minutes: 3))),
    ]);
  });

  test('entries are removed one by one or all at once', () async {
    await dao.add(ids[0], noon);
    await dao.add(ids[1], noon);
    final first = (await dao.watchAll().first).last;

    await dao.remove(first.id);
    expect((await rows()).map((r) => r.$1), [ids[1]]);

    await dao.clear();
    expect(await rows(), isEmpty);
  });

  test('a song deleted from the library leaves History', () async {
    await dao.add(ids[0], noon);
    await db.customStatement('DELETE FROM tracks WHERE id = ?', [ids[0]]);
    expect(await rows(), isEmpty);
  });
}
