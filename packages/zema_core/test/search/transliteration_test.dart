import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

String _skeleton(String word) => consonantSkeleton(normalizeSearchText(word));

double _score(String query, String target) =>
    matchScore(SearchKey(query), SearchKey(target));

void main() {
  group('consonantSkeleton', () {
    test('Ethiopic and Latin spellings of a word agree', () {
      for (final word in ['ቅድስት', 'ቅዱስት', 'kidist', 'qidist', 'kiddist']) {
        expect(_skeleton(word), 'kdst', reason: word);
      }
      expect(_skeleton('እግዚአብሔር'), 'gzbhr');
      expect(_skeleton('egziabher'), 'gzbhr');
      expect(_skeleton('ሰላም'), 'slm');
      expect(_skeleton('ጸሎት'), 'tslt');
      expect(_skeleton('ፀሎት'), 'tslt');
      expect(_skeleton('tselot'), 'tslt');
      expect(_skeleton('አምላክ'), 'mlk');
      expect(_skeleton('ሻሎም'), _skeleton('shalom'));
      expect(_skeleton('ኢየሱስ'), _skeleton('iyesus'));
    });

    test('Latin spelling folds apply', () {
      expect(_skeleton('ph'), 'f');
      expect(_skeleton('xa'), 'h');
      expect(_skeleton('kha'), 'h');
      expect(_skeleton('agegnehu'), _skeleton('አገኘሁ'));
    });

    test('labialized rows use their base consonant', () {
      expect(_skeleton('ቋንቋ'), 'knk');
      expect(_skeleton('ጓደኛ'), 'gdny');
      expect(_skeleton('ኳስ'), 'ks');
    });

    test('vowels drop and repeated letters collapse', () {
      expect(_skeleton('aeiou'), isEmpty);
      expect(_skeleton('kiddusss'), 'kds');
      expect(_skeleton('የሱስ'), 'ys');
    });

    test('digits and other scripts pass through', () {
      expect(consonantSkeleton('23'), '23');
      expect(consonantSkeleton('ψαλμ'), 'ψαλμ');
    });
  });

  group('SearchKey', () {
    test('holds normalized words and their skeletons', () {
      final key = SearchKey('ፀሎት – Official Video');
      expect(key.words, ['ጸሎት']);
      expect(key.skeletons, ['tslt']);
      expect(SearchKey(' ። ').isEmpty, isTrue);
    });
  });

  group('matchScore and isMatch', () {
    // Query → targets that must match.
    const matches = {
      'kidist': ['ቅድስት', 'ቅዱስት', 'Kidist Mariam'],
      'qidist': ['ቅድስት'],
      'kiddist': ['ቅዱስት'],
      'ቅዱስት': ['ቅድስት', 'kidist'],
      'egziabher': ['እግዚአብሔር', 'እግዚአብሄር ይመስገን'],
      'selam': ['ሰላም', 'ሰላም ለኪ'],
      'tselot': ['ጸሎት', 'ፀሎት'],
      'selot': ['ጸሎት'],
      'ስላሴ': ['ሥላሴ'],
      'amlak': ['አምላክ', 'Amlak - Official Video'],
      'kidus mikael': ['ቅዱስ ሚካኤል'],
      'egzi': ['እግዚአብሔር'],
      'ki': ['ቅድስት'],
      'mari': ['ማርያም'],
      'ሰላ': ['ሰላም'],
    };
    // Query → targets that must not match.
    const misses = {
      'kidist': ['ቀዳሚ', 'ቤዛዊት', 'ሰላም', 'Amlak'],
      'selam': ['ስም', 'ማርያም', 'kidist'],
      'ki': ['ሰላም', 'mikael'],
      'k': ['ማርያም'],
      'amlak': ['ቤዛዊት', 'ሰላም'],
      'egziabher': ['እግር'],
    };

    test('match the expected pairs', () {
      for (final MapEntry(key: query, value: targets) in matches.entries) {
        for (final target in targets) {
          expect(
            isMatch(SearchKey(query), SearchKey(target)),
            isTrue,
            reason: '$query → $target (${_score(query, target)})',
          );
        }
      }
    });

    test('miss the unrelated pairs', () {
      for (final MapEntry(key: query, value: targets) in misses.entries) {
        for (final target in targets) {
          expect(
            isMatch(SearchKey(query), SearchKey(target)),
            isFalse,
            reason: '$query → $target (${_score(query, target)})',
          );
        }
      }
    });

    test('rank exact above typing above near spellings', () {
      expect(_score('kidist', 'ቅድስት'), 1);
      expect(_score('kidist', 'kidist'), 1);
      expect(_score('kid', 'kidist'), 0.9);
      expect(_score('selot', 'ጸሎት'), lessThan(_score('tselot', 'ጸሎት')));
      expect(_score('selot', 'ጸሎት'), greaterThan(_score('kidist', 'ቀዳሚ')));
    });

    test('a word inside another word scores below a start', () {
      expect(_score('dist', 'kidist'), 0.8);
      expect(_score('dist', 'kidist'), lessThan(_score('kidi', 'kidist')));
    });

    test('one- and two-letter words match starts only', () {
      expect(_score('di', 'kidist'), 0);
      expect(_score('ka', 'kidist'), 0.9);
      expect(_score('s', 'ሰላም'), 0.9);
      expect(_score('l', 'ሰላም'), 0);
    });

    test('the score is the mean over the query words', () {
      expect(_score('kidus mikael', 'ቅዱስ ሚካኤል'), 1);
      expect(_score('kidus zzzz', 'ቅዱስ ሚካኤል'), 0.5);
      expect(isMatch(SearchKey('kidus zzzz'), SearchKey('ቅዱስ ሚካኤል')), isFalse);
    });

    test('words with the same consonants match (a known limit)', () {
      // Vowels are dropped so loose spellings meet; the cost is that
      // "amlak" (አምላክ) and "malak" (መላክ) look the same.
      expect(_score('amlak', 'መላክ'), 1);
      expect(_score('amlak', 'አምላክ'), 1);
      // And a query reads as the start of a longer word ("mlk" → ምልክት).
      expect(_score('amlak', 'ምልክት'), 0.9);
    });

    test('an empty query matches everything; an empty target nothing', () {
      expect(_score('', 'ሰላም'), 1);
      expect(_score('Official Video', 'ሰላም'), 1);
      expect(_score('selam', ''), 0);
    });

    test('is the same for a key reused across targets', () {
      final query = SearchKey('kidist');
      expect(matchScore(query, SearchKey('ቅድስት')), 1);
      expect(matchScore(query, SearchKey('ሰላም')), lessThan(matchThreshold));
      expect(matchScore(query, SearchKey('ቅዱስት')), 1);
    });
  });

  test('scores 1,000 titles in well under the keystroke budget', () {
    final titles = [
      for (var i = 0; i < 1000; i++)
        SearchKey('ቅዱስ ሚካኤል $i ፀሎት ለኪ Zemari Number $i'),
    ];
    final query = SearchKey('tselot leki');
    final watch = Stopwatch()..start();
    final found = titles.where((t) => isMatch(query, t)).length;
    watch.stop();
    expect(found, 1000);
    // The app's goal is < 100 ms per keystroke for everything; leave room.
    expect(watch.elapsedMilliseconds, lessThan(50));
  });
}
