import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../../library/application/library_providers.dart';
import '../data/microphone.dart';
import '../data/quick_launch.dart';
import 'library_search.dart';
import 'quick_listen.dart';

final _log = Logger('identify.listen');

/// What Listen is doing (intent 009 FR-5).
sealed class ListenState {
  const ListenState();
}

class ListenIdle extends ListenState {
  const ListenIdle();
}

class ListenLoading extends ListenState {
  const ListenLoading();
}

/// Recording; [heard] is how long so far.
class Listening extends ListenState {
  const Listening(this.heard, {this.level = 0});

  final Duration heard;

  /// How loud the last moment was, 0 (silence) to 1 (loud), for the
  /// animation.
  final double level;
}

/// [track] was at [match]'s position at [startedAt], the moment the audio
/// that was heard began.
class ListenFound extends ListenState {
  const ListenFound({
    required this.track,
    required this.match,
    required this.startedAt,
    this.sure = true,
  });

  final Track track;
  final AudioMatch match;
  final DateTime startedAt;
  final bool sure;

  /// Where the song is at [now], if it kept playing.
  Duration positionAt(DateTime now) {
    final since = now.difference(startedAt).inMicroseconds;
    return match.position +
        Duration(microseconds: (since * match.playbackSpeed).round());
  }

  OpenListenMatch toLaunch() => OpenListenMatch(
    trackId: track.id,
    position: match.position,
    startedAt: startedAt,
    speed: match.playbackSpeed,
    score: match.score,
    sure: sure,
  );

  bool endedAt(DateTime now) =>
      track.duration > Duration.zero && positionAt(now) >= track.duration;

  Duration playFrom(DateTime now) {
    final at = positionAt(now);
    if (at < Duration.zero || endedAt(now)) return Duration.zero;
    return at;
  }
}

class ListenNotFound extends ListenState {
  const ListenNotFound();
}

/// The microphone permission was refused.
class ListenDenied extends ListenState {
  const ListenDenied();
}

/// No library song has a fingerprint yet.
class ListenNothingToMatch extends ListenState {
  const ListenNothingToMatch();
}

/// The microphone wouldn't start or stopped giving sound, or the song
/// couldn't be looked for.
class ListenFailed extends ListenState {
  const ListenFailed();
}

/// Seconds of audio after which Listen tries to identify; it stops at the
/// first sure match, and gives up after the last.
const listenCheckpoints = [
  Duration(seconds: 3),
  Duration(seconds: 6),
  Duration(seconds: 10),
];

/// How long past the last checkpoint Listen waits for sound that isn't
/// arriving.
const listenPatience = Duration(seconds: 5);

/// How loud [samples] are, 0 to 1: their level from -50 dB (silence) to
/// -10 dB (loud music near the phone).
double loudness(Float32List samples) {
  if (samples.isEmpty) return 0;
  var sum = 0.0;
  for (final s in samples) {
    sum += s * s;
  }
  final rms = math.sqrt(sum / samples.length);
  if (rms <= 0) return 0;
  final db = 20 * math.log(rms) / math.ln10;
  return ((db + 50) / 40).clamp(0.0, 1.0);
}

final listenControllerProvider =
    NotifierProvider.autoDispose<ListenController, ListenState>(
      ListenController.new,
    );

/// Listens through the microphone and identifies the song against the
/// library's fingerprints. Microphone samples stay in memory and are dropped
/// when listening ends.
class ListenController extends Notifier<ListenState> {
  StreamSubscription<Float32List>? _samples;
  Timer? _ticker;
  var _session = 0;

  /// The microphone's starts and stops, one at a time: a stop asked for during
  /// a start waits for it, so the microphone can't be left on.
  Future<void> _microphoneWork = Future.value();

  late Microphone _microphone;

  LibrarySearch? _library;
  (int, DateTime?)? _libraryStamp;
  Future<LibrarySearch>? _opening;
  var _closed = false;

  @override
  ListenState build() {
    _closed = false;
    _microphone = ref.read(microphoneProvider);
    ref.onDispose(() {
      _session++;
      _closed = true;
      _library?.close();
      _library = null;
      unawaited(_stopRecording());
    });
    ref.listen(pendingMatchProvider, (_, next) {
      if (next == null) return;
      _session++;
      unawaited(_stopRecording());
      state = next;
      ref.read(pendingMatchProvider.notifier).set(null);
    });
    final pending = ref.read(pendingMatchProvider);
    if (pending != null) {
      Future.microtask(() {
        if (!_closed) ref.read(pendingMatchProvider.notifier).set(null);
      });
      return pending;
    }
    return const ListenIdle();
  }

  Future<void> prepare() async {
    try {
      await _search();
    } catch (e, s) {
      _log.warning('Could not prepare the search', e, s);
    }
  }

  Future<bool> _searchIsStale() async =>
      _library == null ||
      await ref.read(databaseProvider).fingerprintsDao.stamp() != _libraryStamp;

  Future<LibrarySearch> _search() =>
      _opening ??= _openSearch().whenComplete(() => _opening = null);

