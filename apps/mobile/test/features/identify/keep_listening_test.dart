import 'dart:async';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/features/identify/application/keep_listening.dart';
import 'package:zema/features/identify/application/listen_controller.dart';
import 'package:zema/features/identify/data/keep_listening_service.dart';
import 'package:zema/features/identify/data/microphone.dart';
import 'package:zema_core/zema_core.dart';

ListenFound _found(
  String id, {
  Duration at = Duration.zero,
  Duration length = const Duration(minutes: 4),
  DateTime? startedAt,
}) => ListenFound(
  song: CatalogEntry(
    id: id,
    title: 'Song $id',
    artist: 'Artist',
    synced: true,
    version: 1,
    approvedAt: DateTime.utc(2026),
  ),
  match: AudioMatch(
    recordingId: '$id-rec',
    position: at,
    score: 40,
    playbackSpeed: 1,
    ambiguousPosition: false,
  ),
  startedAt: startedAt ?? clock.now(),
  recordingDuration: length,
);

/// Each burst ends with the next of [results] (a function of the burst's
/// time, or a state), then with nothing found.
class _Listen extends ListenController {
  final results = <Object>[];
  final bursts = <DateTime>[];
  var cancelled = 0;

  @override
  ListenState build() => const ListenIdle();

  @override
  Future<ListenState?> listenInBackground() async {
    bursts.add(clock.now());
    final next = results.isEmpty ? const ListenNotFound() : results.removeAt(0);
    final result = next is ListenState Function()
        ? next()
        : next as ListenState;
    if (result is ListenFound) state = result;
    return result;
  }

  @override
  Future<void> cancelBackground() async => cancelled++;
}

class _Microphone implements Microphone {
  var allow = true;

  @override
  int get sampleRate => 44100;

  @override
  Future<bool> requestPermission() async => allow;

  @override
  Future<Stream<Float32List>> start() async => const Stream.empty();

  @override
  Future<void> stop() async {}
}

class _Service implements KeepListeningService {
  final shown = <KeepListeningNotice>[];
  final stops = StreamController<void>.broadcast();
  String? stopLabel;
  var started = 0;
  final stopped = <String?>[];

  @override
  Future<void> start(
    KeepListeningNotice notice, {
    required String stopLabel,
    required Duration length,
  }) async {
    started++;
    this.stopLabel = stopLabel;
    shown.add(notice);
  }

  @override
  Future<void> show(KeepListeningNotice notice) async => shown.add(notice);

  @override
  Future<void> stop({String? why}) async => stopped.add(why);

  @override
  Stream<void> get stopTaps => stops.stream;
}

final _texts = KeepListeningTexts(
  waiting: 'Listening for songs',
  until: (until) => 'Until ${until.hour}:${until.minute}',
  stop: 'Stop',
  timeUp: 'Time is up',
  microphone: 'Microphone gone',
);

