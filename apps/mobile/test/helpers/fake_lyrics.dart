import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:zema/features/lyrics/data/bundled_lyrics_repository.dart';

/// Reads assets straight from the project folder, so the bundled lyrics
/// load without real asset I/O, which stalls under the test clock.
class DiskAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(File(key).readAsBytesSync());

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      File(key).readAsStringSync();
}

/// The bundled sample lyrics, read from disk, fresh for each app.
List<Override> lyricsOverrides() => [
  lyricsRepositoryProvider.overrideWithValue(
    BundledLyricsRepository(DiskAssetBundle()),
  ),
];
