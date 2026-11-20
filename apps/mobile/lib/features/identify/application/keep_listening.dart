import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/keep_listening_service.dart';
import '../data/microphone.dart';
import 'listen_controller.dart';

/// How long Keep listening can be started for; the middle one is the default.
const keepListeningLengths = [
  Duration(minutes: 30),
  Duration(hours: 1),
  Duration(hours: 2),
];

/// The pause after a match, to catch the next song.
const keepListeningAfterMatch = Duration(seconds: 15);

/// The pauses after one, two, and three or more bursts that found nothing.
const keepListeningBackOff = [
  Duration(seconds: 10),
  Duration(seconds: 20),
  Duration(seconds: 30),
];

/// How long after the matched song should end the next burst starts.
const keepListeningAfterEnd = Duration(seconds: 2);

/// The shortest pause between bursts.
const keepListeningShortest = Duration(seconds: 3);

/// Failed bursts in a row after which the microphone is taken to be gone (a
/// call, or another app using it).
const keepListeningFailures = 2;

/// The pause before the next burst: after [found] at [now], or after
/// [misses] bursts in a row that found nothing.
Duration keepListeningPause({
  ListenFound? found,
  DateTime? now,
  int misses = 0,
}) {
  if (found != null) {
    final left = found.duration - found.positionAt(now ?? clock.now());
    if (found.duration > Duration.zero && left < keepListeningAfterMatch) {
      final soon = left + keepListeningAfterEnd;
      return soon < keepListeningShortest ? keepListeningShortest : soon;
    }
    return keepListeningAfterMatch;
  }
  if (misses <= 0) return keepListeningAfterMatch;
  return keepListeningBackOff[math.min(misses, keepListeningBackOff.length) -
      1];
}

enum KeepListeningEnd { stopped, timeUp, microphone, denied, nothingToMatch }

/// On until [until]; off with why it last ended, if it ran.
class KeepListeningState {
  const KeepListeningState({this.until, this.ended});

  final DateTime? until;
  final KeepListeningEnd? ended;

  bool get on => until != null;
}

/// The words Keep listening shows outside the app.
class KeepListeningTexts {
  const KeepListeningTexts({
    required this.waiting,
    required this.until,
    required this.stop,
    required this.timeUp,
    required this.microphone,
  });

  /// The notification's title before a song is found.
  final String waiting;

  /// "Until 10:42".
  final String Function(DateTime until) until;
  final String stop;
  final String timeUp;
  final String microphone;
}

final keepListeningProvider =
    NotifierProvider<KeepListening, KeepListeningState>(KeepListening.new);

/// Keep listening (intent 010 FR-1, FR-2): bursts of Listen until the time
/// is up or it's stopped. Each found song replaces the shown one, so the
/// Listen and lyrics screens follow it.
class KeepListening extends Notifier<KeepListeningState> {
  ProviderSubscription<ListenState>? _hold;
  StreamSubscription<void>? _stopTaps;
  Timer? _next;
  Timer? _limit;
  KeepListeningTexts? _texts;
  ListenFound? _shown;
  var _run = 0;
  var _misses = 0;
  var _failures = 0;

  KeepListeningService get _service => ref.read(keepListeningServiceProvider);

  @override
  KeepListeningState build() {
    ref.onDispose(() {
      _run++;
      _close();
    });
    return const KeepListeningState();
  }

  Future<void> start(Duration length, KeepListeningTexts texts) async {
    if (state.on) return;
    final run = ++_run;
    if (!await ref.read(microphoneProvider).requestPermission()) {
      if (run == _run) {
        state = const KeepListeningState(ended: KeepListeningEnd.denied);
      }
      return;
    }
    if (run != _run) return;
    _texts = texts;
    _misses = 0;
    _failures = 0;
    state = KeepListeningState(until: clock.now().add(length));
    _hold = ref.listen(listenControllerProvider, (_, next) {
      if (next is ListenFound && !identical(next, _shown)) {
        _shown = next;
        unawaited(_service.show(_notice()));
      }
    });
    _shown = switch (_hold!.read()) {
      final ListenFound found => found,
      _ => null,
    };
    _stopTaps = _service.stopTaps.listen((_) => stop());
    _limit = Timer(length, () => _end(KeepListeningEnd.timeUp));
    await _service.start(_notice(), stopLabel: texts.stop, length: length);
    if (run == _run) unawaited(_burst(run));
  }

  void stop() => _end(KeepListeningEnd.stopped);

  Future<void> _burst(int run) async {
    final result = await ref
        .read(listenControllerProvider.notifier)
        .listenInBackground();
    if (run != _run) return;
    final now = clock.now();
    switch (result) {
      case ListenDenied():
        return _end(KeepListeningEnd.denied);
      case ListenNothingToMatch():
        return _end(KeepListeningEnd.nothingToMatch);
      case ListenFailed():
        if (++_failures >= keepListeningFailures) {
          return _end(KeepListeningEnd.microphone);
        }
        _wait(run, keepListeningPause(misses: 1));
      case final ListenFound found:
        _failures = 0;
        _misses = 0;
        _wait(run, keepListeningPause(found: found, now: now));
      case null:
        _wait(run, keepListeningAfterMatch);
      case _:
        _failures = 0;
        _wait(run, keepListeningPause(misses: ++_misses));
    }
  }

  void _wait(int run, Duration pause) {
    _next?.cancel();
    _next = Timer(pause, () {
      if (run == _run) unawaited(_burst(run));
    });
  }

  KeepListeningNotice _notice() {
    final texts = _texts!;
    final until = texts.until(state.until!);
    return switch (_shown) {
      final found? => (
        title: found.title,
        text: [?found.artist, until].join(' · '),
      ),
      null => (title: texts.waiting, text: until),
    };
  }

  void _end(KeepListeningEnd why) {
    if (!state.on) return;
    _run++;
    final texts = _texts;
    unawaited(ref.read(listenControllerProvider.notifier).cancelBackground());
    _close();
    state = KeepListeningState(ended: why);
    unawaited(
      _service.stop(
        why: switch (why) {
          KeepListeningEnd.timeUp => texts?.timeUp,
          KeepListeningEnd.microphone => texts?.microphone,
          _ => null,
        },
      ),
    );
  }

  void _close() {
    _next?.cancel();
    _next = null;
    _limit?.cancel();
    _limit = null;
    unawaited(_stopTaps?.cancel());
    _stopTaps = null;
    _hold?.close();
    _hold = null;
    _shown = null;
  }
}
