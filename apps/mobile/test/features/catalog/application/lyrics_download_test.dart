import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/backend/backend_providers.dart';
import 'package:zema/app/database/database_provider.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/preferences_provider.dart';
import 'package:zema/features/catalog/application/lyrics_download.dart';
import 'package:zema/features/lyrics/application/lyrics_links.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_catalog.dart';
import '../../../helpers/fake_library.dart';

/// Ten songs, so Download all runs in batches of 4, 4 and 2.
final _ids = [for (var i = 0; i < 10; i++) 'song-$i'];

/// Serves [_ids] with one verse each; [failOn] fails that song's fetch.
class _Lyrics implements LyricsRepository {
  String? failOn;

  @override
  Future<List<Song>> songs() async => [for (final id in _ids) _song(id)];
  @override
  Future<Song?> song(String id) async {
    if (id == failOn) throw const NetworkFailure('offline');
    return _ids.contains(id) ? _song(id) : null;
  }

  @override
  Future<List<Recording>> recordings(String songId) async => const [];
  @override
  Future<SyncTiming?> timing(String recordingId) async => null;
  @override
  Future<List<Song>> search(String query) async => const [];

  static Song _song(String id) => Song(
    id: id,
    title: id,
    sections: const [
      LyricSection(
        id: 'v1',
        kind: SectionKind.verse,
        lines: [LyricLine('Amen')],
      ),
    ],
  );
}

void main() {
  late ZemaDatabase db;
  late _Lyrics lyrics;
  late FakeCatalogRepository catalog;
  late ProviderContainer container;
  late List<LyricsDownload> states;

  LyricsDownloader downloader() =>
      container.read(lyricsDownloaderProvider.notifier);

  Future<List<String>> cached() async => [
    for (final c in await db.cachedSongsDao.watchSongs().first)
      c.document.song.id,
  ];

  setUp(() async {
    db = ZemaDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    lyrics = _Lyrics();
    catalog = FakeCatalogRepository(lyrics: lyrics);
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(preferences),
        catalogRepositoryProvider.overrideWithValue(catalog),
      ],
    );
    states = [];
    container.listen(
      lyricsDownloaderProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('starts idle', () {
    expect(states.single.status, LyricsDownloadStatus.idle);
  });

  test('downloads every song in the index, in batches of 4, with '
      'progress', () async {
    await downloader().start();

    expect(await cached(), unorderedEquals(_ids));
    expect(catalog.indexCalls, 1); // the index was missing, so fetched
    expect(
      [
        for (final s in states)
          if (s.running) (s.done, s.total),
      ],
      [(0, 0), (0, 10), (4, 10), (8, 10), (10, 10)],
    );
    expect(states.last.status, LyricsDownloadStatus.finished);
    expect((states.last.done, states.last.total), (10, 10));
  });

  test('a second run skips songs already up to date', () async {
    await downloader().start();
    catalog.songCalls.clear();

    await downloader().start();

    expect(catalog.songCalls, isEmpty);
    expect(catalog.indexCalls, 1); // the index is fresh, so not fetched again
    expect(states.last.status, LyricsDownloadStatus.finished);
    expect(states.last.done, 10);
  });

  test('start while running returns at once and keeps the progress', () async {
    final gate = catalog.songGate = Completer<void>();
    final first = downloader().start();
    await pumpEventQueue();
    final before = states.length;

    var secondDone = false;
    unawaited(downloader().start().then((_) => secondDone = true));
    await pumpEventQueue();
    expect(secondDone, isTrue);
    expect(states, hasLength(before)); // no new state: progress not reset

    gate.complete();
    await first;
    expect(catalog.indexCalls, 1);
    expect(catalog.songCalls, hasLength(10));
    expect([
      for (final s in states)
        if (s.running && s.total == 0) s,
    ], hasLength(1));
  });

  test('Cancel stops after the batch in progress, which is kept', () async {
    final gate = catalog.songGate = Completer<void>();
    final run = downloader().start();
    await pumpEventQueue();
    expect(catalog.songCalls, hasLength(4));

    downloader().cancel();
    gate.complete();
    await run;

    expect(await cached(), hasLength(4));
    expect(catalog.songCalls, hasLength(4));
    expect(states.last.status, LyricsDownloadStatus.cancelled);
    expect((states.last.done, states.last.total), (4, 10));
  });

  test('a failure stops after its batch and keeps what finished', () async {
    lyrics.failOn = 'song-5';
    await downloader().start();

    // The second batch (4–7) ran; three of its songs were saved.
    expect(await cached(), hasLength(7));
    expect(await cached(), isNot(contains('song-5')));
    expect(catalog.songCalls, hasLength(8));
    final last = states.last;
    expect(last.status, LyricsDownloadStatus.failed);
    expect(last.failure, isA<NetworkFailure>());
    expect((last.done, last.total), (7, 10));
  });

  test('offline, the saved index is used', () async {
    // A saved index with no refresh time counts as stale, so it is fetched.
    await db.catalogDao.replaceAll(await catalog.index());
    catalog
      ..indexCalls = 0
      ..failure = const NetworkFailure('offline');

    await downloader().start();

    expect(catalog.indexCalls, 1);
    expect(states.last.status, LyricsDownloadStatus.failed);
    expect(states.last.total, 10); // from the saved index
    expect(states.last.done, 0);
  });

  test('Clear removes downloaded songs; the index and links stay', () async {
    await downloader().start();
    final library = db.libraryDao;
    await library.applyReconciliation(
      reconcileTracks(
        stored: await library.allTracks(),
        scan: [scannedAudio(1, '/m/1.mp3', title: 'Song 0')],
      ),
    );
    final trackId = (await library.allTracks()).single.id;
    await db.lyricsLinksDao.setManual(trackId, 'song-0');
    final song = container.listen(songProvider('song-0'), (_, _) {});
    addTearDown(song.close);
    await container.read(songProvider('song-0').future);

    await downloader().clear();

    expect(await cached(), isEmpty);
    expect(await db.catalogDao.watchEntries().first, hasLength(10));
    final links = await db.lyricsLinksDao.watchLinks().first;
    expect(links.single.songId, 'song-0');
    expect(states.last.status, LyricsDownloadStatus.idle);
    // songProvider is read again: offline, the cleared song can't be shown.
    catalog.failure = const NetworkFailure('offline');
    await expectLater(
      container.read(songProvider('song-0').future),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('Clear is refused while a download runs', () async {
    await db.cachedSongsDao.save(
      SongDocument(song: _Lyrics._song('old'), recordings: [], timings: []),
      1,
    );
    final gate = catalog.songGate = Completer<void>();
    final run = downloader().start();
    await pumpEventQueue();

    await downloader().clear();
    expect(await cached(), contains('old'));

    gate.complete();
    await run;
  });
}
