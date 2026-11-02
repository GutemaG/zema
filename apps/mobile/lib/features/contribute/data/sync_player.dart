import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// The sync editor's own player, separate from the main one, so syncing
/// doesn't touch the queue. Tests use a fake.
abstract interface class SyncPlayer {
  /// Loads [uri] (a `content://` track or a `file://` copy); returns its
  /// length when known.
  Future<Duration?> load(Uri uri);

  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setSpeed(double speed);

  /// Where playback is now.
  Duration get position;
  Stream<Duration> get positions;
  Stream<bool> get playing;

  Future<void> dispose();
}

/// [SyncPlayer] on just_audio.
class JustAudioSyncPlayer implements SyncPlayer {
  final _player = AudioPlayer();

  @override
  Future<Duration?> load(Uri uri) =>
      _player.setAudioSource(AudioSource.uri(uri));

  @override
  Future<void> play() {
    // just_audio's play completes when playback stops; don't wait for it.
    unawaited(_player.play());
    return Future.value();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Duration get position => _player.position;

  @override
  Stream<Duration> get positions => _player.createPositionStream(
    minPeriod: const Duration(milliseconds: 50),
    maxPeriod: const Duration(milliseconds: 200),
  );

  @override
  Stream<bool> get playing => _player.playingStream;

  @override
  Future<void> dispose() => _player.dispose();
}
