import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../shared/combine_async.dart';
import '../data/collections_repository.dart';
import 'album_grouping.dart';
import 'library_providers.dart';

/// A user playlist with its visible songs.
class Playlist {
  Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.tracks,
    required this.storedIds,
  });

  /// Joins [stored] with the visible tracks ([byId]); hidden and missing
  /// songs are left out of [tracks] but stay in [storedIds].
  factory Playlist.of(StoredPlaylist stored, Map<int, Track> byId) => Playlist(
    id: stored.id,
    name: stored.name,
    description: stored.description,
    tracks: [for (final id in stored.trackIds) ?byId[id]],
    storedIds: stored.trackIds,
  );

  final int id;
  final String name;
  final String? description;

  /// Visible songs in playlist order.
  final List<Track> tracks;

  /// Every song in the playlist, hidden and missing ones included.
  final List<int> storedIds;

  late final Set<int> _stored = storedIds.toSet();

  /// Whether [trackId] is in the playlist (even if hidden).
  bool contains(int trackId) => _stored.contains(trackId);

  Duration get duration =>
      tracks.fold(Duration.zero, (sum, t) => sum + t.duration);

  /// The songs whose art makes the cover: the first song of each of the
  /// first four albums when there are four, otherwise just the first song.
  /// Empty for an empty playlist.
  List<Track> get covers {
    final albums = <AlbumId>{};
    final firsts = [
      for (final t in tracks)
        if (albums.add(AlbumId.of(t))) t,
    ];
    return firsts.length >= 4 ? firsts.sublist(0, 4) : firsts.take(1).toList();
  }
}

final _storedPlaylistsProvider = StreamProvider<List<StoredPlaylist>>(
  (ref) => ref.watch(collectionsRepositoryProvider).watchPlaylists(),
);

/// User playlists by name.
final playlistsProvider = Provider<AsyncValue<List<Playlist>>>(
  (ref) => combineAsync(
    ref.watch(_storedPlaylistsProvider),
    ref.watch(libraryTracksProvider),
    (stored, tracks) {
      final byId = {for (final t in tracks) t.id: t};
      return [for (final p in stored) Playlist.of(p, byId)]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    },
  ),
);

/// The playlist with this ID; null once it no longer exists.
final playlistProvider = Provider.family<AsyncValue<Playlist?>, int>(
  (ref, id) => ref
      .watch(playlistsProvider)
      .whenData((all) => all.where((p) => p.id == id).firstOrNull),
);

/// Why a playlist name can't be saved.
enum PlaylistNameProblem { empty, duplicate }

/// Checks [name] against [playlists], ignoring the playlist being renamed
/// ([editing]). Null when the name can be saved.
PlaylistNameProblem? checkPlaylistName(
  String name,
  Iterable<Playlist> playlists, {
  int? editing,
}) {
  final key = playlistNameKey(name);
  if (key.isEmpty) return PlaylistNameProblem.empty;
  final taken = playlists.any(
    (p) => p.id != editing && playlistNameKey(p.name) == key,
  );
  return taken ? PlaylistNameProblem.duplicate : null;
}

final playlistsControllerProvider = Provider<PlaylistsController>(
  (ref) => PlaylistsController(ref.watch(collectionsRepositoryProvider)),
);

class PlaylistsController {
  const PlaylistsController(this._repository);

  final CollectionsRepository _repository;

  /// Creates a playlist and returns its ID. Throws [DuplicateNameFailure]
  /// when the name is taken.
  Future<int> create(String name, {String? description}) =>
      _repository.createPlaylist(name, description: description);

  /// Throws [DuplicateNameFailure] when the name is taken.
  Future<void> rename(int id, String name, {String? description}) =>
      _repository.renamePlaylist(id, name, description: description);

  Future<void> delete(int id) => _repository.deletePlaylist(id);

  /// Adds [trackIds] to the end, skipping songs already in the playlist.
  /// Returns how many were added.
  Future<int> add(int id, List<int> trackIds) =>
      _repository.addToPlaylist(id, trackIds);

  /// Removes [trackId]. Returns a function that puts it back in place, or
  /// null if it wasn't in the playlist.
  Future<Future<void> Function()?> remove(int id, int trackId) =>
      _repository.removeFromPlaylist(id, trackId);

  /// Saves the order of [playlist]'s visible songs as [visibleOrder] (track
  /// IDs). Hidden songs keep their slots.
  Future<void> reorder(Playlist playlist, List<int> visibleOrder) =>
      _repository.setPlaylistOrder(
        playlist.id,
        applyVisibleOrder(playlist.storedIds, visibleOrder),
      );

  /// Adds [trackId] to [playlist], or removes it if it's already there.
  Future<void> toggle(Playlist playlist, int trackId) async {
    if (playlist.contains(trackId)) {
      await _repository.removeFromPlaylist(playlist.id, trackId);
    } else {
      await _repository.addToPlaylist(playlist.id, [trackId]);
    }
  }
}
