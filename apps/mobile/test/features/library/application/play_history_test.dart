import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/database_provider.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/features/library/application/play_history.dart';
import 'package:zema/features/player/application/player_providers.dart';
import 'package:zema/features/player/data/zema_audio_handler.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/fake_player.dart';

void main() {
  group('recentlyAdded', () {
    Track added(int id, DateTime at) => Track.fromScan(
      id,
      scannedAudio(id, '/m/$id.mp3'),
    ).copyWith(dateAdded: at);

    test('keeps the last 30 days, newest first', () {
      final now = DateTime.utc(2026, 10, 31, 12);
      final tracks = [
        added(1, DateTime.utc(2026, 10, 1, 12)), // exactly 30 days: in
        added(2, DateTime.utc(2026, 10, 1, 11)), // 30 days and 1 h: out
        added(3, DateTime.utc(2026, 10, 30)),
        added(4, DateTime.utc(2026, 10, 15)),
      ];

      final result = withClock(Clock.fixed(now), () => recentlyAdded(tracks));

      expect([for (final t in result) t.id], [3, 4, 1]);
    });

    test('same date: the higher ID (stored later) first', () {
      final at = DateTime.utc(2026, 10, 20);
      final result = withClock(
        Clock.fixed(DateTime.utc(2026, 10, 21)),
        () => recentlyAdded([added(1, at), added(2, at)]),
      );

      expect([for (final t in result) t.id], [2, 1]);
    });
  });

  group('auto playlists and history', () {
    late ZemaDatabase db;
    late ProviderContainer container;
    late ZemaAudioHandler handler;
    late List<int> ids;

    setUp(() async {
      db = memoryDatabase();
      final files = [
        for (var i = 1; i <= 55; i++) scannedAudio(i, '/m/$i.mp3'),
        // Too short for the default 30 s minimum.
        scannedAudio(56, '/m/short.mp3', durationMs: 5000),
        // In a folder that gets hidden.
        scannedAudio(57, '/hidden/x.mp3'),
      ];
      await db.libraryDao.applyReconciliation(
        reconcileTracks(stored: const [], scan: files),
      );
      ids = [for (final t in await db.libraryDao.allTracks()) t.id];
      await db.libraryDao.hideFolder('/hidden');
      handler = fakeAudioHandler();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          audioHandlerProvider.overrideWithValue(handler),
        ],
      );
      addTearDown(container.dispose);
    });

    /// Waits until the auto playlist [kind] satisfies [ready].
    Future<List<Track>> playlist(
      AutoPlaylistKind kind, {
      bool Function(List<Track>)? ready,
      ProviderContainer? from,
    }) async {
      final scope = from ?? container;
      final provider = autoPlaylistProvider(kind);
      final subscription = scope.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      for (var i = 0; i < 200; i++) {
        final value = scope.read(provider).value;
        if (value != null && (ready?.call(value) ?? true)) return value;
        await Future<void>.delayed(Duration.zero);
      }
      fail('$kind never became ready: ${scope.read(provider)}');
    }

    Future<void> play(int index, int day) =>
        db.historyDao.recordPlay(ids[index], at: DateTime.utc(2026, 10, day));

    test('hidden and too-short songs are left out before the top 50', () async {
      // The hidden and the short song are played most.
      for (var i = 0; i < 5; i++) {
        await play(55, 1);
        await play(56, 1);
      }
      // Every visible song once, later ones played later.
      for (var i = 0; i < 55; i++) {
        await play(i, 2 + i ~/ 2);
      }

      final most = await playlist(
        AutoPlaylistKind.mostPlayed,
        ready: (t) => t.length == 50,
      );
      final mostIds = [for (final t in most) t.id];
      expect(mostIds, isNot(contains(ids[55])));
      expect(mostIds, isNot(contains(ids[56])));
      expect(mostIds.first, ids[54]);

      final recent = await playlist(
        AutoPlaylistKind.recentlyPlayed,
        ready: (t) => t.length == 50,
      );
      expect(recent.first.id, ids[54]);
      expect([for (final t in recent) t.id], isNot(contains(ids[55])));
    });

    test('most played by count; recently played latest first', () async {
      await play(0, 1);
      await play(1, 2);
      await play(1, 3);
      await play(2, 4);

      final most = await playlist(
        AutoPlaylistKind.mostPlayed,
        ready: (t) => t.length == 3,
      );
      expect([for (final t in most) t.id], [ids[1], ids[2], ids[0]]);
      final recent = await playlist(
        AutoPlaylistKind.recentlyPlayed,
        ready: (t) => t.length == 3,
      );
      expect([for (final t in recent) t.id], [ids[2], ids[1], ids[0]]);
    });

    test('a hidden song comes back when unhidden', () async {
      await play(56, 1);
      expect(await playlist(AutoPlaylistKind.recentlyPlayed), isEmpty);

      await db.libraryDao.unhideFolder('/hidden');

      final recent = await playlist(
        AutoPlaylistKind.recentlyPlayed,
        ready: (t) => t.isNotEmpty,
      );
      expect([for (final t in recent) t.id], [ids[56]]);
    });

    test('Recently added comes from the visible library', () async {
      final added = await withClock(
        Clock.fixed(DateTime.utc(2026, 10, 15)),
        () => playlist(AutoPlaylistKind.recentlyAdded),
      );

      // scannedAudio dates every file 1 October; the short and hidden
      // songs are left out.
      expect(added, hasLength(55));
    });

    test('counted plays are stored; old ones pruned at start', () async {
      final history = db.historyDao;
      final now = DateTime.now();
      await history.recordPlay(
        ids[3],
        at: now.subtract(const Duration(days: 400)),
      );
      await history.recordPlay(
        ids[4],
        at: now.subtract(const Duration(days: 300)),
      );
      // A handler built under a test clock, so 30 s pass at once.
      var clockNow = now;
      final backend = FakeAudioBackend();
      final counting = withClock(
        Clock(() => clockNow),
        () => fakeAudioHandler(backend),
      );
      final scope = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          audioHandlerProvider.overrideWithValue(counting),
        ],
      );
      addTearDown(scope.dispose);
      scope.listen(playHistoryProvider, (_, _) {});

      final track = (await db.libraryDao.tracksByIds([ids[0]])).single;
      await counting.playTracks([track]);
      await pumpEventQueue();
      clockNow = clockNow.add(const Duration(seconds: 31));
      backend.advanceTo(const Duration(seconds: 31));
      await pumpEventQueue();

      // The year-old play was pruned; the new one is first.
      final recent = await playlist(
        AutoPlaylistKind.recentlyPlayed,
        from: scope,
        ready: (t) => t.length == 2,
      );
      expect([for (final t in recent) t.id], [ids[0], ids[4]]);
    });
  });
}
