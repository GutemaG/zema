import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../../catalog/application/catalog_index.dart';
import '../../library/application/library_providers.dart';
import '../data/bundled_lyrics_repository.dart';
import '../data/lyrics_links_repository.dart';

final _log = Logger('lyrics.links');

final lyricsLinksRepositoryProvider = Provider<LyricsLinksRepository>(
  (ref) => LyricsLinksRepository(ref.watch(databaseProvider).lyricsLinksDao),
);

/// Every lyrics song, in the repository's order.
final lyricsSongsProvider = FutureProvider<List<Song>>(
  (ref) => ref.watch(lyricsRepositoryProvider).songs(),
);

final _linksProvider = StreamProvider<Map<int, LyricsLink>>(
  (ref) => ref.watch(lyricsLinksRepositoryProvider).watchLinks(),
);

/// Links every track without a manual choice to the catalog song its title
/// matches (see [SongMatcher]), whenever the library or the song index
/// change. Works offline from the saved index. Kept alive by the app shell.
final lyricsLinkSyncProvider = Provider<void>((ref) {
  final tracks = ref.watch(libraryTracksProvider).value;
  final songs = ref.watch(catalogEntriesProvider).value;
  if (tracks == null || songs == null) return;
  final matcher = SongMatcher(songs);
  final links = <int, String>{
    for (final track in tracks)
      if (matcher.match(track) case final song?) track.id: song.id,
  };
  unawaited(
    ref
        .read(lyricsLinksRepositoryProvider)
        .replaceAutomatic(links)
        .catchError(
          (Object e) => _log.warning('Could not save lyrics links', e),
          test: (e) => e is ZemaFailure,
        ),
  );
});

/// The lyrics song [trackId] is linked to, or null. A link to a song that
/// is no longer in the catalog's index (or has no lyrics here) counts as
/// none.
final trackSongProvider = Provider.family<AsyncValue<Song?>, int>((
  ref,
  trackId,
) {
  final links = ref.watch(_linksProvider);
  final index = ref.watch(catalogEntriesProvider);
  final songs = ref.watch(lyricsSongsProvider);
  return switch ((links, index, songs)) {
    (
      AsyncData(value: final links),
      AsyncData(value: final index),
      AsyncData(value: final songs),
    ) =>
      AsyncData(switch (links[trackId]?.songId) {
        final id? when index.any((e) => e.id == id) =>
          songs.where((s) => s.id == id).firstOrNull,
        _ => null,
      }),
    (AsyncError(:final error, :final stackTrace), _, _) ||
    (_, AsyncError(:final error, :final stackTrace), _) ||
    (
      _,
      _,
      AsyncError(:final error, :final stackTrace),
    ) => AsyncError(error, stackTrace),
    _ => const AsyncLoading(),
  };
});

final lyricsLinksControllerProvider = Provider<LyricsLinksController>(
  (ref) => LyricsLinksController(ref.watch(lyricsLinksRepositoryProvider)),
);

/// The user's choices about a track's lyrics.
class LyricsLinksController {
  const LyricsLinksController(this._links);

  final LyricsLinksRepository _links;

  /// Links [track] to [song]; automatic matching won't change it.
  Future<void> link(Track track, SongIdentity song) =>
      _links.setManual(track.id, song.id);

  /// Marks [track] as having no lyrics; automatic matching won't link it.
  Future<void> unlink(Track track) => _links.setManual(track.id, null);
}

/// The library's tracks linked to the song [songId], in library order.
final songTracksProvider = Provider.family<List<Track>, String>((ref, songId) {
  final links = ref.watch(_linksProvider).value ?? const {};
  final tracks = ref.watch(libraryTracksProvider).value ?? const <Track>[];
  return [
    for (final track in tracks)
      if (links[track.id]?.songId == songId) track,
  ];
});

/// The recordings of the song [songId].
final songRecordingsProvider = FutureProvider.family<List<Recording>, String>(
  (ref, songId) => ref.watch(lyricsRepositoryProvider).recordings(songId),
);

/// Finds songs by a lyric line; built once per song list.
final lyricsSearchIndexProvider = Provider<LyricLineIndex?>((ref) {
  final songs = ref.watch(lyricsSongsProvider).value;
  return songs == null ? null : LyricLineIndex(songs);
});
