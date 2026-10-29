import 'package:flutter_riverpod/misc.dart';
import 'package:zema/app/backend/backend_providers.dart';
import 'package:zema/app/database/zema_database.dart';
import 'package:zema_core/zema_core.dart';

import 'bundled_lyrics_repository.dart';
import 'fake_catalog.dart';

/// The app's lyrics come from [catalog], by default one serving
/// [repository] (or the sample fixtures read from disk, fresh for each app)
/// as its index and song documents, filled by the app's start-up refresh
/// and downloaded on first use like the real catalog. Without
/// [backendConfigured] the build has no catalog at all.
List<Override> lyricsOverrides({
  LyricsRepository? repository,
  CatalogRepository? catalog,
  bool backendConfigured = true,
}) => [
  catalogRepositoryProvider.overrideWithValue(
    backendConfigured
        ? catalog ??
              FakeCatalogRepository(
                lyrics:
                    repository ?? BundledLyricsRepository(DiskAssetBundle()),
              )
        : null,
  ),
];

/// Saves every sample song in [db]'s lyrics cache, as if each had been
/// opened once (lyric-line search only covers cached songs).
Future<void> cacheSampleLyrics(ZemaDatabase db) async {
  final catalog = FakeCatalogRepository(
    lyrics: BundledLyricsRepository(DiskAssetBundle()),
  );
  for (final entry in await catalog.index()) {
    await db.cachedSongsDao.save(
      (await catalog.song(entry.id))!,
      entry.version,
    );
  }
}
