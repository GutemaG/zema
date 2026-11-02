import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _log = Logger('contribute.share');

/// An audio file shared to Zema (from Telegram or any app), already copied
/// into Zema's own storage.
class SharedAudio {
  const SharedAudio({required this.path, required this.name, this.duration});

  /// Zema's copy.
  final String path;

  /// The file's name in the app it came from.
  final String name;
  final Duration? duration;
}

/// Audio files shared to Zema. Tests use a fake.
abstract interface class ShareReceiver {
  /// The file that started the app, once; null when there was none.
  Future<SharedAudio?> takeInitial();

  /// Files shared while the app runs.
  Stream<SharedAudio> get shares;
}

/// [ShareReceiver] for platforms with no share target (iOS).
class NoShareReceiver implements ShareReceiver {
  const NoShareReceiver();

  @override
  Future<SharedAudio?> takeInitial() async => null;

  @override
  Stream<SharedAudio> get shares => const Stream.empty();
}

/// [ShareReceiver] on Android, through `MainActivity`'s `ShareChannel`:
/// it copies an `audio/*` share into `files/shared_audio`, answers
/// `takeShared` with the one that started the app, and calls `shared` for
/// later ones.
class AndroidShareReceiver implements ShareReceiver {
  AndroidShareReceiver([this._channel = const MethodChannel(channelName)]) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'shared') {
        if (_read(call.arguments) case final audio?) _shares.add(audio);
      }
    });
  }

  static const channelName = 'zema/share';

  final MethodChannel _channel;
  final _shares = StreamController<SharedAudio>.broadcast();

  @override
  Future<SharedAudio?> takeInitial() async {
    try {
      return _read(await _channel.invokeMethod<Object?>('takeShared'));
    } on PlatformException catch (e) {
      _log.warning('Reading the shared file failed', e);
      return null;
    }
  }

  @override
  Stream<SharedAudio> get shares => _shares.stream;

  static SharedAudio? _read(Object? value) {
    if (value is! Map) return null;
    final path = value['path'];
    if (path is! String) return null;
    final ms = value['durationMs'];
    return SharedAudio(
      path: path,
      name: value['name'] as String? ?? path.split('/').last,
      duration: ms is int && ms > 0 ? Duration(milliseconds: ms) : null,
    );
  }
}

/// Deletes Zema's copy of a shared file at [path], if it is one (under a
/// `shared_audio` folder).
Future<void> deleteSharedAudio(String? path) async {
  if (path == null || !path.contains('/shared_audio/')) return;
  try {
    await File(path).delete();
  } on FileSystemException {
    // Already gone.
  }
}
