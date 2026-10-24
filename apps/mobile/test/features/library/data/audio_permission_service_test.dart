import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zema/features/library/data/audio_permission_service.dart';
import 'package:zema/features/library/data/media_store_library_scanner.dart';

const _library = MethodChannel(MediaStoreLibraryScanner.channelName);
const _permissions = MethodChannel('flutter.baseflow.com/permissions/methods');

/// permission_handler's wire values for [PermissionStatus].
const _wire = {
  PermissionStatus.denied: 0,
  PermissionStatus.granted: 1,
  PermissionStatus.restricted: 2,
  PermissionStatus.limited: 3,
  PermissionStatus.permanentlyDenied: 4,
  PermissionStatus.provisional: 5,
};

/// Fakes the Android version and the permission plugin. Returns the
/// permission values the plugin was asked about.
List<int> _fakePlatform({
  required int? sdk,
  PermissionStatus status = PermissionStatus.denied,
  PermissionStatus requestResult = PermissionStatus.granted,
}) {
  final asked = <int>[];
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_library, (call) async {
    if (sdk == null) throw PlatformException(code: 'unavailable');
    return sdk;
  });
  messenger.setMockMethodCallHandler(_permissions, (call) async {
    switch (call.method) {
      case 'checkPermissionStatus':
        asked.add(call.arguments as int);
        return _wire[status];
      case 'requestPermissions':
        final requested = (call.arguments as List<Object?>).cast<int>();
        asked.addAll(requested);
        return {for (final p in requested) p: _wire[requestResult]};
      case 'openAppSettings':
        return true;
    }
    return null;
  });
  addTearDown(() {
    messenger.setMockMethodCallHandler(_library, null);
    messenger.setMockMethodCallHandler(_permissions, null);
  });
  return asked;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AndroidAudioPermissionService', () {
    test('uses READ_MEDIA_AUDIO on Android 13 and newer', () async {
      final asked = _fakePlatform(sdk: 34);

      await AndroidAudioPermissionService().status();

      expect(asked, [Permission.audio.value]);
    });

    test('uses storage access on Android 12 and older', () async {
      final asked = _fakePlatform(sdk: 32);

      await AndroidAudioPermissionService().status();

      expect(asked, [Permission.storage.value]);
    });

    test('assumes a new Android when the version is unknown', () async {
      final asked = _fakePlatform(sdk: null);

      await AndroidAudioPermissionService().status();

      expect(asked, [Permission.audio.value]);
    });

    test('maps every permission status', () async {
      const expected = {
        PermissionStatus.granted: AudioAccess.granted,
        PermissionStatus.limited: AudioAccess.granted,
        PermissionStatus.denied: AudioAccess.denied,
        PermissionStatus.provisional: AudioAccess.denied,
        PermissionStatus.permanentlyDenied: AudioAccess.permanentlyDenied,
        PermissionStatus.restricted: AudioAccess.permanentlyDenied,
      };
      for (final MapEntry(key: status, value: access) in expected.entries) {
        _fakePlatform(sdk: 34, status: status);

        expect(
          await AndroidAudioPermissionService().status(),
          access,
          reason: '$status',
        );
      }
    });

    test('returns the answer of the system dialog', () async {
      final asked = _fakePlatform(
        sdk: 34,
        requestResult: PermissionStatus.permanentlyDenied,
      );

      final access = await AndroidAudioPermissionService().request();

      expect(access, AudioAccess.permanentlyDenied);
      expect(asked, [Permission.audio.value]);
    });
  });

  group('UnsupportedAudioPermissionService', () {
    test('always reports unsupported', () async {
      const service = UnsupportedAudioPermissionService();

      expect(await service.status(), AudioAccess.unsupported);
      expect(await service.request(), AudioAccess.unsupported);
      await service.openSettings();
    });
  });
}
