import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/features/identify/application/track_print_sharing.dart';
import 'package:zema/features/identify/application/track_sound_links.dart';
import 'package:zema/features/identify/data/audio_decoder.dart';
import 'package:zema/features/lyrics/data/lyrics_links_repository.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';

/// Decodes every file to 2 minutes of silence, or nothing when [unreadable].
class _Decoder implements AudioDecoder {
  bool unreadable = false;
  var decoded = 0;

  @override
  Future<DecodedAudio?> decode(
    String uri, {
    Duration maxLength = maxDecodedLength,
  }) async {
    decoded++;
    expect(maxLength, linkDecodeLength);
    if (unreadable) return null;
    return DecodedAudio(pcm16: Uint8List(110 * fingerprintSampleRate * 2));
  }

  @override
  Future<DecodeDevice?> device() async => null;
}

class _Prints implements TrackPrintCatalog {
  ZemaFailure? failure;
  final shared = <String>[];

  @override
  Future<FingerprintShare> shareTrackPrint(
    String songId,
    TrackPrint print, {
    required String installId,
  }) async {
    if (failure case final f?) throw f;
    shared.add(songId);
    return FingerprintShare.pending;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ZemaDatabase db;
  late List<Track> tracks;
  late _Decoder decoder;
  late _Prints prints;
  late Map<int, LyricsLink> links;

  TrackPrintSharer sharer() => TrackPrintSharer(
    catalog: prints,
    decoder: decoder,
    store: db.fingerprintsDao,
    links: () async => links,
    tracks: () async => tracks,
    installId: () => 'install-1234',
  );

  setUp(() async {
    db = ZemaDatabase(NativeDatabase.memory());
    await db.libraryDao.applyReconciliation(
      reconcileTracks(
        stored: const [],
        scan: [
          scannedAudio(1, '/m/a.mp3', title: 'A', durationMs: 200000),
          scannedAudio(2, '/m/a2.mp3', title: 'A again', durationMs: 200000),
          scannedAudio(3, '/m/b.mp3', title: 'B', durationMs: 200000),
          scannedAudio(4, '/m/none.mp3', title: 'None', durationMs: 200000),
          scannedAudio(5, '/m/short.mp3', title: 'Short', durationMs: 20000),
        ],
      ),
    );
    tracks = await db.libraryDao.allTracks();
    decoder = _Decoder();
    prints = _Prints();
    links = {
      tracks[0].id: const LyricsLink(songId: 'song-a', manual: false),
      tracks[1].id: const LyricsLink(songId: 'song-a', manual: false),
      tracks[2].id: const LyricsLink(songId: 'song-b', manual: true),
      tracks[3].id: const LyricsLink(songId: null, manual: true),
      tracks[4].id: const LyricsLink(songId: 'song-s', manual: false),
    };
  });
  tearDown(() => db.close());

  test('one file per linked song, by title or by hand', () async {
    expect((await sharer().needed()).map((t) => t.title), ['A', 'B']);
  });

  test('shares each song once', () async {
    expect(await sharer().share(), 2);
    expect(prints.shared, ['song-a', 'song-b']);
    expect(await db.fingerprintsDao.sharedPrintSongs(), {'song-a', 'song-b'});
    expect(await sharer().needed(), isEmpty);
    expect(await sharer().share(), 0);
  });

  test('uses a kept print instead of decoding again', () async {
    final print = TrackPrint(
      values: Uint32List(trackPrintMinValues),
      duration: tracks[0].duration,
    );
    await db.fingerprintsDao.putTrackPrint(
      TrackPrintsCompanion.insert(
        trackId: Value(tracks[0].id),
        sizeBytes: tracks[0].sizeBytes,
        version: trackPrintVersion,
        print: print.toBytes(),
        songId: const Value('song-x'),
        lookedUp: true,
        checkedAt: DateTime.utc(2026),
      ),
    );
    await sharer().share();
    expect(decoder.decoded, 1, reason: 'only song-b was decoded');
    final row = (await db.fingerprintsDao.trackPrint(tracks[0].id))!;
    expect(row.songId, 'song-x', reason: 'the lookup result is kept');
    expect(row.sharedSongId, 'song-a');
  });

  test('offline: stops and tries again next time', () async {
    prints.failure = const NetworkFailure('offline');
    expect(await sharer().share(), 0);
    expect(await db.fingerprintsDao.sharedPrintSongs(), isEmpty);
    prints.failure = null;
    expect(await sharer().share(), 2);
  });

  test('a refused print is not sent again', () async {
    prints.failure = const BackendFailure('bad_print');
    await sharer().share();
    prints.failure = null;
    expect(await sharer().needed(), isEmpty);
  });

  test('an unreadable file is skipped from then on, for another file of '
      'its song', () async {
    decoder.unreadable = true;
    await sharer().share();
    expect(prints.shared, isEmpty);
    expect((await sharer().needed()).map((t) => t.title), ['A again']);
    await sharer().share();
    expect(await sharer().needed(), isEmpty);
  });
}
