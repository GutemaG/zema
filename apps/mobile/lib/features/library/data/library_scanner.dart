import 'dart:typed_data';

import 'package:zema_core/zema_core.dart';

/// Reads the device's audio files. The only way app code reaches the
/// platform's media index; everything else works with [ScannedAudio].
///
/// Implementations throw [PermissionFailure] when audio access is missing and
/// [ScanFailure] for any other platform error.
abstract interface class LibraryScanner {
  /// Whether this platform can scan at all (false on iOS for now).
  bool get isSupported;

  /// Every audio file in the media index, unfiltered.
  Future<List<ScannedAudio>> scan();

  /// Album art for the file with [mediaStoreId], as encoded image bytes at
  /// roughly [size]×[size] pixels, or null when the file has none.
  Future<Uint8List?> loadArtwork(int mediaStoreId, {int size = 200});
}

/// Used where the platform has no library access (iOS until a later intent).
class UnsupportedLibraryScanner implements LibraryScanner {
  const UnsupportedLibraryScanner();

  @override
  bool get isSupported => false;

  @override
  Future<List<ScannedAudio>> scan() async =>
      throw const ScanFailure('Library scanning is not supported here');

  @override
  Future<Uint8List?> loadArtwork(int mediaStoreId, {int size = 200}) async =>
      null;
}
