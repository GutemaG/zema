import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:clock/clock.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';
import 'package:zema_core/zema_core.dart';

import 'audio_backend.dart';
import 'play_counter.dart';
import 'player_snapshot.dart';
import 'sleep_timer.dart';

final _log = Logger('player.handler');

/// The player: owns the queue and the audio backend, and publishes state to
/// the app ([snapshots], [positions]) and to the system (notification, lock
/// screen, headset buttons) through `audio_service`.
///
/// Plays one file at a time; [PlayQueue] decides what comes next. With
/// gapless on, the next file is preloaded and takes over by itself. Also
/// runs the sleep timer, so it keeps going while the UI is closed, and
/// reports counted plays ([playCounted]).
class ZemaAudioHandler extends BaseAudioHandler with SeekHandler {
  ZemaAudioHandler(this._backend, {PlayQueue<Track>? queue})
    : _queue = queue ?? PlayQueue<Track>() {
    _counter = PlayCounter(onCounted: _played.add);
    _subscriptions
      ..add(_backend.states.listen(_onBackendState))
      ..add(_backend.advanced.listen((_) => _onAdvanced()))
      ..add(_backend.positions.listen((_) => _counter.tick()));
  }

  final AudioBackend _backend;
  final PlayQueue<Track> _queue;
  final _subscriptions = <StreamSubscription<void>>[];
  final _snapshots = BehaviorSubject.seeded(PlayerSnapshot.empty);
  final _unplayable = StreamController<Track>.broadcast();
  final _played = StreamController<Track>.broadcast();
  late final PlayCounter _counter;
  var _options = const PlaybackOptions();

  /// Whether [setOptions] has run; the first call always reaches the
  /// backend.
  var _optionsApplied = false;
  BackendState _state = const BackendState(
    playing: false,
    processing: BackendProcessing.idle,
  );
  Duration? _duration;
  SleepTimer? _sleep;
  Timer? _sleepTimer;
  Timer? _fadeTimer;

  /// How long the volume takes to fade out when a sleep timer ends.
  static const fadeDuration = Duration(seconds: 5);
  static const _fadeSteps = 20;

  /// Bumped on every load, so a slow load that finishes after a newer one
  /// is ignored.
  var _loadGeneration = 0;

  ValueStream<PlayerSnapshot> get snapshots => _snapshots.stream;
  PlayerSnapshot get snapshot => _snapshots.value;

  /// The current track's position.
  Stream<Duration> get positions => _backend.positions;
  Duration get position => _backend.position;

  /// Tracks that could not be played (they are skipped).
  Stream<Track> get unplayable => _unplayable.stream;

  /// A track each time a play of it counts (see [PlayCounter]).
  Stream<Track> get playCounted => _played.stream;

  /// Applies Settings → Playback.
  Future<void> setOptions(PlaybackOptions options) async {
    if (_optionsApplied && options == _options) return;
    _optionsApplied = true;
    _options = options;
    await _backend.setOptions(options);
    await _syncNext();
  }

  /// Replaces the queue with [tracks] and plays from [start].
  Future<void> playTracks(
    List<Track> tracks, {
    int start = 0,
    bool shuffle = false,
    Duration position = Duration.zero,
  }) async {
    if (tracks.isEmpty) return;
    _queue.load(tracks, start: start, shuffle: shuffle);
    await _loadCurrent(play: true, position: position);
  }

  /// Loads a saved queue without playing (on app start). [tracks] are in
  /// the saved play order, so shuffle starts off.
  Future<void> restore(
    List<Track> tracks, {
    required int index,
    required Duration position,
    QueueRepeat repeat = QueueRepeat.off,
  }) async {
    if (tracks.isEmpty) return;
    _queue
      ..load(tracks, start: index)
      ..repeat = repeat;
    await _loadCurrent(play: false, position: position);
  }

  @override
  Future<void> play() async {
    if (_queue.isEmpty) return;
    if (_state.processing == BackendProcessing.completed) {
      await _backend.seek(Duration.zero);
    }
    await _backend.play();
  }

  @override
  Future<void> pause() async {
    await _backend.pause();
    // Pausing during a sleep fade ends it early.
    if (_fadeTimer != null) {
      _cancelSleep();
      _publish();
    }
  }

  @override
  Future<void> seek(Duration position) => _backend.seek(position);

  @override
  Future<void> skipToNext() async {
    _log.fine('Skip to next');
    if (_queue.next()) await _loadCurrent(play: _wantsToPlay);
  }

