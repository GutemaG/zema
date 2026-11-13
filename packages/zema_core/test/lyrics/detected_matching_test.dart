import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

Song _song(
  String id,
  String title, {
  String? transliteration,
  String? artist,
}) => Song(
  id: id,
  title: title,
  transliteration: transliteration,
  artist: artist,
  sections: const [],
);

void main() {
  final matcher = SongMatcher([
    _song('selam', 'ሰላም ለዚህ ቤት', transliteration: 'Selam Lezih Bet'),
    _song('amlak', 'Amlak', artist: 'Zerfe Kebede'),
    _song('haleluya', 'ሃሌሉያ'),
    _song('haleluya2', 'ሃሌሉያ', artist: 'Another Choir'),
    _song('kidus', 'ቅዱስ ቅዱስ', artist: 'Choir A'),
    _song('kidus2', 'ቅዱስ ቅዱስ', artist: 'Choir B'),
  ]);

  String? sure(String title, {String? artist}) =>
      chooseDetectedSong(matcher.rank(title, artist: artist)).sure?.id;

  List<String> candidates(String title, {String? artist}) => [
    for (final s in chooseDetectedSong(
      matcher.rank(title, artist: artist),
    ).candidates)
      s.id,
  ];

  test('a YouTube title with noise around the song is sure', () {
    expect(
      sure('ሰላም ለዚህ ቤት - Zemari Someone | New Mezmur 2024 (Official Video)'),
      'selam',
    );
    expect(sure('Selam lezih bet [lyrics]'), 'selam');
  });

  test('a one-word title needs the artist to be sure', () {
    expect(sure('Amlak - live'), isNull);
    expect(candidates('Amlak - live'), contains('amlak'));
    expect(sure('Amlak', artist: 'Zerfe Kebede Official'), 'amlak');
    expect(sure('Zerfe Kebede - Amlak'), 'amlak');
  });

  test('two songs with the same title ask, unless the artist decides', () {
    expect(sure('ቅዱስ ቅዱስ'), isNull);
    expect(candidates('ቅዱስ ቅዱስ'), unorderedEquals(['kidus', 'kidus2']));
    expect(sure('ቅዱስ ቅዱስ', artist: 'Choir B'), 'kidus2');
  });

  test('nothing close gives no candidates', () {
    final choice = chooseDetectedSong(matcher.rank('Lofi beats to study to'));
    expect(choice.sure, isNull);
    expect(choice.candidates, isEmpty);
    expect(matcher.rank(''), isEmpty);
  });

  test('at most five candidates, best first', () {
    final ranked = matcher.rank('ሃሌሉያ ቅዱስ ቅዱስ ሰላም', minimum: 0, limit: 5);
    expect(ranked, hasLength(5));
    for (var i = 1; i < ranked.length; i++) {
      expect(ranked[i - 1].score, greaterThanOrEqualTo(ranked[i].score));
    }
  });
}
