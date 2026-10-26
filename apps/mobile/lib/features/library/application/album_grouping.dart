import 'package:zema_core/zema_core.dart';

/// Identifies an album: its name and album-artist tags. Songs without an
/// album tag all belong to the "Unknown album" ([title] null).
class AlbumId {
  const AlbumId(this.title, [String? albumArtist])
    : albumArtist = title == null ? null : albumArtist;

  factory AlbumId.of(Track track) => AlbumId(track.album, track.albumArtist);

  /// Reads the id written by [toQuery]; null when [query] has none.
  static AlbumId? fromQuery(Map<String, String> query) {
    if (query['unknown'] == '1') return const AlbumId(null);
    final title = query['album'];
    return title == null ? null : AlbumId(title, query['albumArtist']);
  }

  final String? title;
  final String? albumArtist;

  /// Route query parameters for this id.
  Map<String, String> toQuery() => title == null
      ? const {'unknown': '1'}
      : {'album': title!, 'albumArtist': ?albumArtist};

  @override
  bool operator ==(Object other) =>
      other is AlbumId &&
      other.title == title &&
      other.albumArtist == albumArtist;

  @override
  int get hashCode => Object.hash(title, albumArtist);

  @override
  String toString() => 'AlbumId($title, $albumArtist)';
}

/// An album grouped from file tags.
class Album {
  const Album({
    required this.id,
    required this.artist,
    required this.variousArtists,
    required this.year,
    required this.tracks,
  });

  /// Groups [tracks] (all from one album) and orders them.
  factory Album.of(AlbumId id, List<Track> tracks) {
    final ordered = [...tracks]..sort(_inAlbumOrder);
    final albumArtists = {for (final t in ordered) ?t.albumArtist};
    final artists = {for (final t in ordered) t.artist};
    final String? artist;
    final bool various;
    if (albumArtists.length == 1) {
      (artist, various) = (albumArtists.single, false);
    } else if (artists.length == 1) {
      (artist, various) = (artists.single, false);
    } else {
      (artist, various) = (null, true);
    }
    return Album(
      id: id,
      artist: artist,
      variousArtists: various,
      year: _commonYear(ordered),
      tracks: ordered,
    );
  }

  final AlbumId id;

  /// Null with [variousArtists] false means no artist is known.
  final String? artist;

  /// The songs are by different artists and there is no album artist.
  final bool variousArtists;

  /// The year most of the songs have, or null.
  final int? year;

  /// By track number (unnumbered last), then title.
  final List<Track> tracks;

  String? get title => id.title;
  Duration get duration =>
      tracks.fold(Duration.zero, (sum, t) => sum + t.duration);

  /// The song whose art is the album cover.
  Track get cover => tracks.first;

  static int _inAlbumOrder(Track a, Track b) {
    final an = a.trackNumber, bn = b.trackNumber;
    if (an != bn) {
      if (an == null) return 1;
      if (bn == null) return -1;
      return an.compareTo(bn);
    }
    final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
  }

  /// The most frequent year; the latest one on a tie.
  static int? _commonYear(List<Track> tracks) {
    final counts = <int, int>{};
    for (final t in tracks) {
      if (t.year case final year?) counts[year] = (counts[year] ?? 0) + 1;
    }
    int? best;
    for (final MapEntry(key: year, value: count) in counts.entries) {
      final bestCount = counts[best] ?? 0;
      if (count > bestCount || (count == bestCount && year > best!)) {
        best = year;
      }
    }
    return best;
  }
}

/// [tracks] grouped into albums, in no particular order.
List<Album> groupAlbums(List<Track> tracks) {
  final byId = <AlbumId, List<Track>>{};
  for (final track in tracks) {
    (byId[AlbumId.of(track)] ??= []).add(track);
  }
  return [
    for (final MapEntry(key: id, value: tracks) in byId.entries)
      Album.of(id, tracks),
  ];
}

enum AlbumSortField { name, artist, year }

class AlbumSort {
  const AlbumSort(this.field, {this.descending = false});

  static const initial = AlbumSort(AlbumSortField.name);

  final AlbumSortField field;
  final bool descending;

  @override
  bool operator ==(Object other) =>
      other is AlbumSort &&
      other.field == field &&
      other.descending == descending;

  @override
  int get hashCode => Object.hash(field, descending);
}

/// [albums] sorted by [sort]. Unknown names, artists ("Various artists"
/// included) and years go last in either direction; ties are broken by
/// name.
List<Album> sortAlbums(List<Album> albums, AlbumSort sort) {
  final sign = sort.descending ? -1 : 1;

  int nullsLast<T>(T? a, T? b, int Function(T, T) compare, {int sign = 1}) {
    if (a == null || b == null) {
      if (a == b) return 0;
      return a == null ? 1 : -1;
    }
    return sign * compare(a, b);
  }

  int text(String? a, String? b, {int sign = 1}) => nullsLast(
    a?.toLowerCase(),
    b?.toLowerCase(),
    (x, y) => x.compareTo(y),
    sign: sign,
  );

  int compare(Album a, Album b) {
    final primary = switch (sort.field) {
      AlbumSortField.name => text(a.title, b.title, sign: sign),
      AlbumSortField.artist => text(a.artist, b.artist, sign: sign),
      AlbumSortField.year => nullsLast(
        a.year,
        b.year,
        (x, y) => x.compareTo(y),
        sign: sign,
      ),
    };
    if (primary != 0) return primary;
    final secondary = text(a.title, b.title);
    return secondary != 0
        ? secondary
        : (a.artist ?? '').compareTo(b.artist ?? '');
  }

  return [...albums]..sort(compare);
}
