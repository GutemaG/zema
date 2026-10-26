import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/lyrics_links_dao.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';

void main() {
  late ZemaDatabase db;
  late LyricsLinksDao dao;
  late List<int> ids;

  Future<void> scan(List<ScannedAudio> files) async {
    final library = db.libraryDao;
    await library.applyReconciliation(
      reconcileTracks(stored: await library.allTracks(), scan: files),
    );
  }

  final files = [
    for (var i = 1; i <= 3; i++) scannedAudio(i, '/m/$i.mp3', title: 'S$i'),
  ];

  setUp(() async {
    db = ZemaDatabase(NativeDatabase.memory());
    dao = db.lyricsLinksDao;
    await scan(files);
    ids = [for (final t in await db.libraryDao.allTracks()) t.id];
  });
  tearDown(() => db.close());

  Future<Map<int, (String?, bool)>> links() async => {
    for (final row in await dao.watchLinks().first)
      row.trackId: (row.songId, row.manual),
  };

  test(
    'replaceAutomatic makes the automatic links exactly those given',
    () async {
      await dao.replaceAutomatic({ids[0]: 'a', ids[1]: 'b'});
      expect(await links(), {ids[0]: ('a', false), ids[1]: ('b', false)});

      await dao.replaceAutomatic({ids[1]: 'c'});
      expect(await links(), {ids[1]: ('c', false)});
    },
  );

  test(
    'a manual link or "no lyrics" is never replaced automatically',
    () async {
      await dao.setManual(ids[0], 'mine');
      await dao.setManual(ids[1], null);

      await dao.replaceAutomatic({
        ids[0]: 'auto',
        ids[1]: 'auto',
        ids[2]: 'auto',
      });

      expect(await links(), {
        ids[0]: ('mine', true),
        ids[1]: (null, true),
        ids[2]: ('auto', false),
      });
    },
  );

  test('a manual choice replaces an automatic link and can change', () async {
    await dao.replaceAutomatic({ids[0]: 'auto'});
    await dao.setManual(ids[0], 'mine');
    expect(await links(), {ids[0]: ('mine', true)});

    await dao.setManual(ids[0], null);
    expect(await links(), {ids[0]: (null, true)});
  });

  test('links survive a rescan, even with the file missing', () async {
    await dao.setManual(ids[0], 'mine');
    await dao.replaceAutomatic({ids[1]: 'auto'});

    await scan(files.skip(1).toList());
    await scan(files);

    expect(await links(), {ids[0]: ('mine', true), ids[1]: ('auto', false)});
  });

  test("a link goes with its track's row", () async {
    await dao.setManual(ids[0], 'mine');
    await db.customStatement('DELETE FROM tracks WHERE id = ${ids[0]}');
    expect(await links(), isEmpty);
  });

  test('the stream updates', () async {
    final seen = <int>[];
    final subscription = dao.watchLinks().listen((r) => seen.add(r.length));
    await pumpEventQueue();
    await dao.replaceAutomatic({ids[0]: 'a'});
    await pumpEventQueue();
    await dao.setManual(ids[1], 'b');
    await pumpEventQueue();
    await subscription.cancel();
    expect(seen, [0, 1, 2]);
  });
}
