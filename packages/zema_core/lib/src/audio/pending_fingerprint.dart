import 'audio_fingerprint.dart';

/// A fingerprint shared from a library, waiting for a moderator (intent
/// 009, FR-2).
class PendingFingerprint {
  const PendingFingerprint({
    required this.id,
    required this.recordingId,
    required this.songId,
    required this.songTitle,
    required this.frameCount,
    required this.hashCount,
    required this.installs,
    required this.sentAt,
    this.recordingArtist,
    this.recordingDuration,
  });

  final String id;
  final String recordingId;
  final String songId;
  final String songTitle;
  final String? recordingArtist;

  /// The catalog recording's length, when known.
  final Duration? recordingDuration;

  /// The fingerprinted file's length, in fingerprint frames.
  final int frameCount;
  final int hashCount;

  /// How many installs sent a fingerprint for the recording.
  final int installs;
  final DateTime sentAt;

  /// The fingerprinted file's length.
  Duration get duration => fingerprintFrameTime(frameCount);
}

/// A track print shared from a library, waiting for a moderator (intent
/// 013, FR-6): no second install sent a matching one, or it matched a
/// different song's ([conflictSongTitle]).
class PendingTrackPrint {
  const PendingTrackPrint({
    required this.id,
    required this.songId,
    required this.songTitle,
    required this.duration,
    required this.installs,
    required this.sentAt,
    this.songArtist,
    this.conflictSongId,
    this.conflictSongTitle,
  });

  final int id;
  final String songId;
  final String songTitle;
  final String? songArtist;

  /// The printed file's length.
  final Duration duration;

  /// How many installs sent a print for the song.
  final int installs;

  /// The other song the print matched when it was shared, if any.
  final String? conflictSongId;
  final String? conflictSongTitle;
  final DateTime sentAt;
}
