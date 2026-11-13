import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/database_provider.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/features/detection/application/detected_song.dart';
import 'package:zema/features/detection/application/detection_providers.dart';
import 'package:zema/features/detection/data/playback_detector.dart';
import 'package:zema/features/identify/application/listen_controller.dart';
import 'package:zema/features/lyrics/data/lyrics_links_repository.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';

class _FakeDetector extends NoPlaybackDetector {
  final controller = StreamController<DetectedPlayback>.broadcast();

  @override
  Stream<DetectedPlayback> get events => controller.stream;
}

CatalogEntry _entry(String id, String title, {String? artist}) => CatalogEntry(
  id: id,
  title: title,
  artist: artist,
  synced: true,
  version: 1,
  approvedAt: DateTime.utc(2026, 10, 1),
);

final _at = DateTime(2026, 11, 13, 12);

DetectedPlayback _playing(String title, {String? artist, String? mediaId}) =>
    DetectedPlayback(
      source: 'com.google.android.youtube',
      state: DetectedState.playing,
      title: title,
      artist: artist,
      mediaId: mediaId,
      position: const Duration(seconds: 30),
      positionUpdatedAt: _at,
    );

void main() {
  late ZemaDatabase db;
  late _FakeDetector detector;
  late ProviderContainer container;

  setUp(() async {
    db = memoryDatabase();
    await db.catalogDao.replaceAll([
      _entry('selam', 'ሰላም ለዚህ ቤት'),
      _entry('kidus', 'ቅዱስ ቅዱስ', artist: 'Choir A'),
      _entry('kidus2', 'ቅዱስ ቅዱስ', artist: 'Choir B'),
    ]);
    detector = _FakeDetector();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        playbackDetectorProvider.overrideWithValue(detector),
        detectedMatchControllerProvider.overrideWith(
          (ref) => DetectedMatchController(
            db.detectedMatchesDao,
            () => Stream.value({
              7: const LyricsLink(songId: 'kidus', manual: false),
            }),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(detectedSongProvider, (_, _) {});
  });

  Future<DetectedSong?> detect(DetectedPlayback playback) async {
    detector.controller.add(playback);
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return container.read(detectedSongProvider);
  }

  DetectedMatchController controller() =>
      container.read(detectedMatchControllerProvider);

  test('a clear title is matched', () async {
    final song = await detect(_playing('ሰላም ለዚህ ቤት | Official Video'));
    expect(song, isA<DetectedMatch>());
    song as DetectedMatch;
    expect(song.song.id, 'selam');
    expect(song.how, DetectedHow.title);
  });

  test('an unclear title asks, and the answer is remembered', () async {
    final playback = _playing('ቅዱስ ቅዱስ mezmur');
    final song = await detect(playback);
    expect(song, isA<DetectedUnsure>());
    expect(
      (song! as DetectedUnsure).candidates.map((e) => e.id),
      unorderedEquals(['kidus', 'kidus2']),
    );

    await controller().confirm(playback, _entry('kidus2', 'ቅዱስ ቅዱስ'));
    final again = await detect(_playing('ቅዱስ  ቅዱስ  MEZMUR'));
    expect(again, isA<DetectedMatch>());
    again as DetectedMatch;
    expect(again.song.id, 'kidus2');
    expect(again.how, DetectedHow.remembered);

    await controller().forget(playback);
    expect(await detect(playback), isA<DetectedUnsure>());
  });

  test('Not a mezmur is remembered, and can be cleared', () async {
    final playback = _playing('ሰላም ለዚህ ቤት (cover)');
    await controller().notMezmur(playback);
    expect(await detect(playback), isA<DetectedNotMezmur>());

    await controller().clearAll();
    expect(await detect(playback), isA<DetectedMatch>());
  });

  test('nothing close is unknown', () async {
    expect(await detect(_playing('lofi beats')), isA<DetectedUnknown>());
  });

  test('a media ID keys the answer, whatever the title says', () async {
    await controller().confirm(
      _playing('first title', mediaId: 'abc'),
      _entry('selam', 'ሰላም ለዚህ ቤት'),
    );
    final song = await detect(_playing('renamed', mediaId: 'abc'));
    expect((song! as DetectedMatch).song.id, 'selam');
  });

  test('a song found by listening is remembered with its offset', () async {
    final track = Track.fromScan(7, scannedAudio(7, '/m/7.mp3', title: 'x'));
    final found = ListenFound(
      track: track,
      match: const AudioMatch(
        recordingId: '7',
        position: Duration(seconds: 42),
        score: 30,
        playbackSpeed: 1,
        ambiguousPosition: false,
      ),
      startedAt: _at,
    );
    final playback = _playing('ቅዱስ ቅዱስ');
    final links = DetectedMatchController(
      db.detectedMatchesDao,
      () => Stream.value({7: const LyricsLink(songId: 'kidus', manual: false)}),
    );
    final unlinked = DetectedMatchController(
      db.detectedMatchesDao,
      () => Stream.value(const {}),
    );

    await withClock(Clock.fixed(_at.add(const Duration(seconds: 5))), () async {
      expect(await unlinked.rememberListened(playback, found), isFalse);
      expect(await links.rememberListened(playback, found), isTrue);
    });
    final song = await detect(playback);
    song as DetectedMatch;
    expect(song.song.id, 'kidus');
    expect(song.offset, const Duration(seconds: 12));
    expect(
      song.positionAt(_at.add(const Duration(seconds: 10))),
      const Duration(seconds: 52),
    );
  });

  test('Identify by listening remembers what Listen finds', () async {
    final track = Track.fromScan(7, scannedAudio(7, '/m/7.mp3', title: 'x'));
    ListenFound found(int seconds) => ListenFound(
      track: track,
      match: AudioMatch(
        recordingId: '7',
        position: Duration(seconds: seconds),
        score: 30,
        playbackSpeed: 1,
        ambiguousPosition: false,
      ),
      startedAt: clock.now(),
    );
    container.listen(listenedMatchSyncProvider, (_, _) {});
    final playback = _playing('ቅዱስ ቅዱስ');
    await detect(playback);
    final events = container.read(listenFoundEventsProvider);

    events.add(found(1));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(await db.detectedMatchesDao.watchAll().first, isEmpty);

    container.read(listeningForProvider.notifier).set(playback);
    events.add(found(40));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final rows = await db.detectedMatchesDao.watchAll().first;
    expect(rows.single.songId, 'kidus');
    expect(container.read(listeningForProvider), isNull);
  });
}