  @override
  Future<void> skipToPrevious() async {
    if (_queue.previous(_backend.position)) {
      await _loadCurrent(play: _wantsToPlay);
    } else {
      await _backend.seek(Duration.zero);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _queue.jumpTo(index);
    await _loadCurrent(play: true);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    _queue.setShuffle(shuffleMode != AudioServiceShuffleMode.none);
    _queueChanged();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    _queue.repeat = switch (repeatMode) {
      AudioServiceRepeatMode.none => QueueRepeat.off,
      AudioServiceRepeatMode.one => QueueRepeat.one,
      AudioServiceRepeatMode.all ||
      AudioServiceRepeatMode.group => QueueRepeat.all,
    };
    _queueChanged();
  }

  /// Moves the queue entry at [from] to [to] (indexes in play order, [to]
  /// counted after removal).
  Future<void> moveQueueItem(int from, int to) async {
    if (from == to) return;
    _queue.move(from, to);
    _queueChanged();
  }

  /// Removes the queue entry at [index]; returns what [restoreQueueItem]
  /// needs to undo it, or null for the current track (which can't be
  /// removed).
  Future<QueueRemoval<Track>?> removeQueueEntry(int index) async {
    final removal = _queue.removeAt(index);
    if (removal != null) _queueChanged();
    return removal;
  }

  /// Puts back an entry removed by [removeQueueEntry].
  Future<void> restoreQueueItem(QueueRemoval<Track> removal) async {
    if (_queue.restore(removal)) _queueChanged();
  }

  /// Puts [tracks] right after the current track. With an empty queue they
  /// become the queue, loaded paused.
  Future<void> playNext(List<Track> tracks) =>
      _enqueue(tracks, _queue.insertNext);

  /// Puts [tracks] at the end of the queue. With an empty queue they become
  /// the queue, loaded paused.
  Future<void> addToQueue(List<Track> tracks) => _enqueue(tracks, _queue.add);

  Future<void> _enqueue(
    List<Track> tracks,
    void Function(List<Track>) insert,
  ) async {
    if (tracks.isEmpty) return;
    final wasEmpty = _queue.isEmpty;
    insert(tracks);
    if (wasEmpty) {
      await _loadCurrent(play: false);
    } else {
      _queueChanged();
    }
  }

  /// Removes everything after the current track.
  Future<void> clearUpcoming() async {
    _queue.clearUpcoming();
    _queueChanged();
  }

  /// Pauses playback after [after], fading out over [fadeDuration]. Replaces
  /// any running timer.
  void setSleepTimer(Duration after) {
    _cancelSleep();
    _sleep = TimedSleep(clock.now().add(after));
    _sleepTimer = Timer(after, _onSleepTimerEnd);
    _log.fine('Sleep timer set for $after');
    _publish();
  }

  /// Stops playback when the current track ends. Replaces any running timer.
  void sleepAtEndOfTrack() {
    _cancelSleep();
    _sleep = const EndOfTrackSleep();
    _queueChanged();
  }

  void cancelSleepTimer() {
    _cancelSleep();
    _queueChanged();
  }

  @override
  Future<void> stop() async {
    _cancelSleep();
    _counter.stop();
    await _backend.stop();
    await super.stop();
  }

  /// Releases the backend. The handler can't be used afterwards.
  Future<void> dispose() async {
    _sleepTimer?.cancel();
    _fadeTimer?.cancel();
    _counter.stop();
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _backend.dispose();
    await _snapshots.close();
    await _unplayable.close();
    await _played.close();
  }

  bool get _wantsToPlay =>
      _state.playing && _state.processing != BackendProcessing.completed;

  /// Loads the queue's current track; skips forward past unplayable files
  /// (at most once around the queue).
  Future<void> _loadCurrent({
    required bool play,
    Duration position = Duration.zero,
  }) async {
    final generation = ++_loadGeneration;
    _log.fine('Loading queue item ${_queue.index} (play: $play)');
    for (var attempts = 0; attempts < _queue.length; attempts++) {
      final track = _queue.current!;
      _duration = track.duration;
      _publish();
      try {
        final duration = await _backend.load(track.uri, position: position);
        if (generation != _loadGeneration) return;
        _duration = duration ?? track.duration;
        _counter.start(track);
        _publish();
        if (play) await _backend.play();
        await _syncNext();
        return;
      } on UnplayableAudioException catch (e) {
        if (generation != _loadGeneration) return;
        _log.warning('Skipping a track that cannot be played: ${e.message}');
        _unplayable.add(track);
        position = Duration.zero;
        if (!_queue.next()) break;
      }
    }
    // Nothing in the queue can be played: clear it so the app doesn't keep
    // showing a song that won't play.
    _queue.load(const []);
    _duration = null;
    _counter.stop();
    await _backend.stop();
    _publish();
  }

  /// Stops the timer and any fade in progress, restoring the volume.
  void _cancelSleep() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    if (_fadeTimer != null) {
      _fadeTimer!.cancel();
      _fadeTimer = null;
      unawaited(_backend.setVolume(1));
    }
    _sleep = null;
  }

