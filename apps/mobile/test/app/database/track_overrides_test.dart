import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/library_dao.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';

const _min = Duration(seconds: 30);

void main() {
  late ZemaDatabase db;
  late LibraryDao dao;

  setUp(() {
    db = ZemaDatabase(NativeDatabase.memory());
    dao = db.libraryDao;
  });
  tearDown(() => db.close());

  Future<List<Track>> visible() =>
      dao.watchVisibleTracks(minDuration: _min).first;

  Future<List<Track>> addScan(List<ScannedAudio> files) async {
    await dao.applyReconciliation(
      reconcileTracks(stored: await dao.allTracks(), scan: files),
    );
    return dao.allTracks();
  }

  TrackOverrideRow edit(int id, {String? title, String? artist}) =>
      TrackOverrideRow(
        trackId: id,
        title: title,
        artist: artist,
        trackNumber: 7,
        updatedAt: DateTime.utc(2026),
      );

  test('edits show, sort and reach every read but the rescan one', () async {
    final [a, b] = await addScan([
      scannedAudio(1, '/m/a.mp3', title: 'Alpha', artist: 'Choir'),
      scannedAudio(2, '/m/b.mp3', title: 'Beta'),
    ]);
    await dao.setOverride(edit(b.id, title: 'Aaa first'));

    final shown = await visible();
    expect([for (final t in shown) t.title], ['Aaa first', 'Alpha']);
    expect(shown.first.trackNumber, 7);
    expect(shown.first.artist, b.artist, reason: 'null keeps the file');
    expect((await dao.tracksByIds([b.id])).single.title, 'Aaa first');
    expect(
      [for (final t in await dao.allTracks()) t.title],
      containsAll(['Alpha', 'Beta']),
      reason: 'rescans compare with the files',
    );
    expect((await dao.fileTrack(b.id))!.title, 'Beta');

    await dao.hideTrack(b.id);
    expect((await dao.watchHiddenTracks().first).single.title, 'Aaa first');
    expect(a.title, 'Alpha');
  });

  test(
    'a rescan keeps the edits; Reset and a deleted file drop them',
    () async {
      final files = [scannedAudio(1, '/m/a.mp3', title: 'Alpha')];
      final [a] = await addScan(files);
      await dao.setOverride(edit(a.id, title: 'Edited'));
      await addScan(files);
      expect((await visible()).single.title, 'Edited');

      await dao.clearOverride(a.id);
      expect((await visible()).single.title, 'Alpha');

      await dao.setOverride(edit(a.id, title: 'Edited'));
      await db.delete(db.tracks).go();
      expect(await db.select(db.trackOverrides).get(), isEmpty);
    },
  );
}
