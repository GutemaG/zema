import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/app/database/database_provider.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/preferences_provider.dart';
import 'package:zema/features/identify/application/library_search.dart';
import 'package:zema/features/identify/application/track_sound_links.dart';
import 'package:zema/features/identify/data/audio_decoder.dart';
import 'package:zema/features/lyrics/application/lyrics_links.dart';
import 'package:zema/features/lyrics/application/track_lyrics.dart';
import 'package:zema/features/lyrics/data/lyrics_links_repository.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';

const _s = Duration(seconds: 1);

/// Decodes every file to [length] of silence, or nothing when [unreadable].
class _Decoder implements AudioDecoder {
  Duration length = const Duration(seconds: 105);
  bool unreadable = false;
  var decoded = 0;

  @override
  Future<DecodedAudio?> decode(
    String uri, {
    Duration maxLength = maxDecodedLength,
  }) async {
    decoded++;
    expect(maxLength, soundDecodeLength);
    if (unreadable) return null;
    final samples = length.inMilliseconds * fingerprintSampleRate ~/ 1000;
    return DecodedAudio(pcm16: Uint8List(samples * 2));
  }

  @override
  Future<DecodeDevice?> device() async => null;
}

AudioMatch _at(String id, Duration position) => AudioMatch(
  recordingId: id,
  position: position,
  score: 50,
  playbackSpeed: 1,
  ambiguousPosition: false,
);

/// Answers each excerpt in turn with the next of [answers].
class _Search implements SoundSearch {
  _Search(this.answers);

  List<List<AudioMatch>> answers;
  var asked = 0;
  final excluded = <String?>[];

  @override
  int recordingCount = 10;

  @override
  Map<String, OfflineRecording> catalogRecordings = {
    'rec-a': (songId: 'song-a', duration: const Duration(minutes: 4)),
  };

  @override
  Future<LibraryHeard> identify(
    Float32List pcm,
    int rate, {
    String? exclude,
    int limit = 1,
  }) async {
    expect(pcm.length, soundExcerptLength.inSeconds * fingerprintSampleRate);
    excluded.add(exclude);
    final answer = answers[asked++ % answers.length];
    return (
      matches: answer,
      queries: [
        AudioFingerprint(
          hashes: Uint32List(0),
          frames: Uint32List(0),
          frameCount: 0,
        ),
      ],
    );
  }
}

class _Catalog implements AudioCatalog {
  List<List<CatalogAudioMatch>> answers = [];
  ZemaFailure? failure;
  var asked = 0;

