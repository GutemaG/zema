import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

import 'media_store_library_scanner.dart';

final _log = Logger('library.permission');

/// Where the app stands with access to the phone's audio files.
enum AudioAccess {
  granted,

  /// Not granted; asking again shows the system dialog.
  denied,

  /// Not granted, and the system won't show the dialog any more: only the
  /// app's system settings can grant it.
  permanentlyDenied,

  /// This platform has no library access (iOS for now).
  unsupported,
}

/// Checks and requests access to audio files.
abstract interface class AudioPermissionService {
  Future<AudioAccess> status();

  /// Shows the system dialog when the system allows it.
  Future<AudioAccess> request();

  /// Opens the app's page in the system settings.
  Future<void> openSettings();
}

/// Android: `READ_MEDIA_AUDIO` on Android 13 and newer, storage access on
/// Android 12 and older.
class AndroidAudioPermissionService implements AudioPermissionService {
  AndroidAudioPermissionService([
    this._channel = const MethodChannel(MediaStoreLibraryScanner.channelName),
  ]);

  final MethodChannel _channel;
  Permission? _permission;

  Future<Permission> _audioPermission() async {
    if (_permission case final permission?) return permission;
    var sdk = 33;
    try {
      sdk = await _channel.invokeMethod<int>('sdkInt') ?? sdk;
    } on PlatformException catch (e) {
      _log.warning('Could not read the Android version', e);
    }
    return _permission = sdk >= 33 ? Permission.audio : Permission.storage;
  }

  @override
  Future<AudioAccess> status() async =>
      _map(await (await _audioPermission()).status);

  @override
  Future<AudioAccess> request() async =>
      _map(await (await _audioPermission()).request());

  @override
  Future<void> openSettings() async {
    if (!await openAppSettings()) {
      _log.warning('Could not open the app settings');
    }
  }

  static AudioAccess _map(PermissionStatus status) => switch (status) {
    PermissionStatus.granted || PermissionStatus.limited => AudioAccess.granted,
    PermissionStatus.permanentlyDenied ||
    PermissionStatus.restricted => AudioAccess.permanentlyDenied,
    PermissionStatus.denied ||
    PermissionStatus.provisional => AudioAccess.denied,
  };
}

/// Platforms without library access.
class UnsupportedAudioPermissionService implements AudioPermissionService {
  const UnsupportedAudioPermissionService();

  @override
  Future<AudioAccess> status() async => AudioAccess.unsupported;

  @override
  Future<AudioAccess> request() async => AudioAccess.unsupported;

  @override
  Future<void> openSettings() async {}
}
