import 'package:flutter_test/flutter_test.dart';
import 'package:zema/features/library/application/album_grouping.dart';
import 'package:zema/features/library/application/artist_grouping.dart';
import 'package:zema/features/search/application/library_search.dart';
import 'package:zema_core/zema_core.dart';

import '../../../helpers/fake_library.dart';

var _nextId = 1;
Track _track(String title, {String? artist, String? album}) {
  final id = _nextId++;
  return Track.fromScan(
    id,
    scannedAudio(id, '/m/$id.mp3', title: title, artist: artist, album: album),
  );
}

LibrarySearchIndex _index(List<Track> tracks) => LibrarySearchIndex(
  tracks: tracks,
  artists: groupArtists(tracks),
  albums: groupAlbums(tracks),
);

List<String> _titles(List<Track> tracks) => [for (final t in tracks) t.title];

void main() {
  final library = [
    _track('ቅድስት ማርያም', artist: 'ዘማሪት ሰላም', album: 'ምስጋና'),
    _track('ፀሎት', artist: 'Zerfe Kebede', album: 'Kidase'),
    _track('Amlak', artist: 'Zerfe Kebede', album: 'Kidase'),
    _track('መላክ', artist: 'Tewodros'),
    _track('Selam Leki - Official Video 2019', artist: 'Meskerem'),
    _track('No Album', artist: null),
  ];
  final index = _index(library);

  group('LibrarySearchIndex', () {
    test('finds Ethiopic titles from Latin spellings and variants', () {
      expect(_titles(index.search('kidist').songs), ['ቅድስት ማርያም']);
      expect(_titles(index.search('ቅዱስት').songs), ['ቅድስት ማርያም']);
      expect(_titles(index.search('tselot').songs), ['ፀሎት']);
      expect(_titles(index.search('ጸሎት').songs), ['ፀሎት']);
    });

    test('ignores noise in titles', () {
      expect(_titles(index.search('selam leki').songs), [
        'Selam Leki - Official Video 2019',
      ]);
      expect(index.search('official video').songs, isEmpty);
    });

    test('songs by title, artists by name, albums by name and artist', () {
      final zerfe = index.search('zerfe');
      expect(zerfe.songs, isEmpty);
      expect([for (final a in zerfe.artists) a.name], ['Zerfe Kebede']);
      expect([for (final a in zerfe.albums) a.id.title], ['Kidase']);

      expect(
        [for (final a in index.search('kidase').albums) a.id.title],
        ['Kidase'],
      );
      expect(
        [for (final a in index.search('selam').artists) a.name],
        ['ዘማሪት ሰላም'],
      );
    });

    test('unknown artists and albums are not searchable by a name', () {
      expect(index.search('unknown').isEmpty, isTrue);
    });

    test('text containing the query comes before same-consonant words', () {
      // "amlak" and "መላክ" (malak) share consonants: both score 1.
      expect(_titles(index.search('amlak').songs), ['Amlak', 'መላክ']);
      expect(_titles(index.search('መላክ').songs), ['መላክ', 'Amlak']);
    });

    test('better scores first, then library order', () {
      final tracks = [
        _track('Kidus Gabriel'),
        _track('Kidist'),
        _track('Kidus'),
      ];
      // "kidus": exact for both Kidus songs (library order), then the
      // near spelling.
      expect(_titles(_index(tracks).search('kidus').songs), [
        'Kidus Gabriel',
        'Kidus',
        'Kidist',
      ]);
    });

    test('an empty or noise-only query finds nothing', () {
      expect(index.search('').isEmpty, isTrue);
      expect(index.search('  ').isEmpty, isTrue);
      expect(index.search('lyrics').isEmpty, isTrue);
    });

    test('searches 1,000 songs within the keystroke budget', () {
      final big = [
        for (var i = 0; i < 1000; i++)
          _track(
            'መዝሙር ቁጥር $i ቅዱስ',
            artist: 'Artist ${i % 40}',
            album: 'Album ${i % 80}',
          ),
      ];
      final bigIndex = _index(big);
      final watch = Stopwatch()..start();
      // Each keystroke of "kidus".
      for (final query in ['k', 'ki', 'kid', 'kidu', 'kidus']) {
        bigIndex.search(query);
      }
      watch.stop();
      expect(bigIndex.search('kidus').songs, hasLength(1000));
      // < 100 ms per keystroke; five keystrokes here.
      expect(watch.elapsedMilliseconds, lessThan(5 * 100));
      final one = Stopwatch()..start();
      bigIndex.search('kidus');
      expect(one.elapsedMilliseconds, lessThan(100));
    });
  });
}