  @override
  Future<List<CatalogAudioMatch>> identify(
    List<AudioFingerprint> queries, {
    required String installId,
    int limit = 3,
  }) async {
    if (failure case final f?) throw f;
    return answers[asked++ % answers.length];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CatalogAudioMatch _server(String song, String recording, Duration at) =>
    CatalogAudioMatch(
      songId: song,
      match: _at(recording, at),
      recordingDuration: const Duration(minutes: 4),
    );

void main() {
  test('excerpts: a quarter in and near the end, none under 30 s', () {
    expect(soundExcerptStarts(const Duration(seconds: 29)), isEmpty);
    expect(soundExcerptStarts(const Duration(seconds: 105)), [
      _s * 26.25,
      _s * 90,
    ]);
    expect(soundExcerptStarts(const Duration(seconds: 40)), [
      _s * 10,
      const Duration(milliseconds: 27500),
    ]);
  });

  group('two excerpts agree', () {
    const a = (songId: 's', recordingId: 'r', offset: Duration(seconds: 3));

    test('on song and offset', () {
      expect(
        agreedMatch(a, (
          songId: 's',
          recordingId: null,
          offset: const Duration(milliseconds: 3200),
        )),
        a,
      );
    });

    test('on the song only: no offset, no recording', () {
      expect(agreedMatch(a, (songId: 's', recordingId: 'r', offset: _s * 60)), (
        songId: 's',
        recordingId: null,
        offset: Duration.zero,
      ));
    });

    test('not when songs differ or one found nothing', () {
      expect(
        agreedMatch(a, (songId: 'x', recordingId: 'r', offset: _s * 3)),
        isNull,
      );
      expect(agreedMatch(a, null), isNull);
    });
  });

  group('SoundLinker', () {
    late ZemaDatabase db;
    late List<Track> tracks;
    late _Decoder decoder;
    late _Search search;
    late _Catalog catalog;
    late Map<int, LyricsLink> links;

    SoundLinker linker({bool withCatalog = false}) => SoundLinker(
      decoder: decoder,
      search: () async => search,
      store: db.fingerprintsDao,
      links: () async => links,
      catalog: withCatalog ? catalog : null,
      installId: () => 'install-1234',
    );

    setUp(() async {
      db = ZemaDatabase(NativeDatabase.memory());
      await db.libraryDao.applyReconciliation(
        reconcileTracks(
          stored: const [],
          scan: [
            scannedAudio(1, '/m/track01.mp3', title: 'track01'),
            scannedAudio(2, '/m/known.mp3', title: 'Known'),
          ],
        ),
      );
      tracks = await db.libraryDao.allTracks();
      decoder = _Decoder();
      search = _Search([]);
      catalog = _Catalog();
      links = {};
    });
    tearDown(() => db.close());

    Track track(int i) => tracks[i];

    test(
      'a catalog recording on the phone, with how late the file runs',
      () async {
        search.answers = [
          [
            _at(
              '${catalogSearchPrefix}rec-a',
              const Duration(milliseconds: 23250),
            ),
          ],
          [_at('${catalogSearchPrefix}rec-a', const Duration(seconds: 87))],
        ];
        final found = await linker().check(track(0));
        expect(found, (songId: 'song-a', recordingId: 'rec-a', offset: _s * 3));
        expect(search.excluded, ['${track(0).id}', '${track(0).id}']);

        final row = (await db.fingerprintsDao.audioMatch(track(0).id))!;
        expect(row.songId, 'song-a');
        expect(row.offsetMs, 3000);

        expect(await linker().check(track(0)), found);
        expect(decoder.decoded, 1, reason: 'kept, not decoded again');
      },
    );

    test('a library file lends its song', () async {
      final other = track(1).id;
      links = {other: const LyricsLink(songId: 'song-b', manual: false)};
      search.answers = [
        [_at('$other', _s * 26.25)],
        [_at('$other', _s * 90)],
      ];
      expect(await linker().check(track(0)), (
        songId: 'song-b',
        recordingId: null,
        offset: Duration.zero,
      ));
    });

    test('not one marked as having no lyrics', () async {
      final other = track(1).id;
      links = {other: const LyricsLink(songId: null, manual: true)};
      search.answers = [
        [_at('$other', _s * 26.25)],
      ];
      expect(await linker().check(track(0)), isNull);
    });

    test(
      'nothing found: checked again only when there is more to search',
      () async {
        search.answers = [[]];
        expect(await linker().check(track(0)), isNull);
        await linker().check(track(0));
        expect(decoder.decoded, 1);

        search.recordingCount = 11;
        await linker().check(track(0));
        expect(decoder.decoded, 2);
      },
    );

    test('a short or unreadable file is saved as no match', () async {
      decoder.length = const Duration(seconds: 20);
      expect(await linker().check(track(0)), isNull);
      expect(search.asked, 0);
      decoder.unreadable = true;
      expect(await linker().check(track(1)), isNull);
      expect(await db.fingerprintsDao.audioMatch(track(1).id), isNotNull);
    });

    test('the server, when allowed and the phone finds nothing', () async {
      search.answers = [[]];
      catalog.answers = [
        [_server('song-c', 'rec-c', _s * 26.25)],
        [_server('song-c', 'rec-c', _s * 90)],
      ];
      expect(await linker().check(track(0)), isNull);
      expect(catalog.asked, 0, reason: 'not while not playing');

      expect(await linker(withCatalog: true).check(track(0), server: true), (
        songId: 'song-c',
        recordingId: 'rec-c',
        offset: Duration.zero,
      ));
      expect(catalog.asked, 2);
    });

    test('offline: the server is asked the next time', () async {
      search.answers = [[]];
      catalog.failure = const NetworkFailure('offline');
      await linker(withCatalog: true).check(track(0), server: true);
      expect(
        (await db.fingerprintsDao.audioMatch(track(0).id))!.askedServer,
        isFalse,
      );

      catalog
        ..failure = null
        ..answers = [[]];
      await linker(withCatalog: true).check(track(0), server: true);
      expect(decoder.decoded, 2);
      expect(
        (await db.fingerprintsDao.audioMatch(track(0).id))!.askedServer,
        isTrue,
      );
      await linker(withCatalog: true).check(track(0), server: true);
      expect(decoder.decoded, 2);
    });

    test('a changed file is checked again', () async {
      search.answers = [
        [_at('${catalogSearchPrefix}rec-a', _s * 26.25)],
      ];
      await linker().check(track(0));
      final changed = Track(
        id: track(0).id,
        mediaStoreId: track(0).mediaStoreId,
        uri: track(0).uri,
        path: track(0).path,
        title: track(0).title,
        duration: track(0).duration,
        sizeBytes: track(0).sizeBytes + 1,
        dateAdded: track(0).dateAdded,
      );
      await linker().check(changed);
      expect(decoder.decoded, 2);
    });

    group('in the lyrics', () {
      late ProviderContainer container;

      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            sharedPreferencesProvider.overrideWithValue(
              await SharedPreferences.getInstance(),
            ),
          ],
        );
        addTearDown(container.dispose);
        container.listen(trackAudioMatchesProvider, (_, _) {});
        container.listen(lyricsLinksProvider, (_, _) {});
        search.answers = [
          [
            _at(
              '${catalogSearchPrefix}rec-a',
              const Duration(milliseconds: 23250),
            ),
          ],
        ];
        await linker().check(track(0));
        await container.read(trackAudioMatchesProvider.future);
        await container.read(lyricsLinksProvider.future);
        await pumpEventQueue();
      });

      test('the match decides, unless the user linked the track', () async {
        expect(
          container.read(trackSoundMatchProvider(track(0).id))?.songId,
          'song-a',
        );
        await db.lyricsLinksDao.setManual(track(0).id, 'song-z');
        await container.read(lyricsLinksProvider.future);
        await pumpEventQueue();
        expect(container.read(trackSoundMatchProvider(track(0).id)), isNull);
      });

      test('its offset moves the timing', () {
        const song = Song(
          id: 'song-a',
          title: 'A',
          sections: [],
          playOrder: [],
        );
        final lyrics = TrackLyrics(
          song: song,
          lines: const [],
          recording: const Recording(
            id: 'rec-a',
            songId: 'song-a',
            source: RecordingSource.localFile,
            offset: Duration(milliseconds: 200),
          ),
          soundOffset: _s * 3,
        );
        expect(
          container.read(lyricsShiftProvider(lyrics)),
          const Duration(milliseconds: 3200),
        );
      });
    });
  });
}
