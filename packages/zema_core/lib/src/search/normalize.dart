import 'search_tables.dart';

final _marks = RegExp(r'\p{M}', unicode: true);
final _notLetterOrDigit = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

final List<List<String>> _noise = [
  for (final phrase in searchNoisePhrases) phrase.split(' '),
];

/// [text] as search compares it: lower-case, Ethiopic spelling variants and
/// Latin accents folded ([ethiopicRowFolds], [latinAccentFolds]), anything
/// that isn't a letter or digit turned into a space (Ethiopic ፡ and ። too),
/// noise words and years dropped ([searchNoisePhrases]), single spaces.
///
/// Letters of any script are kept; only marks and punctuation go.
String normalizeSearchText(String text) => searchWords(text).join(' ');

/// The words of [text] after [normalizeSearchText].
List<String> searchWords(String text) {
  final folded = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    folded.write(foldCharacter(rune));
  }
  final words = folded
      .toString()
      .replaceAll(_marks, '')
      .split(_notLetterOrDigit)
      .where((w) => w.isNotEmpty)
      .toList();
  return _dropNoise(words);
}

/// One character with [ethiopicRowFolds], [ethiopicSyllableFolds] and
/// [latinAccentFolds] applied.
String foldCharacter(int rune) {
  if (!isEthiopicSyllable(rune)) {
    final char = String.fromCharCode(rune);
    return latinAccentFolds[char] ?? char;
  }
  final row = ethiopicRow(rune);
  final foldedRow = ethiopicRowFolds[row];
  final folded = foldedRow == null ? rune : foldedRow + (rune - row);
  return String.fromCharCode(ethiopicSyllableFolds[folded] ?? folded);
}

/// Whether [rune] is in the main Ethiopic syllable block (ሀ … ፚ).
bool isEthiopicSyllable(int rune) => rune >= 0x1200 && rune <= 0x135A;

/// The first code point of [rune]'s row of eight.
int ethiopicRow(int rune) => rune - (rune - 0x1200) % 8;

List<String> _dropNoise(List<String> words) {
  final kept = <String>[];
  var i = 0;
  outer:
  while (i < words.length) {
    if (searchNoiseYear.hasMatch(words[i])) {
      i++;
      continue;
    }
    for (final phrase in _noise) {
      if (_startsAt(words, i, phrase)) {
        i += phrase.length;
        continue outer;
      }
    }
    kept.add(words[i++]);
  }
  return kept;
}

bool _startsAt(List<String> words, int at, List<String> phrase) {
  if (at + phrase.length > words.length) return false;
  for (var j = 0; j < phrase.length; j++) {
    if (words[at + j] != phrase[j]) return false;
  }
  return true;
}
