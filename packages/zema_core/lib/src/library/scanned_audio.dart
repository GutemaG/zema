/// One audio file as the device's media index reports it, before Zema matches
/// it to a stored track.
///
/// Optional fields are null when the file has no such tag. Scanners map
/// platform placeholders such as MediaStore's `<unknown>` artist to null.
class ScannedAudio {
  const ScannedAudio({
    required this.mediaStoreId,
    required this.uri,
    required this.path,
    required this.displayName,
    required this.title,
    required this.duration,
    required this.sizeBytes,
    required this.dateAdded,
    this.artist,
    this.album,
    this.albumArtist,
    this.trackNumber,
    this.year,
  });

  /// The media index's own ID. Can change when the index is rebuilt, so Zema
  /// only uses it to play the file and load its art.
  final int mediaStoreId;

  /// Content URI used to play the file.
  final String uri;

  /// Absolute file path, e.g. `/storage/emulated/0/Music/Song.mp3`.
  final String path;

  /// File name with extension.
  final String displayName;

  /// Title tag, or null/empty when the file has none.
  final String? title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final int? trackNumber;
  final int? year;
  final Duration duration;
  final int sizeBytes;
  final DateTime dateAdded;

  @override
  bool operator ==(Object other) =>
      other is ScannedAudio &&
      other.mediaStoreId == mediaStoreId &&
      other.uri == uri &&
      other.path == path &&
      other.displayName == displayName &&
      other.title == title &&
      other.artist == artist &&
      other.album == album &&
      other.albumArtist == albumArtist &&
      other.trackNumber == trackNumber &&
      other.year == year &&
      other.duration == duration &&
      other.sizeBytes == sizeBytes &&
      other.dateAdded == dateAdded;

  @override
  int get hashCode => Object.hash(
    mediaStoreId,
    uri,
    path,
    displayName,
    title,
    artist,
    album,
    albumArtist,
    trackNumber,
    year,
    duration,
    sizeBytes,
    dateAdded,
  );

  @override
  String toString() => 'ScannedAudio($mediaStoreId, $displayName)';
}
