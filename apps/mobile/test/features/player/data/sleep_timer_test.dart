import 'dart:async';

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/features/player/data/sleep_timer.dart';
import 'package:zema/features/player/data/zema_audio_handler.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';
import '../../../helpers/fake_player.dart';

List<Track> _tracks(int count) => [
  for (var i = 1; i <= count; i++)
    Track.fromScan(i, scannedAudio(100 + i, '/m/$i.mp3', title: 'Song $i')),
];

/// Runs [body] on a fake clock with a handler that is already playing
/// [count] tracks (each 10 minutes long, so none ends on its own).
void _playing(
  void Function(FakeAsync async, ZemaAudioHandler handler, FakeAudioBackend b)
  body, {
  int count = 3,
}) {
  fakeAsync((async) {
    final backend = FakeAudioBackend()..duration = const Duration(minutes: 10);
    final handler = fakeAudioHandler(backend);
    unawaited(handler.playTracks(_tracks(count)));
    async.flushMicrotasks();
    body(async, handler, backend);
  });
}

void main() {
  group('Sleep timer', () {
    test('shows when it will end', () {
      _playing((async, handler, _) {
        final start = clock.now();

        handler.setSleepTimer(const Duration(minutes: 15));

        expect(
          handler.snapshot.sleepTimer,
          TimedSleep(start.add(const Duration(minutes: 15))),
        );
        expect(
          (handler.snapshot.sleepTimer! as TimedSleep).remainingAt(
            clock.now().add(const Duration(minutes: 5)),
          ),
          const Duration(minutes: 10),
        );
      });
    });

    test('fades out over 5 s, then pauses at full volume', () {
      _playing((async, handler, backend) {
        handler.setSleepTimer(const Duration(minutes: 1));

        async.elapse(const Duration(seconds: 59));
        expect(backend.playing, isTrue);
        expect(backend.volumes, isEmpty);

        async.elapse(const Duration(seconds: 1));
        expect(backend.playing, isTrue, reason: 'the fade has started');

        async.elapse(const Duration(milliseconds: 2500));
        expect(backend.volume, closeTo(0.5, 0.01));
        expect(backend.playing, isTrue);

        async.elapse(const Duration(milliseconds: 2500));
        async.flushMicrotasks();
        expect(backend.playing, isFalse);
        expect(handler.snapshot.playing, isFalse);
        expect(handler.snapshot.sleepTimer, isNull);
        expect(backend.volume, 1, reason: 'ready for the next play');

        // Down in steps to silence, then back up once paused.
        final fade = backend.volumes.sublist(0, backend.volumes.length - 1);
        for (var i = 1; i < fade.length; i++) {
          expect(fade[i], lessThan(fade[i - 1]));
        }
        expect(fade.last, 0);
        expect(backend.volumes.last, 1);
      });
    });

    test('keeps counting while paused', () {
      _playing((async, handler, backend) {
        handler.setSleepTimer(const Duration(minutes: 1));

        async.elapse(const Duration(seconds: 20));
        unawaited(handler.pause());
        async.elapse(const Duration(seconds: 20));
        unawaited(handler.play());
        async.elapse(const Duration(seconds: 26));
        async.flushMicrotasks();

        expect(backend.playing, isFalse, reason: 'ended 60 s after setting');
      });
    });

    test('ending while paused only clears the timer', () {
      _playing((async, handler, backend) {
        handler.setSleepTimer(const Duration(minutes: 1));
        unawaited(handler.pause());

        async.elapse(const Duration(minutes: 2));

        expect(handler.snapshot.sleepTimer, isNull);
        expect(backend.volumes, isEmpty);
        expect(backend.playing, isFalse);
      });
    });

    test(
      'cancelling during the fade restores the volume and keeps playing',
      () {
        _playing((async, handler, backend) {
          handler.setSleepTimer(const Duration(minutes: 1));
          async.elapse(const Duration(seconds: 62));
          expect(backend.volume, lessThan(1));

          handler.cancelSleepTimer();
          async.elapse(const Duration(seconds: 10));

          expect(backend.volume, 1);
          expect(backend.playing, isTrue);
          expect(handler.snapshot.sleepTimer, isNull);
        });
      },
    );

    test('pausing during the fade ends it at full volume', () {
      _playing((async, handler, backend) {
        handler.setSleepTimer(const Duration(minutes: 1));
        async.elapse(const Duration(seconds: 62));

        unawaited(handler.pause());
        async.flushMicrotasks();

        // At once, not when the fade would have finished.
        expect(backend.volume, 1);
        expect(backend.playing, isFalse);
        expect(handler.snapshot.sleepTimer, isNull);

        final changes = backend.volumes.length;
        async.elapse(const Duration(seconds: 10));
        expect(backend.volumes, hasLength(changes), reason: 'fade stopped');
      });
    });

    test('a new timer replaces the running one', () {
      _playing((async, handler, backend) {
        handler.setSleepTimer(const Duration(minutes: 1));
        handler.setSleepTimer(const Duration(minutes: 5));

        async.elapse(const Duration(minutes: 2));
        expect(backend.playing, isTrue);

        async.elapse(const Duration(minutes: 3, seconds: 6));
        async.flushMicrotasks();
        expect(backend.playing, isFalse);
      });
    });

    test('cancel and stop turn it off', () {
      _playing((async, handler, backend) {
        handler.setSleepTimer(const Duration(minutes: 1));
        handler.cancelSleepTimer();
        async.elapse(const Duration(minutes: 2));
        expect(backend.playing, isTrue);

        handler.setSleepTimer(const Duration(minutes: 1));
        unawaited(handler.stop());
        async.flushMicrotasks();
        expect(handler.snapshot.sleepTimer, isNull);
      });
    });

    test('end of current song stops there, with the next song ready', () {
      _playing((async, handler, backend) {
        handler.sleepAtEndOfTrack();
        expect(handler.snapshot.sleepTimer, const EndOfTrackSleep());

        backend.finishTrack();
        async.flushMicrotasks();

        expect(handler.snapshot.current?.title, 'Song 2');
        expect(handler.snapshot.playing, isFalse);
        expect(handler.snapshot.sleepTimer, isNull);
        expect(backend.loaded.last, _tracks(2)[1].uri);

        // The next play carries on with the next song.
        unawaited(handler.play());
        async.flushMicrotasks();
        expect(handler.snapshot.playing, isTrue);
        expect(handler.snapshot.current?.title, 'Song 2');
      });
    });

    test('end of current song on the last song stops at its start', () {
      _playing((async, handler, backend) {
        handler.sleepAtEndOfTrack();

        backend.finishTrack();
        async.flushMicrotasks();

        expect(handler.snapshot.current?.title, 'Song 1');
        expect(handler.snapshot.playing, isFalse);
        expect(backend.position, Duration.zero);
        expect(handler.snapshot.sleepTimer, isNull);
      }, count: 1);
    });
  });
}
