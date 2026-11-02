import '../lyrics/lyrics_models.dart';

/// Lyrics pasted as one text, split into sections and the order they are
/// sung in.
class PastedLyrics {
  const PastedLyrics({required this.sections, required this.playOrder});

  final List<LyricSection> sections;

  /// Section ids in the order they are sung, repeats included.
  final List<String> playOrder;
}

final _spaces = RegExp(r'\s+');

/// Splits [text] into sections: a blank line starts a new one. A section
/// equal to an earlier one (ignoring spacing) is a repeat of it in the play
/// order, and the earlier one becomes a chorus; the rest are verses. Ids
/// follow the kinds: v1, v2, c1.
PastedLyrics splitPastedLyrics(String text) {
  final blocks = <List<String>>[];
  var current = <String>[];
  for (final raw in text.split(RegExp(r'\r\n|\r|\n'))) {
    final line = raw.trim().replaceAll(_spaces, ' ');
    if (line.isEmpty) {
      if (current.isNotEmpty) blocks.add(current);
      current = [];
    } else {
      current.add(line);
    }
  }
  if (current.isNotEmpty) blocks.add(current);

  final unique = <List<String>>[];
  final keys = <String, int>{};
  final repeated = <int>{};
  final order = <int>[];
  for (final block in blocks) {
    final key = block.join('\n');
    final seen = keys[key];
    if (seen != null) {
      repeated.add(seen);
      order.add(seen);
    } else {
      keys[key] = unique.length;
      order.add(unique.length);
      unique.add(block);
    }
  }

  var verses = 0;
  var choruses = 0;
  final ids = <String>[];
  final sections = <LyricSection>[];
  for (var i = 0; i < unique.length; i++) {
    final chorus = repeated.contains(i);
    final id = chorus ? 'c${++choruses}' : 'v${++verses}';
    ids.add(id);
    sections.add(
      LyricSection(
        id: id,
        kind: chorus ? SectionKind.chorus : SectionKind.verse,
        lines: [for (final line in unique[i]) LyricLine(line)],
      ),
    );
  }
  return PastedLyrics(
    sections: sections,
    playOrder: [for (final i in order) ids[i]],
  );
}
