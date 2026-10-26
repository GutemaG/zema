import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

LyricSection _section(String id, SectionKind kind, List<String> lines) =>
    LyricSection(
      id: id,
      kind: kind,
      lines: [for (final l in lines) LyricLine(l)],
    );

Song _song(List<LyricSection> sections, [List<String> playOrder = const []]) =>
    Song(id: 's', title: 'T', sections: sections, playOrder: playOrder);

List<String> _texts(PlayOrderExpansion e) => [
  for (final o in e.occurrences) o.line.text,
];

void main() {
  final v1 = _section('v1', SectionKind.verse, ['v1 a', 'v1 b']);
  final v2 = _section('v2', SectionKind.verse, ['v2 a']);
  final chorus = _section('c', SectionKind.chorus, ['c a', 'c b']);
  final bridge = _section('b', SectionKind.bridge, ['b a']);

  group('expandPlayOrder', () {
    test('a chorus written once is sung each time it is listed', () {
      final expansion = expandPlayOrder(
        _song([v1, chorus, v2], ['v1', 'c', 'v2', 'c', 'c']),
      );

      expect(_texts(expansion), [
        'v1 a', 'v1 b', //
        'c a', 'c b',
        'v2 a',
        'c a', 'c b',
        'c a', 'c b',
      ]);
      expect(
        [for (final o in expansion.occurrences) o.repeat],
        [
          0, 0, 0, 0, 0, 1, 1, 2, 2, //
        ],
      );
      expect(expansion.missingSections, isEmpty);
    });

    test('occurrences know their index, section and line', () {
      final occurrences = expandPlayOrder(_song([v1, chorus], ['c', 'v1', 'c']))
          .occurrences;

      expect([for (final o in occurrences) o.index], [0, 1, 2, 3, 4, 5]);
      final third = occurrences[2];
      expect(third.sectionId, 'v1');
      expect(third.sectionKind, SectionKind.verse);
      expect(third.lineIndex, 0);
      expect(third.startsSection, isTrue);
      expect(occurrences[3].startsSection, isFalse);
      expect(occurrences[4].sectionKind, SectionKind.chorus);
      expect(occurrences[4].repeat, 1);
    });

    test('a bridge sits between choruses', () {
      final expansion = expandPlayOrder(
        _song([chorus, bridge], ['c', 'b', 'c']),
      );

      expect(_texts(expansion), ['c a', 'c b', 'b a', 'c a', 'c b']);
      expect(expansion.occurrences[2].sectionKind, SectionKind.bridge);
    });

    test('empty sections add nothing', () {
      final empty = _section('e', SectionKind.other, []);
      final expansion = expandPlayOrder(_song([v1, empty], ['e', 'v1', 'e']));

      expect(_texts(expansion), ['v1 a', 'v1 b']);
      expect(expansion.occurrences.first.index, 0);
    });

    test('section IDs the song lacks are skipped and reported', () {
      final expansion = expandPlayOrder(
        _song([v1, chorus], ['v1', 'chorus', 'c', 'x']),
      );

      expect(_texts(expansion), ['v1 a', 'v1 b', 'c a', 'c b']);
      expect(expansion.missingSections, ['chorus', 'x']);
    });

    test('no play order means each section once, as written', () {
      expect(_texts(expandPlayOrder(_song([chorus, v1]))), [
        'c a', 'c b', 'v1 a', 'v1 b', //
      ]);
    });

    test('a song without sections has no lines', () {
      final expansion = expandPlayOrder(_song([]));
      expect(expansion.occurrences, isEmpty);
      expect(expansion.missingSections, isEmpty);
    });
  });
}
