import '../library/track.dart';

/// A track as a backup knows it: its tags, length and file name, never the
/// phone's own track ID, so it can be found again on another phone.
class TrackIdentity {
  const TrackIdentity({
    required this.title,
    required this.durationMs,
    required this.fileName,
    this.artist,
    this.album,
  });

  factory TrackIdentity.ofTrack(Track track) => TrackIdentity(
    title: track.title,
    artist: track.artist,
    album: track.album,
    durationMs: track.duration.inMilliseconds,
    fileName: fileNameOf(track.path),
  );

  /// Reads [toJson]'s output; unknown keys are ignored. Throws a
  /// [TypeError] when a field has the wrong type.
  factory TrackIdentity.fromJson(Map<String, Object?> json) => TrackIdentity(
    title: json['title']! as String,
    artist: json['artist'] as String?,
    album: json['album'] as String?,
    durationMs: (json['ms']! as num).toInt(),
    fileName: json['file']! as String,
  );

  final String title;
  final String? artist;
  final String? album;
  final int durationMs;

  /// The last part of the track's path, e.g. `Tizita.mp3`.
  final String fileName;

  Duration get duration => Duration(milliseconds: durationMs);

  /// Short keys, and no nulls: a backup holds thousands of these.
  Map<String, Object?> toJson() => {
    'title': title,
    'artist': ?artist,
    'album': ?album,
    'ms': durationMs,
    'file': fileName,
  };

  @override
  bool operator ==(Object other) =>
      other is TrackIdentity &&
      other.title == title &&
      other.artist == artist &&
      other.album == album &&
      other.durationMs == durationMs &&
      other.fileName == fileName;

  @override
  int get hashCode => Object.hash(title, artist, album, durationMs, fileName);

  @override
  String toString() =>
      'TrackIdentity("$title", $artist, $durationMs ms, $fileName)';
}

/// The file name at the end of [path], without its folders.
String fileNameOf(String path) {
  final slash = path.lastIndexOf('/');
  return slash < 0 ? path : path.substring(slash + 1);
}
