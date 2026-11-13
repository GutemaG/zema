import 'dart:math' as math;

import 'audio_fingerprint.dart';

/// Fewest hashes that must line up at one time shift for a match. Excerpts
/// of songs that aren't in the index scored at most 7 in the 009 spike.
const int minimumMatchScore = 12;

/// A recording an excerpt was found in.
class AudioMatch {
  const AudioMatch({
    required this.recordingId,
    required this.position,
    required this.score,
    required this.playbackSpeed,
    required this.ambiguousPosition,
  });

  final String recordingId;

  /// Where the excerpt starts in the recording. Negative when the excerpt
  /// starts before the recording does (a file with a longer intro).
  final Duration position;

  /// Hashes that lined up at [position]; higher is surer, at least
  /// [minimumMatchScore].
  final int score;

  /// How fast the excerpt's audio runs against the recording: 1.02 for a
  /// copy sped up by 2%. The lyrics' clock runs at this speed.
  final double playbackSpeed;

  /// The excerpt also lines up well at another position, as a chorus that
  /// repeats does; listen longer before trusting [position].
  final bool ambiguousPosition;

  @override
  String toString() =>
      'AudioMatch($recordingId at $position, score $score, '
      'speed $playbackSpeed${ambiguousPosition ? ', ambiguous' : ''})';
}

/// Fingerprints of recordings, searchable by excerpt.
///
/// Matching counts, for each recording, how many of the excerpt's hashes
/// appear in it at each time shift (recording frame minus excerpt frame).
/// Random hash collisions spread over many shifts; the right recording piles
/// up at one shift, and that shift is where the excerpt starts.
class FingerprintIndex {
  final _ids = <String>[];
  final _numbers = <String, int>{};

  /// Hash → postings, each `recording number * _frameSpan + frame`.
  final _postings = <int, List<int>>{};
  var _hashCount = 0;

  static const _frameSpan = 1 << 21; // ~13 hours of frames

  int get recordingCount => _ids.length;
  int get hashCount => _hashCount;

  /// Adds [fingerprint] as [recordingId]. Adding the same id again adds to
  /// it; don't.
  void add(String recordingId, AudioFingerprint fingerprint) {
    final number = _numbers.putIfAbsent(recordingId, () {
      _ids.add(recordingId);
      return _ids.length - 1;
    });
    for (var i = 0; i < fingerprint.length; i++) {
      (_postings[fingerprint.hashes[i]] ??= []).add(
        number * _frameSpan + fingerprint.frames[i],
      );
    }
    _hashCount += fingerprint.length;
  }

  /// The recordings [queries] match, best first, at most [limit]. [queries]
  /// are one excerpt fingerprinted at several speeds
  /// (`Fingerprinter.queries`); each recording keeps its best speed.
  List<AudioMatch> match(List<AudioFingerprint> queries, {int limit = 3}) {
    final best = <int, AudioMatch>{};
    for (final query in queries) {
      for (final MapEntry(key: number, value: votes) in _votes(query).entries) {
        final m = _best(number, votes, query.speed);
        if (m == null) continue;
        final previous = best[number];
        if (previous == null || m.score > previous.score) best[number] = m;
      }
    }
    final matches = best.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return matches.take(limit).toList();
  }

  /// Per recording number: time shift → hashes at that shift.
  Map<int, Map<int, int>> _votes(AudioFingerprint query) {
    final votes = <int, Map<int, int>>{};
    for (var i = 0; i < query.length; i++) {
      final postings = _postings[query.hashes[i]];
      if (postings == null) continue;
      for (final p in postings) {
        final number = p ~/ _frameSpan;
        final shift = p % _frameSpan - query.frames[i];
        final byShift = votes[number] ??= {};
        byShift[shift] = (byShift[shift] ?? 0) + 1;
      }
    }
    return votes;
  }

  /// The shift with the most votes, counting the frames either side too
  /// (peaks move by a frame between copies).
  AudioMatch? _best(int number, Map<int, int> votes, double speed) {
    var top = 0;
    var topShift = 0;
    final scores = <int, int>{};
    for (final shift in votes.keys) {
      final score =
          votes[shift]! + (votes[shift - 1] ?? 0) + (votes[shift + 1] ?? 0);
      scores[shift] = score;
      if (score > top || score == top && shift < topShift) {
        top = score;
        topShift = shift;
      }
    }
    if (top < minimumMatchScore) return null;
    var runnerUp = 0;
    scores.forEach((shift, score) {
      if ((shift - topShift).abs() > 3) runnerUp = math.max(runnerUp, score);
    });
    return audioMatchAt(
      recordingId: _ids[number],
      shift: topShift,
      score: top,
      runnerUp: runnerUp,
      speed: speed,
    );
  }
}

/// The match of an excerpt fingerprinted at [speed] that lines up with
/// [recordingId] at [shift] frames, [score] hashes there and [runnerUp] at
/// the best shift elsewhere.
AudioMatch audioMatchAt({
  required String recordingId,
  required int shift,
  required int score,
  required int runnerUp,
  double speed = 1,
}) => AudioMatch(
  recordingId: recordingId,
  position: shift >= 0
      ? fingerprintFrameTime(shift)
      : -fingerprintFrameTime(-shift),
  score: score,
  playbackSpeed: 1 / speed,
  ambiguousPosition: runnerUp >= minimumMatchScore && runnerUp * 3 >= score * 2,
);
