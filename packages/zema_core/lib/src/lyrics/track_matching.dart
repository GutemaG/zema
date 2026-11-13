import 'dart:math';

import '../library/track.dart';
import '../search/transliteration.dart';
import 'lyrics_models.dart';

/// The score a track's title must reach to link to a song automatically.
const double autoLinkThreshold = 0.9;

/// Songs prepared for matching against many tracks; build once per lyrics
/// change. Works on full songs or catalog index entries.
class SongMatcher<S extends SongIdentity> {
  SongMatcher(List<S> songs)
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

  final List<(S, List<SearchKey>, SearchKey?)> _songs;

  /// The song [track] is, or null when none matches well enough or two
  /// match equally well.
  ///
  /// The song's title (or transliteration) must be found in the track's
  /// title, so noise around it ("… - Official Video") doesn't matter. The
  /// artist only breaks ties between equal titles.
  S? match(Track track) {
    final title = SearchKey(track.title);
    if (title.isEmpty) return null;
    final artist = track.artist == null ? null : SearchKey(track.artist!);
    S? best;
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

  List<SongCandidate<S>> rank(
    String title, {
    String? artist,
    double minimum = 0.6,
    int limit = 5,
  }) {
    final target = SearchKey(title);
    if (target.isEmpty) return const [];
    final by = artist == null ? null : SearchKey(artist);
    final found = <SongCandidate<S>>[];
    for (final (song, keys, songArtist) in _songs) {
      final titleScore = keys.map((k) => matchScore(k, target)).reduce(max);
      if (titleScore < minimum) continue;
      final artistScore = by != null && songArtist != null
          ? max(matchScore(songArtist, by), matchScore(songArtist, target))
          : songArtist != null
          ? matchScore(songArtist, target)
          : 0.0;
      found.add(
        SongCandidate(
          song: song,
          titleScore: titleScore,
          artistScore: artistScore,
          titleWords: keys.map((k) => k.words.length).reduce(max),
        ),
      );
    }
    found.sort((a, b) => b.score.compareTo(a.score));
    return found.take(limit).toList();
  }
}

class SongCandidate<S> {
  const SongCandidate({
    required this.song,
    required this.titleScore,
    required this.artistScore,
    required this.titleWords,
  });

  final S song;
  final double titleScore;
  final double artistScore;
  final int titleWords;

  double get score => titleScore + 0.01 * artistScore;
}

class DetectedSongChoice<S> {
  const DetectedSongChoice({this.sure, this.candidates = const []});

  final S? sure;
  final List<S> candidates;
}

DetectedSongChoice<S> chooseDetectedSong<S>(List<SongCandidate<S>> ranked) {
  if (ranked.isEmpty) return DetectedSongChoice<S>();
  final top = ranked.first;
  final second = ranked.length > 1 ? ranked[1] : null;
  final clear =
      second == null ||
      top.titleScore - second.titleScore >= 0.05 ||
      (top.artistScore >= autoLinkThreshold &&
          top.artistScore - second.artistScore >= 0.3);
  final strong =
      top.titleScore >= autoLinkThreshold &&
      (top.titleWords >= 2 || top.artistScore >= autoLinkThreshold);
  return DetectedSongChoice(
    sure: clear && strong ? top.song : null,
    candidates: [for (final c in ranked) c.song],
  );
}
