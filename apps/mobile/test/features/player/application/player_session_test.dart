import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/database/database_provider.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/preferences_provider.dart';
import 'package:zema/features/player/application/player_providers.dart';
import 'package:zema/features/player/data/player_persistence.dart';
import 'package:zema/features/player/data/zema_audio_handler.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/fake_player.dart';

/// Stores [files] as the library and returns the tracks with their IDs.
Future<List<Track>> _storeLibrary(
  ZemaDatabase db,
  List<ScannedAudio> files,
) async {
  final dao = db.libraryDao;
  await dao.applyReconciliation(reconcileTracks(stored: const [], scan: files));
  return dao.allTracks();
}

Future<ProviderContainer> _container({
  required ZemaAudioHandler handler,
  ZemaDatabase? database,
  Map<String, Object> saved = const {},
}) async {
  SharedPreferences.setMockInitialValues(saved);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer.test(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(database ?? memoryDatabase()),
      audioHandlerProvider.overrideWithValue(handler),
    ],
  );
}

Map<String, Object> _savedQueue(
  List<int> ids, {
  int index = 0,
  int positionMs = 0,
  String repeat = 'off',
}) => {
  PlayerPersistence.queueKey: [for (final id in ids) '$id'],
  PlayerPersistence.indexKey: index,
  PlayerPersistence.positionKey: positionMs,
  PlayerPersistence.repeatKey: repeat,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('player session', () {
    test('restores the saved queue paused at the saved position', () async {
      final db = memoryDatabase();
      final tracks = await _storeLibrary(db, [
        scannedAudio(1, '/m/a.mp3', title: 'A'),
        scannedAudio(2, '/m/b.mp3', title: 'B'),
      ]);
      final backend = FakeAudioBackend();
      final handler = fakeAudioHandler(backend);
      final container = await _container(
        handler: handler,
        database: db,
        saved: _savedQueue(
          [tracks[1].id, tracks[0].id],
          index: 1,
          positionMs: 15000,
          repeat: 'all',
        ),
      );

      container.read(playerSessionProvider);
      await pumpEventQueue();

      final snapshot = handler.snapshot;
      expect(snapshot.queue.map((t) => t.title), ['B', 'A']);
      expect(snapshot.current?.title, 'A');
      expect(snapshot.playing, isFalse);
      expect(snapshot.repeat, QueueRepeat.all);
      expect(backend.position, const Duration(seconds: 15));
    });

    test('drops deleted tracks and continues with the next one', () async {
      final db = memoryDatabase();
      final tracks = await _storeLibrary(db, [
        scannedAudio(1, '/m/a.mp3', title: 'A'),
        scannedAudio(2, '/m/b.mp3', title: 'B', sizeBytes: 2),
        scannedAudio(3, '/m/c.mp3', title: 'C', sizeBytes: 3),
      ]);
      // B disappears from the phone.
      await db.libraryDao.applyReconciliation(
        reconcileTracks(
          stored: tracks,
          scan: [
            scannedAudio(1, '/m/a.mp3', title: 'A'),
            scannedAudio(3, '/m/c.mp3', title: 'C', sizeBytes: 3),
          ],
        ),
      );
      final backend = FakeAudioBackend();
      final handler = fakeAudioHandler(backend);
      final container = await _container(
        handler: handler,
        database: db,
        saved: _savedQueue(
          [for (final t in tracks) t.id],
          index: 1,
          positionMs: 20000,
        ),
      );

      container.read(playerSessionProvider);
      await pumpEventQueue();

      expect(handler.snapshot.queue.map((t) => t.title), ['A', 'C']);
      expect(handler.snapshot.current?.title, 'C');
      expect(backend.position, Duration.zero);
    });

    test('does nothing when no saved track exists any more', () async {
      final handler = fakeAudioHandler();
      final container = await _container(
        handler: handler,
        saved: _savedQueue([404]),
      );

      container.read(playerSessionProvider);
      await pumpEventQueue();

      expect(handler.snapshot.hasTrack, isFalse);
    });

    test('saves the queue when playback pauses', () async {
      final db = memoryDatabase();
      final tracks = await _storeLibrary(db, [
        scannedAudio(1, '/m/a.mp3'),
        scannedAudio(2, '/m/b.mp3'),
      ]);
      final backend = FakeAudioBackend();
      final handler = fakeAudioHandler(backend);
      final container = await _container(handler: handler, database: db);
      container.read(playerSessionProvider);
      await pumpEventQueue();

      await handler.playTracks(tracks, start: 1);
      await pumpEventQueue();
      backend.advanceTo(const Duration(seconds: 9));
      await handler.pause();
      await pumpEventQueue();

      final saved = container.read(playerPersistenceProvider).load()!;
      expect(saved.trackIds, [for (final t in tracks) t.id]);
      expect(saved.index, 1);
      expect(saved.position, const Duration(seconds: 9));
    });

    test('reports the same unplayable song every time it fails', () async {
      final backend = FakeAudioBackend();
      final handler = fakeAudioHandler(backend);
      final container = await _container(handler: handler);
      final skipped = <String>[];
      container.listen(unplayableTrackProvider, (_, next) {
        if (next.value case final skip?) skipped.add(skip.track.title);
      });
      final track = Track.fromScan(
        1,
        scannedAudio(1, '/m/bad.mp3', title: 'Bad'),
      );
      backend.unplayable.add(track.uri);

      await handler.playTracks([track]);
      await pumpEventQueue();
      await handler.playTracks([track]);
      await pumpEventQueue();

      expect(skipped, ['Bad', 'Bad']);
    });

    testWidgets('saves the position every 10 s while playing', (tester) async {
      final handler = fakeAudioHandler();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          audioHandlerProvider.overrideWithValue(handler),
        ],
      );
      container.read(playerSessionProvider);
      await tester.pump();

      await handler.playTracks([
        Track.fromScan(5, scannedAudio(1, '/m/a.mp3')),
      ]);
      await tester.pump();
      expect(prefs.getStringList(PlayerPersistence.queueKey), isNull);

      await tester.pump(autosaveInterval);

      expect(prefs.getStringList(PlayerPersistence.queueKey), ['5']);
      // Disposed here, not in tearDown: it cancels the autosave timer, which
      // must be gone before the test ends.
      container.dispose();
    });
  });
}
