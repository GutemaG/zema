import 'scanned_audio.dart';
import 'track.dart';

/// Identifies the same audio file after it moved or was renamed, when its
/// path no longer matches: file size, duration to the nearest second, and the
/// normalized title.
class TrackFingerprint {
  const TrackFingerprint({
    required this.sizeBytes,
    required this.durationSeconds,
    required this.title,
  });

  factory TrackFingerprint.ofScan(ScannedAudio audio) => TrackFingerprint(
    sizeBytes: audio.sizeBytes,
    durationSeconds: _roundedSeconds(audio.duration),
    title: normalizeTitle(resolveTitle(audio)),
  );

  factory TrackFingerprint.ofTrack(Track track) => TrackFingerprint(
    sizeBytes: track.sizeBytes,
    durationSeconds: _roundedSeconds(track.duration),
    title: normalizeTitle(track.title),
  );

  final int sizeBytes;
  final int durationSeconds;

  /// Already normalized with [normalizeTitle].
  final String title;

  static int _roundedSeconds(Duration d) => (d.inMilliseconds / 1000).round();

  @override
  bool operator ==(Object other) =>
      other is TrackFingerprint &&
      other.sizeBytes == sizeBytes &&
      other.durationSeconds == durationSeconds &&
      other.title == title;

  @override
  int get hashCode => Object.hash(sizeBytes, durationSeconds, title);

  @override
  String toString() =>
      'TrackFingerprint($sizeBytes B, $durationSeconds s, "$title")';
}

final _whitespace = RegExp(r'\s+');

/// Trims, lowercases and collapses runs of whitespace. Ethiopic has no case,
/// so it passes through unchanged apart from spacing.
String normalizeTitle(String title) =>
    title.trim().toLowerCase().replaceAll(_whitespace, ' ');
