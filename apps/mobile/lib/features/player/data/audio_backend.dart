import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';

final _log = Logger('player.backend');

/// Where the backend is with the loaded file.
enum BackendProcessing { idle, loading, buffering, ready, completed }

class BackendState {
  const BackendState({required this.playing, required this.processing});

  final bool playing;
  final BackendProcessing processing;

  @override
  bool operator ==(Object other) =>
      other is BackendState &&
      other.playing == playing &&
      other.processing == processing;

  @override
  int get hashCode => Object.hash(playing, processing);
}

/// Thrown by [AudioBackend.load] when a file can't be played.
class UnplayableAudioException implements Exception {
  const UnplayableAudioException(this.message);

  final String message;

  @override
  String toString() => 'UnplayableAudioException: $message';
}

/// How playback reacts to the outside world (Settings → Playback).
@immutable
class PlaybackOptions {
  const PlaybackOptions({
    this.pauseOnUnplug = true,
    this.duckOnInterruption = false,
    this.gapless = true,
  });

  /// Pause when headphones are unplugged.
  final bool pauseOnUnplug;

  /// When another app plays a short sound (a navigation prompt, a
  /// notification): lower the volume instead of pausing. Calls always pause.
  final bool duckOnInterruption;

  /// Preload the next track so it starts without a gap.
  final bool gapless;

  @override
  bool operator ==(Object other) =>
      other is PlaybackOptions &&
      other.pauseOnUnplug == pauseOnUnplug &&
      other.duckOnInterruption == duckOnInterruption &&
      other.gapless == gapless;

  @override
  int get hashCode => Object.hash(pauseOnUnplug, duckOnInterruption, gapless);
}

/// Plays one audio file at a time, optionally with the next one preloaded. The only code that touches the audio
/// plugin, so the handler above it can be tested with a fake.
abstract interface class AudioBackend {
  Stream<BackendState> get states;
  Stream<Duration> get positions;

  /// Fires when the file set with [setNext] took over by itself at the end
  /// of the current one. It is then the current file, and nothing is
  /// preloaded.
  Stream<void> get advanced;
  Duration get position;
  Duration get bufferedPosition;

  /// Loads [uri] and returns its duration when known.
  ///
  /// Throws [UnplayableAudioException] if the file can't be opened.
  Future<Duration?> load(String uri, {Duration position = Duration.zero});

  /// Preloads [uri] to start straight after the current file, replacing any
  /// file preloaded before; null clears it.
  Future<void> setNext(String? uri);

  /// Applies the unplug and interruption options ([PlaybackOptions.gapless]
  /// is the caller's: it decides whether to call [setNext]).
  Future<void> setOptions(PlaybackOptions options);

  /// Starts playing; returns once playback has started (not finished).
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> stop();
  Future<void> dispose();
}

/// [AudioBackend] on `just_audio`, with an `audio_session` set up for music:
/// calls pause playback (resuming after short interruptions); short sounds
/// from other apps pause it or lower its volume, and unplugging headphones
/// pauses it, depending on [PlaybackOptions].
///
/// The next file is preloaded as a second item in `just_audio`'s playlist,
/// so it starts without a gap; once it takes over, the finished item is
/// dropped and the playlist holds one file again.
class JustAudioBackend implements AudioBackend {
  JustAudioBackend() {
    unawaited(_configureSession());
    // The playlist holds the current file at 0 and at most a preloaded one
    // at 1, and nothing ever seeks to 1: reaching it means the player moved
    // on by itself. (`positionDiscontinuityStream` can't be used: it calls
    // every change of file without a seek an auto-advance, a new load
    // included.)
    _indexes = _player.currentIndexStream.listen((index) {
      if (index == 1 && _next != null) unawaited(_onAutoAdvance());
    });
  }

  final _player = AudioPlayer();
  final _advanced = StreamController<void>.broadcast();
  late final StreamSubscription<void> _indexes;
  StreamSubscription<void>? _noisy;
  var _options = const PlaybackOptions();
  String? _next;

  Future<void> _configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(_sessionConfiguration);
    _noisy = session.becomingNoisyEventStream.listen((_) {
      if (!_options.pauseOnUnplug) return;
      _log.fine('Headphones unplugged: pausing');
      unawaited(_player.pause());
    });
  }

  /// With "will pause when ducked", `audio_session` turns duck requests into
  /// pause events, which `just_audio` pauses for and resumes after.
  /// Without it, Android lowers the volume itself.
  AudioSessionConfiguration get _sessionConfiguration =>
      const AudioSessionConfiguration.music().copyWith(
        androidWillPauseWhenDucked: !_options.duckOnInterruption,
      );

  @override
  Future<void> setOptions(PlaybackOptions options) async {
    final duckChanged =
        options.duckOnInterruption != _options.duckOnInterruption;
    _options = options;
    if (!duckChanged) return;
    final session = await AudioSession.instance;
    await session.configure(_sessionConfiguration);
    // The focus request made when playback started captured the old
    // setting; ask again so it applies now.
    if (_player.playing) await session.setActive(true);
  }

  Future<void> _onAutoAdvance() async {
    _next = null;
    _advanced.add(null);
    // Drop the finished file; the one playing becomes item 0.
    if (_player.audioSources.length > 1) await _player.removeAudioSourceAt(0);
  }

  @override
  Stream<void> get advanced => _advanced.stream;

  @override
  Stream<BackendState> get states => _player.playerStateStream.map(
    (s) => BackendState(
      playing: s.playing,
      processing: switch (s.processingState) {
        ProcessingState.idle => BackendProcessing.idle,
        ProcessingState.loading => BackendProcessing.loading,
        ProcessingState.buffering => BackendProcessing.buffering,
        ProcessingState.ready => BackendProcessing.ready,
        ProcessingState.completed => BackendProcessing.completed,
      },
    ),
  );

  @override
  Stream<Duration> get positions => _player.positionStream;

  @override
  Duration get position => _player.position;

  @override
  Duration get bufferedPosition => _player.bufferedPosition;

  @override
  Future<Duration?> load(
    String uri, {
    Duration position = Duration.zero,
  }) async {
    _next = null;
    try {
      return await _player.setAudioSource(
        AudioSource.uri(Uri.parse(uri)),
        initialPosition: position,
      );
    } on PlayerException catch (e) {
      throw UnplayableAudioException('${e.code}: ${e.message}');
    } on PlayerInterruptedException {
      // A newer load replaced this one.
      return null;
    }
  }

  @override
  Future<void> setNext(String? uri) async {
    if (uri == _next) return;
    _next = uri;
    final current = _player.currentIndex ?? 0;
    final count = _player.audioSources.length;
    if (count > current + 1) {
      await _player.removeAudioSourceRange(current + 1, count);
    }
    if (uri != null) {
      await _player.addAudioSource(AudioSource.uri(Uri.parse(uri)));
    }
  }

  @override
  Future<void> play() async {
    // just_audio's play() completes when playback stops, not when it starts.
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() async {
    await _indexes.cancel();
    await _noisy?.cancel();
    await _advanced.close();
    await _player.dispose();
  }
}
