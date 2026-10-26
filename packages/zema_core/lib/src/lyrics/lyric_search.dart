import '../search/transliteration.dart';
import 'lyrics_models.dart';

/// A song found by one of its lines.
class LyricMatch {
  const LyricMatch(this.song, this.line, this.score);

  final Song song;

  /// The song's best-matching line.
  final LyricLine line;
  final double score;

  @override
  String toString() => 'LyricMatch(${song.id}: ${line.text})';
}

/// Finds songs by a line of their lyrics, in either script.
///
/// Built once per song list: each distinct line (with its transliteration)
/// gets one [SearchKey], so a search only scores keys.
class LyricLineIndex {
  LyricLineIndex(List<Song> songs)
    : _entries = [
        for (final song in songs)
          for (final line in _distinctLines(song))
            (
              song,
              line,
              SearchKey([line.text, ?line.transliteration].join(' ')),
            ),
      ];

  final List<(Song, LyricLine, SearchKey)> _entries;

  /// Songs with a line matching [query], each once with its best line,
  /// best first, then in the given order.
  List<LyricMatch> search(String query) {
    final key = SearchKey(query);
    if (key.isEmpty) return const [];
    final best = <String, LyricMatch>{};
    final order = <String, int>{};
    for (final (song, line, lineKey) in _entries) {
      order.putIfAbsent(song.id, () => order.length);
      final score = matchScore(key, lineKey);
      if (score < matchThreshold) continue;
      final current = best[song.id];
      if (current == null || score > current.score) {
        best[song.id] = LyricMatch(song, line, score);
      }
    }
    return best.values.toList()..sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0
          ? byScore
          : order[a.song.id]!.compareTo(order[b.song.id]!);
    });
  }

  static Iterable<LyricLine> _distinctLines(Song song) {
    final seen = <String>{};
    return [
      for (final section in song.sections)
        for (final line in section.lines)
          if (seen.add(line.text)) line,
    ];
  }
}
