import '../library/track.dart';
import '../search/normalize.dart';
import 'track_identity.dart';

/// How far a track's length may be from a backed-up one, either way.
const matchDurationTolerance = Duration(seconds: 2);

/// Finds the track on this phone that a backed-up [TrackIdentity] is.
/// Build once per restore; [match] is a lookup.
///
/// In order:
/// 1. the same file name (any letter case) and a length within
///    [matchDurationTolerance];
/// 2. the same title and artist, compared as search compares them (case,
///    spacing, punctuation and Ethiopic spelling variants ignored), and a
///    length within [matchDurationTolerance].
///
/// Never on the title alone: an identity or track without an artist is
/// matched by file name only. Missing tracks are left out. When several
/// fit, the closest length wins, then the lowest track ID.
class BackupTrackMatcher {
  BackupTrackMatcher(Iterable<Track> tracks) {
    for (final track in tracks) {
      if (track.missing) continue;
      _byFile
          .putIfAbsent(fileNameOf(track.path).toLowerCase(), () => [])
          .add(track);
      if (_tagKey(track.title, track.artist) case final key?) {
        _byTags.putIfAbsent(key, () => []).add(track);
      }
    }
  }

  final _byFile = <String, List<Track>>{};
  final _byTags = <String, List<Track>>{};

  /// The track [identity] is on this phone, or null.
  Track? match(TrackIdentity identity) =>
      _closest(_byFile[identity.fileName.toLowerCase()], identity) ??
      switch (_tagKey(identity.title, identity.artist)) {
        final key? => _closest(_byTags[key], identity),
        null => null,
      };

  static Track? _closest(List<Track>? tracks, TrackIdentity identity) {
    if (tracks == null) return null;
    Track? best;
    var bestGap = 0;
    for (final track in tracks) {
      final gap = (track.duration.inMilliseconds - identity.durationMs).abs();
      if (gap > matchDurationTolerance.inMilliseconds) continue;
      if (best == null ||
          gap < bestGap ||
          (gap == bestGap && track.id < best.id)) {
        best = track;
        bestGap = gap;
      }
    }
    return best;
  }

  /// Title and artist as search compares them; null without an artist or
  /// when either has nothing left to compare.
  static String? _tagKey(String title, String? artist) {
    if (artist == null) return null;
    final t = normalizeSearchText(title);
    final a = normalizeSearchText(artist);
    if (t.isEmpty || a.isEmpty) return null;
    return '$t\u0000$a';
  }
}
