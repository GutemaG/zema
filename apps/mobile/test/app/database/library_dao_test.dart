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

  /// Adds [files] as a fresh scan and returns the stored tracks.
  Future<List<Track>> addScan(List<ScannedAudio> files) async {
    await dao.applyReconciliation(
      reconcileTracks(stored: await dao.allTracks(), scan: files),
    );
    return dao.allTracks();
  }

  group('LibraryDao', () {
    test('stores a scan and reads it back unchanged', () async {
      final audio = scannedAudio(
        5,
        '/m/መዝሙር/ቅዱስ.mp3',
        title: 'ቅዱስ ቅዱስ ቅዱስ',
        artist: 'ሊቀ መዘምራን ይልማ ኃይሉ',
        album: 'የቅዱሳን መዝሙር',
      );

      final track = (await addScan([audio])).single;

      expect(track, Track.fromScan(track.id, audio));
      expect(track.folder, '/m/መዝሙር');
      expect(track.dateAdded.isUtc, isTrue);
    });

    test('a rescan of an unchanged library changes nothing', () async {
      final files = [scannedAudio(1, '/m/a.mp3'), scannedAudio(2, '/m/b.mp3')];
      await addScan(files);

      final changes = reconcileTracks(
        stored: await dao.allTracks(),
        scan: files,
      );

      expect(changes.isEmpty, isTrue);
    });

    test('keeps IDs when a file moves and marks missing files', () async {
      final before = await addScan([
        scannedAudio(1, '/Download/a.mp3', title: 'A', sizeBytes: 100),
        scannedAudio(2, '/Download/b.mp3', title: 'B', sizeBytes: 200),
      ]);
      final idA = before.firstWhere((t) => t.title == 'A').id;
      final idB = before.firstWhere((t) => t.title == 'B').id;

      final after = await addScan([
        scannedAudio(9, '/Music/a.mp3', title: 'A', sizeBytes: 100),
      ]);

      final moved = after.firstWhere((t) => t.id == idA);
      expect(moved.path, '/Music/a.mp3');
      expect(moved.mediaStoreId, 9);
      expect(after.firstWhere((t) => t.id == idB).missing, isTrue);
      expect((await visible()).map((t) => t.id), [idA]);
    });

    test('lists visible tracks sorted by title, ignoring case', () async {
      await addScan([
        scannedAudio(1, '/m/1.mp3', title: 'kidus'),
        scannedAudio(2, '/m/2.mp3', title: 'Amlak'),
        scannedAudio(3, '/m/3.mp3', title: 'ሰላም'),
      ]);

      expect((await visible()).map((t) => t.title), ['Amlak', 'kidus', 'ሰላም']);
    });

    test('leaves out audio shorter than the minimum', () async {
      await addScan([
        scannedAudio(1, '/m/song.mp3', durationMs: 30000),
        scannedAudio(2, '/m/voice.mp3', durationMs: 29999),
      ]);

      expect((await visible()).map((t) => t.path), ['/m/song.mp3']);
    });

    test('leaves out hidden tracks until they are unhidden', () async {
      final tracks = await addScan([
        scannedAudio(1, '/m/a.mp3'),
        scannedAudio(2, '/m/b.mp3'),
      ]);
      final a = tracks.firstWhere((t) => t.path == '/m/a.mp3');

      await dao.hideTrack(a.id);
      expect((await visible()).map((t) => t.path), ['/m/b.mp3']);

      await dao.unhideTrack(a.id);
      expect(await visible(), hasLength(2));
    });

    test(
      'a hidden folder hides its subfolders but not similar names',
      () async {
        await addScan([
          scannedAudio(1, '/s/Music/a.mp3'),
          scannedAudio(2, '/s/Music/Live/b.mp3'),
          scannedAudio(3, '/s/Music Videos/c.mp3'),
          scannedAudio(4, '/s/Music_x/d.mp3'),
        ]);

        await dao.hideFolder('/s/Music');

        expect((await visible()).map((t) => t.path), [
          '/s/Music Videos/c.mp3',
          '/s/Music_x/d.mp3',
        ]);

        await dao.unhideFolder('/s/Music');
        expect(await visible(), hasLength(4));
      },
    );

    test('hiding twice is harmless', () async {
      final track = (await addScan([scannedAudio(1, '/m/a.mp3')])).single;

      await dao.hideTrack(track.id);
      await dao.hideTrack(track.id);
      await dao.hideFolder('/m');
      await dao.hideFolder('/m');

      expect(await visible(), isEmpty);
    });

    test('the visible list updates when the library changes', () async {
      final updates = dao.watchVisibleTracks(minDuration: _min);
      final seen = <int>[];
      final subscription = updates.listen((tracks) => seen.add(tracks.length));
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      await addScan([scannedAudio(1, '/m/a.mp3')]);
      await pumpEventQueue();
      await dao.hideFolder('/m');
      await pumpEventQueue();

      expect(seen, [0, 1, 0]);
    });

    test('applies all of a scan or none of it', () async {
      await addScan([scannedAudio(1, '/m/a.mp3')]);
      final stored = await dao.allTracks();

      // The second new file reuses a stored path, which the unique
      // constraint rejects; the first new file must not be kept either.
      final broken = TrackReconciliation(
        added: [scannedAudio(2, '/m/new.mp3'), scannedAudio(3, '/m/a.mp3')],
        updated: const [],
        newlyMissing: [stored.single.id],
        moved: const {},
        returned: const {},
      );

      await expectLater(
        dao.applyReconciliation(broken),
        throwsA(isA<Exception>()),
      );
      expect(await dao.allTracks(), stored);
    });

    test('foreign keys are enforced', () async {
      await expectLater(dao.hideTrack(12345), throwsA(isA<SqliteException>()));
    });
  });
}
