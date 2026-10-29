import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

LrcImport _import(String lrc) => importLrc(lrc, songId: 's', recordingId: 'r');

List<String> _sung(LrcImport i) => [
  for (final o in expandPlayOrder(i.song).occurrences) o.line.text,
];

Duration _ms(int ms) => Duration(milliseconds: ms);

void main() {
  group('time tags', () {
    test('minutes:seconds with no, two or three decimals', () {
      final i = _import('''
[00:01]a
[00:02.5]b
[00:03.45]c
[01:04.456]d
[100:00.00]e
''');
      expect(i.timing.starts, [
        _ms(1000),
        _ms(2500),
        _ms(3450),
        _ms(64456),
        _ms(6000000),
      ]);
      expect(_sung(i), ['a', 'b', 'c', 'd', 'e']);
    });

    test('several tags put the line at each time; lines go in time order', () {
      final i = _import('''
[00:10.00]late
[00:01.00][00:05.00]twice
[00:03.00]middle
''');
      expect(_sung(i), ['twice', 'middle', 'twice', 'late']);
      expect(i.timing.starts, [_ms(1000), _ms(3000), _ms(5000), _ms(10000)]);
    });

    test('lines at the same time keep their file order', () {
      final i = _import('[00:01]first\n[00:01]second\n');
      expect(_sung(i), ['first', 'second']);
    });

    test('the result always fits SyncedLyrics', () {
      final i = _import('[00:01]a\n[00:02][00:04]b\n[00:03]c\n[00:05]a\n');
      expect(() => SyncedLyrics.of(i.song, i.timing), returnsNormally);
    });
  });

  group('tags', () {
    test('title, artist and album', () {
      final i = _import('[ti:ሰላም ለኪ]\n[ar:ዘማሪት]\n[al:ምስጋና]\n[00:01]a\n');
      expect(i.song.title, 'ሰላም ለኪ');
      expect(i.song.artist, 'ዘማሪት');
      expect(i.song.album, 'ምስጋና');
      expect(i.recording.artist, 'ዘማሪት');
      expect(i.song.id, 's');
      expect(i.recording.id, 'r');
      expect(i.timing.recordingId, 'r');
    });

    test('without a title the song is named by its ID', () {
      expect(_import('[00:01]a').song.title, 's');
    });

    test(
      "LRC's offset (positive = earlier) becomes Zema's (positive = later)",
      () {
        expect(_import('[offset:+500]\n[00:01]a').recording.offset, _ms(-500));
        expect(_import('[offset:-250]\n[00:01]a').recording.offset, _ms(250));
        expect(_import('[00:01]a').recording.offset, Duration.zero);
      },
    );

    test('a bad offset is skipped and reported', () {
      final i = _import('[offset:soon]\n[00:01]a');
      expect(i.recording.offset, Duration.zero);
      expect(i.skipped.single.lineNumber, 1);
    });

    test('[tr:] after a timed line is its transliteration, every time', () {
      final i = _import('''
[00:01][00:09]ሰላም
[tr:Selam]
[00:05]ለኪ
''');
      final sung = expandPlayOrder(i.song).occurrences;
      expect(
        [for (final o in sung) o.line.transliteration],
        ['Selam', null, 'Selam'],
      );
    });

    test('a [tr:] with no timed line before it is ignored', () {
      final i = _import('[tr:nothing]\n[00:01]a');
      expect(
        expandPlayOrder(i.song).occurrences.single.line.transliteration,
        isNull,
      );
      expect(i.skipped, isEmpty);
    });

    test('other LRC tags are ignored', () {
      final i = _import('[length:03:20]\n[by:someone]\n[re:tool]\n[00:01]a');
      expect(i.skipped, isEmpty);
      expect(_sung(i), ['a']);
    });
  });

  group('chorus detection', () {
    test('a repeated block becomes one chorus between verses', () {
      final i = _import('''
[00:01]v1 a
[00:02]v1 b
[00:03][00:07][00:09]c a
[00:04][00:08][00:10]c b
[00:05]v2 a
[00:06]v2 b
''');
      expect(i.song.playOrder, ['v1', 'c', 'v2', 'c', 'c']);
      expect(
        [for (final s in i.song.sections) (s.id, s.kind)],
        [
          ('v1', SectionKind.verse),
          ('c', SectionKind.chorus),
          ('v2', SectionKind.verse),
        ],
      );
      expect(_sung(i), [
        'v1 a', 'v1 b', 'c a', 'c b', 'v2 a', 'v2 b', //
        'c a', 'c b', 'c a', 'c b',
      ]);
    });

    test('the longest repeated block wins over its parts', () {
      final i = _import('''
[00:01]x
[00:02]a
[00:03]b
[00:04]c
[00:05]y
[00:06]a
[00:07]b
[00:08]c
''');
      final chorus = i.song.sections.firstWhere(
        (s) => s.kind == SectionKind.chorus,
      );
      expect([for (final l in chorus.lines) l.text], ['a', 'b', 'c']);
      expect(i.song.playOrder, ['v1', 'c', 'v2', 'c']);
    });

    test('a song can start with its chorus', () {
      final i = _import(
        '[00:01]c a\n[00:02]c b\n[00:03]v\n[00:04]c a\n[00:05]c b',
      );
      expect(i.song.playOrder, ['c', 'v1', 'c']);
    });

    test('a single repeated line is not a chorus', () {
      final i = _import('[00:01]amen\n[00:02]x\n[00:03]amen\n');
      expect(i.song.playOrder, ['v1']);
      expect(i.song.sections.single.lines, hasLength(3));
    });

    test('no repeat means one verse', () {
      final i = _import('[00:01]a\n[00:02]b\n[00:03]c');
      expect(i.song.sections.single.kind, SectionKind.verse);
      expect(i.song.playOrder, ['v1']);
    });

    test('a repeat without its [tr:] line still matches', () {
      final i = _import('''
[00:01]c a
[tr:see a]
[00:02]c b
[00:03]v
[00:04]c a
[00:05]c b
''');
      expect(i.song.playOrder, ['c', 'v1', 'c']);
    });
  });

  group('problems', () {
    test(
      'untimed text and timed lines without text are skipped and listed',
      () {
        final i = _import('''
[00:01]a
just words
[00:02]

[00:03]b
''');
        expect(_sung(i), ['a', 'b']);
        expect([for (final s in i.skipped) s.lineNumber], [2, 3]);
        expect(i.skipped.first.text, 'just words');
      },
    );

    test('Windows line endings and surrounding spaces', () {
      final i = _import('[00:01]  ሰላም  \r\n[00:02]ለኪ\r\n');
      expect(_sung(i), ['ሰላም', 'ለኪ']);
    });

    test('Ethiopic text is kept exactly', () {
      const text = 'ሀሐኀ ሰሠ አዐ ጸፀ፡ ቅዱስ።';
      expect(_sung(_import('[00:01]$text')), [text]);
    });

    test('no timed line at all fails', () {
      for (final lrc in ['', '[ti:Title]\n[ar:x]', 'words only']) {
        expect(
          () => _import(lrc),
          throwsA(isA<LyricsFormatFailure>()),
          reason: lrc,
        );
      }
    });
  });

  group('searchSongs', () {
    const songs = [
      Song(
        id: 'a',
        title: 'ብርሃን ሆንልን',
        transliteration: 'Birhan Honlin',
        sections: [],
      ),
      Song(id: 'b', title: 'Galatoomi', artist: 'Zema Samples', sections: []),
      Song(id: 'c', title: 'ሰላም ለዚህ ቤት', sections: []),
    ];

    List<String> ids(String q) => [for (final s in searchSongs(songs, q)) s.id];

    test('matches title, transliteration and artist', () {
      expect(ids('birhan'), ['a']);
      expect(ids('ብርሃን'), ['a']);
      expect(ids('selam'), ['c']);
      expect(ids('zema samples'), ['b']);
      expect(ids('galatoomi'), ['b']);
    });

    test('better matches first, ties in the given order', () {
      const ranked = [
        Song(id: 'near', title: 'Kidist', sections: []),
        Song(id: 'exact', title: 'Kidus', sections: []),
        Song(id: 'exact2', title: 'Kidus Mikael', sections: []),
      ];
      expect(
        [for (final s in searchSongs(ranked, 'kidus')) s.id],
        ['exact', 'exact2', 'near'],
      );
    });

    test('nothing for an empty or unrelated query', () {
      expect(ids(''), isEmpty);
      expect(ids('qqqzzz'), isEmpty);
    });

    test('works on catalog index entries too', () {
      final entries = [
        for (final s in songs)
          CatalogEntry(
            id: s.id,
            title: s.title,
            transliteration: s.transliteration,
            artist: s.artist,
            synced: false,
            version: 1,
            approvedAt: DateTime.utc(2026),
          ),
      ];
      for (final q in ['birhan', 'ብርሃን', 'selam', 'zema samples', 'qqqzzz']) {
        expect(
          [for (final e in searchSongs(entries, q)) e.id],
          ids(q),
          reason: q,
        );
      }
    });
  });
}
