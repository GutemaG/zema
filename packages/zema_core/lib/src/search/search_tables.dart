/// The rules search uses to compare text, as plain data so the cloud catalog
/// can apply the same ones on the server (in SQL).
///
/// Ethiopic syllables come in rows of eight code points, one per vowel order:
/// U+1200 ሀ, U+1201 ሁ … U+1207 ሇ. A row is named by its first code point.
library;

/// Rows that spell the same sound, folded to one row; the vowel order is
/// kept (ሑ → ሁ).
const Map<int, int> ethiopicRowFolds = {
  0x1210: 0x1200, // ሐ → ሀ
  0x1280: 0x1200, // ኀ → ሀ
  0x1220: 0x1230, // ሠ → ሰ
  0x12D0: 0x12A0, // ዐ → አ
  0x1340: 0x1338, // ፀ → ጸ
};

/// Single syllables that spell the same sound, applied after
/// [ethiopicRowFolds] (so ሓ, ኃ and ዓ follow).
const Map<int, int> ethiopicSyllableFolds = {
  0x1203: 0x1200, // ሃ → ሀ
  0x12A3: 0x12A0, // ኣ → አ
};

/// The Latin consonant(s) of each Ethiopic row, for comparing Ethiopic text
/// with Latin spellings of it. Labialized rows (ቈ, ኰ, ጐ …) use their base
/// consonant; the vowel carriers አ and ዐ have none.
const Map<int, String> ethiopicRowConsonants = {
  0x1200: 'h', // ሀ
  0x1208: 'l', // ለ
  0x1210: 'h', // ሐ
  0x1218: 'm', // መ
  0x1220: 's', // ሠ
  0x1228: 'r', // ረ
  0x1230: 's', // ሰ
  0x1238: 'sh', // ሸ
  0x1240: 'q', // ቀ
  0x1248: 'q', // ቈ
  0x1250: 'q', // ቐ
  0x1258: 'q', // ቘ
  0x1260: 'b', // በ
  0x1268: 'v', // ቨ
  0x1270: 't', // ተ
  0x1278: 'ch', // ቸ
  0x1280: 'h', // ኀ
  0x1288: 'h', // ኈ
  0x1290: 'n', // ነ
  0x1298: 'ny', // ኘ
  0x12A0: '', // አ
  0x12A8: 'k', // ከ
  0x12B0: 'k', // ኰ
  0x12B8: 'h', // ኸ
  0x12C0: 'h', // ዀ
  0x12C8: 'w', // ወ
  0x12D0: '', // ዐ
  0x12D8: 'z', // ዘ
  0x12E0: 'zh', // ዠ
  0x12E8: 'y', // የ
  0x12F0: 'd', // ደ
  0x12F8: 'd', // ዸ
  0x1300: 'j', // ጀ
  0x1308: 'g', // ገ
  0x1310: 'g', // ጐ
  0x1318: 'g', // ጘ
  0x1320: 't', // ጠ
  0x1328: 'ch', // ጨ
  0x1330: 'p', // ጰ
  0x1338: 'ts', // ጸ
  0x1340: 'ts', // ፀ
  0x1348: 'f', // ፈ
  0x1350: 'p', // ፐ
};

/// Latin spellings of the same sound, applied in order to both sides before
/// vowels are dropped ("qidist" and "kidist" agree).
const List<(String, String)> latinSpellingFolds = [
  ('ph', 'f'),
  ('kh', 'h'),
  ('x', 'h'),
  ('q', 'k'),
  ('gn', 'ny'),
];

/// Vowels dropped from Latin spellings; Ethiopic vowels are already implied
/// by the syllable.
const String latinVowels = 'aeiou';

/// Accented Latin letters and their plain form.
const Map<String, String> latinAccentFolds = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'ā': 'a',
  'ç': 'c',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ē': 'e',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ī': 'i',
  'ñ': 'n',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ō': 'o',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ū': 'u',
  'ý': 'y',
  'ÿ': 'y',
};

/// Words and phrases in titles that don't help find a song, already
/// normalized. Longer phrases come first so they win over their parts.
const List<String> searchNoisePhrases = [
  'official music video',
  'official lyric video',
  'official video',
  'official audio',
  'lyric video',
  'music video',
  'new mezmur',
  'አዲስ መዝሙር',
  'lyrics',
  'feat',
  'ft',
  'hd',
];

/// Years in titles ("… 2019"): four digits from 1900 to 2099.
final RegExp searchNoiseYear = RegExp(r'^(19|20)\d\d$');
