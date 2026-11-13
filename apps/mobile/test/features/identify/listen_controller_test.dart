import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/backend/backend_providers.dart';
import 'package:zema/app/database/database_provider.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/app/preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zema/features/identify/application/library_fingerprints.dart';
import 'package:zema/features/identify/application/listen_controller.dart';
import 'package:zema/features/identify/application/pending_lookups.dart';
import 'package:zema/features/identify/application/quick_listen.dart';
import 'package:zema/features/identify/data/audio_decoder.dart';
import 'package:zema/features/identify/data/microphone.dart';
import 'package:zema/features/library/application/library_providers.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';

const _rate = fingerprintSampleRate;

/// A made-up song: tones with overtones, different for every [seed].
Float32List _song(int seed, double seconds) {
  final random = math.Random(seed);
  final out = Float32List((seconds * _rate).round());
  var at = 0;
  while (at < out.length) {
    final length = ((0.2 + random.nextDouble() * 0.3) * _rate).round();
    final base = 150 + random.nextDouble() * 1000;
    for (var i = 0; i < length && at + i < out.length; i++) {
      final t = i / _rate;
      out[at + i] =
          0.3 *
          math.min(1, i / 200) *
          math.exp(-3 * t) *
          (math.sin(2 * math.pi * base * t) +
              0.5 * math.sin(2 * math.pi * base * 2.01 * t));
    }
    at += length;
  }
  return out;
}

/// Decodes `content://…/<mediaStoreId>` to [songs] by that ID; others fail.
/// While [broken], it throws instead.
class _FakeDecoder implements AudioDecoder {
  _FakeDecoder(this.songs);

  final Map<int, Float32List> songs;
  var decoded = 0;
  var broken = false;

  @override
  Future<DecodeDevice?> device() async =>
      const DecodeDevice(cores: 8, powerSave: false);

  @override
  Future<DecodedAudio?> decode(String uri, {Duration? maxLength}) async {
    decoded++;
    if (broken) throw StateError('Decoder broke');
    final pcm = songs[int.parse(uri.split('/').last)];
    if (pcm == null) return null;
    final bytes = ByteData(pcm.length * 2);
    for (var i = 0; i < pcm.length; i++) {
      bytes.setInt16(i * 2, (pcm[i] * 32767).round(), Endian.little);
    }
    return DecodedAudio(pcm16: bytes.buffer.asUint8List(), codec: 'fake');
  }
}

/// Plays [pcm] into the "microphone" in 0.5 s chunks, all at once, or passes
/// on [stream]. Starting waits for [gate], then throws [startError] if set.
class _FakeMicrophone implements Microphone {
  Float32List pcm = Float32List(0);
  bool allow = true;
  Future<void>? gate;
  Object? startError;
  Stream<Float32List>? stream;
  var started = 0;
  var stopped = 0;

  @override
  int get sampleRate => _rate;

  @override
  Future<bool> requestPermission() async => allow;

  @override
  Future<Stream<Float32List>> start() async {
    started++;
    await gate;
    if (startError case final error?) throw error;
    if (stream case final stream?) return stream;
    const chunk = _rate ~/ 2;
    return Stream.fromIterable([
      for (var at = 0; at < pcm.length; at += chunk)
        Float32List.sublistView(pcm, at, math.min(pcm.length, at + chunk)),
    ]);
  }

  @override
  Future<void> stop() async => stopped++;
}

/// The catalog: one recording, [song], of the song "selam"; or offline.
class _FakeCatalog implements AudioCatalog {
  _FakeCatalog(Float32List song) {
    _index.add('selam-rec', const Fingerprinter().fingerprint(song));
  }

  final _index = FingerprintIndex();
  var offline = false;
  var asked = 0;

