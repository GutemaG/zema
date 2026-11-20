import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

final _log = Logger('identify.keep');

/// What the Keep listening notification says.
typedef KeepListeningNotice = ({String title, String text});

/// Keeps the microphone usable with the screen off, and shows that it's on
/// (Android's microphone foreground service and its notification).
abstract interface class KeepListeningService {
  /// Starts the service, showing [notice] with a [stopLabel] button, for at
  /// most [length]. Android asks to show notifications first; without that
  /// the service still runs, unseen except for the microphone indicator.
  Future<void> start(
    KeepListeningNotice notice, {
    required String stopLabel,
    required Duration length,
  });

  Future<void> show(KeepListeningNotice notice);

  /// Stops the service; [why], when given, stays as a notification.
  Future<void> stop({String? why});

  /// Stop tapped in the notification.
  Stream<void> get stopTaps;
}

final keepListeningServiceProvider = Provider<KeepListeningService>((ref) {
  if (!Platform.isAndroid) return const NoKeepListeningService();
  final service = AndroidKeepListeningService();
  ref.onDispose(service.dispose);
  return service;
});

/// iOS and tests: listening goes on only while Zema is open.
class NoKeepListeningService implements KeepListeningService {
  const NoKeepListeningService();

  @override
  Future<void> start(
    KeepListeningNotice notice, {
    required String stopLabel,
    required Duration length,
  }) async {}

  @override
  Future<void> show(KeepListeningNotice notice) async {}

  @override
  Future<void> stop({String? why}) async {}

  @override
  Stream<void> get stopTaps => const Stream.empty();
}

class AndroidKeepListeningService implements KeepListeningService {
  AndroidKeepListeningService([
    this._channel = const MethodChannel('zema/keep_listening'),
  ]) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'stopTapped') _stops.add(null);
    });
  }

  final MethodChannel _channel;
  final _stops = StreamController<void>.broadcast();

  @override
  Future<void> start(
    KeepListeningNotice notice, {
    required String stopLabel,
    required Duration length,
  }) async {
    try {
      await Permission.notification.request();
    } on PlatformException catch (e) {
      _log.info('Asking to show notifications failed', e);
    }
    await _call('start', {
      'title': notice.title,
      'text': notice.text,
      'stop': stopLabel,
      'lengthMs': length.inMilliseconds,
    });
  }

  @override
  Future<void> show(KeepListeningNotice notice) =>
      _call('show', {'title': notice.title, 'text': notice.text});

  @override
  Future<void> stop({String? why}) => _call('stop', {'why': why});

  @override
  Stream<void> get stopTaps => _stops.stream;

  Future<void> _call(String method, Map<String, Object?> args) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on PlatformException catch (e) {
      _log.warning('Keep listening $method failed', e);
    } on MissingPluginException {
      return;
    }
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
    unawaited(_stops.close());
  }
}
