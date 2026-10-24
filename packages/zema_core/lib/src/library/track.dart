import 'scanned_audio.dart';

/// A local audio file as Zema knows it.
///
/// [id] is Zema's own ID: it stays the same across rescans, moves and media
/// index rebuilds, so favorites, playlists and play counts follow the file.
class Track {
  const Track({
    required this.id,
    required this.mediaStoreId,
    required this.uri,
    required this.path,
    required this.title,
    required this.duration,
    required this.sizeBytes,
    required this.dateAdded,
    this.artist,
    this.album,
    this.albumArtist,
    this.trackNumber,
    this.year,
    this.missing = false,
  });

  /// Builds the track a scan entry describes, for a given Zema [id].
  factory Track.fromScan(int id, ScannedAudio audio) => Track(
    id: id,
    mediaStoreId: audio.mediaStoreId,
    uri: audio.uri,
    path: audio.path,
    title: resolveTitle(audio),
    artist: audio.artist,
    album: audio.album,
    albumArtist: audio.albumArtist,
    trackNumber: audio.trackNumber,
    year: audio.year,
    duration: audio.duration,
    sizeBytes: audio.sizeBytes,
    dateAdded: audio.dateAdded,
  );

  final int id;
  final int mediaStoreId;
  final String uri;
  final String path;

  /// Title tag, or the file name without its extension.
  final String title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final int? trackNumber;
  final int? year;
  final Duration duration;
  final int sizeBytes;
  final DateTime dateAdded;

  /// True when the last scan didn't find the file. Missing tracks are kept so
  /// their favorites and playlist entries come back if the file returns.
  final bool missing;

  /// The folder that contains the file.
  String get folder => folderOf(path);

  Track copyWith({
    int? mediaStoreId,
    String? uri,
    String? path,
    String? title,
    String? artist,
    String? album,
    String? albumArtist,
    int? trackNumber,
    int? year,
    Duration? duration,
    int? sizeBytes,
    DateTime? dateAdded,
    bool? missing,
  }) => Track(
    id: id,
    mediaStoreId: mediaStoreId ?? this.mediaStoreId,
    uri: uri ?? this.uri,
    path: path ?? this.path,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    album: album ?? this.album,
    albumArtist: albumArtist ?? this.albumArtist,
    trackNumber: trackNumber ?? this.trackNumber,
    year: year ?? this.year,
    duration: duration ?? this.duration,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    dateAdded: dateAdded ?? this.dateAdded,
    missing: missing ?? this.missing,
  );

  @override
  bool operator ==(Object other) =>
      other is Track &&
      other.id == id &&
      other.mediaStoreId == mediaStoreId &&
      other.uri == uri &&
      other.path == path &&
      other.title == title &&
      other.artist == artist &&
      other.album == album &&
      other.albumArtist == albumArtist &&
      other.trackNumber == trackNumber &&
      other.year == year &&
      other.duration == duration &&
      other.sizeBytes == sizeBytes &&
      other.dateAdded == dateAdded &&
      other.missing == missing;

  @override
  int get hashCode => Object.hash(
    id,
    mediaStoreId,
    uri,
    path,
    title,
    artist,
    album,
    albumArtist,
    trackNumber,
    year,
    duration,
    sizeBytes,
    dateAdded,
    missing,
  );

  @override
  String toString() => 'Track($id, $title)';
}

/// The title to show for [audio]: its title tag, or the file name without
/// the extension when the tag is missing or blank.
String resolveTitle(ScannedAudio audio) {
  final tag = audio.title?.trim();
  if (tag != null && tag.isNotEmpty) return tag;
  final name = audio.displayName;
  final dot = name.lastIndexOf('.');
  return dot > 0 ? name.substring(0, dot) : name;
}

/// The folder part of a `/`-separated [path], without a trailing slash.
/// Returns `/` for files at the root and an empty string for bare names.
String folderOf(String path) {
  final slash = path.lastIndexOf('/');
  if (slash < 0) return '';
  if (slash == 0) return '/';
  return path.substring(0, slash);
}
