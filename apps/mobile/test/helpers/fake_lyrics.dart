import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:zema/features/lyrics/data/bundled_lyrics_repository.dart';
import 'package:zema_core/zema_core.dart';

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

/// [repository], or by default the bundled sample lyrics read from disk,
/// fresh for each app.
List<Override> lyricsOverrides({LyricsRepository? repository}) => [
  lyricsRepositoryProvider.overrideWithValue(
    repository ?? BundledLyricsRepository(DiskAssetBundle()),
  ),
];
