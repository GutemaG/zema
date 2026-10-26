import 'dart:math';

import '../library/track.dart';
import '../search/transliteration.dart';
import 'lyrics_models.dart';

/// The score a track's title must reach to link to a song automatically.
const double autoLinkThreshold = 0.9;

/// Songs prepared for matching against many tracks; build once per lyrics
/// change.
class SongMatcher {
  SongMatcher(List<Song> songs)
    : _songs = [
        for (final song in songs)
          (
            song,
            [
              SearchKey(song.title),
              if (song.transliteration case final t?) SearchKey(t),
            ],
            song.artist == null ? null : SearchKey(song.artist!),
          ),
      ];

  final List<(Song, List<SearchKey>, SearchKey?)> _songs;

  /// The song [track] is, or null when none matches well enough or two
  /// match equally well.
  ///
  /// The song's title (or transliteration) must be found in the track's
  /// title, so noise around it ("… - Official Video") doesn't matter. The
  /// artist only breaks ties between equal titles.
  Song? match(Track track) {
    final title = SearchKey(track.title);
    if (title.isEmpty) return null;
    final artist = track.artist == null ? null : SearchKey(track.artist!);
    Song? best;
    var bestScore = 0.0;
    var tie = false;
    for (final (song, keys, songArtist) in _songs) {
      final titleScore = keys.map((k) => matchScore(k, title)).reduce(max);
      if (titleScore < autoLinkThreshold) continue;
      final artistBonus = artist != null && songArtist != null
          ? 0.01 * matchScore(songArtist, artist)
          : 0.0;
      final score = titleScore + artistBonus;
      if (score > bestScore) {
        (best, bestScore, tie) = (song, score, false);
      } else if (score == bestScore) {
        tie = true;
      }
    }
    return tie ? null : best;
  }
}
