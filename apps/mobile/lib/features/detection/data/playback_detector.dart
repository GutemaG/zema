import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _log = Logger('detection');

enum DetectedState { playing, paused, buffering, stopped, gone }

class DetectedPlayback {
  const DetectedPlayback({
    required this.source,
    required this.state,
    this.title,
    this.artist,
    this.mediaId,
    this.duration,
    this.position = Duration.zero,
    this.positionUpdatedAt,
    this.speed = 1,
  });

  final String source;
  final DetectedState state;
  final String? title;
  final String? artist;
  final String? mediaId;
  final Duration? duration;
  final Duration position;
  final DateTime? positionUpdatedAt;
  final double speed;

  bool get isPlaying => state == DetectedState.playing;

  Duration positionAt(DateTime now) {
    final at = positionUpdatedAt;
    var live = position;
    if (isPlaying && at != null && now.isAfter(at)) {
      live += now.difference(at) * speed;
    }
    final end = duration;
    if (end != null && live > end) return end;
    return live;
  }

  static DetectedPlayback? fromMap(Object? value) {
    if (value is! Map) return null;
    final source = value['sourcePackage'];
    if (source is! String || source.isEmpty) return null;
    final state = DetectedState.values.asNameMap()[value['playbackState']];
    final durationMs = (value['durationMs'] as num?)?.toInt();
    final updatedAt = (value['positionUpdatedAt'] as num?)?.toInt();
    return DetectedPlayback(
      source: source,
      state: state ?? DetectedState.stopped,
      title: _text(value['title']),
      artist: _text(value['artist']),
      mediaId: _text(value['mediaId']),
      duration: durationMs != null && durationMs > 0
          ? Duration(milliseconds: durationMs)
          : null,
      position: Duration(
        milliseconds: (value['positionMs'] as num?)?.toInt() ?? 0,
      ),
      positionUpdatedAt: updatedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(updatedAt),
      speed: (value['speed'] as num?)?.toDouble() ?? 1,
    );
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

abstract interface class PlaybackDetector {
  Stream<DetectedPlayback> get events;

  Future<bool> hasAccess();

  Future<void> openAccessSettings();

  Future<bool> enabled();

  Future<void> setEnabled(bool on);

  Future<Set<String>> sources();

  Future<void> setSources(Set<String> sources);
}

class NoPlaybackDetector implements PlaybackDetector {
  const NoPlaybackDetector();

  @override
  Stream<DetectedPlayback> get events => const Stream.empty();

  @override
  Future<bool> hasAccess() async => false;

  @override
  Future<void> openAccessSettings() async {}

  @override
  Future<bool> enabled() async => false;

  @override
  Future<void> setEnabled(bool on) async {}

  @override
  Future<Set<String>> sources() async => const {};

  @override
  Future<void> setSources(Set<String> sources) async {}
}

class AndroidPlaybackDetector implements PlaybackDetector {
  const AndroidPlaybackDetector([
    this._methods = const MethodChannel('zema/detection'),
    this._events = const EventChannel('zema/detection/events'),
  ]);

  final MethodChannel _methods;
  final EventChannel _events;

  @override
  Stream<DetectedPlayback> get events => _events
      .receiveBroadcastStream()
      .map(DetectedPlayback.fromMap)
      .where((event) => event != null)
      .cast<DetectedPlayback>()
      .handleError((Object e) => _log.warning('Detection events failed', e));

  @override
  Future<bool> hasAccess() async {
    try {
      return await _methods.invokeMethod<bool>('hasAccess') ?? false;
    } on PlatformException catch (e) {
      _log.warning('Checking notification access failed', e);
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> openAccessSettings() async {
    try {
      await _methods.invokeMethod<void>('openAccessSettings');
    } on PlatformException catch (e) {
      _log.warning('Opening notification access settings failed', e);
    } on MissingPluginException {
      return;
    }
  }

  @override
  Future<bool> enabled() async {
    try {
      return await _methods.invokeMethod<bool>('enabled') ?? true;
    } on PlatformException catch (e) {
      _log.warning('Reading the detection switch failed', e);
      return true;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> setEnabled(bool on) =>
      _methods.invokeMethod<void>('setEnabled', on);

  @override
  Future<Set<String>> sources() async {
    try {
      final list = await _methods.invokeListMethod<String>('sources');
      return {...?list};
    } on PlatformException catch (e) {
      _log.warning('Reading detection sources failed', e);
      return const {};
    } on MissingPluginException {
      return const {};
    }
  }

  @override
  Future<void> setSources(Set<String> sources) =>
      _methods.invokeMethod<void>('setSources', sources.toList());
}
