import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zema_core/zema_core.dart';

import '../../library/application/album_grouping.dart';
import '../../library/application/artist_grouping.dart';
import '../../library/application/library_groups.dart';
import '../../library/application/library_providers.dart';

/// One searchable thing and the text it is found by.
class _Entry<T> {
  _Entry(this.item, String text) : key = SearchKey(text);

  final T item;
  final SearchKey key;
}

/// The library prepared for searching: a [SearchKey] per song (its title),
/// artist (name) and album (name and artist). Built once per library
/// change, not per keystroke.
class LibrarySearchIndex {
  LibrarySearchIndex({
    required List<Track> tracks,
    required List<Artist> artists,
    required List<Album> albums,
  }) : _songs = [for (final t in tracks) _Entry(t, t.title)],
       _artists = [
         for (final a in artists)
           if (a.name case final name?) _Entry(a, name),
       ],
       _albums = [
         for (final a in albums)
           if (a.id.title case final title?)
             _Entry(a, '$title ${a.artist ?? ''}'),
       ];

  final List<_Entry<Track>> _songs;
  final List<_Entry<Artist>> _artists;
  final List<_Entry<Album>> _albums;

  /// Everything matching [query], best first in each group. An empty query
  /// finds nothing.
  SearchResults search(String query) {
    final key = SearchKey(query);
    if (key.isEmpty) return const SearchResults.empty();
    final text = key.words.join(' ');
    return SearchResults(
      songs: _rank(_songs, key, text),
      artists: _rank(_artists, key, text),
      albums: _rank(_albums, key, text),
    );
  }

  /// Matches ordered by score, then by whether the text itself contains the
  /// query (a title with the typed word comes before a different word with
  /// the same consonants), then by library order.
  static List<T> _rank<T>(List<_Entry<T>> entries, SearchKey key, String text) {
    final hits = <(int, double, bool)>[];
    for (final (i, entry) in entries.indexed) {
      final score = matchScore(key, entry.key);
      if (score < matchThreshold) continue;
      hits.add((i, score, entry.key.words.join(' ').contains(text)));
    }
    hits.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      if (byScore != 0) return byScore;
      if (a.$3 != b.$3) return a.$3 ? -1 : 1;
      return a.$1.compareTo(b.$1);
    });
    return [for (final (i, _, _) in hits) entries[i].item];
  }
}

/// What a search found, by group.
class SearchResults {
  const SearchResults({
    required this.songs,
    required this.artists,
    required this.albums,
  });

  const SearchResults.empty()
    : songs = const [],
      artists = const [],
      albums = const [];

  final List<Track> songs;
  final List<Artist> artists;
  final List<Album> albums;

  bool get isEmpty => songs.isEmpty && artists.isEmpty && albums.isEmpty;
}

/// The index of the visible library; null until the library has loaded.
final librarySearchIndexProvider = Provider<LibrarySearchIndex?>((ref) {
  final tracks = ref.watch(libraryTracksProvider).value;
  final artists = ref.watch(artistsProvider).value;
  final albums = ref.watch(albumsProvider).value;
  if (tracks == null || artists == null || albums == null) return null;
  return LibrarySearchIndex(tracks: tracks, artists: artists, albums: albums);
});
