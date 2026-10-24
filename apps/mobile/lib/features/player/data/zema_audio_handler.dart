import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';
import 'package:zema_core/zema_core.dart';

import 'audio_backend.dart';
import 'player_snapshot.dart';

final _log = Logger('player.handler');

/// The player: owns the queue and the audio backend, and publishes state to
/// the app ([snapshots], [positions]) and to the system (notification, lock
/// screen, headset buttons) through `audio_service`.
///
/// Plays one file at a time; [PlayQueue] decides what comes next.
class ZemaAudioHandler extends BaseAudioHandler with SeekHandler {
  ZemaAudioHandler(this._backend, {PlayQueue<Track>? queue})
    : _queue = queue ?? PlayQueue<Track>() {
    _subscriptions.add(_backend.states.listen(_onBackendState));
  }

  final AudioBackend _backend;
  final PlayQueue<Track> _queue;
  final _subscriptions = <StreamSubscription<void>>[];
  final _snapshots = BehaviorSubject.seeded(PlayerSnapshot.empty);
  final _unplayable = StreamController<Track>.broadcast();
  BackendState _state = const BackendState(
    playing: false,
    processing: BackendProcessing.idle,
  );
  Duration? _duration;

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

  /// Replaces the queue with [tracks] and plays from [start].
  Future<void> playTracks(
    List<Track> tracks, {
    int start = 0,
    bool shuffle = false,
  }) async {
    if (tracks.isEmpty) return;
    _queue.load(tracks, start: start, shuffle: shuffle);
    await _loadCurrent(play: true);
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
  Future<void> pause() => _backend.pause();

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
    _publish();
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    _queue.repeat = switch (repeatMode) {
      AudioServiceRepeatMode.none => QueueRepeat.off,
      AudioServiceRepeatMode.one => QueueRepeat.one,
      AudioServiceRepeatMode.all ||
      AudioServiceRepeatMode.group => QueueRepeat.all,
    };
    _publish();
  }

  @override
  Future<void> stop() async {
    await _backend.stop();
    await super.stop();
  }

  /// Releases the backend. The handler can't be used afterwards.
  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _backend.dispose();
    await _snapshots.close();
    await _unplayable.close();
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
        _publish();
        if (play) await _backend.play();
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
    await _backend.stop();
    _publish();
  }

  void _onBackendState(BackendState state) {
    _log.finer('Backend: playing ${state.playing}, ${state.processing.name}');
    final completed =
        state.processing == BackendProcessing.completed &&
        _state.processing != BackendProcessing.completed;
    _state = state;
    _publish();
    if (completed) unawaited(_onTrackCompleted());
  }

  Future<void> _onTrackCompleted() async {
    final advance = _queue.trackCompleted();
    _log.fine('Track completed: $advance');
    switch (advance) {
      case QueueAdvance.replay:
        await _backend.seek(Duration.zero);
        await _backend.play();
      case QueueAdvance.advanced:
        await _loadCurrent(play: true);
      case QueueAdvance.finished:
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
        index: _queue.index,
        playing: playing,
        buffering: buffering,
        shuffle: _queue.shuffle,
        repeat: _queue.repeat,
        duration: _duration,
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
