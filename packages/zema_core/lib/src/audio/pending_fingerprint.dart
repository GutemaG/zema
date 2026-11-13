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
