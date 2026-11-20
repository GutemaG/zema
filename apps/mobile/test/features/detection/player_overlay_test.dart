import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/app/database/database_provider.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema/features/detection/application/detection_providers.dart';
import 'package:zema/features/detection/application/lyrics_overlay_sync.dart';
import 'package:zema/features/detection/application/player_overlay.dart';
import 'package:zema/features/detection/data/lyrics_overlay.dart';
import 'package:zema/features/detection/data/playback_detector.dart';
import 'package:zema/features/settings/application/settings_controller.dart';
import 'package:zema/features/settings/data/app_settings.dart';
import 'package:zema_core/zema_core.dart';

import '../../helpers/fake_library.dart';

class _Detector extends NoPlaybackDetector {
  final controller = StreamController<DetectedPlayback>.broadcast();

  @override
  Stream<DetectedPlayback> get events => controller.stream;
}

class _Overlay extends NoLyricsOverlay {
  final shown = <OverlayContent>[];
  var hidden = 0;
  final controller = StreamController<OverlayAction>.broadcast();

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

class _Own extends Notifier<PlayerOverlay?> {
  @override
  PlayerOverlay? build() => null;

  void play(int trackId, {bool playing = true}) => state = (
    sheet: OverlaySheet(
      key: playerOverlayKey(trackId),
      source: playerOverlaySource,
      songId: 'song-$trackId',
      title: 'Song $trackId',
      lines: const [OverlayLine('ሰላም', at: Duration(seconds: 1))],
    ),
    playing: playing,
  );

  void stop() => state = null;
}

final _own = NotifierProvider<_Own, PlayerOverlay?>(_Own.new);

void main() {
  late ZemaDatabase db;
  late _Detector detector;
  late _Overlay overlay;

  ProviderContainer start({bool floatLyrics = true}) {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        playbackDetectorProvider.overrideWithValue(detector),
        lyricsOverlayProvider.overrideWithValue(overlay),
        initialSettingsProvider.overrideWithValue(
          AppSettings(floatLyrics: floatLyrics),
        ),
        playerOverlayProvider.overrideWith((ref) => ref.watch(_own)),
        overlayHideDelayProvider.overrideWithValue(
          const Duration(milliseconds: 40),
        ),
        detectedLyricsProvider.overrideWith(
          (ref, id) async => DetectedLyrics(
            song: Song(id: id, title: 'Detected $id', sections: const []),
            lines: const [OverlayLine('ቅዱስ', at: Duration(seconds: 2))],
            sung: const [],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(lyricsOverlaySyncProvider, (_, _) {});
    return container;
  }

  Future<void> settle() async {
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  setUp(() async {
    db = memoryDatabase();
    await db.catalogDao.replaceAll([
      CatalogEntry(
        id: 'kidus',
        title: 'ቅዱስ ቅዱስ እግዚአብሔር',
        synced: true,
        version: 1,
        approvedAt: DateTime.utc(2026, 10),
      ),
    ]);
    detector = _Detector();
    overlay = _Overlay();
  });
  tearDown(() => db.close());

  test('a song with lyrics playing in Zema floats by default', () async {
    final container = start();
    container.read(_own.notifier).play(7);
    await settle();
    final sheet = overlay.shown.last as OverlaySheet;
    expect(sheet.key, 'player:7');
    expect(sheet.source, playerOverlaySource);
    expect(playerOverlayTrack(sheet.key), 7);
    expect(playerOverlayTrack('com.google.android.youtube|x'), isNull);

    container.read(_own.notifier).stop();
    await settle();
    expect(overlay.hidden, greaterThan(0));
  });

  test('closed, it stays away for that song only', () async {
    final container = start();
    container.read(_own.notifier).play(7);
    await settle();
    overlay.controller.add(OverlayClosed(playerOverlayKey(7)));
    await settle();
    final before = overlay.shown.length;
    container.read(_own.notifier).play(7, playing: false);
    await settle();
    expect(overlay.shown, hasLength(before));

    container.read(_own.notifier).play(8);
    await settle();
    expect((overlay.shown.last as OverlaySheet).key, 'player:8');
  });

  test('with the setting off, only Float lyrics shows it', () async {
    final container = start(floatLyrics: false);
    container.read(_own.notifier).play(7);
    await settle();
    expect(overlay.shown, isEmpty);

    container.read(overlayChoicesProvider.notifier).open(playerOverlayKey(7));
    await settle();
    expect((overlay.shown.last as OverlaySheet).key, 'player:7');

    container.read(_own.notifier).play(8);
    await settle();
    expect((overlay.shown.last as OverlaySheet).key, 'player:7');
  });

  test(
    'Zema playing wins over another app; paused, the other app does',
    () async {
      final container = start();
      container.read(_own.notifier).play(7);
      await settle();
      detector.controller.add(
        DetectedPlayback(
          source: 'com.google.android.youtube',
          state: DetectedState.playing,
          title: 'ቅዱስ ቅዱስ እግዚአብሔር',
          position: Duration.zero,
          positionUpdatedAt: DateTime(2026, 11, 20),
        ),
      );
      await settle();
      expect((overlay.shown.last as OverlaySheet).key, 'player:7');

      container.read(_own.notifier).play(7, playing: false);
      await settle();
      expect((overlay.shown.last as OverlaySheet).songId, 'kidus');
    },
  );
}
