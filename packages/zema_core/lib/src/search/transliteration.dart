import 'dart:math';

import 'normalize.dart';
import 'search_tables.dart';

/// A word reduced to its Latin consonants, so Ethiopic and the many Latin
/// spellings of it compare equal: "ቅድስት", "kidist", "kiddist" and "qidist"
/// are all "kdst".
///
/// Ethiopic syllables become their row's consonant(s)
/// ([ethiopicRowConsonants]); Latin goes through [latinSpellingFolds] and
/// loses its vowels ([latinVowels]); then repeated letters collapse. Pass a
/// word already through [normalizeSearchText]. Other scripts and digits pass
/// through.
///
/// Dropping vowels is what lets loose spellings meet, and also why words
/// with the same consonants meet: "amlak" (አምላክ) and "malak" (መላክ) are
/// both "mlk".
String consonantSkeleton(String word) {
  // Latin folds apply to a Latin run or one syllable's consonant, never
  // across syllables: ገ + ኘ is "g" + "ny", not a "gn" to fold.
  final spelled = StringBuffer();
  final latin = StringBuffer();
  void flushLatin() {
    spelled.write(_foldLatin(latin.toString()));
    latin.clear();
  }

  for (final rune in word.runes) {
    if (isEthiopicSyllable(rune)) {
      flushLatin();
      final consonant = ethiopicRowConsonants[ethiopicRow(rune)];
      spelled.write(
        consonant == null ? String.fromCharCode(rune) : _foldLatin(consonant),
      );
    } else {
      latin.writeCharCode(rune);
    }
  }
  flushLatin();
  final skeleton = StringBuffer();
  int? previous;
  for (final rune in spelled.toString().runes) {
    if (latinVowels.codeUnits.contains(rune) || rune == previous) continue;
    skeleton.writeCharCode(rune);
    previous = rune;
  }
  return skeleton.toString();
}

String _foldLatin(String text) {
  var folded = text;
  for (final (from, to) in latinSpellingFolds) {
    folded = folded.replaceAll(from, to);
  }
  return folded;
}

/// A text prepared for matching: its normalized words and their consonant
/// skeletons. Build one per song or query and reuse it.
class SearchKey {
  SearchKey(String text) : words = searchWords(text) {
    skeletons = [for (final w in words) consonantSkeleton(w)];
  }

  final List<String> words;
  late final List<String> skeletons;

  bool get isEmpty => words.isEmpty;
}

/// How well [query] matches [target], from 0 (not at all) to 1: the mean,
/// over the query's words, of the best score against any target word.
///
/// A query word scores 1 when it equals a target word or has the same
/// skeleton, 0.9 when it starts one (still typing), 0.8 when it is inside
/// one, and otherwise by how few letters its skeleton differs by. Words of
/// one or two letters only match starts. An empty query matches everything.
double matchScore(SearchKey query, SearchKey target) {
  if (query.isEmpty) return 1;
  var total = 0.0;
  for (var i = 0; i < query.words.length; i++) {
    var best = 0.0;
    for (var j = 0; j < target.words.length && best < 1; j++) {
      best = max(
        best,
        _wordScore(
          query.words[i],
          query.skeletons[i],
          target.words[j],
          target.skeletons[j],
        ),
      );
    }
    total += best;
  }
  return total / query.words.length;
}

/// The score from which [matchScore] counts as a match.
const double matchThreshold = 0.75;

/// Whether [query] matches [target] ([matchScore] at least
/// [matchThreshold]).
bool isMatch(SearchKey query, SearchKey target) =>
    matchScore(query, target) >= matchThreshold;

double _wordScore(String q, String qs, String t, String ts) {
  if (q == t || (qs.isNotEmpty && qs == ts)) return 1;
  if (t.startsWith(q) || (qs.isNotEmpty && ts.startsWith(qs))) return 0.9;
  if (q.runes.length <= 2) return 0;
  if (t.contains(q)) return 0.8;
  if (qs.length < 3 || ts.length < 3) return 0;
  // Near spellings, against the whole word or (still typing) its start.
  final whole = 1 - _distance(qs, ts) / max(qs.length, ts.length);
  final start = ts.length > qs.length
      ? 0.9 * (1 - _distance(qs, ts.substring(0, qs.length)) / qs.length)
      : 0.0;
  return max(0, max(whole, start));
}

/// Levenshtein distance between [a] and [b].
int _distance(String a, String b) {
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      current[j] = min(
        min(current[j - 1] + 1, previous[j] + 1),
        previous[j - 1] + cost,
      );
    }
    previous = current;
  }
  return previous[b.length];
}