  Future<LibrarySearch> _openSearch() async {
    final db = ref.read(databaseProvider);
    final stamp = await db.fingerprintsDao.stamp();
    final current = _library;
    if (current != null && stamp == _libraryStamp) return current;
    final fresh = await LibrarySearch.open(db);
    if (_closed) {
      fresh.close();
      return fresh;
    }
    current?.close();
    _library = fresh;
    _libraryStamp = stamp;
    return fresh;
  }

  Future<void> listen() async {
    final session = ++_session;
    try {
      await _stopRecording();
      final allowed = await _microphone.requestPermission();
      if (session != _session) return;
      if (!allowed) {
        state = const ListenDenied();
        return;
      }
      final stale = await _searchIsStale();
      if (session != _session) return;
      if (stale) state = const ListenLoading();
      final library = await _search();
      if (session != _session) return;
      if (library.recordingCount == 0) {
        state = const ListenNothingToMatch();
        return;
      }
      await _record(session, library);
    } catch (e, s) {
      _fail(session, e, s);
    }
  }

  Future<void> _record(int session, LibrarySearch library) async {
    final chunks = <Float32List>[];
    final rate = _microphone.sampleRate;
    final askedAt = clock.now();
    var samples = 0;
    DateTime? startedAt;

    void onSamples(Float32List chunk) {
      chunks.add(chunk);
      samples += chunk.length;
      // Samples can arrive late but never early, so the earliest estimate of
      // when the first one was heard is the truest.
      final start = clock.now().subtract(
        Duration(microseconds: samples * 1000000 ~/ rate),
      );
      final earliest = startedAt;
      if (earliest == null || start.isBefore(earliest)) startedAt = start;
    }

    state = const Listening(Duration.zero);
    await _inTurn(() async {
      if (session != _session) return;
      final stream = await _microphone.start();
      _samples = stream.listen(
        onSamples,
        onError: (Object e, StackTrace s) => _fail(session, e, s),
      );
    });
    if (session != _session) return;

    var next = 0;
    var checking = false;
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (session != _session) return;
      final heard = Duration(microseconds: samples * 1000000 ~/ rate);
      state = Listening(
        heard,
        level: chunks.isEmpty ? 0 : loudness(chunks.last),
      );
      if (checking) return;
      if (heard < listenCheckpoints[next]) {
        final waited = clock.now().difference(askedAt);
        if (waited > listenCheckpoints.last + listenPatience) {
          _fail(session, 'No sound after $waited', StackTrace.current);
        }
        return;
      }
      checking = true;
      try {
        final last = next == listenCheckpoints.length - 1;
        final matches = await library.identify(_join(chunks), rate);
        if (session != _session) return;
        _log.fine('At $heard: $matches');
        final sure = matches.isNotEmpty && !matches.first.ambiguousPosition;
        if (sure || (last && matches.isNotEmpty)) {
          final found = _found(matches.first, startedAt!, sure: sure);
          state = found;
          if (found is ListenFound) _remember(found.track);
          await _stopRecording();
        } else if (last) {
          state = const ListenNotFound();
          await _stopRecording();
        } else {
          next++;
          checking = false;
        }
      } catch (e, s) {
        _fail(session, e, s);
      }
    });
  }

  Future<void> cancel() async {
    _session++;
    state = const ListenIdle();
    await _stopRecording();
  }

  /// Ends [session], if it's still the current one, and says listening failed.
  void _fail(int session, Object error, StackTrace stack) {
    _log.warning('Listening failed', error, stack);
    if (session != _session) return;
    _session++;
    state = const ListenFailed();
    unawaited(_stopRecording());
  }

  ListenState _found(
    AudioMatch match,
    DateTime startedAt, {
    required bool sure,
  }) {
    final id = int.tryParse(match.recordingId);
    final tracks = ref.read(libraryTracksProvider).value ?? const <Track>[];
    for (final track in tracks) {
      if (track.id == id) {
        return ListenFound(
          track: track,
          match: match,
          startedAt: startedAt,
          sure: sure,
        );
      }
    }
    // Fingerprinted, then removed from the library.
    return const ListenNotFound();
  }

  void _remember(Track track) {
    unawaited(
      ref
          .read(databaseProvider)
          .identifiedDao
          .add(track.id, clock.now())
          .catchError((Object e, StackTrace s) {
            _log.warning('Could not save to History', e, s);
          }),
    );
  }

  /// Runs [work] after the microphone work already asked for, even if some of
  /// it failed.
  Future<void> _inTurn(Future<void> Function() work) {
    final done = _microphoneWork.then((_) => work());
    _microphoneWork = done.catchError((Object _) {});
    return done;
  }

  Future<void> _stopRecording() {
    _ticker?.cancel();
    _ticker = null;
    return _inTurn(() async {
      final samples = _samples;
      _samples = null;
      if (samples == null) return;
      try {
        await samples.cancel();
        await _microphone.stop();
      } catch (e, s) {
        _log.warning('Could not stop the microphone', e, s);
      }
    });
  }

  static Float32List _join(List<Float32List> chunks) {
    final out = Float32List(chunks.fold(0, (n, c) => n + c.length));
    var at = 0;
    for (final c in chunks) {
      out.setAll(at, c);
      at += c.length;
    }
    return out;
  }
}
