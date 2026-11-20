import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/backend/backend_providers.dart';
import '../../../app/database/database_provider.dart';
import '../../../app/preferences_provider.dart';
import '../../catalog/application/report_sender.dart';
import '../../library/application/library_providers.dart';
import '../data/microphone.dart';
import '../data/quick_launch.dart';
import 'library_search.dart';
import 'pending_lookups.dart';
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

/// A library [track], or a catalog [song]'s recording `match.recordingId`,
/// was at [match]'s position at [startedAt], the moment the audio that was
/// heard began.
class ListenFound extends ListenState {
  const ListenFound({
    this.track,
    this.song,
    required this.match,
    required this.startedAt,
    this.sure = true,
    this.recordingDuration = Duration.zero,
  }) : assert(track != null || song != null);

  final Track? track;
  final CatalogEntry? song;
  final AudioMatch match;
  final DateTime startedAt;
  final bool sure;

  /// The catalog recording's length; a library track has its own.
  final Duration recordingDuration;

  String get title => track?.title ?? song!.title;

  String? get artist => track == null ? song!.artist : track!.artist;

  Duration get duration => track?.duration ?? recordingDuration;

  /// Where the song is at [now], if it kept playing.
  Duration positionAt(DateTime now) {
    final since = now.difference(startedAt).inMicroseconds;
    return match.position +
        Duration(microseconds: (since * match.playbackSpeed).round());
  }

  /// For a library track only.
  OpenListenMatch? toLaunch() => switch (track) {
    final track? => OpenListenMatch(
      trackId: track.id,
      position: match.position,
      startedAt: startedAt,
      speed: match.playbackSpeed,
      score: match.score,
      sure: sure,
    ),
    null => null,
  };

  bool endedAt(DateTime now) =>
      duration > Duration.zero && positionAt(now) >= duration;

  Duration playFrom(DateTime now) {
    final at = positionAt(now);
    if (at < Duration.zero || endedAt(now)) return Duration.zero;
    return at;
  }
}

class ListenNotFound extends ListenState {
  const ListenNotFound();
}

/// Offline and not in the library: what was heard is kept, as fingerprints,
/// and looked up when the phone is back online; the song goes into History.
class ListenSavedForLater extends ListenState {
  const ListenSavedForLater();
}

/// The microphone permission was refused.
class ListenDenied extends ListenState {
  const ListenDenied();
}

/// No library song has a fingerprint yet, and there's no catalog to ask.
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

/// How far a background burst's match may be from where the shown song
/// should be and still count as the same moment, not a re-sync.
const listenSameMoment = Duration(seconds: 2);

/// Whether [a] and [b] are the same library track or catalog song.
bool sameSong(ListenFound a, ListenFound b) =>
    a.track?.id == b.track?.id && a.song?.id == b.song?.id;

/// Whether [found] is the [shown] song where it should be at [now], so
/// nothing needs to change.
bool sameMoment(ListenFound shown, ListenFound found, DateTime now) =>
    sameSong(shown, found) &&
    (found.positionAt(now) - shown.positionAt(now)).abs() < listenSameMoment;

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

