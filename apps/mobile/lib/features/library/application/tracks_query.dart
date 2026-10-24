import 'package:zema_core/zema_core.dart';

/// What the track list can be sorted by.
enum TrackSortField { title, artist, album, dateAdded, duration }

class TrackSort {
  const TrackSort(this.field, {this.descending = false});

  static const initial = TrackSort(TrackSortField.title);

  final TrackSortField field;
  final bool descending;

  /// Sorts by text, so the alphabet strip makes sense.
  bool get isAlphabetical => switch (field) {
    TrackSortField.title ||
    TrackSortField.artist ||
    TrackSortField.album => true,
    TrackSortField.dateAdded || TrackSortField.duration => false,
  };

  @override
  bool operator ==(Object other) =>
      other is TrackSort &&
      other.field == field &&
      other.descending == descending;

  @override
  int get hashCode => Object.hash(field, descending);
}

/// Tracks whose title, artist or album contains [query], ignoring case and
/// surrounding spaces. An empty query keeps everything.
List<Track> filterTracks(List<Track> tracks, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return tracks;
  return [
    for (final t in tracks)
      if (t.title.toLowerCase().contains(q) ||
          (t.artist?.toLowerCase().contains(q) ?? false) ||
          (t.album?.toLowerCase().contains(q) ?? false))
        t,
  ];
}

/// [tracks] sorted by [sort]. Missing artists or albums go last in either
/// direction; ties are broken by title, then ID, so the order is stable.
List<Track> sortTracks(List<Track> tracks, TrackSort sort) {
  final sign = sort.descending ? -1 : 1;
  int text(String? a, String? b) {
    if (a == null || b == null) {
      if (a == b) return 0;
      return a == null ? 1 : -1; // Unknown last, whatever the direction.
    }
    return sign * a.toLowerCase().compareTo(b.toLowerCase());
  }

  int compare(Track a, Track b) {
    final primary = switch (sort.field) {
      TrackSortField.title => text(a.title, b.title),
      TrackSortField.artist => text(a.artist, b.artist),
      TrackSortField.album => text(a.album, b.album),
      TrackSortField.dateAdded => sign * a.dateAdded.compareTo(b.dateAdded),
      TrackSortField.duration => sign * a.duration.compareTo(b.duration),
    };
    if (primary != 0) return primary;
    final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
  }

  return [...tracks]..sort(compare);
}

/// The text a track is grouped by in the alphabet strip, or null when [sort]
/// isn't alphabetical or the value is missing.
String? sortText(Track track, TrackSort sort) => switch (sort.field) {
  TrackSortField.title => track.title,
  TrackSortField.artist => track.artist,
  TrackSortField.album => track.album,
  TrackSortField.dateAdded || TrackSortField.duration => null,
};

/// Ethiopic syllables are laid out in rows of eight (ሀ ሁ ሂ ሃ ሄ ህ ሆ ሇ), so
/// the row's first code point is the consonant family.
const _ethiopicStart = 0x1200;
const _ethiopicEnd = 0x137F;

/// The alphabet-strip label for [text]: the uppercase Latin letter, the
/// Ethiopic consonant family (ቁ → ቀ), or `#` for anything else.
String initialOf(String? text) {
  final trimmed = text?.trimLeft() ?? '';
  if (trimmed.isEmpty) return '#';
  final rune = trimmed.runes.first;
  if (rune >= _ethiopicStart && rune <= _ethiopicEnd) {
    return String.fromCharCode(rune - (rune - _ethiopicStart) % 8);
  }
  final letter = String.fromCharCode(rune).toUpperCase();
  final code = letter.codeUnitAt(0);
  return code >= 0x41 && code <= 0x5A ? letter : '#';
}

/// The first index of each initial in an already sorted list, in list order.
Map<String, int> sectionStarts(List<Track> sorted, TrackSort sort) {
  final starts = <String, int>{};
  for (var i = 0; i < sorted.length; i++) {
    starts.putIfAbsent(initialOf(sortText(sorted[i], sort)), () => i);
  }
  return starts;
}
