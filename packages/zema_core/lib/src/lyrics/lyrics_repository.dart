import '../search/transliteration.dart';
import 'lyrics_models.dart';

/// Where lyrics come from: bundled samples now, the cloud catalog later.
///
/// Implementations throw a `ZemaFailure` when they can't read their source,
/// never a raw platform error.
abstract interface class LyricsRepository {
  /// Every song, in a stable order.
  Future<List<Song>> songs();

  /// The song with [id], or null.
  Future<Song?> song(String id);

  /// The recordings of the song [songId].
  Future<List<Recording>> recordings(String songId);

  /// The timing of the recording [recordingId], or null when it has none
  /// (plain lyrics).
  Future<SyncTiming?> timing(String recordingId);

  /// Songs whose title, transliteration or artist matches [query], best
  /// first.
  Future<List<Song>> search(String query);
}

/// The text a song is found by in [LyricsRepository.search].
SearchKey songSearchKey(Song song) =>
    SearchKey([song.title, ?song.transliteration, ?song.artist].join(' '));

/// [songs] matching [query], best first, then in their given order.
List<Song> searchSongs(List<Song> songs, String query) {
  final key = SearchKey(query);
  if (key.isEmpty) return const [];
  final scored =
      [
        for (final (i, song) in songs.indexed)
          (i, song, matchScore(key, songSearchKey(song))),
      ].where((e) => e.$3 >= matchThreshold).toList()..sort((a, b) {
        final byScore = b.$3.compareTo(a.$3);
        return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
      });
  return [for (final (_, song, _) in scored) song];
}