  void _onSleepTimerEnd() {
    _sleepTimer = null;
    if (!_wantsToPlay) {
      _log.fine('Sleep timer ended while paused');
      _sleep = null;
      _publish();
      return;
    }
    _log.fine('Sleep timer ended: fading out');
    var step = 0;
    _fadeTimer = Timer.periodic(fadeDuration ~/ _fadeSteps, (timer) {
      step++;
      if (step < _fadeSteps) {
        unawaited(_backend.setVolume(1 - step / _fadeSteps));
        return;
      }
      timer.cancel();
      _fadeTimer = null;
      _sleep = null;
      unawaited(_pauseAfterFade());
    });
  }

  Future<void> _pauseAfterFade() async {
    await _backend.setVolume(0);
    await _backend.pause();
    // Back to full volume for the next play.
    await _backend.setVolume(1);
    _publish();
  }

  void _onBackendState(BackendState state) {
    _log.finer('Backend: playing ${state.playing}, ${state.processing.name}');
    final completed =
        state.processing == BackendProcessing.completed &&
        _state.processing != BackendProcessing.completed;
    _state = state;
    _counter.setPlaying(
      state.playing && state.processing == BackendProcessing.ready,
    );
    _publish();
    if (completed) unawaited(_onTrackCompleted());
  }

  /// The preloaded next file took over (gapless).
  void _onAdvanced() {
    _counter.completed();
    if (_queue.trackCompleted() != QueueAdvance.advanced) {
      // The queue changed before the preload caught up: play what the
      // queue says instead.
      unawaited(_loadCurrent(play: _wantsToPlay));
      return;
    }
    final track = _queue.current!;
    _log.fine('Advanced without a gap');
    _duration = track.duration;
    _counter.start(track);
    _publish();
    unawaited(_syncNext());
  }

  /// Publishes a queue edit and updates the preloaded next file.
  void _queueChanged() {
    _publish();
    unawaited(_syncNext());
  }

  /// Preloads what the queue plays next, or nothing when gapless is off,
  /// the current track repeats, or playback should stop at its end.
  Future<void> _syncNext() async {
    final next = _options.gapless && _sleep is! EndOfTrackSleep
        ? _queue.upcoming
        : null;
    await _backend.setNext(next?.uri);
  }

  Future<void> _onTrackCompleted() async {
    _counter.completed();
    final advance = _queue.trackCompleted();
    _log.fine('Track completed: $advance');
    if (_sleep is EndOfTrackSleep) {
      // Stop here, with the next track ready to play.
      _sleep = null;
      await _backend.pause();
      if (advance == QueueAdvance.advanced) {
        await _loadCurrent(play: false);
      } else {
        await _backend.seek(Duration.zero);
        _counter.start(_queue.current!);
        _publish();
      }
      return;
    }
    switch (advance) {
      case QueueAdvance.replay:
        _counter.start(_queue.current!);
        await _backend.seek(Duration.zero);
        await _backend.play();
      case QueueAdvance.advanced:
        await _loadCurrent(play: true);
      case QueueAdvance.finished:
        _counter.start(_queue.current!);
        await _backend.pause();
        await _backend.seek(Duration.zero);
    }
  }

  /// Sends the current state to the app and to the system.
  void _publish() {
    final tracks = _queue.items;
    final current = _queue.current;
    final buffering =
        _state.processing == BackendProcessing.loading ||
        _state.processing == BackendProcessing.buffering;
    final playing =
        _state.playing && _state.processing != BackendProcessing.completed;

    _snapshots.add(
      PlayerSnapshot(
        queue: tracks,
        queueKeys: _queue.keys,
        index: _queue.index,
        playing: playing,
        buffering: buffering,
        shuffle: _queue.shuffle,
        repeat: _queue.repeat,
        duration: _duration,
        sleepTimer: _sleep,
      ),
    );

    mediaItem.add(current == null ? null : _mediaItem(current, _duration));
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: current == null
            ? AudioProcessingState.idle
            : switch (_state.processing) {
                BackendProcessing.idle => AudioProcessingState.idle,
                BackendProcessing.loading => AudioProcessingState.loading,
                BackendProcessing.buffering => AudioProcessingState.buffering,
                BackendProcessing.ready => AudioProcessingState.ready,
                BackendProcessing.completed => AudioProcessingState.completed,
              },
        playing: playing,
        updatePosition: _backend.position,
        bufferedPosition: _backend.bufferedPosition,
        queueIndex: current == null ? null : _queue.index,
        shuffleMode: _queue.shuffle
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
        repeatMode: switch (_queue.repeat) {
          QueueRepeat.off => AudioServiceRepeatMode.none,
          QueueRepeat.one => AudioServiceRepeatMode.one,
          QueueRepeat.all => AudioServiceRepeatMode.all,
        },
      ),
    );
  }

  static MediaItem _mediaItem(Track track, Duration? duration) => MediaItem(
    id: '${track.id}',
    title: track.title,
    artist: track.artist,
    album: track.album,
    duration: duration ?? track.duration,
    // The audio file's own URI: Android loads its embedded art as a
    // thumbnail.
    artUri: Uri.parse(track.uri),
    extras: const {'loadThumbnailUri': 'true'},
  );
}
