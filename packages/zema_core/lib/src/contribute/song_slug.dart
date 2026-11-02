import 'dart:math';

import '../search/normalize.dart';
import '../search/transliteration.dart';
import 'contribution_rules.dart';

final _notSlug = RegExp('[^a-z0-9]+');

/// An id for a new song, from its [transliteration] when given, otherwise
/// from its [title]: Latin words as they are, Ethiopic words as their
/// consonants ("ሰላም ለዚህ ቤት" is "slm-lzh-bt"). Lower case words joined by
/// hyphens, at most [maxSlugLength] characters, "song" when nothing is left.
/// The backend makes it unique when the song is approved.
String proposeSongSlug(String title, {String? transliteration}) {
  final latin = transliteration?.trim() ?? '';
  final words = [
    for (final word in searchWords(latin.isNotEmpty ? latin : title))
      (word.runes.any(isEthiopicSyllable) ? consonantSkeleton(word) : word)
          .replaceAll(_notSlug, ''),
  ].where((w) => w.isNotEmpty);
  var slug = '';
  for (final word in words) {
    final next = slug.isEmpty ? word : '$slug-$word';
    if (next.length > maxSlugLength) {
      if (slug.isEmpty) slug = word.substring(0, maxSlugLength);
      break;
    }
    slug = next;
  }
  return slug.isEmpty ? 'song' : slug;
}

final _random = Random.secure();

/// A new random recording id: a lower-case UUID (version 4), which is also a
/// valid slug.
String newRecordingId() {
  final bytes = [for (var i = 0; i < 16; i++) _random.nextInt(256)];
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')];
  return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-'
      '${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-'
      '${hex.sublist(10).join()}';
}
