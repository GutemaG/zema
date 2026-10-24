import 'dart:async';

import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/features/player/application/player_providers.dart';
import 'package:zema/features/player/data/audio_backend.dart';
import 'package:zema/features/player/data/zema_audio_handler.dart';

/// An [AudioBackend] that plays nothing. Loads succeed instantly unless the
/// URI is in [unplayable]; [finishTrack] simulates a track playing to its
/// end. Like `just_audio`, it delivers state events asynchronously, so tests
/// let events settle (`pumpEventQueue`) before checking the handler.
class FakeAudioBackend implements AudioBackend {
  final _states = StreamController<BackendState>.broadcast();
  final _positions = StreamController<Duration>.broadcast();

  /// URIs that fail to load.
  final unplayable = <String>{};

  /// Every URI loaded, in order.
  final loaded = <String>[];
  var playing = false;
  var processing = BackendProcessing.idle;
  var volume = 1.0;
  Duration _position = Duration.zero;
  Duration? duration = const Duration(seconds: 60);

  void _emit() =>
      _states.add(BackendState(playing: playing, processing: processing));

  /// Moves the position, as playback would.
  void advanceTo(Duration position) {
    _position = position;
    _positions.add(position);
  }

  /// The current track reaches its end.
  void finishTrack() {
    processing = BackendProcessing.completed;
    _emit();
  }

  @override
  Stream<BackendState> get states => _states.stream;

  @override
  Stream<Duration> get positions => _positions.stream;

  @override
  Duration get position => _position;

  @override
  Duration get bufferedPosition => _position;

  @override
  Future<Duration?> load(
    String uri, {
    Duration position = Duration.zero,
  }) async {
    loaded.add(uri);
    processing = BackendProcessing.loading;
    _emit();
    if (unplayable.contains(uri)) {
      processing = BackendProcessing.idle;
      _emit();
      throw UnplayableAudioException('fake: $uri');
    }
    _position = position;
    processing = BackendProcessing.ready;
    _emit();
    return duration;
  }

  @override
  Future<void> play() async {
    playing = true;
    _emit();
  }

  @override
  Future<void> pause() async {
    playing = false;
    _emit();
  }

  @override
  Future<void> seek(Duration position) async {
    if (processing == BackendProcessing.completed) {
      processing = BackendProcessing.ready;
    }
    advanceTo(position);
    _emit();
  }

  @override
  Future<void> setVolume(double volume) async => this.volume = volume;

  @override
  Future<void> stop() async {
    playing = false;
    processing = BackendProcessing.idle;
    _emit();
  }

  @override
  Future<void> dispose() async {
    await _states.close();
    await _positions.close();
  }
}

/// A handler over a [FakeAudioBackend], disposed when the test ends.
ZemaAudioHandler fakeAudioHandler([FakeAudioBackend? backend]) {
  final handler = ZemaAudioHandler(backend ?? FakeAudioBackend());
  addTearDown(handler.dispose);
  return handler;
}

/// Provider overrides that replace the player with a fake one.
List<Override> playerOverrides({ZemaAudioHandler? handler}) => [
  audioHandlerProvider.overrideWithValue(handler ?? fakeAudioHandler()),
];