void main() {
  group('the pause before the next burst', () {
    final now = DateTime.utc(2026, 1, 1, 10);

    test('is 15 s after a match, sooner near the song\'s end', () {
      expect(
        keepListeningPause(
          found: _found('a', startedAt: now),
          now: now,
        ),
        keepListeningAfterMatch,
      );
      final nearEnd = _found(
        'a',
        at: const Duration(seconds: 95),
        length: const Duration(seconds: 100),
        startedAt: now,
      );
      expect(
        keepListeningPause(found: nearEnd, now: now),
        const Duration(seconds: 7),
      );
      final ended = _found(
        'a',
        at: const Duration(seconds: 120),
        length: const Duration(seconds: 100),
        startedAt: now,
      );
      expect(keepListeningPause(found: ended, now: now), keepListeningShortest);
    });

    test('backs off after misses', () {
      expect(
        [for (var m = 1; m <= 5; m++) keepListeningPause(misses: m).inSeconds],
        [10, 20, 30, 30, 30],
      );
    });
  });

  test('the same song where it should be is the same moment', () {
    final now = DateTime.utc(2026, 1, 1, 10);
    final shown = _found(
      'a',
      startedAt: now.subtract(const Duration(seconds: 30)),
    );
    final later = _found('a', at: const Duration(seconds: 31), startedAt: now);
    expect(sameMoment(shown, later, now), isTrue);
    final moved = _found('a', at: const Duration(seconds: 60), startedAt: now);
    expect(sameMoment(shown, moved, now), isFalse);
    final other = _found('b', at: const Duration(seconds: 30), startedAt: now);
    expect(sameMoment(shown, other, now), isFalse);
  });

  group('Keep listening', () {
    late _Listen listen;
    late _Microphone microphone;
    late _Service service;
    late ProviderContainer container;

    void run(void Function(FakeAsync async, KeepListening keep) body) {
      fakeAsync((async) {
        listen = _Listen();
        microphone = _Microphone();
        service = _Service();
        container = ProviderContainer(
          overrides: [
            listenControllerProvider.overrideWith(() => listen),
            microphoneProvider.overrideWithValue(microphone),
            keepListeningServiceProvider.overrideWithValue(service),
          ],
        );
        body(async, container.read(keepListeningProvider.notifier));
        container.dispose();
      });
    }

    KeepListeningState state() => container.read(keepListeningProvider);

    test('listens at once, shows each found song, and paces the bursts', () {
      run((async, keep) {
        listen.results.addAll([() => _found('a'), () => _found('b')]);
        unawaited(keep.start(const Duration(hours: 1), _texts));
        async.flushMicrotasks();
        expect(state().on, isTrue);
        expect(service.started, 1);
        expect(service.stopLabel, 'Stop');
        expect(service.shown.first.title, 'Listening for songs');
        expect(listen.bursts, hasLength(1));
        expect(service.shown.last.title, 'Song a');
        expect(service.shown.last.text, startsWith('Artist · Until '));

        async.elapse(const Duration(seconds: 14));
        expect(listen.bursts, hasLength(1));
        async.elapse(const Duration(seconds: 1));
        expect(listen.bursts, hasLength(2));
        expect(service.shown.last.title, 'Song b');

        // Then nothing: 15 s after the match, then 10, 20 and 30 s apart.
        final before = listen.bursts.length;
        async.elapse(const Duration(seconds: 15 + 10 + 20 + 30));
        expect(listen.bursts.length - before, 4);
      });
    });

    test('ends when the time is up, and says so', () {
      run((async, keep) {
        unawaited(keep.start(const Duration(minutes: 30), _texts));
        async.elapse(const Duration(minutes: 30));
        expect(state().on, isFalse);
        expect(state().ended, KeepListeningEnd.timeUp);
        expect(service.stopped, ['Time is up']);
        expect(listen.cancelled, 1);
        final bursts = listen.bursts.length;
        async.elapse(const Duration(minutes: 5));
        expect(listen.bursts, hasLength(bursts));
      });
    });

    test('Stop in the notification ends it quietly', () {
      run((async, keep) {
        unawaited(keep.start(const Duration(hours: 1), _texts));
        async.flushMicrotasks();
        service.stops.add(null);
        async.flushMicrotasks();
        expect(state().ended, KeepListeningEnd.stopped);
        expect(service.stopped, [null]);
      });
    });

    test('two failed bursts in a row mean the microphone is gone', () {
      run((async, keep) {
        listen.results.addAll([
          const ListenFailed(),
          const ListenNotFound(),
          const ListenFailed(),
          const ListenFailed(),
        ]);
        unawaited(keep.start(const Duration(hours: 1), _texts));
        async.elapse(const Duration(seconds: 25));
        expect(state().on, isTrue, reason: 'a miss in between resets it');
        async.elapse(const Duration(seconds: 5));
        expect(state().ended, KeepListeningEnd.microphone);
        expect(service.stopped, ['Microphone gone']);
      });
    });

    test('a refused microphone starts nothing', () {
      run((async, keep) {
        microphone.allow = false;
        unawaited(keep.start(const Duration(hours: 1), _texts));
        async.flushMicrotasks();
        expect(state().ended, KeepListeningEnd.denied);
        expect(service.started, 0);
        expect(listen.bursts, isEmpty);
      });
    });

    test('nothing to match ends it', () {
      run((async, keep) {
        listen.results.add(const ListenNothingToMatch());
        unawaited(keep.start(const Duration(hours: 1), _texts));
        async.flushMicrotasks();
        expect(state().ended, KeepListeningEnd.nothingToMatch);
        expect(service.stopped, [null]);
      });
    });
  });
}
