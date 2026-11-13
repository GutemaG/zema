import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/database_provider.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/features/detection/application/detected_song.dart';
import 'package:zema/features/detection/application/detection_providers.dart';
import 'package:zema/features/detection/application/lyrics_overlay_sync.dart';
import 'package:zema/features/detection/data/lyrics_overlay.dart';
import 'package:zema/features/detection/data/playback_detector.dart';
import 'package:zema/features/identify/data/quick_launch.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';

class _FakeDetector extends NoPlaybackDetector {
  final controller = StreamController<DetectedPlayback>.broadcast();

  @override
  Stream<DetectedPlayback> get events => controller.stream;
}

class _FakeOverlay extends NoLyricsOverlay {
  final shown = <OverlayContent>[];
  var hidden = 0;
  final controller = StreamController<OverlayAction>.broadcast();
  var start = OverlayStart.bubble;

  @override
  Future<OverlayAppearance> appearance() async =>
      OverlayAppearance(start: start);

  OverlaySheet? get last => shown.lastOrNull as OverlaySheet?;

  OverlayContent? get latest => shown.lastOrNull;

  @override
  Future<bool> show(OverlayContent content) async {
    shown.add(content);
    return true;
  }

  @override
  Future<void> hide() async => hidden++;

  @override
  Stream<OverlayAction> get actions => controller.stream;
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

DetectedPlayback _playing(
  String title, {
  Duration position = const Duration(seconds: 30),
  DetectedState state = DetectedState.playing,
}) => DetectedPlayback(
  source: 'com.google.android.youtube',
  state: state,
  title: title,
  position: position,
  positionUpdatedAt: _at,
);

const _lines = [
  OverlayLine('ሰላም ለዚህ ቤት', at: Duration(seconds: 2)),
  OverlayLine('ሰላም ለእናንተ', at: Duration(seconds: 6)),
];

void main() {
  late ZemaDatabase db;
  late _FakeDetector detector;
  late _FakeOverlay overlay;
  late ProviderContainer container;

  setUp(() async {
    db = memoryDatabase();
    await db.catalogDao.replaceAll([
      _entry('selam', 'ሰላም ለዚህ ቤት'),
      _entry('kidus', 'ቅዱስ ቅዱስ እግዚአብሔር'),
      _entry('halea', 'ሃሌ ሉያ ዘምሩ', artist: 'Choir A'),
      _entry('haleb', 'ሃሌ ሉያ ዘምሩ', artist: 'Choir B'),
      _entry('broken', 'የተሰበረ ሰንሰለት መዝሙር'),
    ]);
    detector = _FakeDetector();
    overlay = _FakeOverlay();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        playbackDetectorProvider.overrideWithValue(detector),
        lyricsOverlayProvider.overrideWithValue(overlay),
        overlayHideDelayProvider.overrideWithValue(
          const Duration(milliseconds: 40),
        ),
        detectedLyricsProvider.overrideWith(
          (ref, id) async => id == 'broken'
              ? throw const NetworkFailure('offline')
              : DetectedLyrics(
                  song: Song(id: id, title: 'Title of $id', sections: const []),
                  lines: _lines,
                  sung: const [],
                  recordingOffset: const Duration(milliseconds: 300),
                ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(lyricsOverlaySyncProvider, (_, _) {});
  });

  Future<void> settle() async {
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<void> detect(DetectedPlayback playback) async {
    detector.controller.add(playback);
    await settle();
  }

  test('a matched song is shown with its timed lines', () async {
    await detect(_playing('ሰላም ለዚህ ቤት | Official'));

    final sheet = overlay.last!;
    expect(sheet.songId, 'selam');
    expect(sheet.title, 'Title of selam');
    expect(sheet.source, 'com.google.android.youtube');
    expect(sheet.lines, _lines);
    expect(sheet.offset, const Duration(milliseconds: -300));
    expect(sheet.key, detectionKey(_playing('ሰላም ለዚህ ቤት | Official')));
  });

  test('"only when I tap" waits until the song is asked for', () async {
    overlay.start = OverlayStart.tap;
    container.invalidate(overlayStartProvider);
    await detect(_playing('ሰላም ለዚህ ቤት'));
    expect(overlay.shown, isEmpty);

    final key = detectionKey(_playing('ሰላም ለዚህ ቤት'));
    container.read(overlayChoicesProvider.notifier).open(key);
    await settle();
    expect(overlay.last!.songId, 'selam');

    overlay.controller.add(OverlayClosed(key));
    await settle();
    container.read(overlayChoicesProvider.notifier).open(key);
    await settle();
    expect(overlay.shown, hasLength(2));
  });

  test('playback moving on does not send the lines again', () async {
    await detect(_playing('ሰላም ለዚህ ቤት'));
    await detect(_playing('ሰላም ለዚህ ቤት', position: const Duration(seconds: 40)));
    await detect(_playing('ሰላም ለዚህ ቤት', state: DetectedState.paused));

    expect(overlay.shown, hasLength(1));
  });

  test('no match, or playback stopping, hides it', () async {
    await detect(_playing('lofi beats'));
    expect(overlay.shown, isEmpty);

    await detect(_playing('ሰላም ለዚህ ቤት'));
    expect(overlay.shown, hasLength(1));
    final hiddenBefore = overlay.hidden;

    await detect(_playing('ሰላም ለዚህ ቤት', state: DetectedState.stopped));
    expect(overlay.hidden, greaterThan(hiddenBefore));
  });

  test('stopping hides it only after a while, a new song at once', () async {
    await detect(_playing('ሰላም ለዚህ ቤት'));
    final hiddenBefore = overlay.hidden;

    detector.controller.add(
      _playing('ሰላም ለዚህ ቤት', state: DetectedState.stopped),
    );
    await Future<void>.delayed(const Duration(milliseconds: 15));
    expect(overlay.hidden, hiddenBefore);
    await settle();
    expect(overlay.hidden, hiddenBefore + 1);

    await detect(_playing('ሰላም ለዚህ ቤት'));
    detector.controller.add(_playing('lofi beats'));
    await Future<void>.delayed(const Duration(milliseconds: 15));
    expect(overlay.hidden, hiddenBefore + 2);
  });

  test('closing hides it for that song only', () async {
    await detect(_playing('ሰላም ለዚህ ቤት'));
    overlay.controller.add(OverlayClosed(overlay.last!.key));
    await settle();
    final shownBefore = overlay.shown.length;

    await detect(_playing('ሰላም ለዚህ ቤት', position: const Duration(minutes: 1)));
    expect(overlay.shown, hasLength(shownBefore));

    await detect(_playing('ቅዱስ ቅዱስ እግዚአብሔር'));
    expect(overlay.last!.songId, 'kidus');
  });

  test('a timing change is remembered for the video', () async {
    final playback = _playing('ሰላም ለዚህ ቤት');
    await detect(playback);
    overlay.controller.add(
      OverlayOffset(overlay.last!.key, const Duration(milliseconds: 1200)),
    );
    await settle();

    final row = (await db.detectedMatchesDao.watchAll().first).single;
    expect(row.sourceKey, detectionKey(playback));
    expect(row.songId, 'selam');
    expect(row.offsetMs, 1500);
    expect(overlay.last!.offset, const Duration(milliseconds: 1200));
  });

  test('an unsure match asks, and Yes shows its lyrics', () async {
    await detect(_playing('ሃሌ ሉያ ዘምሩ'));
    final question = overlay.latest! as OverlayQuestion;
    expect(question.songId, anyOf('halea', 'haleb'));

    overlay.controller.add(OverlayConfirmed(question.key, 'haleb'));
    await settle();

    expect(overlay.last!.songId, 'haleb');
    expect(overlay.last!.key, question.key);
  });

  test('Not a mezmur hides it and is remembered', () async {
    final playback = _playing('ሃሌ ሉያ ዘምሩ');
    await detect(playback);
    final hiddenBefore = overlay.hidden;
    overlay.controller.add(OverlayNotMezmur(overlay.latest!.key));
    await settle();

    expect(overlay.hidden, greaterThan(hiddenBefore));
    final row = (await db.detectedMatchesDao.watchAll().first).single;
    expect(row.sourceKey, detectionKey(playback));
    expect(row.songId, isNull);
  });

  test('lyrics that cannot be loaded say so', () async {
    await detect(_playing('የተሰበረ ሰንሰለት መዝሙር'));
    final sheet = overlay.last!;
    expect(sheet.songId, 'broken');
    expect(sheet.failed, isTrue);
    expect(sheet.lines, isEmpty);
  });

  test('the window\'s actions and Open in Zema are read', () {
    expect(
      OverlayAction.fromMap({'type': 'offset', 'key': 'k', 'offsetMs': -500}),
      isA<OverlayOffset>().having(
        (a) => a.offset,
        'offset',
        const Duration(milliseconds: -500),
      ),
    );
    expect(
      OverlayAction.fromMap({'type': 'closed', 'key': 'k'}),
      isA<OverlayClosed>(),
    );
    expect(OverlayAction.fromMap({'type': 'closed'}), isNull);
    expect(
      AndroidLaunchReceiver.read({'open': 'song', 'songId': 'selam'}),
      isA<OpenSong>().having((o) => o.songId, 'songId', 'selam'),
    );
    expect(AndroidLaunchReceiver.read({'open': 'song'}), isNull);
  });
}
