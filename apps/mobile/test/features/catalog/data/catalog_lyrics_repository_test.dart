import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/features/catalog/data/catalog_lyrics_repository.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_catalog.dart';

Song _song(String id, {String line = 'Amen'}) => Song(
  id: id,
  title: id.toUpperCase(),
  sections: [
    LyricSection(id: 'v1', kind: SectionKind.verse, lines: [LyricLine(line)]),
  ],
);

/// Lyrics held in memory, one recording per song; [byId] can change.
class _Lyrics implements LyricsRepository {
  _Lyrics(this.byId);

  Map<String, Song> byId;

  Recording _recording(String id) =>
      Recording(id: '$id-r', songId: id, source: RecordingSource.localFile);

  @override
  Future<List<Song>> songs() async => [...byId.values];
  @override
  Future<Song?> song(String id) async => byId[id];
  @override
  Future<List<Recording>> recordings(String songId) async =>
      byId.containsKey(songId) ? [_recording(songId)] : const [];
  @override
  Future<SyncTiming?> timing(String recordingId) async => SyncTiming(
    recordingId: recordingId,
    starts: const [Duration(seconds: 1)],
  );
  @override
  Future<List<Song>> search(String query) async =>
      searchSongs([...byId.values], query);
}

void main() {
  late ZemaDatabase db;
  late _Lyrics lyrics;
  late FakeCatalogRepository catalog;

  CatalogLyricsRepository repository({bool configured = true}) =>
      CatalogLyricsRepository(
        catalog: configured ? catalog : null,
        index: db.catalogDao,
        cache: db.cachedSongsDao,
      );

  /// Saves the catalog's current index on the phone.
  Future<void> refreshIndex() async =>
      db.catalogDao.replaceAll(await catalog.index());

  Future<List<String>> cachedIds() async => [
    for (final c in await db.cachedSongsDao.watchSongs().first)
      c.document.song.id,
  ];

  setUp(() async {
    db = ZemaDatabase(NativeDatabase.memory());
    lyrics = _Lyrics({'selam': _song('selam'), 'amlak': _song('amlak')});
    catalog = FakeCatalogRepository(lyrics: lyrics);
    await refreshIndex();
  });
  tearDown(() => db.close());

  group('song', () {
    test('a song the index does not list is null, with no fetch', () async {
      expect(await repository().song('kidus'), isNull);
      expect(catalog.songCalls, isEmpty);
    });

    test(
      'the first read fetches and saves; later reads use the cache',
      () async {
        final first = repository();
        expect((await first.song('selam'))?.title, 'SELAM');
        expect(catalog.songCalls, ['selam']);
        expect(await cachedIds(), ['selam']);

        expect((await first.song('selam'))?.title, 'SELAM');
        // A new repository (the app restarted) reads Drift, offline.
        catalog.failure = const NetworkFailure('offline');
        expect((await repository().song('selam'))?.title, 'SELAM');
        expect(catalog.songCalls, ['selam']);
      },
    );

    test('a newer version in the index is fetched on next use', () async {
      await repository().song('selam');
      lyrics.byId = {...lyrics.byId, 'selam': _song('selam', line: 'New')};
      catalog.versions['selam'] = 2;
      await refreshIndex();

      final again = await repository().song('selam');

      expect(again?.sections.single.lines.single.text, 'New');
      expect(catalog.songCalls, ['selam', 'selam']);
      expect((await db.cachedSongsDao.song('selam'))?.version, 2);
    });

    test(
      'the same repository also refetches after the index changes',
      () async {
        final r = repository();
        await r.song('selam');
        lyrics.byId = {...lyrics.byId, 'selam': _song('selam', line: 'New')};
        catalog.versions['selam'] = 2;
        await refreshIndex();

        final again = await r.song('selam');
        expect(again?.sections.single.lines.single.text, 'New');
      },
    );

    test('offline, an older cached copy is shown and kept', () async {
      await repository().song('selam');
      catalog.versions['selam'] = 2;
      await refreshIndex();
      catalog.failure = const NetworkFailure('offline');

      expect((await repository().song('selam'))?.title, 'SELAM');
      expect((await db.cachedSongsDao.song('selam'))?.version, 1);
    });

    test('offline and never cached, the failure is thrown and nothing is '
        'cached', () async {
      catalog.failure = const NetworkFailure('offline');

      await expectLater(
        repository().song('selam'),
        throwsA(isA<NetworkFailure>()),
      );
      expect(await cachedIds(), isEmpty);

      // Nothing remembers the failure: the next call tries again.
      catalog.failure = null;
      expect((await repository().song('selam'))?.title, 'SELAM');
    });

    test('other failures are thrown too', () async {
      catalog.failure = const BackendFailure('refused');
      await expectLater(
        repository().song('selam'),
        throwsA(isA<BackendFailure>()),
      );
      expect(await cachedIds(), isEmpty);
    });

    test('a song the server no longer has is null and not cached', () async {
      lyrics.byId = {'amlak': _song('amlak')};

      expect(await repository().song('selam'), isNull);
      expect(await cachedIds(), isEmpty);
    });

    test('with no backend, an uncached song is a NetworkFailure', () async {
      await expectLater(
        repository(configured: false).song('selam'),
        throwsA(isA<NetworkFailure>()),
      );
      expect(catalog.songCalls, isEmpty);
    });

    test('reads at the same time share one fetch', () async {
      final gate = catalog.songGate = Completer<void>();
      final r = repository();

      final reads = [r.song('selam'), r.song('selam')];
      await pumpEventQueue();
      gate.complete();

      expect(
        [for (final s in await Future.wait(reads)) s?.id],
        ['selam', 'selam'],
      );
      expect(catalog.songCalls, ['selam']);

      // Once it is done, a later change fetches again.
      catalog.versions['selam'] = 2;
      await refreshIndex();
      await r.song('selam');
      expect(catalog.songCalls, ['selam', 'selam']);
    });

    test('a cached song reads in under 300 ms', () async {
      await repository().song('selam');

      final watch = Stopwatch()..start();
      final song = await repository().song('selam');
      watch.stop();

      expect(song, isNotNull);
      expect(watch.elapsed, lessThan(const Duration(milliseconds: 300)));
    });
  });

  group('the other reads use the cache only', () {
    test('recordings and timing come from the cached document', () async {
      final r = repository();
      expect(await r.recordings('selam'), isEmpty);
      expect(await r.timing('selam-r'), isNull);
      expect(catalog.songCalls, isEmpty);

      await r.song('selam');

      expect(
        [for (final rec in await r.recordings('selam')) rec.id],
        ['selam-r'],
      );
      expect((await repository().timing('selam-r'))?.starts, const [
        Duration(seconds: 1),
      ]);
    });

    test('songs and search list cached songs the index still lists', () async {
      final r = repository();
      await r.song('selam');
      await r.song('amlak');
      expect([for (final s in await r.songs()) s.id], ['amlak', 'selam']);

      catalog.entries = [
        for (final e in await catalog.index())
          if (e.id != 'amlak') e,
      ];
      await refreshIndex();

      expect([for (final s in await r.songs()) s.id], ['selam']);
      expect([for (final s in await r.search('amlak')) s.id], isEmpty);
      expect([for (final s in await r.search('selam')) s.id], ['selam']);
      expect(catalog.songCalls, ['selam', 'amlak']);
    });
  });
}
