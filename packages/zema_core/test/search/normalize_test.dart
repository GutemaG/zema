import 'package:test/test.dart';
import 'package:zema_core/zema_core.dart';

void main() {
  group('normalizeSearchText folds Ethiopic spelling variants', () {
    test('h: ሐ and ኀ rows become the ሀ row, keeping the vowel order', () {
      expect(normalizeSearchText('ሐዋርያ'), normalizeSearchText('ሀዋርያ'));
      expect(normalizeSearchText('ኀጢአት'), normalizeSearchText('ሀጢአት'));
      expect(normalizeSearchText('ሑ ሒ ሔ ሕ ሖ'), 'ሁ ሂ ሄ ህ ሆ');
      expect(normalizeSearchText('ኁ ኂ ኄ ኅ ኆ'), 'ሁ ሂ ሄ ህ ሆ');
    });

    test('s: the ሠ row becomes the ሰ row', () {
      expect(normalizeSearchText('ሥላሴ'), 'ስላሴ');
      expect(normalizeSearchText('ሠ ሡ ሢ ሣ ሤ ሥ ሦ'), 'ሰ ሱ ሲ ሳ ሴ ስ ሶ');
    });

    test('glottal: the ዐ row becomes the አ row', () {
      expect(normalizeSearchText('ዐ ዑ ዒ ዔ ዕ ዖ'), 'አ ኡ ኢ ኤ እ ኦ');
    });

    test('ts: the ፀ row becomes the ጸ row', () {
      expect(normalizeSearchText('ፀሎት'), 'ጸሎት');
      expect(normalizeSearchText('ፁ ፂ ፃ ፄ ፅ ፆ'), 'ጹ ጺ ጻ ጼ ጽ ጾ');
    });

    test('ሃ and ኣ (and ሓ, ኃ, ዓ through the row fold) become ሀ and አ', () {
      expect(normalizeSearchText('ሃ ሓ ኃ'), 'ሀ ሀ ሀ');
      expect(normalizeSearchText('ኣ ዓ'), 'አ አ');
      expect(normalizeSearchText('ዓመት'), normalizeSearchText('አመት'));
    });

    test('other letters are left alone', () {
      const text = 'ቅድስት ማርያም ምስጋና ኢየሱስ ክርስቶስ';
      expect(normalizeSearchText(text), text);
    });
  });

  group('normalizeSearchText cleans up', () {
    test('lower-cases Latin and drops accents', () {
      expect(normalizeSearchText('KIDUS Mikael'), 'kidus mikael');
      expect(
        normalizeSearchText('Café Résumé Ñame Über'),
        'cafe resume name uber',
      );
    });

    test('drops combining marks without splitting words', () {
      // "é" written as e + combining acute.
      expect(normalizeSearchText('résumé'), 'resume');
      // Ethiopic combining gemination mark.
      expect(normalizeSearchText('ሰ፟ላም'), 'ሰላም');
    });

    test(
      'turns punctuation, Ethiopic word marks and spacing into one space',
      () {
        expect(normalizeSearchText('ሰላም፡ለኪ። ማርያም፣'), 'ሰላም ለኪ ማርያም');
        expect(
          normalizeSearchText('  Kidus -- Mikael (Live)!\n'),
          'kidus mikael live',
        );
        expect(normalizeSearchText("Egzi'abher"), 'egzi abher');
      },
    );

    test('drops noise words and phrases', () {
      expect(
        normalizeSearchText(
          'ፀሎት - Zemari Kidus | Official Video 2019 (New Mezmur) ft. Abebe',
        ),
        'ጸሎት zemari kidus abebe',
      );
      expect(normalizeSearchText('Amlak [Official Music Video] HD'), 'amlak');
      expect(normalizeSearchText('Amlak (Official Lyric Video)'), 'amlak');
      expect(normalizeSearchText('Amlak - Official Audio'), 'amlak');
      expect(
        normalizeSearchText('Amlak Lyrics feat. Meskerem'),
        'amlak meskerem',
      );
      expect(normalizeSearchText('አዲስ መዝሙር ሰላም'), 'ሰላም');
    });

    test('keeps the parts of noise phrases when they stand alone', () {
      expect(normalizeSearchText('Official Mezmur'), 'official mezmur');
      expect(normalizeSearchText('አዲስ ዘመን'), 'አዲስ ዘመን');
      expect(normalizeSearchText('New Song'), 'new song');
    });

    test('drops years from 1900 to 2099 but keeps other numbers', () {
      expect(normalizeSearchText('Fasika 2016 1999'), 'fasika');
      expect(
        normalizeSearchText('Psalm 23 1800 2100 12345'),
        'psalm 23 1800 2100 12345',
      );
    });

    test('keeps Ethiopic numerals and other scripts', () {
      expect(normalizeSearchText('መዝሙር ፳፫'), 'መዝሙር ፳፫');
      expect(normalizeSearchText('Ψαλμός Σαλάμ'), 'ψαλμός σαλάμ');
    });

    test('mixed scripts keep every word', () {
      expect(normalizeSearchText('Selam ሰላም ለኪ Mariam'), 'selam ሰላም ለኪ mariam');
    });

    test('empty, spaces only and noise only give nothing', () {
      expect(normalizeSearchText(''), isEmpty);
      expect(normalizeSearchText('   '), isEmpty);
      expect(normalizeSearchText('Official Video 2020'), isEmpty);
      expect(searchWords('— ። —'), isEmpty);
    });
  });

  group('the rule tables', () {
    test('every fold points at a row the consonant table knows', () {
      for (final MapEntry(:key, :value) in ethiopicRowFolds.entries) {
        expect(ethiopicRowConsonants[key], ethiopicRowConsonants[value]);
      }
    });

    test('noise phrases are already normalized', () {
      for (final phrase in searchNoisePhrases) {
        expect(normalizeSearchText(phrase), anyOf(isEmpty, phrase));
        expect(phrase, isNot(contains('  ')));
      }
    });

    test('rows are named by their first code point', () {
      for (final row in ethiopicRowConsonants.keys) {
        expect((row - 0x1200) % 8, 0, reason: row.toRadixString(16));
      }
    });
  });
}
