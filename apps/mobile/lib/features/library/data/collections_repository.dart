import 'package:zema_core/zema_core.dart';

import '../../../app/database/collections_dao.dart';

export '../../../app/database/collections_dao.dart' show StoredPlaylist;

/// A favorited song and when it was favorited.
typedef FavoriteEntry = ({int trackId, DateTime addedAt});

/// Favorites and playlists. Store failures surface as [DatabaseFailure];
/// a taken playlist name as [DuplicateNameFailure].
class CollectionsRepository {
  CollectionsRepository(this._dao);

  final CollectionsDao _dao;

  /// Every favorite, newest first.
  Stream<List<FavoriteEntry>> watchFavorites() => _dao.watchFavorites().map(
    (rows) => [
      for (final row in rows) (trackId: row.trackId, addedAt: row.addedAt),
    ],
  );

  Future<void> addFavorite(int trackId) => _guard(_dao.addFavorite(trackId));

  Future<void> addFavorites(List<int> trackIds) =>
      _guard(_dao.addFavorites(trackIds));

  Future<void> removeFavorites(List<int> trackIds) =>
      _guard(_dao.removeFavorites(trackIds));

  /// Removes [trackId] from favorites. Returns a function that puts it back
  /// in the same place, or null if it wasn't a favorite.
  Future<Future<void> Function()?> removeFavorite(int trackId) async {
    final row = await _guard(_dao.removeFavorite(trackId));
    if (row == null) return null;
    return () => _guard(_dao.restoreFavorite(row));
  }

  /// Every playlist with all its stored entries, by ID.
  Stream<List<StoredPlaylist>> watchPlaylists() => _dao.watchPlaylists();

  Future<int> createPlaylist(String name, {String? description}) =>
      _guard(_dao.createPlaylist(name, description: description));

  Future<void> renamePlaylist(int id, String name, {String? description}) =>
      _guard(_dao.renamePlaylist(id, name, description: description));

  Future<void> deletePlaylist(int id) => _guard(_dao.deletePlaylist(id));

  /// Adds [trackIds] to the end of playlist [id], skipping songs already in
  /// it. Returns how many were added.
  Future<int> addToPlaylist(int id, List<int> trackIds) =>
      _guard(_dao.addToPlaylist(id, trackIds));

  /// Removes [trackId] from playlist [id]. Returns a function that puts it
  /// back at the same place, or null if it wasn't there.
  Future<Future<void> Function()?> removeFromPlaylist(
    int id,
    int trackId,
  ) async {
    final index = await _guard(_dao.removeFromPlaylist(id, trackId));
    if (index == null) return null;
    return () => _guard(_dao.insertIntoPlaylist(id, trackId, index));
  }

  Future<void> setPlaylistOrder(int id, List<int> trackIds) =>
      _guard(_dao.setPlaylistOrder(id, trackIds));

  Future<T> _guard<T>(Future<T> operation) async {
    try {
      return await operation;
    } on ZemaFailure {
      rethrow;
    } catch (e) {
      throw DatabaseFailure('Saving favorites or playlists failed', cause: e);
    }
  }
}
