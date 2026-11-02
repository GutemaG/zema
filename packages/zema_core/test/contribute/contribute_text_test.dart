import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

void main() {
  group('splitPastedLyrics', () {
    List<List<String>> texts(PastedLyrics p) => [
      for (final s in p.sections) [for (final l in s.lines) l.text],
    ];

    test('blank lines split sections; the play order is as written', () {
      final p = splitPastedLyrics('one\ntwo\n\nthree\n\n\n\nfour\n');
      expect(texts(p), [
        ['one', 'two'],
        ['three'],
        ['four'],
      ]);
      expect(p.playOrder, ['v1', 'v2', 'v3']);
      expect(p.sections.every((s) => s.kind == SectionKind.verse), isTrue);
    });

    test('a repeated section is written once, sung each time, a chorus', () {
      final p = splitPastedLyrics(
        'verse one\n\nchorus a\nchorus b\n\nverse two\n\nchorus a\nchorus b\n'
        '\nchorus a\nchorus b',
      );
      expect(texts(p), [
        ['verse one'],
        ['chorus a', 'chorus b'],
        ['verse two'],
      ]);
      expect([for (final s in p.sections) s.id], ['v1', 'c1', 'v2']);
      expect(p.sections[1].kind, SectionKind.chorus);
      expect(p.playOrder, ['v1', 'c1', 'v2', 'c1', 'c1']);
    });

    test('Windows line endings, spaces and blank lines of spaces', () {
      final p = splitPastedLyrics(
        '  ሰላም   ለዚህ ቤት  \r\n\t\r\n   \r\nሰላም ለዚህ ቤት\r\n',
      );
      expect(texts(p), [
        ['ሰላም ለዚህ ቤት'],
      ]);
      expect(p.playOrder, ['c1', 'c1'], reason: 'spacing is ignored');
    });

    test('nothing pasted gives nothing', () {
      expect(splitPastedLyrics('\n \n').sections, isEmpty);
      expect(splitPastedLyrics('').playOrder, isEmpty);
    });

    test('the result passes the song rules', () {
      final p = splitPastedLyrics('a\nb\n\nc\n\na\nb');
      expect(
        songErrors(
          Song(
            id: 'x',
            title: 'X',
            sections: p.sections,
            playOrder: p.playOrder,
          ),
        ),
        isEmpty,
      );
    });
  });

  group('youtubeVideoId', () {
    const id = 'dQw4w9WgXcQ';

    test('reads the common link forms', () {
      for (final link in [
        'https://www.youtube.com/watch?v=$id',
        'https://youtube.com/watch?v=$id&t=42s&list=PL123',
        'http://m.youtube.com/watch?feature=share&v=$id',
        'https://music.youtube.com/watch?v=$id&si=abc',
        'https://youtu.be/$id',
        'https://youtu.be/$id?si=xyz&t=10',
        'youtu.be/$id',
        'www.youtube.com/watch?v=$id',
        'https://www.youtube.com/shorts/$id',
        'https://www.youtube.com/embed/$id?start=5',
        'https://www.youtube.com/live/$id',
        'https://www.youtube-nocookie.com/embed/$id',
        '  https://youtu.be/$id  ',
        id,
      ]) {
        expect(youtubeVideoId(link), id, reason: link);
      }
    });

    test('anything else is not a video', () {
      for (final link in [
        '',
        'https://www.youtube.com/',
        'https://www.youtube.com/playlist?list=PL123',
        'https://www.youtube.com/@choir',
        'https://www.youtube.com/watch?v=short',
        'https://vimeo.com/$id',
        'https://vimeo.com/watch?v=$id',
        'https://example.com/shorts/$id',
        'https://youtu.be.example.com/$id',
        'not a link',
      ]) {
        expect(youtubeVideoId(link), isNull, reason: link);
      }
    });
  });

  group('proposeSongSlug', () {
    test('from the transliteration when given', () {
      expect(
        proposeSongSlug('ሰላም ለዚህ ቤት', transliteration: 'Selam Lezih Bet'),
        'selam-lezih-bet',
      );
    });

    test('Ethiopic titles become their consonants', () {
      expect(proposeSongSlug('ሰላም ለዚህ ቤት'), 'slm-lzh-bt');
    });

    test('Latin titles, punctuation and accents', () {
      expect(proposeSongSlug("  Amazing Grace! (Live) "), 'amazing-grace-live');
      expect(proposeSongSlug('Café Mezmur 2'), 'cafe-mezmur-2');
    });

    test('long titles stop at a word within 120 characters', () {
      final slug = proposeSongSlug(List.filled(40, 'word').join(' '));
      expect(slug.length, lessThanOrEqualTo(120));
      expect(slug.endsWith('word'), isTrue);
      expect(proposeSongSlug('a' * 200), 'a' * 120);
    });

    test('nothing usable gives "song"', () {
      expect(proposeSongSlug('!!!'), 'song');
      expect(proposeSongSlug('', transliteration: '  '), 'song');
    });

    test('is always a valid slug', () {
      for (final title in ['ሰላም', 'Hello, World', '!!!', 'ቅድስት ማርያም 3']) {
        expect(isValidSlug(proposeSongSlug(title)), isTrue, reason: title);
      }
    });
  });

  test('newRecordingId is a random lower-case UUID and a valid slug', () {
    final ids = {for (var i = 0; i < 100; i++) newRecordingId()};
    expect(ids, hasLength(100));
    for (final id in ids) {
      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(isValidSlug(id), isTrue);
    }
  });
}
