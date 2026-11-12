import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _log = Logger('identify.launch');

sealed class LaunchRequest {
  const LaunchRequest();
}

class OpenListenHistory extends LaunchRequest {
  const OpenListenHistory();
}

class OpenListenMatch extends LaunchRequest {
  const OpenListenMatch({
    required this.trackId,
    required this.position,
    required this.startedAt,
    required this.speed,
    required this.score,
    required this.sure,
  });

  final int trackId;
  final Duration position;
  final DateTime startedAt;
  final double speed;
  final int score;
  final bool sure;

  Map<String, Object> toMap() => {
    'trackId': trackId,
    'positionMs': position.inMilliseconds,
    'startedAtMs': startedAt.millisecondsSinceEpoch,
    'speed': speed,
    'score': score,
    'sure': sure,
  };

  static OpenListenMatch? fromMap(Map<Object?, Object?> map) {
    final trackId = map['trackId'];
    if (trackId is! int || trackId < 0) return null;
    return OpenListenMatch(
      trackId: trackId,
      position: Duration(
        milliseconds: (map['positionMs'] as num?)?.toInt() ?? 0,
      ),
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['startedAtMs'] as num?)?.toInt() ?? 0,
      ),
      speed: (map['speed'] as num?)?.toDouble() ?? 1,
      score: (map['score'] as num?)?.toInt() ?? 0,
      sure: map['sure'] as bool? ?? true,
    );
  }
}

abstract interface class LaunchReceiver {
  Future<LaunchRequest?> takeInitial();

  Stream<LaunchRequest> get launches;
}

class NoLaunchReceiver implements LaunchReceiver {
  const NoLaunchReceiver();

  @override
  Future<LaunchRequest?> takeInitial() async => null;

  @override
  Stream<LaunchRequest> get launches => const Stream.empty();
}

class AndroidLaunchReceiver implements LaunchReceiver {
  AndroidLaunchReceiver([this._channel = const MethodChannel('zema/launch')]) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'launch') {
        if (read(call.arguments) case final request?) _launches.add(request);
      }
    });
  }

  final MethodChannel _channel;
  final _launches = StreamController<LaunchRequest>.broadcast();

  @override
  Future<LaunchRequest?> takeInitial() async {
    try {
      return read(await _channel.invokeMethod<Object?>('takeLaunch'));
    } on PlatformException catch (e) {
      _log.warning('Reading how Zema was opened failed', e);
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Stream<LaunchRequest> get launches => _launches.stream;

  static LaunchRequest? read(Object? value) {
    if (value is! Map) return null;
    return switch (value['open']) {
      'history' => const OpenListenHistory(),
      'match' => OpenListenMatch.fromMap(value),
      _ => null,
    };
  }
}

abstract interface class QuickListenHost {
  Future<void> openApp(OpenListenMatch match);

  Future<void> close();
}

class AndroidQuickListenHost implements QuickListenHost {
  const AndroidQuickListenHost([
    this._channel = const MethodChannel('zema/quick_listen'),
  ]);

  final MethodChannel _channel;

  @override
  Future<void> openApp(OpenListenMatch match) =>
      _channel.invokeMethod<void>('openApp', match.toMap());

  @override
  Future<void> close() => _channel.invokeMethod<void>('close');
}

abstract interface class HomeWidget {
  Future<void> showLast({String? title, String? artist});
}

class NoHomeWidget implements HomeWidget {
  const NoHomeWidget();

  @override
  Future<void> showLast({String? title, String? artist}) async {}
}

class AndroidHomeWidget implements HomeWidget {
  const AndroidHomeWidget([this._channel = const MethodChannel('zema/widget')]);

  final MethodChannel _channel;

  @override
  Future<void> showLast({String? title, String? artist}) async {
    try {
      await _channel.invokeMethod<void>('setLast', {
        'title': title,
        'artist': artist,
      });
    } on PlatformException catch (e) {
      _log.warning('Updating the widget failed', e);
    } on MissingPluginException {
      return;
    }
  }
}
