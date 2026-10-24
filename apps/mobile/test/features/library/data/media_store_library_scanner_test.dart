import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/features/library/data/library_scanner.dart';
import 'package:zema/features/library/data/media_store_library_scanner.dart';
import 'package:zema_core/zema_core.dart';

const _channel = MethodChannel(MediaStoreLibraryScanner.channelName);

/// Answers channel calls with [handler] for this test.
void _onCall(Future<Object?> Function(MethodCall call) handler) {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_channel, handler);
  addTearDown(() => messenger.setMockMethodCallHandler(_channel, null));
}

Map<String, Object?> _row({
  int id = 7,
  String? title = 'ሰላም ለኪ',
  String? artist = 'ዘማሪት ዘርፌ ከበደ',
  String? album = 'Mezmur Vol. 1',
  Object? track = 3,
  Object? year = 2019,
}) => {
  'id': id,
  'uri': 'content://media/external/audio/media/$id',
  'path': '/storage/emulated/0/Music/Zema Test/03 Selam.mp3',
  'displayName': '03 Selam.mp3',
  'title': title,
  'artist': artist,
  'album': album,
  'albumArtist': null,
  'track': track,
  'year': year,
  'durationMs': 48039,
  'sizeBytes': 774000,
  'dateAddedSeconds': 1761300000,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MediaStoreLibraryScanner', () {
    test('maps every field of a row', () async {
      _onCall((call) async => [_row()]);

      final audio = (await const MediaStoreLibraryScanner().scan()).single;

      expect(audio.mediaStoreId, 7);
      expect(audio.uri, 'content://media/external/audio/media/7');
      expect(audio.path, '/storage/emulated/0/Music/Zema Test/03 Selam.mp3');
      expect(audio.displayName, '03 Selam.mp3');
      expect(audio.title, 'ሰላም ለኪ');
      expect(audio.artist, 'ዘማሪት ዘርፌ ከበደ');
      expect(audio.album, 'Mezmur Vol. 1');
      expect(audio.albumArtist, isNull);
      expect(audio.trackNumber, 3);
      expect(audio.year, 2019);
      expect(audio.duration, const Duration(milliseconds: 48039));
      expect(audio.sizeBytes, 774000);
      expect(
        audio.dateAdded,
        DateTime.fromMillisecondsSinceEpoch(1761300000000, isUtc: true),
      );
    });

    test("turns MediaStore's <unknown> and blank tags into no tag", () async {
      _onCall(
        (call) async => [_row(title: '  ', artist: '<unknown>', album: '')],
      );

      final audio = (await const MediaStoreLibraryScanner().scan()).single;

      expect(audio.title, isNull);
      expect(audio.artist, isNull);
      expect(audio.album, isNull);
      expect(resolveTitle(audio), '03 Selam');
    });

    test('accepts numbers of any width and missing numbers', () async {
      _onCall((call) async => [_row(track: 3.0, year: null)]);

      final audio = (await const MediaStoreLibraryScanner().scan()).single;

      expect(audio.trackNumber, 3);
      expect(audio.year, isNull);
    });

    test('returns an empty list for an empty or missing result', () async {
      _onCall((call) async => null);

      expect(await const MediaStoreLibraryScanner().scan(), isEmpty);
    });

    test('maps permission_denied to PermissionFailure', () async {
      _onCall(
        (call) async => throw PlatformException(code: 'permission_denied'),
      );

      expect(
        const MediaStoreLibraryScanner().scan(),
        throwsA(isA<PermissionFailure>()),
      );
    });

    test('maps other platform errors to ScanFailure', () async {
      _onCall((call) async => throw PlatformException(code: 'scan_failed'));

      expect(
        const MediaStoreLibraryScanner().scan(),
        throwsA(isA<ScanFailure>()),
      );
    });

    test('maps a missing channel to ScanFailure', () async {
      // No handler registered: the channel is not there.
      expect(
        const MediaStoreLibraryScanner().scan(),
        throwsA(isA<ScanFailure>()),
      );
    });

    test('asks for artwork by id and size', () async {
      MethodCall? received;
      _onCall((call) async {
        received = call;
        return Uint8List.fromList([1, 2, 3]);
      });

      final bytes = await const MediaStoreLibraryScanner().loadArtwork(
        7,
        size: 120,
      );

      expect(bytes, [1, 2, 3]);
      expect(received?.method, 'loadArtwork');
      expect(received?.arguments, {'id': 7, 'size': 120});
    });
  });

  group('UnsupportedLibraryScanner', () {
    test('is not supported, fails to scan and has no artwork', () async {
      const scanner = UnsupportedLibraryScanner();

      expect(scanner.isSupported, isFalse);
      expect(scanner.scan(), throwsA(isA<ScanFailure>()));
      expect(await scanner.loadArtwork(1), isNull);
    });
  });
}
