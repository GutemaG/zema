import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/preferences_provider.dart';
import 'album_grouping.dart';
import 'artist_grouping.dart';
import 'folder_tree.dart';
import 'library_providers.dart';

// Folders, albums and artists are grouped in memory from the visible
// tracks, so hidden folders and the minimum duration apply to them too.

final folderIndexProvider = Provider<AsyncValue<FolderIndex>>(
  (ref) => ref.watch(libraryTracksProvider).whenData(FolderIndex.from),
);

/// Albums in the chosen sort order.
final albumsProvider = Provider<AsyncValue<List<Album>>>((ref) {
  final sort = ref.watch(albumSortProvider);
  return ref
      .watch(libraryTracksProvider)
      .whenData((tracks) => sortAlbums(groupAlbums(tracks), sort));
});

final artistsProvider = Provider<AsyncValue<List<Artist>>>(
  (ref) => ref.watch(libraryTracksProvider).whenData(groupArtists),
);

/// The Albums sort, remembered across restarts.
final albumSortProvider = NotifierProvider<AlbumSortController, AlbumSort>(
  AlbumSortController.new,
);

class AlbumSortController extends Notifier<AlbumSort> {
  static const fieldKey = 'albumsSort';
  static const descendingKey = 'albumsSortDescending';

  @override
  AlbumSort build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final name = prefs.getString(fieldKey);
    final field = AlbumSortField.values.firstWhere(
      (f) => f.name == name,
      orElse: () => AlbumSort.initial.field,
    );
    return AlbumSort(field, descending: prefs.getBool(descendingKey) ?? false);
  }

  Future<void> set(AlbumSort sort) async {
    if (sort == state) return;
    state = sort;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(fieldKey, sort.field.name);
    await prefs.setBool(descendingKey, sort.descending);
  }
}
