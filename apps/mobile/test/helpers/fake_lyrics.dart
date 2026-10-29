import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:zema/app/backend/backend_providers.dart';
import 'package:zema/features/lyrics/data/bundled_lyrics_repository.dart';
import 'package:zema_core/zema_core.dart';

import 'fake_catalog.dart';

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
/// fresh for each app; and [catalog], by default one whose index lists the
/// same songs (filled by the app's start-up refresh). Without
/// [backendConfigured] the build has no catalog at all.
List<Override> lyricsOverrides({
  LyricsRepository? repository,
  CatalogRepository? catalog,
  bool backendConfigured = true,
}) {
  final lyrics = repository ?? BundledLyricsRepository(DiskAssetBundle());
  return [
    lyricsRepositoryProvider.overrideWithValue(lyrics),
    catalogRepositoryProvider.overrideWithValue(
      backendConfigured
          ? catalog ?? FakeCatalogRepository(lyrics: lyrics)
          : null,
    ),
  ];
}
