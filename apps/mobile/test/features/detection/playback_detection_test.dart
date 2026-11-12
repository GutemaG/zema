import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/features/detection/application/detection_providers.dart';
import 'package:zema/features/detection/data/playback_detector.dart';

class _FakeDetector extends NoPlaybackDetector {
  final controller = StreamController<DetectedPlayback>.broadcast();

  @override
  Stream<DetectedPlayback> get events => controller.stream;
}

DetectedPlayback _event(
  String source,
  String state, {
  String? title = 'Song',
  int updatedAt = 1000,
}) => DetectedPlayback.fromMap({
  'sourcePackage': source,
  'playbackState': state,
  'title': title,
  'positionMs': 0,
  'positionUpdatedAt': updatedAt,
})!;

void main() {
  group('DetectedPlayback.fromMap', () {
    test('reads the event Kotlin sends', () {
      final event = DetectedPlayback.fromMap({
        'sourcePackage': 'com.google.android.youtube',
        'title': ' ስብሐት ለእግዚአብሔር ',
        'artist': 'Channel',
        'mediaId': '',
        'durationMs': 312000,
        'positionMs': 45210,
        'positionUpdatedAt': 1761123456789,
        'speed': 1.0,
        'playbackState': 'playing',
      })!;
      expect(event.source, 'com.google.android.youtube');
      expect(event.title, 'ስብሐት ለእግዚአብሔር');
      expect(event.artist, 'Channel');
      expect(event.mediaId, isNull);
      expect(event.duration, const Duration(milliseconds: 312000));
      expect(event.position, const Duration(milliseconds: 45210));
      expect(
        event.positionUpdatedAt,
        DateTime.fromMillisecondsSinceEpoch(1761123456789),
      );
      expect(event.isPlaying, isTrue);
    });

    test('missing values are safe', () {
      final event = DetectedPlayback.fromMap({
        'sourcePackage': 'org.telegram.messenger',
        'durationMs': 0,
        'playbackState': 'whatever',
      })!;
      expect(event.state, DetectedState.stopped);
      expect(event.duration, isNull);
      expect(event.position, Duration.zero);
      expect(DetectedPlayback.fromMap({'title': 'x'}), isNull);
      expect(DetectedPlayback.fromMap('nope'), isNull);
    });
  });

  group('positionAt', () {
    final at = DateTime(2026, 1, 1, 12);
    DetectedPlayback make(String state, {double speed = 1}) => DetectedPlayback(
      source: 's',
      state: DetectedState.values.byName(state),
      position: const Duration(seconds: 10),
      positionUpdatedAt: at,
      duration: const Duration(seconds: 60),
      speed: speed,
    );

    test('moves on while playing, at the playing speed', () {
      final later = at.add(const Duration(seconds: 4));
      expect(make('playing').positionAt(later), const Duration(seconds: 14));
      expect(
        make('playing', speed: 1.5).positionAt(later),
        const Duration(seconds: 16),
      );
    });

    test('stays put while paused, and stops at the end', () {
      final later = at.add(const Duration(minutes: 5));
      expect(make('paused').positionAt(later), const Duration(seconds: 10));
      expect(make('playing').positionAt(later), const Duration(seconds: 60));
    });
  });

  group('detected playbacks', () {
    late _FakeDetector detector;
    late ProviderContainer container;

    setUp(() {
      detector = _FakeDetector();
      container = ProviderContainer(
        overrides: [playbackDetectorProvider.overrideWithValue(detector)],
      );
      addTearDown(container.dispose);
      container.listen(detectedPlaybacksProvider, (_, _) {});
    });

    Future<void> send(DetectedPlayback event) async {
      detector.controller.add(event);
      await Future<void>.delayed(Duration.zero);
    }

    test('keeps the latest per app, and forgets an app that is gone', () async {
      await send(_event('yt', 'paused'));
      await send(_event('yt', 'playing'));
      await send(_event('tg', 'paused'));
      final all = container.read(detectedPlaybacksProvider);
      expect(all.keys, ['yt', 'tg']);
      expect(all['yt']!.isPlaying, isTrue);

      await send(_event('yt', 'gone'));
      expect(container.read(detectedPlaybacksProvider).keys, ['tg']);
    });

    test('the current one is what is playing, newest first', () async {
      expect(container.read(currentDetectionProvider), isNull);
      await send(_event('tg', 'paused', updatedAt: 9000));
      expect(container.read(currentDetectionProvider)!.source, 'tg');

      await send(_event('yt', 'playing', updatedAt: 1000));
      await send(_event('ym', 'playing', updatedAt: 2000));
      expect(container.read(currentDetectionProvider)!.source, 'ym');

      await send(_event('ym', 'stopped'));
      expect(container.read(currentDetectionProvider)!.source, 'yt');

      await send(_event('yt', 'playing', title: null));
      expect(container.read(currentDetectionProvider)!.source, 'tg');
    });
  });
}