final listenFoundEventsProvider = Provider<StreamController<ListenFound>>((
  ref,
) {
  final events = StreamController<ListenFound>.broadcast();
  ref.onDispose(events.close);
  return events;
});

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

  /// Completes the current session's [listen] with how it ended, or null
  /// when another session replaced it.
  Completer<ListenState?>? _done;

  /// In a background session, the song kept on screen while it listens.
  ListenFound? _shown;
  var _background = false;

  /// The microphone's starts and stops, one at a time: a stop asked for during
  /// a start waits for it, so the microphone can't be left on.
  Future<void> _microphoneWork = Future.value();

  late Microphone _microphone;

  LibrarySearch? _library;
  Object? _libraryStamp;
  Future<LibrarySearch>? _opening;
  var _closed = false;

  @override
  ListenState build() {
    _closed = false;
    _microphone = ref.read(microphoneProvider);
    ref.onDispose(() {
      _session++;
      _settle(null);
      _closed = true;
      _library?.close();
      _library = null;
      unawaited(_stopRecording());
    });
    ref.listen(pendingMatchProvider, (_, next) {
      if (next == null) return;
      _session++;
      _settle(null);
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

  /// Changes when library or kept catalog fingerprints change.
  Future<Object> _stamp() async {
    final fingerprints = ref.read(databaseProvider).fingerprintsDao;
    return (await fingerprints.stamp(), await fingerprints.catalogStamp());
  }

  Future<bool> _searchIsStale() async =>
      _library == null || await _stamp() != _libraryStamp;

  Future<LibrarySearch> _search() =>
      _opening ??= _openSearch().whenComplete(() => _opening = null);

  Future<LibrarySearch> _openSearch() async {
    final db = ref.read(databaseProvider);
    final stamp = await _stamp();
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

  /// Starts listening; done once the microphone is on.
  Future<void> listen() {
    _open(background: false);
    return _start(_session);
  }

  /// One Keep listening burst: how it ended, or null when another session
  /// replaced it.
  ///
  /// It keeps a found song on screen while it listens and when it finds
  /// nothing, saves nothing for later, and adds to History only a song that
  /// isn't the one shown.
  Future<ListenState?> listenInBackground() {
    final done = _open(background: true);
    unawaited(_start(_session));
    return done;
  }

  Future<ListenState?> _open({required bool background}) {
    _session++;
    _settle(null);
    final done = _done = Completer<ListenState?>();
    _background = background;
    _shown = switch (state) {
      final ListenFound found when background => found,
      _ => null,
    };
    return done.future;
  }

  Future<void> _start(int session) async {
    try {
      await _stopRecording();
      final allowed = await _microphone.requestPermission();
      if (session != _session) return;
      if (!allowed) return _end(const ListenDenied());
      final stale = await _searchIsStale();
      if (session != _session) return;
      if (stale && _shown == null) state = const ListenLoading();
      final library = await _search();
      if (session != _session) return;
      if (library.recordingCount == 0 &&
          ref.read(audioCatalogProvider) == null) {
        return _end(const ListenNothingToMatch());
      }
      await _record(session, library);
    } catch (e, s) {
      _fail(session, e, s);
    }
  }

  /// Ends the session with [result], shown unless a background session keeps
  /// its song on screen.
  void _end(ListenState result, {ListenState? show}) {
    state = show ?? _shown ?? result;
    _settle(result);
  }

  void _settle(ListenState? result) {
    final done = _done;
    _done = null;
    if (done != null && !done.isCompleted) done.complete(result);
  }

  /// [found] as a background session shows it: the shown song stays when it's
  /// at the expected moment, and History gets only a new song.
  void _found(ListenFound found) {
    final shown = _shown;
    if (shown != null && sameSong(shown, found)) {
      _end(found, show: sameMoment(shown, found, clock.now()) ? shown : found);
      return;
    }
    _end(found, show: found);
    _remember(found);
    ref.read(listenFoundEventsProvider).add(found);
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

    if (_shown == null) state = const Listening(Duration.zero);
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
      if (_shown == null) {
        state = Listening(
          heard,
          level: chunks.isEmpty ? 0 : loudness(chunks.last),
        );
      }
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
        final heardNow = await library.identify(_join(chunks), rate);
        if (session != _session) return;
        _log.fine('At $heard: ${heardNow.matches}');
        var found = await _onPhone(library, heardNow.matches, startedAt!);
        var offline = false;
        if (found == null || !found.sure) {
          final (inCatalog, reached) = await _inCatalog(
            heardNow.queries,
            startedAt!,
          );
          if (session != _session) return;
          offline = !reached;
          if (inCatalog != null && (found == null || inCatalog.sure)) {
            found = inCatalog;
          }
        }
        if (found != null && (found.sure || last)) {
          _found(found);
          await _stopRecording();
        } else if (last && offline && !_background) {
          _saveForLater(heardNow.queries, startedAt!);
          _end(const ListenSavedForLater());
          await _stopRecording();
        } else if (last) {
          _end(const ListenNotFound());
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
    _settle(null);
    state = _shown ?? const ListenIdle();
    await _stopRecording();
  }

  /// Stops a Keep listening burst, leaving a session the user started alone.
  Future<void> cancelBackground() async {
    if (_background && _done != null) await cancel();
  }

  /// Ends [session], if it's still the current one, and says listening failed.
  void _fail(int session, Object error, StackTrace stack) {
    _log.warning('Listening failed', error, stack);
    if (session != _session) return;
    _session++;
    _end(const ListenFailed());
    unawaited(_stopRecording());
  }

  /// The best match on the phone: a library file, or a catalog recording
  /// kept for offline.
  Future<ListenFound?> _onPhone(
    LibrarySearch search,
    List<AudioMatch> matches,
    DateTime startedAt,
  ) async {
    final match = matches.firstOrNull;
    if (match == null) return null;
    if (match.recordingId.startsWith(catalogSearchPrefix)) {
      final recordingId = match.recordingId.substring(
        catalogSearchPrefix.length,
      );
      final kept = search.catalogRecordings[recordingId];
      if (kept == null) return null;
      final song = await ref
          .read(databaseProvider)
          .catalogDao
          .entry(kept.songId);
      if (song == null) return null;
      return ListenFound(
        song: song,
        match: AudioMatch(
          recordingId: recordingId,
          position: match.position,
          score: match.score,
          playbackSpeed: match.playbackSpeed,
          ambiguousPosition: match.ambiguousPosition,
        ),
        startedAt: startedAt,
        sure: !match.ambiguousPosition,
        recordingDuration: kept.duration,
      );
    }
    final id = int.tryParse(match.recordingId);
    final tracks = ref.read(libraryTracksProvider).value ?? const <Track>[];
    for (final track in tracks) {
      if (track.id == id) {
        return ListenFound(
          track: track,
          match: match,
          startedAt: startedAt,
          sure: !match.ambiguousPosition,
        );
      }
    }
    // Fingerprinted, then removed from the library.
    return null;
  }

  /// The catalog's best match, or null when there's none or no backend; and
  /// whether the catalog answered (false offline).
  Future<(ListenFound?, bool)> _inCatalog(
    List<AudioFingerprint> queries,
    DateTime startedAt,
  ) async {
    final catalog = ref.read(audioCatalogProvider);
    if (catalog == null) return (null, true);
    final List<CatalogAudioMatch> matches;
    try {
      matches = await catalog.identify(
        queries,
        installId: installId(ref.read(sharedPreferencesProvider)),
        limit: 1,
      );
    } on NetworkFailure catch (e) {
      _log.info('The catalog could not be reached', e);
      return (null, false);
    } on ZemaFailure catch (e) {
      _log.warning('The catalog refused the lookup', e);
      return (null, true);
    }
    unawaited(ref.read(pendingLookupSenderProvider).flush());
    final best = matches.firstOrNull;
    if (best == null) return (null, true);
    _log.fine('In the catalog: $best');
    final song = await ref.read(databaseProvider).catalogDao.entry(best.songId);
    if (song == null) return (null, true);
    return (
      ListenFound(
        song: song,
        match: best.match,
        startedAt: startedAt,
        sure: !best.match.ambiguousPosition,
        recordingDuration: best.recordingDuration,
      ),
      true,
    );
  }

  void _saveForLater(List<AudioFingerprint> queries, DateTime heardAt) {
    unawaited(
      ref
          .read(databaseProvider)
          .identifiedDao
          .addPending(encodeQueries(queries), heardAt)
          .catchError((Object e, StackTrace s) {
            _log.warning('Could not keep the lookup for later', e, s);
          }),
    );
  }

  void _remember(ListenFound found) {
    unawaited(
      ref
          .read(databaseProvider)
          .identifiedDao
          .add(clock.now(), trackId: found.track?.id, songId: found.song?.id)
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