  @override
  Future<List<CatalogAudioMatch>> identify(
    List<AudioFingerprint> queries, {
    required String installId,
    int limit = 3,
  }) async {
    asked++;
    if (offline) throw const NetworkFailure('offline');
    return [
      for (final match in _index.match(queries, limit: limit))
        CatalogAudioMatch(
          songId: 'selam',
          match: match,
          recordingDuration: const Duration(seconds: 40),
        ),
    ];
  }

  @override
  Future<Set<String>> missingFingerprints(List<String> recordingIds) async =>
      const {};

  @override
  Future<FingerprintShare> shareFingerprint(
    String recordingId,
    AudioFingerprint fingerprint, {
    required String installId,
  }) async => FingerprintShare.notNeeded;
}

void main() {
  late ZemaDatabase db;
  late SharedPreferences preferences;
  _FakeCatalog? catalog;
  late ProviderContainer container;
  late _FakeMicrophone microphone;
  late _FakeDecoder decoder;
  late List<Track> tracks;
  final songs = {1: _song(1, 40), 2: _song(2, 40)};

  ProviderContainer newContainer() {
    final made = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        libraryTracksProvider.overrideWith((ref) => Stream.value(tracks)),
        microphoneProvider.overrideWithValue(microphone),
        audioDecoderProvider.overrideWithValue(decoder),
        audioCatalogProvider.overrideWithValue(catalog),
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    // As the Listen screen does; unwatched providers are paused.
    made.listen(libraryFingerprintsProvider, (_, _) {});
    return made;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    db = ZemaDatabase(NativeDatabase.memory());
    await db.libraryDao.applyReconciliation(
      reconcileTracks(
        stored: const [],
        scan: [
          scannedAudio(1, '/music/one.mp3', title: 'One'),
          scannedAudio(2, '/music/two.mp3', title: 'Two'),
          scannedAudio(3, '/music/broken.mp3', title: 'Broken'),
        ],
      ),
    );
    tracks = await db.libraryDao.allTracks();
    microphone = _FakeMicrophone();
    decoder = _FakeDecoder(songs);
    container = newContainer();
  });

  tearDown(() async {
    catalog = null;
    container.dispose();
    await db.close();
  });

  Future<ListenState> settled() async {
    for (
      var i = 0;
      i < 100 && container.read(listenControllerProvider) is Listening;
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    // Let a stop that's under way finish.
    await Future<void>.delayed(Duration.zero);
    return container.read(listenControllerProvider);
  }

  Future<ListenState> listenUntilDone() async {
    final sub = container.listen(listenControllerProvider, (_, _) {});
    await container.read(listenControllerProvider.notifier).listen();
    final state = await settled();
    sub.close();
    return state;
  }

  /// Waits for the microphone to be asked to start.
  Future<void> untilStarted() async {
    for (var i = 0; i < 200 && microphone.started == 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(microphone.started, 1);
  }

  test(
    'fingerprints the library once, setting aside files it cannot read',
    () async {
      final library = container.read(libraryFingerprintsProvider.notifier);
      await library.start();
      final state = container.read(libraryFingerprintsProvider);
      expect(state.ready, 2);
      expect(state.unreadable, 1);
      expect(state.done, isTrue);
      expect(decoder.decoded, 3);

      await library.start();
      expect(decoder.decoded, 3, reason: 'nothing left to do');
    },
  );

  test('tries a file it could not read again when Zema starts again', () async {
    await container.read(libraryFingerprintsProvider.notifier).start();
    expect(decoder.decoded, 3);

    decoder.songs[3] = _song(3, 40);
    addTearDown(() => decoder.songs.remove(3));
    final nextRun = newContainer();
    addTearDown(nextRun.dispose);
    await nextRun.read(libraryFingerprintsProvider.notifier).start();

    expect(decoder.decoded, 4, reason: 'only the file that failed');
    final state = nextRun.read(libraryFingerprintsProvider);
    expect(state.ready, 3);
    expect(state.unreadable, 0);
  });

  test('a decoder that throws does not stop the other songs', () async {
    decoder.broken = true;
    await container.read(libraryFingerprintsProvider.notifier).start();

    final state = container.read(libraryFingerprintsProvider);
    expect(decoder.decoded, 3);
    expect(state.ready, 0);
    expect(state.unreadable, 3);
    expect(await db.fingerprintsDao.all(), isEmpty);
  });

  test('a damaged fingerprint is deleted and does not stop Listen', () async {
    await container.read(libraryFingerprintsProvider.notifier).start();
    final broken = tracks.firstWhere((t) => t.title == 'One');
    await db.fingerprintsDao.put(
      broken.id,
      version: fingerprintVersion,
      sizeBytes: broken.sizeBytes,
      data: Uint8List.fromList([fingerprintVersion, 1, 0xff, 0xff, 0x7f]),
    );
    microphone.pcm = Float32List.sublistView(songs[2]!, 5 * _rate, 15 * _rate);

    final state = await listenUntilDone();

    expect(state, isA<ListenFound>());
    expect((state as ListenFound).track!.title, 'Two');
    final left = await db.fingerprintsDao.all();
    expect(left.map((r) => r.trackId), isNot(contains(broken.id)));
  });

  test(
    'identifies a song heard from the middle, at the right moment',
    () async {
      await container.read(libraryFingerprintsProvider.notifier).start();
      final tracks = await db.libraryDao.allTracks();
      microphone.pcm = Float32List.sublistView(
        songs[2]!,
        20 * _rate,
        30 * _rate,
      );

      final state = await listenUntilDone();

      expect(state, isA<ListenFound>());
      final found = state as ListenFound;
      expect(found.track!.id, tracks.firstWhere((t) => t.title == 'Two').id);
      expect(found.match.position.inMilliseconds, closeTo(20000, 50));
      // Ten seconds after listening started, the song is ten seconds on.
      expect(
        found
            .positionAt(found.startedAt.add(const Duration(seconds: 10)))
            .inMilliseconds,
        closeTo(30000, 50),
      );
      expect(found.sure, isTrue);
      expect(microphone.stopped, 1);
      final history = await db.identifiedDao.watchAll().first;
      expect(history.map((r) => r.trackId), [found.track!.id]);
    },
  );

  test('a part the song repeats is found, but not sure of the place', () async {
    final part = Float32List.sublistView(
      _song(7, 13),
      0,
      12 * 43 * fingerprintHop,
    );
    final repeating = Float32List(part.length * 3)
      ..setAll(0, part)
      ..setAll(part.length, _song(8, 12))
      ..setAll(part.length * 2, part);
    decoder.songs[3] = repeating;
    addTearDown(() => decoder.songs.remove(3));
    await container.read(libraryFingerprintsProvider.notifier).start();
    microphone.pcm = Float32List.sublistView(part, _rate, 11 * _rate);

    final state = await listenUntilDone();

    expect(state, isA<ListenFound>());
    final found = state as ListenFound;
    expect(found.track!.title, 'Broken');
    expect(found.sure, isFalse);
  });

  group('the catalog', () {
    final selam = _song(9, 40);

    setUp(() async {
      await db.catalogDao.replaceAll([
        CatalogEntry(
          id: 'selam',
          title: 'Selam',
          artist: 'Choir',
          synced: true,
          version: 1,
          approvedAt: DateTime.utc(2026, 10, 1),
        ),
      ]);
      container.dispose();
      catalog = _FakeCatalog(selam);
      container = newContainer();
    });

    test(
      'finds a song the library does not have, with no library at all',
      () async {
        microphone.pcm = Float32List.sublistView(selam, 5 * _rate, 15 * _rate);

        final state = await listenUntilDone();

        expect(state, isA<ListenFound>());
        final found = state as ListenFound;
        expect(found.track, isNull);
        expect(found.song!.id, 'selam');
        expect(found.title, 'Selam');
        expect(found.match.recordingId, 'selam-rec');
        expect(found.match.position.inMilliseconds, closeTo(5000, 50));
        expect(found.duration, const Duration(seconds: 40));
        expect(found.sure, isTrue);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final history = await db.identifiedDao.watchAll().first;
        expect(history.single.songId, 'selam');
        expect(history.single.trackId, isNull);
      },
    );

    test('is asked only when the library has no sure match', () async {
      await container.read(libraryFingerprintsProvider.notifier).start();
      microphone.pcm = Float32List.sublistView(
        songs[2]!,
        5 * _rate,
        15 * _rate,
      );

      final state = await listenUntilDone();

      expect((state as ListenFound).track!.title, 'Two');
      expect(catalog!.asked, 0);
    });

    test('offline, what was heard is kept and found once online', () async {
      catalog!.offline = true;
      microphone.pcm = Float32List.sublistView(selam, 5 * _rate, 15 * _rate);

      expect(await listenUntilDone(), isA<ListenSavedForLater>());
      expect(catalog!.asked, listenCheckpoints.length);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(await db.identifiedDao.pending(), hasLength(1));

      final found = <CatalogEntry>[];
      final sub = container.read(lateMatchesProvider).stream.listen(found.add);
      addTearDown(sub.cancel);
      await container.read(pendingLookupSenderProvider).flush();
      expect(
        await db.identifiedDao.pending(),
        hasLength(1),
        reason: 'still offline',
      );

      catalog!.offline = false;
      await container.read(pendingLookupSenderProvider).flush();
      await Future<void>.delayed(Duration.zero);
      expect(await db.identifiedDao.pending(), isEmpty);
      expect(found.single.id, 'selam');
      expect((await db.identifiedDao.watchAll().first).single.songId, 'selam');
    });

    test('a song the catalog does not have is not kept', () async {
      microphone.pcm = Float32List.sublistView(_song(10, 20), 0, 10 * _rate);

      expect(await listenUntilDone(), isA<ListenNotFound>());
      expect(await db.identifiedDao.pending(), isEmpty);
    });
  });

  test('queries survive being kept, speeds and all', () {
    final queries = const Fingerprinter().queries(_song(11, 4));
    final back = decodeQueries(encodeQueries(queries));
    expect(back, hasLength(queries.length));
    for (final (i, q) in back.indexed) {
      expect(q.hashes, queries[i].hashes);
      expect(q.frames, queries[i].frames);
      expect(q.speed, queries[i].speed);
    }
    expect(
      () => decodeQueries(Uint8List.fromList([0, 0, 0, 9, 1])),
      throwsA(isA<FingerprintFormatFailure>()),
    );
  });

  test('a match handed over from the lock screen is shown', () async {
    final track = tracks.first;
    ListenFound handed(Duration position) => ListenFound(
      track: track,
      match: AudioMatch(
        recordingId: '${track.id}',
        position: position,
        score: 20,
        playbackSpeed: 1,
        ambiguousPosition: false,
      ),
      startedAt: DateTime(2026),
    );
    container
        .read(pendingMatchProvider.notifier)
        .set(handed(const Duration(seconds: 5)));
    final sub = container.listen(listenControllerProvider, (_, _) {});
    addTearDown(sub.close);

    final first = container.read(listenControllerProvider);
    expect((first as ListenFound).match.position, const Duration(seconds: 5));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(pendingMatchProvider), isNull);

    container
        .read(pendingMatchProvider.notifier)
        .set(handed(const Duration(seconds: 9)));
    final next = container.read(listenControllerProvider);
    expect((next as ListenFound).match.position, const Duration(seconds: 9));
    expect(container.read(pendingMatchProvider), isNull);
  });

  test('playing a match starts inside the song', () {
    final track = tracks.first.copyWith(duration: const Duration(minutes: 3));
    final started = DateTime(2026);
    ListenFound at(Duration position) => ListenFound(
      track: track,
      match: AudioMatch(
        recordingId: '${track.id}',
        position: position,
        score: 20,
        playbackSpeed: 1,
        ambiguousPosition: false,
      ),
      startedAt: started,
    );
    final later = started.add(const Duration(seconds: 10));

    expect(
      at(const Duration(minutes: 1)).playFrom(later),
      const Duration(seconds: 70),
    );
    expect(at(const Duration(seconds: -20)).playFrom(later), Duration.zero);
    final over = at(const Duration(minutes: 3));
    expect(over.endedAt(later), isTrue);
    expect(over.playFrom(later), Duration.zero);
  });

  test('a song that is not on the phone is not found', () async {
    await container.read(libraryFingerprintsProvider.notifier).start();
    microphone.pcm = _song(9, 12);

    expect(await listenUntilDone(), isA<ListenNotFound>());
    expect(microphone.stopped, 1);
    expect(await db.identifiedDao.watchAll().first, isEmpty);
  });

  test('without fingerprints there is nothing to match', () async {
    microphone.pcm = songs[1]!;
    expect(await listenUntilDone(), isA<ListenNothingToMatch>());
    expect(microphone.started, 0);
  });

  test('a refused microphone says so, without recording', () async {
    microphone.allow = false;
    expect(await listenUntilDone(), isA<ListenDenied>());
    expect(microphone.started, 0);
  });

  group('the search', () {
    setUp(() => container.read(libraryFingerprintsProvider.notifier).start());

    test('is built once while the fingerprints stay the same', () async {
      final states = <ListenState>[];
      final sub = container.listen(
        listenControllerProvider,
        (_, next) => states.add(next),
      );
      addTearDown(sub.close);
      final controller = container.read(listenControllerProvider.notifier);
      microphone.pcm = Float32List.sublistView(
        songs[2]!,
        20 * _rate,
        30 * _rate,
      );

      await controller.listen();
      expect(await settled(), isA<ListenFound>());
      expect(states.whereType<ListenLoading>(), hasLength(1));

      states.clear();
      await controller.listen();
      expect(await settled(), isA<ListenFound>());
      expect(states.whereType<ListenLoading>(), isEmpty);
    });

    test('is built again when the fingerprints change', () async {
      final sub = container.listen(listenControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final controller = container.read(listenControllerProvider.notifier);
      microphone.pcm = Float32List.sublistView(
        songs[2]!,
        20 * _rate,
        30 * _rate,
      );
      await controller.listen();
      expect(await settled(), isA<ListenFound>());

      await db.fingerprintsDao.remove([for (final t in tracks) t.id]);
      await controller.listen();

      expect(await settled(), isA<ListenNothingToMatch>());
    });

    test('prepared ahead is used by listening', () async {
      final states = <ListenState>[];
      final sub = container.listen(
        listenControllerProvider,
        (_, next) => states.add(next),
      );
      addTearDown(sub.close);
      final controller = container.read(listenControllerProvider.notifier);
      microphone.pcm = Float32List.sublistView(
        songs[1]!,
        20 * _rate,
        30 * _rate,
      );

      await controller.prepare();
      await controller.listen();

      expect(await settled(), isA<ListenFound>());
      expect(states.whereType<ListenLoading>(), isEmpty);
    });

    test('reads only usable rows, in pages', () async {
      final dao = db.fingerprintsDao;
      final first = tracks[0];
      final second = tracks[1];
      final third = tracks[2];
      final data = Uint8List.fromList([1, 2, 3]);
      await dao.remove([for (final t in tracks) t.id]);
      await dao.put(first.id, version: 1, sizeBytes: 10, data: data);
      await dao.put(second.id, version: 1, sizeBytes: 20, data: Uint8List(0));
      await dao.put(third.id, version: 2, sizeBytes: 30, data: data);

      expect(await dao.sizes(1), {first.id: 10});
      expect(await dao.page(1, after: -1, limit: 10), hasLength(1));
      expect(await dao.page(1, after: first.id, limit: 10), isEmpty);
    });
  });

  group('the microphone', () {
    setUp(() => container.read(libraryFingerprintsProvider.notifier).start());

    test('stops when listening is cancelled while it starts', () async {
      final gate = Completer<void>();
      microphone.gate = gate.future;
      final samples = StreamController<Float32List>();
      microphone.stream = samples.stream;
      final sub = container.listen(listenControllerProvider, (_, _) {});
      addTearDown(sub.close);
      final controller = container.read(listenControllerProvider.notifier);

      final listening = controller.listen();
      await untilStarted();
      final cancelled = controller.cancel();
      expect(container.read(listenControllerProvider), isA<ListenIdle>());
      gate.complete();
      await Future.wait([listening, cancelled]);

      expect(microphone.stopped, 1);
      expect(samples.hasListener, isFalse);
    });

    test('stops when the screen is left while it starts', () async {
      final gate = Completer<void>();
      microphone.gate = gate.future;
      final samples = StreamController<Float32List>();
      microphone.stream = samples.stream;
      final sub = container.listen(listenControllerProvider, (_, _) {});
      final listening = container
          .read(listenControllerProvider.notifier)
          .listen();
      await untilStarted();

      sub.close();
      await container.pump();
      gate.complete();
      await listening;
      await Future<void>.delayed(Duration.zero);

      expect(microphone.stopped, 1);
      expect(samples.hasListener, isFalse);
    });

    test('that will not start says so', () async {
      microphone.startError = StateError('In use by a call');

      expect(await listenUntilDone(), isA<ListenFailed>());
      expect(microphone.stopped, 0, reason: 'it never started');
    });

    test('that fails while listening says so, and stops', () async {
      final samples = StreamController<Float32List>();
      microphone.stream = samples.stream;
      final sub = container.listen(listenControllerProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(listenControllerProvider.notifier).listen();
      samples.addError(StateError('Taken by another app'));

      expect(await settled(), isA<ListenFailed>());
      expect(microphone.stopped, 1);
    });

    test('that gives no sound is given up on, and stops', () async {
      var now = DateTime.utc(2026, 11, 5, 12);
      final samples = StreamController<Float32List>();
      microphone.stream = samples.stream;
      final sub = container.listen(listenControllerProvider, (_, _) {});
      addTearDown(sub.close);

      await withClock(
        Clock(() => now),
        () => container.read(listenControllerProvider.notifier).listen(),
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(container.read(listenControllerProvider), isA<Listening>());

      now = now.add(listenCheckpoints.last + listenPatience);
      now = now.add(const Duration(seconds: 1));

      expect(await settled(), isA<ListenFailed>());
      expect(microphone.stopped, 1);
    });

    test('that starts late does not put the position ahead', () async {
      final asked = DateTime.utc(2026, 11, 5, 12);
      var now = asked;
      final gate = Completer<void>();
      microphone.gate = gate.future;
      final samples = StreamController<Float32List>(sync: true);
      microphone.stream = samples.stream;
      final sub = container.listen(listenControllerProvider, (_, _) {});
      addTearDown(sub.close);

      final listening = withClock(
        Clock(() => now),
        () => container.read(listenControllerProvider.notifier).listen(),
      );
      await untilStarted();
      now = asked.add(const Duration(milliseconds: 400));
      gate.complete();
      await listening;

      const chunk = _rate ~/ 2;
      for (var i = 0; i < 20; i++) {
        now = now.add(const Duration(milliseconds: 500));
        final at = 20 * _rate + i * chunk;
        samples.add(Float32List.sublistView(songs[2]!, at, at + chunk));
      }

      final state = await settled();
      expect(state, isA<ListenFound>());
      expect(
        (state as ListenFound).startedAt.difference(asked).inMilliseconds,
        closeTo(400, 5),
      );
    });
  });
}
