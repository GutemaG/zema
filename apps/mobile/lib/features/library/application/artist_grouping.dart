import 'package:zema_core/zema_core.dart';

import 'album_grouping.dart';

/// A singer or group, by the artist tag as written ("A & B" is its own
/// artist). Songs without an artist tag belong to "Unknown artist"
/// ([name] null).
class Artist {
  const Artist({
    required this.name,
    required this.tracks,
    required this.albums,
  });

  factory Artist.of(String? name, List<Track> tracks) {
    final albums = groupAlbums(tracks)..sort(_byYearThenName);
    return Artist(
      name: name,
      tracks: [...tracks]..sort(_byTitle),
      albums: albums,
    );
  }

  final String? name;

  /// Their songs, by title.
  final List<Track> tracks;

  /// Albums with at least one of their songs, newest first ("Unknown album"
  /// last). Each holds only this artist's songs.
  final List<Album> albums;

  /// The song whose art is the avatar: the cover of their first named
  /// album, else their first song.
  Track get cover {
    for (final album in albums) {
      if (album.title != null) return album.cover;
    }
    return tracks.first;
  }

  static int _byTitle(Track a, Track b) {
    final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
  }

  static int _byYearThenName(Album a, Album b) {
    if ((a.title == null) != (b.title == null)) return a.title == null ? 1 : -1;
    final ay = a.year, by = b.year;
    if (ay != by) {
      if (ay == null) return 1;
      if (by == null) return -1;
      return by.compareTo(ay);
    }
    return (a.title ?? '').toLowerCase().compareTo(
      (b.title ?? '').toLowerCase(),
    );
  }
}

/// [tracks] grouped by artist, by name ("Unknown artist" last).
List<Artist> groupArtists(List<Track> tracks) {
  final byName = <String?, List<Track>>{};
  for (final track in tracks) {
    (byName[track.artist] ??= []).add(track);
  }
  return [
    for (final MapEntry(key: name, value: tracks) in byName.entries)
      Artist.of(name, tracks),
  ]..sort((a, b) {
    final an = a.name, bn = b.name;
    if (an == null || bn == null) return an == bn ? 0 : (an == null ? 1 : -1);
    return an.toLowerCase().compareTo(bn.toLowerCase());
  });
}
