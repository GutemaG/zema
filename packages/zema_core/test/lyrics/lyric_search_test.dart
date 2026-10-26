import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

Song _song(String id, List<LyricLine> lines, {List<String>? chorus}) => Song(
  id: id,
  title: id,
  sections: [
    LyricSection(id: 'v1', kind: SectionKind.verse, lines: lines),
    if (chorus != null)
      LyricSection(
        id: 'c',
        kind: SectionKind.chorus,
        lines: [for (final l in chorus) LyricLine(l)],
      ),
  ],
);

void main() {
  final songs = [
    _song('selam', const [
      LyricLine('ሰላም ለዚህ ቤት', transliteration: 'Selam lezih bet'),
      LyricLine('ፍቅር ይግባ', transliteration: 'Fikir yigba'),
    ]),
    _song(
      'galatoomi',
      const [LyricLine('Waaqayyo nu jaallatee')],
      chorus: ['Galatoomi, galatoomi', 'Galatoomi, galatoomi'],
    ),
    _song('another-selam', const [
      LyricLine('Selam to all'),
      LyricLine('Selam again'),
    ]),
  ];
  final index = LyricLineIndex(songs);

  List<String> ids(String q) => [for (final m in index.search(q)) m.song.id];

  test('finds a song by a line, in either script', () {
    expect(ids('jaallatee'), ['galatoomi']);
    expect(ids('ፍቅር'), ['selam']);
    expect(ids('fikir yigba'), ['selam']);
    expect(index.search('fikir').single.line.text, 'ፍቅር ይግባ');
  });

  test('each song once, with its best line, best first', () {
    final matches = index.search('selam');
    expect([for (final m in matches) m.song.id], ['selam', 'another-selam']);
    expect(matches.first.line.text, 'ሰላም ለዚህ ቤት');
    expect(ids('galatoomi'), ['galatoomi']);
  });

  test('nothing for an empty or unrelated query', () {
    expect(ids(''), isEmpty);
    expect(ids('qqqzzz'), isEmpty);
  });

  test('a search over 5,000 lines takes under 100 ms', () {
    final words = ['selam', 'fikir', 'birhan', 'tesfa', 'kidus', 'egzi'];
    final big = LyricLineIndex([
      for (var s = 0; s < 250; s++)
        _song('s$s', [
          for (var l = 0; l < 20; l++)
            LyricLine('${words[(s + l) % 6]} ${words[(s * l) % 6]} line $s $l'),
        ]),
    ]);
    big.search('warm up');
    final watch = Stopwatch()..start();
    final found = big.search('birhan tesfa');
    watch.stop();
    expect(found, isNotEmpty);
    expect(watch.elapsedMilliseconds, lessThan(100));
  });
}
