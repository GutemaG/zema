import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

Track _track(String name, {String? title, String? artist}) => Track.fromScan(
  1,
  ScannedAudio(
    mediaStoreId: 1,
    uri: 'content://media/external/audio/media/1',
    path: '/storage/Music/$name',
    displayName: name,
    title: title,
    artist: artist,
    duration: const Duration(minutes: 4),
    sizeBytes: 1000,
    dateAdded: DateTime.utc(2026, 11, 1),
  ),
);

Song _song(String id, String title, {String? artist}) =>
    Song(id: id, title: title, artist: artist, sections: const []);

void main() {
  group('cleanTag', () {
    test('drops what sites and rippers add', () {
      expect(cleanTag('12 Tamrat Desta [@ETHIOALBUMS]'), '12 Tamrat Desta');
      expect(cleanTag('Ne-Geste Saba CD 1 TRACK 7 (128)'), 'Ne-Geste Saba');
      expect(cleanTag('sara mariyam - fC2ZoJszdzg'), 'sara mariyam');
      expect(cleanTag('ማረኝ @Maryam_Maryam2127'), 'ማረኝ');
      expect(cleanTag('የማይረሳው_ጌታ'), 'የማይረሳው ጌታ');
      expect(cleanTag('Track01'), '');
    });

    test('keeps a last word that is not a video ID', () {
      expect(cleanTag('Teddy - Altesenadah'), 'Teddy - Altesenadah');
      expect(cleanTag('Teddy - Altesenadahu'), 'Teddy - Altesenadahu');
    });

    test('file names also lose their track number', () {
      expect(cleanFileName('01 Endene Filagot'), 'Endene Filagot');
      expect(cleanFileName('01_የማይረሳው_ጌታ'), 'የማይረሳው ጌታ');
      expect(
        cleanFileName('04 - Merkato Sefere - Zoro'),
        'Merkato Sefere - Zoro',
      );
      expect(cleanTag('7 Days'), '7 Days');
    });
  });

  test('isJunkTag', () {
    for (final junk in [
      null,
      '',
      'Track 01',
      'New Title',
      'New Artist (35)',
      'Unknown',
      '<unknown>',
      '123',
    ]) {
      expect(isJunkTag(junk), isTrue, reason: '$junk');
    }
    expect(isJunkTag('ሸኙኝ'), isFalse);
    expect(isJunkTag('Tizita'), isFalse);
  });

  group('matchTitle and matchArtist', () {
    test('a junk title tag gives way to the file name', () {
      final t = _track(
        '01 Endene Filagot.MP3',
        title: 'Track 01',
        artist: 'New Artist',
      );
      expect(matchTitle(t), 'Endene Filagot');
      expect(matchArtist(t), isNull);
    });

    test('no tags: the cleaned file name', () {
      expect(matchTitle(_track('01_የማይረሳው_ጌታ.mp3')), 'የማይረሳው ጌታ');
      expect(matchTitle(_track('Track 09.MP3')), '');
      expect(matchTitle(_track('Track01.mp3', title: 'Track01')), '');
    });

    test('a good title tag is kept', () {
      final t = _track('T4.mp3', title: 'Tsehaye- Sintun Lizerzrew');
      expect(matchTitle(t), 'Tsehaye- Sintun Lizerzrew');
    });

    test('channel, junk and title-again artists are unknown', () {
      expect(
        matchArtist(_track('a.mp3', title: 'ማረኝ', artist: '@Maryam')),
        isNull,
      );
      expect(
        matchArtist(_track('a.mp3', title: 'X', artist: 'Unknown')),
        isNull,
      );
      expect(
        matchArtist(_track('a.mp3', title: 'Track01', artist: 'Track01')),
        isNull,
      );
      expect(
        matchArtist(_track('a.mp3', title: 'X', artist: 'ታምራት ደስታ')),
        'ታምራት ደስታ',
      );
    });
  });

  group('SongMatcher with untidy tags', () {
    final matcher = SongMatcher([
      _song('kuku', 'Tizita', artist: 'Kuku'),
      _song('alex', 'Tizta', artist: 'Alex'),
      _song('filagot', 'Endene Filagot', artist: 'Tilahun Gessesse'),
      _song('dinq', 'ድንቅ አድርጎልኛል', artist: 'ቀሲስ ምንዳዬ ብርሀኑ'),
      _song('dinq-2', 'ድንቅ አድርጎልኛል', artist: 'Another Choir'),
    ]);
    String? match(Track t) => matcher.match(t)?.id;

    test('a "Track 01" tag links by its file name', () {
      expect(
        match(_track('01 Endene Filagot.MP3', title: 'Track 01')),
        'filagot',
      );
    });

    test('the artist in the file name breaks a tie', () {
      final t = _track(
        'Kuku- Tizita.mp3',
        title: 'Tizita',
        artist: 'The Best Of Amharic I',
      );
      expect(match(t), 'kuku');
    });

    test('the artist in the title breaks a tie', () {
      final t = _track(
        'sara mariyam - fC2ZoJszdzg.m4a',
        title: 'ድንቅ አድርጎልኛል ቀሲስ ምንዳዬ ብርሀኑ',
        artist: 'sara mariyam',
      );
      expect(match(t), 'dinq');
    });

    test('still no link when nothing breaks the tie', () {
      expect(match(_track('x.mp3', title: 'Tizita')), isNull);
    });

    test('"Track NN" alone links nothing', () {
      expect(match(_track('Track 09.MP3', title: 'Track 09')), isNull);
    });
  });
}
