import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:zema_core/zema_core.dart';

import '../../../app/database/database_provider.dart';
import '../../catalog/application/catalog_index.dart';
import '../../catalog/data/catalog_lyrics_repository.dart';
import '../../identify/application/track_sound_links.dart';
import '../../library/application/library_providers.dart';
import '../data/lyrics_links_repository.dart';

final _log = Logger('lyrics.links');

final lyricsLinksRepositoryProvider = Provider<LyricsLinksRepository>(
  (ref) => LyricsLinksRepository(ref.watch(databaseProvider).lyricsLinksDao),
);

/// The songs whose lyrics are on the phone, by ID (searched by line until
/// the catalog's search joins in). Updates as songs are downloaded.
final lyricsSongsProvider = StreamProvider<List<Song>>((ref) {
  final index = ref.watch(catalogEntriesProvider).value;
  if (index == null) return const Stream.empty();
  final listed = {for (final e in index) e.id};
  return ref
      .watch(databaseProvider)
      .cachedSongsDao
      .watchSongs()
      .map(
        (cached) => [
          for (final c in cached)
            if (listed.contains(c.document.song.id)) c.document.song,
        ],
      );
});

/// The catalog song [songId] with its lyrics, downloaded on first use, or
/// null when the catalog doesn't list it. Fetched again when the index
/// shows a new version. Fails (usually with a [NetworkFailure]) when the
/// song isn't on the phone and can't be downloaded; invalidate to retry.
final songProvider = FutureProvider.family<Song?, String>((ref, songId) async {
  final entry = switch (ref.watch(
    catalogEntriesProvider.select(
      (index) => index.whenData(
        (entries) => entries.where((e) => e.id == songId).firstOrNull,
      ),
    ),
  )) {
    AsyncData(:final value) => value,
    AsyncError(:final error, :final stackTrace) => Error.throwWithStackTrace(
      error,
      stackTrace,
    ),
    // Rebuilt when the index loads.
    _ => await Completer<CatalogEntry?>().future,
  };
  if (entry == null) return null;
  return ref.watch(lyricsRepositoryProvider).song(songId);
}, retry: (_, _) => null);

/// Every track's link, by track ID.
final lyricsLinksProvider = StreamProvider<Map<int, LyricsLink>>(
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

/// The lyrics song [trackId] is linked to, or null: the user's choice, else
/// what its sound matched, else what its title matched. A link to a song
/// that is no longer in the catalog's index counts as none.
final trackSongProvider = Provider.family<AsyncValue<Song?>, int>((
  ref,
  trackId,
) {
  return switch (ref.watch(lyricsLinksProvider)) {
    AsyncData(value: final links) => switch (ref
            .watch(trackSoundMatchProvider(trackId))
            ?.songId ??
        links[trackId]?.songId) {
      final id? => ref.watch(songProvider(id)),
      null => const AsyncData(null),
    },
    AsyncError(:final error, :final stackTrace) => AsyncError(
      error,
      stackTrace,
    ),
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
  final links = ref.watch(lyricsLinksProvider).value ?? const {};
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
