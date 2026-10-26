import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

var _nextId = 1;
Track _track(String title, {String? artist}) {
  final id = _nextId++;
  return Track.fromScan(
    id,
    ScannedAudio(
      mediaStoreId: id,
      uri: 'content://media/external/audio/media/$id',
      path: '/m/$id.mp3',
      displayName: '$id.mp3',
      title: title,
      artist: artist,
      duration: const Duration(minutes: 3),
      sizeBytes: 1000,
      dateAdded: DateTime.utc(2026, 10, 1),
    ),
  );
}

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
    _song('tselot', 'ጸሎት', transliteration: 'Tselot'),
    _song('selam', 'ሰላም ለዚህ ቤት', transliteration: 'Selam Lezih Bet'),
    _song('amlak', 'Amlak', artist: 'Zerfe Kebede'),
    _song('kidus-a', 'ቅዱስ', artist: 'Choir A'),
    _song('kidus-b', 'ቅዱስ', artist: 'Choir B'),
  ]);

  String? match(String title, {String? artist}) =>
      matcher.match(_track(title, artist: artist))?.id;

  group('SongMatcher', () {
    test('links a track whose title is the song', () {
      expect(match('ጸሎት'), 'tselot');
      expect(match('ሰላም ለዚህ ቤት'), 'selam');
      expect(match('Amlak'), 'amlak');
    });

    test('spelling variants, Latin spellings and the transliteration', () {
      expect(match('ፀሎት'), 'tselot');
      expect(match('Tselot'), 'tselot');
      expect(match('selam lezih bet'), 'selam');
      expect(match('AMLAK'), 'amlak');
    });

    test('noise around the title does not stop a link', () {
      expect(match('ፀሎት - Official Video 2019'), 'tselot');
      expect(match('Zemari X - ሰላም ለዚህ ቤት (New Mezmur) HD'), 'selam');
    });

    test('a track title missing part of the song title does not link', () {
      expect(match('ሰላም'), isNull);
      expect(match('Selam Bet'), isNull);
    });

    test('unrelated titles do not link', () {
      for (final title in ['Kidist Mariam', 'Bulk Track 0001', 'ምስጋና']) {
        expect(match(title), isNull, reason: title);
      }
    });

    test('near spellings below 0.9 do not link', () {
      // "selot" is one letter off "tselot" (0.75): fine for search, too weak
      // to link by itself.
      expect(match('Selot'), isNull);
    });

    test('the artist breaks a tie between equal titles', () {
      expect(match('ቅዱስ', artist: 'Choir B'), 'kidus-b');
      expect(match('Kidus', artist: 'choir a'), 'kidus-a');
    });

    test('equal candidates with no artist to choose by give no link', () {
      expect(match('ቅዱስ'), isNull);
      expect(match('ቅዱስ', artist: 'Someone else'), isNull);
    });

    test('a track with an empty or noise-only title does not link', () {
      expect(match('Official Video'), isNull);
    });

    test('no songs, no links', () {
      expect(SongMatcher(const []).match(_track('ጸሎት')), isNull);
    });
  });
}
