import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/features/library/data/audio_share_service.dart';
import 'package:zema/features/library/data/media_store_library_scanner.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';

const _library = MethodChannel(MediaStoreLibraryScanner.channelName);

final _track = Track.fromScan(1, scannedAudio(42, '/m/ቅዱስ.mp3', title: 'ቅዱስ'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(_library, null));

  test('Android shares the content URI and title', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(_library, (call) async {
      calls.add(call);
      return null;
    });

    expect(await const AndroidAudioShareService().share(_track), isTrue);

    expect(calls.single.method, 'share');
    expect(calls.single.arguments, {
      'uri': 'content://media/external/audio/media/42',
      'title': 'ቅዱስ',
    });
  });

  test('a failure to open the share sheet returns false', () async {
    messenger.setMockMethodCallHandler(_library, (call) async {
      throw PlatformException(code: 'share_failed');
    });

    expect(await const AndroidAudioShareService().share(_track), isFalse);
  });

  test('elsewhere sharing is unsupported', () async {
    const service = UnsupportedAudioShareService();
    expect(service.isSupported, isFalse);
    expect(await service.share(_track), isFalse);
  });
}
