import 'lyrics_models.dart';

/// One line as sung: a line of a section, at one place in the play order.
/// A chorus sung three times gives each of its lines three occurrences.
class LineOccurrence {
  const LineOccurrence({
    required this.index,
    required this.sectionId,
    required this.sectionKind,
    required this.lineIndex,
    required this.repeat,
    required this.line,
  });

  /// Position in the sung order; timings are kept per index.
  final int index;
  final String sectionId;
  final SectionKind sectionKind;

  /// The line's position within its section.
  final int lineIndex;

  /// How many times the section was sung before this (0 the first time).
  final int repeat;
  final LyricLine line;

  /// Whether this starts a section, where the lyrics view can mark it.
  bool get startsSection => lineIndex == 0;

  @override
  String toString() =>
      'LineOccurrence($index: $sectionId[$lineIndex] #$repeat)';
}

/// The lines of a song in the order they are sung.
class PlayOrderExpansion {
  const PlayOrderExpansion({
    required this.occurrences,
    required this.missingSections,
  });

  final List<LineOccurrence> occurrences;

  /// Section IDs the play order names that the song doesn't have; they
  /// were skipped.
  final List<String> missingSections;
}

/// Expands [song]'s play order into the lines as sung, repeats included.
/// With no play order the sections are sung once each, as written.
/// Empty sections add nothing.
PlayOrderExpansion expandPlayOrder(Song song) {
  final byId = {for (final s in song.sections) s.id: s};
  final order = song.playOrder.isEmpty
      ? [for (final s in song.sections) s.id]
      : song.playOrder;
  final occurrences = <LineOccurrence>[];
  final missing = <String>[];
  final sung = <String, int>{};
  for (final id in order) {
    final section = byId[id];
    if (section == null) {
      missing.add(id);
      continue;
    }
    final repeat = sung[id] ?? 0;
    sung[id] = repeat + 1;
    for (final (i, line) in section.lines.indexed) {
      occurrences.add(
        LineOccurrence(
          index: occurrences.length,
          sectionId: id,
          sectionKind: section.kind,
          lineIndex: i,
          repeat: repeat,
          line: line,
        ),
      );
    }
  }
  return PlayOrderExpansion(occurrences: occurrences, missingSections: missing);
}
