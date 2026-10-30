import 'track_identity.dart';

/// Which part of a backup an [UnmatchedEntry] came from.
enum BackupEntryKind { favorite, playlist, lyricsChoice, hiddenTrack }

/// A backed-up entry whose track isn't on this phone (yet). Kept, so the
/// next backup still holds it and a later scan can add it.
class UnmatchedEntry {
  const UnmatchedEntry.favorite(this.track, {required DateTime this.addedAt})
    : kind = BackupEntryKind.favorite,
      playlist = null,
      position = null,
      songId = null;

  const UnmatchedEntry.playlist(
    this.track, {
    required String this.playlist,
    required int this.position,
  }) : kind = BackupEntryKind.playlist,
       addedAt = null,
       songId = null;

  const UnmatchedEntry.lyricsChoice(this.track, {this.songId})
    : kind = BackupEntryKind.lyricsChoice,
      playlist = null,
      position = null,
      addedAt = null;

  const UnmatchedEntry.hiddenTrack(this.track)
    : kind = BackupEntryKind.hiddenTrack,
      playlist = null,
      position = null,
      addedAt = null,
      songId = null;

  final BackupEntryKind kind;
  final TrackIdentity track;

  /// For a favorite: when it was added.
  final DateTime? addedAt;

  /// For a playlist entry: the playlist's name and the song's place in it.
  final String? playlist;
  final int? position;

  /// For a lyrics choice: the song, or null for "no lyrics".
  final String? songId;

  @override
  bool operator ==(Object other) =>
      other is UnmatchedEntry &&
      other.kind == kind &&
      other.track == track &&
      other.addedAt == addedAt &&
      other.playlist == playlist &&
      other.position == position &&
      other.songId == songId;

  @override
  int get hashCode =>
      Object.hash(kind, track, addedAt, playlist, position, songId);

  @override
  String toString() => 'UnmatchedEntry(${kind.name}, $track)';
}
