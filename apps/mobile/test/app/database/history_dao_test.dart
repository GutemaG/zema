import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/history_dao.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';

void main() {
  late ZemaDatabase db;
  late HistoryDao dao;
  late List<int> ids;

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
    dao = db.historyDao;
    await scan(files);
    ids = [for (final t in await db.libraryDao.allTracks()) t.id];
  });
  tearDown(() => db.close());

  DateTime day(int d, [int hour = 12]) => DateTime.utc(2026, 10, d, hour);

  test('most played: by play count, ties to the one played last', () async {
    await dao.recordPlay(ids[0], at: day(1));
    await dao.recordPlay(ids[0], at: day(2));
    await dao.recordPlay(ids[1], at: day(3));
    await dao.recordPlay(ids[2], at: day(4));
    await dao.recordPlay(ids[1], at: day(5));
    await dao.recordPlay(ids[3], at: day(6));

    // S1 and S2 have two plays, S2 last; S3 and S4 one, S4 last.
    expect(await dao.watchMostPlayed().first, [ids[1], ids[0], ids[3], ids[2]]);
  });

  test('recently played: each song once, latest play first', () async {
    await dao.recordPlay(ids[0], at: day(1));
    await dao.recordPlay(ids[1], at: day(2));
    await dao.recordPlay(ids[0], at: day(3));
    await dao.recordPlay(ids[2], at: day(4));

    expect(await dao.watchRecentlyPlayed().first, [ids[2], ids[0], ids[1]]);
  });

  test('times stored with an offset compare by the instant', () async {
    await dao.recordPlay(ids[0], at: DateTime.utc(2026, 10, 1, 10));
    // A row written in local time with an offset: 12:00 at +03:00 is
    // 09:00 UTC, before the play above although its text sorts after.
    await db.customStatement(
      'INSERT INTO play_events (track_id, played_at) VALUES (?, ?)',
      [ids[1], '2026-10-01T12:00:00.000+03:00'],
    );

    expect(await dao.watchRecentlyPlayed().first, [ids[0], ids[1]]);
    expect(await dao.pruneBefore(DateTime.utc(2026, 10, 1, 9, 30)), 1);
    expect(await dao.watchRecentlyPlayed().first, [ids[0]]);
  });

  test('pruneBefore deletes older plays only', () async {
    await dao.recordPlay(ids[0], at: day(1));
    await dao.recordPlay(ids[1], at: day(10));
    await dao.recordPlay(ids[2], at: day(20));

    expect(await dao.pruneBefore(day(10)), 1);
    expect(await dao.watchRecentlyPlayed().first, [ids[2], ids[1]]);
  });

  test('history is kept through a rescan, even for a missing file', () async {
    await dao.recordPlay(ids[0], at: day(1));
    await dao.recordPlay(ids[3], at: day(2));

    // S4 disappears; S1 is still there.
    await scan(files.take(3).toList());

    expect(await dao.watchMostPlayed().first, [ids[3], ids[0]]);
  });

  test('the stream updates when a play is recorded', () async {
    final updates = dao.watchRecentlyPlayed();
    await dao.recordPlay(ids[0], at: day(1));
    expect(await updates.first, [ids[0]]);

    await dao.recordPlay(ids[1], at: day(2));
    expect(await updates.first, [ids[1], ids[0]]);
  });
}
