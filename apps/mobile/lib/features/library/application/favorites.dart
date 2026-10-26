import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../../shared/combine_async.dart';
import '../data/collections_repository.dart';
import 'library_providers.dart';

final _favoriteEntriesProvider = StreamProvider<List<FavoriteEntry>>(
  (ref) => ref.watch(collectionsRepositoryProvider).watchFavorites(),
);

/// IDs of every favorited track, for hearts.
final favoriteIdsProvider = Provider<Set<int>>(
  (ref) => {
    for (final entry
        in ref.watch(_favoriteEntriesProvider).value ?? <FavoriteEntry>[])
      entry.trackId,
  },
);

/// Whether the track with this ID is a favorite.
final isFavoriteProvider = Provider.family<bool, int>(
  (ref, trackId) => ref.watch(favoriteIdsProvider).contains(trackId),
);

/// The visible favorite tracks, newest first. Favorites of hidden or
/// missing songs are kept but not listed.
final favoritesProvider = Provider<AsyncValue<List<Track>>>(
  (ref) => combineAsync(
    ref.watch(_favoriteEntriesProvider),
    ref.watch(libraryTracksProvider),
    (entries, tracks) {
      final byId = {for (final t in tracks) t.id: t};
      return [for (final entry in entries) ?byId[entry.trackId]];
    },
  ),
);

final favoritesControllerProvider = Provider<FavoritesController>(
  (ref) => FavoritesController(ref.watch(collectionsRepositoryProvider)),
);

class FavoritesController {
  const FavoritesController(this._repository);

  final CollectionsRepository _repository;

  /// Favorites [trackId] when [favorite] is true, else unfavorites it.
  Future<void> set(int trackId, {required bool favorite}) async {
    if (favorite) {
      await _repository.addFavorite(trackId);
    } else {
      await _repository.removeFavorite(trackId);
    }
  }

  /// Favorites (or unfavorites) every track in [trackIds] at once.
  Future<void> setAll(List<int> trackIds, {required bool favorite}) => favorite
      ? _repository.addFavorites(trackIds)
      : _repository.removeFavorites(trackIds);

  /// Unfavorites [trackId]. Returns a function that restores it in the
  /// same place, or null if it wasn't a favorite.
  Future<Future<void> Function()?> remove(int trackId) =>
      _repository.removeFavorite(trackId);
}
