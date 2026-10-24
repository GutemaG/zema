import 'dart:async';

import 'package:audio_session/audio_session.dart';
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

/// Plays one audio file at a time. The only code that touches the audio
/// plugin, so the handler above it can be tested with a fake.
abstract interface class AudioBackend {
  Stream<BackendState> get states;
  Stream<Duration> get positions;
  Duration get position;
  Duration get bufferedPosition;

  /// Loads [uri] and returns its duration when known.
  ///
  /// Throws [UnplayableAudioException] if the file can't be opened.
  Future<Duration?> load(String uri, {Duration position = Duration.zero});

  /// Starts playing; returns once playback has started (not finished).
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setVolume(double volume);
  Future<void> stop();
  Future<void> dispose();
}

/// [AudioBackend] on `just_audio`, with an `audio_session` set up for music:
/// calls and other apps pause playback (resuming after short interruptions),
/// and unplugging headphones pauses it.
class JustAudioBackend implements AudioBackend {
  JustAudioBackend() {
    unawaited(_configureSession());
  }

  final _player = AudioPlayer();
  StreamSubscription<void>? _noisy;

  Future<void> _configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _noisy = session.becomingNoisyEventStream.listen((_) {
      _log.fine('Headphones unplugged: pausing');
      unawaited(_player.pause());
    });
  }

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
    await _noisy?.cancel();
    await _player.dispose();
  }
}
